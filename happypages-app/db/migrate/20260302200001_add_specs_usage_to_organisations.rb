class AddSpecsUsageToOrganisations < ActiveRecord::Migration[8.0]
  def change
    add_column :organisations, :specs_tier, :string
    add_column :organisations, :specs_monthly_limit, :integer
    add_column :organisations, :specs_billing_cycle_anchor, :date
  end
end
