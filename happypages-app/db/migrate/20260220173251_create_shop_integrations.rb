class CreateShopIntegrations < ActiveRecord::Migration[8.1]
  def change
    create_table :shop_integrations do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :status, null: false, default: "active"
      t.string :shopify_domain
      t.string :shopify_access_token
      t.string :granted_scopes
      t.string :api_endpoint
      t.string :api_key
      t.string :webhook_secret
      t.string :awtomic_api_key
      t.string :awtomic_webhook_secret
      t.string :klaviyo_api_key

      t.timestamps
    end

    add_index :shop_integrations, [:shop_id, :provider], unique: true
    add_index :shop_integrations, :shopify_domain, where: "shopify_domain IS NOT NULL"
  end
end
