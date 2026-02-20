import { Controller } from "@hotwired/stimulus"

const COLORS = {
  visitors: "#0072B2",
  pageviews: "#E69F00",
  revenue: "#009E73"
}

const COMPARISON_COLOR = "#CC79A7"

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    metrics: Object,   // { dates, visitors, pageviews, revenue, comparison? }
    activeMetric: { type: String, default: "visitors" }
  }

  connect() {
    this.chart = null
    this.renderChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }

  activeMetricValueChanged() {
    this.renderChart()
  }

  switchMetric({ params: { metric } }) {
    this.activeMetricValue = metric
    // Dispatch event so KPI cards can update active state
    this.dispatch("metricChanged", { detail: { metric } })
  }

  renderChart() {
    if (!this.hasCanvasTarget || !this.metricsValue?.dates) return

    if (this.chart) {
      this.chart.destroy()
    }

    const data = this.metricsValue
    const metric = this.activeMetricValue
    const color = COLORS[metric] || COLORS.visitors
    const values = data[metric] || []
    const labels = data.dates || []

    const datasets = [
      {
        label: this.metricLabel(metric),
        data: values,
        borderColor: color,
        backgroundColor: color + "1A",
        fill: true,
        tension: 0.3,
        pointRadius: 0,
        pointHitRadius: 8,
        borderWidth: 2
      }
    ]

    // Add comparison dataset if present
    if (data.comparison && data.comparison[metric]) {
      datasets.push({
        label: `Previous ${this.metricLabel(metric)}`,
        data: data.comparison[metric],
        borderColor: COMPARISON_COLOR,
        backgroundColor: "transparent",
        borderDash: [5, 5],
        fill: false,
        tension: 0.3,
        pointRadius: 0,
        pointHitRadius: 8,
        borderWidth: 1.5
      })
    }

    const ctx = this.canvasTarget.getContext("2d")
    this.chart = new Chart(ctx, {
      type: "line",
      data: { labels, datasets },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: "index",
          intersect: false
        },
        plugins: {
          legend: { display: datasets.length > 1 },
          tooltip: {
            callbacks: {
              label: (ctx) => {
                const val = ctx.parsed.y
                if (metric === "revenue") return `${ctx.dataset.label}: £${val.toFixed(2)}`
                return `${ctx.dataset.label}: ${val.toLocaleString()}`
              }
            }
          }
        },
        scales: {
          x: {
            grid: { display: false },
            ticks: {
              maxTicksLimit: 7,
              font: { family: "Inter, system-ui, sans-serif", size: 11 },
              color: "#9ca3af"
            }
          },
          y: {
            beginAtZero: true,
            grid: { color: "rgba(0,0,0,0.04)" },
            ticks: {
              font: { family: "Inter, system-ui, sans-serif", size: 11 },
              color: "#9ca3af",
              callback: (val) => {
                if (metric === "revenue") return `£${val}`
                if (val >= 1000) return `${(val / 1000).toFixed(1)}K`
                return val
              }
            }
          }
        }
      }
    })
  }

  metricLabel(metric) {
    return { visitors: "Visitors", pageviews: "Pageviews", revenue: "Revenue" }[metric] || metric
  }
}
