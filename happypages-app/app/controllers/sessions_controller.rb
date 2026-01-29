class SessionsController < ApplicationController
  skip_before_action :set_current_shop

  def new
    # Show login page with "Install via Shopify" button
    if current_user
      redirect_to admin_config_path
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Logged out"
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end
end
