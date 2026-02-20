module Analytics
  class Payment < ApplicationRecord
    self.table_name = "analytics_payments"

    belongs_to :site, class_name: "Analytics::Site", foreign_key: :analytics_site_id

    validates :visitor_id, presence: true
    validates :amount_cents, presence: true, numericality: { greater_than: 0 }
    validates :currency, presence: true
    validates :order_id, uniqueness: { scope: :analytics_site_id }, allow_nil: true
  end
end
