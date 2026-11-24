import { Controller } from "@hotwired/stimulus"

// As staff type in Find People, lists people in the directory who match and
// aren't in Programs yet under the table, each linked to their page
export default class extends Controller {
  static targets = ["input", "more", "list"]
  static values = { url: String, people: String }

  connect() {
    if (this.inputTarget.value.trim()) this.suggest()
  }

  async suggest() {
    const q = this.inputTarget.value.trim()
    if (q.length < 2) return this.show([])
    const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(q)}`, {
      headers: { Accept: "application/json" },
    })
    if (!response.ok || this.inputTarget.value.trim() !== q) return
    this.show(await response.json())
  }

  show(people) {
    this.listTarget.replaceChildren(
      ...people.map((person) => {
        const li = document.createElement("li")
        const link = document.createElement("a")
        link.href = `${this.peopleValue}/${encodeURIComponent(person.andrewid)}`
        link.textContent = `${person.name} (${person.andrewid})`
        li.append(link)
        return li
      }),
    )
    this.moreTarget.hidden = people.length === 0
  }
}
