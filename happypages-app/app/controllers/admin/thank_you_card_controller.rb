class Admin::ThankYouCardController < Admin::BaseController
  include Admin::ConfigSaving

  def edit
    load_configs
    @active_group = SharedDiscount.current(Current.shop)
  end

  def update
    save_configs(allowed_keys, allow_blank_keys)
    redirect_to edit_admin_thank_you_card_path, notice: "Thank-you card saved successfully!"
  end

  private

  def allowed_keys
    %w[extension_banner_image extension_heading extension_subtitle extension_button_text]
  end

  def allow_blank_keys
    %w[extension_banner_image]
  end
end
