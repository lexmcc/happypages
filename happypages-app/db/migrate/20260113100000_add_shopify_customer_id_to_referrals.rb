class AddShopifyCustomerIdToReferrals < ActiveRecord::Migration[8.0]
  def change
    add_column :referrals, :shopify_customer_id, :string
    add_index :referrals, :shopify_customer_id
  end
end
