module Analytics
  class Event < ApplicationRecord
    self.table_name = "analytics_events"
    self.record_timestamps = false

    belongs_to :site, class_name: "Analytics::Site", foreign_key: :analytics_site_id

    validates :visitor_id, presence: true
    validates :session_id, presence: true
    validates :event_name, presence: true

    scope :pageviews, -> { where(event_name: "pageview") }
    scope :custom_events, -> { where.not(event_name: "pageview") }
    scope :in_period, ->(range) { where(occurred_at: range) }
    scope :for_site, ->(site) { where(analytics_site_id: site.id) }
  end
end
