class AddSubscriptionAppliedAtToReferrals < ActiveRecord::Migration[8.0]
  def change
    add_column :referrals, :subscription_applied_at, :datetime
  end
end
