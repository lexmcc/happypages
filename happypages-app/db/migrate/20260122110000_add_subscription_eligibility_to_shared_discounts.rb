class AddSubscriptionEligibilityToSharedDiscounts < ActiveRecord::Migration[8.1]
  def change
    add_column :shared_discounts, :applies_on_subscription, :boolean, default: true
    add_column :shared_discounts, :applies_on_one_time_purchase, :boolean, default: true
  end
end
