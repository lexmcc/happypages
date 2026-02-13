require "rack/cors"

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow requests from Shopify checkout domains and custom storefront domains
    shopify_origins = [
      /\Ahttps:\/\/.*\.shopify\.com\z/,
      /\Ahttps:\/\/.*\.myshopify\.com\z/
    ]

    custom_origins = ENV.fetch("CORS_ALLOWED_ORIGINS", "")
      .split(",")
      .map(&:strip)
      .reject(&:empty?)

    origins(*shopify_origins, *custom_origins)

    resource "/api/referrals",
      headers: :any,
      methods: [:post, :options]
  end

  # Config endpoint needs to allow all origins for checkout extensions
  # Per Shopify docs: "requests could originate from anywhere on the Internet"
  allow do
    origins "*"

    resource "/api/config",
      headers: :any,
      methods: [:get, :options]
  end

  # Analytics endpoint for tracking events from checkout extension
  allow do
    origins "*"

    resource "/api/analytics",
      headers: :any,
      methods: [:post, :options]
  end
end
