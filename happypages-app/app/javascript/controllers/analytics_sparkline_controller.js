import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    data: Array,
    color: { type: String, default: "#0072B2" }
  }

  connect() {
    this.render()
  }

  render() {
    const data = this.dataValue
    if (!data || data.length === 0) return

    const width = this.element.clientWidth || 80
    const height = 48
    const max = Math.max(...data, 1)
    const min = Math.min(...data, 0)
    const range = max - min || 1

    const points = data.map((val, i) => {
      const x = (i / Math.max(data.length - 1, 1)) * width
      const y = height - ((val - min) / range) * (height - 4) - 2
      return `${x.toFixed(1)},${y.toFixed(1)}`
    }).join(" ")

    // Fill area points
    const fillPoints = `0,${height} ${points} ${width},${height}`

    this.element.innerHTML = `
      <svg width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" preserveAspectRatio="none" class="block">
        <polygon points="${fillPoints}" fill="${this.colorValue}" opacity="0.1" />
        <polyline points="${points}" fill="none" stroke="${this.colorValue}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" />
      </svg>
    `
  }
}
