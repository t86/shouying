const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const Vue = require('vue');
const compiler = require('vue-template-compiler');

const root = path.join(__dirname, '..');
function source(relative) { return fs.readFileSync(path.join(root, relative), 'utf8'); }
function loadMixin(relative, dependencies = {}) {
  const code = source(relative).replace(/^import[\s\S]*?;\s*$/gm, '').replace('export default', 'return');
  return Function(...Object.keys(dependencies), code)(...Object.values(dependencies));
}
const fcCode = source('src/utils/fcPrice.js').replace(/export /g, '');
const getFcPrice = Function(fcCode + '\nreturn getFcPrice;')();
const fcPriceMixin = loadMixin('src/components/order/fcPriceMixin.js', { getFcPrice });
const cardAmountLoaderMixin = loadMixin('src/components/common/cardAmountLoaderMixin.js');
function card(overrides = {}) {
  return { seatId: 7, bizType: 1, wkCsmId: 101, turnoverCnt: 1, bizStatus: 5, orderAmt: 2377.1, payedAmt: 800, canLookOrder: true, ...overrides };
}
function rows() {
  return [
    { pid: 9, ae: 11, wei: 11, pp: '800', p2: '777', pa: '777', pc: 1, s: 1 },
    { pid: 10, pp: '0.10', p2: '0.10', pa: '0.10', pc: 1, s: 1 },
    { pid: 9, ae: 22, wei: 22, pp: '800', p2: '800', pa: '800', pc: 1, s: 1 },
    { pid: 12, pp: 0, pa: 800, pc: 1, s: 5 },
  ];
}
function response(records = rows(), orderAmount = 237710) {
  return { code: 1, data: { records, pay_info: { order_amt: orderAmount } } };
}
function deferred() {
  let resolve;
  const promise = new Promise(done => { resolve = done; });
  return { promise, resolve };
}
async function flush() { for (let i = 0; i < 8; i += 1) await Promise.resolve(); await Vue.nextTick(); }
async function settled(view) {
  for (let i = 0; i < 100; i += 1) {
    await flush();
    if (!view.cardAmountRefreshRunning) return;
  }
  assert.fail('order card amount requests did not finish');
}
function fixture(request = async () => response(), cards = [card()], options = {}) {
  const calls = [];
  const store = Vue.observable({ state: {
    userInfo: { emp_id: 11, roleIds: [2] },
    cardPageInfo: { storeStatusId: 1, resResultDataObj: {
      fcPlanEmployees: [{ emp_id: 11, plan_id: 1, status: 1 }, { emp_id: 22, plan_id: 2, status: 1 }],
      fcProductPrices: [{ prd_id: 9, plan_id: 1, pay_amt: 77700, status: 1 }, { prd_id: 9, plan_id: 2, pay_amt: 60000, status: 1 }],
    } },
  } });
  const mixin = loadMixin('src/components/order/cardAmountMixin.js', {
    api_order: { reqGetOrderList(params) { calls.push(params); return request(params); } },
    cardAmountLoaderMixin,
    fcPriceMixin,
  });
  const view = new Vue({
    mixins: [mixin],
    data: () => ({ card: { cardList: cards }, safeModeEnabled: false, typeModule: 1, ...options }),
    beforeCreate() { this.$store = store; },
  });
  return { view, store, calls };
}

test('order homepage A03 displays 2177.10 from the waiter order response', async () => {
  const records = rows();
  const before = JSON.stringify(records);
  const { view, calls } = fixture(async () => response(records));
  try {
    const current = view.card.cardList[0];
    assert.equal(view.getCardOrderAmount(current), '--');
    await settled(view);
    assert.deepEqual(calls, [{ seat_id: 7, turnover_cnt: 1 }]);
    assert.equal(view.getCardOrderAmount(current), '2177.10');
    assert.equal(current.orderAmt, 2377.1);
    assert.equal(current.payedAmt, 800);
    assert.equal(JSON.stringify(records), before);
  } finally { view.$destroy(); }
});

test('backend cents remain the scope of the total and retain historical settlement discounts', async () => {
  const { view } = fixture(async () => response(rows(), 257710));
  try {
    await settled(view);
    assert.equal(view.getCardOrderAmount(view.card.cardList[0]), '2377.10', 'only the unpaid scheme price delta changes the backend total');
  } finally { view.$destroy(); }
});

test('scheme changes, free scheme prices and disabled schemes update without refetching', async () => {
  const { view, store, calls } = fixture();
  try {
    await settled(view);
    const current = view.card.cardList[0];
    const scheme = store.state.cardPageInfo.resResultDataObj.fcProductPrices[1];
    scheme.pay_amt = 50000;
    await Vue.nextTick();
    assert.equal(view.getCardOrderAmount(current), '2077.10');
    scheme.pay_amt = 0;
    assert.equal(view.getCardOrderAmount(current), '1577.10');
    scheme.status = 2;
    assert.equal(view.getCardOrderAmount(current), '2377.10');
    assert.equal(calls.length, 1);
  } finally { view.$destroy(); }
});

