const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const Vue = require('vue');
const compiler = require('vue-template-compiler');

const root = path.join(__dirname, '..');
function loadMixin(file, dependencies = {}) {
  const source = fs.readFileSync(path.join(root, 'src/components/order', file), 'utf8')
    .replace(/^import .*;$/gm, '').replace('export default', 'return');
  return Function(...Object.keys(dependencies), source)(...Object.values(dependencies));
}
const getFcPrice = Function(fs.readFileSync(path.join(root, 'src/utils/fcPrice.js'), 'utf8')
  .replace('export function', 'function') + '\nreturn getFcPrice;')();
const fcPriceMixin = loadMixin('fcPriceMixin.js', { getFcPrice });
const payOrderPriceMixin = loadMixin('payOrderPriceMixin.js', { fcPriceMixin });

function rows() {
  return [
    { id: 1, pid: 9, ae: 11, wei: 11, pp: '800', pa: '777', pc: 1 },
    { id: 2, pid: 10, pp: '0.10', pa: '0.10', pc: 1 },
    { id: 3, pid: 9, ae: 22, wei: 22, pp: '800', pa: '800', pc: 1 },
  ];
}
function fixture(request = async () => ({ code: 1, data: { os: rows() } })) {
  const calls = [];
  const warnings = [];
  const errors = [];
  const store = Vue.observable({ state: {
    orderInfo: { currentCardInfo: { seatId: 7 } },
    cardPageInfo: { resResultDataObj: {
      fcPlanEmployees: [{ emp_id: 11, plan_id: 1, status: 1 }, { emp_id: 22, plan_id: 2, status: 1 }],
      fcProductPrices: [{ prd_id: 9, plan_id: 1, pay_amt: 77700, status: 1 }, { prd_id: 9, plan_id: 2, pay_amt: 60000, status: 1 }],
    } },
  } });
  const mixin = loadMixin('waiterPayAmountMixin.js', {
    payOrderPriceMixin,
    api_order: { reqGetPayOrderList(params) { calls.push(params); return request(params); } },
    console: { error(...args) { errors.push(args); } },
  });
  const view = new Vue({
    mixins: [mixin],
    beforeCreate() { this.$store = store; this.$message = { warning: text => warnings.push(text) }; },
    computed: { currentSeatId() { return this.$store.state.orderInfo.currentCardInfo.seatId * 1; } },
  });
  return { view, store, calls, warnings, errors };
}
function deferred() {
  let resolve, reject;
  const promise = new Promise((yes, no) => { resolve = yes; reject = no; });
  return { promise, resolve, reject };
}

test('the preview sums selected discounted orders and reacts to selection but not current metadata', async () => {
  const { view, store, calls } = fixture();
  try {
    view.selectedOrderIdList = [1, '2', 3, 3];
    await view.loadPayAmount();
    assert.deepEqual(calls, [{ seat_id: 7 }]);
    assert.equal(view.payAmount, 1577.1);
    view.selectedOrderIdList = ['3'];
    assert.equal(view.payAmount, 800);
    store.state.cardPageInfo.resResultDataObj.fcProductPrices[1].pay_amt = 50000;
    await Vue.nextTick();
    assert.equal(view.payAmount, 800);
    store.state.cardPageInfo.resResultDataObj.fcProductPrices[1].pay_amt = 0;
    assert.equal(view.payAmount, 800, 'metadata zero does not overwrite the recorded price');
    store.state.cardPageInfo.resResultDataObj.fcProductPrices[1].status = 2;
    assert.equal(view.payAmount, 800, 'inactive schemes fall back to the recorded order subtotal');
    assert.equal(view.payOrderItems[2].pa, '800', 'preview must not overwrite backend order amounts');
  } finally { view.$destroy(); }
});

test('refunds, exhausted orders, online groups and gifts are excluded without double-counting packages', async () => {
  const orders = [
    { id: 1, pid: 9, ae: 22, pp: 800, pa: 1600, pc: 2, is: 1, si: [{ pa: 9000 }], bs: [{ pa: 800, pc: 1 }] },
    { id: 2, pp: 800, pa: 800, pc: 1, back: true },
    { id: 3, pp: 0, pa: 800, pc: '0' },
    { id: 4, oid: 4, pp: 800, pa: 800, pc: 1 },
    { id: 5, pp: 800, pa: 800, pc: 1, at: 2 },
    { id: 6, pp: 800, pa: 800, pc: 1, at: '3' },
    { id: 7, pp: 0, pa: '12.34', pc: 3 },
    { id: 8, pp: 0.1, pa: '0.10', pc: 1 },
    { id: 9, pp: 0.2, pa: '0.20', pc: 1 },
  ];
  const { view } = fixture(async () => ({ code: 1, data: { os: orders, oos: [{ oid: 99, pa: 9999 }] } }));
  try {
    view.selectedOrderIdList = orders.map(item => item.id);
    await view.loadPayAmount();
    assert.equal(view.payAmount, 1612.64);
  } finally { view.$destroy(); }
});

