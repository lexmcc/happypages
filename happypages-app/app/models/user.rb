class User < ApplicationRecord
  belongs_to :shop
  has_secure_password validations: false  # Optional password for Shopify users

  validates :email, presence: true, uniqueness: { scope: :shop_id }

  def shopify_user?
    shopify_user_id.present?
  end
end
