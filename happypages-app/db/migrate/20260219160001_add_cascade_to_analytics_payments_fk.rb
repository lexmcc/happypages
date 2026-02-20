class AddCascadeToAnalyticsPaymentsFk < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :analytics_payments, :analytics_sites
    add_foreign_key :analytics_payments, :analytics_sites, on_delete: :cascade
  end

  def down
    remove_foreign_key :analytics_payments, :analytics_sites
    add_foreign_key :analytics_payments, :analytics_sites
  end
end
