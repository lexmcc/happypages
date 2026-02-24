class AddHandoffSupportToSpecs < ActiveRecord::Migration[8.0]
  def change
    add_reference :specs_messages, :user, foreign_key: true, null: true

    create_table :specs_handoffs do |t|
      t.references :specs_session, null: false, foreign_key: true
      t.references :from_user, foreign_key: { to_table: :users }, null: true
      t.references :to_user, foreign_key: { to_table: :users }, null: true
      t.string :from_name, null: false
      t.string :to_name
      t.string :to_role
      t.text :reason, null: false
      t.text :summary, null: false
      t.jsonb :suggested_questions, default: []
      t.string :suggested_role
      t.integer :turn_number, null: false
      t.string :invite_token
      t.datetime :invite_accepted_at
      t.datetime :invite_expires_at
      t.datetime :created_at, null: false
    end

    add_index :specs_handoffs, :invite_token, unique: true, where: "invite_token IS NOT NULL"
  end
end
