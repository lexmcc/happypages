class GenerationLog < ApplicationRecord
  belongs_to :shop

  SURFACES = %w[referral_banner extension_card og_image].freeze

  validates :surface, presence: true, inclusion: { in: SURFACES }

  scope :recent, -> { order(created_at: :desc) }
  scope :for_surface, ->(surface) { where(surface: surface) }
end
