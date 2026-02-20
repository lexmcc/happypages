class EmbeddedController < ApplicationController
  include ShopifySessionTokenVerifiable

  skip_forgery_protection only: [ :authenticate ]
  skip_before_action :set_current_shop

  layout "embedded"

  after_action :allow_shopify_iframe

  def show
  end

  # POST /embedded/authenticate
  # App Bridge auto-injects Authorization: Bearer <session-token>
  def authenticate
    auth_header = request.headers["Authorization"]
    unless auth_header&.start_with?("Bearer ")
      return render json: { error: "Missing authorization" }, status: :unauthorized
    end

    token = auth_header.delete_prefix("Bearer ")
    claims = verify_session_token(token)
    unless claims
      return render json: { error: "Invalid session token" }, status: :unauthorized
    end

    # Extract shop domain from dest claim (e.g. "https://my-store.myshopify.com")
    dest = claims["dest"]
    unless dest.present?
      return render json: { error: "Missing dest claim" }, status: :unauthorized
    end

    shop_domain = URI.parse(dest).host
    unless shop_domain&.match?(/\A[\w-]+\.myshopify\.com\z/)
      return render json: { error: "Invalid shop domain" }, status: :unauthorized
    end

    shop = Shop.find_by(domain: shop_domain, status: "active")
    unless shop
      return render json: { error: "Shop not found" }, status: :not_found
    end

    user = shop.users.order(:id).first
    unless user
      return render json: { error: "User not found" }, status: :not_found
    end

    # Establish cookie session (same pattern as OAuth callback)
    reset_session
    session[:user_id] = user.id
    session[:last_seen] = Time.current

    render json: { authenticated: true, redirect_url: "/admin" }
  rescue URI::InvalidURIError
    render json: { error: "Invalid dest claim" }, status: :unauthorized
  end

  private

  def allow_shopify_iframe
    response.headers.delete("X-Frame-Options")
    response.headers["Content-Security-Policy"] = "frame-ancestors https://*.myshopify.com https://admin.shopify.com"
  end
end
