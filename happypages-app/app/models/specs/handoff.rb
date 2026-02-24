module Specs
  class Handoff < ApplicationRecord
    self.table_name = "specs_handoffs"

    ROLES = %w[owner member client].freeze

    belongs_to :session, class_name: "Specs::Session", foreign_key: :specs_session_id
    belongs_to :from_user, class_name: "User", optional: true
    belongs_to :to_user, class_name: "User", optional: true

    validates :from_name, :reason, :summary, presence: true
    validates :turn_number, presence: true, numericality: { greater_than: 0 }
    validates :to_role, inclusion: { in: ROLES }, allow_nil: true
    validates :invite_token, uniqueness: true, allow_nil: true
    validate :one_pending_per_session, on: :create

    scope :pending, -> { where(invite_accepted_at: nil).where.not(invite_token: nil) }
    scope :accepted, -> { where.not(invite_accepted_at: nil) }
    scope :not_expired, -> { where("invite_expires_at IS NULL OR invite_expires_at > ?", Time.current) }

    def accepted?
      invite_accepted_at.present?
    end

    def pending?
      invite_token.present? && invite_accepted_at.nil?
    end

    def internal?
      to_user.present?
    end

    def expired?
      invite_expires_at.present? && invite_expires_at < Time.current
    end

    def generate_invite_token!
      update!(
        invite_token: SecureRandom.urlsafe_base64(32),
        invite_expires_at: 7.days.from_now
      )
    end

    private

    def one_pending_per_session
      if session&.handoffs&.where(invite_accepted_at: nil, to_user_id: nil)&.where&.not(id: id)&.exists?
        errors.add(:base, "session already has a pending handoff")
      end
    end
  end
end
