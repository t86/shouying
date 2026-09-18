const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const Vue = require('vue');
const compiler = require('vue-template-compiler');

const root = path.join(__dirname, '..');
function load(relative, dependencies = {}) {
  const source = fs.readFileSync(path.join(root, relative), 'utf8');
  const exports = [...source.matchAll(/export (?:const|function) (\w+)/g)].map(match => match[1]);
  const code = source.replace(/^import[\s\S]*?;\s*$/gm, '').replace(/export /g, '');
  return Function(...Object.keys(dependencies), code + '\nreturn {' + exports.join(',') + '}')(...Object.values(dependencies));
}
const { getFcPrice } = load('src/utils/fcPrice.js');
const { getProductPrice } = load('src/utils/priceCalculator.js');
const prices = load('src/utils/orderItemPrice.js', { getFcPrice, getProductPrice });
function card(overrides = {}) {
  return { seatId: 7, seatType: 1, wkCsmId: 101, turnoverCnt: 1, bizStatus: 5, orderAmt: 2377.1, payedAmt: 800, ...overrides };
}
function rows() {
  return [
    { pid: 9, ae: 11, wei: 11, pp: '800', p2: '777', pa: '777', pc: 1 },
    { pid: 10, pp: '0.10', p2: '0.10', pa: '0.10', pc: 1 },
    { pid: 9, ae: 22, wei: 22, pp: '800', p2: '800', pa: '800', pc: 1 },
  ];
}
function response(orders = rows()) { return { code: 1, data: { unpay_order: { os: orders } } }; }
function deferred() {
  let resolve, reject;
  const promise = new Promise((yes, no) => { resolve = yes; reject = no; });
  return { promise, resolve, reject };
}
async function flush() { for (let i = 0; i < 8; i += 1) await Promise.resolve(); await Vue.nextTick(); }
async function settled(view) {
  for (let i = 0; i < 100; i += 1) {
    await flush();
    if (!view.cardAmountRefreshRunning) return;
  }
  assert.fail('card amount requests did not finish');
}
function fixture(request = async () => response(), cards = [card()], safeModeEnabled = false) {
  const calls = [];
  const store = Vue.observable({ state: {
    orderInfo: { currentCardInfo: { seatId: 99, seatType: 4 } },
    cardPageInfo: { storeStatusId: 1, resResultDataObj: {
      fcPlanEmployees: [{ emp_id: 11, plan_id: 1, status: 1 }, { emp_id: 22, plan_id: 2, status: 1 }],
      fcProductPrices: [{ prd_id: 9, plan_id: 1, pay_amt: 77700, status: 1 }, { prd_id: 9, plan_id: 2, pay_amt: 60000, status: 1 }],
      goodsAroundInfo: [], businessData: [], businessEmpList: [],
    } },
  } });
  const loaderSource = fs.readFileSync(path.join(root, 'src/components/common/cardAmountLoaderMixin.js'), 'utf8')
    .replace('export default', 'return');
  const cardAmountLoaderMixin = Function(loaderSource)();
  const source = fs.readFileSync(path.join(root, 'src/components/money/cardAmountMixin.js'), 'utf8')
    .replace(/^import[\s\S]*?;\s*$/gm, '').replace('export default', 'return');
  const mixin = Function('api_money', 'cardAmountLoaderMixin', ...Object.keys(prices), source)(
    { reqGetCardPayInfo(params) { calls.push(params); return request(params); } }, cardAmountLoaderMixin, ...Object.values(prices)
  );
  const view = new Vue({
    mixins: [mixin],
    data: () => ({ card: { cardList: cards }, safeModeEnabled }),
    beforeCreate() { this.$store = store; },
  });
  return { view, store, calls };
}

test('cashier card uses 777 + 0.10 + 800, retaining the already settled 800', async () => {
  const originalRows = rows();
  const before = JSON.stringify(originalRows);
  const { view, calls } = fixture(async () => response(originalRows));
  try {
    const current = view.card.cardList[0];
    assert.equal(view.getCardUnpaidAmount(current), '--', 'the stale summary is not used while loading');
    await settled(view);
    assert.deepEqual(calls, [{ seat_id: 7, turnover_cnt: 1 }]);
    assert.equal(view.getCardUnpaidAmount(current), '1577.10');
    assert.equal(view.getCardOrderAmount(current), '2377.10');
    assert.equal(current.payedAmt, 800);
    assert.equal(current.orderAmt, 2377.1);
    assert.equal(JSON.stringify(originalRows), before, 'server records stay unchanged');
  } finally { view.$destroy(); }
});

test('order total preserves paid historical gross amounts and settlement discounts', async () => {
  const { view } = fixture(async () => response(), [card({ orderAmt: 2577.1, payedAmt: 800 })]);
  try {
    await settled(view);
    const current = view.card.cardList[0];
    assert.equal(view.getCardUnpaidAmount(current), '1577.10');
    assert.equal(view.getCardOrderAmount(current), '2577.10', 'recorded summary must not be repriced');
  } finally { view.$destroy(); }
});

