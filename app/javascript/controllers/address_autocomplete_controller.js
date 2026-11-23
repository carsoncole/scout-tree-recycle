import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "results" ]
  static values = {
    url: String,
    minLength: { type: Number, default: 3 }
  }

  connect() {
    this.suggestions = []
    this.activeIndex = -1
    this.timeout = null
    this.abortController = null
  }

  disconnect() {
    this.clearTimer()
    this.abortController?.abort()
  }

  search() {
    this.clearTimer()
    this.close()

    const query = this.inputTarget.value.trim()
    if (query.length < this.minLengthValue) return

    this.timeout = window.setTimeout(() => this.fetchSuggestions(query), 250)
  }

  async fetchSuggestions(query) {
    if (!this.urlValue) return

    this.abortController?.abort()
    this.abortController = new AbortController()

    try {
      const response = await fetch(`${this.urlValue}?query=${encodeURIComponent(query)}`, {
        headers: { Accept: "application/json" },
        signal: this.abortController.signal
      })

      if (response.status === 204 || !response.ok) return

      const data = await response.json()
      this.render(Array.isArray(data.suggestions) ? data.suggestions : [])
    } catch (error) {
      if (error.name !== "AbortError") this.close()
    }
  }

  render(suggestions) {
    this.suggestions = suggestions
    this.activeIndex = -1
    this.resultsTarget.replaceChildren()

    if (suggestions.length === 0) {
      this.close()
      return
    }

    suggestions.forEach((suggestion, index) => {
      const item = document.createElement("li")
      item.id = `street-suggestion-${index}`
      item.setAttribute("role", "option")
      item.setAttribute("aria-selected", "false")
      item.className = "cursor-pointer px-4 py-3 text-sm text-ink hover:bg-sage-soft dark:text-ink-dark dark:hover:bg-sage-soft-dark"
      item.textContent = suggestion.label
      item.addEventListener("mousedown", (event) => {
        event.preventDefault()
        this.select(index)
      })
      this.resultsTarget.appendChild(item)
    })

    this.resultsTarget.hidden = false
    this.inputTarget.setAttribute("aria-expanded", "true")
  }

  keydown(event) {
    if (this.resultsTarget.hidden) return

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.move(1)
        break
      case "ArrowUp":
        event.preventDefault()
        this.move(-1)
        break
      case "Enter":
        if (this.activeIndex >= 0) {
          event.preventDefault()
          this.select(this.activeIndex)
        }
        break
      case "Escape":
        event.preventDefault()
        this.close()
        this.inputTarget.focus()
        break
    }
  }

  blur() {
    window.setTimeout(() => this.close(), 150)
  }

  move(direction) {
    if (this.suggestions.length === 0) return

    const nextIndex = this.activeIndex + direction
    this.activeIndex = nextIndex < 0 ? this.suggestions.length - 1 : nextIndex % this.suggestions.length
    this.highlightActive()
  }

  highlightActive() {
    Array.from(this.resultsTarget.children).forEach((item, index) => {
      const active = index === this.activeIndex
      item.classList.toggle("bg-sage-soft", active)
      item.classList.toggle("dark:bg-sage-soft-dark", active)
      item.setAttribute("aria-selected", active.toString())
    })

    if (this.activeIndex >= 0) {
      this.inputTarget.setAttribute("aria-activedescendant", `street-suggestion-${this.activeIndex}`)
      this.resultsTarget.children[this.activeIndex]?.scrollIntoView({ block: "nearest" })
    } else {
      this.inputTarget.removeAttribute("aria-activedescendant")
    }
  }

  select(index) {
    const suggestion = this.suggestions[index]
    if (!suggestion) return

    this.inputTarget.value = suggestion.street || suggestion.label
    this.close()
    this.inputTarget.focus()
  }

  close() {
    this.resultsTarget.hidden = true
    this.resultsTarget.replaceChildren()
    this.inputTarget.setAttribute("aria-expanded", "false")
    this.inputTarget.removeAttribute("aria-activedescendant")
    this.suggestions = []
    this.activeIndex = -1
  }

  clearTimer() {
    if (this.timeout) {
      window.clearTimeout(this.timeout)
      this.timeout = null
    }
  }
}
