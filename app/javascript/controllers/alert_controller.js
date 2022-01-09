import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = {
    dismissAfter: Number,
    showDelay: Number,
    removeDelay: Number

  }
  static classes = ["show", "hide"]

  initialize() {
    this.hide()
  }

  connect() {
    setTimeout(() => {
      this.show()
    }, this.showAfter)

    // Auto dimiss if defined
    if (this.hasDismissAfterValue) {
      setTimeout(() => {
        this.close()
      }, this.dismissAfterValue)
    }
  }

  close() {
    this.hide()

    setTimeout(() => {
      this.element.remove()
    }, this.removeAfter)
  }

  show() {
    this.element.classList.add(...this.showClasses)
    this.element.classList.remove(...this.hideClasses)
  }

  hide() {
    this.element.classList.add(...this.hideClasses)
    this.element.classList.remove(...this.showClasses)
  }

  get removeAfter() {
    if (this.hasRemoveDelayValue) {
      return this.removeDelayValue
    } else {
      return 300
    }
  }

  get showAfter() {
    if (this.hasShowDelayValue) {
      return this.showDelayValue
    } else {
      return 200
    }
  }
}
