class AddReferrerRewardsToReferrals < ActiveRecord::Migration[8.0]
  def change
    add_column :referrals, :referrer_reward_codes, :text, array: true, default: []
  end
end
