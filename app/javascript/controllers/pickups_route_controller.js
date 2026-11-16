import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "mapWrap", "panel"]

  connect() {
    this.markersById = {}
    this.refreshMarkersIndex()
  }

  refreshMarkersIndex() {
    const el = document.getElementById("pickups-route-markers")
    if (el) {
      try {
        const markers = JSON.parse(el.textContent || "[]")
        markers.forEach((m) => { if (m && m.id) this.markersById[String(m.id)] = m })
      } catch (e) {
        // ignore
      }
    }
  }

  select(event) {
    const marker = event.detail?.marker || event.detail
    if (!marker || !marker.id) return
    this.currentMarker = marker
    this.renderPanel(marker)

    if (this.hasPanelTarget && window.matchMedia("(max-width: 1023px)").matches) {
      this.panelTarget.scrollIntoView({ behavior: "smooth", block: "start" })
    }
  }

  markerUpdated(event) {
    const detail = event.detail || {}
    const id = detail.id
    if (!id) return
    const color = detail.color
    const status = detail.status
    if (this.markersById[String(id)]) {
      if (color) this.markersById[String(id)].color = color
      if (status) this.markersById[String(id)].status = status
    }
    const mapEl = this.hasMapWrapTarget ? this.mapWrapTarget.querySelector('[data-controller~="map"]') : document.querySelector('[data-controller~="map"]')
    if (mapEl && mapEl.__mapController) {
      mapEl.__mapController.updateMarker({ detail: { id, color, status } })
    } else if (mapEl && this.application) {
      const mapController = this.application.getControllerForElementAndIdentifier(mapEl, "map")
      if (mapController && mapController.updateMarker) mapController.updateMarker({ detail: { id, color, status } })
    }
  }

  renderPanel(marker) {
    if (!this.hasContentTarget) return
    const csrf = document.querySelector('meta[name="csrf-token"]')?.content || ""
    const status = marker.status || "pending_pickup"
    const options = [
      ["pending_pickup", "Pending Pickup"],
      ["picked_up", "Picked Up"],
      ["missing", "Missing"]
    ]
    const optionsHtml = options.map(([value, label]) => {
      const selected = value === status ? " selected" : ""
      return `<option value="${value}"${selected}>${label}</option>`
    }).join("")
    const badgeClass = this.badgeClass(status)

    this.contentTarget.innerHTML = `
      <div id="panel_reservation_${marker.id}" class="admin-stack" data-pickups-route-panel-reservation-id-value="${marker.id}">
        <div>
          <p class="admin-label">Address</p>
          <p class="admin-detail-value"></p>
        </div>
        <div>
          <p class="admin-label">Notes</p>
          <div class="notes-slot"></div>
        </div>
        <div>
          <p class="admin-label">Current status</p>
          <p><span class="${badgeClass}" data-status-badge>${this.statusLabel(status)}</span></p>
        </div>
        <form action="${marker.update_url}" method="post" data-turbo="true" class="admin-form">
          <input type="hidden" name="_method" value="patch">
          <input type="hidden" name="authenticity_token" value="${csrf}">
          <div class="admin-field">
            <label class="admin-label" for="reservation_status_${marker.id}">Update status</label>
            <select id="reservation_status_${marker.id}" name="reservation[status]" class="admin-select">${optionsHtml}</select>
          </div>
          <div class="mt-3">
            <button type="submit" class="admin-button">Update status</button>
          </div>
        </form>
      </div>
    `
    const panel = this.contentTarget.querySelector(`#panel_reservation_${marker.id}`)
    if (panel) {
      panel.querySelector(".admin-detail-value").textContent = marker.address || ""
      const notesSlot = panel.querySelector(".notes-slot")
      if (marker.pickup_notes && marker.pickup_notes.length > 0) {
        notesSlot.innerHTML = `<p class="admin-detail-value whitespace-pre-wrap"></p>`
        notesSlot.querySelector("p").textContent = marker.pickup_notes
      } else {
        notesSlot.innerHTML = `<p class="admin-table-note">No special instructions.</p>`
      }
    }
  }

  statusLabel(status) {
    if (status === "pending_pickup") return "Pending pickup"
    if (status === "picked_up") return "Picked up"
    if (status === "missing") return "Missing"
    return String(status || "").replace(/_/g, " ")
  }

  badgeClass(status) {
    if (status === "pending_pickup") return "admin-badge admin-badge--positive"
    if (status === "picked_up") return "admin-badge admin-badge--info"
    if (status === "missing") return "admin-badge admin-badge--warning"
    return "admin-badge admin-badge--neutral"
  }
}
