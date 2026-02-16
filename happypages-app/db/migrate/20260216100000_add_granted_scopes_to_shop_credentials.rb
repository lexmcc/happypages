class AddGrantedScopesToShopCredentials < ActiveRecord::Migration[8.1]
  def change
    add_column :shop_credentials, :granted_scopes, :string
  end
end
