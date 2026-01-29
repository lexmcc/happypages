class AddShopifyOrderIdToReferralRewards < ActiveRecord::Migration[8.1]
  def change
    add_column :referral_rewards, :shopify_order_id, :string
    add_index :referral_rewards, [:referral_id, :shopify_order_id], unique: true
  end
end
