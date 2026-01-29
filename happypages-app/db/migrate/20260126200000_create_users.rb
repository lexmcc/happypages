class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :email, null: false
      t.string :password_digest  # For future custom platform signup
      t.string :shopify_user_id  # Shopify user who installed the app

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :shopify_user_id, unique: true
  end
end
