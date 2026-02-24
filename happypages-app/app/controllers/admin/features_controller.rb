class Admin::FeaturesController < Admin::BaseController
  def show
    @feature_key = params[:feature_name]
    @feature_meta = SidebarHelper::FEATURE_NAV[@feature_key]

    unless @feature_meta
      head :not_found
      return
    end

    # If this feature is active, redirect to its dashboard
    if Current.shop.feature_enabled?(@feature_key)
      redirect_to admin_dashboard_path
      return
    end

    @shop_feature = Current.shop.shop_features.find_by(feature: @feature_key)
  end
end
