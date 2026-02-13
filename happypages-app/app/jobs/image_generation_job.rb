class ImageGenerationJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound
  retry_on GeminiClient::RateLimitError, wait: :polynomially_longer, attempts: 3
  retry_on Net::ReadTimeout, wait: 30.seconds, attempts: 2

  # surface: nil = generate all, or "referral_banner"/"extension_card"/"og_image"
  def perform(shop_id, surface: nil)
    shop = Shop.find(shop_id)
    return unless shop.active? && shop.brand_scraped?

    # Deduct credit atomically BEFORE generation
    shop.use_credit!

    generator = ImageryGenerator.new(shop)

    if surface
      generator.generate_surface!(surface)
    else
      generator.generate_all!
    end
  end
end
