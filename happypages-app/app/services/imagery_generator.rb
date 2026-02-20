class ImageryGenerator
  SURFACES = {
    "referral_banner" => { width: 1200, height: 400, aspect: "21:9", config_key: "referral_banner_image" },
    "extension_card"  => { width: 600,  height: 400, aspect: "3:2",  config_key: "extension_banner_image" },
    "og_image"        => { width: 1200, height: 630, aspect: "16:9", config_key: "og_image_url" }
  }.freeze

  QUALITY_THRESHOLD = 7

  def initialize(shop)
    @shop = shop
    @gemini = GeminiClient.new
    @profile = shop.brand_profile
  end

  # Generate imagery for all three surfaces
  def generate_all!
    SURFACES.each_key do |surface|
      generate_surface!(surface)
    end
  end

  # Generate imagery for a single surface
  def generate_surface!(surface)
    spec = SURFACES.fetch(surface)
    Rails.logger.info "[ImageryGenerator] Generating #{surface} for #{@shop.domain}"

    # Step 1: Select best product images
    selected_products = select_product_images

    # Step 2: Match a scene asset
    scene = match_scene

    # Step 3: Build prompt from template
    prompt = build_prompt(surface, selected_products, scene)

    # Step 4: Generate image
    reference_urls = build_reference_urls(selected_products, scene)
    image_data = generate_image(prompt, reference_urls)

    unless image_data
      log_generation(surface, prompt, nil, nil, false)
      Rails.logger.error "[ImageryGenerator] No image generated for #{surface}"
      return nil
    end

    # Step 5: Quality review
    quality_score = review_quality(image_data, surface)

    # Step 6: Retry once if quality is low
    if quality_score < QUALITY_THRESHOLD
      Rails.logger.info "[ImageryGenerator] Quality #{quality_score}/10 below threshold, retrying #{surface}"
      prompt = refine_prompt(prompt, quality_score)
      image_data = generate_image(prompt, reference_urls)

      if image_data
        quality_score = review_quality(image_data, surface)
        log_generation(surface, prompt, nil, quality_score, true)
      end
    end

    return nil unless image_data

    # Step 7: Post-process (crop/resize to exact dimensions)
    processed = post_process(image_data, spec)

    # Step 8: Store as MediaAsset and apply to config
    media_asset = store_image(processed, surface, spec)
    apply_to_config(media_asset, surface, spec)
    log_generation(surface, prompt, media_asset, quality_score, false)

    Rails.logger.info "[ImageryGenerator] #{surface} complete for #{@shop.domain} (quality: #{quality_score}/10)"
    media_asset
  rescue => e
    Rails.logger.error "[ImageryGenerator] Failed #{surface} for #{@shop.domain}: #{e.message}"
    raise
  end

  private

  # ── Step 1: Product Selection ──────────────────────────────

  def select_product_images
    products = @profile["products"] || []
    return [] if products.empty?
    return products.first(2) if products.size <= 2

    template = PromptTemplate.resolve(surface: "product_selection", category: @profile["category"])
    return products.first(2) unless template

    context = base_context.merge(
      product_names: products.map { |p| "- #{p['title']}" }.join("\n")
    )

    begin
      result = @gemini.generate_json(template.render(context))
      selected_names = result["selected"] || []

      products.select { |p| selected_names.include?(p["title"]) }.first(2)
    rescue GeminiClient::Error
      products.first(2)
    end
  end

  # ── Step 2: Scene Matching ─────────────────────────────────

  def match_scene
    category = @profile["category"] || "general"

    # Try category match first, fall back to general
    candidates = SceneAsset.for_category(category)
    candidates = SceneAsset.for_category("general") if candidates.empty?
    return nil if candidates.empty?

    return candidates.first if candidates.size == 1

    # Gemini tiebreak
    template = PromptTemplate.resolve(surface: "scene_selection", category: category)
    return candidates.first unless template

    scene_descriptions = candidates.map { |s| "ID #{s.id}: #{s.description} (mood: #{s.mood}, tags: #{s.tag_list})" }.join("\n")
    context = base_context.merge(scene_descriptions: scene_descriptions)

    begin
      result = @gemini.generate_json(template.render(context))
      selected_id = result["selected_scene_id"]
      candidates.find_by(id: selected_id) || candidates.first
    rescue GeminiClient::Error
      candidates.first
    end
  end

  # ── Step 3: Build Prompt ───────────────────────────────────

  def build_prompt(surface, selected_products, scene)
    template = PromptTemplate.resolve(surface: surface, category: @profile["category"])
    template ||= PromptTemplate.resolve(surface: surface)

    unless template
      # Fallback: basic prompt without template
      return "Create a professional marketing image for #{@shop.name}, a #{@profile['category']} brand. " \
             "Style: #{@profile['vibe']}. Colors: #{(@profile['palette'] || []).join(', ')}. " \
             "Feature products: #{selected_products.map { |p| p['title'] }.join(', ')}. " \
             "No text in the image."
    end

    product_names = selected_products.map { |p| p["title"] }.join(", ")
    scene_desc = scene&.description || @profile["suggested_scene"] || "A clean, professional lifestyle scene"

    context = base_context.merge(
      product_names: product_names,
      scene_description: scene_desc,
      aspect_ratio: SURFACES[surface][:aspect]
    )

    template.render(context)
  end

  # ── Step 4: Generate Image ─────────────────────────────────

  def generate_image(prompt, reference_urls)
    if reference_urls.any?
      @gemini.generate_image_with_references(prompt, reference_image_urls: reference_urls)
    else
      @gemini.generate_image(prompt)
    end
  rescue GeminiClient::Error => e
    Rails.logger.error "[ImageryGenerator] Generation failed: #{e.message}"
    nil
  end

  def build_reference_urls(selected_products, scene)
    urls = []

    # Add product images
    selected_products.each do |p|
      urls << p["image_url"] if p["image_url"].present?
    end

    # Add scene image URL if available
    if scene&.file&.attached?
      begin
        urls << Rails.application.routes.url_helpers.rails_blob_url(scene.file, host: ENV.fetch("APP_URL", "https://app.happypages.co"))
      rescue
        # Skip if URL generation fails
      end
    end

    urls.compact
  end

  # ── Step 5: Quality Review ─────────────────────────────────

  def review_quality(image_data, surface)
    template = PromptTemplate.resolve(surface: "quality_review")
    return 8 unless template # Skip review if no template

    product_names = (@profile["products"] || []).map { |p| p["title"] }.compact.join(", ")
    context = base_context.merge(product_names: product_names)
    prompt = template.render(context)

    # Send the generated image to Gemini for multimodal quality review
    begin
      result = @gemini.analyze_json_with_image(prompt, image_data: image_data)
      score = result["overall"].to_i
      score.clamp(1, 10)
    rescue GeminiClient::Error
      8 # Assume passing quality if review fails
    end
  end

  # ── Step 6: Refine Prompt ──────────────────────────────────

  def refine_prompt(original_prompt, score)
    original_prompt + "\n\nIMPORTANT: The previous generation scored #{score}/10. " \
      "Please improve: ensure brand colors are more prominent, products are clearly visible, " \
      "and the overall composition is more professional and balanced."
  end

  # ── Step 7: Post-Process ───────────────────────────────────

  def post_process(image_data, spec)
    tempfile = Tempfile.new([ "gen", extension_for(image_data[:mime_type]) ])
    begin
      tempfile.binmode
      tempfile.write(image_data[:bytes])
      tempfile.rewind

      processed = ImageProcessing::Vips
        .source(tempfile.path)
        .resize_to_fill(spec[:width], spec[:height])
        .convert("webp")
        .call

      {
        bytes: File.binread(processed.path),
        mime_type: "image/webp",
        filename: "#{SecureRandom.hex(8)}.webp"
      }
    rescue => e
      Rails.logger.warn "[ImageryGenerator] Post-processing failed, using raw image: #{e.message}"
      image_data.merge(filename: "#{SecureRandom.hex(8)}#{extension_for(image_data[:mime_type])}")
    ensure
      tempfile.close!
    end
  end

  def extension_for(mime_type)
    case mime_type
    when "image/png" then ".png"
    when "image/webp" then ".webp"
    when "image/jpeg" then ".jpg"
    else ".png"
    end
  end

  # ── Step 8: Store & Apply ──────────────────────────────────

  def store_image(processed, surface, spec)
    media_asset = @shop.media_assets.create!(
      filename: processed[:filename],
      content_type: processed[:mime_type],
      byte_size: processed[:bytes].size,
      surface: surface
    )

    io = StringIO.new(processed[:bytes])
    media_asset.file.attach(
      io: io,
      filename: media_asset.filename,
      content_type: media_asset.content_type
    )

    media_asset
  end

  def apply_to_config(media_asset, surface, spec)
    config_key = spec[:config_key]
    return unless config_key

    # Build the variant URL for this surface
    variant_url = case surface
    when "referral_banner"
      Rails.application.routes.url_helpers.rails_representation_url(
        media_asset.referral_banner_variant,
        host: ENV.fetch("APP_URL", "https://app.happypages.co")
      )
    when "extension_card"
      Rails.application.routes.url_helpers.rails_representation_url(
        media_asset.extension_banner_variant,
        host: ENV.fetch("APP_URL", "https://app.happypages.co")
      )
    when "og_image"
      Rails.application.routes.url_helpers.rails_blob_url(
        media_asset.file,
        host: ENV.fetch("APP_URL", "https://app.happypages.co")
      )
    end

    return unless variant_url

    @shop.discount_configs.find_or_initialize_by(config_key: config_key).update!(config_value: variant_url)
  rescue => e
    Rails.logger.warn "[ImageryGenerator] Failed to apply config #{config_key}: #{e.message}"
  end

  # ── Logging ────────────────────────────────────────────────

  def log_generation(surface, prompt, media_asset, quality_score, is_retry)
    GenerationLog.create!(
      shop: @shop,
      surface: surface,
      model_used: GeminiClient::IMAGE_MODEL,
      prompt_text: prompt,
      input_context: @profile.slice("category", "vibe", "style", "palette"),
      output_image_url: media_asset ? Rails.application.routes.url_helpers.rails_blob_path(media_asset.file) : nil,
      quality_score: quality_score,
      cost_cents: estimate_cost(is_retry),
      is_retry: is_retry
    )
  rescue => e
    Rails.logger.warn "[ImageryGenerator] Failed to log generation: #{e.message}"
  end

  def estimate_cost(is_retry)
    # Approximate cost per generation call in cents
    # Flash: ~$0.04/image = 4 cents
    is_retry ? 8 : 4
  end

  # ── Context Helpers ────────────────────────────────────────

  def base_context
    {
      category: @profile["category"] || "general",
      vibe: @profile["vibe"] || "professional",
      style: @profile["style"] || "modern",
      colors: (@profile["palette"] || []).join(", "),
      brand_name: @shop.name,
      logo_url: @profile["logo_url"] || "",
      storefront_description: @profile["storefront_description"] || ""
    }
  end
end
