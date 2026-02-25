class CreateSpecsClients < ActiveRecord::Migration[8.1]
  def change
    create_table :specs_clients do |t|
      t.references :organisation, null: false, foreign_key: true
      t.string :email, null: false
      t.string :name
      t.string :password_digest
      t.string :invite_token
      t.datetime :invite_sent_at
      t.datetime :invite_accepted_at
      t.datetime :last_sign_in_at

      t.timestamps
    end

    add_index :specs_clients, [:organisation_id, :email], unique: true
    add_index :specs_clients, :invite_token, unique: true, where: "invite_token IS NOT NULL"
    add_index :specs_clients, :email
  end
end
