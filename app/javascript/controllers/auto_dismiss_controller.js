import { Controller } from "@hotwired/stimulus"

// Removes a transient notification after a delay. The element needs Tailwind's
// transition utilities for the exit classes to animate.
const ENTER_CLASSES = ["opacity-0", "-translate-y-full"]
const EXIT_CLASSES = ["opacity-0", "-translate-y-2"]
const EXIT_DURATION = 200

export default class extends Controller {
  static values = {
    delay: { type: Number, default: 5000 }
  }

  connect() {
    // Force the initial off-screen styles to be laid out before removing them,
    // so the notification slides down into its final position.
    this.element.offsetHeight
    this.element.classList.remove(...ENTER_CLASSES)

    this.timeout = window.setTimeout(() => this.dismiss(), this.delayValue)
  }

  disconnect() {
    window.clearTimeout(this.timeout)
    window.clearTimeout(this.removeTimeout)
  }

  dismiss() {
    window.clearTimeout(this.timeout)
    this.element.classList.add(...EXIT_CLASSES)
    this.removeTimeout = window.setTimeout(() => this.element.remove(), EXIT_DURATION)
  }
}
