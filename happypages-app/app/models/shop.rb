class Shop < ApplicationRecord
  STATUSES = %w[active suspended uninstalled].freeze
  PLATFORM_TYPES = %w[shopify custom woocommerce].freeze

  has_one :shop_credential, dependent: :destroy
  has_many :shop_features, dependent: :destroy
  has_many :shop_integrations, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :shared_discounts, dependent: :destroy
  has_many :discount_configs, dependent: :destroy
  has_many :referral_events, dependent: :destroy
  has_many :analytics_sites, class_name: "Analytics::Site", dependent: :destroy
  has_many :referrals, dependent: :destroy
  has_many :referral_rewards, dependent: :destroy
  has_many :audit_logs, dependent: :destroy
  has_many :media_assets, dependent: :destroy
  has_many :generation_logs, dependent: :destroy
  has_many :customer_imports, dependent: :destroy

  validates :name, presence: true
  validates :domain, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :platform_type, presence: true, inclusion: { in: PLATFORM_TYPES }
  validates :slug, uniqueness: true, allow_nil: true
  validates :slug, length: { minimum: 3, maximum: 50 }, allow_nil: true
  validates :slug, format: { with: /\A[a-z0-9-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" }, allow_nil: true

  before_validation :generate_slug

  scope :active, -> { where(status: "active") }
  scope :shopify, -> { where(platform_type: "shopify") }
  scope :custom, -> { where(platform_type: "custom") }

  # Feature & integration helpers
  def feature_enabled?(feature_name)
    shop_features.active.exists?(feature: feature_name)
  end

  def integration_for(provider)
    shop_integrations.active.find_by(provider: provider)
  end

  def self.find_by_shopify_domain(domain)
    joins(:shop_integrations)
      .where(shop_integrations: { shopify_domain: domain, provider: "shopify" })
      .first
  end

  # Credential accessors - read from ShopIntegration first, fall back to ShopCredential
  def shopify_credentials
    return nil unless shopify?
    integration = integration_for("shopify")
    if integration
      { url: integration.shopify_domain, token: integration.shopify_access_token }
    else
      { url: domain, token: shop_credential&.shopify_access_token }
    end
  end

  def platform_credentials
    case platform_type
    when "shopify"
      shopify_credentials
    when "custom"
      integration = integration_for("custom")
      if integration
        { endpoint: integration.api_endpoint, api_key: integration.api_key }
      else
        { endpoint: shop_credential&.api_endpoint, api_key: shop_credential&.api_key }
      end
    end
  end

  def awtomic_credentials
    integration = integration_for(platform_type)
    if integration&.awtomic_api_key.present?
      { api_key: integration.awtomic_api_key }
    else
      { api_key: shop_credential&.awtomic_api_key }
    end
  end

  def klaviyo_credentials
    integration = integration_for(platform_type)
    if integration&.klaviyo_api_key.present?
      { api_key: integration.klaviyo_api_key }
    else
      { api_key: shop_credential&.klaviyo_api_key }
    end
  end

  def webhook_secret
    integration = integration_for(platform_type)
    if integration
      integration.webhook_secret
    else
      case platform_type
      when "shopify" then shop_credential&.shopify_webhook_secret
      else shop_credential&.webhook_secret
      end
    end
  end

  # Provider accessors
  def discount_provider
    @discount_provider ||= provider_class("DiscountProvider").new(self)
  end

  def customer_provider
    @customer_provider ||= provider_class("CustomerProvider").new(self)
  end

  def order_handler
    @order_handler ||= provider_class("OrderHandler").new(self)
  end

  def customer_facing_url
    storefront_url.presence || "https://#{domain}"
  end

  # Platform type helpers
  def shopify?
    platform_type == "shopify"
  end

  def custom?
    platform_type == "custom"
  end

  # Brand profile accessors (brand_profile defaults to {} via migration)
  def brand_colors    = (brand_profile || {})["palette"] || []
  def brand_category  = (brand_profile || {})["category"]
  def brand_logo_url  = (brand_profile || {})["logo_url"]
  def brand_products  = (brand_profile || {})["products"] || []
  def brand_vibe      = (brand_profile || {})["vibe"]
  def brand_style     = (brand_profile || {})["style"]
  def brand_scraped?  = (brand_profile || {})["scraped_at"].present?

  # Credit methods
  def can_generate?
    generation_credits_remaining.to_i > 0
  end

  def use_credit!
    # Atomic decrement — only succeeds if credits > 0
    rows = self.class.where(id: id).where("generation_credits_remaining > 0")
      .update_all("generation_credits_remaining = generation_credits_remaining - 1")
    raise "No generation credits remaining" if rows == 0
    reload
  end

  def reset_credits!(amount = 10)
    update!(generation_credits_remaining: amount, credits_reset_at: Time.current)
  end

  # Status helpers
  def active?
    status == "active"
  end

  def suspended?
    status == "suspended"
  end

  def uninstalled?
    status == "uninstalled"
  end

  private

  def provider_class(name)
    "Providers::#{platform_type.camelize}::#{name}".constantize
  end

  def generate_slug
    return if slug.present?
    return unless name.present?

    base_slug = name.parameterize
    candidate = base_slug
    counter = 1

    while Shop.exists?(slug: candidate)
      candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate
  end
end
