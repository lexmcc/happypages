class ScopeUsersEmailUniquenessToShop < ActiveRecord::Migration[8.0]
  def change
    remove_index :users, :email
    add_index :users, [ :shop_id, :email ], unique: true
  end
end
