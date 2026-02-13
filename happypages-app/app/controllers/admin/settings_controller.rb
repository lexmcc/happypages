class Admin::SettingsController < Admin::BaseController

  def edit
    @shop = Current.shop
  end

  def update
    if Current.shop
      attrs = {}
      attrs[:slug] = params[:shop_slug] if params[:shop_slug].present?
      attrs[:storefront_url] = params[:storefront_url].presence if params.key?(:storefront_url)

      if attrs.any? && Current.shop.update(attrs)
        sync_shop_slug_metafield(Current.shop) if attrs.key?(:slug)
        redirect_to edit_admin_settings_path, notice: "Settings saved successfully!"
      elsif attrs.empty?
        redirect_to edit_admin_settings_path
      else
        redirect_to edit_admin_settings_path, alert: "Could not save: #{Current.shop.errors.full_messages.join(', ')}"
      end
    else
      redirect_to edit_admin_settings_path
    end
  end

  private

  def sync_shop_slug_metafield(shop)
    return unless shop.shopify? && shop.slug.present?

    ShopMetafieldWriter.new(shop).write_slug
  rescue => e
    Rails.logger.error "Failed to sync shop slug metafield: #{e.message}"
  end
end
