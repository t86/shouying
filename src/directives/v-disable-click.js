export default {
  bind(el, binding, vnode) {
    const originalHandler = binding.value;

    if (typeof originalHandler !== 'function') {
      console.warn('v-disable-click only works with function handlers');
      return;
    }

    el.__originalClickHandler__ = async function(event) {
      console.log('v-disable-click ', event);
      if (el.disabled) {
        event && event.stopImmediatePropagation();
        return;
      }

      el.disabled = true;
      try {
        await originalHandler.apply(this, arguments);
      } finally {
        el.disabled = false;
      }
    };

    el.addEventListener('click', el.__originalClickHandler__);
  },
  unbind(el) {
    el.removeEventListener('click', el.__originalClickHandler__);
    delete el.__originalClickHandler__;
  }
};
