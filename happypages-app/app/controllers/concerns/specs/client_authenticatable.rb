module Specs
  module ClientAuthenticatable
    extend ActiveSupport::Concern

    included do
      helper_method :current_specs_client
      before_action :require_specs_client
    end

    private

    def current_specs_client
      return @current_specs_client if defined?(@current_specs_client)
      @current_specs_client = if session[:specs_client_id]
        ::Specs::Client.find_by(id: session[:specs_client_id])
      end
    end

    def require_specs_client
      unless current_specs_client
        redirect_to specs_login_path, alert: "please log in."
        return
      end

      if session[:specs_last_seen].present? && session[:specs_last_seen] < 24.hours.ago
        reset_session
        redirect_to specs_login_path, alert: "session expired, please log in again."
        return
      end

      session[:specs_last_seen] = Time.current
    end
  end
end
