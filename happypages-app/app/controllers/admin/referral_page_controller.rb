class Admin::ReferralPageController < Admin::BaseController
  include Admin::ConfigSaving

  def edit
    load_configs
    @active_group = SharedDiscount.current(Current.shop)
  end

  def update
    save_configs(allowed_keys, allow_blank_keys)
    redirect_to edit_admin_referral_page_path, notice: "Referral page saved successfully!"
  end

  private

  def allowed_keys
    %w[
      referral_primary_color referral_secondary_color referral_background_color
      referral_banner_image referral_heading referral_subtitle
      referral_step_1 referral_step_2 referral_step_3
      referral_copy_button_text referral_back_button_text
    ]
  end

  def allow_blank_keys
    %w[
      referral_banner_image referral_heading referral_subtitle
      referral_step_1 referral_step_2 referral_step_3
      referral_copy_button_text referral_back_button_text
    ]
  end
end
