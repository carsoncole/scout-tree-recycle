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
    this.polygonLabels = []

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
    this.separatePolygonLabels()
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

  renderLayers() {
    if (!this.layerGroup) return
    const bounds = []
    this.statusEntries = new Map()

    let polygonBounds = null
    this.polygonLabels = []

    this.polygonsValue.forEach((polygon) => {
      const points = this.normalizePolygon(polygon)
      if (points.length > 3) {
        const labelUrl = this.localPath(polygon?.labelUrl)
        const layer = L.polygon(points, {
          color: polygon.color || "#2563eb",
          weight: 2,
          fillColor: polygon.fillColor || "#3b82f6",
          fillOpacity: polygon.fillOpacity ?? 0.2
        })
        if (polygon?.permanentLabel && polygon.label) {
          this.addPolygonLabel(points, String(polygon.label), labelUrl)
        } else if (polygon && polygon.label) {
          layer.bindPopup(String(polygon.label))
        }
        layer.addTo(this.layerGroup)
        polygonBounds = polygonBounds ? polygonBounds.extend(layer.getBounds()) : layer.getBounds()
      }
    })

    if (polygonBounds) bounds.push(polygonBounds)

    this.markersValue.forEach((marker) => {
      const lat = Number(marker.lat ?? marker.latitude)
      const lng = Number(marker.lng ?? marker.longitude)
      if (!this.validCoord(lat, lng)) return

      if (marker.role === "route_point" || marker.role === "nearby_route_point") {
        this.polygonPointLayer(marker, lat, lng).addTo(this.layerGroup)
        // This route's corners always frame the map. A nearby corner only
        // does when it sits near the boundary, so a distant point cannot
        // zoom the map out.
        if (marker.role === "route_point" || !polygonBounds || this.nearBounds(polygonBounds, lat, lng)) {
          bounds.push(L.latLngBounds([ [ lat, lng ], [ lat, lng ] ]))
        }
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

  // Leaflet paints its popup chrome white. Pickup previews follow light and dark mode.
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

  // The basemap stays light, so route-point popups use the light surface only.
  // Leaflet's unlayered popup rules beat layered utilities, so these use
  // important. There are no dark: classes: the tiles do not switch.
  styleMapPopupChrome(popup) {
    const element = popup.getElement()
    if (!element) return

    const wrapper = element.querySelector(".leaflet-popup-content-wrapper")
    const tip = element.querySelector(".leaflet-popup-tip")
    const close = element.querySelector(".leaflet-popup-close-button")

    if (wrapper) wrapper.classList.add("border", "!border-line", "!bg-surface", "!text-ink")
    if (tip) tip.classList.add("!bg-surface")
    if (close) close.classList.add("rounded-full", "!text-ink", "hover:!text-ink", "hover:!bg-stone")
  }

  // One popup for every route point on admin settings maps: route name,
  // latitude, longitude, and an edit link.
  bindRoutePointPopup(layer, marker, lat, lng) {
    const popup = document.createElement("div")
    popup.className = "route-point-popup flex flex-col font-sans text-[0.85rem] leading-tight !text-ink"
    if (marker.id !== undefined && marker.id !== null) popup.dataset.pointId = String(marker.id)

    const heading = document.createElement("div")
    heading.className = "font-semibold !text-ink"
    heading.textContent = marker.route_name ? String(marker.route_name) : "Route"

    const latitude = document.createElement("div")
    latitude.className = "!text-ink"
    latitude.textContent = `Latitude ${this.formatCoord(lat)}`

    const longitude = document.createElement("div")
    longitude.className = "!text-ink"
    longitude.textContent = `Longitude ${this.formatCoord(lng)}`

    popup.append(heading, latitude, longitude)

    const editUrl = typeof marker.edit_url === "string" ? marker.edit_url : ""
    if (editUrl.startsWith("/")) {
      const edit = document.createElement("a")
      edit.href = editUrl
      // Leaflet colors every map link #0078A8. Important keeps the light sage
      // on the light basemap, including after the link has been visited.
      edit.className = "mt-1 no-underline !text-sage-deep hover:!text-ink visited:!text-sage-deep"
      edit.textContent = "Edit"
      edit.addEventListener("click", (event) => event.stopPropagation())
      popup.append(edit)
    }

    layer.bindPopup(popup)
    layer.on("popupopen", (event) => {
      this.styleMapPopupChrome(event.popup)
    })
  }

  // A same-site path opens that page. Route names use it. Polygon fills do not.
  localPath(value) {
    if (typeof value !== "string") return ""
    if (!value.startsWith("/") || value.startsWith("//")) return ""

    return value
  }

  visitLocalPath(url, originalEvent) {
    const path = this.localPath(url)
    if (!path) return

    const openNewTab = originalEvent && (
      originalEvent.metaKey ||
      originalEvent.ctrlKey ||
      originalEvent.shiftKey ||
      originalEvent.button === 1
    )
    if (openNewTab) {
      window.open(path, "_blank", "noopener")
      return
    }

    if (window.Turbo && typeof window.Turbo.visit === "function") {
      window.Turbo.visit(path)
    } else {
      window.location.assign(path)
    }
  }

  // Name drawn on a route polygon. A linked name opens that route even when
  // another boundary covers the fill. An unlabeled name does not take clicks.
  // The label is anchored inside the polygon, then nudged so neighboring
  // names do not cover each other.
  addPolygonLabel(points, text, url = "") {
    const [ lat, lng ] = this.polygonLabelPoint(points)
    const path = this.localPath(url)
    const badge = document.createElement(path ? "a" : "span")
    badge.className = "route-polygon-label absolute left-0 top-0 -translate-x-1/2 -translate-y-1/2 whitespace-nowrap rounded-full border border-line bg-surface px-2 py-0.5 text-[0.75rem] font-semibold leading-none text-ink shadow-xs dark:border-line-dark dark:bg-surface-dark dark:text-ink-dark"
    badge.textContent = text
    if (path) {
      badge.href = path
      // Leaflet colors every map link #0078A8, which beats layered utilities.
      badge.classList.add(
        "pointer-events-auto",
        "cursor-pointer",
        "no-underline",
        "!text-ink",
        "hover:!text-ink",
        "visited:!text-ink",
        "dark:!text-ink-dark",
        "dark:hover:!text-ink-dark",
        "dark:visited:!text-ink-dark"
      )
      badge.setAttribute("data-route-url", path)
      badge.addEventListener("pointerdown", (event) => event.stopPropagation())
      badge.addEventListener("mousedown", (event) => event.stopPropagation())
      badge.addEventListener("click", (event) => {
        event.preventDefault()
        event.stopPropagation()
        this.visitLocalPath(path, event)
      })
    } else {
      badge.classList.add("pointer-events-none")
    }

    const marker = L.marker([ lat, lng ], {
      interactive: false,
      keyboard: false,
      zIndexOffset: 50,
      icon: L.divIcon({
        className: "route-polygon-label-icon",
        html: badge,
        iconSize: [ 0, 0 ],
        iconAnchor: [ 0, 0 ]
      })
    }).addTo(this.layerGroup)

    this.polygonLabels.push({
      marker,
      text,
      anchor: L.latLng(lat, lng)
    })
  }

  // Prefer the interior point farthest from the boundary so a concave route
  // does not leave its name on a neighbor.
  polygonLabelPoint(points) {
    const candidates = []
    const centroid = this.areaCentroid(points)
    if (centroid && this.pointInRing(centroid, points)) candidates.push(centroid)

    let minLat = Infinity
    let maxLat = -Infinity
    let minLng = Infinity
    let maxLng = -Infinity
    points.forEach(([ lat, lng ]) => {
      minLat = Math.min(minLat, lat)
      maxLat = Math.max(maxLat, lat)
      minLng = Math.min(minLng, lng)
      maxLng = Math.max(maxLng, lng)
    })

    const steps = 12
    for (let row = 0; row <= steps; row++) {
      for (let col = 0; col <= steps; col++) {
        const point = [
          minLat + ((maxLat - minLat) * row) / steps,
          minLng + ((maxLng - minLng) * col) / steps
        ]
        if (this.pointInRing(point, points)) candidates.push(point)
      }
    }

    if (candidates.length === 0) {
      const lat = points.reduce((sum, point) => sum + point[0], 0) / points.length
      const lng = points.reduce((sum, point) => sum + point[1], 0) / points.length
      return [ lat, lng ]
    }

    return candidates.reduce((best, point) => (
      this.ringClearance(point, points) > this.ringClearance(best, points) ? point : best
    ))
  }

  areaCentroid(points) {
    let area = 0
    let cx = 0
    let cy = 0
    points.forEach((point, index) => {
      const next = points[(index + 1) % points.length]
      const cross = (point[1] * next[0]) - (next[1] * point[0])
      area += cross
      cx += (point[1] + next[1]) * cross
      cy += (point[0] + next[0]) * cross
    })
    area *= 0.5
    if (Math.abs(area) < 1e-14) return null

    return [ cy / (6 * area), cx / (6 * area) ]
  }

  pointInRing(point, ring) {
    const x = point[1]
    const y = point[0]
    let inside = false
    for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      const yi = ring[i][0]
      const xi = ring[i][1]
      const yj = ring[j][0]
      const xj = ring[j][1]
      const crosses = (yi > y) !== (yj > y)
      if (crosses && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) inside = !inside
    }
    return inside
  }

  ringClearance(point, ring) {
    let min = Infinity
    ring.forEach((start, index) => {
      min = Math.min(min, this.distanceToSegment(point, start, ring[(index + 1) % ring.length]))
    })
    return min
  }

  distanceToSegment(point, start, end) {
    const scale = Math.cos(point[0] * Math.PI / 180)
    const ax = start[1] * scale
    const ay = start[0]
    const bx = end[1] * scale
    const by = end[0]
    const px = point[1] * scale
    const py = point[0]
    const dx = bx - ax
    const dy = by - ay
    const lengthSquared = (dx * dx) + (dy * dy)
    const ratio = lengthSquared === 0 ? 0 : Math.max(0, Math.min(1, ((px - ax) * dx + (py - ay) * dy) / lengthSquared))
    return Math.hypot(px - (ax + (ratio * dx)), py - (ay + (ratio * dy)))
  }

  // Shift overlapping names apart in screen space, then convert back to
  // coordinates. Each pass starts from the polygon anchor so a resize does
  // not keep pushing labels farther away.
  separatePolygonLabels() {
    if (!this.map || !this.polygonLabels || this.polygonLabels.length < 2) return

    const size = this.map.getSize()
    const boxes = this.polygonLabels.map((entry) => {
      entry.marker.setLatLng(entry.anchor)
      const badge = entry.marker.getElement()?.querySelector(".route-polygon-label")
      const width = badge?.offsetWidth || Math.ceil(entry.text.length * 7.2) + 16
      const height = badge?.offsetHeight || 18
      const projected = this.map.latLngToContainerPoint(entry.anchor)
      return {
        entry,
        width,
        height,
        x: projected.x - (width / 2),
        y: projected.y - (height / 2)
      }
    })

    for (let pass = 0; pass < 24; pass++) {
      let moved = false
      for (let i = 0; i < boxes.length; i++) {
        for (let j = i + 1; j < boxes.length; j++) {
          const a = boxes[i]
          const b = boxes[j]
          const overlapX = Math.min(a.x + a.width, b.x + b.width) - Math.max(a.x, b.x)
          const overlapY = Math.min(a.y + a.height, b.y + b.height) - Math.max(a.y, b.y)
          if (overlapX <= 2 || overlapY <= 2) continue

          const gap = 6
          if (overlapY <= overlapX) {
            const push = (overlapY + gap) / 2
            const direction = (a.y + (a.height / 2)) <= (b.y + (b.height / 2)) ? -1 : 1
            a.y += direction * push
            b.y -= direction * push
          } else {
            const push = (overlapX + gap) / 2
            const direction = (a.x + (a.width / 2)) <= (b.x + (b.width / 2)) ? -1 : 1
            a.x += direction * push
            b.x -= direction * push
          }
          moved = true
        }
      }
      if (!moved) break
    }

    boxes.forEach((box) => {
      const pad = 4
      const x = Math.min(Math.max(box.x, pad), Math.max(pad, size.x - box.width - pad))
      const y = Math.min(Math.max(box.y, pad), Math.max(pad, size.y - box.height - pad))
      box.entry.marker.setLatLng(this.map.containerPointToLatLng([ x + (box.width / 2), y + (box.height / 2) ]))
    })
  }

  // A polygon vertex on this route or a nearby route. Every corner uses the
  // same circle. Clicking it opens the shared coordinate popup.
  polygonPointLayer(marker, lat, lng) {
    const layer = L.circleMarker([ lat, lng ], {
      radius: 6,
      color: "#4b5563",
      weight: 2,
      fillColor: "#f9fafb",
      fillOpacity: 1,
      className: "route-polygon-point"
    })
    layer.on("add", () => {
      const element = layer.getElement()
      if (!element || marker.id === undefined || marker.id === null) return

      element.setAttribute("data-point-id", String(marker.id))
    })

    this.bindRoutePointPopup(layer, marker, lat, lng)

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
