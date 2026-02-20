class WebhooksController < ApplicationController
  include KlaviyoTrackable
  skip_before_action :verify_authenticity_token
  skip_before_action :set_current_shop  # We identify shop from webhook headers
  before_action :set_shop_from_webhook
  before_action :verify_webhook_signature

  # Shopify compliance webhook dispatcher
  # All compliance topics arrive at the same URI, differentiated by X-Shopify-Topic header
  def compliance
    topic = request.headers["X-Shopify-Topic"]

    request.body.rewind
    payload = JSON.parse(request.body.read)

    case topic
    when "customers/data_request"
      handle_customers_data_request(payload)
    when "customers/redact"
      handle_customers_redact(payload)
    when "shop/redact"
      handle_shop_redact(payload)
    else
      Rails.logger.warn "Unknown compliance webhook topic: #{topic}"
    end

    head :ok
  rescue JSON::ParserError => e
    Rails.logger.error "Compliance webhook JSON parse error: #{e.message}"
    head :bad_request
  end

  def orders
    request.body.rewind
    payload = JSON.parse(request.body.read)

    # Parse order using platform-specific handler
    order = Current.shop&.order_handler&.parse_order(payload) || parse_legacy_order(payload)

    # Create referral for the buyer (fallback if extension didn't)
    create_buyer_referral(order)

    # Process discount codes used in this order
    order[:discount_codes_used].each do |code|
      referral = find_referral_by_code(code)

      if referral
        process_referral_usage(referral, order)
      else
        process_reward_consumption(code, order[:order_id])
      end
    end

    head :ok
  rescue JSON::ParserError => e
    Rails.logger.error "Webhook JSON parse error: #{e.message}"
    head :bad_request
  end

  private

  def set_shop_from_webhook
    # Identify shop from webhook headers
    domain = Providers::Shopify::OrderHandler.extract_shop_domain(request) ||
             Providers::Custom::OrderHandler.extract_shop_domain(request)

    if domain
      Current.shop = Shop.find_by(domain: domain)
    end

    unless Current.shop
      Rails.logger.warn "Webhook received for unknown shop domain: #{domain}"
    end
  end

  def verify_webhook_signature
    if Current.shop
      handler = Current.shop.order_handler
      # Shopify signs webhooks with the app client secret, not a per-shop secret
      secret = Current.shop.shopify? ? ENV["SHOPIFY_CLIENT_SECRET"] : Current.shop.webhook_secret
    else
      secret = ENV["SHOPIFY_CLIENT_SECRET"]
      handler = Providers::Shopify::OrderHandler.new(nil)
    end

    hmac_header = request.headers["X-Shopify-Hmac-Sha256"] ||
                  request.headers["X-Webhook-Signature"]

    # If a signature header is present but we have no secret to verify, reject
    if hmac_header.present? && secret.blank?
      head :unauthorized
      return false
    end

    # Skip verification only when there's no signature and no secret (local dev)
    return if hmac_header.blank? && secret.blank?

    unless handler.verify_signature(request, secret)
      Rails.logger.warn "Invalid webhook signature#{Current.shop ? " for shop #{Current.shop.domain}" : ""}"
      head :unauthorized
      false
    end
  end

  def parse_legacy_order(payload)
    {
      order_id: payload["id"].to_s,
      customer_email: payload.dig("customer", "email"),
      customer_id: normalize_gid(payload.dig("customer", "id")),
      customer_first_name: payload.dig("customer", "first_name"),
      discount_codes_used: payload["discount_codes"]&.map { |d| d["code"] } || [],
      total: payload["total_price"].to_f,
      raw_payload: payload
    }
  end

  def normalize_gid(id)
    return nil unless id
    id.to_s.include?("gid://") ? id.to_s : "gid://shopify/Customer/#{id}"
  end

  # --- Compliance webhook handlers ---

  def handle_customers_data_request(payload)
    AuditLog.log(
      action: "data_request",
      actor: "webhook",
      shop: Current.shop,
      actor_identifier: payload.dig("customer", "email"),
      details: {
        shopify_customer_id: payload.dig("customer", "id"),
        orders_requested: payload["orders_requested"],
        shop_domain: payload["shop_domain"]
      }
    )
    Rails.logger.info "Customers data request received for #{payload.dig('customer', 'email')} (shop: #{payload['shop_domain']})"
  end

  def handle_customers_redact(payload)
    customer_email = payload.dig("customer", "email")
    customer_id = payload.dig("customer", "id")
    shop_domain = payload["shop_domain"]

    shop = Current.shop || Shop.find_by(domain: shop_domain)

    unless shop && customer_email.present?
      Rails.logger.warn "Customer redact: could not find shop (#{shop_domain}) or missing email"
      return
    end

    referrals = shop.referrals.where(email: customer_email)
    referral_count = referrals.count
    referrals.find_each do |referral|
      referral.update!(
        email: "deleted-#{referral.id}@redacted",
        first_name: "Deleted"
      )
    end

    events_count = shop.referral_events.where(email: customer_email).count
    shop.referral_events.where(email: customer_email).delete_all

    AuditLog.log(
      action: "customer_redact",
      actor: "webhook",
      shop: shop,
      actor_identifier: "shopify:#{customer_id}",
      details: {
        shop_domain: shop_domain,
        referrals_anonymised: referral_count,
        events_deleted: events_count
      }
    )
    Rails.logger.info "Customer redact complete for shop #{shop_domain}: #{referral_count} referrals anonymised, #{events_count} events deleted"
  end

  def handle_shop_redact(payload)
    shop_domain = payload["shop_domain"]
    shop = Current.shop || Shop.find_by(domain: shop_domain)

    unless shop
      Rails.logger.warn "Shop redact: could not find shop #{shop_domain}"
      return
    end

    AuditLog.log(
      action: "shop_redact",
      actor: "webhook",
      shop: shop,
      details: {
        shop_domain: shop_domain,
        shop_id: shop.id,
        referral_count: shop.referrals.count,
        event_count: shop.referral_events.count
      }
    )

    shop.destroy!
    Rails.logger.info "Shop redact complete: all data deleted for #{shop_domain}"
  end

  # --- Order webhook helpers ---

  def find_referral_by_code(code)
    return nil unless Current.shop
    Current.shop.referrals.find_by(referral_code: code)
  end

  def process_referral_usage(referral, order)
    # Skip if we already processed this order for this referral (webhook retry)
    if referral.referral_rewards.exists?(shopify_order_id: order[:order_id])
      Rails.logger.info "Order #{order[:order_id]} already processed for #{referral.referral_code}, skipping"
      return
    end

    referral.increment!(:usage_count)
    Rails.logger.info "Referral code #{referral.referral_code} used! Total uses: #{referral.usage_count}"

    group = SharedDiscount.current(Current.shop)
    track_klaviyo(:referral_used, referral,
      buyer_email: order[:customer_email] || "",
      referred_discount_value: group&.effective_referred_value,
      referred_discount_type: group&.effective_referred_type
    )

    # Create a reward discount for the referrer
    create_referrer_reward(referral, order_id: order[:order_id])
  end

  def process_reward_consumption(code, order_id)
    return unless Current.shop
    reward = ReferralReward.joins(:referral).where(referrals: { shop_id: Current.shop.id }).find_by(code: code)
    if reward && !reward.consumed?
      reward.mark_consumed!
      Rails.logger.info "Reward #{code} consumed via order #{order_id}"
    end
  end

  def create_buyer_referral(order)
    raw = order[:raw_payload]
    customer = raw["customer"] || {}
    shipping = raw["shipping_address"] || {}
    billing = raw["billing_address"] || {}

    email = order[:customer_email].presence
    first_name = order[:customer_first_name].presence ||
                 shipping["first_name"].presence ||
                 billing["first_name"].presence
    customer_id = order[:customer_id]

    return unless email.present?

    return unless Current.shop
    existing = Current.shop.referrals.find_by(email: email)

    if existing
      Rails.logger.info "Referral already exists for #{email}, skipping webhook creation"
      if customer_id.present? && existing.shopify_customer_id.blank?
        existing.update(shopify_customer_id: customer_id)
      end
      return
    end

    first_name ||= "Customer"

    referral = Referral.new(
      first_name: first_name,
      email: email,
      shopify_customer_id: customer_id,
      shop: Current.shop
    )

    if referral.save
      Rails.logger.info "Created referral via webhook for #{email}: #{referral.referral_code}"
      create_discount_for_referral(referral)
    else
      Rails.logger.error "Failed to create referral via webhook: #{referral.errors.full_messages.join(', ')}"
    end
  rescue => e
    Rails.logger.error "Error in create_buyer_referral: #{e.message}"
  end

  def create_discount_for_referral(referral)
    group = SharedDiscount.current(Current.shop)

    unless group
      Rails.logger.warn "No active discount group, skipping discount creation"
      return
    end

    return unless Current.shop  # Requires shop context
    provider = Current.shop.discount_provider
    customer_provider = Current.shop.customer_provider

    generation = group.current_generation

    unless generation
      result = provider.create_generation_discount(
        group: group,
        initial_code: referral.referral_code
      )

      if result[:success]
        generation = result[:generation]
        referral.update(
          discount_generation: generation,
          shopify_discount_id: result[:discount_id],
          uses_shared_discount: true
        )
        Rails.logger.info "Created new generation for #{referral.referral_code}: #{result[:discount_id]}"
        add_customer_note_for_referral(referral, customer_provider)
      else
        Rails.logger.error "Failed to create generation: #{result[:errors]}"
      end
      return
    end

    result = provider.add_code_to_generation(
      code: referral.referral_code,
      generation: generation
    )

    if result[:success]
      referral.update(
        discount_generation: generation,
        shopify_discount_id: result[:discount_id],
        uses_shared_discount: true
      )
      Rails.logger.info "Added #{referral.referral_code} to generation #{generation.id}"
      add_customer_note_for_referral(referral, customer_provider)
    else
      Rails.logger.error "Discount creation failed: #{result[:errors]}"
    end
  rescue => e
    Rails.logger.error "Discount creation error: #{e.message}"
  end

  def add_customer_note_for_referral(referral, customer_provider)
    return unless referral.shopify_customer_id.present?
    return unless customer_provider  # Requires customer provider

    result = customer_provider.update_note(
      customer_id: referral.shopify_customer_id,
      note: "Referral Code: #{referral.referral_code}"
    )

    if result[:success]
      Rails.logger.info "Added note to customer #{referral.shopify_customer_id}: Referral Code: #{referral.referral_code}"
    else
      Rails.logger.error "Failed to add customer note: #{result[:errors]}"
    end
  rescue => e
    Rails.logger.error "Error adding customer note: #{e.message}"
  end

  def create_referrer_reward(referral, order_id: nil)
    return unless Current.shop  # Requires shop context

    discount_provider = Current.shop.discount_provider
    customer_provider = Current.shop.customer_provider

    # Look up customer ID if not already stored
    if referral.shopify_customer_id.blank?
      customer_id = customer_provider.lookup_by_email(referral.email)

      if customer_id
        referral.update!(shopify_customer_id: customer_id)
        Rails.logger.info "Found customer #{customer_id} for #{referral.email}"
      else
        Rails.logger.warn "No customer found for #{referral.email}, creating non-restricted reward"
      end
    end

    # Use effective reward values from the active group (considers override)
    group = SharedDiscount.current(Current.shop)
    reward_type = group&.effective_reward_type || "percentage"
    reward_value = group&.effective_reward_value || "50"

    # Create customer-specific reward (or general if no customer found)
    result = discount_provider.create_referrer_reward(
      referral_code: referral.referral_code,
      usage_number: referral.usage_count,
      customer_id: referral.shopify_customer_id,
      discount_type: reward_type,
      discount_value: reward_value
    )

    if result[:success]
      # Store the reward code on the referral (legacy)
      referral.referrer_reward_codes ||= []
      referral.referrer_reward_codes << result[:reward_code]
      referral.save!

      # Create ReferralReward record for lifecycle tracking
      shopify_discount_id = result.dig(:result, "data", "discountCodeBasicCreate", "codeDiscountNode", "id")
      reward = referral.referral_rewards.create!(
        code: result[:reward_code],
        shopify_discount_id: shopify_discount_id,
        shopify_order_id: order_id,
        status: "created",
        usage_number: referral.usage_count,
        expires_at: 30.days.from_now
      )

      Rails.logger.info "Created referrer reward #{result[:reward_code]} for #{referral.email} (customer-specific: #{referral.shopify_customer_id.present?})"

      track_klaviyo(:reward_earned, referral,
        reward_code: result[:reward_code],
        reward_value: reward_value,
        reward_type: reward_type,
        expires_at: 30.days.from_now
      )

      # Apply reward to subscription after a delay (allows discount to sync)
      RewardSubscriptionApplicationJob.set(wait: 10.seconds).perform_later(reward.id)

      # Add timeline comment to referrer's customer
      add_reward_timeline_note(referral, result[:reward_code], customer_provider)
    else
      Rails.logger.error "Failed to create referrer reward: #{result[:errors]}"
    end
  rescue => e
    Rails.logger.error "Error creating referrer reward: #{e.message}"
  end

  def add_reward_timeline_note(referral, reward_code, customer_provider)
    return unless referral.shopify_customer_id.present?
    return unless customer_provider  # Requires customer provider

    result = customer_provider.update_note(
      customer_id: referral.shopify_customer_id,
      note: "Referral code used on #{Date.today} - reward #{reward_code}",
      append: true
    )

    if result[:success]
      Rails.logger.info "Added timeline note for referral usage"
    else
      Rails.logger.error "Failed to add timeline note: #{result[:errors]}"
    end
  rescue => e
    Rails.logger.error "Error adding timeline note: #{e.message}"
  end
end
