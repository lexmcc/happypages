class AdminController < ApplicationController
  skip_before_action :verify_authenticity_token

  def register_webhook
    # Simple token auth - check for admin secret
    admin_secret = ENV["ADMIN_SECRET"]
    provided_secret = request.headers["X-Admin-Secret"] || params[:secret]

    if admin_secret.present? && provided_secret != admin_secret
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end

    callback_url = ENV.fetch("WEBHOOK_CALLBACK_URL") do
      "https://app.happypages.co/webhooks/orders"
    end

    unless Current.shop
      return render json: { error: "No shop configured" }, status: :unprocessable_entity
    end

    service = ShopifyDiscountService.new(Current.shop)
    result = service.register_webhook(callback_url: callback_url)

    if result.dig("data", "webhookSubscriptionCreate", "userErrors")&.any?
      render json: {
        success: false,
        errors: result["data"]["webhookSubscriptionCreate"]["userErrors"]
      }, status: :unprocessable_entity
    elsif result["errors"]
      render json: {
        success: false,
        errors: result["errors"]
      }, status: :unprocessable_entity
    else
      webhook_id = result.dig("data", "webhookSubscriptionCreate", "webhookSubscription", "id")
      render json: {
        success: true,
        webhook_id: webhook_id,
        callback_url: callback_url
      }
    end
  end
end
