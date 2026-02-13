class Admin::ImageGenerationsController < Admin::BaseController
  # POST /admin/image_generations
  def create
    shop = Current.shop
    surface = params[:surface]

    unless ImageryGenerator::SURFACES.key?(surface)
      redirect_back fallback_location: admin_dashboard_path, alert: "Invalid surface"
      return
    end

    unless shop.can_generate?
      redirect_back fallback_location: admin_dashboard_path, alert: "No generation credits remaining this month"
      return
    end

    unless shop.brand_scraped?
      # Trigger a brand scrape first, then generation will chain
      BrandScrapeJob.perform_later(shop.id)
      redirect_back fallback_location: admin_dashboard_path, notice: "Analyzing your brand first — imagery will generate automatically"
      return
    end

    ImageGenerationJob.perform_later(shop.id, surface: surface)
    redirect_back fallback_location: admin_dashboard_path, notice: "Generating new #{surface.humanize.downcase} image — this may take a minute"
  end

  # GET /admin/image_generations/status
  def status
    shop = Current.shop
    latest = shop.generation_logs.where(surface: params[:surface]).recent.first

    render json: {
      credits_remaining: shop.generation_credits_remaining.to_i,
      latest_generation: latest ? {
        surface: latest.surface,
        quality_score: latest.quality_score,
        created_at: latest.created_at.iso8601,
        image_url: latest.output_image_url
      } : nil
    }
  end
end
