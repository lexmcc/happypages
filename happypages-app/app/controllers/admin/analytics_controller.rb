class Admin::AnalyticsController < Admin::BaseController

  def index
    @period = params[:period] || "7d"
    @period_duration = period_to_duration(@period)

    # Base scope for analytics - scoped to current shop
    base_scope = ReferralEvent.all
    base_scope = base_scope.where(shop: Current.shop) if Current.shop

    # Checkout extension metrics
    @extension_loads = base_scope
      .extension_events
      .where(event_type: ReferralEvent::EXTENSION_LOAD)
      .in_period(@period_duration)
      .group_by_day(:created_at)
      .count

    @share_clicks = base_scope
      .extension_events
      .where(event_type: ReferralEvent::SHARE_CLICK)
      .in_period(@period_duration)
      .group_by_day(:created_at)
      .count

    @extension_total_loads = @extension_loads.values.sum
    @extension_total_clicks = @share_clicks.values.sum
    @extension_click_rate = @extension_total_loads > 0 ? (@extension_total_clicks.to_f / @extension_total_loads * 100).round(1) : 0

    # Referral page metrics
    @page_loads = base_scope
      .referral_page_events
      .where(event_type: ReferralEvent::PAGE_LOAD)
      .in_period(@period_duration)
      .group_by_day(:created_at)
      .count

    @copy_clicks = base_scope
      .referral_page_events
      .where(event_type: ReferralEvent::COPY_CLICK)
      .in_period(@period_duration)
      .group_by_day(:created_at)
      .count

    @page_total_loads = @page_loads.values.sum
    @page_total_clicks = @copy_clicks.values.sum
    @page_click_rate = @page_total_loads > 0 ? (@page_total_clicks.to_f / @page_total_loads * 100).round(1) : 0
  end

  private

  def period_to_duration(period)
    case period
    when "1d" then 1.day
    when "7d" then 7.days
    when "30d" then 30.days
    else 7.days
    end
  end
end
