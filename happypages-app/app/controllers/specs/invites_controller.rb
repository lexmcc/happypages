module Specs
  class InvitesController < ApplicationController
    layout "client"
    skip_before_action :set_current_shop

    before_action :find_client_by_token

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

      @client.password = params[:password]
      @client.password_confirmation = params[:password_confirmation]
      @client.invite_token = nil
      @client.invite_accepted_at = Time.current

      if @client.save
        reset_session
        session[:specs_client_id] = @client.id
        session[:specs_last_seen] = Time.current
        @client.update_column(:last_sign_in_at, Time.current)

        redirect_to specs_dashboard_path, notice: "password set. you're now logged in."
      else
        flash.now[:alert] = @client.errors.full_messages.join(", ")
        render :show, status: :unprocessable_entity
      end
    end

    private

    def find_client_by_token
      @client = ::Specs::Client.find_by(invite_token: params[:token])
      unless @client
        redirect_to specs_login_path, alert: "invalid or expired invite link."
      end
    end
  end
end
