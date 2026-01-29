class AddShopIdToModels < ActiveRecord::Migration[8.1]
  def change
    # Add shop_id to core business models
    # Optional (nullable) for backward compatibility during transition
    add_reference :shared_discounts, :shop, foreign_key: true, index: true
    add_reference :discount_configs, :shop, foreign_key: true, index: true
    add_reference :analytics_events, :shop, foreign_key: true, index: true
    add_reference :referrals, :shop, foreign_key: true, index: true
  end
end
