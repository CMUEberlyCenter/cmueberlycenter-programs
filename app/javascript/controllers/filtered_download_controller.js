import { Controller } from "@hotwired/stimulus"

// A table's spreadsheet link that downloads only the rows its search shows:
// the search text goes in the link as ?q=, and the link counts the rows
export default class extends Controller {
  static values = { input: String, table: String, noun: String }

  connect() {
    this.input = document.getElementById(this.inputValue)
    this.base = new URL(this.element.href)
    this.update = () => requestAnimationFrame(() => this.render())
    this.input?.addEventListener("input", this.update)
    this.update()
  }

  disconnect() {
    this.input?.removeEventListener("input", this.update)
  }

  render() {
    const url = new URL(this.base)
    const q = this.input?.value.trim()
    if (q) url.searchParams.set("q", q)
    this.element.href = url.pathname + url.search
    const rows = document.querySelectorAll(`#${this.tableValue} tbody tr:not([hidden])`).length
    const [one, many] = this.nounValue.split("|")
    this.element.textContent = `Spreadsheet of ${rows} ${rows === 1 ? one : many}`
  }
}
