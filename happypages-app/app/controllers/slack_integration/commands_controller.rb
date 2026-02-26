module SlackIntegration
  class CommandsController < ActionController::API
    include SlackIntegration::RequestVerification

    def create
      text = params[:text].to_s.strip
      subcommand, *args = text.split(" ")

      case subcommand&.downcase
      when "new"
        project_name = args.join(" ").presence || "Untitled Project"
        enqueue_new_project(project_name)
        render json: { response_type: "ephemeral", text: "Creating project \"#{project_name}\"..." }
      when "help"
        render json: help_response
      else
        render json: help_response
      end
    end

    private

    def enqueue_new_project(project_name)
      Specs::SlackCommandJob.perform_later(
        team_id: params[:team_id],
        channel_id: params[:channel_id],
        slack_user_id: params[:user_id],
        project_name: project_name,
        response_url: params[:response_url]
      )
    end

    def help_response
      {
        response_type: "ephemeral",
        text: "*Speccy Commands*\n`/spec new [project name]` — Start a new spec interview\n`/spec help` — Show this help message"
      }
    end
  end
end
