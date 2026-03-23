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
    elsif params[:klaviyo_api_key].present?
      integration = Current.shop.integration_for(Current.shop.platform_type)
      if integration
        integration.update!(klaviyo_api_key: params[:klaviyo_api_key])
      end

      credential = Current.shop.shop_credential || Current.shop.build_shop_credential
      credential.klaviyo_api_key = params[:klaviyo_api_key]
      credential.save!

      redirect_to edit_admin_integrations_path, notice: "Klaviyo connected successfully!"
    else
      redirect_to edit_admin_integrations_path, alert: "API key can't be blank."
    end
  end

  def destroy
    integration_name = params[:integration]

    case integration_name
    when "klaviyo"
      integration = Current.shop.integration_for(Current.shop.platform_type)
      integration&.update!(klaviyo_api_key: nil)

      credential = Current.shop.shop_credential
      credential&.update!(klaviyo_api_key: nil) if credential&.klaviyo_api_key.present?

      redirect_to edit_admin_integrations_path, notice: "Klaviyo disconnected."
    when "awtomic"
      integration = Current.shop.integration_for(Current.shop.platform_type)
      integration&.update!(awtomic_api_key: nil)

      credential = Current.shop.shop_credential
      credential&.update!(awtomic_api_key: nil) if credential&.awtomic_api_key.present?

      redirect_to edit_admin_integrations_path, notice: "Awtomic disconnected."
    else
      redirect_to edit_admin_integrations_path
    end
  end

  def test_klaviyo
    api_key = Current.shop.klaviyo_credentials[:api_key]

    unless api_key.present?
      redirect_to edit_admin_integrations_path, alert: "No Klaviyo API key configured."
      return
    end

    service = KlaviyoService.new(api_key)
    result = service.test_connection(email: current_user.email)

    if result[:success]
      redirect_to edit_admin_integrations_path, notice: "Test event sent to Klaviyo! Check your Klaviyo dashboard for an 'Integration Test' event."
    else
      redirect_to edit_admin_integrations_path, alert: "Klaviyo test failed: #{result[:error]}"
    end
  end
end
