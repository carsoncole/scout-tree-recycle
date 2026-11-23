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
  }

  markersValueChanged() {
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
      const select = () => this.dispatch("marker-selected", { detail: { marker } })
      const statusLayers = []

      if (selectable) {
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
        hit.on("click", select)
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
