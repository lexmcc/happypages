class AddSurfaceToMediaAssets < ActiveRecord::Migration[8.0]
  def change
    add_column :media_assets, :surface, :string
  end
end
