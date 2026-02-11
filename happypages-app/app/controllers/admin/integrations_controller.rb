class Admin::IntegrationsController < Admin::BaseController
  include Admin::ConfigSaving

  def edit
  end

  def update
    save_configs(allowed_keys)
    redirect_to edit_admin_integrations_path, notice: "Integration settings saved successfully!"
  end

  private

  def allowed_keys
    %w[klaviyo_reminder_delay_days]
  end
end
