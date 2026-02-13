class PromptTemplate < ApplicationRecord
  SURFACES = %w[referral_banner extension_card og_image brand_analysis quality_review product_selection scene_selection].freeze

  validates :key, presence: true, uniqueness: true
  validates :surface, presence: true, inclusion: { in: SURFACES }
  validates :template_text, presence: true

  scope :active, -> { where(active: true) }
  scope :for_surface, ->(surface) { where(surface: surface) }

  # Find the best template for a given surface and optional category.
  # Falls back to a universal template (category: nil) if no category-specific one exists.
  def self.resolve(surface:, category: nil)
    if category.present?
      active.find_by(surface: surface, category: category) || active.find_by(surface: surface, category: nil)
    else
      active.find_by(surface: surface, category: nil)
    end
  end

  # Interpolate template variables from a context hash.
  # Variables use {variable_name} syntax.
  def render(context = {})
    text = template_text.dup
    context.each do |key, value|
      text.gsub!("{#{key}}", value.to_s)
    end
    text
  end

  # List of available variables for reference
  VARIABLES = %w[
    category vibe style colors product_name product_names brand_name
    aspect_ratio scene_description logo_url storefront_description
  ].freeze
end
