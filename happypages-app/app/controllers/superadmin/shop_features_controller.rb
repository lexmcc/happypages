class Superadmin::ShopFeaturesController < Superadmin::BaseController
  before_action :set_shop

  def create
    feature = @shop.shop_features.build(feature_params)
    feature.activated_at = Time.current if feature.status == "active"

    if feature.save
      audit!(action: "create", shop: @shop, details: { feature: feature.feature, status: feature.status })
      redirect_to manage_superadmin_shop_path(@shop), notice: "Feature #{feature.feature} added"
    else
      redirect_to manage_superadmin_shop_path(@shop), alert: feature.errors.full_messages.join(", ")
    end
  end

  def update
    feature = @shop.shop_features.find(params[:id])
    if feature.update(feature_params)
      audit!(action: "update", shop: @shop, details: { feature: feature.feature, status: feature.status })
      redirect_to manage_superadmin_shop_path(@shop), notice: "Feature #{feature.feature} updated"
    else
      redirect_to manage_superadmin_shop_path(@shop), alert: feature.errors.full_messages.join(", ")
    end
  end

  def destroy
    feature = @shop.shop_features.find(params[:id])
    feature.destroy!
    audit!(action: "delete", shop: @shop, details: { feature: feature.feature })
    redirect_to manage_superadmin_shop_path(@shop), notice: "Feature #{feature.feature} removed"
  end

  private

  def set_shop
    @shop = Shop.find(params[:shop_id])
  end

  def feature_params
    params.require(:shop_feature).permit(:feature, :status)
  end
end
