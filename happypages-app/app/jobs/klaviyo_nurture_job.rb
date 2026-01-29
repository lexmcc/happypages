class KlaviyoNurtureJob < ApplicationJob
  queue_as :default

  def perform
    return unless ENV["KLAVIYO_API_KEY"].present?

    delay_days = DiscountConfig.find_by(config_key: "klaviyo_reminder_delay_days")&.config_value&.to_i || 3

    eligible = Referral
      .where(reminder_sent_at: nil)
      .where("created_at < ?", delay_days.days.ago)
      .where.not(email: AnalyticsEvent.where(event_type: AnalyticsEvent::SHARE_CLICK).select(:email))

    eligible.find_each do |referral|
      KlaviyoService.new.track_share_reminder(referral)
      referral.update_column(:reminder_sent_at, Time.current)
    rescue => e
      Rails.logger.error("[KlaviyoNurtureJob] Failed for #{referral.email}: #{e.message}")
    end
  end
end
