class AddNewCustomersOnlyToSharedDiscounts < ActiveRecord::Migration[8.0]
  def change
    add_column :shared_discounts, :new_customers_only, :boolean, default: true
  end
end
