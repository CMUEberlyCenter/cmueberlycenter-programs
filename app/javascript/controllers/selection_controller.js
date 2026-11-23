import { Controller } from "@hotwired/stimulus"

// The kit's Tables With Actions: a Select All checkbox, the selection
// count in the bulk bar and the bulk buttons, shown only with a selection
// and labeled with how many: "Confirm (2)"
export default class extends Controller {
  static targets = ["all", "row", "count", "action"]
  static values = { noun: { type: String, default: "person|people" } }

  connect() {
    this.update()
  }

  toggleAll() {
    this.rowTargets.forEach((box) => (box.checked = this.allTarget.checked))
    this.update()
  }

  update() {
    const selected = this.rowTargets.filter((box) => box.checked).length
    const [one, many] = this.nounValue.split("|")
    this.countTarget.textContent =
      selected === 0 ? `No ${many} selected` : `${selected} ${selected === 1 ? one : many} selected`
    this.countTarget.classList.toggle("cmu-has-selection", selected > 0)
    this.actionTargets.forEach((el) => {
      el.dataset.label ||= el.textContent.trim()
      el.textContent = `${el.dataset.label} (${selected})`
      el.hidden = selected === 0
    })
    if (this.hasAllTarget) {
      this.allTarget.checked = selected > 0 && selected === this.rowTargets.length
      this.allTarget.indeterminate = selected > 0 && selected < this.rowTargets.length
    }
  }
}
