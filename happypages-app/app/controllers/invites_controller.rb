class InvitesController < ApplicationController
  layout "public"
  skip_before_action :set_current_shop

  before_action :find_user_by_token

  def show
  end

  def update
    if params[:password].blank?
      flash.now[:alert] = "password can't be blank."
      return render :show, status: :unprocessable_entity
    end

    if params[:password].length < 8
      flash.now[:alert] = "password must be at least 8 characters."
      return render :show, status: :unprocessable_entity
    end

    if params[:password] != params[:password_confirmation]
      flash.now[:alert] = "passwords don't match."
      return render :show, status: :unprocessable_entity
    end

    @user.password = params[:password]
    @user.password_confirmation = params[:password_confirmation]
    @user.invite_token = nil
    @user.invite_accepted_at = Time.current

    if @user.save
      reset_session
      session[:user_id] = @user.id
      session[:last_seen] = Time.current
      @user.update_column(:last_sign_in_at, Time.current)

      redirect_to admin_dashboard_path, notice: "password set. you're now logged in."
    else
      flash.now[:alert] = @user.errors.full_messages.join(", ")
      render :show, status: :unprocessable_entity
    end
  end

  private

  def find_user_by_token
    @user = User.find_by(invite_token: params[:token])
    unless @user
      redirect_to login_path, alert: "invalid or expired invite link."
    end
  end
end
