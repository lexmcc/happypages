module Specs
  class GuestsController < ApplicationController
    layout "guest"
    skip_before_action :set_current_shop

    before_action :find_handoff
    before_action :check_not_expired
    before_action :set_current_shop_from_handoff
    before_action :require_accepted, only: [:show, :message]

    def join
      if @handoff.accepted?
        redirect_to specs_guest_session_path(@handoff.invite_token)
        return
      end

      if params[:name].present?
        @handoff.update!(
          to_name: params[:name],
          invite_accepted_at: Time.current
        )
        session[:specs_guest_token] = @handoff.invite_token
        redirect_to specs_guest_session_path(@handoff.invite_token)
      end
      # Otherwise render the join form
    end

    def show
      @session = @handoff.session
      @project = @session.project
      @messages = @session.messages.order(:turn_number, :created_at)
      @handoffs = @session.handoffs.accepted.to_a
    end

    def message
      spec_session = @handoff.session
      result = ::Specs::Orchestrator.new(spec_session).process_turn(
        params[:message].to_s.strip,
        user: nil,
        active_user: {
          name: @handoff.to_name,
          role: @handoff.to_role || "client"
        }
      )

      if result[:error]
        status = result[:type] == :max_tokens ? :unprocessable_entity : :internal_server_error
        render json: { error: result[:error] }, status: status
      else
        render json: result
      end
    rescue AnthropicClient::RateLimitError
      render json: { error: "Too many requests. Please wait a moment and try again." }, status: :too_many_requests
    rescue AnthropicClient::Error => e
      Rails.logger.error "[Specs Guest] Anthropic error: #{e.message}"
      render json: { error: "Something went wrong. Please try again." }, status: :internal_server_error
    end

    private

    def find_handoff
      @handoff = ::Specs::Handoff.find_by!(invite_token: params[:token])
    rescue ActiveRecord::RecordNotFound
      redirect_to root_path, alert: "Invalid or expired invite link."
    end

    def check_not_expired
      if @handoff.expired?
        redirect_to root_path, alert: "This invite link has expired."
      end
    end

    def set_current_shop_from_handoff
      shop = @handoff.session.shop
      Current.shop = shop if shop
    end

    def require_accepted
      unless @handoff.accepted?
        redirect_to specs_guest_join_path(@handoff.invite_token)
      end
    end
  end
end
