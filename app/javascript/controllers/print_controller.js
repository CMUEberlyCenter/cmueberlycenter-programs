import { Controller } from "@hotwired/stimulus"

// A button that prints the page
export default class extends Controller {
  print() {
    window.print()
  }
}
