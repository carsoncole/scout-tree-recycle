import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle"]

  connect() {
    this.toggleTargets.forEach((toggle) => {
      toggle.addEventListener("change", this.handleToggle)
    })
  }

  disconnect() {
    this.toggleTargets.forEach((toggle) => {
      toggle.removeEventListener("change", this.handleToggle)
    })
  }

  handleToggle = (event) => {
    const toggle = event.target
    const row = toggle.closest("[data-toggle-row]") || this.element
    const control = row.querySelector("[data-toggle-control]") || toggle.parentElement
    const copy = row.querySelector("[data-toggle-copy]") || row
    const setting = toggle.dataset.setting
    const value = toggle.checked

    row.querySelectorAll(".admin-toggle-feedback").forEach((element) => element.remove())

    const headers = { "Content-Type": "application/json" }
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) headers["X-CSRF-Token"] = csrfToken

    fetch(this.element.dataset.toggleUrl, {
      method: "PATCH",
      headers: headers,
      body: JSON.stringify({ setting: setting, value: value })
    })
      .then((response) => response.json())
      .then((data) => {
        if (data.success) {
          const indicator = document.createElement("span")
          indicator.className = "admin-toggle-feedback admin-badge admin-badge--positive"
          indicator.textContent = "Saved"
          control.insertBefore(indicator, control.firstChild)

          setTimeout(() => indicator.remove(), 2000)
        } else {
          toggle.checked = !value

          const message = document.createElement("p")
          message.className = "admin-toggle-feedback admin-error-text"
          message.textContent = data.errors?.[0] || "An error occurred"
          copy.appendChild(message)

          setTimeout(() => message.remove(), 3000)
        }
      })
      .catch((error) => {
        console.error("Error:", error)
        toggle.checked = !value
      })
  }
}