test('paid records, refunds, gifts and package children do not create scheme corrections', async () => {
  const unpaid = { pid: 9, ae: 22, wei: 22, pp: 800, p2: 800, pa: 1600, pc: 2, s: 1 };
  const records = [
    { ...unpaid, changeCount: 1, si: [{ ...unpaid, pc: 20 }], bs: [{ ...unpaid, pc: 1 }] },
    { ...unpaid, s: '5', pa: 999 },
    { ...unpaid, back: true },
    { ...unpaid, at: 2 },
    { ...unpaid, at: '3' },
    { ...unpaid, pc: 0 },
  ];
  const { view } = fixture(async () => response(records, 500000));
  try {
    await settled(view);
    assert.equal(view.getCardOrderAmount(view.card.cardList[0]), '4600.00', 'only remaining pc=2 has a 400 scheme difference');
  } finally { view.$destroy(); }
});

test('missing recorded subtotals fall back to effective unit price while explicit zero stays zero', async () => {
  const records = [
    { pid: 9, ae: 22, pp: 800, p2: 700, pc: 2, s: 1 },
    { pid: 9, ae: 22, pp: 800, pa: 0, pc: 1, s: 1 },
    { pid: 9, ae: 999, wei: 22, pp: 800, pa: 800, pc: 1, s: 1 },
  ];
  const { view } = fixture(async () => response(records, 200000));
  try {
    await settled(view);
    assert.equal(view.getCardOrderAmount(view.card.cardList[0]), '2400.00', 'missing author scheme must not fall back to waiter scheme');
  } finally { view.$destroy(); }
});

test('missing or invalid backend totals fall back to the card summary; backend zero is valid', async () => {
  for (const orderAmount of [undefined, null, '', 'bad']) {
    const { view } = fixture(async () => ({ code: 1, data: { records: rows(), pay_info: { order_amt: orderAmount } } }));
    try {
      await settled(view);
      assert.equal(view.getCardOrderAmount(view.card.cardList[0]), '2177.10');
    } finally { view.$destroy(); }
  }
  const { view } = fixture(async () => response([], 0));
  try {
    await settled(view);
    assert.equal(view.getCardOrderAmount(view.card.cardList[0]), '0.00');
  } finally { view.$destroy(); }
});

test('invalid or nonpositive quantities cannot corrupt a valid summary', async () => {
  const records = [undefined, null, { pid: 9, ae: 22, pp: 800, pa: 800 }, { pid: 9, ae: 22, pp: 800, pa: 800, pc: 'bad' }, { pid: 9, ae: 22, pp: 800, pa: 800, pc: -1 }];
  const { view } = fixture(async () => response(records));
  try {
    await settled(view);
    assert.equal(view.getCardOrderAmount(view.card.cardList[0]), '2377.10');
  } finally { view.$destroy(); }
});

test('no lookup permission, wine mode and safe mode do not fetch order details', async () => {
  for (const config of [
    { cards: [card({ canLookOrder: false })], options: {} },
    { cards: [card()], options: { typeModule: 2 } },
    { cards: [card()], options: { safeModeEnabled: true } },
  ]) {
    const { view, calls } = fixture(async () => response(), config.cards, config.options);
    try {
      await settled(view);
      assert.equal(calls.length, 0);
      assert.equal(view.getCardOrderAmount(view.card.cardList[0]), '--');
      assert.deepEqual(Object.keys(view.cardAmountDetails), []);
    } finally { view.$destroy(); }
  }
});

test('switching wine or safe mode clears details and resuming order mode reloads', async () => {
  const { view, calls } = fixture();
  try {
    await settled(view);
    view.typeModule = 2;
    await settled(view);
    assert.deepEqual(Object.keys(view.cardAmountDetails), []);
    view.typeModule = 1;
    await settled(view);
    assert.equal(view.getCardOrderAmount(view.card.cardList[0]), '2177.10');
    view.safeModeEnabled = true;
    await settled(view);
    assert.deepEqual(Object.keys(view.cardAmountDetails), []);
    assert.equal(calls.length, 2);
  } finally { view.$destroy(); }
});

test('a settled table retains its recorded total without repricing or fetching details', async () => {
  const { view, calls } = fixture(async () => response(), [card({ bizStatus: 7 })]);
  try {
    await settled(view);
    assert.equal(calls.length, 0);
    assert.equal(view.getCardOrderAmount(view.card.cardList[0]), '2377.10');
  } finally { view.$destroy(); }
});

test('truthy employee lookup permissions work while linked function tables keep their aggregate totals', async () => {
  const { view, calls } = fixture(async () => response(), [
    card({ seatId: 1, canLookOrder: '11' }),
    card({ seatId: 2, bizType: '3', orderAmt: 12000 }),
  ]);
  try {
    await settled(view);
    assert.deepEqual(calls, [{ seat_id: 1, turnover_cnt: 1 }]);
    assert.equal(view.getCardOrderAmount(view.card.cardList[0]), '2177.10');
    assert.equal(view.getCardOrderAmount(view.card.cardList[1]), '12000.00', 'a normal-seat detail total cannot replace a grouped function table summary');
  } finally { view.$destroy(); }
});

