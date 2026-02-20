class AddRoleAndInviteToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, default: "owner"
    add_column :users, :invite_token, :string
    add_column :users, :invite_sent_at, :datetime
    add_column :users, :invite_accepted_at, :datetime
    add_column :users, :last_sign_in_at, :datetime

    add_index :users, :invite_token, unique: true, where: "invite_token IS NOT NULL"
  end
end
