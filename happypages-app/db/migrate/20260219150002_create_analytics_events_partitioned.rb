class CreateAnalyticsEventsPartitioned < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE TABLE analytics_events (
        id bigint GENERATED ALWAYS AS IDENTITY,
        analytics_site_id bigint NOT NULL REFERENCES analytics_sites(id),
        visitor_id varchar(32) NOT NULL,
        session_id varchar(32) NOT NULL,
        event_name varchar(64) NOT NULL DEFAULT 'pageview',
        pathname varchar(2048),
        hostname varchar(255),
        referrer varchar(2048),
        utm_source varchar(255),
        utm_medium varchar(255),
        utm_campaign varchar(255),
        utm_term varchar(255),
        utm_content varchar(255),
        browser varchar(64),
        browser_version varchar(32),
        os varchar(64),
        os_version varchar(32),
        device_type varchar(16),
        country_code char(2),
        region varchar(128),
        city varchar(128),
        referral_code varchar(64),
        properties jsonb NOT NULL DEFAULT '{}',
        occurred_at timestamptz NOT NULL DEFAULT now(),
        PRIMARY KEY (id, occurred_at)
      ) PARTITION BY RANGE (occurred_at);

      CREATE INDEX idx_analytics_events_site_time ON analytics_events (analytics_site_id, occurred_at);
      CREATE INDEX idx_analytics_events_site_path ON analytics_events (analytics_site_id, pathname);
      CREATE INDEX idx_analytics_events_site_visitor ON analytics_events (analytics_site_id, visitor_id);
      CREATE INDEX idx_analytics_events_session ON analytics_events (session_id);
      CREATE INDEX idx_analytics_events_referral ON analytics_events (referral_code) WHERE referral_code IS NOT NULL;
    SQL

    # Create partitions: current month + 2 months ahead
    now = Time.current
    3.times do |i|
      month_start = now.beginning_of_month + i.months
      month_end = month_start + 1.month
      partition_name = "analytics_events_y#{month_start.year}m#{'%02d' % month_start.month}"

      execute <<~SQL
        CREATE TABLE #{partition_name} PARTITION OF analytics_events
          FOR VALUES FROM ('#{month_start.strftime('%Y-%m-%d')}') TO ('#{month_end.strftime('%Y-%m-%d')}');
      SQL
    end
  end

  def down
    execute "DROP TABLE IF EXISTS analytics_events CASCADE"
  end
end
