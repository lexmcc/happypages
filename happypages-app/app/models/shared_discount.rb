class SharedDiscount < ApplicationRecord
  belongs_to :shop, optional: true  # Optional during transition

  before_validation :set_shop_from_current, on: :create

  has_many :discount_generations, dependent: :destroy
  has_one :current_generation, -> { where(is_current: true) }, class_name: "DiscountGeneration"

  validates :name, presence: true
  validates :referred_discount_value, presence: true
  validates :referrer_reward_value, presence: true
  validates :referred_discount_type, inclusion: { in: %w[percentage fixed_amount] }, allow_nil: true
  validates :referrer_reward_type, inclusion: { in: %w[percentage fixed_amount] }, allow_nil: true
  validates :override_referred_type, inclusion: { in: %w[percentage fixed_amount] }, allow_nil: true
  validates :override_reward_type, inclusion: { in: %w[percentage fixed_amount] }, allow_nil: true
  validate :percentage_values_within_range

  scope :active, -> { where(is_active: true) }

  # Returns the current active discount for the given shop
  # Falls back to global lookup if no shop provided (backward compatibility)
  def self.current(shop = nil)
    scope = active
    scope = scope.where(shop: shop) if shop
    scope.first
  end

  # Effective values consider override if active
  def effective_referred_type
    override_active? ? override_referred_type : referred_discount_type
  end

  def effective_referred_value
    override_active? ? override_referred_value : referred_discount_value
  end

  def effective_reward_type
    override_active? ? override_reward_type : referrer_reward_type
  end

  def effective_reward_value
    override_active? ? override_reward_value : referrer_reward_value
  end

  # Override status checks
  def override_active?
    return false unless override_starts_at && override_ends_at
    Time.current.between?(override_starts_at, override_ends_at) && override_applied?
  end

  def override_scheduled?
    override_starts_at.present? && override_starts_at > Time.current
  end

  def override_expired?
    override_ends_at.present? && override_ends_at < Time.current
  end

  def override_pending?
    override_starts_at.present? && !override_applied?
  end

  # Apply override to platform (updates the current generation's discount)
  def apply_override_to_shopify!
    return unless current_generation&.shopify_discount_id.present?
    return unless shop  # Requires shop association

    shop.discount_provider.update_generation_discount(
      generation: current_generation,
      discount_type: override_referred_type,
      discount_value: override_referred_value
    )
  end

  # Clear override and revert to base rates
  def clear_override!
    # Revert to base rates (only if we have a synced generation and shop)
    if current_generation&.shopify_discount_id.present? && shop
      shop.discount_provider.update_generation_discount(
        generation: current_generation,
        discount_type: referred_discount_type,
        discount_value: referred_discount_value
      )
    end

    # Always clear override fields
    update!(
      override_referred_type: nil,
      override_referred_value: nil,
      override_reward_type: nil,
      override_reward_value: nil,
      override_starts_at: nil,
      override_ends_at: nil,
      override_applied: false
    )
  end

  # Activate this group (deactivates all others for this shop)
  def activate!
    transaction do
      scope = SharedDiscount.all
      scope = scope.where(shop_id: shop_id) if shop_id
      scope.update_all(is_active: false)
      update!(is_active: true)
    end
  end

  # Create new generation (for grandfathering when referred discount changes)
  def create_new_generation!(shopify_discount_id:)
    discount_generations.update_all(is_current: false)
    discount_generations.create!(
      shopify_discount_id: shopify_discount_id,
      referred_discount_type: referred_discount_type,
      referred_discount_value: referred_discount_value,
      is_current: true
    )
  end

  # Format discount for display
  def referred_discount_display
    format_discount(referred_discount_type, referred_discount_value)
  end

  def referrer_reward_display
    format_discount(referrer_reward_type, referrer_reward_value)
  end

  def override_referred_display
    format_discount(override_referred_type, override_referred_value)
  end

  def override_reward_display
    format_discount(override_reward_type, override_reward_value)
  end

  private

  def set_shop_from_current
    self.shop ||= Current.shop
  end

  def format_discount(type, value)
    return "Not set" unless type && value
    type == "percentage" ? "#{value}%" : "£#{value}"
  end

  def percentage_values_within_range
    if referred_discount_type == "percentage" && referred_discount_value.to_f > 100
      errors.add(:referred_discount_value, "cannot exceed 100%")
    end
    if referrer_reward_type == "percentage" && referrer_reward_value.to_f > 100
      errors.add(:referrer_reward_value, "cannot exceed 100%")
    end
  end
end
