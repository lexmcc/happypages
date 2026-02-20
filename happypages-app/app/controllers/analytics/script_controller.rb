module Analytics
  class ScriptController < ActionController::API
    include ActionController::ConditionalGet

    SCRIPT_PATH = Rails.root.join("public", "analytics", "hp-analytics.js").freeze

    def show
      content = Rails.cache.fetch("hp-analytics-js", expires_in: 1.hour) do
        File.read(SCRIPT_PATH)
      end

      response.headers["Cache-Control"] = "public, max-age=86400"
      response.headers["Content-Type"] = "application/javascript; charset=utf-8"

      if stale?(etag: content)
        render plain: content
      end
    end
  end
end
