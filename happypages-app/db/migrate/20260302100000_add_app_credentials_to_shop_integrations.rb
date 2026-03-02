class AddAppCredentialsToShopIntegrations < ActiveRecord::Migration[8.0]
  def change
    add_column :shop_integrations, :app_client_id, :string
    add_column :shop_integrations, :app_client_secret, :string

    add_index :shop_integrations, :app_client_id, unique: true, where: "app_client_id IS NOT NULL"
  end
end
