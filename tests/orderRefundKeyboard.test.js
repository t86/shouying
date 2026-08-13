const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const test = require('node:test');

const source = fs.readFileSync(
  path.join(__dirname, '..', 'src/components/order/myOrder/newDrawerMyOrder.vue'),
  'utf8',
);

test('refund drawer opens Android keyboard for an editable quantity and cleanup hides it', () => {
  assert.match(source, /ref="refundQuantityInput"/);
  assert.match(source, /@focus="showRefundQuantityKeyboard"/);
  assert.match(source, /@blur="hideRefundQuantityKeyboard"/);
  assert.match(source, /atool\.showSoftInput\(\)/);
  assert.match(source, /atool\.hideSoftInput\(\)/);
  assert.match(source, /this\.showRefundQuantityKeyboard\(\)/);
});
