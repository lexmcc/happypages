class AddReminderSentAtToReferrals < ActiveRecord::Migration[8.0]
  def change
    add_column :referrals, :reminder_sent_at, :datetime
  end
end
