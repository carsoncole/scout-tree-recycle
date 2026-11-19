import { Controller } from "@hotwired/stimulus"

// Route map page: opens the pickup details dialog when a map marker is
// selected and keeps the map marker colors in sync after status updates.
export default class extends Controller {
  static targets = [ "dialog", "frame", "mapWrap" ]

  select(event) {
    const marker = event.detail?.marker || event.detail
    if (!marker || !marker.detail_url) return

    this.frameTarget.src = marker.detail_url

    if (!this.dialogTarget.open) {
      this.dialogTarget.showModal()
    }
  }

  close() {
    if (this.dialogTarget.open) this.dialogTarget.close()
  }

  dialogClosed() {
    this.frameTarget.removeAttribute("src")
    this.frameTarget.innerHTML = ""
  }

  // The dialog element itself is the backdrop, so a click that hits the
  // element (not its children) is a backdrop tap.
  backdropClose(event) {
    if (event.target === event.currentTarget) event.currentTarget.close()
  }

  markerUpdated(event) {
    const detail = event.detail || {}
    const id = detail.id
    if (!id) return

    const mapEl = this.hasMapWrapTarget ? this.mapWrapTarget.querySelector('[data-controller~="map"]') : document.querySelector('[data-controller~="map"]')
    if (mapEl && mapEl.__mapController) {
      mapEl.__mapController.updateMarker({ detail: { id, color: detail.color, status: detail.status } })
    } else if (mapEl && this.application) {
      const mapController = this.application.getControllerForElementAndIdentifier(mapEl, "map")
      if (mapController && mapController.updateMarker) mapController.updateMarker({ detail: { id, color: detail.color, status: detail.status } })
    }
  }
}
