class Admin::DashboardController < Admin::BaseController
  include Admin::ConfigSaving

  def index
    load_configs
    @shop = Current.shop
    @active_group = SharedDiscount.current(Current.shop)

    # Today's metrics
    base_scope = AnalyticsEvent.where(shop: Current.shop)
    today = Date.current.all_day

    @extension_loads_today = base_scope.extension_events
      .where(event_type: AnalyticsEvent::EXTENSION_LOAD, created_at: today).count
    @share_clicks_today = base_scope.extension_events
      .where(event_type: AnalyticsEvent::SHARE_CLICK, created_at: today).count
    @page_views_today = base_scope.referral_page_events
      .where(event_type: AnalyticsEvent::PAGE_LOAD, created_at: today).count
    @code_copies_today = base_scope.referral_page_events
      .where(event_type: AnalyticsEvent::COPY_CLICK, created_at: today).count
  end
end
