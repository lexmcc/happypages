module ShopIdentifiable
  extend ActiveSupport::Concern

  private

  def set_shop_from_header
    domain = request.headers["X-Shop-Domain"]

    unless domain.present?
      return render json: { error: "Missing X-Shop-Domain header" }, status: :bad_request
    end

    shop = Shop.active.find_by(domain: domain)

    unless shop
      return render json: { error: "Shop not found", signup_url: "/auth/shopify" }, status: :not_found
    end

    Current.shop = shop
  end
end
