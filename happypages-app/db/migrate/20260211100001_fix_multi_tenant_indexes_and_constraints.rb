class FixMultiTenantIndexesAndConstraints < ActiveRecord::Migration[8.1]
  def up
    # 1. Replace referrals.referral_code unique index → [shop_id, referral_code]
    remove_index :referrals, :referral_code, name: "index_referrals_on_referral_code"
    add_index :referrals, [ :shop_id, :referral_code ], unique: true

    # 2. Replace users.shopify_user_id unique index → [shop_id, shopify_user_id]
    remove_index :users, :shopify_user_id, name: "index_users_on_shopify_user_id"
    add_index :users, [ :shop_id, :shopify_user_id ], unique: true

    # 3. Replace referrals.email index → [shop_id, email]
    remove_index :referrals, :email, name: "index_referrals_on_email"
    add_index :referrals, [ :shop_id, :email ]

    # 4. Replace referrals.shopify_customer_id index → [shop_id, shopify_customer_id]
    remove_index :referrals, :shopify_customer_id, name: "index_referrals_on_shopify_customer_id"
    add_index :referrals, [ :shop_id, :shopify_customer_id ]

    # 5. Add NOT NULL to shop_id on referrals, shared_discounts, discount_configs, analytics_events
    # First delete any orphaned rows where shop_id IS NULL
    execute "DELETE FROM referrals WHERE shop_id IS NULL"
    execute "DELETE FROM shared_discounts WHERE shop_id IS NULL"
    execute "DELETE FROM discount_configs WHERE shop_id IS NULL"
    execute "DELETE FROM analytics_events WHERE shop_id IS NULL"

    change_column_null :referrals, :shop_id, false
    change_column_null :shared_discounts, :shop_id, false
    change_column_null :discount_configs, :shop_id, false
    change_column_null :analytics_events, :shop_id, false

    # 6. Add NOT NULL to audit_logs.shop_id
    execute "DELETE FROM audit_logs WHERE shop_id IS NULL"
    change_column_null :audit_logs, :shop_id, false

    # 7. Add NOT NULL to shops.slug
    execute "DELETE FROM shops WHERE slug IS NULL"
    change_column_null :shops, :slug, false
  end

  def down
    # Reverse index changes (restore original single-column indexes)

    # 1. Restore referrals.referral_code unique index
    remove_index :referrals, [ :shop_id, :referral_code ]
    add_index :referrals, :referral_code, unique: true, name: "index_referrals_on_referral_code"

    # 2. Restore users.shopify_user_id unique index
    remove_index :users, [ :shop_id, :shopify_user_id ]
    add_index :users, :shopify_user_id, unique: true, name: "index_users_on_shopify_user_id"

    # 3. Restore referrals.email index
    remove_index :referrals, [ :shop_id, :email ]
    add_index :referrals, :email, name: "index_referrals_on_email"

    # 4. Restore referrals.shopify_customer_id index
    remove_index :referrals, [ :shop_id, :shopify_customer_id ]
    add_index :referrals, :shopify_customer_id, name: "index_referrals_on_shopify_customer_id"

    # NOT NULL constraints are intentionally not reversed
  end
end
