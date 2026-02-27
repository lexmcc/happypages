module Specs
  class LinearPushJob < ApplicationJob
    queue_as :default

    STATUS_MAP = {
      "backlog" => "backlog",
      "in_progress" => "started",
      "review" => "started",
      "done" => "completed"
    }.freeze

    def perform(card_ids:, integration_id:)
      integration = ShopIntegration.find_by(id: integration_id)
      return unless integration&.linear_connected?

      client = LinearClient.new(integration.linear_access_token)
      team_id = integration.linear_team_id

      states = client.workflow_states(team_id)
      state_map = build_state_map(states)

      cards = Specs::Card.where(id: card_ids, linear_issue_id: nil)

      cards.find_each do |card|
        push_card(client, team_id, card, state_map)
      rescue LinearClient::Error => e
        Rails.logger.error "[LinearPushJob] Failed to push card #{card.id}: #{e.message}"
      end
    end

    private

    def push_card(client, team_id, card, state_map)
      description = build_description(card)
      state_id = state_map[card.status]

      issue = client.create_issue(
        team_id: team_id,
        title: card.title,
        description: description,
        state_id: state_id
      )

      card.update!(
        linear_issue_id: issue["id"],
        linear_issue_url: issue["url"]
      )
    end

    def build_description(card)
      parts = []
      parts << card.description if card.description.present?

      if card.acceptance_criteria.present? && card.acceptance_criteria.any?
        parts << "## Acceptance Criteria"
        card.acceptance_criteria.each { |ac| parts << "- [ ] #{ac}" }
      end

      if card.dependencies.present? && card.dependencies.any?
        parts << "**Dependencies:** #{card.dependencies.join(", ")}"
      end

      parts.join("\n\n")
    end

    def build_state_map(states)
      map = {}

      backlog = states.find { |s| s["type"] == "backlog" } ||
                states.find { |s| s["type"] == "triage" }
      map["backlog"] = backlog["id"] if backlog

      started = states.find { |s| s["type"] == "started" }
      map["in_progress"] = started["id"] if started

      review = states.find { |s| s["type"] == "started" && s["name"].downcase.include?("review") } || started
      map["review"] = review["id"] if review

      completed = states.find { |s| s["type"] == "completed" }
      map["done"] = completed["id"] if completed

      map
    end
  end
end
