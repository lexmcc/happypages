module Specs
  class ProjectsController < ApplicationController
    layout "client"
    skip_before_action :set_current_shop
    include Specs::ClientAuthenticatable

    before_action :set_project, only: [:show, :message, :export, :board_cards]

    def new
      @project = current_specs_client.organisation.specs_projects.new
    end

    def create
      @project = current_specs_client.organisation.specs_projects.new(project_params)

      if @project.save
        @project.sessions.create!(specs_client: current_specs_client)
        redirect_to specs_project_path(@project)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @session = @project.sessions.order(version: :desc).first
      return redirect_to specs_dashboard_path, alert: "no session found." unless @session

      @messages = @session.messages.order(:turn_number, :created_at)
      @handoffs = @session.handoffs.accepted.to_a
    end

    def message
      session_record = @project.sessions.active.order(version: :desc).first

      unless session_record
        return render json: { error: "No active session" }, status: :unprocessable_entity
      end

      user_text = params[:message].to_s.strip
      if user_text.blank?
        return render json: { error: "Message cannot be blank" }, status: :unprocessable_entity
      end

      orchestrator = ::Specs::Orchestrator.new(session_record)
      result = orchestrator.process_turn(
        user_text,
        user: nil,
        specs_client: current_specs_client,
        active_user: {
          name: current_specs_client.name || current_specs_client.email,
          role: "client"
        },
        tools: ::Specs::ToolDefinitions.v1_client
      )

      if result[:error]
        status = result[:type] == :max_tokens ? :unprocessable_entity : :internal_server_error
        render json: { error: result[:error] }, status: status
      else
        result.delete(:team_spec)
        render json: result
      end
    rescue AnthropicClient::RateLimitError
      render json: { error: "Too many requests. Please wait a moment and try again." }, status: :too_many_requests
    rescue AnthropicClient::Error => e
      Rails.logger.error "[Specs Client] Anthropic error: #{e.message}"
      render json: { error: "Something went wrong. Please try again." }, status: :internal_server_error
    end

    def board_cards
      cards = @project.cards.ordered.group_by(&:status)
      grouped = Specs::Card::STATUSES.each_with_object({}) do |status, hash|
        hash[status] = (cards[status] || []).map { |c| serialize_card(c) }
      end
      render json: grouped
    end

    def export
      return head(:bad_request) unless params[:type] == "brief"

      session_record = @project.sessions.order(version: :desc).first
      data = session_record&.client_brief
      return head(:not_found) unless data

      markdown = render_brief_markdown(data)
      filename = "#{@project.name.parameterize}-brief-v#{session_record.version}.md"
      send_data markdown, filename: filename, type: "text/markdown", disposition: :attachment
    end

    private

    def set_project
      @project = current_specs_client.organisation.specs_projects.find(params[:id])
    end

    def project_params
      params.require(:specs_project).permit(:name, :context_briefing)
    end

    def serialize_card(card)
      {
        id: card.id,
        title: card.title,
        description: card.description,
        acceptance_criteria: card.acceptance_criteria,
        has_ui: card.has_ui,
        dependencies: card.dependencies,
        status: card.status,
        position: card.position,
        chunk_index: card.chunk_index
      }
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
  end
end
