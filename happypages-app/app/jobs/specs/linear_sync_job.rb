module Specs
  class LinearSyncJob < ApplicationJob
    queue_as :default

    def perform(issue_id:, state_name:, state_type:)
      card = Specs::Card.find_by(linear_issue_id: issue_id)
      return unless card

      new_status = map_state_to_status(state_type, state_name)
      return unless new_status
      return if card.status == new_status

      card.update!(status: new_status)
    end

    private

    def map_state_to_status(state_type, state_name)
      case state_type
      when "backlog", "triage", "unstarted"
        "backlog"
      when "started"
        state_name&.downcase&.include?("review") ? "review" : "in_progress"
      when "completed"
        "done"
      when "cancelled"
        nil
      end
    end
  end
end
