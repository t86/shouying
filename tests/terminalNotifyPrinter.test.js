const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const source = fs.readFileSync(
  path.join(__dirname, '../src/views/ManagementSystem/BMS/terminalBms/terminalBms.vue'),
  'utf8',
);

test('configures and displays the warehouse wine notification printer', () => {
  assert.match(source, /存取酒通知小票打印机/);
  assert.match(source, /v-model="wineNotifyPrintVal"/);
  assert.match(source, /v-for="item in printOption"/);
  assert.match(source, /item\.npn/);
  assert.match(source, /wineNotifyPrintVal:\s*["']0["']/);
  assert.match(source, /this\.wineNotifyPrintVal = \(itemInfo\.npi \|\| 0\)\.toString\(\)/);
  assert.match(source, /wine_notify_prt_id:\s*this\.wineNotifyPrintVal \* 1/);
});
