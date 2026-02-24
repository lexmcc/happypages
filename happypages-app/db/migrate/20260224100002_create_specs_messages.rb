class CreateSpecsMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :specs_messages do |t|
      t.references :specs_session, null: false, foreign_key: { to_table: :specs_sessions }
      t.string :role, null: false
      t.text :content
      t.jsonb :tool_calls
      t.string :tool_name
      t.jsonb :image_data
      t.integer :turn_number, null: false
      t.string :model_used
      t.integer :input_tokens
      t.integer :output_tokens

      t.datetime :created_at, null: false
    end

    add_index :specs_messages, [:specs_session_id, :turn_number]
  end
end
