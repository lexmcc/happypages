class ShopIntegration < ApplicationRecord
  PROVIDERS = %w[shopify woocommerce custom].freeze
  STATUSES = %w[active expired revoked].freeze

  belongs_to :shop

  encrypts :shopify_access_token
  encrypts :api_key
  encrypts :awtomic_api_key
  encrypts :klaviyo_api_key

  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :provider, uniqueness: { scope: :shop_id }

  scope :active, -> { where(status: "active") }

  def shopify?
    provider == "shopify"
  end

  def custom?
    provider == "custom"
  end
end
