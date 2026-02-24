import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["group", "content", "chevron"]

  connect() {
    this.restoreState()
  }

  toggle(event) {
    const group = event.currentTarget.closest("[data-sidebar-collapse-target='group']")
    if (!group) return

    const content = group.querySelector("[data-sidebar-collapse-target='content']")
    const chevron = group.querySelector("[data-sidebar-collapse-target='chevron']")
    if (!content) return

    const isCollapsed = content.classList.contains("hidden")

    if (isCollapsed) {
      content.classList.remove("hidden")
      chevron?.classList.remove("-rotate-90")
    } else {
      content.classList.add("hidden")
      chevron?.classList.add("-rotate-90")
    }

    this.saveState()
  }

  restoreState() {
    const saved = localStorage.getItem("sidebar-collapse-state")
    if (!saved) return

    try {
      const state = JSON.parse(saved)
      this.groupTargets.forEach(group => {
        const feature = group.dataset.feature
        if (state[feature] === "collapsed") {
          const content = group.querySelector("[data-sidebar-collapse-target='content']")
          const chevron = group.querySelector("[data-sidebar-collapse-target='chevron']")
          content?.classList.add("hidden")
          chevron?.classList.add("-rotate-90")
        }
      })
    } catch {
      // Ignore corrupt localStorage
    }
  }

  saveState() {
    const state = {}
    this.groupTargets.forEach(group => {
      const feature = group.dataset.feature
      const content = group.querySelector("[data-sidebar-collapse-target='content']")
      state[feature] = content?.classList.contains("hidden") ? "collapsed" : "expanded"
    })
    localStorage.setItem("sidebar-collapse-state", JSON.stringify(state))
  }
}
