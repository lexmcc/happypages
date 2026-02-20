class CreateAnalyticsSites < ActiveRecord::Migration[8.1]
  def change
    create_table :analytics_sites do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :domain, null: false
      t.string :site_token, null: false
      t.string :name
      t.string :timezone, default: "UTC"
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :analytics_sites, :site_token, unique: true
    add_index :analytics_sites, :domain
    add_index :analytics_sites, [ :shop_id, :domain ], unique: true
  end
end
