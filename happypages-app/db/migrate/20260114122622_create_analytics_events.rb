class CreateAnalyticsEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :analytics_events do |t|
      t.string :event_type, null: false
      t.string :source, null: false
      t.string :referral_code
      t.string :email
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :analytics_events, :event_type
    add_index :analytics_events, :source
    add_index :analytics_events, :created_at
  end
end
