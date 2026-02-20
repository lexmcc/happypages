class ShopFeature < ApplicationRecord
  FEATURES = %w[referrals analytics cro insights landing_pages funnels ads ambassadors].freeze
  STATUSES = %w[active locked trial expired].freeze

  belongs_to :shop

  validates :feature, presence: true, inclusion: { in: FEATURES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :feature, uniqueness: { scope: :shop_id }

  scope :active, -> { where(status: "active") }
  scope :locked, -> { where(status: "locked") }

  def active?
    status == "active"
  end

  def locked?
    status == "locked"
  end

  def trial?
    status == "trial"
  end
end
