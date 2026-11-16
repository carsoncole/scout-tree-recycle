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
      <div id="panel_reservation_${marker.id}" class="flex flex-col gap-6" data-pickups-route-panel-reservation-id-value="${marker.id}">
        <div>
          <p class="admin-label text-ink dark:text-ink-dark">Address</p>
          <p class="admin-detail-value text-ink dark:text-ink-dark"></p>
        </div>
        <div>
          <p class="admin-label text-ink dark:text-ink-dark">Notes</p>
          <div class="notes-slot"></div>
        </div>
        <div>
          <p class="admin-label text-ink dark:text-ink-dark">Current status</p>
          <p><span class="${badgeClass}" data-status-badge>${this.statusLabel(status)}</span></p>
        </div>
        <form action="${marker.update_url}" method="post" data-turbo="true" class="admin-form">
          <input type="hidden" name="_method" value="patch">
          <input type="hidden" name="authenticity_token" value="${csrf}">
          <div class="admin-field">
            <label class="admin-label text-ink dark:text-ink-dark" for="reservation_status_${marker.id}">Update status</label>
            <select id="reservation_status_${marker.id}" name="reservation[status]" class="admin-select border border-line-strong bg-surface text-ink placeholder-muted hover:border-ink-soft focus:border-sage focus:bg-[#fffdf8] disabled:bg-stone disabled:text-muted dark:border-line-strong-dark dark:bg-stone-dark dark:text-ink-dark dark:placeholder-muted-dark dark:hover:border-ink-soft-dark dark:focus:border-sage-dark dark:focus:bg-input-focus-dark dark:disabled:bg-stone-dark dark:disabled:text-muted-dark">${optionsHtml}</select>
          </div>
          <div class="mt-3">
            <button type="submit" class="admin-button bg-sage text-surface hover:bg-sage-deep dark:bg-sage-dark dark:text-page-dark dark:hover:bg-sage-deep-dark">Update status</button>
          </div>
        </form>
      </div>
    `
    const panel = this.contentTarget.querySelector(`#panel_reservation_${marker.id}`)
    if (panel) {
      panel.querySelector(".admin-detail-value").textContent = marker.address || ""
      const notesSlot = panel.querySelector(".notes-slot")
      if (marker.pickup_notes && marker.pickup_notes.length > 0) {
        notesSlot.innerHTML = `<p class="admin-detail-value whitespace-pre-wrap text-ink dark:text-ink-dark"></p>`
        notesSlot.querySelector("p").textContent = marker.pickup_notes
      } else {
        notesSlot.innerHTML = `<p class="admin-table-note text-ink-soft dark:text-ink-soft-dark">No special instructions.</p>`
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
