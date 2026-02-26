module SlackIntegration
  module RequestVerification
    extend ActiveSupport::Concern

    included do
      before_action :verify_slack_signature!
    end

    private

    def verify_slack_signature!
      signing_secret = ENV["SLACK_SIGNING_SECRET"]
      return head(:unauthorized) if signing_secret.blank?

      timestamp = request.headers["X-Slack-Request-Timestamp"]
      signature = request.headers["X-Slack-Signature"]

      return head(:unauthorized) if timestamp.blank? || signature.blank?
      return head(:unauthorized) if Time.now.to_i - timestamp.to_i > 300

      body = request.raw_post
      base = "v0:#{timestamp}:#{body}"
      computed = "v0=#{OpenSSL::HMAC.hexdigest("sha256", signing_secret, base)}"

      head(:unauthorized) unless ActiveSupport::SecurityUtils.secure_compare(computed, signature)
    end
  end
end
