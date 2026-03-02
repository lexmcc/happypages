class AddMetadataToShopFeatures < ActiveRecord::Migration[8.0]
  def change
    add_column :shop_features, :metadata, :jsonb, default: {}
  end
end
