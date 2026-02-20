namespace :shop do
  desc "Create Shop record from existing ENV credentials and backfill existing data"
  task setup: :environment do
    shop_url = ENV["SHOPIFY_SHOP_URL"]

    if shop_url.blank?
      puts "ERROR: SHOPIFY_SHOP_URL environment variable not set"
      exit 1
    end

    # Extract shop name from domain (e.g., "my-store.myshopify.com" -> "My Store")
    shop_name = shop_url.split(".").first.titleize

    puts "Setting up shop: #{shop_name} (#{shop_url})"

    ActiveRecord::Base.transaction do
      # Create or find the shop
      shop = Shop.find_or_initialize_by(domain: shop_url)
      shop.assign_attributes(
        name: shop_name,
        platform_type: "shopify",
        status: "active"
      )

      if shop.new_record?
        shop.save!
        puts "✓ Created Shop: #{shop.name} (ID: #{shop.id})"
      else
        shop.save!
        puts "✓ Found existing Shop: #{shop.name} (ID: #{shop.id})"
      end

      # Create or update credentials (legacy)
      credential = shop.shop_credential || shop.build_shop_credential
      credential.assign_attributes(
        shopify_access_token: ENV["SHOPIFY_ACCESS_TOKEN"],
        shopify_webhook_secret: nil, # Shopify signs webhooks with client secret (ENV["SHOPIFY_CLIENT_SECRET"])
        awtomic_api_key: ENV["AWTOMIC_API_KEY"],
        awtomic_webhook_secret: ENV["AWTOMIC_WEBHOOK_SECRET"],
        klaviyo_api_key: ENV["KLAVIYO_API_KEY"]
      )
      credential.save!
      puts "✓ Configured ShopCredential"

      # Create or update ShopIntegration
      integration = shop.shop_integrations.find_or_initialize_by(provider: "shopify")
      integration.assign_attributes(
        status: "active",
        shopify_domain: shop_url,
        shopify_access_token: ENV["SHOPIFY_ACCESS_TOKEN"],
        awtomic_api_key: ENV["AWTOMIC_API_KEY"],
        awtomic_webhook_secret: ENV["AWTOMIC_WEBHOOK_SECRET"],
        klaviyo_api_key: ENV["KLAVIYO_API_KEY"]
      )
      integration.save!
      puts "✓ Configured ShopIntegration"

      # Ensure default features exist
      %w[referrals analytics].each do |feature|
        shop.shop_features.find_or_create_by!(feature: feature) do |sf|
          sf.status = "active"
          sf.activated_at = shop.created_at
        end
      end
      puts "✓ Configured ShopFeatures"

      # Backfill existing records
      puts "\nBackfilling existing records..."

      updated = SharedDiscount.where(shop_id: nil).update_all(shop_id: shop.id)
      puts "  - SharedDiscount: #{updated} records"

      updated = DiscountConfig.where(shop_id: nil).update_all(shop_id: shop.id)
      puts "  - DiscountConfig: #{updated} records"

      updated = Referral.where(shop_id: nil).update_all(shop_id: shop.id)
      puts "  - Referral: #{updated} records"

      updated = ReferralEvent.where(shop_id: nil).update_all(shop_id: shop.id)
      puts "  - ReferralEvent: #{updated} records"

      puts "\n✓ Shop setup complete!"
      puts "\nShop ID: #{shop.id}"
      puts "Domain: #{shop.domain}"
      puts "Platform: #{shop.platform_type}"
    end
  end

  desc "Show current shop configuration"
  task info: :environment do
    shops = Shop.includes(:shop_credential, :shop_integrations, :shop_features).all

    if shops.empty?
      puts "No shops configured. Run `rails shop:setup` to create one."
      exit
    end

    shops.each do |shop|
      puts "=" * 50
      puts "Shop: #{shop.name}"
      puts "  ID: #{shop.id}"
      puts "  Domain: #{shop.domain}"
      puts "  Platform: #{shop.platform_type}"
      puts "  Status: #{shop.status}"
      puts "  Created: #{shop.created_at}"
      puts ""
      puts "  Integrations:"
      if shop.shop_integrations.any?
        shop.shop_integrations.each do |integration|
          puts "    #{integration.provider} (#{integration.status}):"
          puts "      Shopify Domain: #{integration.shopify_domain || 'N/A'}"
          puts "      Shopify Token: #{integration.shopify_access_token.present? ? '✓ Set' : '✗ Not set'}"
          puts "      Awtomic Key: #{integration.awtomic_api_key.present? ? '✓ Set' : '✗ Not set'}"
          puts "      Klaviyo Key: #{integration.klaviyo_api_key.present? ? '✓ Set' : '✗ Not set'}"
        end
      else
        puts "    No integrations configured"
      end
      puts ""
      puts "  Legacy Credentials:"
      cred = shop.shop_credential
      if cred
        puts "    Shopify Token: #{cred.shopify_access_token.present? ? '✓ Set' : '✗ Not set'}"
        puts "    Awtomic Key: #{cred.awtomic_api_key.present? ? '✓ Set' : '✗ Not set'}"
        puts "    Klaviyo Key: #{cred.klaviyo_api_key.present? ? '✓ Set' : '✗ Not set'}"
      else
        puts "    No legacy credentials"
      end
      puts ""
      puts "  Features:"
      if shop.shop_features.any?
        shop.shop_features.each do |feature|
          puts "    #{feature.feature}: #{feature.status}"
        end
      else
        puts "    No features configured"
      end
      puts ""
      puts "  Record counts:"
      puts "    SharedDiscounts: #{shop.shared_discounts.count}"
      puts "    Referrals: #{shop.referrals.count}"
      puts "    ReferralEvents: #{shop.referral_events.count}"
      puts "    DiscountConfigs: #{shop.discount_configs.count}"
    end
  end

  desc "Clean up orphan shops without credentials or integrations"
  task cleanup: :environment do
    # Find shops with credentials OR integrations
    shops_with_creds = Shop.joins(:shop_credential).pluck(:id)
    shops_with_integrations = Shop.joins(:shop_integrations).pluck(:id)
    shops_with_either = (shops_with_creds + shops_with_integrations).uniq
    orphans = Shop.where.not(id: shops_with_either)

    if orphans.empty?
      puts "No orphan shops found. All shops have credentials or integrations."
      exit
    end

    puts "Found #{orphans.count} orphan shops (no credentials or integrations):"
    orphans.each do |shop|
      puts "  - ID #{shop.id}: #{shop.domain}"
    end

    puts "\nDeleting orphan shops..."
    orphans.destroy_all

    puts "✓ Cleanup complete!"
    puts "\nRemaining shops:"
    Shop.includes(:shop_credential, :shop_integrations).each do |shop|
      puts "  - ID #{shop.id}: #{shop.domain} (integration: #{shop.shop_integrations.any?}, legacy_credential: #{shop.shop_credential.present?})"
    end
  end
end
