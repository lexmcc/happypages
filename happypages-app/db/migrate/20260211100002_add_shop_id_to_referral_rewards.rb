class AddShopIdToReferralRewards < ActiveRecord::Migration[8.1]
  def up
    add_reference :referral_rewards, :shop, foreign_key: true

    # Backfill from referrals
    execute <<~SQL
      UPDATE referral_rewards
      SET shop_id = referrals.shop_id
      FROM referrals
      WHERE referral_rewards.referral_id = referrals.id
    SQL

    # Delete orphans (shouldn't exist, but defensive)
    execute "DELETE FROM referral_rewards WHERE shop_id IS NULL"

    change_column_null :referral_rewards, :shop_id, false

    # Replace global unique with shop-scoped unique
    remove_index :referral_rewards, :code, name: "index_referral_rewards_on_code"
    add_index :referral_rewards, [:shop_id, :code], unique: true
  end

  def down
    remove_index :referral_rewards, [:shop_id, :code]
    add_index :referral_rewards, :code, unique: true, name: "index_referral_rewards_on_code"
    remove_reference :referral_rewards, :shop
  end
end
