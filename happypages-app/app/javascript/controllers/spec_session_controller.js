import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    turnsUsed: Number,
    turnBudget: Number,
    status: String,
    csrf: String
  }

  static targets = [
    "thread", "input", "sendButton", "loading", "options",
    "turnCounter", "phaseLabel", "fileInput", "imagePreview"
  ]

  connect() {
    this.pendingFile = null
    this.autoResize()
  }

  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.sendMessage()
    }
  }

  async sendMessage() {
    const text = this.inputTarget.value.trim()
    if (!text && !this.pendingFile) return
    if (this.sendButtonTarget.disabled) return

    // Disable send immediately to prevent double-send
    this.sendButtonTarget.disabled = true
    this.hideOptions()
    this.showLoading()

    // Show user message immediately
    if (text) {
      this.appendMessage("user", text)
      this.inputTarget.value = ""
      this.autoResize()
    }

    const formData = new FormData()
    if (text) formData.append("message", text)
    if (this.pendingFile) {
      formData.append("image", this.pendingFile)
      this.clearImagePreview()
    }

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: { "X-CSRF-Token": this.csrfValue },
        body: formData
      })

      const data = await response.json()

      if (!response.ok) {
        this.appendError(data.error || "Something went wrong.")
        return
      }

      this.renderAssistantResponse(data)
      this.updateSessionState(data)
    } catch (err) {
      this.appendError("Network error. Please try again.")
    } finally {
      this.hideLoading()
      if (this.statusValue === "active") {
        this.sendButtonTarget.disabled = false
      }
    }
  }

  renderAssistantResponse(data) {
    if (data.tool_name === "ask_question") {
      this.renderQuestion(data.tool_input, data.content)
    } else if (data.tool_name === "ask_freeform") {
      this.renderFreeform(data.tool_input, data.content)
    } else if (data.tool_name === "analyze_image") {
      this.renderImageAnalysis(data.tool_input, data.content)
    } else if (data.tool_name === "generate_client_brief" || data.tool_name === "generate_team_spec") {
      this.renderGenerated(data.tool_name, data.content)
    } else if (data.tool_name === "request_handoff") {
      this.renderHandoffRequest(data.tool_input, data.content)
    } else {
      this.renderPlainText(data.content)
    }
  }

  renderQuestion(input, text) {
    if (text) this.appendAssistantBubble(text)

    const el = document.createElement("div")
    el.className = "max-w-3xl mx-auto px-4 sm:px-6"

    let html = '<div class="max-w-[80%]">'
    html += '<div class="bg-[#f4f4f0] border border-black/5 shadow-[inset_1px_1px_0_rgba(255,255,255,1),inset_-1px_-1px_0_rgba(0,0,0,0.05),0_2px_4px_rgba(0,0,0,0.05)] rounded-2xl rounded-bl-md px-4 py-2.5">'

    if (input.context) {
      html += `<p class="text-xs text-gray-500 mb-2">${this.escapeHtml(input.context)}</p>`
    }
    html += `<p class="text-sm font-medium text-gray-900 mb-2">${this.escapeHtml(input.question)}</p>`

    html += '</div></div>'
    el.innerHTML = html
    this.threadTarget.querySelector(".space-y-4").appendChild(el)

    // Render option buttons
    this.showOptions()
    let optionsHtml = '<div class="flex flex-wrap gap-2 py-2">'
    for (const option of input.options) {
      optionsHtml += `<button type="button"
        data-action="click->spec-session#selectOption"
        data-option-label="${this.escapeAttr(option.label)}"
        class="px-3 py-1.5 bg-white border border-gray-200 rounded-lg text-sm text-gray-700 hover:border-[#ff584d] hover:text-[#ff584d] transition-colors">
        ${this.escapeHtml(option.label)}
      </button>`
    }
    optionsHtml += '</div>'
    this.optionsTarget.innerHTML = optionsHtml

    this.scrollToBottom()
  }

  renderFreeform(input, text) {
    if (text) this.appendAssistantBubble(text)

    const el = document.createElement("div")
    el.className = "max-w-3xl mx-auto px-4 sm:px-6"

    let html = '<div class="max-w-[80%]">'
    html += '<div class="bg-[#f4f4f0] border border-black/5 shadow-[inset_1px_1px_0_rgba(255,255,255,1),inset_-1px_-1px_0_rgba(0,0,0,0.05),0_2px_4px_rgba(0,0,0,0.05)] rounded-2xl rounded-bl-md px-4 py-2.5">'

    if (input.context) {
      html += `<p class="text-xs text-gray-500 mb-2">${this.escapeHtml(input.context)}</p>`
    }
    html += `<p class="text-sm font-medium text-gray-900">${this.escapeHtml(input.question)}</p>`

    html += '</div></div>'
    el.innerHTML = html
    this.threadTarget.querySelector(".space-y-4").appendChild(el)

    if (input.hint) {
      this.inputTarget.placeholder = input.hint
    }

    this.scrollToBottom()
  }

  renderGenerated(toolName, text) {
    const label = toolName === "generate_client_brief" ? "Client brief" : "Team spec"

    const el = document.createElement("div")
    el.className = "flex justify-start"

    let html = '<div class="max-w-[80%]">'
    html += '<div class="bg-emerald-50 border border-emerald-200 rounded-2xl rounded-bl-md px-4 py-2.5">'
    html += `<div class="flex items-center gap-2 text-emerald-700">`
    html += `<svg class="size-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>`
    html += `<span class="text-sm font-medium">${this.escapeHtml(label)} generated</span>`
    html += '</div>'
    if (text) {
      html += `<p class="text-xs text-emerald-600 mt-1">${this.escapeHtml(text)}</p>`
    }
    html += '</div></div>'

    el.innerHTML = html
    this.threadTarget.querySelector(".space-y-4").appendChild(el)
    this.scrollToBottom()
  }

  renderImageAnalysis(input, text) {
    if (text) this.appendAssistantBubble(text)

    const el = document.createElement("div")
    el.className = "flex justify-start"

    let html = '<div class="max-w-[80%]">'
    html += '<div class="bg-blue-50 border border-blue-200 rounded-2xl rounded-bl-md px-4 py-2.5">'
    html += '<div class="flex items-center gap-2 text-blue-700 mb-1">'
    html += '<svg class="size-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909M3.75 21h16.5a2.25 2.25 0 002.25-2.25V5.25a2.25 2.25 0 00-2.25-2.25H3.75A2.25 2.25 0 001.5 5.25v13.5A2.25 2.25 0 003.75 21z"/></svg>'
    html += '<span class="text-sm font-medium">image analysed</span>'
    html += '</div>'

    if (input && input.summary) {
      html += `<p class="text-xs text-blue-600">${this.escapeHtml(input.summary)}</p>`
    }

    // Color swatches
    if (input && input.analysis && input.analysis.colors && input.analysis.colors.length > 0) {
      html += '<div class="flex flex-wrap gap-1.5 mt-2">'
      const colors = input.analysis.colors.slice(0, 8)
      for (const color of colors) {
        const hex = this.escapeAttr(color.hex || "")
        html += `<span class="inline-flex items-center gap-1"><span class="size-3.5 rounded-full border border-blue-200" style="background-color: ${hex}"></span><span class="text-[10px] text-blue-500">${this.escapeHtml(hex)}</span></span>`
      }
      html += '</div>'
    }

    html += '</div></div>'
    el.innerHTML = html
    this.threadTarget.querySelector(".space-y-4").appendChild(el)
    this.scrollToBottom()
  }

  renderHandoffRequest(input, text) {
    if (text) this.appendAssistantBubble(text)

    const el = document.createElement("div")
    el.className = "flex justify-start"

    let html = '<div class="max-w-[80%]">'
    html += '<div class="bg-amber-50 border border-amber-200 rounded-2xl rounded-bl-md px-4 py-3">'
    html += '<div class="flex items-center gap-2 text-amber-700 mb-2">'
    html += '<svg class="size-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3"/></svg>'
    html += '<span class="text-sm font-medium">handoff requested</span>'
    html += '</div>'

    if (input && input.reason) {
      html += `<p class="text-sm text-amber-800 mb-2">${this.escapeHtml(input.reason)}</p>`
    }

    if (input && input.suggested_questions && input.suggested_questions.length > 0) {
      html += '<p class="text-xs font-medium text-amber-600 mb-1">suggested questions:</p><ul class="space-y-0.5">'
      for (const q of input.suggested_questions) {
        html += `<li class="text-xs text-amber-700">&bull; ${this.escapeHtml(q)}</li>`
      }
      html += '</ul>'
    }

    html += '<p class="text-xs text-amber-500 mt-2">reload the page to create an invite or assign to a team member.</p>'
    html += '</div></div>'

    el.innerHTML = html
    this.threadTarget.querySelector(".space-y-4").appendChild(el)
    this.scrollToBottom()
  }

  renderPlainText(text) {
    if (text) this.appendAssistantBubble(text)
    this.scrollToBottom()
  }

  selectOption(event) {
    const label = event.currentTarget.dataset.optionLabel
    this.inputTarget.value = label
    this.sendMessage()
  }

  clickFileInput() {
    this.fileInputTarget.click()
  }

  attachImage() {
    const file = this.fileInputTarget.files[0]
    if (!file) return

    if (file.size > 5 * 1024 * 1024) {
      this.appendError("Image must be less than 5MB.")
      this.fileInputTarget.value = ""
      return
    }

    this.pendingFile = file

    // Show preview
    const reader = new FileReader()
    reader.onload = (e) => {
      this.imagePreviewTarget.classList.remove("hidden")
      this.imagePreviewTarget.innerHTML = `
        <div class="flex items-center gap-2 p-2 bg-gray-50 rounded-lg">
          <img src="${e.target.result}" class="size-10 object-cover rounded" />
          <span class="text-xs text-gray-500 flex-1 truncate">${this.escapeHtml(file.name)}</span>
          <button type="button" data-action="click->spec-session#removeImage" class="text-gray-400 hover:text-gray-600">
            <svg class="size-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
          </button>
        </div>`
    }
    reader.readAsDataURL(file)
  }

  removeImage() {
    this.clearImagePreview()
  }

  // Private helpers

  appendMessage(role, content) {
    const el = document.createElement("div")
    el.className = role === "user" ? "flex justify-end" : "flex justify-start"

    if (role === "user") {
      el.innerHTML = `<div class="max-w-[80%]"><div class="bg-[#ff584d] text-white rounded-2xl rounded-br-md px-4 py-2.5"><p class="text-sm">${this.escapeHtml(content)}</p></div></div>`
    }

    this.threadTarget.querySelector(".space-y-4").appendChild(el)
    this.scrollToBottom()
  }

  appendAssistantBubble(text) {
    const el = document.createElement("div")
    el.className = "flex justify-start"
    el.innerHTML = `<div class="max-w-[80%]"><div class="bg-[#f4f4f0] border border-black/5 shadow-[inset_1px_1px_0_rgba(255,255,255,1),inset_-1px_-1px_0_rgba(0,0,0,0.05),0_2px_4px_rgba(0,0,0,0.05)] rounded-2xl rounded-bl-md px-4 py-2.5"><p class="text-sm text-gray-800">${this.escapeHtml(text)}</p></div></div>`
    this.threadTarget.querySelector(".space-y-4").appendChild(el)
  }

  appendError(message) {
    const el = document.createElement("div")
    el.className = "flex justify-start"
    el.innerHTML = `<div class="max-w-[80%]"><div class="bg-red-50 border border-red-200 rounded-2xl rounded-bl-md px-4 py-2.5"><p class="text-sm text-red-700">${this.escapeHtml(message)}</p></div></div>`
    this.threadTarget.querySelector(".space-y-4").appendChild(el)
    this.scrollToBottom()
  }

  updateSessionState(data) {
    if (data.turns_used != null) {
      this.turnsUsedValue = data.turns_used
      this.turnCounterTarget.textContent = `${data.turns_used}/${data.turn_budget}`
    }
    if (data.phase) {
      this.phaseLabelTarget.textContent = data.phase
    }
    if (data.status === "completed") {
      this.statusValue = "completed"
      this.renderCompletedState()
    }
  }

  renderCompletedState() {
    // Reload to show completed view
    window.location.reload()
  }

  showLoading() {
    this.loadingTarget.classList.remove("hidden")
    this.scrollToBottom()
  }

  hideLoading() {
    this.loadingTarget.classList.add("hidden")
  }

  showOptions() {
    this.optionsTarget.classList.remove("hidden")
  }

  hideOptions() {
    this.optionsTarget.classList.add("hidden")
    this.optionsTarget.innerHTML = ""
  }

  clearImagePreview() {
    this.pendingFile = null
    this.fileInputTarget.value = ""
    if (this.hasImagePreviewTarget) {
      this.imagePreviewTarget.classList.add("hidden")
      this.imagePreviewTarget.innerHTML = ""
    }
  }

  scrollToBottom() {
    requestAnimationFrame(() => {
      this.threadTarget.scrollTop = this.threadTarget.scrollHeight
    })
  }

  autoResize() {
    if (!this.hasInputTarget) return
    const el = this.inputTarget
    el.style.height = "auto"
    el.style.height = Math.min(el.scrollHeight, 120) + "px"
  }

  escapeHtml(str) {
    if (!str) return ""
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }

  escapeAttr(str) {
    if (!str) return ""
    return str.replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/'/g, "&#39;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }
}
