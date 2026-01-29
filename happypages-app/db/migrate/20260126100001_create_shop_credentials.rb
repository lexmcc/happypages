class CreateShopCredentials < ActiveRecord::Migration[8.1]
  def change
    create_table :shop_credentials do |t|
      t.references :shop, null: false, foreign_key: true

      # Shopify-specific (when platform_type = "shopify")
      t.string :shopify_access_token
      t.string :shopify_webhook_secret

      # Generic platform credentials (for custom platforms)
      t.string :api_endpoint              # Custom platform API URL
      t.string :api_key                   # Generic API key
      t.string :webhook_secret            # Generic webhook verification

      # Third-party integrations (platform-agnostic)
      t.string :awtomic_api_key
      t.string :awtomic_webhook_secret
      t.string :klaviyo_api_key

      t.timestamps
    end
  end
end
