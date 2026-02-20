class Superadmin::WebAnalyticsController < Superadmin::BaseController
  def index
    @sites = Analytics::Site.active.includes(:shop).order(:domain)
    @site = if params[:site_id].present?
      @sites.find_by(id: params[:site_id])
    else
      @sites.first
    end

    return render :no_site unless @site

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
