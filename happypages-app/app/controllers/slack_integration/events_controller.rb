module SlackIntegration
  class EventsController < ActionController::API
    include SlackIntegration::RequestVerification

    def create
      body = JSON.parse(request.raw_post)

      case body["type"]
      when "url_verification"
        render plain: body["challenge"], status: :ok
      when "event_callback"
        handle_event_callback(body)
      else
        head :ok
      end
    end

    private

    def handle_event_callback(body)
      event_id = body["event_id"]

      # Deduplicate retries (Slack may resend within 3s timeout)
      cache_key = "slack_event:#{event_id}"
      if Rails.cache.read(cache_key)
        head :ok
        return
      end
      Rails.cache.write(cache_key, true, expires_in: 5.minutes)

      event = body["event"] || {}

      # Ignore bot messages
      if event["bot_id"].present?
        head :ok
        return
      end

      # Only process threaded messages
      thread_ts = event["thread_ts"]
      if thread_ts.blank?
        head :ok
        return
      end

      Specs::SlackEventJob.perform_later(
        team_id: body["team_id"],
        channel_id: event["channel"],
        thread_ts: thread_ts,
        slack_user_id: event["user"],
        text: event["text"]
      )

      head :ok
    end
  end
end
