const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const test = require('node:test');

const source = fs.readFileSync(
  path.join(__dirname, '..', 'src/components/order/myOrder/newDrawerMyOrder.vue'),
  'utf8',
);

test('refund quantity click opens Android keyboard and drawer cleanup hides it', () => {
  assert.match(source, /ref="refundQuantityInput"/);
  assert.match(source, /@click="showRefundQuantityKeyboard"/);
  assert.match(source, /@blur="hideRefundQuantityKeyboard"/);
  assert.match(source, /atool\.showSoftInput\(\)/);
  assert.match(source, /atool\.executeJs\(`this\.\$refs\.refundQuantityInput\.focus\(\)`\)/);
  assert.match(source, /atool\.hideSoftInput\(\)/);
  assert.doesNotMatch(
    source,
    /this\.formData\.reason = "";\s*this\.\$nextTick\(\(\) => this\.showRefundQuantityKeyboard\(\)\);/,
  );
});
