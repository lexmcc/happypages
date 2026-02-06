class Admin::SettingsController < Admin::BaseController

  def edit
    @shop = Current.shop
  end

  def update
    if params[:shop_slug].present? && Current.shop
      if Current.shop.update(slug: params[:shop_slug])
        redirect_to edit_admin_settings_path, notice: "Settings saved successfully!"
      else
        redirect_to edit_admin_settings_path, alert: "Could not update slug: #{Current.shop.errors.full_messages.join(', ')}"
      end
    else
      redirect_to edit_admin_settings_path
    end
  end
end
