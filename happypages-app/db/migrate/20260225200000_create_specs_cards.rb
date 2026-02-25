class CreateSpecsCards < ActiveRecord::Migration[8.1]
  def change
    create_table :specs_cards do |t|
      t.references :specs_project, null: false, foreign_key: { to_table: :specs_projects }
      t.references :specs_session, foreign_key: { to_table: :specs_sessions }
      t.integer :chunk_index
      t.string :title, null: false
      t.text :description
      t.jsonb :acceptance_criteria, default: []
      t.boolean :has_ui, default: false
      t.jsonb :dependencies, default: []
      t.string :status, null: false, default: "backlog"
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :specs_cards, [:specs_project_id, :status, :position]
  end
end
