import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitButton", "valueInput", "typeSelect"]

  connect() {
    this.validate()
  }

  validate() {
    let isValid = true

    this.valueInputTargets.forEach((input, index) => {
      const value = input.value.trim()
      const typeSelect = this.typeSelectTargets[index]
      const type = typeSelect?.value

      // Check blank
      if (!value) {
        isValid = false
        input.classList.add("border-red-300")
      } else {
        input.classList.remove("border-red-300")
      }

      // Check percentage max
      if (type === "percentage" && parseFloat(value) > 100) {
        isValid = false
        input.classList.add("border-red-300")
      }
    })

    // Disable/enable submit button
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = !isValid
      this.submitButtonTarget.classList.toggle("opacity-50", !isValid)
      this.submitButtonTarget.classList.toggle("cursor-not-allowed", !isValid)
    }
  }
}
