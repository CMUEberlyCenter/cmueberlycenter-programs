import { Controller } from "@hotwired/stimulus"

// Suggests people from the directory as an administrator types an Andrew ID
// or name (the kit's Search Suggestions); picking one opens their page
export default class extends Controller {
  static targets = ["input", "list"]
  static values = { url: String }

  async suggest() {
    const q = this.inputTarget.value.trim()
    if (q.length < 2) {
      this.listTarget.replaceChildren()
      return
    }
    const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(q)}`, {
      headers: { Accept: "application/json" },
    })
    if (!response.ok || this.inputTarget.value.trim() !== q) return
    const people = await response.json()
    this.listTarget.replaceChildren(
      ...people.map((person) => {
        const li = document.createElement("li")
        li.dataset.value = person.andrewid
        li.textContent = `${person.name} (${person.andrewid})`
        return li
      }),
    )
  }

  open(event) {
    window.Turbo.visit(`${this.inputTarget.form.action}/${encodeURIComponent(event.detail.dataset.value)}`)
  }
}
