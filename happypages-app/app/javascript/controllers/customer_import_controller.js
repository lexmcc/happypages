import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }
  static targets = ["status", "progress"]

  connect() {
    // Start polling if an import is in progress
    this.poll()
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  poll() {
    if (!this.urlValue) return

    fetch(this.urlValue, { headers: { "Accept": "application/json" } })
      .then(r => r.json())
      .then(data => {
        if (data.status === "running" || data.status === "pending") {
          this.renderRunning(data)
          this.timer = setTimeout(() => this.poll(), 2000)
        } else if (data.status === "completed") {
          this.renderCompleted(data)
        } else if (data.status === "failed") {
          this.renderFailed(data)
        }
      })
      .catch(() => {
        // Retry on network error
        this.timer = setTimeout(() => this.poll(), 5000)
      })
  }

  renderRunning(data) {
    this.statusTarget.innerHTML = `
      <div class="flex items-center gap-3 p-4 bg-blue-50 border border-blue-200 rounded-lg">
        <svg class="animate-spin size-5 text-blue-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        <div>
          <p class="text-sm font-medium text-blue-800">Import in progress...</p>
          <p class="text-xs text-blue-600">${data.total_fetched} customers fetched, ${data.total_created} created, ${data.total_skipped} skipped</p>
        </div>
      </div>`

    // Disable the submit button
    const btn = this.element.querySelector("button[type=submit]")
    if (btn) {
      btn.disabled = true
      btn.textContent = "Importing..."
    }
  }

  renderCompleted(data) {
    this.statusTarget.innerHTML = `
      <div class="p-4 bg-emerald-50 border border-emerald-200 rounded-lg">
        <p class="text-sm font-medium text-emerald-800">Import completed</p>
        <p class="text-xs text-emerald-600">${data.total_created} imported, ${data.total_skipped} skipped</p>
      </div>`

    const btn = this.element.querySelector("button[type=submit]")
    if (btn) {
      btn.disabled = false
      btn.textContent = "Re-sync Customers"
    }
  }

  renderFailed(data) {
    this.statusTarget.innerHTML = `
      <div class="p-4 bg-red-50 border border-red-200 rounded-lg">
        <p class="text-sm font-medium text-red-800">Import failed</p>
        <p class="text-xs text-red-600">${data.error_message || "Unknown error"} (${data.total_created} created before failure)</p>
      </div>`

    const btn = this.element.querySelector("button[type=submit]")
    if (btn) {
      btn.disabled = false
      btn.textContent = "Retry Import"
    }
  }
}
