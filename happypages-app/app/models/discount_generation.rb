class DiscountGeneration < ApplicationRecord
  belongs_to :shared_discount
  has_many :referrals

  scope :current, -> { where(is_current: true) }

  validates :referred_discount_type, presence: true, inclusion: { in: %w[percentage fixed_amount] }
  validates :referred_discount_value, presence: true

  def discount_display
    referred_discount_type == "percentage" ? "#{referred_discount_value}%" : "£#{referred_discount_value}"
  end

  def synced?
    shopify_discount_id.present?
  end

  def codes_count
    referrals.count
  end
end
