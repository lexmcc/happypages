import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tooltip"]
  static values = { text: String, email: String, referralCode: String }

  copy(event) {
    const text = event.currentTarget.dataset.clipboardTextValue
    navigator.clipboard.writeText(text).then(() => {
      this.showTooltip()
      this.trackCopyEvent()
    })
  }

  trackCopyEvent() {
    const email = this.emailValue
    const referralCode = this.referralCodeValue

    fetch('/api/analytics', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        event_type: 'copy_click',
        source: 'referral_page',
        email: email,
        referral_code: referralCode
      })
    }).catch(() => {}) // Silent fail
  }

  showTooltip() {
    if (this.hasTooltipTarget) {
      this.tooltipTarget.classList.remove("opacity-0")
      this.tooltipTarget.classList.add("opacity-100")
      setTimeout(() => {
        this.tooltipTarget.classList.remove("opacity-100")
        this.tooltipTarget.classList.add("opacity-0")
      }, 1500)
    }
  }
}
