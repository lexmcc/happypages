import SidebarController from "./sidebar_controller"

export default class extends SidebarController {
  connect() {
    super.connect()
    try {
      if (localStorage.getItem('sidebarCollapsed') === 'true') {
        this.sidebarTarget.classList.add('sidebar-collapsed')
      }
    } catch(e) {}
    this._keyHandler = this._onKeydown.bind(this)
    document.addEventListener('keydown', this._keyHandler)
  }

  disconnect() {
    super.disconnect()
    document.removeEventListener('keydown', this._keyHandler)
  }

  collapse() {
    this.sidebarTarget.classList.toggle('sidebar-collapsed')
    try {
      localStorage.setItem('sidebarCollapsed',
        this.sidebarTarget.classList.contains('sidebar-collapsed'))
    } catch(e) {}
  }

  _onKeydown(e) {
    var tag = e.target.tagName
    if (tag === 'INPUT' || tag === 'TEXTAREA' || e.target.isContentEditable) return
    if (e.key === '[') { e.preventDefault(); this.collapse() }
  }
}
