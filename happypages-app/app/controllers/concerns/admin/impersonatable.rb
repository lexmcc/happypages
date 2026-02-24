module Admin::Impersonatable
  extend ActiveSupport::Concern

  included do
    before_action :check_impersonation_timeout
    helper_method :impersonating?
    helper_method :impersonated_shop
  end

  private

  def impersonating?
    session[:impersonating_shop_id].present?
  end

  def impersonated_shop
    return nil unless impersonating?
    @impersonated_shop ||= Shop.find_by(id: session[:impersonating_shop_id])
  end

  def check_impersonation_timeout
    return unless impersonating?

    if session[:impersonation_started_at].present? && session[:impersonation_started_at] < 4.hours.ago
      session.delete(:impersonating_shop_id)
      session.delete(:impersonation_started_at)
      redirect_to superadmin_root_path, alert: "Impersonation session expired"
    end
  end
end
