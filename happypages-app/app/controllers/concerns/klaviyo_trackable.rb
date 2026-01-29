module KlaviyoTrackable
  private

  def track_klaviyo(event, referral, **kwargs)
    return unless ENV["KLAVIYO_API_KEY"].present?

    case event
    when :referral_created
      KlaviyoService.new.track_referral_created(referral)
    when :referral_used
      KlaviyoService.new.track_referral_used(referral, **kwargs)
    when :reward_earned
      KlaviyoService.new.track_reward_earned(referral, **kwargs)
    when :share_click
      KlaviyoService.new.track_share_click(referral)
    end
  rescue => e
    Rails.logger.error("[Klaviyo] #{event} tracking failed: #{e.message}")
  end
end
