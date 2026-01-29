import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu", "hidden", "selected"]
  static values = { open: Boolean }

  toggle() {
    this.openValue = !this.openValue
  }

  select(event) {
    const value = event.currentTarget.dataset.value
    const label = event.currentTarget.dataset.label
    this.hiddenTarget.value = value
    this.selectedTarget.textContent = label
    this.openValue = false

    // Dispatch change event for preview controller
    this.hiddenTarget.dispatchEvent(new Event('change', { bubbles: true }))
  }

  openValueChanged() {
    this.menuTarget.classList.toggle('hidden', !this.openValue)
    // Rotate chevron
    const chevron = this.buttonTarget.querySelector('svg')
    if (chevron) {
      chevron.classList.toggle('rotate-180', this.openValue)
    }
  }

  // Close on click outside
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.openValue = false
    }
  }

  connect() {
    this.clickOutsideHandler = this.clickOutside.bind(this)
    document.addEventListener('click', this.clickOutsideHandler)
  }

  disconnect() {
    document.removeEventListener('click', this.clickOutsideHandler)
  }
}
