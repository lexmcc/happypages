class User < ApplicationRecord
  ROLES = %w[owner admin member].freeze

  include Authenticatable

  belongs_to :shop
  has_many :notifications, as: :recipient, dependent: :destroy

  validates :email, presence: true, uniqueness: { scope: :shop_id }
  validates :role, inclusion: { in: ROLES }, allow_nil: true

  def shopify_user?
    shopify_user_id.present?
  end

  def notification_muted?(action)
    notification_preferences.dig(action.to_s) == false
  end

  def unread_notification_count
    notifications.unread.count
  end
end
