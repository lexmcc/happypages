class Admin::IntegrationsController < Admin::BaseController
  def edit
  end

  def update
    if params[:awtomic_api_key].present?
      # Write to ShopIntegration (primary) and ShopCredential (fallback, during transition)
      integration = Current.shop.integration_for(Current.shop.platform_type)
      if integration
        integration.update!(awtomic_api_key: params[:awtomic_api_key])
      end

      credential = Current.shop.shop_credential || Current.shop.build_shop_credential
      credential.awtomic_api_key = params[:awtomic_api_key]
      credential.save!

      redirect_to edit_admin_integrations_path, notice: "Awtomic connected successfully!"
    else
      redirect_to edit_admin_integrations_path, alert: "API key can't be blank."
    end
  end

  def destroy
    # Clear from ShopIntegration (primary)
    integration = Current.shop.integration_for(Current.shop.platform_type)
    integration&.update!(awtomic_api_key: nil)

    # Clear from ShopCredential (fallback, during transition)
    credential = Current.shop.shop_credential
    if credential&.awtomic_api_key.present?
      credential.update!(awtomic_api_key: nil)
      redirect_to edit_admin_integrations_path, notice: "Awtomic disconnected."
    else
      redirect_to edit_admin_integrations_path
    end
  end
end
