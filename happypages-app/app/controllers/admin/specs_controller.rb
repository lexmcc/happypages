class Admin::SpecsController < Admin::BaseController
  before_action :require_specs_feature
  before_action :set_project, only: [:show, :message, :complete]

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
    @session = active_session
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

  def project_params
    params.require(:specs_project).permit(:name, :context_briefing)
  end
end
