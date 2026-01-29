class Current < ActiveSupport::CurrentAttributes
  attribute :shop

  # Convenience methods for accessing shop-related data
  def shop_id
    shop&.id
  end

  def shopify?
    shop&.shopify?
  end

  def custom?
    shop&.custom?
  end
end
