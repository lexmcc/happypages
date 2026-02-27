import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }
  static targets = ["badge"]

  connect() {
    this.poll()
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  poll() {
    if (!this.urlValue) return

    fetch(this.urlValue, {
      headers: { "Accept": "application/json" },
      credentials: "same-origin"
    })
      .then(r => {
        if (!r.ok) throw new Error("not ok")
        return r.json()
      })
      .then(data => {
        this.updateBadge(data.unread_count)
        this.timer = setTimeout(() => this.poll(), 30000)
      })
      .catch(() => {
        this.timer = setTimeout(() => this.poll(), 60000)
      })
  }

  updateBadge(count) {
    if (count > 0) {
      this.badgeTarget.textContent = count > 99 ? "99+" : count
      this.badgeTarget.classList.remove("hidden")
    } else {
      this.badgeTarget.classList.add("hidden")
    }
  }
}
