module Referrals
  class PerformanceQueryService
    attr_reader :shop, :period_range, :comparison_range

    def initialize(shop:, period_range:, comparison_range: nil)
      @shop = shop
      @period_range = period_range
      @comparison_range = comparison_range
    end

    def call
      {
        kpis: kpis,
        sparklines: sparklines,
        time_series: time_series,
        funnel: funnel,
        source_breakdown: source_breakdown,
        top_referrers: top_referrers
      }
    end

    # Reuse the same period helpers as the analytics service
    def self.period_to_range(period, from: nil, to: nil)
      case period
      when "today" then Date.current.beginning_of_day..Time.current
      when "7d"    then 7.days.ago..Time.current
      when "30d"   then 30.days.ago..Time.current
      when "90d"   then 90.days.ago..Time.current
      when "custom"
        return 30.days.ago..Time.current unless from.present? && to.present?
        Date.parse(from).beginning_of_day..Date.parse(to).end_of_day
      else 30.days.ago..Time.current
      end
    end

    def self.comparison_range_for(period_range)
      duration = period_range.last - period_range.first
      (period_range.first - duration)..period_range.first
    end

    private

    # --- Scopes ---

    def events_scope
      shop.referral_events.where(created_at: period_range)
    end

    def comparison_events_scope
      shop.referral_events.where(created_at: comparison_range)
    end

    def rewards_scope
      shop.referral_rewards.where(created_at: period_range)
    end

    def comparison_rewards_scope
      shop.referral_rewards.where(created_at: comparison_range)
    end

    # --- KPIs ---

    def kpis
      current = compute_kpis(events_scope, rewards_scope)

      if comparison_range
        previous = compute_kpis(comparison_events_scope, comparison_rewards_scope)
        current.each_key do |key|
          prev_val = previous[key][:value]
          curr_val = current[key][:value]
          current[key][:change] = compute_change(curr_val, prev_val)
        end
      end

      current
    end

    def compute_kpis(ev_scope, rw_scope)
      extension_loads = ev_scope.where(event_type: ReferralEvent::EXTENSION_LOAD).count
      page_visits = ev_scope.where(event_type: ReferralEvent::PAGE_LOAD).count
      share_clicks = ev_scope.where(event_type: ReferralEvent::SHARE_CLICK).count
      copy_clicks = ev_scope.where(event_type: ReferralEvent::COPY_CLICK).count
      shares_total = share_clicks + copy_clicks

      referred_orders = rw_scope.count
      revenue_cents = rw_scope.sum(:order_total_cents).to_i

      share_rate = extension_loads > 0 ? (shares_total.to_f / extension_loads * 100).round(1) : 0
      conversion_rate = extension_loads > 0 ? (referred_orders.to_f / extension_loads * 100).round(1) : 0

      {
        extension_loads: { value: extension_loads, change: nil },
        share_rate: { value: share_rate, change: nil },
        page_visits: { value: page_visits, change: nil },
        referred_orders: { value: referred_orders, change: nil },
        conversion_rate: { value: conversion_rate, change: nil },
        referred_revenue: { value: revenue_cents / 100.0, change: nil }
      }
    end

    # --- Sparklines (daily counts for mini-charts on KPI cards) ---

    def sparklines
      days = date_series

      extension_by_day = events_scope.where(event_type: ReferralEvent::EXTENSION_LOAD)
        .group("DATE(created_at)").count
      page_by_day = events_scope.where(event_type: ReferralEvent::PAGE_LOAD)
        .group("DATE(created_at)").count
      shares_by_day = events_scope.where(event_type: [ReferralEvent::SHARE_CLICK, ReferralEvent::COPY_CLICK])
        .group("DATE(created_at)").count
      orders_by_day = rewards_scope.group("DATE(created_at)").count
      revenue_by_day = rewards_scope.group("DATE(created_at)").sum(:order_total_cents)

      {
        extension_loads: days.map { |d| extension_by_day[d] || 0 },
        page_visits: days.map { |d| page_by_day[d] || 0 },
        shares: days.map { |d| shares_by_day[d] || 0 },
        referred_orders: days.map { |d| orders_by_day[d] || 0 },
        referred_revenue: days.map { |d| revenue_by_day[d].to_i / 100.0 }
      }
    end

    # --- Time series (for main chart, with comparison overlay) ---

    def time_series
      days = date_series

      result = build_time_series_for(days, events_scope, rewards_scope)

      if comparison_range
        comp_days = (comparison_range.first.to_date..comparison_range.last.to_date).to_a
        result[:comparison] = build_time_series_for(comp_days, comparison_events_scope, comparison_rewards_scope)
      end

      result
    end

    def build_time_series_for(days, ev_scope, rw_scope)
      extension_by_day = ev_scope.where(event_type: ReferralEvent::EXTENSION_LOAD)
        .group("DATE(created_at)").count
      page_by_day = ev_scope.where(event_type: ReferralEvent::PAGE_LOAD)
        .group("DATE(created_at)").count
      shares_by_day = ev_scope.where(event_type: [ReferralEvent::SHARE_CLICK, ReferralEvent::COPY_CLICK])
        .group("DATE(created_at)").count
      orders_by_day = rw_scope.group("DATE(created_at)").count
      revenue_by_day = rw_scope.group("DATE(created_at)").sum(:order_total_cents)

      {
        dates: days.map(&:iso8601),
        extension_loads: days.map { |d| extension_by_day[d] || 0 },
        page_visits: days.map { |d| page_by_day[d] || 0 },
        shares: days.map { |d| shares_by_day[d] || 0 },
        referred_orders: days.map { |d| orders_by_day[d] || 0 },
        referred_revenue: days.map { |d| revenue_by_day[d].to_i / 100.0 }
      }
    end

    # --- Funnel (4 stages with step-to-step conversion rates) ---

    def funnel
      ext_loads = events_scope.where(event_type: ReferralEvent::EXTENSION_LOAD).count
      page_visits = events_scope.where(event_type: ReferralEvent::PAGE_LOAD).count
      shares = events_scope.where(event_type: [ReferralEvent::SHARE_CLICK, ReferralEvent::COPY_CLICK]).count
      orders = rewards_scope.count

      {
        stages: [
          { key: :extension_loads, label: "Extension Loads", value: ext_loads },
          { key: :page_visits, label: "Page Visits", value: page_visits },
          { key: :shares, label: "Shares + Copies", value: shares },
          { key: :referred_orders, label: "Referred Orders", value: orders }
        ],
        conversion_rates: {
          load_to_visit: rate(page_visits, ext_loads),
          visit_to_share: rate(shares, page_visits),
          share_to_order: rate(orders, shares),
          overall: rate(orders, ext_loads)
        }
      }
    end

    # --- Source breakdown (how customers reach the referral page) ---

    def source_breakdown
      page_events = events_scope.where(event_type: ReferralEvent::PAGE_LOAD)
      total = page_events.count

      by_source = page_events.group(:source).count

      [
        { source: "checkout_extension", label: "From Extension", count: by_source[ReferralEvent::CHECKOUT_EXTENSION] || 0 },
        { source: "referral_page", label: "Direct", count: by_source[ReferralEvent::REFERRAL_PAGE] || 0 }
      ].map do |entry|
        entry[:pct] = total > 0 ? (entry[:count].to_f / total * 100).round(1) : 0
        entry
      end
    end

    # --- Top referrers ---

    def top_referrers
      join_sql = ActiveRecord::Base.sanitize_sql_array([
        "LEFT JOIN referral_rewards ON referral_rewards.referral_id = referrals.id AND referral_rewards.created_at BETWEEN ? AND ?",
        period_range.first, period_range.last
      ])

      shop.referrals
        .where("referrals.usage_count > 0")
        .joins(join_sql)
        .group("referrals.id")
        .order("referrals.usage_count DESC")
        .limit(10)
        .select("referrals.referral_code, referrals.usage_count, COALESCE(SUM(referral_rewards.order_total_cents), 0) AS period_revenue_cents")
        .map do |r|
          { referral_code: r.referral_code, usage_count: r.usage_count, revenue: r.period_revenue_cents.to_i / 100.0 }
        end
    end

    # --- Helpers ---

    def date_series
      start_date = period_range.first.to_date
      end_date = period_range.last.to_date
      (start_date..end_date).to_a
    end

    def rate(numerator, denominator)
      return 0 if denominator.nil? || denominator == 0
      (numerator.to_f / denominator * 100).round(1)
    end

    # Period comparison: show percentage when base > 10, absolute when <= 10
    def compute_change(current, previous)
      return nil if previous.nil?
      diff = current - previous
      if previous.is_a?(Float) || current.is_a?(Float)
        # Rate KPIs (share_rate, conversion_rate, revenue) — always show absolute change
        { absolute: diff.round(1), type: :absolute }
      elsif previous > 10
        pct = previous != 0 ? ((diff.to_f / previous) * 100).round(1) : (diff > 0 ? 100.0 : 0)
        { value: pct, type: :percentage }
      else
        { value: diff, type: :absolute }
      end
    end
  end
end