test('open tables with a nonzero summary load prices while empty and reserved tables do not', async () => {
  const { view, calls } = fixture(async () => response(), [
    card({ seatId: 1, bizStatus: 3, orderAmt: 10 }),
    card({ seatId: 2, bizStatus: 4, orderAmt: 10 }),
    card({ seatId: 3, bizStatus: 3, orderAmt: 0 }),
    card({ seatId: 4, bizStatus: 1 }),
    card({ seatId: 5, bizStatus: 2 }),
    card({ seatId: 6, bizStatus: 8 }),
  ]);
  try {
    await settled(view);
    assert.deepEqual(calls.map(item => item.seat_id).sort(), [1, 2]);
  } finally { view.$destroy(); }
});

test('late responses from a previous turnover cannot populate a reused seat', async () => {
  const oldRequest = deferred();
  const nextRequest = deferred();
  let invocation = 0;
  const { view, calls } = fixture(() => { invocation += 1; if (invocation === 1) return oldRequest.promise; return nextRequest.promise; });
  try {
    view.card.cardList = [card({ wkCsmId: 202, turnoverCnt: 2 })];
    await flush();
    oldRequest.resolve(response());
    await flush();
    assert.equal(view.getCardOrderAmount(view.card.cardList[0]), '--');
    assert.deepEqual(calls, [{ seat_id: 7, turnover_cnt: 1 }, { seat_id: 7, turnover_cnt: 2 }]);
    nextRequest.resolve(response([], 1234));
    await settled(view);
    assert.equal(view.getCardOrderAmount(view.card.cardList[0]), '12.34');
    assert.equal(Object.keys(view.cardAmountDetails).length, 1);
  } finally { view.$destroy(); }
});

test('permission revocation ignores an outstanding response and code 2 clears previously cached amounts', async () => {
  let denied = false;
  const { view } = fixture(async () => { if (denied) return { code: 2 }; return response(); });
  try {
    await settled(view);
    denied = true;
    await view.refreshCardAmounts();
    assert.equal(view.getCardOrderAmount(view.card.cardList[0]), '--');
    assert.deepEqual(Object.keys(view.cardAmountDetails), []);
  } finally { view.$destroy(); }

  const pending = deferred();
  const next = fixture(() => pending.promise);
  try {
    next.view.card.cardList = [card({ canLookOrder: false })];
    await flush();
    pending.resolve(response());
    await settled(next.view);
    assert.deepEqual(Object.keys(next.view.cardAmountDetails), []);
    assert.equal(next.view.getCardOrderAmount(next.view.card.cardList[0]), '--');
  } finally { next.view.$destroy(); }
});

test('overlapping refreshes maintain a maximum of three requests and destruction blocks late writes', async () => {
  const requests = [];
  let active = 0;
  let maxActive = 0;
  const { view, calls } = fixture(() => {
    const pending = deferred();
    requests.push(pending);
    active += 1;
    maxActive = Math.max(maxActive, active);
    return pending.promise.finally(() => { active -= 1; });
  }, Array.from({ length: 8 }, (_, index) => card({ seatId: index + 1 })));
  try {
    assert.equal(calls.length, 3);
    view.refreshCardAmounts();
    view.refreshCardAmounts();
    assert.equal(calls.length, 3);
    let handled = 0;
    for (let i = 0; i < 30 && view.cardAmountRefreshRunning; i += 1) {
      while (handled < requests.length) { requests[handled].resolve(response()); handled += 1; }
      await flush();
    }
    assert.equal(view.cardAmountRefreshRunning, false);
    assert.equal(maxActive, 3);
    assert.equal(new Set(calls.map(params => params.seat_id)).size, 8);
  } finally { view.$destroy(); }

  const pending = deferred();
  const next = fixture(() => pending.promise);
  next.view.$destroy();
  pending.resolve(response());
  await settled(next.view);
  assert.deepEqual(Object.keys(next.view.cardAmountDetails), []);
});

test('both ordering homepages bind displayed order amounts to the shared calculation', () => {
  for (const name of ['orderCard', 'newOrderCard']) {
    const page = compiler.parseComponent(source('src/views/Order/' + name + '.vue'));
    assert.match(page.script.content, /mixins:\s*\[[^\]]*cardAmountMixin/);
    assert.match(page.template.content, /点:￥\s*\{\{\s*getCardOrderAmount\(item\)\s*\}\}/);
    assert.match(page.template.content, /v-if="item\.canLookOrder"/);
    assert.deepEqual(compiler.compile(page.template.content).errors, []);
  }
  assert.doesNotMatch(source('src/components/order/cardAmountMixin.js'), /api_money|reqGetCardPayInfo|\/sel\//, 'waiter accounts never call cashier detail endpoints');
});
