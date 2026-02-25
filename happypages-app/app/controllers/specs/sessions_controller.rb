module Specs
  class SessionsController < ApplicationController
    layout "client"
    skip_before_action :set_current_shop

    def new
      if session[:specs_client_id] && ::Specs::Client.find_by(id: session[:specs_client_id])
        redirect_to specs_dashboard_path
      end
    end

    def create
      client = ::Specs::Client.find_by(email: params[:email]&.downcase&.strip)

      if client&.authenticate(params[:password])
        reset_session
        session[:specs_client_id] = client.id
        session[:specs_last_seen] = Time.current
        client.update_column(:last_sign_in_at, Time.current)
        redirect_to specs_dashboard_path
      else
        flash.now[:alert] = "invalid email or password."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      reset_session
      redirect_to specs_login_path, notice: "logged out."
    end
  end
end
