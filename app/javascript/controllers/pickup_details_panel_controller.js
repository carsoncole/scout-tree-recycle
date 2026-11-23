import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { reservationId: String, status: String, color: String }

  connect() {
    if (this.hasReservationIdValue && this.hasColorValue) {
      window.dispatchEvent(new CustomEvent("pickups:marker-update", {
        detail: { id: this.reservationIdValue, color: this.colorValue, status: this.statusValue }
      }))
    }
  }
}
