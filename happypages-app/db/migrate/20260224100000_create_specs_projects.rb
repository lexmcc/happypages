class CreateSpecsProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :specs_projects do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :name, null: false
      t.text :context_briefing
      t.jsonb :accumulated_context, default: {}

      t.timestamps
    end

    add_index :specs_projects, [:shop_id, :created_at]
  end
end
