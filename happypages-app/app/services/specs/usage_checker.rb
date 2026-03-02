module Specs
  class UsageChecker
    TIERS = {
      "tier_1" => { name: "Tier 1", default_limit: 5 },
      "tier_2" => { name: "Tier 2", default_limit: 8 }
    }.freeze

    attr_reader :shop, :organisation

    def initialize(shop: nil, organisation: nil)
      @shop = shop
      @organisation = organisation
    end

    def can_create_session?
      return true if unlimited?
      used < limit
    end

    def usage
      { used: used, limit: limit, cycle_start: cycle_start, unlimited: unlimited? }
    end

    def limit_message
      return nil if can_create_session?
      "You've reached your session limit (#{used}/#{limit}) for this billing cycle."
    end

    private

    def used
      @used ||= completed_sessions_count
    end

    def limit
      @limit ||= read_limit
    end

    def unlimited?
      limit.nil? || limit.zero?
    end

    def cycle_start
      @cycle_start ||= calculate_cycle_start
    end

    def read_limit
      if shop
        feature = shop.shop_features.find_by(feature: "specs")
        feature&.metadata&.dig("monthly_limit")&.to_i
      elsif organisation
        organisation.specs_monthly_limit
      end
    end

    def completed_sessions_count
      if shop
        shop.specs_sessions.completed.where("created_at >= ?", cycle_start).count
      elsif organisation
        Specs::Session.joins(:project)
          .where(specs_projects: { organisation_id: organisation.id })
          .completed
          .where("specs_sessions.created_at >= ?", cycle_start)
          .count
      else
        0
      end
    end

    def calculate_cycle_start
      anchor_day = read_anchor_day
      today = Date.current

      if anchor_day
        day = [anchor_day, today.end_of_month.day].min
        candidate = today.change(day: day)
        candidate > today ? candidate.prev_month : candidate
      else
        today.beginning_of_month
      end
    end

    def read_anchor_day
      if shop
        feature = shop.shop_features.find_by(feature: "specs")
        date_str = feature&.metadata&.dig("billing_cycle_anchor")
        Date.parse(date_str).day if date_str.present?
      elsif organisation
        organisation.specs_billing_cycle_anchor&.day
      end
    rescue Date::Error
      nil
    end
  end
end
