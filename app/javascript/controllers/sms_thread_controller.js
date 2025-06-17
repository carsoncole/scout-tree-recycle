import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]
  static values = {
    phone: String
  }

  connect() {
    // Auto-scroll to bottom if the thread is expanded (show page)
    if (this.contentTarget && !this.contentTarget.classList.contains("hidden")) {
      this.scrollToBottom()
    }
    // Listen for Turbo Frame updates
    this.element.addEventListener("turbo:frame-render", this.handleFrameRender)
  }

  disconnect() {
    this.element.removeEventListener("turbo:frame-render", this.handleFrameRender)
  }

  handleFrameRender = () => {
    if (this.contentTarget && !this.contentTarget.classList.contains("hidden")) {
      this.scrollToBottom()
    }
  }

  scrollToBottom() {
    // Scroll to the bottom of the thread content
    this.contentTarget.scrollTop = this.contentTarget.scrollHeight
    // Or scroll the last message into view
    const messages = this.contentTarget.querySelectorAll(".flex");
    if (messages.length > 0) {
      messages[messages.length - 1].scrollIntoView({ behavior: "smooth", block: "end" })
    }
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

  insertCannedResponse(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const message = event.currentTarget.dataset.message
    const phoneNumber = this.phoneValue.replace(/[^0-9]/g, '')
    const textarea = document.getElementById(`reply-textarea-${phoneNumber}`)
    
    if (textarea) {
      // Insert the message at the cursor position or replace existing content
      const currentValue = textarea.value
      const cursorPos = textarea.selectionStart
      
      if (currentValue.trim() === '') {
        // If textarea is empty, just insert the message
        textarea.value = message
      } else {
        // If there's existing content, add the message at the cursor position
        const beforeCursor = currentValue.substring(0, cursorPos)
        const afterCursor = currentValue.substring(cursorPos)
        textarea.value = beforeCursor + message + afterCursor
      }
      
      // Set cursor position to end of inserted message
      const newCursorPos = cursorPos + message.length
      textarea.setSelectionRange(newCursorPos, newCursorPos)
      
      // Focus the textarea
      textarea.focus()
    }
  }
} 