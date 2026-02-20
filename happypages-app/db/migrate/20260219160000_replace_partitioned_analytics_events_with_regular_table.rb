class ReplacePartitionedAnalyticsEventsWithRegularTable < ActiveRecord::Migration[8.1]
  def up
    # Drop the partitioned table and all its partitions
    execute "DROP TABLE IF EXISTS analytics_events CASCADE"

    create_table :analytics_events do |t|
      t.references :analytics_site, null: false, foreign_key: { on_delete: :cascade }
      t.string :visitor_id, limit: 32, null: false
      t.string :session_id, limit: 32, null: false
      t.string :event_name, limit: 64, null: false, default: "pageview"
      t.string :pathname, limit: 2048
      t.string :hostname, limit: 255
      t.string :referrer, limit: 2048
      t.string :utm_source, limit: 255
      t.string :utm_medium, limit: 255
      t.string :utm_campaign, limit: 255
      t.string :utm_term, limit: 255
      t.string :utm_content, limit: 255
      t.string :browser, limit: 64
      t.string :browser_version, limit: 32
      t.string :os, limit: 64
      t.string :os_version, limit: 32
      t.string :device_type, limit: 16
      t.string :country_code, limit: 2
      t.string :region, limit: 128
      t.string :city, limit: 128
      t.string :referral_code, limit: 64
      t.jsonb :properties, null: false, default: {}
      t.timestamptz :occurred_at, null: false, default: -> { "now()" }
    end

    add_index :analytics_events, [ :analytics_site_id, :occurred_at ], name: "idx_analytics_events_site_time"
    add_index :analytics_events, [ :analytics_site_id, :pathname ], name: "idx_analytics_events_site_path"
    add_index :analytics_events, [ :analytics_site_id, :visitor_id ], name: "idx_analytics_events_site_visitor"
    add_index :analytics_events, [ :analytics_site_id, :event_name, :occurred_at ], name: "idx_analytics_events_site_event_time"
    add_index :analytics_events, :session_id, name: "idx_analytics_events_session"
    add_index :analytics_events, :referral_code, where: "referral_code IS NOT NULL", name: "idx_analytics_events_referral"
  end

  def down
    drop_table :analytics_events
  end
end
