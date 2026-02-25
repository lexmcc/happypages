import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static values = {
    url: String,
    updateUrl: String,
    createUrl: String,
    readonly: { type: Boolean, default: false },
    csrf: String
  }

  static targets = ["column", "cardCount"]

  connect() {
    this.fetchCards()
  }

  async fetchCards() {
    const response = await fetch(this.urlValue)
    if (!response.ok) return

    const grouped = await response.json()
    const statuses = ["backlog", "in_progress", "review", "done"]

    statuses.forEach((status, i) => {
      const column = this.columnTargets[i]
      if (!column) return

      column.innerHTML = ""
      const cards = grouped[status] || []

      cards.forEach(card => {
        column.appendChild(this.buildCardElement(card))
      })

      this.updateCount(i, cards.length)
    })

    if (!this.readonlyValue) {
      this.initSortable()
    }
  }

  initSortable() {
    this.sortables = this.columnTargets.map(column => {
      return new Sortable(column, {
        group: "board",
        animation: 150,
        ghostClass: "opacity-30",
        dragClass: "shadow-lg",
        onEnd: (evt) => this.handleDrop(evt)
      })
    })
  }

  async handleDrop(evt) {
    const cardId = evt.item.dataset.cardId
    const statuses = ["backlog", "in_progress", "review", "done"]
    const newStatus = statuses[this.columnTargets.indexOf(evt.to)]
    const newPosition = evt.newIndex

    // Update counts
    this.columnTargets.forEach((col, i) => {
      this.updateCount(i, col.children.length)
    })

    await fetch(this.updateUrlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfValue
      },
      body: JSON.stringify({ card_id: cardId, status: newStatus, position: newPosition })
    })
  }

  addCard() {
    const form = this.element.querySelector("[data-kanban-form]")
    if (form) {
      form.classList.toggle("hidden")
      if (!form.classList.contains("hidden")) {
        form.querySelector("input")?.focus()
      }
      return
    }
  }

  async submitCard(event) {
    event.preventDefault()
    const form = this.element.querySelector("[data-kanban-form]")
    const titleInput = form.querySelector("[data-kanban-title]")
    const descInput = form.querySelector("[data-kanban-desc]")

    const title = titleInput.value.trim()
    if (!title) return

    const response = await fetch(this.createUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfValue
      },
      body: JSON.stringify({ title: title, description: descInput.value.trim() })
    })

    if (!response.ok) return

    const card = await response.json()
    const backlogColumn = this.columnTargets[0]
    backlogColumn.prepend(this.buildCardElement(card))
    this.updateCount(0, backlogColumn.children.length)

    titleInput.value = ""
    descInput.value = ""
    form.classList.add("hidden")
  }

  cancelCard() {
    const form = this.element.querySelector("[data-kanban-form]")
    if (form) form.classList.add("hidden")
  }

  buildCardElement(card) {
    const el = document.createElement("div")
    el.dataset.cardId = card.id
    el.className = `p-3 bg-white border border-gray-200 rounded-lg shadow-sm ${this.readonlyValue ? "cursor-default" : "cursor-grab active:cursor-grabbing"}`

    const badges = []
    if (card.has_ui) {
      badges.push('<span class="px-1.5 py-0.5 rounded text-[10px] font-medium bg-blue-50 text-blue-700">UI</span>')
    }
    if (card.chunk_index !== null && card.chunk_index !== undefined) {
      badges.push(`<span class="inline-flex items-center justify-center size-4 rounded-full bg-gray-100 text-[9px] font-bold text-gray-500">${card.chunk_index + 1}</span>`)
    }

    const criteriaCount = (card.acceptance_criteria || []).length
    const deps = (card.dependencies || []).filter(d => d)

    el.innerHTML = `
      <div class="flex items-start justify-between gap-2 mb-1">
        <h4 class="text-xs font-semibold text-gray-900 leading-tight">${this.escapeHtml(card.title)}</h4>
        <div class="flex items-center gap-1 flex-shrink-0">${badges.join("")}</div>
      </div>
      ${card.description ? `<p class="text-[11px] text-gray-500 leading-snug line-clamp-2 mb-2">${this.escapeHtml(card.description)}</p>` : ""}
      <div class="flex items-center gap-2 flex-wrap">
        ${criteriaCount > 0 ? `<span class="text-[10px] text-gray-400">${criteriaCount} criteria</span>` : ""}
        ${deps.map(d => `<span class="px-1 py-0.5 rounded text-[9px] bg-gray-100 text-gray-500">${this.escapeHtml(d)}</span>`).join("")}
      </div>
    `

    return el
  }

  updateCount(index, count) {
    const badge = this.cardCountTargets[index]
    if (badge) badge.textContent = count
  }

  escapeHtml(str) {
    if (!str) return ""
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
