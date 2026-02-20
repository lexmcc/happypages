class RenameAnalyticsEventsToReferralEvents < ActiveRecord::Migration[8.1]
  def change
    rename_table :analytics_events, :referral_events
  end
end
