import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    selectUrl: String,
    csrf: String
  }

  static targets = ["select"]

  connect() {
    this.fetchTeams()
  }

  async fetchTeams() {
    const response = await fetch(this.urlValue)
    if (!response.ok) return

    const teams = await response.json()
    const select = this.selectTarget
    select.innerHTML = ""

    teams.forEach(team => {
      const option = document.createElement("option")
      option.value = team.id
      option.textContent = `${team.name} (${team.key})`
      select.appendChild(option)
    })
  }

  async submit() {
    const teamId = this.selectTarget.value
    if (!teamId) return

    const form = document.createElement("form")
    form.method = "POST"
    form.action = this.selectUrlValue

    const methodInput = document.createElement("input")
    methodInput.type = "hidden"
    methodInput.name = "_method"
    methodInput.value = "PATCH"
    form.appendChild(methodInput)

    const csrfInput = document.createElement("input")
    csrfInput.type = "hidden"
    csrfInput.name = "authenticity_token"
    csrfInput.value = this.csrfValue
    form.appendChild(csrfInput)

    const teamInput = document.createElement("input")
    teamInput.type = "hidden"
    teamInput.name = "team_id"
    teamInput.value = teamId
    form.appendChild(teamInput)

    document.body.appendChild(form)
    form.submit()
  }
}
