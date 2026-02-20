import { Controller } from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo-rails"

export default class extends Controller {
  setPeriod(event) {
    event.preventDefault()
    const period = event.currentTarget.dataset.period
    const url = this.buildUrl({ period })
    Turbo.visit(url)
  }

  addFilter(event) {
    event.preventDefault()
    const key = event.currentTarget.dataset.filterKey
    const value = event.currentTarget.dataset.filterValue
    if (!key || !value) return

    const url = new URL(window.location.href)
    url.searchParams.set(`filters[${key}]`, value)
    Turbo.visit(url.toString())
  }

  removeFilter(event) {
    event.preventDefault()
    const key = event.currentTarget.dataset.filterKey
    if (!key) return

    const url = new URL(window.location.href)
    url.searchParams.delete(`filters[${key}]`)
    Turbo.visit(url.toString())
  }

  toggleCompare(event) {
    const url = new URL(window.location.href)
    if (url.searchParams.get("compare") === "1") {
      url.searchParams.delete("compare")
    } else {
      url.searchParams.set("compare", "1")
    }
    Turbo.visit(url.toString())
  }

  changeSite(event) {
    const siteId = event.currentTarget.value
    const url = this.buildUrl({ site_id: siteId })
    Turbo.visit(url)
  }

  buildUrl(overrides = {}) {
    const url = new URL(window.location.href)
    for (const [key, value] of Object.entries(overrides)) {
      if (value) {
        url.searchParams.set(key, value)
      } else {
        url.searchParams.delete(key)
      }
    }
    return url.toString()
  }
}
