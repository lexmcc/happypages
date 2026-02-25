module Specs
  class Session < ApplicationRecord
    self.table_name = "specs_sessions"

    STATUSES = %w[active completed archived].freeze
    PHASES = %w[explore narrow converge generate].freeze

    belongs_to :project, class_name: "Specs::Project", foreign_key: :specs_project_id
    belongs_to :shop, optional: true
    belongs_to :user, optional: true
    belongs_to :specs_client, class_name: "Specs::Client", optional: true
    has_many :messages, class_name: "Specs::Message", foreign_key: :specs_session_id, dependent: :delete_all
    has_many :handoffs, class_name: "Specs::Handoff", foreign_key: :specs_session_id, dependent: :destroy

    validates :status, presence: true, inclusion: { in: STATUSES }
    validates :phase, presence: true, inclusion: { in: PHASES }
    validates :version, presence: true
    validates :turn_budget, presence: true, numericality: { greater_than: 0 }

    before_validation :set_version, on: :create

    scope :active, -> { where(status: "active") }
    scope :completed, -> { where(status: "completed") }

    def budget_percentage
      return 0.0 if turn_budget.zero?
      turns_used.to_f / turn_budget
    end

    def active_handoff
      handoffs.accepted.order(created_at: :desc).first
    end

    def pending_handoff
      # A handoff that hasn't been actioned yet: no acceptance and no to_user (internal handoff)
      handoffs.where(invite_accepted_at: nil, to_user_id: nil).order(created_at: :desc).first
    end

    private

    def set_version
      return if version_changed? && version > 1
      max = self.class.where(specs_project_id: specs_project_id).maximum(:version) || 0
      self.version = max + 1
    end
  end
end
