module Api
  class BaseController < ActionController::API
    include ShopIdentifiable
    before_action :set_shop_from_header
  end
end
