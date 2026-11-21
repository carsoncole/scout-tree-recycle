import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tooltip", "guide"]

  show(event) {
    const tooltip = this.tooltipTarget
    tooltip.hidden = false
    tooltip.replaceChildren()

    const value = document.createElement("span")
    value.className = "font-semibold text-ink dark:text-ink-dark"
    value.textContent = event.params.value

    const label = document.createElement("span")
    label.className = "text-ink-soft dark:text-ink-soft-dark"
    label.textContent = event.params.label

    tooltip.append(value, label)

    const host = this.element.getBoundingClientRect()
    const column = event.currentTarget.getBoundingClientRect()
    const center = column.left + (column.width / 2) - host.left
    const width = tooltip.offsetWidth
    const left = Math.min(Math.max(center - (width / 2), 8), Math.max(host.width - width - 8, 8))

    tooltip.style.left = `${left}px`
    tooltip.style.top = "0.35rem"

    if (this.hasGuideTarget) {
      this.guideTarget.hidden = false
      this.guideTarget.style.left = `${center}px`
    }
  }

  hide() {
    this.tooltipTarget.hidden = true
    if (this.hasGuideTarget) this.guideTarget.hidden = true
  }
}
