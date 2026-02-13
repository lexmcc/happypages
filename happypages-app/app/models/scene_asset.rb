class SceneAsset < ApplicationRecord
  CATEGORIES = %w[food fashion beauty home wellness tech pets sports kids general].freeze
  MOODS = %w[warm minimal bold playful organic industrial classic elegant cozy vibrant].freeze

  has_one_attached :file

  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :mood, inclusion: { in: MOODS }, allow_blank: true
  validates :description, presence: true
  validate :file_must_be_attached

  scope :for_category, ->(cat) { where(category: cat) }
  scope :with_any_tags, ->(tags) { where("tags ?| array[:tags]", tags: tags) }

  def tag_list
    tags.join(", ")
  end

  def tag_list=(value)
    self.tags = value.to_s.split(",").map(&:strip).reject(&:blank?)
  end

  private

  def file_must_be_attached
    errors.add(:file, "must be attached") unless file.attached?
  end
end
