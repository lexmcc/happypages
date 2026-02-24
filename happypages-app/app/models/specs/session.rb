module Specs
  class Session < ApplicationRecord
    self.table_name = "specs_sessions"

    STATUSES = %w[active completed archived].freeze
    PHASES = %w[explore narrow converge generate].freeze

    belongs_to :project, class_name: "Specs::Project", foreign_key: :specs_project_id
    belongs_to :shop
    belongs_to :user, optional: true
    has_many :messages, class_name: "Specs::Message", foreign_key: :specs_session_id, dependent: :delete_all

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

    private

    def set_version
      return if version_changed? && version > 1
      max = self.class.where(specs_project_id: specs_project_id).maximum(:version) || 0
      self.version = max + 1
    end
  end
end
