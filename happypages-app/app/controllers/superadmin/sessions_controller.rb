class Superadmin::SessionsController < ApplicationController
  layout "superadmin_login"

  skip_before_action :set_current_shop

  def new
    redirect_to superadmin_root_path if session[:super_admin]
  end

  def create
    email = params[:email].to_s.strip.downcase
    password = params[:password].to_s

    if valid_credentials?(email, password)
      reset_session
      session[:super_admin] = true
      session[:super_admin_email] = email
      session[:super_admin_last_seen] = Time.current
      redirect_to superadmin_root_path, notice: "Logged in"
    else
      Rails.logger.warn "[SuperAdmin] Failed login attempt for #{email.presence || '(blank)'} from #{request.remote_ip}"
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to superadmin_login_path, notice: "Logged out"
  end

  private

  def valid_credentials?(email, password)
    expected_email = ENV["SUPER_ADMIN_EMAIL"].to_s.strip.downcase
    digest = ENV["SUPER_ADMIN_PASSWORD_DIGEST"].to_s

    return false if expected_email.blank? || digest.blank?
    return false unless ActiveSupport::SecurityUtils.secure_compare(email, expected_email)

    BCrypt::Password.new(digest) == password
  rescue BCrypt::Errors::InvalidHash
    false
  end
end
