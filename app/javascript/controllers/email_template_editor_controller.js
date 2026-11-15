import { Controller } from "@hotwired/stimulus"

// Small, dependency-free code editor enhancement for the template textareas.
// It keeps Tab inside the textarea and lets the variable list insert merge tags
// into whichever editor was focused most recently.
export default class extends Controller {
  static targets = ["field"]

  connect() {
    this.activeField = this.fieldTargets[0]
  }

  focus(event) {
    if (this.fieldTargets.includes(event.target)) {
      this.activeField = event.target
    }
  }

  handleKeydown(event) {
    if (event.key !== "Tab" || event.shiftKey || !this.fieldTargets.includes(event.target)) return

    event.preventDefault()
    this.insertText(event.target, "  ")
  }

  insert(event) {
    event.preventDefault()

    const variable = event.currentTarget.dataset.variable
    if (!variable) return

    const field = this.activeField || this.fieldTargets[0]
    if (!field) return

    this.insertText(field, variable)
  }

  insertText(field, text) {
    const start = field.selectionStart ?? field.value.length
    const end = field.selectionEnd ?? field.value.length

    field.setRangeText(text, start, end, "end")
    field.focus()
    field.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
