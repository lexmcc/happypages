class AddChannelToSpecsSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :specs_sessions, :channel_type, :string, default: "web", null: false
    add_column :specs_sessions, :channel_metadata, :jsonb, default: {}
  end
end