test('scheme metadata cannot change recorded detail totals', async () => {
  const { view, store, calls } = fixture();
  try {
    await settled(view);
    const current = view.card.cardList[0];
    store.state.cardPageInfo.resResultDataObj.fcProductPrices[1].pay_amt = 50000;
    await Vue.nextTick();
    assert.equal(view.getCardUnpaidAmount(current), '1577.10');
    assert.equal(view.getCardOrderAmount(current), '2377.10');
    store.state.cardPageInfo.resResultDataObj.fcProductPrices[1].pay_amt = 0;
    assert.equal(view.getCardUnpaidAmount(current), '1577.10');
    store.state.cardPageInfo.resResultDataObj.fcProductPrices[1].status = 2;
    assert.equal(view.getCardUnpaidAmount(current), '1577.10');
    assert.equal(calls.length, 1);
  } finally { view.$destroy(); }
});

test('current business/member/box metadata cannot overwrite recorded prices', async () => {
  const pending = deferred();
  const { view, store } = fixture(() => pending.promise, [
    card({ seatId: 1, seatType: 4, orderAmt: 100, payedAmt: 0 }),
    card({ seatId: 2, seatType: 1, orderAmt: 100, payedAmt: 0 }),
  ]);
  try {
    const metadata = store.state.cardPageInfo.resResultDataObj;
    metadata.goodsAroundInfo = [{ id: 40, price: '100', bxBsMbPrice: '55', bxPrice: '70' }];
    metadata.businessData = [
      { seatId: 1, sales_emp_id: 11, csm_cust_phone: '13800000000' },
      { seatId: 2, sales_emp_id: 0, csm_cust_phone: '' },
      { seatId: 99, sales_emp_id: 0, csm_cust_phone: '' },
    ];
    metadata.businessEmpList = [{ emp_id: 11, status: 1 }];
    pending.resolve(response([{ pid: 40, pp: 100, pa: 100, pc: 1 }]));
    await settled(view);
    assert.equal(view.getCardUnpaidAmount(view.card.cardList[0]), '100.00');
    assert.equal(view.getCardOrderAmount(view.card.cardList[0]), '100.00');
    assert.equal(view.getCardUnpaidAmount(view.card.cardList[1]), '100.00');
  } finally { view.$destroy(); }
});

test('online rows count once, refunds and gifts count zero, and remaining pc ignores checkout selection', async () => {
  const { view } = fixture(async () => ({ code: 1, data: { unpay_order: {
    os: [
      { pid: 9, ae: 22, pp: 800, p2: 800, pa: 1600, pc: 2, changeCount: 1, is: 1, si: [{ pp: 9999, pc: 1 }], bs: [{ pp: 800, pc: 1 }] },
      { pp: 100, pc: 1, pa: 100, back: true },
      { pp: 0, pc: 0, pa: 999 },
      { pp: 100, pc: 1, pa: 100, at: 2 },
      { pp: 100, pc: 1, pa: 100, at: '3' },
      { pp: 0, pc: 3, pa: '12.34' },
    ],
    oos: [
      { oid: 1, os: [{ pp: 0.1, pc: 1, pa: 0.1 }, { pp: 0.2, pc: 1, pa: 0.2 }, { pp: 9, pc: 1, back: true }] },
      { oid: 2, back: true, os: [{ pp: 999, pc: 1 }] },
    ],
  }, payed_order: { os: [{ pp: 800, pc: 1, pa: 800 }] } } }));
  try {
    await settled(view);
    assert.equal(view.getCardUnpaidAmount(view.card.cardList[0]), '1612.64');
  } finally { view.$destroy(); }
});

test('missing recorded subtotal falls back to recorded unit price', async () => {
  const { view } = fixture(async () => response([{ pid: 9, ae: 22, pp: 800, p2: 800, pc: 2 }]), [card({ orderAmt: 2400 })]);
  try {
    await settled(view);
    assert.equal(view.getCardUnpaidAmount(view.card.cardList[0]), '1600.00');
    assert.equal(view.getCardOrderAmount(view.card.cardList[0]), '2400.00');
  } finally { view.$destroy(); }
});

test('settled cards make no requests and a successful missing unpaid section means zero', async () => {
  const { view, calls } = fixture(async () => ({ code: 1, data: {} }), [card({ bizStatus: 7 })]);
  try {
    await settled(view);
    assert.equal(calls.length, 0);
    assert.equal(view.getCardUnpaidAmount(view.card.cardList[0]), '0.00');
    assert.equal(view.getCardOrderAmount(view.card.cardList[0]), '2377.10');
    view.card.cardList = [card({ bizStatus: 6 })];
    await settled(view);
    assert.equal(calls.length, 1, 'replacing the visible card list refreshes details');
    assert.equal(view.getCardUnpaidAmount(view.card.cardList[0]), '0.00');
  } finally { view.$destroy(); }
});

