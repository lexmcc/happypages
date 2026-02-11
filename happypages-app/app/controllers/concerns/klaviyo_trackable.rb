module KlaviyoTrackable
  private

  def track_klaviyo(event, referral, **kwargs)
    api_key = Current.shop&.klaviyo_credentials&.dig(:api_key)
    return unless api_key.present?

    klaviyo = KlaviyoService.new(api_key)
    case event
    when :referral_created then klaviyo.track_referral_created(referral)
    when :referral_used    then klaviyo.track_referral_used(referral, **kwargs)
    when :reward_earned    then klaviyo.track_reward_earned(referral, **kwargs)
    when :share_click      then klaviyo.track_share_click(referral)
    end
  rescue => e
    Rails.logger.error("[Klaviyo] #{event} tracking failed: #{e.message}")
  end
end
