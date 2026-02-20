class CreateShopFeatures < ActiveRecord::Migration[8.1]
  def change
    create_table :shop_features do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :feature, null: false
      t.string :status, null: false, default: "active"
      t.datetime :activated_at
      t.datetime :expires_at

      t.timestamps
    end

    add_index :shop_features, [:shop_id, :feature], unique: true
  end
end
