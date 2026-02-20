module Analytics
  class Site < ApplicationRecord
    self.table_name = "analytics_sites"

    belongs_to :shop
    has_many :events, class_name: "Analytics::Event", foreign_key: :analytics_site_id, dependent: :delete_all
    has_many :payments, class_name: "Analytics::Payment", foreign_key: :analytics_site_id, dependent: :delete_all

    validates :domain, presence: true
    validates :site_token, presence: true, uniqueness: true
    validates :domain, uniqueness: { scope: :shop_id }

    before_validation :generate_site_token, on: :create

    scope :active, -> { where(active: true) }

    private

    def generate_site_token
      self.site_token ||= SecureRandom.hex(16)
    end
  end
end
