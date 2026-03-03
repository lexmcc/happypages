module PerformanceHelper
  def performance_change_indicator(change)
    return "".html_safe if change.nil?

    if change[:type] == :percentage
      val = change[:value]
      if val > 0
        content_tag(:span, raw("&#9650; #{val}%"), class: "text-emerald-600 text-xs font-medium tabular-nums")
      elsif val < 0
        content_tag(:span, raw("&#9660; #{val.abs}%"), class: "text-red-500 text-xs font-medium tabular-nums")
      else
        content_tag(:span, "0%", class: "text-gray-400 text-xs font-medium tabular-nums")
      end
    else
      val = change[:absolute] || change[:value]
      if val > 0
        content_tag(:span, raw("&#9650; +#{val}"), class: "text-emerald-600 text-xs font-medium tabular-nums")
      elsif val < 0
        content_tag(:span, raw("&#9660; #{val}"), class: "text-red-500 text-xs font-medium tabular-nums")
      else
        content_tag(:span, "—", class: "text-gray-400 text-xs font-medium tabular-nums")
      end
    end
  end

  def performance_metric_color(metric)
    case metric.to_s
    when "extension_loads" then "#0072B2"
    when "shares" then "#E69F00"
    when "page_visits" then "#56B4E9"
    when "referred_orders" then "#009E73"
    when "referred_revenue" then "#D55E00"
    else "#0072B2"
    end
  end
end
