module Specs
  class Message < ApplicationRecord
    self.table_name = "specs_messages"
    self.record_timestamps = false

    belongs_to :session, class_name: "Specs::Session", foreign_key: :specs_session_id
    belongs_to :user, optional: true
    has_one_attached :image

    ALLOWED_IMAGE_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
    MAX_IMAGE_SIZE = 5.megabytes

    validates :role, presence: true, inclusion: { in: %w[user assistant] }
    validates :turn_number, presence: true
    validate :acceptable_image, if: -> { image.attached? }

    before_create { self.created_at = Time.current }

    def sender_name(handoffs_cache = nil)
      return nil if role == "assistant"
      if user.present?
        user.email
      elsif role == "user"
        handoffs = handoffs_cache || session.handoffs.accepted.order(turn_number: :desc).to_a
        handoff = handoffs.find { |h| h.turn_number <= turn_number }
        handoff&.to_name || "Guest"
      end
    end

    private

    def acceptable_image
      unless ALLOWED_IMAGE_TYPES.include?(image.content_type)
        errors.add(:image, "must be PNG, JPEG, GIF or WebP")
      end
      if image.byte_size > MAX_IMAGE_SIZE
        errors.add(:image, "must be less than 5MB")
      end
    end
  end
end
