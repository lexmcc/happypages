class OverrideSchedulerJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Running override scheduler job"

    # Start pending overrides (where start time has passed but not yet applied)
    start_pending_overrides

    # End expired overrides (where end time has passed)
    end_expired_overrides

    Rails.logger.info "Override scheduler job completed"
  end

  private

  def start_pending_overrides
    SharedDiscount.where("override_starts_at <= ? AND override_applied = ?", Time.current, false)
                  .where.not(override_starts_at: nil)
                  .find_each do |group|
      Rails.logger.info "Starting override for group: #{group.name}"

      begin
        group.apply_override_to_shopify!
        group.update!(override_applied: true)
        Rails.logger.info "Override started successfully for: #{group.name}"
      rescue => e
        Rails.logger.error "Failed to start override for #{group.name}: #{e.message}"
      end
    end
  end

  def end_expired_overrides
    SharedDiscount.where("override_ends_at <= ? AND override_applied = ?", Time.current, true)
                  .where.not(override_ends_at: nil)
                  .find_each do |group|
      Rails.logger.info "Ending override for group: #{group.name}"

      begin
        group.clear_override!
        Rails.logger.info "Override ended successfully for: #{group.name}"
      rescue => e
        Rails.logger.error "Failed to end override for #{group.name}: #{e.message}"
      end
    end
  end
end
