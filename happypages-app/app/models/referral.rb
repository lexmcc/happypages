class Referral < ApplicationRecord
  belongs_to :shop, optional: true  # Optional during transition
  belongs_to :discount_generation, optional: true
  has_many :referral_rewards, dependent: :destroy

  encrypts :email, deterministic: true
  encrypts :first_name

  before_validation :set_shop_from_current, on: :create
  before_validation :generate_referral_code, on: :create

  validates :first_name, presence: true
  validates :email, presence: true
  validates :referral_code, presence: true, uniqueness: { scope: :shop_id }

  private

  def set_shop_from_current
    self.shop ||= Current.shop
  end

  def generate_referral_code
    return if referral_code.present?

    sanitized_name = first_name.to_s.gsub(/[^a-zA-Z]/, "").capitalize
    sanitized_name = "User" if sanitized_name.blank?

    # Try up to 100 times to find a unique code
    100.times do
      suffix = format("%03d", rand(0..999))
      candidate = "#{sanitized_name}#{suffix}"

      unless Referral.where(shop_id: shop_id).exists?(referral_code: candidate)
        self.referral_code = candidate
        return
      end
    end

    # Fallback: Use timestamp if all random attempts fail (extremely rare)
    timestamp_suffix = Time.current.to_i.to_s[-6..]
    self.referral_code = "#{sanitized_name}#{timestamp_suffix}"
  end
end
