class CreateDiscountConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :discount_configs do |t|
      t.string :config_key, null: false
      t.string :config_value, null: false

      t.timestamps
    end

    add_index :discount_configs, :config_key, unique: true
  end
end
