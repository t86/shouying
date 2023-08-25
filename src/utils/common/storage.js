export const sessionStorage = {
  setItem: (key, value) => {
    // try {
    //   atool.setVal(key, value)
    // } catch (error) {
      try {
        window.sessionStorage.setItem(key, value)
      } catch (error) {
        console.log('sessionStorage.setItem error', error);
      }
    // }
  },

  getItem: key => {
    // try {
    //   return atool.getVal(key)
    // } catch (error) {
      return window.sessionStorage.getItem(key)
    // }
  },

  removeItem: key => {
    // try {
    //   return atool.setVal(key, undefined)
    // } catch (error) {
      return window.sessionStorage.removeItem(key)
    // }
  },

  clear: () => {
    // try {
    //   return atool.clearCache()
    // } catch (error) {
      return window.sessionStorage.clear()
    // }
  }
}


export const localStorage = {
  setItem: (key, value) => {
    // try {
    //   atool.setVal(key, value)
    // } catch (error) {
      try {
        window.localStorage.setItem(key, value)
      } catch (error) {
        console.log('localStorage.setItem error', error);
      }
    // }
  },

  getItem: key => {
    // try {
    //   return atool.getVal(key)
    // } catch (error) {
      return window.localStorage.getItem(key)
    // }
  },

  removeItem: key => {
    // try {
    //   return atool.setVal(key, undefined)
    // } catch (error) {
      return window.localStorage.removeItem(key)
    // }
  },

  clear: () => {
    // try {
    //   return atool.clearCache()
    // } catch (error) {
      return window.localStorage.clear()
    // }
  }
}