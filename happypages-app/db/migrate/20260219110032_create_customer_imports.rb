class CreateCustomerImports < ActiveRecord::Migration[8.1]
  def change
    create_table :customer_imports do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.integer :total_fetched, default: 0
      t.integer :total_created, default: 0
      t.integer :total_skipped, default: 0
      t.string :last_cursor
      t.text :error_message
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end
  end
end
