# Seed initial prompt templates for AI imagery generation.
# Run via: rails runner db/seeds/prompt_templates.rb

templates = [
  # ── Brand Analysis ─────────────────────────────────────────
  {
    key: "default_brand_analysis",
    surface: "brand_analysis",
    template_text: <<~PROMPT
      You are a brand analyst. Analyze this Shopify store and return JSON.

      Store: {brand_name} ({domain})
      Storefront title: {storefront_title}
      Storefront description: {storefront_description}
      Theme colors: {colors}
      Product types: {product_types}
      Product names: {product_names}

      Return this exact JSON structure:
      {
        "category": "one of: food, fashion, beauty, home, wellness, tech, pets, sports, kids, general",
        "style": "one of: minimal, bold, luxe, playful, organic, industrial, classic",
        "vibe": "3-5 descriptive words about the brand feeling",
        "palette": ["#hex1", "#hex2", "#hex3"],
        "suggested_scene": "brief description of an ideal referral banner scene for this brand"
      }
    PROMPT
  },

  # ── Product Selection ──────────────────────────────────────
  {
    key: "default_product_selection",
    surface: "product_selection",
    template_text: <<~PROMPT
      You are selecting product images for a referral banner. The brand is a {category} store with a {vibe} vibe.

      Available products:
      {product_names}

      Pick the 1-2 most visually appealing products that would look best in a marketing banner. Consider: vibrant packaging, recognizable shape, photogenic quality.

      Return JSON: {"selected": ["Product Name 1", "Product Name 2"]}
    PROMPT
  },

  # ── Scene Selection ────────────────────────────────────────
  {
    key: "default_scene_selection",
    surface: "scene_selection",
    template_text: <<~PROMPT
      You are matching a brand to a background scene for a referral banner.

      Brand: {brand_name} ({category}, {vibe})
      Colors: {colors}

      Available scenes:
      {scene_descriptions}

      Pick the single best scene that matches this brand's aesthetic. Return JSON: {"selected_scene_id": <id>}
    PROMPT
  },

  # ── Referral Banner Generation ─────────────────────────────
  {
    key: "default_referral_banner",
    surface: "referral_banner",
    template_text: <<~PROMPT
      Create a wide marketing banner image (21:9 aspect ratio) for a referral program.

      Brand: {brand_name} — a {category} brand with a {vibe} style.
      Brand colors: {colors}

      {scene_description}

      Feature these products prominently: {product_names}

      Requirements:
      - Clean, professional marketing imagery
      - Products should be the focal point
      - Use the brand colors as accents
      - Wide panoramic composition suitable for a website banner
      - No text or words in the image
      - Photorealistic style
    PROMPT
  },

  # ── Food-specific referral banner ──────────────────────────
  {
    key: "food_referral_banner",
    category: "food",
    surface: "referral_banner",
    template_text: <<~PROMPT
      Create a wide marketing banner image (21:9 aspect ratio) for a food/beverage brand's referral program.

      Brand: {brand_name} — {vibe} style.
      Brand colors: {colors}

      {scene_description}

      Feature these products: {product_names}

      Requirements:
      - Appetizing food photography style
      - Products as hero elements, styled as in a food magazine
      - Warm, inviting lighting
      - Natural textures (wood, linen, ceramic) as props
      - Brand colors as subtle accents
      - Wide panoramic composition
      - No text or words in the image
      - Photorealistic
    PROMPT
  },

  # ── Extension Card Generation ──────────────────────────────
  {
    key: "default_extension_card",
    surface: "extension_card",
    template_text: <<~PROMPT
      Create a marketing image (3:2 aspect ratio) for a checkout referral card.

      Brand: {brand_name} — a {category} brand with a {vibe} style.
      Brand colors: {colors}

      Feature these products: {product_names}

      Requirements:
      - Compact, eye-catching composition
      - Products clearly visible at small size
      - Brand colors prominent
      - Clean background, minimal distractions
      - No text or words in the image
      - Photorealistic style
    PROMPT
  },

  # ── OG Share Image ─────────────────────────────────────────
  {
    key: "default_og_image",
    surface: "og_image",
    template_text: <<~PROMPT
      Create a social media share preview image (16:9 aspect ratio) for a referral link.

      Brand: {brand_name} — a {category} brand with a {vibe} style.
      Brand colors: {colors}

      Feature these products: {product_names}

      Requirements:
      - Bold, attention-grabbing composition
      - Products clearly visible even at small thumbnail size
      - Strong brand color presence
      - Clean and professional
      - No text or words in the image
      - Photorealistic style
    PROMPT
  },

  # ── Quality Review ─────────────────────────────────────────
  {
    key: "default_quality_review",
    surface: "quality_review",
    template_text: <<~PROMPT
      You are a brand quality reviewer. Rate this generated marketing image for brand consistency.

      Brand: {brand_name} — a {category} brand with a {vibe} style.
      Brand colors: {colors}
      Products that should appear: {product_names}

      Rate the image on these criteria (1-10 each):
      1. Brand color accuracy — do the colors match?
      2. Product visibility — are the products clearly visible?
      3. Professional quality — does it look like professional marketing imagery?
      4. Composition — is the layout balanced and appealing?
      5. Overall brand fit — does it feel like it belongs to this brand?

      Return JSON: {"scores": {"color": N, "product": N, "quality": N, "composition": N, "brand_fit": N}, "overall": N, "feedback": "brief improvement suggestion if score < 7"}
    PROMPT
  }
]

templates.each do |attrs|
  existing = PromptTemplate.find_by(key: attrs[:key])
  if existing
    # Don't overwrite templates that were manually edited via superadmin
    puts "Exists: #{attrs[:key]} (skipped)"
  else
    PromptTemplate.create!(attrs)
    puts "Created: #{attrs[:key]}"
  end
end

puts "Done — #{PromptTemplate.count} prompt templates"
