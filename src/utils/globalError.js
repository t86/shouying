import errApi from "@/api/reportErr";
class GlobalError {
  constructor() {
    this.init();
    this.triggerTime = +new Date();
    this.queue = [];
    this.maxSize = 30;
  }

  init() {
    // 处理 onerror
    window.onerror = (message, source, lineno, colno, error) => {
      this.handleError(error);
    };

    // 处理 unhandledrejection
    window.addEventListener("unhandledrejection", (event) => {
      this.handleError(event.reason);
    });

    setInterval(() => {
      if (this.triggerTime < +new Date() && this.queue.length > 0) {
        // 发送错误日志到服务器
        errApi.reqSendErrMsg(this.queue);
        this.triggerTime = +new Date() + 3600000;
        this.queue = [];
      }
    }, 10000);
  }

  enqueue(item) {
    // 如果队列已满,移除最早的元素
    if (this.queue.length >= this.maxSize) {
      this.queue.shift();
    }
    this.queue.push(item);
  }

  dequeue() {
    return this.queue.shift();
  }

  handleError(error) {
    // 将错误日志存储下来
    this.enqueue(error);
  }
}

export const globalError = new GlobalError();
