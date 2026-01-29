class Admin::DiscountGroupsController < Admin::BaseController

  def new
    @group = SharedDiscount.new(
      referred_discount_type: "percentage",
      referred_discount_value: "50",
      referrer_reward_type: "percentage",
      referrer_reward_value: "50",
      shop: Current.shop
    )
  end

  def create
    @group = SharedDiscount.new(group_params)
    @group.discount_type = "referred"
    @group.shop = Current.shop

    if @group.save
      # Auto-activate if it's the first group for this shop
      @group.activate! if discount_groups_scope.count == 1

      redirect_to edit_admin_config_path, notice: "Discount group '#{@group.name}' created successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @group = find_group(params[:id])
  end

  def update
    @group = find_group(params[:id])
    old_referred = {
      type: @group.referred_discount_type,
      value: @group.referred_discount_value
    }

    if @group.update(group_params)
      # Check if referred discount changed (needs grandfathering)
      if referred_discount_changed?(old_referred)
        create_new_generation_for_group(@group)
      end

      redirect_to edit_admin_config_path, notice: "Discount group '#{@group.name}' updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def activate
    @group = find_group(params[:id])
    @group.activate!
    redirect_to edit_admin_config_path, notice: "'#{@group.name}' is now the active discount group."
  end

  def schedule_override
    @group = find_group(params[:id])

    # Validate boost values before saving
    errors = []

    if params[:override_referred_value].blank?
      errors << "Boost referred value can't be blank"
    elsif params[:override_referred_type] == "percentage" && params[:override_referred_value].to_f > 100
      errors << "Boost referred value cannot exceed 100%"
    end

    if params[:override_reward_value].blank?
      errors << "Boost reward value can't be blank"
    elsif params[:override_reward_type] == "percentage" && params[:override_reward_value].to_f > 100
      errors << "Boost reward value cannot exceed 100%"
    end

    if errors.any?
      redirect_to edit_admin_discount_group_path(@group), alert: errors.join(", ")
      return
    end

    @group.update!(
      override_referred_type: params[:override_referred_type],
      override_referred_value: params[:override_referred_value],
      override_reward_type: params[:override_reward_type],
      override_reward_value: params[:override_reward_value],
      override_starts_at: params[:override_starts_at],
      override_ends_at: params[:override_ends_at],
      override_applied: false
    )

    # If start time is now or in past, apply immediately
    if @group.override_starts_at <= Time.current
      @group.apply_override_to_shopify!
      @group.update!(override_applied: true)
      redirect_to edit_admin_config_path, notice: "Boost activated immediately!"
    else
      redirect_to edit_admin_config_path, notice: "Boost scheduled: #{@group.override_starts_at.strftime('%b %d')} to #{@group.override_ends_at.strftime('%b %d')}"
    end
  rescue => e
    redirect_to edit_admin_config_path, alert: "Failed to schedule boost: #{e.message}"
  end

  def cancel_override
    @group = find_group(params[:id])
    @group.clear_override!
    redirect_to edit_admin_config_path, notice: "Boost cancelled for '#{@group.name}'."
  rescue => e
    redirect_to edit_admin_config_path, alert: "Failed to cancel boost: #{e.message}"
  end

  private

  def discount_groups_scope
    scope = SharedDiscount.all
    scope = scope.where(shop: Current.shop) if Current.shop
    scope
  end

  def find_group(id)
    discount_groups_scope.find(id)
  end

  def group_params
    params.require(:shared_discount).permit(
      :name,
      :referred_discount_type,
      :referred_discount_value,
      :referrer_reward_type,
      :referrer_reward_value,
      :applies_on_subscription,
      :applies_on_one_time_purchase
    )
  end

  def referred_discount_changed?(old_referred)
    @group.referred_discount_type != old_referred[:type] ||
      @group.referred_discount_value != old_referred[:value]
  end

  def create_new_generation_for_group(group)
    return unless group.current_generation.present?

    # Only create new generation if there are existing codes
    return if group.current_generation.codes_count.zero?

    return unless Current.shop  # Requires shop context
    provider = Current.shop.discount_provider

    # Create a placeholder code for the new generation
    # The actual codes will be added when new referrals are created
    placeholder_code = "GEN#{group.id}-#{Time.current.to_i}"

    result = provider.create_generation_discount(
      group: group,
      initial_code: placeholder_code
    )

    if result[:success]
      Rails.logger.info "Created new generation for group #{group.name}: #{result[:discount_id]}"
    else
      Rails.logger.error "Failed to create new generation: #{result[:errors]}"
    end
  rescue => e
    Rails.logger.error "Error creating new generation: #{e.message}"
  end
end
