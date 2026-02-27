class ShopIntegration < ApplicationRecord
  PROVIDERS = %w[shopify woocommerce custom linear].freeze
  STATUSES = %w[active expired revoked].freeze

  belongs_to :shop

  encrypts :shopify_access_token
  encrypts :api_key
  encrypts :awtomic_api_key
  encrypts :klaviyo_api_key
  encrypts :linear_access_token
  encrypts :linear_webhook_secret

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

  def linear?
    provider == "linear"
  end

  def linear_connected?
    linear? && linear_access_token.present?
  end
end
