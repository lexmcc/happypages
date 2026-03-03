class AddOrderTotalCentsToReferralRewards < ActiveRecord::Migration[8.0]
  def change
    add_column :referral_rewards, :order_total_cents, :integer
  end
end
