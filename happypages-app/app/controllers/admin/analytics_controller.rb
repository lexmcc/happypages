class Admin::AnalyticsController < Admin::BaseController
  def index
    @site = Current.shop&.analytics_sites&.active&.first

    unless @site
      domain = Current.shop.customer_facing_url
                 .sub(%r{\Ahttps?://}, "")
                 .sub(%r{/\z}, "")
      @site = Current.shop.analytics_sites.create!(domain: domain, name: Current.shop.name)
      return render :setup
    end

    @period = params[:period] || "30d"
    @metric = params[:metric] || "visitors"
    @compare = params[:compare] == "1"
    @filters = filter_params

    period_range = Analytics::DashboardQueryService.period_to_range(@period, from: params[:from], to: params[:to])
    comparison_range = @compare ? Analytics::DashboardQueryService.comparison_range_for(period_range) : nil

    @data = Analytics::DashboardQueryService.new(
      site: @site, period_range:, comparison_range:, filters: @filters
    ).call
  end

  private

  def filter_params
    return {} unless params[:filters].present?
    params[:filters].permit(
      :browser, :os, :device_type, :country_code, :pathname,
      :utm_source, :utm_medium, :utm_campaign, :referral_code
    ).to_h
  end
end
