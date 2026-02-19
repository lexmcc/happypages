class CustomerImport < ApplicationRecord
  belongs_to :shop

  STATUSES = %w[pending running completed failed].freeze

  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }

  def running?
    status == "running"
  end

  def pending?
    status == "pending"
  end

  def in_progress?
    pending? || running?
  end
end
