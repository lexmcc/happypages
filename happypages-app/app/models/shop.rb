class Shop < ApplicationRecord
  STATUSES = %w[active suspended uninstalled].freeze
  PLATFORM_TYPES = %w[shopify custom woocommerce].freeze

  has_one :shop_credential, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :shared_discounts, dependent: :destroy
  has_many :discount_configs, dependent: :destroy
  has_many :analytics_events, dependent: :destroy
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

  # Credential accessors - used by services
  def shopify_credentials
    return nil unless shopify?
    {
      url: domain,
      token: shop_credential&.shopify_access_token
    }
  end

  def platform_credentials
    case platform_type
    when "shopify"
      shopify_credentials
    when "custom"
      {
        endpoint: shop_credential&.api_endpoint,
        api_key: shop_credential&.api_key
      }
    end
  end

  def awtomic_credentials
    { api_key: shop_credential&.awtomic_api_key }
  end

  def klaviyo_credentials
    { api_key: shop_credential&.klaviyo_api_key }
  end

  def webhook_secret
    case platform_type
    when "shopify" then shop_credential&.shopify_webhook_secret
    else shop_credential&.webhook_secret
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
