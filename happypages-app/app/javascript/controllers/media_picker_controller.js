import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone", "fileInput", "grid", "hiddenField", "urlInput", "progress", "progressBar", "progressText", "error", "urlToggle", "urlSection"]
  static values = { context: String, current: String }

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
    if (this.contextValue) formData.append("context", this.contextValue)

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

      this.prependThumbnail(data)
      this.selectAsset(data)
    } catch (err) {
      this.showError("Upload failed. Please try again.")
    } finally {
      this.hideProgress()
    }
  }

  // --- Load & render thumbnails ---

  async loadAssets() {
    try {
      const surface = this.surfaceForContext()
      const url = surface
        ? `/admin/media_assets?surface=${surface}`
        : "/admin/media_assets"
      const response = await fetch(url, {
        headers: { "Accept": "application/json" }
      })
      const assets = await response.json()
      this.gridTarget.innerHTML = ""
      assets.forEach(asset => this.appendThumbnail(asset))
    } catch {
      // Silently fail — grid stays empty
    }
  }

  thumbnailHTML(asset) {
    const variantUrl = this.variantUrlFor(asset)
    const isSelected = this.currentValue && this.currentValue === variantUrl
    const ringClass = isSelected ? "ring-2 ring-[#ff584d] ring-offset-1" : ""

    return `
      <button
        type="button"
        data-asset-id="${asset.id}"
        data-variant-url="${this.escapeAttr(variantUrl)}"
        data-action="click->media-picker#pickAsset"
        class="relative aspect-[3/2] rounded-lg overflow-hidden border border-black/10 hover:border-[#ff584d]/40 transition-all cursor-pointer ${ringClass}"
        title="${this.escapeAttr(asset.filename)}"
      >
        <img src="${asset.thumbnail_url}" alt="${this.escapeAttr(asset.filename)}" class="w-full h-full object-cover" loading="lazy">
      </button>
    `
  }

  prependThumbnail(asset) {
    this.gridTarget.insertAdjacentHTML("afterbegin", this.thumbnailHTML(asset))
  }

  appendThumbnail(asset) {
    this.gridTarget.insertAdjacentHTML("beforeend", this.thumbnailHTML(asset))
  }

  // --- Selection ---

  pickAsset(event) {
    const button = event.currentTarget
    const url = button.dataset.variantUrl

    // Clear URL input if user was using that
    if (this.hasUrlInputTarget) {
      this.urlInputTarget.value = ""
    }

    // Update hidden field
    this.hiddenFieldTarget.value = url
    this.currentValue = url

    // Update ring styling
    this.gridTarget.querySelectorAll("button[data-asset-id]").forEach(btn => {
      btn.classList.remove("ring-2", "ring-[#ff584d]", "ring-offset-1")
    })
    button.classList.add("ring-2", "ring-[#ff584d]", "ring-offset-1")

    // Dispatch event for preview controllers to pick up
    this.dispatch("select", { detail: { url } })

    // Trigger native input event on hidden field so save controllers detect changes
    this.hiddenFieldTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }

  // --- URL fallback ---

  toggleUrl() {
    this.urlSectionTarget.classList.toggle("hidden")
  }

  urlChanged() {
    const url = this.urlInputTarget.value.trim()
    if (url) {
      this.hiddenFieldTarget.value = url
      this.currentValue = ""

      // Deselect thumbnails
      this.gridTarget.querySelectorAll("button[data-asset-id]").forEach(btn => {
        btn.classList.remove("ring-2", "ring-[#ff584d]", "ring-offset-1")
      })

      this.dispatch("select", { detail: { url } })
      this.hiddenFieldTarget.dispatchEvent(new Event("input", { bubbles: true }))
    }
  }

  // --- Helpers ---

  surfaceForContext() {
    switch (this.contextValue) {
      case "referral": return "referral_banner"
      case "extension": return "extension_card"
      default: return null
    }
  }

  variantUrlFor(asset) {
    if (this.contextValue === "extension") {
      return asset.extension_banner_url
    }
    return asset.referral_banner_url
  }

  showProgress() {
    this.progressTarget.classList.remove("hidden")
    this.progressBarTarget.style.width = "30%"
    this._timer = setInterval(() => {
      const w = parseFloat(this.progressBarTarget.style.width)
      if (w < 90) this.progressBarTarget.style.width = `${w + 10}%`
    }, 300)
  }

  hideProgress() {
    clearInterval(this._timer)
    this.progressBarTarget.style.width = "100%"
    setTimeout(() => {
      this.progressTarget.classList.add("hidden")
      this.progressBarTarget.style.width = "0%"
    }, 300)
  }

  showError(msg) {
    this.errorTarget.textContent = msg
    this.errorTarget.classList.remove("hidden")
  }

  hideError() {
    this.errorTarget.classList.add("hidden")
  }

  escapeAttr(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}
