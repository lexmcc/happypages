class Admin::ConfigsController < Admin::BaseController

  def edit
    # Scope to current shop
    scope = DiscountConfig.all
    scope = scope.where(shop: Current.shop) if Current.shop
    @configs = scope.index_by(&:config_key)

    @config_keys = config_keys_with_labels
    @shared_discount_status = get_shared_discount_status
    @discount_groups = discount_groups_scope.includes(:discount_generations).order(is_active: :desc, created_at: :asc)
    @active_group = SharedDiscount.current(Current.shop)
    @shop = Current.shop
  end

  def update
    # Update shop slug if provided
    if params[:shop_slug].present? && Current.shop
      unless Current.shop.update(slug: params[:shop_slug])
        redirect_to edit_admin_config_path, alert: "Could not update slug: #{Current.shop.errors.full_messages.join(', ')}"
        return
      end
    end

    old_discount_config = current_discount_config

    (params[:configs] || {}).each do |key, value|
      next if value.blank? && !allow_blank_keys.include?(key)

      scope = DiscountConfig.all
      scope = scope.where(shop: Current.shop) if Current.shop
      config = scope.find_or_initialize_by(config_key: key)
      config.shop ||= Current.shop
      config.config_value = value
      config.save!
    end

    # Sync with platform if discount values changed
    sync_result = sync_discount_if_changed(old_discount_config)

    notice = "Configuration saved successfully!"
    notice += " Discount updated." if sync_result[:synced]
    notice += " (Sync failed: #{sync_result[:error]})" if sync_result[:error]

    redirect_to edit_admin_config_path, notice: notice
  end

  private

  def discount_groups_scope
    scope = SharedDiscount.all
    scope = scope.where(shop: Current.shop) if Current.shop
    scope
  end

  def get_shared_discount_status
    group = SharedDiscount.current(Current.shop)
    generation = group&.current_generation
    return { exists: false, synced: false } unless generation&.shopify_discount_id.present?

    return { exists: false, synced: false } unless Current.shop
    Current.shop.discount_provider.get_generation_status(generation)
  end

  def config_keys_with_labels
    {
      extension: {
        label: "Thank You Page Card",
        subtitle: "Displayed on the Shopify thank you page after checkout",
        fields: [
          { key: "extension_banner_image", label: "Banner Image URL", type: :url },
          { key: "extension_heading", label: "Heading", type: :text },
          { key: "extension_subtitle", label: "Subtitle", type: :text },
          { key: "extension_button_text", label: "Button Text", type: :text }
        ]
      },
      referred: {
        label: "Referee Discount",
        subtitle: "The discount given to the person using the code",
        fields: [
          { key: "referred_discount_type", label: "Type", type: :select, options: %w[percentage fixed_amount] },
          { key: "referred_discount_value", label: "Value", type: :number }
        ]
      },
      referrer: {
        label: "Referrer Reward",
        subtitle: "The reward given to the person who shared",
        fields: [
          { key: "referrer_reward_type", label: "Type", type: :select, options: %w[percentage fixed_amount] },
          { key: "referrer_reward_value", label: "Value", type: :number }
        ]
      },
      referral_page: {
        label: "Referral Page",
        subtitle: "Customize the /refer page appearance",
        fields: [
          { key: "referral_primary_color", label: "Primary Color", type: :color },
          { key: "referral_secondary_color", label: "Secondary Color", type: :color },
          { key: "referral_background_color", label: "Background Color", type: :color },
          { key: "referral_banner_image", label: "Banner Image URL", type: :url },
          { key: "referral_heading", label: "Heading", type: :text },
          { key: "referral_subtitle", label: "Subtitle", type: :text },
          { key: "referral_step_1", label: "Step 1", type: :text },
          { key: "referral_step_2", label: "Step 2", type: :text },
          { key: "referral_step_3", label: "Step 3", type: :text },
          { key: "referral_copy_button_text", label: "Copy Button", type: :text },
          { key: "referral_back_button_text", label: "Back Button", type: :text }
        ]
      },
      subscription: {
        label: "Subscription Rewards",
        subtitle: "Control what happens to applied rewards when subscriptions change status",
        fields: [
          { key: "subscription_pause_behavior", label: "On subscription pause", type: :select, options: %w[cancel keep] }
        ]
      }
    }
  end

  def allow_blank_keys
    %w[
      extension_banner_image
      referral_banner_image
      referral_heading
      referral_subtitle
      referral_step_1
      referral_step_2
      referral_step_3
      referral_copy_button_text
      referral_back_button_text
    ]
  end

  def current_discount_config
    scope = DiscountConfig.all
    scope = scope.where(shop: Current.shop) if Current.shop
    {
      referred_type: scope.find_by(config_key: "referred_discount_type")&.config_value,
      referred_value: scope.find_by(config_key: "referred_discount_value")&.config_value
    }
  end

  def sync_discount_if_changed(old_config)
    new_type = params.dig(:configs, :referred_discount_type)
    new_value = params.dig(:configs, :referred_discount_value)

    # Only sync if discount values actually changed
    return { synced: false } unless new_type.present? || new_value.present?

    discount_changed = (new_type.present? && new_type != old_config[:referred_type]) ||
                       (new_value.present? && new_value != old_config[:referred_value])

    return { synced: false } unless discount_changed

    # Check if there's an active group with a generation to update
    group = SharedDiscount.current(Current.shop)
    generation = group&.current_generation
    return { synced: false } unless generation&.shopify_discount_id.present?

    return { synced: false } unless Current.shop
    result = Current.shop.discount_provider.update_generation_discount(
      generation: generation,
      discount_type: new_type || old_config[:referred_type] || "percentage",
      discount_value: new_value || old_config[:referred_value] || "50"
    )

    if result[:success]
      Rails.logger.info "Updated discount in platform"
      { synced: true }
    else
      Rails.logger.error "Failed to sync discount: #{result[:errors]}"
      { synced: false, error: result[:errors]&.first&.dig("message") || "Unknown error" }
    end
  rescue => e
    Rails.logger.error "Discount sync error: #{e.message}"
    { synced: false, error: e.message }
  end
end
