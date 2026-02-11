class EmbeddedController < ApplicationController
  skip_forgery_protection
  skip_before_action :set_current_shop

  layout "embedded"

  after_action :allow_shopify_iframe

  def show
  end

  private

  def allow_shopify_iframe
    response.headers["Content-Security-Policy"] = "frame-ancestors https://*.myshopify.com https://admin.shopify.com"
  end
end
