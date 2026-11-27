import { Controller } from "@hotwired/stimulus"

// Route show map: the Points toggle reveals every route point.
export default class extends Controller {
  static targets = [ "map" ]

  togglePoints(event) {
    const button = event.currentTarget
    const show = button.getAttribute("aria-pressed") !== "true"
    button.setAttribute("aria-pressed", show ? "true" : "false")
    this.mapController()?.setRoutePointsVisible(show)
  }

  mapController() {
    if (!this.hasMapTarget) return null

    const mapEl = this.mapTarget.querySelector('[data-controller~="map"]')
    if (!mapEl) return null

    return mapEl.__mapController || this.application.getControllerForElementAndIdentifier(mapEl, "map")
  }
}
