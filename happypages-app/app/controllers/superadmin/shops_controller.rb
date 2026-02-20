class Superadmin::ShopsController < Superadmin::BaseController
  before_action :set_shop, only: [ :show, :suspend, :reactivate, :rescrape_brand ]

  def index
    @shops = Shop.all.order(created_at: :desc)
    @shops = @shops.where(status: params[:status]) if params[:status].present? && Shop::STATUSES.include?(params[:status])
    @referral_counts = Referral.where(shop_id: @shops.select(:id)).group(:shop_id).count
  end

  def show
    audit!(action: "view", shop: @shop, details: { page: "super_admin_detail" })

    @referrals = @shop.referrals.includes(:referral_rewards).order(created_at: :desc)
    @referrals = @referrals.where(referral_code: params[:code]) if params[:code].present?
    @referrals = @referrals.limit(50)

    @campaigns = @shop.shared_discounts.includes(:discount_generations).order(created_at: :desc).limit(50)

    @analytics_totals = {
      extension_loads: @shop.referral_events.where(event_type: ReferralEvent::EXTENSION_LOAD).count,
      share_clicks: @shop.referral_events.where(event_type: ReferralEvent::SHARE_CLICK).count,
      page_views: @shop.referral_events.where(event_type: ReferralEvent::PAGE_LOAD).count,
      code_copies: @shop.referral_events.where(event_type: ReferralEvent::COPY_CLICK).count
    }

    @daily_events = @shop.referral_events
      .where(created_at: 30.days.ago..)
      .group(:event_type)
      .group("DATE(created_at)")
      .count
      .transform_keys { |(type, date)| [ type, date.to_date ] }

    @credential = @shop.integration_for(@shop.platform_type) || @shop.shop_credential
    @generation_logs = @shop.generation_logs.recent.limit(50)
  end

  def suspend
    @shop.update!(status: "suspended")
    audit!(action: "update", shop: @shop, details: { change: "suspended" })
    redirect_to superadmin_shop_path(@shop), notice: "Shop suspended"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to superadmin_shop_path(@shop), alert: "Failed to suspend: #{e.message}"
  end

  def reactivate
    unless @shop.suspended?
      redirect_to superadmin_shop_path(@shop), alert: "Only suspended shops can be reactivated"
      return
    end

    @shop.update!(status: "active")
    audit!(action: "update", shop: @shop, details: { change: "reactivated" })
    redirect_to superadmin_shop_path(@shop), notice: "Shop reactivated"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to superadmin_shop_path(@shop), alert: "Failed to reactivate: #{e.message}"
  end

  def rescrape_brand
    BrandScrapeJob.perform_later(@shop.id)
    audit!(action: "rescrape_brand", shop: @shop)
    redirect_to superadmin_shop_path(@shop), notice: "Brand scrape queued"
  end

  private

  def set_shop
    @shop = Shop.find(params[:id])
  end
end
