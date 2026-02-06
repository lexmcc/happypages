class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :shop, foreign_key: true
      t.string :action, null: false
      t.string :resource_type
      t.bigint :resource_id
      t.string :actor, null: false
      t.string :actor_ip
      t.string :actor_identifier
      t.jsonb :details, default: {}
      t.timestamps
    end

    add_index :audit_logs, [:shop_id, :created_at]
    add_index :audit_logs, :action
  end
end
