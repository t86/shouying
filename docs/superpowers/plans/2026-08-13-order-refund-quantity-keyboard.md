# 点单端退单数量系统键盘 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 Android 平板点单端退单数量框支持系统数字键盘输入，并在退出退单流程时恢复键盘关闭。

**Architecture:** 在 `newDrawerMyOrder.vue` 为退单数量输入框增加引用和焦点/失焦事件。退单弹窗打开后，组件在渲染完成时为可编辑的数量框显示 Android 系统键盘并聚焦；在弹窗状态变化和取消处理里调用隐藏方法，保持原有数量校验逻辑不变。

**Tech Stack:** Vue 2、Element UI、Android `window.atool` 原生桥、Node.js 内建测试运行器。

---

### Task 1: 锁定退单键盘生命周期的回归约束

**Files:**
- Create: `tests/orderRefundKeyboard.test.js`
- Test: `tests/orderRefundKeyboard.test.js`

- [ ] **Step 1: Write the failing test**

```js
test('refund drawer opens Android keyboard for an editable quantity and cleanup hides it', () => {
  const source = readSource('src/components/order/myOrder/newDrawerMyOrder.vue');
  assert.match(source, /ref="refundQuantityInput"/);
  assert.match(source, /@focus="showRefundQuantityKeyboard"/);
  assert.match(source, /@blur="hideRefundQuantityKeyboard"/);
  assert.match(source, /atool\.showSoftInput\(\)/);
  assert.match(source, /atool\.hideSoftInput\(\)/);
  assert.match(source, /this\.showRefundQuantityKeyboard\(\)/);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node --test tests/orderRefundKeyboard.test.js`

Expected: FAIL because the refund quantity input lacks the ref, events, and keyboard methods.

- [ ] **Step 3: Write minimal implementation**

```js
showRefundQuantityKeyboard() {
  if (window.atool && window.atool.getTermType() === 'android' && ('showSoftInput' in window.atool)) {
    atool.showSoftInput();
    this.$nextTick(() => this.$refs.refundQuantityInput.focus());
  }
},
hideRefundQuantityKeyboard() {
  if (window.atool && window.atool.getTermType() === 'android' && ('hideSoftInput' in window.atool)) {
    atool.hideSoftInput();
  }
},
```

Attach these methods to the editable `status === 1` quantity input. When the refund drawer opens, call the show method after Vue renders; call the hide method when the drawer switches to authorization or closes.

- [ ] **Step 4: Run focused test to verify it passes**

Run: `node --test tests/orderRefundKeyboard.test.js`

Expected: PASS.

### Task 2: Verify the full existing test suite and build

**Files:**
- Modify: `src/components/order/myOrder/newDrawerMyOrder.vue`
- Create: `tests/orderRefundKeyboard.test.js`

- [ ] **Step 1: Run all tests**

Run: `node --test tests/*.test.js`

Expected: PASS with no failed tests.

- [ ] **Step 2: Run production build**

Run: `npm run build`

Expected: command exits 0.

- [ ] **Step 3: Manually verify on Android tablet**

Use card A03, open a refundable item, focus the quantity field, enter a valid number, confirm the amount changes, then cancel and confirm the keyboard is hidden.
