class Api::AnalyticsController < ApplicationController
  include KlaviyoTrackable
  include ShopIdentifiable
  skip_before_action :verify_authenticity_token
  skip_before_action :set_current_shop
  before_action :set_shop_from_header

  def create
    # sendBeacon() sends as text/plain, so parse JSON from raw body
    data = JSON.parse(request.raw_post)

    event = AnalyticsEvent.new(
      event_type: data["event_type"],
      source: data["source"],
      referral_code: data["referral_code"],
      email: data["email"],
      metadata: data["metadata"] || {},
      shop: Current.shop
    )

    if event.save
      if data["event_type"] == AnalyticsEvent::SHARE_CLICK && data["email"].present?
        # Scope referral lookup to current shop
        scope = Referral.all
        scope = scope.where(shop: Current.shop) if Current.shop
        referral = scope.find_by(email: data["email"])
        track_klaviyo(:share_click, referral) if referral
      end
      head :created
    else
      head :unprocessable_entity
    end
  rescue JSON::ParserError
    head :bad_request
  end
end
