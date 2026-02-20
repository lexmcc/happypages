module Analytics
  class CollectController < ActionController::API
    def create
      if request.content_length.to_i > 65_536
        head :payload_too_large
        return
      end

      ingester = EventIngester.new
      result = ingester.call(
        raw_body: request.raw_post,
        user_agent: request.user_agent,
        remote_ip: request.remote_ip
      )

      Rails.logger.info "[Analytics] Collect result: #{result}" unless result == :ok

      head :no_content
    end
  end
end
