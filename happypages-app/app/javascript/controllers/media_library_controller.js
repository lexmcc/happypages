import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone", "fileInput", "grid", "empty", "progress", "progressBar", "progressText", "error"]

  connect() {
    this.loadAssets()
  }

  // --- Drag & drop ---

  dragOver(event) {
    event.preventDefault()
  }

  dragEnter(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("border-[#ff584d]", "bg-[#ff584d]/5")
  }

  dragLeave(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-[#ff584d]", "bg-[#ff584d]/5")
  }

  drop(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-[#ff584d]", "bg-[#ff584d]/5")
    const file = event.dataTransfer.files[0]
    if (file) this.upload(file)
  }

  openFilePicker(event) {
    if (event.target === this.fileInputTarget) return
    this.fileInputTarget.click()
  }

  handleFileSelect(event) {
    const file = event.target.files[0]
    if (file) this.upload(file)
    this.fileInputTarget.value = ""
  }

  // --- Upload ---

  async upload(file) {
    this.hideError()
    this.showProgress()

    const formData = new FormData()
    formData.append("file", file)

    try {
      const response = await fetch("/admin/media_assets", {
        method: "POST",
        headers: { "X-CSRF-Token": this.csrfToken },
        body: formData
      })

      const data = await response.json()

      if (!response.ok) {
        this.showError(data.error || "Upload failed")
        return
      }

      this.prependAssetCard(data)
      this.updateEmptyState()
    } catch (err) {
      this.showError("Upload failed. Please try again.")
    } finally {
      this.hideProgress()
    }
  }

  // --- Delete ---

  async deleteAsset(event) {
    event.stopPropagation()
    const card = event.currentTarget.closest("[data-asset-id]")
    const id = card.dataset.assetId

    if (!confirm("Delete this image? This cannot be undone.")) return

    try {
      const response = await fetch(`/admin/media_assets/${id}`, {
        method: "DELETE",
        headers: { "X-CSRF-Token": this.csrfToken }
      })

      if (response.ok) {
        card.remove()
        this.updateEmptyState()
      } else {
        this.showError("Failed to delete image.")
      }
    } catch {
      this.showError("Failed to delete image.")
    }
  }

  // --- Load existing ---

  async loadAssets() {
    try {
      const response = await fetch("/admin/media_assets", {
        headers: { "Accept": "application/json" }
      })
      const assets = await response.json()
      this.gridTarget.innerHTML = ""
      assets.forEach(asset => this.appendAssetCard(asset))
      this.updateEmptyState()
    } catch {
      // Grid stays empty on error
    }
  }

  // --- Card rendering ---

  assetCardHTML(asset) {
    const sizeKB = Math.round(asset.byte_size / 1024)
    const sizeLabel = sizeKB >= 1024 ? `${(sizeKB / 1024).toFixed(1)} MB` : `${sizeKB} KB`
    const date = new Date(asset.created_at).toLocaleDateString()

    return `
      <div data-asset-id="${asset.id}" class="group relative bg-[#f4f4f0] rounded-xl border border-black/5 shadow-[inset_1px_1px_0_rgba(255,255,255,1),inset_-1px_-1px_0_rgba(0,0,0,0.05),0_4px_8px_rgba(0,0,0,0.05)] overflow-hidden">
        <div class="aspect-[3/2] overflow-hidden">
          <img src="${asset.thumbnail_url}" alt="${this.escapeHTML(asset.filename)}" class="w-full h-full object-cover" loading="lazy">
        </div>
        <div class="px-3 py-2">
          <p class="text-xs font-medium text-gray-700 truncate">${this.escapeHTML(asset.filename)}</p>
          <p class="text-xs text-gray-400">${sizeLabel} &middot; ${date}</p>
        </div>
        <button
          type="button"
          data-action="click->media-library#deleteAsset"
          class="absolute top-2 right-2 p-1.5 bg-white/90 rounded-lg border border-black/5 opacity-0 group-hover:opacity-100 transition-opacity hover:bg-red-50 hover:text-red-600"
          title="Delete"
        >
          <svg class="size-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
          </svg>
        </button>
      </div>
    `
  }

  prependAssetCard(asset) {
    this.gridTarget.insertAdjacentHTML("afterbegin", this.assetCardHTML(asset))
  }

  appendAssetCard(asset) {
    this.gridTarget.insertAdjacentHTML("beforeend", this.assetCardHTML(asset))
  }

  // --- UI helpers ---

  updateEmptyState() {
    const hasCards = this.gridTarget.children.length > 0
    this.emptyTarget.classList.toggle("hidden", hasCards)
  }

  showProgress() {
    this.progressTarget.classList.remove("hidden")
    this.progressBarTarget.style.width = "30%"
    this.progressTextTarget.textContent = "Uploading..."

    // Simulate progress (actual XHR progress not available with fetch)
    this._progressTimer = setInterval(() => {
      const current = parseFloat(this.progressBarTarget.style.width)
      if (current < 90) {
        this.progressBarTarget.style.width = `${current + 10}%`
      }
    }, 300)
  }

  hideProgress() {
    clearInterval(this._progressTimer)
    this.progressBarTarget.style.width = "100%"
    setTimeout(() => {
      this.progressTarget.classList.add("hidden")
      this.progressBarTarget.style.width = "0%"
    }, 300)
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  hideError() {
    this.errorTarget.classList.add("hidden")
  }

  escapeHTML(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}