test('refresh clears the prior amount while loading and picks up changed recorded subtotals', async () => {
  const pending = deferred();
  let invocation = 0;
  const { view } = fixture(() => ++invocation === 1
    ? Promise.resolve({ code: 1, data: { os: [{ id: 1, pp: 10, pa: 8, pc: 1 }] } }) : pending.promise);
  try {
    view.selectedOrderIdList = [1];
    await view.loadPayAmount();
    assert.equal(view.payAmount, 8);
    const refresh = view.loadPayAmount();
    assert.equal(view.payAmount, 0);
    pending.resolve({ code: 1, data: { os: [{ id: 1, pp: 10, pa: 5, pc: 1 }] } });
    await refresh;
    assert.equal(view.payAmount, 5);
  } finally { view.$destroy(); }
});

test('no selected orders makes no request and an empty response clears the cached amount', async () => {
  let response = { code: 1, data: { os: rows() } };
  const { view, calls } = fixture(async () => response);
  try {
    await view.loadPayAmount();
    assert.equal(calls.length, 0);
    view.selectedOrderIdList = [1];
    await view.loadPayAmount();
    assert.equal(view.payAmount, 777);
    response = { code: 1, data: {} };
    await view.loadPayAmount();
    assert.equal(view.payAmount, 0);
    view.selectedOrderIdList = [];
    await view.loadPayAmount();
    assert.equal(calls.length, 2);
  } finally { view.$destroy(); }
});

test('an older success cannot overwrite the latest refreshed amount', async () => {
  const first = deferred();
  const second = deferred();
  let invocation = 0;
  const { view } = fixture(() => ++invocation === 1 ? first.promise : second.promise);
  try {
    view.selectedOrderIdList = [1];
    const oldLoad = view.loadPayAmount();
    const newLoad = view.loadPayAmount();
    second.resolve({ code: 1, data: { os: [{ id: 1, pp: 10, pa: 5, pc: 1 }] } });
    await newLoad;
    first.resolve({ code: 1, data: { os: [{ id: 1, pp: 10, pa: 8, pc: 1 }] } });
    await oldLoad;
    assert.equal(view.payAmount, 5);
  } finally { view.$destroy(); }
});

test('an older request cannot show a stale failure', async () => {
  const first = deferred();
  const second = deferred();
  let invocation = 0;
  const { view, warnings } = fixture(() => ++invocation === 1 ? first.promise : second.promise);
  try {
    view.selectedOrderIdList = [1];
    const oldLoad = view.loadPayAmount();
    const newLoad = view.loadPayAmount();
    second.resolve({ code: 1, data: { os: [{ id: 1, pp: 10, pa: 5, pc: 1 }] } });
    await newLoad;
    first.resolve({ code: 0, msg: '旧请求失败' });
    await oldLoad;
    assert.equal(view.payAmount, 5);
    assert.deepEqual(warnings, []);
  } finally { view.$destroy(); }
});

test('changing tables invalidates cached selections and prevents an in-flight response from leaking across tables', async () => {
  const pending = deferred();
  const { view, store } = fixture(() => pending.promise);
  try {
    view.selectedOrderIdList = [1];
    const loading = view.loadPayAmount();
    store.state.orderInfo.currentCardInfo.seatId = 8;
    await Vue.nextTick();
    assert.equal(view.selectedOrderIdList.length, 0);
    store.state.orderInfo.currentCardInfo.seatId = 7;
    await Vue.nextTick();
    pending.resolve({ code: 1, data: { os: rows() } });
    await loading;
    assert.equal(view.payOrderItems.length, 0);
    assert.equal(view.payAmount, 0);
  } finally { view.$destroy(); }
});

test('API errors clear stale values and surface a warning', async () => {
  let fail = false;
  const { view, warnings, errors } = fixture(async () => {
    if (fail) throw new Error('network unavailable');
    return { code: 1, data: { os: rows() } };
  });
  try {
    view.selectedOrderIdList = [1];
    await view.loadPayAmount();
    assert.equal(view.payAmount, 777);
    fail = true;
    await view.loadPayAmount();
    assert.equal(view.payAmount, 0);
    assert.equal(warnings.length, 1);
    assert.equal(errors.length, 1);
  } finally { view.$destroy(); }
});

test('both footer variants use the shared preview and their templates compile', () => {
  for (const name of ['footBar.vue', 'newFootBar.vue']) {
    const page = compiler.parseComponent(fs.readFileSync(path.join(root, 'src/components/order', name), 'utf8'));
    assert.match(page.script.content, /mixins:\s*\[[^\]]*waiterPayAmountMixin/);
    assert.doesNotMatch(page.script.content, /async loadPayAmount\(|payAmount:\s*0/);
    assert.match(page.script.content, /handleMemberBound\([^)]*\)\s*\{[\s\S]*?this\.loadPayAmount\(\)/);
    assert.match(page.script.content, /order_ids:\s*this\.selectedOrderIdList\.map/);
    assert.deepEqual(compiler.compile(page.template.content).errors, []);
  }
});
