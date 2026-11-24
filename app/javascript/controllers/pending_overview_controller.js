import { Controller } from "@hotwired/stimulus"

// Highlights the routes whose pending counts changed when the overview is
// replaced by a Turbo Stream broadcast. The highlight fades away on its own.
const HIGHLIGHT_CLASSES = [ "ring-2", "ring-sage", "dark:ring-sage-dark" ]
const HIGHLIGHT_DURATION = 1600

export default class extends Controller {
  connect() {
    this.timeouts = []

    this.element
      .querySelectorAll("[data-pending-overview-updated='true'] [data-pending-overview-track]")
      .forEach((track) => {
        track.classList.add(...HIGHLIGHT_CLASSES)
        this.timeouts.push(
          setTimeout(() => track.classList.remove(...HIGHLIGHT_CLASSES), HIGHLIGHT_DURATION)
        )
      })
  }

  disconnect() {
    this.timeouts?.forEach(clearTimeout)
    this.timeouts = []
  }
}
