class Admin::PerformanceController < Admin::BaseController
  def index
    @period = params[:period] || "30d"
    @metric = params[:metric] || "extension_loads"
    @compare = params[:compare] == "1"

    period_range = Referrals::PerformanceQueryService.period_to_range(
      @period, from: params[:from], to: params[:to]
    )
    comparison_range = @compare ? Referrals::PerformanceQueryService.comparison_range_for(period_range) : nil

    @data = Referrals::PerformanceQueryService.new(
      shop: Current.shop, period_range: period_range, comparison_range: comparison_range
    ).call

    @empty = Current.shop.referral_events.none?
  end
end
