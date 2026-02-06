import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "undoButton",
    "saveButton",
    "saveSpinner",
    "saveButtonText",
    "successTooltip",
    "noticeData",
    "form",
    "buttonContainer"
  ]

  connect() {
    // Store original form values for undo
    this.originalValues = this.captureFormValues()

    // Setup scroll listener for floating buttons
    this.handleScroll = this.handleScroll.bind(this)
    window.addEventListener('scroll', this.handleScroll)
    this.handleScroll()

    // Check if we have a success notice (page loaded after save)
    if (this.hasNoticeDataTarget) {
      this.showSuccessTooltip()
    }
  }

  disconnect() {
    window.removeEventListener('scroll', this.handleScroll)
  }

  captureFormValues() {
    if (!this.hasFormTarget) return {}
    const values = {}
    const inputs = this.formTarget.querySelectorAll('input, textarea, select')
    inputs.forEach(input => {
      if (input.name) values[input.name] = input.value
    })
    return values
  }

  handleScroll() {
    if (!this.hasButtonContainerTarget) return

    const scrolled = window.scrollY > 50

    if (scrolled) {
      this.buttonContainerTarget.classList.add(
        'bg-[#f4f4f0]',
        'border',
        'border-black/5',
        'shadow-[inset_1px_1px_0_rgba(255,255,255,1),inset_-1px_-1px_0_rgba(0,0,0,0.05),0_4px_8px_rgba(0,0,0,0.1)]',
        'px-4',
        'py-2'
      )
    } else {
      this.buttonContainerTarget.classList.remove(
        'bg-[#f4f4f0]',
        'border',
        'border-black/5',
        'shadow-[inset_1px_1px_0_rgba(255,255,255,1),inset_-1px_-1px_0_rgba(0,0,0,0.05),0_4px_8px_rgba(0,0,0,0.1)]',
        'px-4',
        'py-2'
      )
    }
  }

  checkForChanges() {
    if (!this.hasFormTarget || !this.hasUndoButtonTarget) return

    const currentValues = this.captureFormValues()
    const hasChanges = Object.keys(this.originalValues).some(
      key => currentValues[key] !== this.originalValues[key]
    )

    this.undoButtonTarget.disabled = !hasChanges

    if (hasChanges) {
      this.undoButtonTarget.classList.remove("opacity-50", "cursor-not-allowed")
      this.undoButtonTarget.classList.add("cursor-pointer")
    } else {
      this.undoButtonTarget.classList.add("opacity-50", "cursor-not-allowed")
      this.undoButtonTarget.classList.remove("cursor-pointer")
    }
  }

  undoAll(event) {
    event.preventDefault()
    if (!this.hasFormTarget) return

    const inputs = this.formTarget.querySelectorAll('input, textarea, select')
    inputs.forEach(input => {
      if (input.name && this.originalValues[input.name] !== undefined) {
        input.value = this.originalValues[input.name]
        // Trigger input event so referral-preview controller updates
        input.dispatchEvent(new Event('input', { bubbles: true }))
      }
    })

    this.checkForChanges()
  }

  handleSave() {
    if (!this.hasSaveSpinnerTarget || !this.hasSaveButtonTarget) return

    this.saveSpinnerTarget.classList.remove("hidden")
    this.saveButtonTarget.classList.add("opacity-75")

    setTimeout(() => {
      this.saveButtonTarget.disabled = true
    }, 0)
  }

  showSuccessTooltip() {
    if (!this.hasSuccessTooltipTarget) return

    this.successTooltipTarget.classList.remove("opacity-0")
    this.successTooltipTarget.classList.add("opacity-100")

    setTimeout(() => {
      this.successTooltipTarget.classList.remove("opacity-100")
      this.successTooltipTarget.classList.add("opacity-0")
    }, 2500)
  }
}
