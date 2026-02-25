class AddOrganisationToSpecs < ActiveRecord::Migration[8.1]
  def change
    # Make shop_id nullable on specs_projects and specs_sessions
    change_column_null :specs_projects, :shop_id, true
    change_column_null :specs_sessions, :shop_id, true

    # Add organisation to projects
    add_reference :specs_projects, :organisation, foreign_key: true, null: true

    # Add specs_client to sessions and messages
    add_reference :specs_sessions, :specs_client, foreign_key: { to_table: :specs_clients }, null: true
    add_reference :specs_messages, :specs_client, foreign_key: { to_table: :specs_clients }, null: true
  end
end
