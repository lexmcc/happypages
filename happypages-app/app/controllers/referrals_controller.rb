class ReferralsController < ApplicationController
  include KlaviyoTrackable
  layout "public"

  before_action :set_shop_from_slug

  def show
    first_name = params[:firstName].presence || params[:first_name].presence
    email = params[:email].presence

    if first_name.blank? || email.blank?
      @error = "Missing required parameters. Please access this page from the checkout confirmation."
      return render :error
    end

    # Find existing referral by email or create new one - scope to shop
    scope = Referral.all
    scope = scope.where(shop: Current.shop) if Current.shop
    @referral = scope.find_by(email: email)

    if @referral.nil?
      @referral = Referral.new(first_name: first_name, email: email, shop: Current.shop)

      if @referral.save
        create_discount(@referral)
        add_customer_note(@referral)
        track_klaviyo(:referral_created, @referral)
      else
        @error = "Could not create referral: #{@referral.errors.full_messages.join(', ')}"
        return render :error
      end
    end

    # Track page view
    track_page_load(@referral)

    # Load active discount group and display values
    @active_group = SharedDiscount.current(Current.shop)
    @discount_display = @active_group&.referred_discount_display || "50%"
    @reward_display = @active_group&.referrer_reward_display || "50%"

    # Load rewards ordered by status: available first, then consumed
    @rewards = @referral.referral_rewards.order(
      Arel.sql("CASE status WHEN 'created' THEN 0 WHEN 'applied_to_subscription' THEN 1 WHEN 'consumed' THEN 2 ELSE 3 END"),
      :created_at
    )

    # Load referral page configs - scope to shop
    config_scope = DiscountConfig.where(config_key: ReferralsHelper::REFERRAL_DEFAULTS.keys)
    config_scope = config_scope.where(shop: Current.shop) if Current.shop
    @referral_configs = config_scope.pluck(:config_key, :config_value)
                                    .to_h
                                    .transform_values { |v| { value: v } }
  end

  private

  def set_shop_from_slug
    return unless params[:shop_slug].present?

    shop = Shop.active.find_by(slug: params[:shop_slug])
    if shop
      Current.shop = shop
    else
      @error = "Shop not found"
      render :error, status: :not_found
    end
  end

  def track_page_load(referral)
    AnalyticsEvent.create(
      event_type: AnalyticsEvent::PAGE_LOAD,
      source: AnalyticsEvent::REFERRAL_PAGE,
      email: referral.email,
      referral_code: referral.referral_code,
      shop: Current.shop
    )
  rescue => e
    Rails.logger.error "Analytics tracking error: #{e.message}"
  end

  def create_discount(referral)
    group = SharedDiscount.current(Current.shop)

    unless group
      Rails.logger.warn "No active discount group, skipping discount creation"
      return
    end

    return unless Current.shop  # Requires shop context
    provider = Current.shop.discount_provider
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
    else
      Rails.logger.error "Discount creation failed: #{result[:errors]}"
    end
  rescue => e
    Rails.logger.error "Discount creation error: #{e.message}"
  end

  def add_customer_note(referral)
    return unless Current.shop  # Requires shop context

    customer_provider = Current.shop.customer_provider
    customer_id = customer_provider.lookup_by_email(referral.email)

    if customer_id
      referral.update(shopify_customer_id: customer_id)

      result = customer_provider.update_note(
        customer_id: customer_id,
        note: "Referral Code: #{referral.referral_code}"
      )

      if result[:success]
        Rails.logger.info "Added note to customer #{customer_id}: Referral Code: #{referral.referral_code}"
      else
        Rails.logger.error "Failed to add customer note: #{result[:errors]}"
      end
    else
      Rails.logger.warn "No customer found for #{referral.email}, skipping note"
    end
  rescue => e
    Rails.logger.error "Error adding customer note: #{e.message}"
  end
end
