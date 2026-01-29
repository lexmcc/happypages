class CreateSharedDiscounts < ActiveRecord::Migration[8.0]
  def change
    create_table :shared_discounts do |t|
      t.string :discount_type, null: false
      t.string :shopify_discount_id

      t.timestamps
    end

    add_index :shared_discounts, :discount_type, unique: true
  end
end
