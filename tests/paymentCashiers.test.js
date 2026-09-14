const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

const source = fs.readFileSync(path.join(__dirname, '../src/utils/paymentCashiers.js'), 'utf8');
const sandbox = { Set, String };
vm.runInNewContext(source.replace(/export /g, ''), sandbox);
const { loadPaymentCashiers, formatPaymentCashier } = sandbox;
const pageSource = fs.readFileSync(path.join(__dirname, '../src/views/Money/payOrder.vue'), 'utf8');
const updateSource = pageSource.match(/    updatePaymentCashiers\(paymentIds, params, cashierRequestId\) \{([\s\S]*?)\n    \},/)[1];
const update = new Function('loadPaymentCashiers', 'api_money', `return function(paymentIds, params, cashierRequestId) {${updateSource}}`);
const tick = () => new Promise(resolve => setImmediate(resolve));

test('reads later pages and matches exact payment ids regardless of seat name', async () => {
  const calls = [];
  const names = await loadPaymentCashiers(async params => {
    calls.push(params);
    return { code: 1, data: { page_cnt: 3, records: params.page_num === 1
      ? [{ id: 91, pe: '其他人' }, { id: '12', pe: '张三' }]
      : [{ id: 13, pe: '李四', n: '转台前卡台' }] } };
  }, '', [12, 13], () => true);
  assert.equal(JSON.stringify(names), JSON.stringify({ 12: '张三', 13: '李四' }));
  assert.deepEqual(calls.map(call => call.page_num), [1, 2]);
  assert.ok(calls.every(call => call.key === ''));
});

test('discards stale lookup responses and stops further pagination', async () => {
  let current = true;
  let resolve;
  const lookup = loadPaymentCashiers(() => new Promise(done => { resolve = done; }), '', [1], () => current);
  current = false;
  resolve({ code: 1, data: { page_cnt: 5, records: [{ id: 1, pe: '旧卡台' }] } });
  assert.equal(JSON.stringify(await lookup), '{}');
});

test('honors total rows with the returned page size when page count is absent', async () => {
  const calls = [];
  const names = await loadPaymentCashiers(async params => {
    calls.push(params.page_num);
    return { code: 1, data: { row_cnt: 2, page_size: 1, records: [{ id: params.page_num, pe: '员工' }] } };
  }, '', [2], () => true);
  assert.deepEqual(calls, [1, 2]);
  assert.equal(names[2], '员工');
});

test('reports API failures without returning partial cashier matches', async () => {
  await assert.rejects(loadPaymentCashiers(async () => ({ code: 0, msg: '失败' }), '', [1], () => true), /失败/);
});

test('formats actual names before the explicit online fallback', () => {
  assert.equal(formatPaymentCashier(' 张三 ', true), '张三');
  assert.equal(formatPaymentCashier('', true), '自助收银');
  assert.equal(formatPaymentCashier(undefined, false), '--');
});

function context() {
  return {
    cashierLookupKey: '', cashierLookupPromise: null, cashierLookupVersion: 0,
    cashierRequestId: 1, paymentCashiers: {},
    $store: { state: { orderInfo: { currentCardInfo: { seatId: 1 } } } },
    turnOverInfo: { activeTurnOverCount: 0 },
  };
}

test('reuses successful and pending lookups and isolates seat/turnover changes', async () => {
  const pending = [];
  const method = update((...args) => new Promise(resolve => pending.push({ resolve, args })), {});
  const ctx = context();
  method.call(ctx, [11], { seat_id: 1, turnover_cnt: 0 }, 1);
  ctx.cashierRequestId = 2;
  method.call(ctx, [11], { seat_id: 1, turnover_cnt: 0 }, 2);
  assert.equal(pending.length, 1);
  pending[0].resolve({ 11: '张三' });
  await tick();
  assert.equal(ctx.paymentCashiers[11], '张三');
  method.call(ctx, [11], { seat_id: 1, turnover_cnt: 0 }, 2);
  assert.equal(pending.length, 1);
  ctx.cashierRequestId = 3;
  ctx.turnOverInfo.activeTurnOverCount = 1;
  method.call(ctx, [12], { seat_id: 1, turnover_cnt: 1 }, 3);
  ctx.cashierRequestId = 4;
  ctx.$store.state.orderInfo.currentCardInfo.seatId = 2;
  method.call(ctx, [21], { seat_id: 2, turnover_cnt: 1 }, 4);
  pending[2].resolve({ 21: '新卡台' });
  await tick();
  pending[1].resolve({ 12: '旧翻台' });
  await tick();
  assert.deepEqual(ctx.paymentCashiers, { 21: '新卡台' });
});

test('failure does not affect orders and a later refresh retries', async () => {
  const ctx = context();
  const orders = [{ pid: 1 }];
  ctx.cardAllOrderInfo = orders;
  let calls = 0;
  const method = update(async () => { calls++; throw new Error('network'); }, {});
  method.call(ctx, [1], { seat_id: 1, turnover_cnt: 0 }, 1);
  await tick();
  assert.equal(ctx.cardAllOrderInfo, orders);
  assert.deepEqual(ctx.paymentCashiers, {});
  assert.equal(ctx.cashierLookupPromise, null);
  method.call(ctx, [1], { seat_id: 1, turnover_cnt: 0 }, 1);
  await tick();
  assert.equal(calls, 2);
});
