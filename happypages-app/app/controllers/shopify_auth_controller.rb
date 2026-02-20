class ShopifyAuthController < ApplicationController
  skip_before_action :set_current_shop
  skip_before_action :verify_authenticity_token, only: [ :callback ]

  SCOPES = "read_customers,write_customers,write_discounts,read_orders,read_products,read_themes"

  # GET /auth/shopify?shop=my-store.myshopify.com
  def initiate
    shop_domain = params[:shop]

    unless valid_shopify_domain?(shop_domain)
      return redirect_to root_path, alert: "Invalid shop domain"
    end

    # Always allow OAuth - handles both new installs and returning shops
    state = SecureRandom.hex(24)
    session[:oauth_state] = state
    session[:oauth_shop] = shop_domain

    redirect_to shopify_oauth_url(shop_domain, state), allow_other_host: true
  end

  # GET /auth/shopify/callback
  def callback
    # Verify state
    unless params[:state] == session[:oauth_state]
      return redirect_to login_path, alert: "Invalid state parameter"
    end

    shop_domain = session[:oauth_shop]

    # Exchange code for token
    token_response = exchange_code_for_token(shop_domain, params[:code])

    unless token_response[:success]
      Rails.logger.error "OAuth token exchange failed: #{token_response[:error]}"
      return redirect_to login_path, alert: "OAuth failed: #{token_response[:error]}"
    end

    access_token = token_response[:access_token]
    granted_scopes = token_response[:scope]

    # Log scope gaps — merchant must re-install to grant new scopes
    granted = granted_scopes.split(",").map(&:strip)
    required = SCOPES.split(",").map(&:strip)

    # Shopify's write_X implicitly covers read_X
    effective = granted.dup
    granted.each do |scope|
      effective << scope.sub("write_", "read_") if scope.start_with?("write_")
    end

    missing = required.sort - effective.uniq.sort

    if missing.any?
      Rails.logger.warn "[OAuth] Token missing scopes: #{missing.join(', ')} — merchant must re-install to grant"
    end

    shop_info = fetch_shop_info(shop_domain, access_token)

    unless shop_info[:success]
      Rails.logger.error "Failed to fetch shop info: #{shop_info[:error]}"
      return redirect_to login_path, alert: "Failed to fetch shop information"
    end

    scopes_upgraded = false

    ActiveRecord::Base.transaction do
      existing_shop = Shop.find_by(domain: shop_domain)

      if existing_shop
        # RETURNING SHOP - preserve all data, only refresh token + scopes
        old_scopes = existing_shop.shop_credential.granted_scopes
        existing_shop.shop_credential.update!(
          shopify_access_token: access_token,
          granted_scopes: granted_scopes
        )
        scopes_upgraded = old_scopes&.split(",")&.map(&:strip)&.sort != granted_scopes.split(",").map(&:strip).sort
        # NOTE: Does NOT touch awtomic_api_key, klaviyo_api_key, webhook_secret

        # Create user if missing (upgrade path for pre-OAuth shops)
        user = existing_shop.users.order(:id).first || User.create!(
          shop: existing_shop,
          email: shop_info[:email],
          shopify_user_id: shop_info[:owner_id]
        )

        reset_session  # Prevent session fixation
        session[:user_id] = user.id
        session[:last_seen] = Time.current
        @shop = existing_shop
        @returning = true
      else
        # NEW SHOP - create everything
        @shop = Shop.create!(
          name: shop_domain.split(".").first.titleize,
          domain: shop_domain,
          platform_type: "shopify",
          status: "active"
        )

        @shop.create_shop_credential!(
          shopify_access_token: access_token,
          granted_scopes: granted_scopes
        )

        user = User.create!(
          shop: @shop,
          email: shop_info[:email],
          shopify_user_id: shop_info[:owner_id]
        )

        reset_session  # Prevent session fixation
        session[:user_id] = user.id
        session[:last_seen] = Time.current
        @returning = false
      end
    end

    # Write shop slug to Shopify metafield (fire-and-forget)
    sync_shop_slug_metafield(@shop)

    # Scrape brand identity (async) — runs on install, re-auth, or scope upgrade
    if !@shop.brand_scraped? || scopes_upgraded || @returning
      BrandScrapeJob.perform_later(@shop.id)
    end

    return_to = session.delete(:return_to) || admin_dashboard_path

    if @returning
      redirect_to return_to, notice: "Welcome back! You're now logged in."
    else
      redirect_to admin_dashboard_path, notice: "App installed successfully! Configure your referral program below."
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "OAuth user/shop creation failed: #{e.message}"
    redirect_to login_path, alert: "Account setup failed: #{e.message}"
  end

  private

  def sync_shop_slug_metafield(shop)
    return unless shop.shopify? && shop.slug.present?

    ShopMetafieldWriter.new(shop).write_slug
  rescue => e
    Rails.logger.error "Failed to sync shop slug metafield: #{e.message}"
  end

  def valid_shopify_domain?(domain)
    domain.present? && domain.match?(/\A[\w-]+\.myshopify\.com\z/)
  end

  def shopify_oauth_url(shop_domain, state)
    client_id = ENV.fetch("SHOPIFY_CLIENT_ID")
    redirect_uri = ENV.fetch("SHOPIFY_REDIRECT_URI")

    "https://#{shop_domain}/admin/oauth/authorize?" + {
      client_id: client_id,
      scope: SCOPES,
      redirect_uri: redirect_uri,
      state: state
    }.to_query
  end

  def exchange_code_for_token(shop_domain, code)
    uri = URI("https://#{shop_domain}/admin/oauth/access_token")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = {
      client_id: ENV.fetch("SHOPIFY_CLIENT_ID"),
      client_secret: ENV.fetch("SHOPIFY_CLIENT_SECRET"),
      code: code
    }.to_json

    response = http.request(request)
    data = JSON.parse(response.body)

    if response.is_a?(Net::HTTPSuccess)
      { success: true, access_token: data["access_token"], scope: data["scope"].to_s }
    else
      { success: false, error: data["error_description"] || "Token exchange failed" }
    end
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def fetch_shop_info(shop_domain, access_token)
    uri = URI("https://#{shop_domain}/admin/api/2025-10/shop.json")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request["X-Shopify-Access-Token"] = access_token

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)["shop"]
      {
        success: true,
        email: data["email"],
        owner_id: data["id"].to_s
      }
    else
      { success: false, error: "API request failed" }
    end
  rescue StandardError => e
    { success: false, error: e.message }
  end
end
