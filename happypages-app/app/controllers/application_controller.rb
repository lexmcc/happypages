class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_current_shop

  private

  # Set Current.shop for multi-tenant context
  # During transition: loads from session or falls back to first active shop
  # TODO: Phase 6 will add proper shop identification (domain, API key, etc.)
  def set_current_shop
    Current.shop = if session[:shop_id]
      Shop.find_by(id: session[:shop_id])
    else
      Shop.active.first
    end
  end
end
