class SessionsController < ApplicationController
  layout "public", only: [:new, :create]
  skip_before_action :set_current_shop

  def new
    if current_user
      redirect_to admin_dashboard_path
    end
  end

  def create
    user = User.find_by("LOWER(email) = ?", params[:email].to_s.downcase.strip)

    if user.nil? || !user.authenticate(params[:password].to_s)
      flash.now[:alert] = "invalid email or password."
      return render :new, status: :unprocessable_entity
    end

    if user.shop&.suspended?
      flash.now[:alert] = "your shop has been suspended. please contact support."
      return render :new, status: :unprocessable_entity
    end

    # Success — set session
    return_to = session.delete(:return_to)
    reset_session
    session[:user_id] = user.id
    session[:last_seen] = Time.current
    user.update_column(:last_sign_in_at, Time.current)

    redirect_to return_to || admin_dashboard_path, notice: "you're now logged in."
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "logged out."
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end
end
