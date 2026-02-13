class AddBrandProfileToShops < ActiveRecord::Migration[8.1]
  def change
    add_column :shops, :brand_profile, :jsonb, default: {}
    add_column :shops, :generation_credits_remaining, :integer, default: 10
    add_column :shops, :credits_reset_at, :datetime
  end
end
