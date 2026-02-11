class ScopeDiscountConfigsUniquenessToShop < ActiveRecord::Migration[8.1]
  def change
    remove_index :discount_configs, column: :config_key, name: "index_discount_configs_on_config_key"
    add_index :discount_configs, [:shop_id, :config_key], unique: true
  end
end
