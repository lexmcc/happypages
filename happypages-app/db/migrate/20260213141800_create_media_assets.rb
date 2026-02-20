class CreateMediaAssets < ActiveRecord::Migration[8.1]
  def change
    create_table :media_assets do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :filename, null: false
      t.string :content_type, null: false
      t.integer :byte_size, null: false
      t.timestamps
    end
    add_index :media_assets, [ :shop_id, :created_at ]
  end
end
