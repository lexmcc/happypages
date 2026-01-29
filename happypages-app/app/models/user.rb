class User < ApplicationRecord
  belongs_to :shop
  has_secure_password validations: false  # Optional password for Shopify users

  validates :email, presence: true, uniqueness: true

  def shopify_user?
    shopify_user_id.present?
  end
end
