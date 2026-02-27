class Admin::LinearController < Admin::BaseController
  def install
    session[:linear_oauth_state] = SecureRandom.urlsafe_base64(32)

    params = {
      client_id: ENV.fetch("LINEAR_CLIENT_ID"),
      redirect_uri: admin_linear_callback_url,
      state: session[:linear_oauth_state],
      response_type: "code",
      scope: "read write issues:create",
      prompt: "consent"
    }

    redirect_to "#{LinearClient::OAUTH_AUTHORIZE_URL}?#{params.to_query}", allow_other_host: true
  end

  def callback
    unless ActiveSupport::SecurityUtils.secure_compare(params[:state].to_s, session.delete(:linear_oauth_state).to_s)
      redirect_to edit_admin_integrations_path, alert: "Invalid OAuth state. Please try again."
      return
    end

    token = LinearClient.exchange_code(params[:code], admin_linear_callback_url)
    integration = Current.shop.shop_integrations.find_or_initialize_by(provider: "linear")
    integration.update!(linear_access_token: token, status: "active")

    # Auto-select team if only one
    client = LinearClient.new(token)
    teams = client.teams

    if teams.length == 1
      team = teams.first
      integration.update!(linear_team_id: team["id"])
      register_webhook!(client, integration, team["id"])
      redirect_to edit_admin_integrations_path, notice: "Linear connected (team: #{team["name"]})."
    else
      redirect_to edit_admin_integrations_path, notice: "Linear connected. Please select a team."
    end
  rescue LinearClient::Error => e
    Rails.logger.error "[Linear OAuth] #{e.message}"
    redirect_to edit_admin_integrations_path, alert: "Failed to connect Linear: #{e.message}"
  end

  def teams
    integration = Current.shop.shop_integrations.active.find_by(provider: "linear")
    return render json: { error: "Linear not connected" }, status: :unprocessable_entity unless integration&.linear_connected?

    client = LinearClient.new(integration.linear_access_token)
    render json: client.teams
  rescue LinearClient::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def select_team
    integration = Current.shop.shop_integrations.active.find_by(provider: "linear")
    return redirect_to edit_admin_integrations_path, alert: "Linear not connected." unless integration&.linear_connected?

    team_id = params[:team_id]
    return redirect_to edit_admin_integrations_path, alert: "No team selected." if team_id.blank?

    client = LinearClient.new(integration.linear_access_token)
    integration.update!(linear_team_id: team_id)
    register_webhook!(client, integration, team_id)

    redirect_to edit_admin_integrations_path, notice: "Linear team selected."
  rescue LinearClient::Error => e
    Rails.logger.error "[Linear] Failed to register webhook: #{e.message}"
    redirect_to edit_admin_integrations_path, alert: "Team selected but webhook registration failed: #{e.message}"
  end

  def destroy
    integration = Current.shop.shop_integrations.find_by(provider: "linear")

    if integration
      # Best-effort cleanup
      if integration.linear_access_token.present?
        begin
          LinearClient.new(integration.linear_access_token).delete_webhook(integration.linear_webhook_id) if integration.linear_webhook_id.present?
        rescue LinearClient::Error => e
          Rails.logger.warn "[Linear] Webhook delete failed: #{e.message}"
        end
        begin
          LinearClient.revoke_token(integration.linear_access_token)
        rescue StandardError => e
          Rails.logger.warn "[Linear] Token revoke failed: #{e.message}"
        end
      end
      integration.destroy!
    end

    redirect_to edit_admin_integrations_path, notice: "Linear disconnected."
  end

  private

  def register_webhook!(client, integration, team_id)
    # Delete old webhook if exists
    if integration.linear_webhook_id.present?
      begin
        client.delete_webhook(integration.linear_webhook_id)
      rescue LinearClient::Error
        # Ignore — old webhook may already be gone
      end
    end

    webhook = client.create_webhook(team_id: team_id, url: linear_integration_webhooks_url)
    integration.update!(
      linear_webhook_id: webhook["id"],
      linear_webhook_secret: webhook["secret"]
    )
  end
end
