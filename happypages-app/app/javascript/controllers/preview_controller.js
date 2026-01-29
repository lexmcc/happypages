import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "bannerImage",
    "heading",
    "subtitle",
    "buttonText",
    "previewImage",
    "previewHeading",
    "previewSubtitle",
    "previewButton",
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
    // Store original values for undo functionality
    this.originalValues = {
      bannerImage: this.bannerImageTarget.value,
      heading: this.headingTarget.value,
      subtitle: this.subtitleTarget.value,
      buttonText: this.buttonTextTarget.value
    }
    this.updatePreview()

    // Auto-resize textareas on load
    this.autoResizeAll()

    // Setup scroll listener for floating buttons
    this.handleScroll = this.handleScroll.bind(this)
    window.addEventListener('scroll', this.handleScroll)
    this.handleScroll() // Check initial state

    // Check if we have a success notice (page loaded after save)
    if (this.hasNoticeDataTarget) {
      this.showSuccessTooltip()
    }
  }

  disconnect() {
    window.removeEventListener('scroll', this.handleScroll)
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

  autoResize(event) {
    const textarea = event.target
    textarea.style.height = 'auto'
    textarea.style.height = textarea.scrollHeight + 'px'
  }

  autoResizeAll() {
    ;[this.headingTarget, this.subtitleTarget, this.buttonTextTarget].forEach(textarea => {
      textarea.style.height = 'auto'
      textarea.style.height = textarea.scrollHeight + 'px'
    })
  }

  updatePreview() {
    // Update preview image with fallback for empty/invalid URLs
    const imageUrl = this.bannerImageTarget.value
    if (imageUrl) {
      this.previewImageTarget.src = imageUrl
    } else {
      this.previewImageTarget.src = "https://via.placeholder.com/400x267/e5e7eb/9ca3af?text=Banner+Image"
    }

    // Helper to replace all variables with actual config values
    const replaceVariables = (text) => {
      // Get discount values from data attributes (set by ERB from active group)
      const discount = this.element.dataset.previewDiscountValue || '50%'
      const reward = this.element.dataset.previewRewardValue || '50%'

      return text
        .replaceAll("{firstName}", "Friend")
        .replaceAll("{discount}", discount)
        .replaceAll("{reward}", reward)
    }

    // Update heading with variable replacement
    const heading = this.headingTarget.value || "{firstName}, Refer A Friend"
    this.previewHeadingTarget.textContent = replaceVariables(heading)

    // Update subtitle with variable replacement
    const subtitle = this.subtitleTarget.value || "Give 50% And Get 50% Off"
    this.previewSubtitleTarget.textContent = replaceVariables(subtitle)

    // Update button text with variable replacement
    const buttonText = this.buttonTextTarget.value || "Share Now"
    this.previewButtonTarget.textContent = replaceVariables(buttonText)

    this.checkForChanges()
  }

  handleImageError() {
    this.previewImageTarget.src = "https://via.placeholder.com/400x267/fecaca/dc2626?text=Invalid+Image"
  }

  checkForChanges() {
    const hasChanges =
      this.bannerImageTarget.value !== this.originalValues.bannerImage ||
      this.headingTarget.value !== this.originalValues.heading ||
      this.subtitleTarget.value !== this.originalValues.subtitle ||
      this.buttonTextTarget.value !== this.originalValues.buttonText
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

    this.bannerImageTarget.value = this.originalValues.bannerImage
    this.headingTarget.value = this.originalValues.heading
    this.subtitleTarget.value = this.originalValues.subtitle
    this.buttonTextTarget.value = this.originalValues.buttonText

    this.autoResizeAll()
    this.updatePreview()
  }

  handleSave(event) {
    // Show spinner immediately, let native form submission happen
    this.saveSpinnerTarget.classList.remove("hidden")
    this.saveButtonTarget.classList.add("opacity-75")

    // Delay disabling button so form submission isn't cancelled
    // (disabled buttons can't submit forms, so we wait until after submission starts)
    setTimeout(() => {
      this.saveButtonTarget.disabled = true
    }, 0)
  }

  showSuccessTooltip() {
    // Show the tooltip
    this.successTooltipTarget.classList.remove("opacity-0")
    this.successTooltipTarget.classList.add("opacity-100")

    // Fade out after 2.5 seconds
    setTimeout(() => {
      this.successTooltipTarget.classList.remove("opacity-100")
      this.successTooltipTarget.classList.add("opacity-0")
    }, 2500)
  }

  insertVariable(event) {
    const variable = event.currentTarget.dataset.variable
    const targetField = event.currentTarget.dataset.targetField
    const textarea = this[`${targetField}Target`]

    // Insert at cursor position
    const start = textarea.selectionStart
    const end = textarea.selectionEnd
    const value = textarea.value
    textarea.value = value.slice(0, start) + variable + value.slice(end)

    // Move cursor after inserted variable
    textarea.selectionStart = textarea.selectionEnd = start + variable.length
    textarea.focus()

    // Auto-resize after inserting
    textarea.style.height = 'auto'
    textarea.style.height = textarea.scrollHeight + 'px'

    this.updatePreview()
  }
}
