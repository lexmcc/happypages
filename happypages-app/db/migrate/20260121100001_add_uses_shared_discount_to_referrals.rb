class AddUsesSharedDiscountToReferrals < ActiveRecord::Migration[8.0]
  def change
    add_column :referrals, :uses_shared_discount, :boolean, default: true
  end
end
