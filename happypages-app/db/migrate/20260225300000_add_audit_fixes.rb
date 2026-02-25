class AddAuditFixes < ActiveRecord::Migration[8.0]
  def change
    add_check_constraint :specs_projects,
      "(shop_id IS NOT NULL AND organisation_id IS NULL) OR (shop_id IS NULL AND organisation_id IS NOT NULL)",
      name: "chk_specs_projects_owner_xor"

    add_column :specs_clients, :invite_expires_at, :datetime

    add_index :specs_projects, [:organisation_id, :created_at]
  end
end
