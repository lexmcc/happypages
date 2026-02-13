class Superadmin::BaseController < ApplicationController
  layout "superadmin"

  skip_before_action :set_current_shop
  before_action :check_session_timeout
  before_action :require_super_admin

  private

  def check_session_timeout
    return unless session[:super_admin]

    if session[:super_admin_last_seen].present? && session[:super_admin_last_seen] < 2.hours.ago
      reset_session
      redirect_to superadmin_login_path, alert: "Session expired, please log in again"
    end
    session[:super_admin_last_seen] = Time.current
  end

  def require_super_admin
    unless session[:super_admin]
      redirect_to superadmin_login_path, alert: "Please log in"
    end
  end

  def audit!(action:, shop:, resource: nil, details: {})
    AuditLog.log(
      action: action,
      actor: "super_admin",
      shop: shop,
      resource: resource,
      actor_ip: request.remote_ip,
      actor_identifier: session[:super_admin_email],
      details: details
    )
  end
end
