import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.previousValues = new Map(
      Array.from(this.element.elements).map((field) => [ field, field.value ])
    )
  }

  submit(event) {
    const field = event.target
    const previousValue = this.previousValues.get(field) ?? field.value

    if (event.params.confirm && !window.confirm(event.params.confirm)) {
      field.value = previousValue
      return
    }

    this.previousValues.set(field, field.value)
    field.form.requestSubmit()
  }
}
