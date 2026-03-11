import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "backdrop"]

  connect() {
    try {
      if (localStorage.getItem('sidebarCollapsed') === 'true') {
        this.sidebarTarget.classList.add('sidebar-collapsed');
      }
    } catch(e) {}

    this._keyHandler = this._onKeydown.bind(this);
    document.addEventListener('keydown', this._keyHandler);
  }

  disconnect() {
    document.removeEventListener('keydown', this._keyHandler);
  }

  toggle() {
    this.sidebarTarget.classList.toggle("-translate-x-full")
    this.backdropTarget.classList.toggle("hidden")
  }

  close() {
    this.sidebarTarget.classList.add("-translate-x-full")
    this.backdropTarget.classList.add("hidden")
  }

  collapse() {
    this.sidebarTarget.classList.toggle('sidebar-collapsed');
    try {
      localStorage.setItem('sidebarCollapsed',
        this.sidebarTarget.classList.contains('sidebar-collapsed'));
    } catch(e) {}
  }

  _onKeydown(e) {
    var tag = e.target.tagName;
    if (tag === 'INPUT' || tag === 'TEXTAREA' || e.target.isContentEditable) return;
    if (e.key === '[') { e.preventDefault(); this.collapse(); }
  }
}
