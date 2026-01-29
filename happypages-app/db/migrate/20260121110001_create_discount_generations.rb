class CreateDiscountGenerations < ActiveRecord::Migration[8.0]
  def change
    create_table :discount_generations do |t|
      t.references :shared_discount, null: false, foreign_key: true
      t.string :shopify_discount_id
      t.string :referred_discount_type, null: false
      t.string :referred_discount_value, null: false
      t.boolean :is_current, default: true

      t.timestamps
    end
  end
end
