export const CODE_INVALID = "code-invaid";

class Observer {
  constructor() {
    this.observers = {};
  }

  subscribe(type, fn) {
    if (!this.observers[type]) {
      this.observers[type] = [];
    }
    this.observers[type].push(fn);
  }

  unsubscribe(type, fn) {
    const observers = this.observers[type];
    if (!observers) return;
    const index = observers.indexOf(fn);
    if (index !== -1) {
      observers.splice(index, 1);
    }
  }

  send(type, data) {
    const observers = this.observers[type];
    if (!observers) return;
    observers.forEach((fn) => {
      fn(data);
    });
  }
}

export default new Observer();
