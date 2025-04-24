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
        // Show success message
        const flash = document.createElement("div")
        flash.className = "mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 mt-4"
        flash.innerHTML = `
          <div class="rounded-md bg-green-50 dark:bg-green-900 p-4">
            <div class="flex">
              <div class="flex-shrink-0">
                <svg class="h-5 w-5 text-green-400 dark:text-green-300" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z" clip-rule="evenodd" />
                </svg>
              </div>
              <div class="ml-3">
                <p class="text-sm font-medium text-green-800 dark:text-green-200">Setting updated successfully</p>
              </div>
            </div>
          </div>
        `
        document.querySelector('.min-h-full').insertBefore(flash, document.querySelector('main'))
        setTimeout(() => flash.remove(), 3000)
      } else {
        // Show error message
        const flash = document.createElement("div")
        flash.className = "mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 mt-4"
        flash.innerHTML = `
          <div class="rounded-md bg-red-50 dark:bg-red-900 p-4">
            <div class="flex">
              <div class="flex-shrink-0">
                <svg class="h-5 w-5 text-red-400 dark:text-red-300" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clip-rule="evenodd" />
                </svg>
              </div>
              <div class="ml-3">
                <p class="text-sm font-medium text-red-800 dark:text-red-200">Failed to update setting</p>
              </div>
            </div>
          </div>
        `
        document.querySelector('.min-h-full').insertBefore(flash, document.querySelector('main'))
        setTimeout(() => flash.remove(), 3000)
        // Revert the toggle
        toggle.checked = !value
      }
    })
    .catch(error => {
      console.error("Error:", error)
      // Show error message
      const flash = document.createElement("div")
      flash.className = "mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 mt-4"
      flash.innerHTML = `
        <div class="rounded-md bg-red-50 dark:bg-red-900 p-4">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-red-400 dark:text-red-300" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clip-rule="evenodd" />
              </svg>
            </div>
            <div class="ml-3">
              <p class="text-sm font-medium text-red-800 dark:text-red-200">Failed to update setting</p>
            </div>
          </div>
        </div>
      `
      document.querySelector('.min-h-full').insertBefore(flash, document.querySelector('main'))
      setTimeout(() => flash.remove(), 3000)
      // Revert the toggle
      toggle.checked = !value
    })
  }
} 