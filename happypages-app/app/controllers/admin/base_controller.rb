class Admin::BaseController < ApplicationController
  layout "admin"

  skip_before_action :set_current_shop
  before_action :check_session_timeout
  before_action :require_login
  before_action :set_current_shop_from_user

  private

  def check_session_timeout
    return unless session[:user_id].present?

    if session[:last_seen].present? && session[:last_seen] < 24.hours.ago
      reset_session
      redirect_to login_path, alert: "Session expired, please log in again"
    end
    session[:last_seen] = Time.current
  end

  def require_login
    unless current_user
      session[:return_to] = request.fullpath
      redirect_to login_path, alert: "Please log in"
    end
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end
  helper_method :current_user

  def set_current_shop_from_user
    Current.shop = current_user&.shop
  end
end
