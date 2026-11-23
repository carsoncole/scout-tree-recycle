import { Controller } from "@hotwired/stimulus"

// Shared pickup details dialog: opens when a map marker is selected and keeps
// the map marker colors in sync after status updates. Used by the driver route
// map and the standalone admin pickups map.
export default class extends Controller {
  static targets = [ "dialog", "frame", "mapWrap", "title" ]

  select(event) {
    const marker = event.detail?.marker || event.detail
    if (!marker || !marker.detail_url) return

    if (this.hasTitleTarget) {
      this.titleTarget.textContent = marker.dialog_title || "Pickup details"
    }

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
    const mapController = mapEl && (mapEl.__mapController || this.application?.getControllerForElementAndIdentifier(mapEl, "map"))
    if (mapController && mapController.updateMarker) {
      mapController.updateMarker({ detail: { id, color: detail.color, status: detail.status } })
    }
  }
}
