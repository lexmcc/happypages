class Admin::DashboardController < Admin::BaseController
  include Admin::ConfigSaving

  def index
    load_configs
    @shop = Current.shop
    @active_group = SharedDiscount.current(Current.shop)

    # Today's metrics
    base_scope = ReferralEvent.where(shop: Current.shop)
    today = Date.current.all_day

    @extension_loads_today = base_scope.extension_events
      .where(event_type: ReferralEvent::EXTENSION_LOAD, created_at: today).count
    @share_clicks_today = base_scope.extension_events
      .where(event_type: ReferralEvent::SHARE_CLICK, created_at: today).count
    @page_views_today = base_scope.referral_page_events
      .where(event_type: ReferralEvent::PAGE_LOAD, created_at: today).count
    @code_copies_today = base_scope.referral_page_events
      .where(event_type: ReferralEvent::COPY_CLICK, created_at: today).count
  end
end
