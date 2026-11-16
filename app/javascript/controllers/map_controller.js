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
    this.settled = false
    this.mapBounds = null

    const hasCenter = Array.isArray(this.centerValue) && this.centerValue.length === 2 && this.validCoord(this.centerValue[0], this.centerValue[1])
    const initialCenter = hasCenter ? [Number(this.centerValue[0]), Number(this.centerValue[1])] : [47.6062, -122.3321]

    this.map = L.map(this.element, { scrollWheelZoom: false, worldCopyJump: true }).setView(initialCenter, this.zoomValue)
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
    setTimeout(() => {
      this.resizeMap(true)
      this.settled = true
    }, 750)
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
    }
    if (this.element) this.element.__mapController = null
  }

  resizeMap(refit = false) {
    if (!this.map) return

    const rect = this.element.getBoundingClientRect()
    if (rect.width === 0 || rect.height === 0) return

    this.map.invalidateSize({ animate: false, pan: false })

    if (refit && !this.settled && this.mapBounds && this.mapBounds.isValid()) {
      this.map.fitBounds(this.mapBounds, { padding: [20, 20], maxZoom: 17 })
    }
  }

  markersValueChanged() {
    if (this.map && this.layerGroup) {
      this.layerGroup.clearLayers()
      this.markerLayers = new Map()
      this.renderLayers()
    }
  }

  renderLayers() {
    if (!this.layerGroup) return
    const bounds = []

    this.polygonsValue.forEach((polygon) => {
      const points = this.normalizePolygon(polygon)
      if (points.length > 3) {
        const layer = L.polygon(points, {
          color: "#2563eb",
          weight: 2,
          fillColor: "#3b82f6",
          fillOpacity: 0.2
        })
        if (polygon && polygon.label) layer.bindPopup(String(polygon.label))
        layer.addTo(this.layerGroup)
        bounds.push(layer.getBounds())
      }
    })

    this.markersValue.forEach((marker) => {
      const lat = Number(marker.lat ?? marker.latitude)
      const lng = Number(marker.lng ?? marker.longitude)
      if (!this.validCoord(lat, lng)) return

      const stroke = marker.color || "#b91c1c"
      const fill = marker.fillColor || marker.color || "#ef4444"
      const layer = L.circleMarker([lat, lng], {
        radius: 7,
        color: stroke,
        weight: 2,
        fillColor: fill,
        fillOpacity: 0.9
      })

      if (this.interactiveValue) {
        layer.on("click", () => {
          this.dispatch("marker-selected", { detail: { marker } })
        })
      } else {
        const popup = marker.popup || marker.label || marker.name
        if (popup) layer.bindPopup(String(popup))
      }

      layer.addTo(this.layerGroup)
      if (marker.id !== undefined && marker.id !== null) {
        this.markerLayers.set(String(marker.id), layer)
      }
      bounds.push(L.latLngBounds([[lat, lng], [lat, lng]]))
    })

    if (bounds.length > 0) {
      const combined = bounds.reduce((acc, b) => (acc ? acc.extend(b) : b), null)
      if (combined && combined.isValid()) {
        this.mapBounds = combined
        this.map.fitBounds(combined, { padding: [20, 20], maxZoom: 17 })
      }
    }
  }

  updateMarker(event) {
    const detail = event.detail || {}
    const id = detail.id
    if (!id || !this.markerLayers) return
    const key = String(id)
    const color = detail.color || "#2563eb"
    const layer = this.markerLayers.get(key)
    if (layer) layer.setStyle({ color: color, fillColor: color })

    const marker = this.markersValue.find((m) => String(m.id) === key)
    if (marker) {
      marker.color = color
      if (detail.status) marker.status = detail.status
    }
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
}
