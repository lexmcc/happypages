module LinearIntegration
  module RequestVerification
    extend ActiveSupport::Concern

    included do
      before_action :verify_linear_signature!
    end

    private

    def verify_linear_signature!
      body = request.raw_post
      @linear_payload = begin
        JSON.parse(body)
      rescue JSON::ParserError
        return head(:unauthorized)
      end

      # Look up webhook secret by team_id
      team_id = @linear_payload.dig("organizationId")
      integration = ShopIntegration.active.find_by(provider: "linear", linear_team_id: find_team_id)
      return head(:unauthorized) unless integration&.linear_webhook_secret.present?

      # Verify HMAC-SHA256 signature
      signature = request.headers["Linear-Signature"]
      return head(:unauthorized) if signature.blank?

      computed = OpenSSL::HMAC.hexdigest("sha256", integration.linear_webhook_secret, body)
      return head(:unauthorized) unless ActiveSupport::SecurityUtils.secure_compare(computed, signature)

      # Replay protection — reject if timestamp >60s old
      webhook_ts = @linear_payload["webhookTimestamp"]
      if webhook_ts.present?
        ts = Time.parse(webhook_ts) rescue nil
        return head(:unauthorized) if ts && (Time.current - ts).abs > 60
      end
    end

    def find_team_id
      # Linear webhook payloads include data.teamId for Issue events
      @linear_payload.dig("data", "teamId") || @linear_payload.dig("data", "team", "id")
    end
  end
end
