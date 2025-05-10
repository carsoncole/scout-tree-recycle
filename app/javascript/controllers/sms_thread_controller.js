import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]
  static values = {
    phone: String
  }

  toggle() {
    this.contentTarget.classList.toggle("hidden")
    
    // If we're expanding the thread (not hiding it)
    if (!this.contentTarget.classList.contains("hidden")) {
      // Mark messages as viewed
      this.markAsViewed()
      
      // Wait for the content to be visible
      setTimeout(() => {
        // Find the reply box in the thread
        const replyBox = this.contentTarget.querySelector(".border-t")
        if (replyBox) {
          // Scroll the reply box into view with a smooth animation
          replyBox.scrollIntoView({ behavior: "smooth", block: "center" })
        }
      }, 100) // Small delay to ensure content is rendered
    }
  }

  markAsViewed() {
    fetch(`/admin/sms/mark_viewed?phone=${encodeURIComponent(this.phoneValue)}`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      }
    }).then(() => {
      // Remove the unviewed count badge
      const badge = this.element.querySelector('.inline-flex.items-center.px-2\\.5.py-0\\.5.rounded-full')
      if (badge) {
        badge.remove()
      }
    })
  }

  stopPropagation(event) {
    event.stopPropagation()
  }
} 