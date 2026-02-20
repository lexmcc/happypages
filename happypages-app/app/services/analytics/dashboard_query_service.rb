module Analytics
  class DashboardQueryService
    attr_reader :site, :period_range, :comparison_range, :filters

    def initialize(site:, period_range:, comparison_range: nil, filters: {})
      @site = site
      @period_range = period_range
      @comparison_range = comparison_range
      @filters = filters.to_h.symbolize_keys
    end

    def call
      {
        kpis: kpis,
        sparklines: sparklines,
        time_series: time_series,
        top_pages: top_pages,
        referrers: referrers,
        utm_campaigns: utm_campaigns,
        geography: geography,
        devices: devices,
        goals: goals,
        revenue_attribution: revenue_attribution,
        referral_performance: referral_performance
      }
    end

    # Class helpers for period ranges

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

    # --- Base scopes ---

    def events_scope
      scope = site.events.in_period(period_range)
      scope = apply_filters(scope)
      scope
    end

    def comparison_events_scope
      return nil unless comparison_range
      scope = site.events.in_period(comparison_range)
      scope = apply_filters(scope)
      scope
    end

    def payments_scope
      site.payments.where(created_at: period_range)
    end

    def comparison_payments_scope
      return nil unless comparison_range
      site.payments.where(created_at: comparison_range)
    end

    def apply_filters(scope)
      scope = scope.where(browser: filters[:browser]) if filters[:browser].present?
      scope = scope.where(os: filters[:os]) if filters[:os].present?
      scope = scope.where(device_type: filters[:device_type]) if filters[:device_type].present?
      scope = scope.where(country_code: filters[:country_code]) if filters[:country_code].present?
      scope = scope.where(pathname: filters[:pathname]) if filters[:pathname].present?
      scope = scope.where(utm_source: filters[:utm_source]) if filters[:utm_source].present?
      scope = scope.where(utm_medium: filters[:utm_medium]) if filters[:utm_medium].present?
      scope = scope.where(utm_campaign: filters[:utm_campaign]) if filters[:utm_campaign].present?
      scope = scope.where(referral_code: filters[:referral_code]) if filters[:referral_code].present?
      scope
    end

    # --- KPIs ---

    def kpis
      current = compute_kpis(events_scope, payments_scope)
      if comparison_range
        previous = compute_kpis(comparison_events_scope, comparison_payments_scope)
        current.each_key do |key|
          prev_val = previous[key][:value]
          curr_val = current[key][:value]
          current[key][:change_pct] = change_pct(curr_val, prev_val)
        end
      end
      current
    end

    def compute_kpis(ev_scope, pay_scope)
      visitors = ev_scope.distinct.count(:visitor_id)
      pageviews = ev_scope.pageviews.count
      revenue_cents = pay_scope.sum(:amount_cents)
      revenue = revenue_cents / 100.0

      {
        visitors: { value: visitors, change_pct: nil },
        pageviews: { value: pageviews, change_pct: nil },
        bounce_rate: { value: bounce_rate_for(ev_scope), change_pct: nil },
        avg_duration: { value: avg_duration_for(ev_scope), change_pct: nil },
        revenue: { value: revenue, change_pct: nil },
        rpv: { value: visitors > 0 ? (revenue / visitors).round(2) : 0, change_pct: nil }
      }
    end

    def bounce_rate_for(scope)
      total_sessions = scope.pageviews.distinct.count(:session_id)
      return 0 if total_sessions == 0

      bounced = scope.pageviews
        .group(:session_id)
        .having("COUNT(*) = 1")
        .count
        .size

      ((bounced.to_f / total_sessions) * 100).round(1)
    end

    def avg_duration_for(scope)
      subquery = scope.select(
        "session_id",
        "EXTRACT(EPOCH FROM (MAX(occurred_at) - MIN(occurred_at))) as session_duration"
      ).group(:session_id).having("COUNT(*) > 1").to_sql

      result = ActiveRecord::Base.connection.select_value(
        "SELECT AVG(session_duration) FROM (#{subquery}) sessions"
      )

      result&.to_f&.round(0) || 0
    end

    # --- Sparklines (daily counts for mini-charts) ---

    def sparklines
      days = date_series
      visitor_counts = events_scope.group("DATE(occurred_at)").distinct.count(:visitor_id)
      pageview_counts = events_scope.pageviews.group("DATE(occurred_at)").count
      revenue_by_day = payments_scope.group("DATE(created_at)").sum(:amount_cents)

      {
        visitors: days.map { |d| visitor_counts[d] || 0 },
        pageviews: days.map { |d| pageview_counts[d] || 0 },
        revenue: days.map { |d| (revenue_by_day[d] || 0) / 100.0 }
      }
    end

    def date_series
      start_date = period_range.first.to_date
      end_date = period_range.last.to_date
      (start_date..end_date).to_a
    end

    # --- Time series (for main chart) ---

    def time_series
      days = date_series
      visitor_counts = events_scope.group("DATE(occurred_at)").distinct.count(:visitor_id)
      pageview_counts = events_scope.pageviews.group("DATE(occurred_at)").count
      revenue_by_day = payments_scope.group("DATE(created_at)").sum(:amount_cents)

      result = {
        dates: days.map(&:iso8601),
        visitors: days.map { |d| visitor_counts[d] || 0 },
        pageviews: days.map { |d| pageview_counts[d] || 0 },
        revenue: days.map { |d| (revenue_by_day[d] || 0) / 100.0 }
      }

      if comparison_range
        comp_days = (comparison_range.first.to_date..comparison_range.last.to_date).to_a
        comp_visitors = comparison_events_scope.group("DATE(occurred_at)").distinct.count(:visitor_id)
        comp_pageviews = comparison_events_scope.pageviews.group("DATE(occurred_at)").count
        comp_revenue = comparison_payments_scope.group("DATE(created_at)").sum(:amount_cents)

        result[:comparison] = {
          dates: comp_days.map(&:iso8601),
          visitors: comp_days.map { |d| comp_visitors[d] || 0 },
          pageviews: comp_days.map { |d| comp_pageviews[d] || 0 },
          revenue: comp_days.map { |d| (comp_revenue[d] || 0) / 100.0 }
        }
      end

      result
    end

    # --- Top pages ---

    def top_pages
      pages = events_scope.pageviews
        .group(:pathname)
        .select(
          "pathname",
          "COUNT(*) as pageviews",
          "COUNT(DISTINCT visitor_id) as visitors"
        )
        .order("visitors DESC")
        .limit(10)

      pages.map do |row|
        {
          pathname: row.pathname,
          visitors: row.visitors,
          pageviews: row.pageviews
        }
      end
    end

    # --- Referrers ---

    def referrers
      events_scope.pageviews
        .where.not(referrer: [ nil, "" ])
        .select(
          "regexp_replace(referrer, '^https?://([^/]+).*', '\\1') as domain",
          "COUNT(DISTINCT visitor_id) as visitors"
        )
        .group("domain")
        .order("visitors DESC")
        .limit(10)
        .map { |r| { domain: r.domain, visitors: r.visitors } }
    end

    # --- UTM campaigns ---

    def utm_campaigns
      events_scope
        .where.not(utm_campaign: [ nil, "" ])
        .select(
          "utm_campaign",
          "utm_source",
          "utm_medium",
          "COUNT(DISTINCT visitor_id) as visitors"
        )
        .group(:utm_campaign, :utm_source, :utm_medium)
        .order("visitors DESC")
        .limit(10)
        .map do |r|
          {
            campaign: r.utm_campaign,
            source: r.utm_source,
            medium: r.utm_medium,
            visitors: r.visitors
          }
        end
    end

    # --- Geography ---

    def geography
      total = events_scope.distinct.count(:visitor_id)
      events_scope
        .where.not(country_code: [ nil, "" ])
        .select("country_code", "COUNT(DISTINCT visitor_id) as visitors")
        .group(:country_code)
        .order("visitors DESC")
        .limit(10)
        .map do |r|
          {
            country_code: r.country_code,
            visitors: r.visitors,
            pct: total > 0 ? (r.visitors.to_f / total * 100).round(1) : 0
          }
        end
    end

    # --- Devices ---

    def devices
      {
        browsers: top_dimension(:browser),
        os: top_dimension(:os),
        device_types: top_dimension(:device_type)
      }
    end

    def top_dimension(column)
      events_scope
        .where.not(column => [ nil, "" ])
        .select("#{column} as name", "COUNT(DISTINCT visitor_id) as visitors")
        .group(column)
        .order("visitors DESC")
        .limit(10)
        .map { |r| { name: r.name, visitors: r.visitors } }
    end

    # --- Goals (custom events) ---

    def goals
      total_visitors = events_scope.distinct.count(:visitor_id)

      events_scope.custom_events
        .select(
          "event_name",
          "COUNT(*) as triggers",
          "COUNT(DISTINCT visitor_id) as unique_visitors"
        )
        .group(:event_name)
        .order("triggers DESC")
        .limit(10)
        .map do |r|
          {
            event_name: r.event_name,
            triggers: r.triggers,
            unique_visitors: r.unique_visitors,
            conversion_rate: total_visitors > 0 ? (r.unique_visitors.to_f / total_visitors * 100).round(1) : 0
          }
        end
    end

    # --- Revenue attribution (first-touch) ---

    def revenue_attribution
      return [] unless site.payments.exists?

      sql = <<~SQL
        WITH first_touch AS (
          SELECT DISTINCT ON (visitor_id)
            visitor_id,
            COALESCE(NULLIF(utm_source, ''), regexp_replace(referrer, '^https?://([^/]+).*', '\\1'), 'Direct') as source
          FROM analytics_events
          WHERE analytics_site_id = :site_id
            AND occurred_at >= :start_at AND occurred_at <= :end_at
          ORDER BY visitor_id, occurred_at ASC
        )
        SELECT
          ft.source,
          COUNT(DISTINCT ft.visitor_id) as visitors,
          COUNT(DISTINCT p.id) as orders,
          COALESCE(SUM(p.amount_cents), 0) as revenue_cents
        FROM first_touch ft
        LEFT JOIN analytics_payments p
          ON p.visitor_id = ft.visitor_id AND p.analytics_site_id = :site_id
          AND p.created_at >= :start_at AND p.created_at <= :end_at
        GROUP BY ft.source
        ORDER BY revenue_cents DESC
        LIMIT 10
      SQL

      results = ActiveRecord::Base.connection.select_all(
        ActiveRecord::Base.sanitize_sql_array([
          sql,
          site_id: site.id,
          start_at: period_range.first,
          end_at: period_range.last
        ])
      )

      results.map do |row|
        revenue = row["revenue_cents"].to_i / 100.0
        visitors = row["visitors"].to_i
        {
          source: row["source"],
          visitors: visitors,
          orders: row["orders"].to_i,
          revenue: revenue,
          rpv: visitors > 0 ? (revenue / visitors).round(2) : 0
        }
      end
    end

    # --- Referral performance ---

    def referral_performance
      events_scope
        .where.not(referral_code: [ nil, "" ])
        .select(
          "referral_code",
          "COUNT(*) as pageviews",
          "COUNT(DISTINCT visitor_id) as visitors"
        )
        .group(:referral_code)
        .order("visitors DESC")
        .limit(10)
        .map do |r|
          payments = payments_scope.where(referral_code: r.referral_code)
          {
            referral_code: r.referral_code,
            visitors: r.visitors,
            pageviews: r.pageviews,
            orders: payments.count,
            revenue: payments.sum(:amount_cents) / 100.0
          }
        end
    end

    # --- Helpers ---

    def change_pct(current, previous)
      return nil if previous.nil?
      return nil if previous == 0 && current == 0
      return 100.0 if previous == 0
      ((current.to_f - previous) / previous * 100).round(1)
    end
  end
end
