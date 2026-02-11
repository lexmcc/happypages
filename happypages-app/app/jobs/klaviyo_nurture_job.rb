class KlaviyoNurtureJob < ApplicationJob
  queue_as :default

  def perform
    Shop.active.find_each do |shop|
      Current.shop = shop

      klaviyo_key = shop.klaviyo_credentials[:api_key]
      next unless klaviyo_key.present?

      delay_days = shop.discount_configs.find_by(config_key: "klaviyo_reminder_delay_days")&.config_value&.to_i || 3

      shared_emails = shop.analytics_events.where(event_type: AnalyticsEvent::SHARE_CLICK).select(:email)

      eligible = shop.referrals
        .where(reminder_sent_at: nil)
        .where("created_at < ?", delay_days.days.ago)
        .where.not(email: shared_emails)

      klaviyo = KlaviyoService.new(klaviyo_key)

      eligible.find_each do |referral|
        klaviyo.track_share_reminder(referral)
        referral.update_column(:reminder_sent_at, Time.current)
      rescue => e
        Rails.logger.error("[KlaviyoNurtureJob] Failed for #{referral.email}: #{e.message}")
      end
    end
  end
end
