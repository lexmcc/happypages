class CreateSpecsSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :specs_sessions do |t|
      t.references :specs_project, null: false, foreign_key: { to_table: :specs_projects }
      t.references :shop, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.integer :version, null: false, default: 1
      t.string :status, null: false, default: "active"
      t.integer :turn_budget, null: false, default: 20
      t.integer :turns_used, null: false, default: 0
      t.string :phase, null: false, default: "explore"
      t.jsonb :transcript, null: false, default: []
      t.text :compressed_context
      t.jsonb :client_brief
      t.jsonb :team_spec
      t.string :prompt_version, null: false, default: "v1"
      t.integer :total_input_tokens, null: false, default: 0
      t.integer :total_output_tokens, null: false, default: 0

      t.timestamps
    end

    add_index :specs_sessions, [:specs_project_id, :version], unique: true
    add_index :specs_sessions, [:shop_id, :status]
  end
end
