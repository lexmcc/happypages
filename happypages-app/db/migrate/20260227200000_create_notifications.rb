class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.string :recipient_type, null: false
      t.bigint :recipient_id, null: false
      t.string :notifiable_type, null: false
      t.bigint :notifiable_id, null: false
      t.string :action, null: false
      t.datetime :read_at
      t.jsonb :data, default: {}
      t.timestamps
    end

    add_index :notifications, [:recipient_type, :recipient_id],
              name: "idx_notifications_recipient_unread",
              where: "read_at IS NULL"
    add_index :notifications, [:recipient_type, :recipient_id, :created_at],
              name: "idx_notifications_recipient_recent"
    add_index :notifications, [:notifiable_type, :notifiable_id]
  end
end
