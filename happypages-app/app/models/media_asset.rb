class MediaAsset < ApplicationRecord
  belongs_to :shop
  has_one_attached :file

  validates :content_type, inclusion: {
    in: %w[image/jpeg image/png image/webp image/gif],
    message: "must be JPEG, PNG, WebP, or GIF"
  }
  validates :byte_size, numericality: {
    less_than_or_equal_to: 10.megabytes, message: "must be under 10 MB"
  }

  SURFACES = %w[referral_banner extension_card og_image].freeze

  validates :surface, inclusion: { in: SURFACES, allow_nil: true }

  scope :recent, -> { order(created_at: :desc) }
  scope :for_surface, ->(s) { where(surface: [s, nil]) }

  after_create_commit -> { MediaVariantJob.perform_later(id) }

  # Referral page: full-width, aspect-[3/1] desktop / aspect-video mobile
  def referral_banner_variant
    file.variant(resize_to_fill: [1200, 400], format: :webp)
  end

  # Checkout extension: aspectRatio 1.5 (3:2), narrow context ~600px
  def extension_banner_variant
    file.variant(resize_to_fill: [600, 400], format: :webp)
  end

  # Media library grid thumbnail
  def thumbnail_variant
    file.variant(resize_to_fill: [300, 200], format: :webp)
  end
end
