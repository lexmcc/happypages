class CreateShops < ActiveRecord::Migration[8.1]
  def change
    create_table :shops do |t|
      t.string :name, null: false
      t.string :domain, null: false                    # Generic (was: shopify_domain)
      t.string :platform_type, null: false             # shopify, custom, woocommerce
      t.string :status, default: "active", null: false
      t.jsonb :platform_config, default: {}            # Platform-specific settings

      t.timestamps
    end

    add_index :shops, :domain, unique: true
    add_index :shops, :platform_type
    add_index :shops, :status
  end
end
