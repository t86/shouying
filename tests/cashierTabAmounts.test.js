const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const sandbox = { module: { exports: {} } };
vm.runInNewContext(fs.readFileSync('src/utils/cashierTabAmounts.js', 'utf8').replace('export const summarizeCashierRows', 'const summarizeCashierRows') + '\nmodule.exports = summarizeCashierRows;', sandbox);
const summarize = rows => JSON.parse(JSON.stringify(sandbox.module.exports(rows)));
const amounts = (allAmt, giveAmt, discountAmt, notPayAmt) => ({ allAmt, giveAmt, discountAmt, notPayAmt });

test('empty tabs have zero amounts', () => {
  assert.deepEqual(summarize([]), amounts('0.00', '0.00', '0.00', '0.00'));
});
test('recorded prices exclude expanded refund rows', () => {
  assert.deepEqual(summarize([
    { pp: 900, p2: 800, pa: 800, pc: 1 },
    { pp: 800, pa: 700, pc: 1, back: true }
  ]), amounts('900.00', '0.00', '100.00', '800.00'));
});
test('net quantities ignore refund and set details and checkout selections', () => {
  assert.deepEqual(summarize([{ pp: 900, p2: 800, pa: 1600, pc: 2, changeCount: 1, checked: false,
    bs: [{ pp: 900, pa: 800, pc: 1 }], si: [{ pp: 100, pa: 100, pc: 1 }] }]),
  amounts('1800.00', '0.00', '200.00', '1600.00'));
});
test('recorded row amount takes precedence over unit amounts', () => {
  assert.deepEqual(summarize([{ pp: 100, p2: 90, pa: 170, pc: 2 }]), amounts('200.00', '0.00', '30.00', '170.00'));
});
test('zero actual price and time price are retained', () => {
  assert.deepEqual(summarize([{ pp: 100, p2: 0, pc: 1 }, { pp: 0, pa: 75, pc: 2 }]),
    amounts('175.00', '0.00', '100.00', '75.00'));
});
test('decimal sums round in cents and missing actual price falls back to original', () => {
  assert.deepEqual(summarize([{ pp: '0.10', pc: 3 }, { pp: '0.20', p2: '0.10', pc: 1 }]),
    amounts('0.50', '0.00', '0.10', '0.40'));
});
test('gifts counted separately and invalid quantities skipped', () => {
  assert.deepEqual(summarize([{ pp: 100, pa: 0, pc: 2, at: 2 }, { pp: 0, pa: 30, pc: 1, at: 3 },
    { pp: 100, pc: 0 }, { pp: 100, pc: -1 }, { pp: 100 }, null]),
    amounts('0.00', '230.00', '0.00', '0.00'));
});
test('online wrappers counted once with expanded rows preferred', () => {
  const item = { pp: 900, pa: 800, pc: 1 };
  assert.deepEqual(summarize([{ oid: '1', resultNotPayData: [item], os: [item] },
    { oid: '2', os: [item] }, { oid: '3', resultNotPayData: [], os: [item] }]),
    amounts('1800.00', '0.00', '200.00', '1600.00'));
});
