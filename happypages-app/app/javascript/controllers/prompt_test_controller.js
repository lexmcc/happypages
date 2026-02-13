import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["shopSelect", "runBtn", "result", "loading", "output"]

  async run() {
    const shopId = this.shopSelectTarget.value
    if (!shopId) {
      alert("Select a shop first")
      return
    }

    const url = this.runBtnTarget.dataset.url
    this.resultTarget.classList.remove("hidden")
    this.loadingTarget.classList.remove("hidden")
    this.outputTarget.innerHTML = ""
    this.runBtnTarget.disabled = true

    try {
      const token = document.querySelector('meta[name="csrf-token"]')?.content
      const response = await fetch(`${url}?shop_id=${shopId}`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": token,
          "Accept": "application/json"
        }
      })

      const data = await response.json()
      this.loadingTarget.classList.add("hidden")

      let html = ""

      // Show rendered prompt
      if (data.prompt) {
        html += `
          <details class="bg-gray-50 rounded-lg border border-gray-200 p-3">
            <summary class="text-xs font-medium text-gray-500 cursor-pointer">Rendered prompt</summary>
            <pre class="mt-2 text-xs text-gray-700 whitespace-pre-wrap font-mono">${this.escapeHtml(data.prompt)}</pre>
          </details>
        `
      }

      // Show generated image
      if (data.image) {
        html += `<img src="${data.image}" class="rounded-lg border border-gray-200 w-full" alt="Generated image" />`
      }

      // Show text result
      if (data.text) {
        html += `<pre class="bg-gray-50 rounded-lg border border-gray-200 p-3 text-xs text-gray-700 whitespace-pre-wrap font-mono">${this.escapeHtml(data.text)}</pre>`
      }

      // Show error
      if (data.error) {
        html += `<div class="bg-red-50 border border-red-200 rounded-lg p-3 text-sm text-red-700">${this.escapeHtml(data.error)}</div>`
      }

      this.outputTarget.innerHTML = html
    } catch (err) {
      this.loadingTarget.classList.add("hidden")
      this.outputTarget.innerHTML = `<div class="bg-red-50 border border-red-200 rounded-lg p-3 text-sm text-red-700">Request failed: ${this.escapeHtml(err.message)}</div>`
    } finally {
      this.runBtnTarget.disabled = false
    }
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
