class User < ApplicationRecord
  ROLES = %w[owner admin member].freeze

  belongs_to :shop
  has_secure_password validations: false  # Optional password for Shopify users

  validates :email, presence: true, uniqueness: { scope: :shop_id }
  validates :role, inclusion: { in: ROLES }, allow_nil: true

  def shopify_user?
    shopify_user_id.present?
  end
end
