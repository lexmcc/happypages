class AddSlackToOrganisations < ActiveRecord::Migration[8.1]
  def change
    # Organisation Slack credentials
    add_column :organisations, :slack_team_id, :string
    add_column :organisations, :slack_bot_token, :string
    add_column :organisations, :slack_app_id, :string
    add_index :organisations, :slack_team_id, unique: true

    # Specs::Client — link Slack user IDs
    add_column :specs_clients, :slack_user_id, :string
    add_index :specs_clients, [:organisation_id, :slack_user_id], unique: true,
              where: "slack_user_id IS NOT NULL", name: "idx_specs_clients_org_slack_user"

    # JSONB lookup index for session-by-thread matching
    add_index :specs_sessions, "(channel_metadata->>'thread_ts')",
              where: "channel_type = 'slack'",
              name: "idx_specs_sessions_slack_thread_ts",
              using: :btree
  end
end
