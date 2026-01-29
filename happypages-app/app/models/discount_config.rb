class DiscountConfig < ApplicationRecord
  belongs_to :shop, optional: true  # Optional during transition

  before_validation :set_shop_from_current, on: :create

  private

  def set_shop_from_current
    self.shop ||= Current.shop
  end
end
