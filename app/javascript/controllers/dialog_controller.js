import { Controller } from "@hotwired/stimulus"

// A dialog (cmu-dialog) that opens when it arrives, such as a form Turbo
// loads into the modal frame, and empties the frame when it closes
export default class extends Controller {
  connect() {
    this.element.showModal()
    this.element.addEventListener("close", () => {
      const frame = this.element.closest("turbo-frame")
      if (frame) frame.innerHTML = ""
    })
  }
}
