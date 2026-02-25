class Organisation < ApplicationRecord
  has_many :specs_clients, class_name: "Specs::Client", dependent: :destroy
  has_many :specs_projects, class_name: "Specs::Project", dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :slug, length: { minimum: 3, maximum: 50 }
  validates :slug, format: { with: /\A[a-z0-9-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" }

  before_validation :generate_slug

  private

  def generate_slug
    return if slug.present?
    return unless name.present?

    base_slug = name.parameterize
    candidate = base_slug
    counter = 1

    while Organisation.exists?(slug: candidate)
      candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate
  end
end
