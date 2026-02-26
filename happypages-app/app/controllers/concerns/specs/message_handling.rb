module Specs
  module MessageHandling
    extend ActiveSupport::Concern

    private

    def handle_message(adapter, text, image: nil, **kwargs)
      if text.blank?
        return render json: { error: "Message cannot be blank" }, status: :unprocessable_entity
      end

      result = adapter.process_message(text, image: image, **kwargs)

      if result[:error]
        status = result[:type] == :max_tokens ? :unprocessable_entity : :internal_server_error
        render json: { error: result[:error] }, status: status
      else
        render json: adapter.format_result(result)
      end
    rescue AnthropicClient::RateLimitError
      render json: { error: "Too many requests. Please wait a moment and try again." }, status: :too_many_requests
    rescue AnthropicClient::Error => e
      Rails.logger.error "[Specs] Anthropic error: #{e.message}"
      render json: { error: "Something went wrong. Please try again." }, status: :internal_server_error
    end
  end
end
