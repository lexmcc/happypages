class MigrateShopCredentialsToIntegrations < ActiveRecord::Migration[8.1]
  def up
    Shop.find_each do |shop|
      # Create ShopIntegration from ShopCredential
      credential = shop.shop_credential
      if credential
        ShopIntegration.create!(
          shop: shop,
          provider: shop.platform_type,
          status: "active",
          shopify_domain: shop.domain,
          shopify_access_token: credential.shopify_access_token,
          granted_scopes: credential.granted_scopes,
          api_endpoint: credential.api_endpoint,
          api_key: credential.api_key,
          webhook_secret: credential.webhook_secret,
          awtomic_api_key: credential.awtomic_api_key,
          awtomic_webhook_secret: credential.awtomic_webhook_secret,
          klaviyo_api_key: credential.klaviyo_api_key
        )
      end

      # Create default ShopFeatures
      ShopFeature.create!(shop: shop, feature: "referrals", status: "active", activated_at: shop.created_at)
      ShopFeature.create!(shop: shop, feature: "analytics", status: "active", activated_at: shop.created_at)
    end
  end

  def down
    ShopIntegration.delete_all
    ShopFeature.delete_all
  end
end
