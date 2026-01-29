class AddCancelledAtToReferralRewards < ActiveRecord::Migration[8.0]
  def change
    add_column :referral_rewards, :cancelled_at, :datetime
  end
end
