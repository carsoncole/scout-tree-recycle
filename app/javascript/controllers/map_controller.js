import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"

export default class extends Controller {
  static values = {
    markers: { type: Array, default: [] },
    polygons: { type: Array, default: [] },
    center: { type: Array, default: [] },
    zoom: { type: Number, default: 13 },
    interactive: { type: Boolean, default: false }
  }

  connect() {
    if (this.map) return

    this.element.__mapController = this
    this.markerLayers = new Map()
    this.statusEntries = new Map()
    this.hiddenStatuses = new Set()
    this.mapBounds = null
    this.previewPopup = null
    this.previewMarker = null
    this.miniMap = null
    this.miniMarker = null
    this.routePointLayers = []
    this.routePointsVisible = false

    const hasCenter = Array.isArray(this.centerValue) && this.centerValue.length === 2 && this.validCoord(this.centerValue[0], this.centerValue[1])
    const initialCenter = hasCenter ? [Number(this.centerValue[0]), Number(this.centerValue[1])] : [47.6062, -122.3321]

    this.map = L.map(this.element, { scrollWheelZoom: false, worldCopyJump: true, zoomSnap: 0.1 }).setView(initialCenter, this.zoomValue)
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(this.map)

    this.layerGroup = L.featureGroup().addTo(this.map)
    this.renderLayers()

    // Leaflet sizes its tile grid from the container at initialization time. If the
    // container grows afterwards (CSS loading, Turbo navigation, responsive layout,
    // flex/grid parents), only part of the map is covered by tiles until we tell
    // Leaflet the size changed. Keep it in sync and re-fit until layout settles.
    if (typeof ResizeObserver !== "undefined") {
      this.resizeObserver = new ResizeObserver(() => this.resizeMap(true))
      this.resizeObserver.observe(this.element)
    }

    this.resizeMap(true)
    requestAnimationFrame(() => this.resizeMap(true))
    setTimeout(() => this.resizeMap(true), 100)
    setTimeout(() => this.resizeMap(true), 300)
    setTimeout(() => this.resizeMap(true), 750)
  }

