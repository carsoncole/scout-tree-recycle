import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["file", "mapping", "error", "matchStatus"]
  static values = { fields: Array }

  connect() {
    this.renderEmpty()
  }

  load() {
    const file = this.fileTarget.files[0]
    if (!file) {
      this.renderEmpty()
      return
    }

    this.errorTarget.hidden = true
    this.errorTarget.textContent = ""
    if (this.hasMatchStatusTarget) {
      this.matchStatusTarget.textContent = "Matching fields found: none yet."
    }

    file.text().then((text) => {
      const headers = this.parseHeader(text)
      if (headers.length === 0 || headers.every((h) => h === "")) {
        this.renderError("The selected file does not contain a readable header row.")
        this.mappingTarget.innerHTML = ""
        if (this.hasMatchStatusTarget) {
          this.matchStatusTarget.textContent = "Matching fields found: none yet."
        }
        return
      }
      this.renderMapping(headers)
    }).catch(() => {
      this.renderError("Could not read the selected file.")
      this.mappingTarget.innerHTML = ""
      if (this.hasMatchStatusTarget) {
        this.matchStatusTarget.textContent = "Matching fields found: none yet."
      }
    })
  }

  parseHeader(text) {
    const firstLine = (text || "").split(/\r?\n/)[0] || ""
    const cells = []
    let value = ""
    let inQuotes = false
    for (let i = 0; i < firstLine.length; i++) {
      const char = firstLine[i]
      if (inQuotes) {
        if (char === '"' && firstLine[i + 1] === '"') {
          value += '"'
          i++
        } else if (char === '"') {
          inQuotes = false
        } else {
          value += char
        }
      } else if (char === '"') {
        inQuotes = true
      } else if (char === ",") {
        cells.push(value)
        value = ""
      } else {
        value += char
      }
    }
    cells.push(value)
    return cells.map((cell) => cell.trim())
  }

  normalize(text) {
    return String(text || "").toLowerCase().replace(/[^a-z0-9]+/g, " ").trim()
  }

  autoSelect(header) {
    const normalizedHeader = this.normalize(header)
    if (!normalizedHeader) return ""

    const used = new Set(
      Array.from(this.mappingTarget.querySelectorAll("select")).map((s) => s.value).filter(Boolean)
    )

    const candidates = this.fieldsValue.filter((field) => !used.has(field.value))

    // Exact alias match first.
    for (const field of candidates) {
      const aliases = [field.value, field.label, ...(field.aliases || [])].map((a) => this.normalize(a))
      if (aliases.includes(normalizedHeader)) return field.value
    }

    // Then partial containment for longer aliases.
    for (const field of candidates) {
      const aliases = [field.value, field.label, ...(field.aliases || [])].map((a) => this.normalize(a)).filter((a) => a.length > 2)
      if (aliases.some((aliasText) => normalizedHeader.includes(aliasText))) return field.value
    }

    return ""
  }

  renderMapping(headers) {
    this.mappingTarget.innerHTML = ""
    headers.forEach((header, index) => {
      const field = document.createElement("div")
      field.className = "admin-field"

      const label = document.createElement("label")
      label.className = "admin-label"
      label.htmlFor = `mapping_${index}`
      label.textContent = `CSV column: ${header}`
      field.appendChild(label)

      const select = document.createElement("select")
      select.id = `mapping_${index}`
      select.name = "mapping[]"
      select.className = "admin-select"

      const skipOption = document.createElement("option")
      skipOption.value = ""
      skipOption.textContent = "Skip this column"
      select.appendChild(skipOption)

      this.fieldsValue.forEach((item) => {
        const option = document.createElement("option")
        option.value = item.value
        option.textContent = item.label
        select.appendChild(option)
      })

      select.value = this.autoSelect(header)
      select.addEventListener("change", () => this.updateMatchStatus())
      field.appendChild(select)
      this.mappingTarget.appendChild(field)
    })
    this.updateMatchStatus()
  }

  updateMatchStatus() {
    if (!this.hasMatchStatusTarget) return
    const selected = Array.from(this.mappingTarget.querySelectorAll("select"))
      .map((select) => select.value)
      .filter(Boolean)
    const found = this.fieldsValue
      .filter((field) => selected.includes(field.value))
      .map((field) => field.label)
    this.matchStatusTarget.textContent = found.length
      ? `Matching fields found: ${found.join(", ")}.`
      : "Matching fields found: none yet."
  }

  renderEmpty() {
    this.mappingTarget.innerHTML = ""
  }

  renderError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.hidden = false
  }
}