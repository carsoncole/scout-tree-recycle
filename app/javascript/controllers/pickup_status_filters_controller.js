import { Controller } from "@hotwired/stimulus"

// Admin pickups map: show or hide reservation markers by pickup status while
// leaving route areas and location squares visible.
export default class extends Controller {
  static targets = [ "mapWrap" ]

  connect() {
    this.hiddenStatuses = new Set()
  }

  toggle(event) {
    const button = event.currentTarget
    const status = button.dataset.status
    if (!status) return

    const pressed = button.getAttribute("aria-pressed") !== "false"
    if (pressed) {
      this.hiddenStatuses.add(status)
      button.setAttribute("aria-pressed", "false")
    } else {
      this.hiddenStatuses.delete(status)
      button.setAttribute("aria-pressed", "true")
    }

    this.applyToMap()
  }

  applyToMap() {
    const mapEl = this.hasMapWrapTarget ? this.mapWrapTarget.querySelector('[data-controller~="map"]') : null
    if (!mapEl) return

    const mapController = mapEl.__mapController || this.application?.getControllerForElementAndIdentifier(mapEl, "map")
    if (mapController && mapController.setHiddenStatuses) {
      mapController.setHiddenStatuses([ ...this.hiddenStatuses ])
    }
  }
}
