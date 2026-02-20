class Superadmin::PromptTemplatesController < Superadmin::BaseController
  before_action :set_prompt_template, only: [ :edit, :update, :destroy, :test_generate ]

  def index
    @prompt_templates = PromptTemplate.order(:surface, :category, :key)
    @grouped = @prompt_templates.group_by(&:surface)
  end

  def new
    @prompt_template = PromptTemplate.new
  end

  def create
    @prompt_template = PromptTemplate.new(prompt_template_params)

    if @prompt_template.save
      redirect_to superadmin_prompt_templates_path, notice: "Template created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @prompt_template.update(prompt_template_params)
      redirect_to superadmin_prompt_templates_path, notice: "Template updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @prompt_template.destroy!
    redirect_to superadmin_prompt_templates_path, notice: "Template deleted"
  end

  # POST /superadmin/prompt_templates/:id/test_generate
  # Test a prompt template against a real shop's brand profile
  def test_generate
    shop = Shop.find(params[:shop_id])

    unless shop.brand_scraped?
      render json: { error: "Shop has no brand profile. Run a brand scrape first." }, status: :unprocessable_entity
      return
    end

    context = build_template_context(shop)
    rendered_prompt = @prompt_template.render(context)

    gemini = GeminiClient.new

    if @prompt_template.surface.in?(%w[referral_banner extension_card og_image])
      # Image generation test
      result = gemini.generate_image(rendered_prompt)
      if result
        render json: {
          prompt: rendered_prompt,
          image: "data:#{result[:mime_type]};base64,#{Base64.strict_encode64(result[:bytes])}",
          surface: @prompt_template.surface
        }
      else
        render json: { prompt: rendered_prompt, error: "No image generated" }, status: :unprocessable_entity
      end
    else
      # Text generation test
      result = gemini.generate_text(rendered_prompt)
      render json: { prompt: rendered_prompt, text: result }
    end
  rescue GeminiClient::Error => e
    render json: { prompt: rendered_prompt, error: e.message }, status: :unprocessable_entity
  end

  private

  def set_prompt_template
    @prompt_template = PromptTemplate.find(params[:id])
  end

  def prompt_template_params
    params.require(:prompt_template).permit(:key, :category, :surface, :template_text, :active)
  end

  def build_template_context(shop)
    profile = shop.brand_profile
    {
      category: profile["category"] || "general",
      vibe: profile["vibe"] || "",
      style: profile["style"] || "",
      colors: (profile["palette"] || []).join(", "),
      brand_name: shop.name,
      product_names: (profile["products"] || []).map { |p| p["title"] }.compact.join(", "),
      logo_url: profile["logo_url"] || "",
      storefront_description: profile["storefront_description"] || "",
      aspect_ratio: aspect_ratio_for(@prompt_template.surface),
      scene_description: profile["suggested_scene"] || "A clean, professional lifestyle scene"
    }
  end

  def aspect_ratio_for(surface)
    case surface
    when "referral_banner" then "21:9"
    when "extension_card" then "3:2"
    when "og_image" then "16:9"
    else "1:1"
    end
  end
end
