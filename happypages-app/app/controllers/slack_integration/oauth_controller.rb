module SlackIntegration
  class OauthController < ApplicationController
    include Specs::ClientAuthenticatable
    skip_before_action :set_current_shop
    skip_before_action :require_specs_client, only: [:callback]

    def install
      session[:slack_oauth_state] = SecureRandom.urlsafe_base64(32)

      scope = "chat:write,commands,app_mentions:read,im:history,channels:history,files:read,users:read,users:read.email"
      redirect_uri = slack_callback_url
      client_id = ENV["SLACK_CLIENT_ID"]

      redirect_to "https://slack.com/oauth/v2/authorize?client_id=#{client_id}&scope=#{scope}&redirect_uri=#{CGI.escape(redirect_uri)}&state=#{session[:slack_oauth_state]}", allow_other_host: true
    end

    def callback
      # Verify CSRF state
      unless ActiveSupport::SecurityUtils.secure_compare(params[:state].to_s, session.delete(:slack_oauth_state).to_s)
        redirect_to specs_login_path, alert: "Invalid OAuth state. Please try again."
        return
      end

      # Verify client session still valid
      client = Specs::Client.find_by(id: session[:specs_client_id])
      unless client
        redirect_to specs_login_path, alert: "Session expired. Please log in and try again."
        return
      end

      # Exchange code for token
      response = exchange_code(params[:code])
      unless response && response["ok"]
        error_msg = response&.dig("error") || "unknown error"
        redirect_to specs_dashboard_path, alert: "Slack connection failed: #{error_msg}"
        return
      end

      # Store credentials on organisation
      org = client.organisation
      org.update!(
        slack_team_id: response.dig("team", "id"),
        slack_bot_token: response["access_token"],
        slack_app_id: response["app_id"]
      )

      redirect_to specs_dashboard_path, notice: "Slack workspace connected successfully!"
    end

    private

    def exchange_code(code)
      uri = URI("https://slack.com/api/oauth.v2.access")
      response = Net::HTTP.post_form(uri, {
        client_id: ENV["SLACK_CLIENT_ID"],
        client_secret: ENV["SLACK_CLIENT_SECRET"],
        code: code,
        redirect_uri: slack_callback_url
      })
      JSON.parse(response.body)
    rescue StandardError => e
      Rails.logger.error "[Slack OAuth] Error exchanging code: #{e.message}"
      nil
    end
  end
end
