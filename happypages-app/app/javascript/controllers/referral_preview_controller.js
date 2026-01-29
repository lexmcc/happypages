import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "primaryColor",
    "secondaryColor",
    "backgroundColor",
    "bannerImage",
    "heading",
    "subtitle",
    "step1",
    "step2",
    "step3",
    "copyButtonText",
    "backButtonText",
    "previewContainer",
    "previewImage",
    "previewHeading",
    "previewSubtitle",
    "previewCopyButton",
    "previewStep1",
    "previewStep2",
    "previewStep3",
    "previewStep1Badge",
    "previewStep2Badge",
    "previewStep3Badge",
    "previewBackButton"
  ]

  connect() {
    this.updatePreview()
    this.autoResizeAll()
  }

  autoResize(event) {
    const textarea = event.target
    textarea.style.height = 'auto'
    textarea.style.height = textarea.scrollHeight + 'px'
  }

  autoResizeAll() {
    const textareas = [
      this.headingTarget,
      this.subtitleTarget,
      this.step1Target,
      this.step2Target,
      this.step3Target
    ].filter(t => t)

    textareas.forEach(textarea => {
      textarea.style.height = 'auto'
      textarea.style.height = textarea.scrollHeight + 'px'
    })
  }

  updatePreview() {
    // Get discount values from data attributes
    const discount = this.element.dataset.referralPreviewDiscountValue || '50%'
    const reward = this.element.dataset.referralPreviewRewardValue || '50%'

    // Helper to replace variables
    const replaceVariables = (text) => {
      return text
        .replaceAll("{firstName}", "Friend")
        .replaceAll("{discount}", discount)
        .replaceAll("{reward}", reward)
    }

    // Update colors
    if (this.hasPrimaryColorTarget && this.hasPreviewCopyButtonTarget) {
      this.previewCopyButtonTarget.style.backgroundColor = this.primaryColorTarget.value
    }
    if (this.hasPrimaryColorTarget && this.hasPreviewBackButtonTarget) {
      this.previewBackButtonTarget.style.color = this.primaryColorTarget.value
    }
    if (this.hasBackgroundColorTarget && this.hasPreviewContainerTarget) {
      this.previewContainerTarget.style.backgroundColor = this.backgroundColorTarget.value
    }

    // Update step badges with colors
    const badges = [
      this.hasPreviewStep1BadgeTarget ? this.previewStep1BadgeTarget : null,
      this.hasPreviewStep2BadgeTarget ? this.previewStep2BadgeTarget : null,
      this.hasPreviewStep3BadgeTarget ? this.previewStep3BadgeTarget : null
    ].filter(b => b)

    badges.forEach(badge => {
      if (this.hasSecondaryColorTarget) {
        badge.style.backgroundColor = this.secondaryColorTarget.value
      }
      if (this.hasPrimaryColorTarget) {
        badge.style.color = this.primaryColorTarget.value
      }
    })

    // Update banner image
    if (this.hasBannerImageTarget && this.hasPreviewImageTarget) {
      const imageUrl = this.bannerImageTarget.value.trim()
      if (imageUrl) {
        this.previewImageTarget.src = imageUrl
        this.previewImageTarget.classList.remove('hidden')
      } else {
        this.previewImageTarget.classList.add('hidden')
      }
    }

    // Update heading
    if (this.hasHeadingTarget && this.hasPreviewHeadingTarget) {
      const heading = this.headingTarget.value || 'Thanks, {firstName}!'
      this.previewHeadingTarget.textContent = replaceVariables(heading)
    }

    // Update subtitle
    if (this.hasSubtitleTarget && this.hasPreviewSubtitleTarget) {
      const subtitle = this.subtitleTarget.value || 'Share your code and earn rewards'
      this.previewSubtitleTarget.textContent = replaceVariables(subtitle)
    }

    // Update steps
    if (this.hasStep1Target && this.hasPreviewStep1Target) {
      const step1 = this.step1Target.value || 'Share your unique code with friends'
      this.previewStep1Target.textContent = replaceVariables(step1)
    }
    if (this.hasStep2Target && this.hasPreviewStep2Target) {
      const step2 = this.step2Target.value || 'They get {discount} off their first order'
      this.previewStep2Target.textContent = replaceVariables(step2)
    }
    if (this.hasStep3Target && this.hasPreviewStep3Target) {
      const step3 = this.step3Target.value || 'You earn {reward} when they purchase!'
      this.previewStep3Target.textContent = replaceVariables(step3)
    }

    // Update copy button title
    if (this.hasCopyButtonTextTarget && this.hasPreviewCopyButtonTarget) {
      this.previewCopyButtonTarget.title = this.copyButtonTextTarget.value || 'Copy'
    }

    // Update back button text
    if (this.hasBackButtonTextTarget && this.hasPreviewBackButtonTarget) {
      const backText = this.backButtonTextTarget.value || 'Back to Store'
      this.previewBackButtonTarget.innerHTML = `&larr; ${backText}`
    }
  }

  handleImageError() {
    if (this.hasPreviewImageTarget) {
      this.previewImageTarget.classList.add('hidden')
    }
  }

  insertVariable(event) {
    const variable = event.currentTarget.dataset.variable
    const targetField = event.currentTarget.dataset.targetField
    const textarea = this[`${targetField}Target`]

    if (!textarea) return

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