test('a late response from a previous turnover cannot populate the reused seat', async () => {
  const oldRequest = deferred();
  const newRequest = deferred();
  let invocation = 0;
  const { view, calls } = fixture(() => { invocation += 1; if (invocation === 1) return oldRequest.promise; return newRequest.promise; });
  try {
    view.card.cardList = [card({ wkCsmId: 202, turnoverCnt: 2 })];
    await flush();
    oldRequest.resolve(response());
    await flush();
    assert.equal(view.getCardUnpaidAmount(view.card.cardList[0]), '--');
    assert.deepEqual(calls, [{ seat_id: 7, turnover_cnt: 1 }, { seat_id: 7, turnover_cnt: 2 }]);
    newRequest.resolve(response([{ pp: 12, p2: 12, pa: 12, pc: 1 }]));
    await settled(view);
    assert.equal(view.getCardUnpaidAmount(view.card.cardList[0]), '12.00');
    assert.equal(Object.keys(view.cardAmountDetails).length, 1);
  } finally { view.$destroy(); }
});

test('a changed amount summary invalidates the cache before its refreshed response arrives', async () => {
  const pending = deferred();
  let invocation = 0;
  const { view } = fixture(() => { invocation += 1; if (invocation === 1) return Promise.resolve(response()); return pending.promise; });
  try {
    await settled(view);
    view.card.cardList = [card({ orderAmt: 2389.1 })];
    await flush();
    assert.equal(view.getCardUnpaidAmount(view.card.cardList[0]), '--');
    pending.resolve(response(rows().concat({ pp: 12, p2: 12, pa: 12, pc: 1 })));
    await settled(view);
    assert.equal(view.getCardUnpaidAmount(view.card.cardList[0]), '1589.10');
  } finally { view.$destroy(); }
});

test('failed requests hide stale amounts and the next refresh retries successfully', async () => {
  let fail = false;
  const { view, calls } = fixture(async () => { if (fail) throw new Error('offline'); return response(); });
  try {
    await settled(view);
    fail = true;
    await view.refreshCardAmounts();
    assert.equal(view.getCardUnpaidAmount(view.card.cardList[0]), '--');
    assert.equal(view.getCardOrderAmount(view.card.cardList[0]), '--');
    fail = false;
    await view.refreshCardAmounts();
    assert.equal(view.getCardUnpaidAmount(view.card.cardList[0]), '1577.10');
    assert.equal(calls.length, 3);
  } finally { view.$destroy(); }
});

test('refreshes share a runner with at most three simultaneous detail requests', async () => {
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
    assert.equal(calls.length, 3, 'overlapping refreshes cannot start another worker pool');
    let handled = 0;
    for (let i = 0; i < 30 && view.cardAmountRefreshRunning; i += 1) {
      while (handled < requests.length) { requests[handled].resolve(response()); handled += 1; }
      await flush();
    }
    assert.equal(view.cardAmountRefreshRunning, false);
    assert.equal(maxActive, 3);
    assert.equal(new Set(calls.map(params => params.seat_id)).size, 8);
    for (const current of view.card.cardList) assert.equal(view.getCardUnpaidAmount(current), '1577.10');
  } finally { view.$destroy(); }
});

test('safe mode skips reads, clears cached details, and loads again when disabled', async () => {
  const { view, calls } = fixture(async () => response(), [card()], true);
  try {
    await settled(view);
    assert.equal(calls.length, 0);
    view.safeModeEnabled = false;
    await settled(view);
    assert.equal(view.getCardUnpaidAmount(view.card.cardList[0]), '1577.10');
    view.safeModeEnabled = true;
    await settled(view);
    assert.equal(calls.length, 1);
    assert.deepEqual(Object.keys(view.cardAmountDetails), []);
  } finally { view.$destroy(); }
});

test('destroying the card page prevents outstanding responses from updating its cache', async () => {
  const pending = deferred();
  const { view } = fixture(() => pending.promise);
  view.$destroy();
  pending.resolve(response());
  await settled(view);
  assert.deepEqual(Object.keys(view.cardAmountDetails), []);
});

test('the cashier page binds both displayed totals to the shared detail calculation', () => {
  const page = compiler.parseComponent(fs.readFileSync(path.join(root, 'src/views/Money/moneyCard.vue'), 'utf8'));
  assert.match(page.script.content, /mixins:\s*\[[^\]]*cardAmountMixin/);
  assert.match(page.template.content, /¥\s*\{\{\s*getCardOrderAmount\(item\)\s*\}\}/);
  assert.match(page.template.content, /¥\s*\{\{\s*getCardUnpaidAmount\(item\)\s*\}\}/);
  assert.match(page.template.content, /Number\(item\.payedAmt\)\.toFixed\(2\)/, 'the displayed amount already paid stays historical');
  assert.deepEqual(compiler.compile(page.template.content).errors, []);
});
