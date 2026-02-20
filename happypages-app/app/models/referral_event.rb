class ReferralEvent < ApplicationRecord
  belongs_to :shop

  encrypts :email, deterministic: true

  before_validation :set_shop_from_current, on: :create

  # Event types
  EXTENSION_LOAD = "extension_load".freeze
  SHARE_CLICK = "share_click".freeze
  PAGE_LOAD = "page_load".freeze
  COPY_CLICK = "copy_click".freeze

  # Sources
  CHECKOUT_EXTENSION = "checkout_extension".freeze
  REFERRAL_PAGE = "referral_page".freeze

  validates :event_type, presence: true
  validates :source, presence: true

  scope :extension_events, -> { where(source: CHECKOUT_EXTENSION) }
  scope :referral_page_events, -> { where(source: REFERRAL_PAGE) }

  scope :loads, -> { where(event_type: [ EXTENSION_LOAD, PAGE_LOAD ]) }
  scope :clicks, -> { where(event_type: [ SHARE_CLICK, COPY_CLICK ]) }

  scope :in_period, ->(period) { where(created_at: period.ago..) }

  private

  def set_shop_from_current
    self.shop ||= Current.shop
  end
end
