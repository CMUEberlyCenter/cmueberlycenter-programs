// Turbo's confirmations (data-turbo-confirm) in the kit's dialog
// (cmu-dialog): the message as the heading, then a button in the words of
// the one that asked, then Cancel. Resolves true for the first button.
function label(element, submitter) {
  const button = submitter || element.querySelector("button, input[type=submit]") || element
  return (button.value || button.textContent || "Continue").trim()
}

window.Turbo.config.forms.confirm = (message, element, submitter) => {
  const dialog = document.createElement("dialog")
  dialog.className = "cmu-dialog"
  dialog.setAttribute("aria-labelledby", "prg-confirm-title")
  dialog.innerHTML =
    '<form method="dialog"><h2 id="prg-confirm-title"></h2><div class="cmu-dialog-buttons">' +
    '<button class="btn" value="yes"></button> <button class="btn ghost" value="no">Cancel</button>' +
    "</div></form>"
  dialog.querySelector("h2").textContent = message
  dialog.querySelector("[value=yes]").textContent = label(element, submitter)
  document.body.append(dialog)
  dialog.showModal()
  return new Promise((resolve) => {
    dialog.addEventListener("close", () => {
      resolve(dialog.returnValue === "yes")
      dialog.remove()
    })
  })
}
