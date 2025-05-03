import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle"]

  connect() {
    this.toggleTargets.forEach(toggle => {
      toggle.addEventListener("change", this.handleToggle.bind(this))
    })
  }

  handleToggle(event) {
    const toggle = event.target
    const setting = toggle.dataset.setting
    const value = toggle.checked
    const toggleContainer = toggle.closest('.flex.items-center.justify-between')
    const toggleParent = toggle.closest('.flex.items-center')
    const toggleLabel = toggleParent.querySelector('label')

    // Remove any existing success indicators
    const existingIndicator = toggleContainer.querySelector('.success-indicator')
    if (existingIndicator) {
      existingIndicator.remove()
    }

    fetch(`/admin/settings/1/toggle`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ setting: setting, value: value })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Create success indicator
        const successIndicator = document.createElement('div')
        successIndicator.className = 'success-indicator mr-2'
        successIndicator.innerHTML = `
          <svg class="h-5 w-5 text-green-500" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z" clip-rule="evenodd" />
          </svg>
        `
        // Insert before the toggle label
        toggleParent.insertBefore(successIndicator, toggleLabel)

        // Remove success indicator after 2 seconds
        setTimeout(() => {
          successIndicator.remove()
        }, 2000)
      } else {
        // Revert the toggle
        toggle.checked = !value
      }
    })
    .catch(error => {
      console.error("Error:", error)
      // Revert the toggle
      toggle.checked = !value
    })
  }
} 