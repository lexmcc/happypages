class AddLinearIntegration < ActiveRecord::Migration[8.0]
  def change
    # ShopIntegration — Linear OAuth + webhook columns
    add_column :shop_integrations, :linear_access_token, :string
    add_column :shop_integrations, :linear_team_id, :string
    add_column :shop_integrations, :linear_webhook_id, :string
    add_column :shop_integrations, :linear_webhook_secret, :string

    # Specs::Card — track Linear issue link
    add_column :specs_cards, :linear_issue_id, :string
    add_column :specs_cards, :linear_issue_url, :string
    add_index :specs_cards, :linear_issue_id, unique: true, where: "linear_issue_id IS NOT NULL"
  end
end
