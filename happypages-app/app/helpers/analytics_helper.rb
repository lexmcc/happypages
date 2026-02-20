module AnalyticsHelper
  COUNTRY_NAMES = {
    "US" => "United States", "GB" => "United Kingdom", "CA" => "Canada",
    "AU" => "Australia", "DE" => "Germany", "FR" => "France", "NL" => "Netherlands",
    "IE" => "Ireland", "ES" => "Spain", "IT" => "Italy", "BR" => "Brazil",
    "IN" => "India", "JP" => "Japan", "KR" => "South Korea", "CN" => "China",
    "SE" => "Sweden", "NO" => "Norway", "DK" => "Denmark", "FI" => "Finland",
    "PT" => "Portugal", "PL" => "Poland", "BE" => "Belgium", "AT" => "Austria",
    "CH" => "Switzerland", "NZ" => "New Zealand", "MX" => "Mexico", "SG" => "Singapore",
    "ZA" => "South Africa", "IL" => "Israel", "AE" => "UAE", "CZ" => "Czech Republic"
  }.freeze

  def format_analytics_currency(amount, currency = "GBP")
    symbol = currency == "USD" ? "$" : "£"
    "#{symbol}#{number_with_delimiter(sprintf('%.2f', amount))}"
  end

  def format_analytics_duration(seconds)
    return "0s" if seconds.nil? || seconds <= 0
    mins = (seconds / 60).floor
    secs = (seconds % 60).round
    mins > 0 ? "#{mins}m #{secs}s" : "#{secs}s"
  end

  def format_analytics_number(value)
    if value >= 1_000_000
      "#{(value / 1_000_000.0).round(1)}M"
    elsif value >= 10_000
      "#{(value / 1_000.0).round(1)}K"
    else
      number_with_delimiter(value)
    end
  end

  def country_flag(code)
    return "" if code.blank?
    code.upcase.chars.map { |c| (c.ord + 127397).chr("UTF-8") }.join
  end

  def country_name(code)
    COUNTRY_NAMES[code&.upcase] || code&.upcase || "Unknown"
  end

  def change_indicator(pct)
    return "" if pct.nil?
    if pct > 0
      content_tag(:span, raw("&#9650; #{pct}%"), class: "text-emerald-600 text-xs font-medium tabular-nums")
    elsif pct < 0
      content_tag(:span, raw("&#9660; #{pct.abs}%"), class: "text-red-500 text-xs font-medium tabular-nums")
    else
      content_tag(:span, "0%", class: "text-gray-400 text-xs font-medium tabular-nums")
    end
  end

  def analytics_period_label(period)
    case period
    when "today" then "Today"
    when "7d" then "7 days"
    when "30d" then "30 days"
    when "90d" then "90 days"
    when "custom" then "Custom"
    else "30 days"
    end
  end

  def analytics_metric_color(metric)
    case metric.to_s
    when "visitors" then "#0072B2"
    when "pageviews" then "#E69F00"
    when "revenue", "rpv" then "#009E73"
    else "#0072B2"
    end
  end
end
