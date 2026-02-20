class ReferralReward < ApplicationRecord
  belongs_to :referral
  belongs_to :shop

  STATUSES = %w[created applied_to_subscription consumed expired released cancelled].freeze

  validates :code, presence: true, uniqueness: { scope: :shop_id }

  before_validation :set_shop_from_referral, on: :create
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :usage_number, presence: true

  scope :unapplied, -> { where(status: "created") }
  scope :applied, -> { where(status: "applied_to_subscription") }
  scope :not_expired, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :expired_but_not_marked, -> { where(status: %w[created applied_to_subscription]).where("expires_at <= ?", Time.current) }
  scope :for_subscription, ->(subscription_id) {
    where(awtomic_subscription_id: [ subscription_id, "gid://shopify/SubscriptionContract/#{subscription_id}" ])
  }

  def mark_applied!(subscription_id:, customer_id:)
    update!(
      status: "applied_to_subscription",
      awtomic_subscription_id: subscription_id,
      awtomic_customer_id: customer_id,
      applied_at: Time.current
    )
  end

  def mark_consumed!
    update!(
      status: "consumed",
      consumed_at: Time.current
    )
  end

  def mark_released!
    update!(
      status: "released",
      awtomic_subscription_id: nil,
      awtomic_customer_id: nil,
      applied_at: nil
    )
  end

  def mark_cancelled!
    update!(
      status: "cancelled",
      cancelled_at: Time.current
    )
  end

  def mark_expired!
    update!(status: "expired")
  end

  def applied?
    status == "applied_to_subscription"
  end

  def consumed?
    status == "consumed"
  end

  def cancelled?
    status == "cancelled"
  end

  def expired?
    status == "expired" || (expires_at.present? && expires_at <= Time.current)
  end

  private

  def set_shop_from_referral
    self.shop_id ||= referral&.shop_id
  end
end
