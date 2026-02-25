module Specs
  class Card < ApplicationRecord
    self.table_name = "specs_cards"

    belongs_to :project, class_name: "Specs::Project", foreign_key: :specs_project_id
    belongs_to :session, class_name: "Specs::Session", foreign_key: :specs_session_id, optional: true

    STATUSES = %w[backlog in_progress review done].freeze

    validates :title, presence: true
    validates :status, inclusion: { in: STATUSES }

    scope :backlog, -> { where(status: "backlog") }
    scope :in_progress, -> { where(status: "in_progress") }
    scope :review, -> { where(status: "review") }
    scope :done, -> { where(status: "done") }
    scope :ordered, -> { order(position: :asc) }

    def self.create_from_team_spec(project, session)
      return if project.cards.where(specs_session_id: session.id).exists?

      chunks = session.team_spec&.dig("chunks")
      return if chunks.blank?

      chunks.each_with_index do |chunk, i|
        project.cards.create!(
          session: session,
          chunk_index: i,
          title: chunk["title"],
          description: chunk["description"],
          acceptance_criteria: chunk["acceptance_criteria"] || [],
          has_ui: chunk["has_ui"] || false,
          dependencies: chunk["dependencies"] || [],
          status: "backlog",
          position: i
        )
      end
    end
  end
end
