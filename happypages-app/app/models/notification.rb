class Notification < ApplicationRecord
  ACTIONS = %w[
    spec_completed
    card_review
    turn_limit_approaching
  ].freeze

  belongs_to :recipient, polymorphic: true
  belongs_to :notifiable, polymorphic: true

  validates :action, presence: true, inclusion: { in: ACTIONS }

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc).limit(20) }
  scope :stale, -> { where("created_at < ?", 90.days.ago) }

  def read?
    read_at.present?
  end

  def mark_read!
    update!(read_at: Time.current) unless read?
  end

  def self.notify(recipient:, notifiable:, action:, data: {})
    return if recipient.respond_to?(:notification_muted?) && recipient.notification_muted?(action)

    create(
      recipient: recipient,
      notifiable: notifiable,
      action: action,
      data: data
    )
  end
end
