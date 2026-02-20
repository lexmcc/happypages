require "net/http"
require "json"

class BrandScraper
  SHOPIFY_API_VERSION = "2025-10"

  def initialize(shop)
    @shop = shop
    @token = shop.shop_credential&.shopify_access_token
    @gemini = GeminiClient.new
  end

  def scrape!
    Rails.logger.info "[BrandScraper] Starting scrape for #{@shop.domain}"

    theme_data = fetch_theme_data
    products_data = fetch_products
    storefront_data = scrape_storefront

    raw_data = {
      theme: theme_data,
      products: products_data,
      storefront: storefront_data,
      shop_name: @shop.name,
      domain: @shop.domain
    }

    analysis = analyze_brand(raw_data)

    brand_profile = build_brand_profile(analysis, theme_data, products_data, storefront_data)
    @shop.update!(brand_profile: brand_profile)

    # Auto-set referral colors from brand palette (only if using defaults)
    auto_set_colors(brand_profile["palette"]) if brand_profile["palette"]&.any?

    Rails.logger.info "[BrandScraper] Scrape complete for #{@shop.domain}: category=#{brand_profile['category']}"
    brand_profile
  rescue => e
    Rails.logger.error "[BrandScraper] Failed for #{@shop.domain}: #{e.message}"
    raise
  end

  private

  # ── Shopify Theme API ──────────────────────────────────────

  def fetch_theme_data
    return {} unless @token.present?

    # Get the published theme
    themes = shopify_get("/themes.json").dig("themes") || []
    main_theme = themes.find { |t| t["role"] == "main" }
    return {} unless main_theme

    theme_id = main_theme["id"]

    # Fetch theme settings (config/settings_data.json)
    settings_asset = shopify_get("/themes/#{theme_id}/assets.json?asset[key]=config/settings_data.json")
    settings_json = settings_asset.dig("asset", "value")
    settings = settings_json ? JSON.parse(settings_json) : {}

    extract_theme_colors_and_fonts(settings)
  rescue => e
    Rails.logger.warn "[BrandScraper] Theme API failed: #{e.message}"
    {}
  end

  def extract_theme_colors_and_fonts(settings)
    # Shopify Dawn/OS 2.0 themes store settings under current.settings
    current = settings.dig("current", "settings") || settings.dig("current") || {}

    colors = {}
    fonts = []

    current.each do |key, value|
      next unless value.is_a?(String)
      if key.match?(/color/i) && value.match?(/\A#[0-9a-f]{3,8}\z/i)
        colors[key] = value
      end
      if key.match?(/font/i) && value.present? && !value.match?(/\A#/)
        fonts << value
      end
    end

    # Also try to find logo
    logo_url = nil
    current.each do |key, value|
      if key.match?(/logo/i) && value.is_a?(String) && value.present?
        logo_url = value
        break
      end
    end

    { colors: colors, fonts: fonts.uniq.first(5), logo_url: logo_url }
  end

  # ── Shopify Products API ───────────────────────────────────

  def fetch_products
    return [] unless @token.present?

    # Fetch top 5 products (by default sort, usually newest)
    data = shopify_get("/products.json?limit=5&fields=id,title,product_type,image,images")
    products = data.dig("products") || []

    products.map do |p|
      image_url = p.dig("image", "src") || p.dig("images", 0, "src")
      {
        "title" => p["title"],
        "type" => p["product_type"],
        "image_url" => image_url
      }.compact
    end
  rescue => e
    Rails.logger.warn "[BrandScraper] Products API failed: #{e.message}"
    []
  end

  # ── Storefront HTML Scrape ─────────────────────────────────

  def scrape_storefront
    url = @shop.customer_facing_url
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.read_timeout = 15
    http.open_timeout = 10

    response = http.request(Net::HTTP::Get.new(uri))
    return {} unless response.is_a?(Net::HTTPSuccess)

    html = response.body.force_encoding("UTF-8")

    {
      title: extract_meta(html, "og:title") || extract_tag(html, "title"),
      description: extract_meta(html, "og:description") || extract_meta(html, "description"),
      og_image: extract_meta(html, "og:image"),
      theme_color: extract_meta(html, "theme-color")
    }.compact
  rescue => e
    Rails.logger.warn "[BrandScraper] Storefront scrape failed: #{e.message}"
    {}
  end

  def extract_meta(html, name)
    # Match both property= and name= attributes
    match = html.match(/<meta\s+(?:property|name)=["']#{Regexp.escape(name)}["']\s+content=["']([^"']+)["']/i)
    match ||= html.match(/<meta\s+content=["']([^"']+)["']\s+(?:property|name)=["']#{Regexp.escape(name)}["']/i)
    match&.[](1)
  end

  def extract_tag(html, tag)
    match = html.match(/<#{tag}[^>]*>([^<]+)<\/#{tag}>/i)
    match&.[](1)&.strip
  end

  # ── Gemini Brand Analysis ──────────────────────────────────

  def analyze_brand(raw_data)
    prompt = build_analysis_prompt(raw_data)
    result = @gemini.generate_json(prompt)
    result = result.first if result.is_a?(Array)
    result.is_a?(Hash) ? result : raise(GeminiClient::ApiError, "Unexpected response type: #{result.class}")
  rescue GeminiClient::Error => e
    Rails.logger.error "[BrandScraper] Gemini analysis failed: #{e.message}"
    # Return sensible defaults so the pipeline doesn't break
    {
      "category" => "general",
      "style" => "modern",
      "vibe" => "clean professional",
      "palette" => extract_fallback_palette(raw_data)
    }
  end

  def build_analysis_prompt(raw_data)
    theme_colors = raw_data[:theme][:colors]&.values&.first(10)&.join(", ") || "unknown"
    product_types = raw_data[:products].map { |p| p["type"] }.compact.uniq.join(", ")
    product_titles = raw_data[:products].map { |p| p["title"] }.compact.first(5).join(", ")

    <<~PROMPT
      You are a brand analyst. Analyze this Shopify store and return JSON.

      Store: #{raw_data[:shop_name]} (#{raw_data[:domain]})
      Storefront title: #{raw_data.dig(:storefront, :title) || "N/A"}
      Storefront description: #{raw_data.dig(:storefront, :description) || "N/A"}
      Theme colors: #{theme_colors}
      Product types: #{product_types.presence || "N/A"}
      Product names: #{product_titles.presence || "N/A"}

      Return this exact JSON structure:
      {
        "category": "one of: food, fashion, beauty, home, wellness, tech, pets, sports, kids, general",
        "style": "one of: minimal, bold, luxe, playful, organic, industrial, classic",
        "vibe": "3-5 descriptive words about the brand feeling",
        "palette": ["#hex1", "#hex2", "#hex3"],
        "suggested_scene": "brief description of an ideal referral banner scene for this brand"
      }

      For the palette, extract the 3 most important brand colors. If theme colors are available, use those. Otherwise infer from the brand category and style.
      The palette should be usable as: primary action color, secondary/background, and accent.
    PROMPT
  end

  def extract_fallback_palette(raw_data)
    colors = raw_data.dig(:theme, :colors)&.values || []
    # Filter out black/white/transparent
    brand_colors = colors.select { |c| c.match?(/\A#[0-9a-f]{6}\z/i) }
      .reject { |c| %w[#000000 #ffffff #FFFFFF].include?(c) }
      .first(3)

    brand_colors.any? ? brand_colors : [ "#ff584d", "#154ffb", "#00C6F7" ]
  end

  # ── Build Final Profile ────────────────────────────────────

  def build_brand_profile(analysis, theme_data, products_data, storefront_data)
    {
      "category" => analysis["category"] || "general",
      "style" => analysis["style"] || "modern",
      "vibe" => analysis["vibe"] || "clean professional",
      "palette" => analysis["palette"] || [],
      "suggested_scene" => analysis["suggested_scene"],
      "logo_url" => theme_data[:logo_url],
      "fonts" => theme_data[:fonts] || [],
      "products" => products_data.first(5),
      "storefront_title" => storefront_data[:title],
      "storefront_description" => storefront_data[:description],
      "og_image" => storefront_data[:og_image],
      "scraped_at" => Time.current.iso8601
    }
  end

  # ── Auto-Set Colors ─────────────────────────────────────────

  def auto_set_colors(palette)
    # Only set colors if the merchant hasn't customized them yet
    color_keys = %w[referral_primary_color referral_secondary_color referral_background_color]
    existing = @shop.discount_configs.where(config_key: color_keys)

    # If any color config already exists, merchant has customized — don't overwrite
    return if existing.any?

    color_map = {
      "referral_primary_color" => palette[0],
      "referral_secondary_color" => palette[1] || lighten_color(palette[0]),
      "referral_background_color" => palette[2] || "#f9fafb"
    }

    color_map.each do |key, value|
      next unless value.present?
      @shop.discount_configs.create!(config_key: key, config_value: value)
    end

    Rails.logger.info "[BrandScraper] Auto-set colors for #{@shop.domain}: #{color_map.values.join(', ')}"
  rescue => e
    Rails.logger.warn "[BrandScraper] Failed to auto-set colors: #{e.message}"
  end

  def lighten_color(hex)
    return "#e0e0e0" unless hex&.match?(/\A#[0-9a-f]{6}\z/i)

    r, g, b = hex[1..].scan(/../).map { |c| c.to_i(16) }
    # Lighten by blending 60% toward white
    r = ((r * 0.4) + (255 * 0.6)).round.clamp(0, 255)
    g = ((g * 0.4) + (255 * 0.6)).round.clamp(0, 255)
    b = ((b * 0.4) + (255 * 0.6)).round.clamp(0, 255)
    "#%02x%02x%02x" % [ r, g, b ]
  end

  # ── Shopify API Helper ─────────────────────────────────────

  def shopify_get(path)
    uri = URI("https://#{@shop.domain}/admin/api/#{SHOPIFY_API_VERSION}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 15

    request = Net::HTTP::Get.new(uri)
    request["X-Shopify-Access-Token"] = @token

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      Rails.logger.warn "[BrandScraper] Shopify API #{path} returned #{response.code}"
      {}
    end
  end
end
