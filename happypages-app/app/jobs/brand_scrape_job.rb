class BrandScrapeJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound
  retry_on GeminiClient::RateLimitError, wait: :polynomially_longer, attempts: 3
  retry_on Net::ReadTimeout, wait: 30.seconds, attempts: 2

  def perform(shop_id, generate_imagery: true)
    shop = Shop.find(shop_id)
    return unless shop.active? && shop.shopify?

    BrandScraper.new(shop).scrape!

    # Chain: generate imagery after successful scrape
    if generate_imagery && shop.reload.brand_scraped? && shop.can_generate?
      ImageGenerationJob.perform_later(shop.id)
    end
  end
end