  disconnect() {
    this.closePickupPreview()
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
      this.resizeObserver = null
    }
    if (this.map) {
      this.map.remove()
      this.map = null
      this.layerGroup = null
      this.markerLayers = null
      this.statusEntries = null
      this.routePointLayers = null
    }
    if (this.element) this.element.__mapController = null
  }

  resizeMap(refit = false) {
    if (!this.map) return

    const rect = this.element.getBoundingClientRect()
    if (rect.width === 0 || rect.height === 0) return

    const widthChanged = this.lastWidth !== rect.width
    this.lastWidth = rect.width

    this.map.invalidateSize({ animate: false, pan: false })

    // Re-fit when the width changes (initial layout, rotation, window resize).
    // Height-only changes, such as a mobile browser hiding its address bar,
    // should not reset the driver's map position.
    if (refit && widthChanged && this.mapBounds && this.mapBounds.isValid()) {
      this.fitToBounds(this.mapBounds)
    }
  }

  fitToBounds(bounds) {
    if (!this.map || !bounds || !bounds.isValid()) return

    const padding = 8
    const size = this.map.getSize()
    const availableWidth = size.x - padding * 2
    const availableHeight = size.y - padding * 2
    if (availableWidth <= 0 || availableHeight <= 0) return

    // fitBounds snaps to whole zoom levels, which often leaves a large margin
    // around the polygon. Calculate the exact zoom so the bounds fill the map.
    const northWest = this.map.project(bounds.getNorthWest(), 0)
    const southEast = this.map.project(bounds.getSouthEast(), 0)
    const boundsWidth = Math.abs(southEast.x - northWest.x)
    const boundsHeight = Math.abs(southEast.y - northWest.y)
    const scaleX = boundsWidth > 0 ? availableWidth / boundsWidth : Infinity
    const scaleY = boundsHeight > 0 ? availableHeight / boundsHeight : Infinity
    const exactZoom = Math.log2(Math.min(scaleX, scaleY))
    const zoom = Math.min(17, Math.floor(exactZoom * 10) / 10)

    this.map.setView(bounds.getCenter(), zoom, { animate: false })
  }

  markersValueChanged() {
    this.closePickupPreview()
    if (this.map && this.layerGroup) {
      this.layerGroup.clearLayers()
      this.markerLayers = new Map()
      this.statusEntries = new Map()
      this.renderLayers()
    }
  }

  // Hide or show reservation markers by pickup status. Location squares and
  // route polygons are unaffected.
  setHiddenStatuses(statuses) {
    this.hiddenStatuses = new Set(Array.isArray(statuses) ? statuses.map(String) : [])
    this.applyStatusVisibility()

    if (this.previewMarker && this.hiddenStatuses.has(String(this.previewMarker.status))) {
      this.closePickupPreview()
    }
  }

  applyStatusVisibility() {
    if (!this.layerGroup || !this.statusEntries) return

    this.statusEntries.forEach(({ status, layers, id }) => {
      const hidden = this.hiddenStatuses.has(status)
      layers.forEach((layer) => {
        if (hidden) {
          this.layerGroup.removeLayer(layer)
        } else if (!this.layerGroup.hasLayer(layer)) {
          this.layerGroup.addLayer(layer)
          // Leaflet may rebuild the SVG element when a layer is re-added, so
          // restore the id used by tests and browser tooling.
          const el = layer.getElement && layer.getElement()
          if (el) el.setAttribute("data-marker-id", String(id))
        }
      })
    })
  }

  // Show or hide the route's own points. Pickup markers and the boundary
  // polygon stay as they are.
  setRoutePointsVisible(visible) {
    this.routePointsVisible = !!visible
    this.applyRoutePointVisibility()
  }

  applyRoutePointVisibility() {
    if (!this.layerGroup || !this.routePointLayers) return

    this.routePointLayers.forEach((layer) => {
      if (this.routePointsVisible) {
        if (!this.layerGroup.hasLayer(layer)) layer.addTo(this.layerGroup)
        const el = layer.getElement && layer.getElement()
        if (el && layer.__pointId != null) el.setAttribute("data-point-id", String(layer.__pointId))
      } else if (this.layerGroup.hasLayer(layer)) {
        this.layerGroup.removeLayer(layer)
      }
    })
  }

  renderLayers() {
    if (!this.layerGroup) return
    const bounds = []
    this.statusEntries = new Map()
    this.routePointLayers = []

    let polygonBounds = null

    this.polygonsValue.forEach((polygon) => {
      const points = this.normalizePolygon(polygon)
      if (points.length > 3) {
        const layer = L.polygon(points, {
          color: polygon.color || "#2563eb",
          weight: 2,
          fillColor: polygon.fillColor || "#3b82f6",
          fillOpacity: 0.2
        })
        if (polygon && polygon.label) layer.bindPopup(String(polygon.label))
        layer.addTo(this.layerGroup)
        polygonBounds = polygonBounds ? polygonBounds.extend(layer.getBounds()) : layer.getBounds()
      }
    })

    if (polygonBounds) bounds.push(polygonBounds)

    this.markersValue.forEach((marker) => {
      const lat = Number(marker.lat ?? marker.latitude)
      const lng = Number(marker.lng ?? marker.longitude)
      if (!this.validCoord(lat, lng)) return

      if (marker.role === "route_point") {
        this.routePointLayers.push(this.routePointLayer(marker, lat, lng))
        bounds.push(L.latLngBounds([ [ lat, lng ], [ lat, lng ] ]))
        return
      }

      const stroke = marker.color || "#b91c1c"
      const fill = marker.fillColor || marker.color || "#ef4444"
      const isSquare = marker.shape === "square"

      const layer = isSquare ? this.squareLayer(lat, lng, stroke, fill) : L.circleMarker([lat, lng], {
        radius: this.interactiveValue ? 12 : 7,
        color: stroke,
        weight: 2,
        fillColor: fill,
        fillOpacity: 0.9
      })

      const selectable = this.interactiveValue && marker.detail_url
      const previewable = selectable && marker.preview
      const select = () => this.selectMarker(marker)
      const preview = () => this.openPickupPreview(marker, lat, lng)
      const statusLayers = []

      if (previewable) {
        layer.on("click", preview)
      } else if (selectable) {
        layer.on("click", select)
      } else {
        const popup = marker.popup || marker.label || marker.name
        if (popup) layer.bindPopup(String(popup))
      }

      layer.addTo(this.layerGroup)
      statusLayers.push(layer)
      if (!isSquare && marker.id !== undefined && marker.id !== null) {
        this.markerLayers.set(String(marker.id), layer)
      }
      if (isSquare && marker.id !== undefined && marker.id !== null) {
        // Expose the location id on the square itself as well as its tap
        // target. The square sits in Leaflet's marker pane above the overlay
        // pane, so it receives clicks at the exact center.
        const markerEl = layer.getElement()
        if (markerEl) markerEl.setAttribute("data-location-id", String(marker.id))
      }

      if (selectable) {
        // Transparent companion circle over the marker so the tap target is
        // large enough for a finger on touch screens (~44px) while the
        // visible marker stays small and easy to tell apart at a glance.
        // Added after the marker so it is the topmost layer at the center.
        const hit = L.circleMarker([lat, lng], {
          radius: 22,
          stroke: false,
          fillColor: "#000000",
          fillOpacity: 0,
          className: isSquare ? "location-marker-hit" : "pickup-marker-hit",
          interactive: true
        })
        hit.on("click", previewable ? preview : select)
        hit.addTo(this.layerGroup)
        statusLayers.push(hit)
        // Mark the SVG element with the marker id so tests and browser
        // devtools can target a specific tap target.
        const hitEl = hit.getElement()
        if (hitEl) hitEl.setAttribute(isSquare ? "data-location-id" : "data-marker-id", String(marker.id))
      }

      if (!isSquare && marker.status && marker.id !== undefined && marker.id !== null) {
        this.statusEntries.set(String(marker.id), {
          id: String(marker.id),
          status: String(marker.status),
          layers: statusLayers
        })
      }

      // A coordinate far from the route boundary must not zoom the map out
      // to the world. The marker stays on the map for anyone who pans to it.
      if (!polygonBounds || this.nearBounds(polygonBounds, lat, lng)) {
        bounds.push(L.latLngBounds([[lat, lng], [lat, lng]]))
      }
    })

    this.applyStatusVisibility()
    this.applyRoutePointVisibility()

    if (bounds.length > 0) {
      const combined = bounds.reduce((acc, b) => (acc ? acc.extend(b) : b), null)
      if (combined && combined.isValid()) {
        this.mapBounds = combined
        this.fitToBounds(combined)
      }
    }
  }

  // A selected reservation opens a preview popup with a close-up map of just
  // that pickup. The full details dialog still loads from detail_url, but only
  // after the driver taps the preview point or the View details button.
  openPickupPreview(marker, lat, lng) {
    if (!this.map) return
    this.closePickupPreview()

    const container = document.createElement("div")
    container.className = "pickup-mini-popup flex flex-col font-sans"
    if (marker.id !== undefined && marker.id !== null) {
      container.dataset.markerId = String(marker.id)
    }

    const miniMapEl = document.createElement("div")
    miniMapEl.className = "pickup-mini-map w-full bg-stone dark:bg-stone-dark"
    miniMapEl.setAttribute("aria-hidden", "true")
    container.appendChild(miniMapEl)

    const address = document.createElement("a")
    address.className = "pickup-mini-address flex min-h-12 items-center gap-2 border-t border-line px-4 py-2.5 text-[0.95rem] font-semibold leading-snug text-sage-deep! hover:text-ink! dark:border-line-dark dark:text-sage-deep-dark! dark:hover:text-ink-dark!"
    address.href = marker.directions_url || marker.detail_url
    address.target = "_blank"
    address.rel = "noopener"
    address.setAttribute("aria-label", `Get directions to ${marker.address || "this pickup"}`)

    const addressIcon = document.createElement("span")
    addressIcon.className = "shrink-0"
    addressIcon.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" class="size-5" aria-hidden="true"><path d="M4.5 19.5v-6.75A3.75 3.75 0 0 1 8.25 9h10.5" /><path d="m15.75 5.25 3 3.75-3 3.75" /></svg>'
    address.appendChild(addressIcon)

    const addressText = document.createElement("span")
    addressText.textContent = marker.address || "Pickup address"
    address.appendChild(addressText)
    container.appendChild(address)

    const details = document.createElement("button")
    details.type = "button"
    details.className = "pickup-mini-details min-h-12 w-full border-t border-line px-4 py-2.5 text-[0.95rem] font-semibold text-ink hover:bg-stone dark:border-line-dark dark:text-ink-dark dark:hover:bg-stone-dark"
    details.textContent = "View details"
    details.addEventListener("click", (event) => {
      event.preventDefault()
      this.selectMarker(marker)
    })
    container.appendChild(details)

    const popup = L.popup({
      maxWidth: 420,
      minWidth: 320,
      autoPan: true,
      autoPanPadding: [16, 16],
      closeButton: true,
      className: "pickup-mini-popup-shell"
    }).setLatLng([lat, lng]).setContent(container)

    this.previewPopup = popup
    this.previewMarker = marker

    popup.on("remove", () => {
      if (this.previewPopup === popup) {
        this.previewPopup = null
        this.previewMarker = null
      }
      this.stopMiniMap()
    })

    this.map.openPopup(popup)
    this.stylePopupChrome(popup)

    requestAnimationFrame(() => {
      if (this.previewPopup === popup) this.startMiniMap(miniMapEl, marker, lat, lng)
    })
  }

  // Hand the selected marker back to pickup_details_controller, which opens
  // the shared details dialog.
  selectMarker(marker) {
    this.closePickupPreview()
    this.dispatch("marker-selected", { detail: { marker } })
  }

  closePickupPreview() {
    this.stopMiniMap()
    if (this.map && this.previewPopup) this.map.closePopup(this.previewPopup)
    this.previewPopup = null
    this.previewMarker = null
  }

  startMiniMap(element, marker, lat, lng) {
    if (!element || this.miniMap) return

    const miniMap = L.map(element, {
      zoomControl: false,
      attributionControl: false,
      scrollWheelZoom: false,
      doubleClickZoom: false,
      boxZoom: false,
      keyboard: false,
      dragging: false,
      touchZoom: false
    }).setView([lat, lng], 17)

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19
    }).addTo(miniMap)

    const dot = L.circleMarker([lat, lng], {
      radius: 10,
      color: marker.color || "#b91c1c",
      weight: 2,
      fillColor: marker.fillColor || marker.color || "#ef4444",
      fillOpacity: 0.95,
      className: "pickup-mini-point"
    }).addTo(miniMap)
    dot.on("click", () => this.selectMarker(marker))

    // Same large invisible tap target as the main map, so the preview point
    // is easy to hit on a phone.
    const hit = L.circleMarker([lat, lng], {
      radius: 22,
      stroke: false,
      fillColor: "#000000",
      fillOpacity: 0,
      className: "pickup-mini-point-hit"
    }).addTo(miniMap)
    hit.on("click", () => this.selectMarker(marker))
    const hitElement = hit.getElement()
    if (hitElement && marker.id !== undefined && marker.id !== null) {
      hitElement.setAttribute("data-marker-id", String(marker.id))
    }

    this.miniMap = miniMap
    this.miniMarker = dot
    // The preview map is decorative and aria-hidden, so keep it out of the
    // keyboard tab order even though Leaflet makes map containers focusable.
    element.removeAttribute("tabindex")
    miniMap.invalidateSize({ animate: false, pan: false })
    requestAnimationFrame(() => {
      if (this.miniMap === miniMap) miniMap.invalidateSize({ animate: false, pan: false })
    })
  }

  stopMiniMap() {
    if (this.miniMap) {
      this.miniMap.remove()
      this.miniMap = null
    }
    this.miniMarker = null
  }

  // Leaflet paints its popup chrome white. Apply the app's surface tokens once
  // the popup is in the DOM so the preview follows light and dark mode.
  stylePopupChrome(popup) {
    const element = popup.getElement()
    if (!element) return

    const wrapper = element.querySelector(".leaflet-popup-content-wrapper")
    const tip = element.querySelector(".leaflet-popup-tip")
    const close = element.querySelector(".leaflet-popup-close-button")

    if (wrapper) {
      wrapper.classList.add("border", "border-line", "bg-surface", "text-ink", "dark:border-line-dark", "dark:bg-surface-dark", "dark:text-ink-dark")
    }
    if (tip) tip.classList.add("bg-surface", "dark:bg-surface-dark")
    if (close) {
      close.classList.add("rounded-full", "text-ink", "hover:bg-stone", "dark:text-ink-dark", "dark:hover:bg-stone-dark")
    }
  }

  // A route point is a numbered corner of the boundary. It stays off the map
  // until the route page asks for it, then opens its own popup when clicked.
  routePointLayer(marker, lat, lng) {
    const label = marker.order === undefined || marker.order === null || marker.order === "" ? "•" : String(marker.order)
    const badge = document.createElement("span")
    badge.className = "flex size-7 items-center justify-center rounded-full border-2 border-sage-deep bg-surface text-[0.75rem] font-semibold leading-none text-sage-deep shadow-sm dark:border-sage-dark dark:bg-surface-dark dark:text-sage-dark"
    badge.textContent = label

    const layer = L.marker([ lat, lng ], {
      keyboard: true,
      title: `Route point ${label}`,
      zIndexOffset: 400,
      icon: L.divIcon({
        className: "route-point-marker",
        html: badge,
        iconSize: [ 28, 28 ],
        iconAnchor: [ 14, 14 ],
        popupAnchor: [ 0, -16 ]
      })
    })
    layer.__pointId = marker.id

    const popup = document.createElement("div")
    popup.className = "route-point-popup flex flex-col font-sans text-[0.85rem] leading-tight"
    if (marker.id !== undefined && marker.id !== null) popup.dataset.pointId = String(marker.id)

    const heading = document.createElement("div")
    heading.className = "font-semibold text-ink dark:text-ink-dark"
    heading.textContent = "Route point"

    const orderLine = document.createElement("div")
    orderLine.className = "text-ink dark:text-ink-dark"
    orderLine.textContent = `Order ${label}`

    const coords = document.createElement("div")
    coords.className = "text-ink-soft dark:text-ink-soft-dark"
    coords.textContent = `${this.formatCoord(lat)}, ${this.formatCoord(lng)}`

    popup.append(heading, orderLine, coords)

    const editUrl = typeof marker.edit_url === "string" ? marker.edit_url : ""
    if (editUrl.startsWith("/")) {
      const edit = document.createElement("a")
      edit.href = editUrl
      edit.className = "admin-link mt-1 text-sage-deep hover:text-ink dark:text-sage-deep-dark dark:hover:text-ink-dark"
      edit.textContent = "Edit"
      edit.addEventListener("click", (event) => event.stopPropagation())
      popup.append(edit)
    }

    layer.bindPopup(popup)
    layer.on("popupopen", (event) => {
      this.stylePopupChrome(event.popup)
    })

    return layer
  }

  formatCoord(value) {
    const number = Number(value)
    if (!Number.isFinite(number)) return ""

    return number.toFixed(6).replace(/\.?0+$/, "")
  }

  // Locations render as fixed-size squares so they are visually distinct from
  // the circular reservation dots at every zoom level. On the driver route map
  // they open the shared details dialog; elsewhere they are popup-only. They
  // are never pickup stops and are not registered in markerLayers.
  squareLayer(lat, lng, stroke, fill) {
    const size = 16
    return L.marker([lat, lng], {
      keyboard: true,
      icon: L.divIcon({
        className: "location-marker",
        html: `<span style="display:block;width:${size}px;height:${size}px;border:2px solid ${stroke};background:${fill};border-radius:2px"></span>`,
        iconSize: [size, size],
        iconAnchor: [size / 2, size / 2]
      })
    })
  }

  updateMarker(event) {
    const detail = event.detail || {}
    const id = detail.id
    if (!id || !this.markerLayers) return
    const key = String(id)
    const color = detail.color || "#2563eb"
    const layer = this.markerLayers.get(key)
    if (layer) layer.setStyle({ color: color, fillColor: color })

    const statusEntry = this.statusEntries?.get(key)
    if (detail.status && statusEntry) statusEntry.status = String(detail.status)

    const marker = this.markersValue.find((m) => String(m.id) === key)
    if (marker) {
      marker.color = color
      if (detail.status) marker.status = detail.status
    }

    if (this.previewMarker && String(this.previewMarker.id) === key) {
      this.previewMarker.color = color
      if (detail.status) this.previewMarker.status = detail.status
      if (this.miniMarker) this.miniMarker.setStyle({ color: color, fillColor: color })
      if (detail.status && this.hiddenStatuses.has(String(detail.status))) this.closePickupPreview()
    }

    if (detail.status) this.applyStatusVisibility()
  }

  normalizePolygon(polygon) {
    const rawPoints = Array.isArray(polygon) ? polygon : (polygon?.points || [])
    return rawPoints
      .map((point) => {
        if (Array.isArray(point)) return [Number(point[0]), Number(point[1])]
        return [Number(point.lat ?? point.latitude), Number(point.lng ?? point.longitude)]
      })
      .filter(([lat, lng]) => this.validCoord(lat, lng))
  }

  validCoord(lat, lng) {
    return Number.isFinite(lat) && Number.isFinite(lng) && Math.abs(lat) <= 90 && Math.abs(lng) <= 180
  }

  nearBounds(bounds, lat, lng) {
    const pad = 0.15
    return lat <= bounds.getNorth() + pad && lat >= bounds.getSouth() - pad &&
      lng <= bounds.getEast() + pad && lng >= bounds.getWest() - pad
  }
}
