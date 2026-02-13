class CreateSceneAssets < ActiveRecord::Migration[8.1]
  def change
    create_table :scene_assets do |t|
      t.string :category, null: false
      t.jsonb :tags, default: []
      t.string :mood
      t.text :description
      t.timestamps
    end

    add_index :scene_assets, :category
    add_index :scene_assets, :tags, using: :gin
  end
end
