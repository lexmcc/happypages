class Admin::SpecsController < Admin::BaseController
  before_action :require_specs_feature
  before_action :set_project, only: [:show, :message, :complete, :export, :new_version]

  def index
    @projects = Current.shop.specs_projects.order(created_at: :desc)
  end

  def new
    @project = Current.shop.specs_projects.new
  end

  def create
    @project = Current.shop.specs_projects.new(project_params)

    if @project.save
      @project.sessions.create!(shop: Current.shop, user: current_user)
      redirect_to admin_spec_path(@project)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @sessions = @project.sessions.order(version: :desc)
    @session = if params[:version].present?
      @project.sessions.find_by!(version: params[:version])
    else
      @sessions.first
    end
    @messages = @session.messages.order(:turn_number, :created_at)
  end

  def message
    session = active_session

    unless session
      return render json: { error: "No active session" }, status: :unprocessable_entity
    end

    user_text = params[:message].to_s.strip
    if user_text.blank?
      return render json: { error: "Message cannot be blank" }, status: :unprocessable_entity
    end

    image = params[:image]
    orchestrator = Specs::Orchestrator.new(session)
    result = orchestrator.process_turn(user_text, image: image)

    if result[:error]
      status = result[:type] == :max_tokens ? :unprocessable_entity : :internal_server_error
      render json: { error: result[:error] }, status: status
    else
      render json: result
    end
  rescue AnthropicClient::RateLimitError
    render json: { error: "Too many requests. Please wait a moment and try again." }, status: :too_many_requests
  rescue AnthropicClient::Error => e
    Rails.logger.error "[Specs] Anthropic error: #{e.message}"
    render json: { error: "Something went wrong. Please try again." }, status: :internal_server_error
  end

  def complete
    session = active_session
    if session
      session.update!(status: "completed")
    end
    redirect_to admin_spec_path(@project)
  end

  def export
    type = params[:type]
    return head(:bad_request) unless type.in?(%w[brief spec])

    session = find_session_for_version
    data = type == "brief" ? session.client_brief : session.team_spec
    return head(:not_found) unless data

    markdown = type == "brief" ? render_brief_markdown(data) : render_spec_markdown(data)
    filename = "#{@project.name.parameterize}-#{type}-v#{session.version}.md"
    send_data markdown, filename: filename, type: "text/markdown", disposition: :attachment
  end

  def new_version
    latest = @project.sessions.order(version: :desc).first
    @project.sessions.create!(
      shop: Current.shop,
      user: current_user,
      compressed_context: seed_context_from(latest)
    )
    redirect_to admin_spec_path(@project)
  end

  private

  def require_specs_feature
    unless Current.shop.feature_enabled?("specs")
      redirect_to admin_feature_path(feature_name: "specs")
    end
  end

  def set_project
    @project = Current.shop.specs_projects.find(params[:id])
  end

  def active_session
    @project.sessions.active.order(version: :desc).first
  end

  def find_session_for_version
    if params[:version].present?
      @project.sessions.find_by!(version: params[:version])
    else
      @project.sessions.order(version: :desc).first
    end
  end

  def project_params
    params.require(:specs_project).permit(:name, :context_briefing)
  end

  def render_brief_markdown(brief)
    lines = []
    lines << "# #{brief["title"]}"
    lines << ""
    lines << "**Goal:** #{brief["goal"]}"
    lines << ""
    Array(brief["sections"]).each do |section|
      lines << "## #{section["heading"]}"
      lines << ""
      lines << section["content"]
      lines << ""
    end
    lines.join("\n")
  end

  def render_spec_markdown(spec)
    lines = []
    lines << "# #{spec["title"]}"
    lines << ""
    lines << "**Goal:** #{spec["goal"]}"
    lines << ""
    lines << "**Approach:** #{spec["approach"]}"
    lines << ""

    Array(spec["chunks"]).each_with_index do |chunk, i|
      lines << "## #{i + 1}. #{chunk["title"]}"
      lines << ""
      lines << chunk["description"]
      lines << ""
      if chunk["acceptance_criteria"].present?
        lines << "### Acceptance Criteria"
        lines << ""
        Array(chunk["acceptance_criteria"]).each { |ac| lines << "- [ ] #{ac}" }
        lines << ""
      end
      if chunk["dependencies"].present?
        lines << "**Dependencies:** #{Array(chunk["dependencies"]).join(", ")}"
        lines << ""
      end
    end

    if spec["tech_notes"].present?
      lines << "## Tech Notes"
      lines << ""
      Array(spec["tech_notes"]).each { |note| lines << "- #{note}" }
      lines << ""
    end

    if spec["design_tokens"].present?
      lines << "## Design Tokens"
      lines << ""
      lines << "```json"
      lines << JSON.pretty_generate(spec["design_tokens"])
      lines << "```"
      lines << ""
    end

    if spec["open_questions"].present?
      lines << "## Open Questions"
      lines << ""
      Array(spec["open_questions"]).each { |q| lines << "- #{q}" }
      lines << ""
    end

    lines.join("\n")
  end

  def seed_context_from(previous)
    return nil unless previous

    parts = []
    if previous.client_brief.present?
      brief = previous.client_brief
      parts << "Previous brief: #{brief["title"]} — #{brief["goal"]}"
    end
    if previous.team_spec.present?
      spec = previous.team_spec
      parts << "Previous approach: #{spec["approach"]}"
      chunk_titles = Array(spec["chunks"]).map { |c| c["title"] }
      parts << "Previous chunks: #{chunk_titles.join(", ")}" if chunk_titles.any?
    end
    if previous.compressed_context.present?
      parts << "Session context: #{previous.compressed_context}"
    end
    parts.join("\n\n").presence
  end
end
