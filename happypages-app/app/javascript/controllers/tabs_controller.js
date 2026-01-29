import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { active: { type: String, default: "classic" } }

  connect() {
    this.showTab(this.activeValue)
  }

  switch(event) {
    event.preventDefault()
    this.showTab(event.currentTarget.dataset.tab)
  }

  showTab(tabName) {
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tab === tabName
      tab.classList.toggle("border-[#ff584d]", isActive)
      tab.classList.toggle("text-[#ff584d]", isActive)
      tab.classList.toggle("border-transparent", !isActive)
      tab.classList.toggle("text-gray-500", !isActive)
    })

    this.panelTargets.forEach(panel => {
      panel.classList.toggle("hidden", panel.dataset.tab !== tabName)
    })

    this.activeValue = tabName
  }
}
