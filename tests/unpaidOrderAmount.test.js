const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const parser = require('@babel/parser');
const compiler = require('vue-template-compiler');
const Vue = require('vue');

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
const page = compiler.parseComponent(fs.readFileSync(path.join(root, 'src/views/Money/payOrder.vue'), 'utf8'));
function pageSection(section, dependencies = {}) {
  const ast = parser.parse(page.script.content, { sourceType: 'module' });
  const options = ast.program.body.find(node => node.type === 'ExportDefaultDeclaration').declaration;
  const value = options.properties.find(node => node.key.name === section).value;
  return vm.runInNewContext('(' + page.script.content.slice(value.start, value.end) + ')', { ...prices, ...dependencies });
}
function metadata() {
  return {
    fcPlanEmployees: [{ emp_id: 11, plan_id: 1, status: 1 }, { emp_id: 22, plan_id: 2, status: 1 }],
    fcProductPrices: [{ prd_id: 9, plan_id: 1, pay_amt: 77700, status: 1 }, { prd_id: 9, plan_id: 2, pay_amt: 60000, status: 1 }],
  };
}
function screenshotItems() {
  return [
    { pid: 9, ae: 11, wei: 11, pp: '800', p2: '800', pa: '800', pc: 1, checkout: true },
    { pid: 10, pp: '0.10', p2: '0.10', pa: '0.10', pc: 1, checkout: true },
    { pid: 9, ae: 22, wei: 22, pp: '800', p2: '800', pa: '800', pc: 1, checkout: true },
  ];
}

test('unpaid total follows the screenshot line prices: 800 + 0.10 + 800 = 1600.10', () => {
  const items = screenshotItems();
  const before = JSON.stringify(items);
  assert.equal(prices.calcUnpaidOrderAmount(items, metadata()).toFixed(2), '1600.10');
  assert.equal(JSON.stringify(items), before, 'calculating the footer must preserve recorded order amounts');
  assert.equal(prices.calcUnpaidOrderAmount([]), 0);
  assert.equal(prices.calcUnpaidOrderAmount(null), 0);
});

test('unpaid total uses the entire remaining quantity regardless of checkout selection', () => {
  const item = { pid: 9, ae: 22, pp: '800', pc: 3, changeCount: 1, checkout: true };
  assert.equal(prices.calcItemAmount(item, metadata()), 800, 'the selected checkout subtotal remains separate');
  assert.equal(prices.calcUnpaidOrderAmount([item], metadata()), 2400);
  item.checkout = false;
  item.changeCount = 0;
  assert.equal(prices.calcUnpaidOrderAmount([item], metadata()), 2400);
  item.pc = 2;
  assert.equal(prices.calcUnpaidOrderAmount([item], metadata()), 1600, 'a changed remaining quantity changes the total');
});

test('online groups use expanded unrefunded rows and charge a package only once', () => {
  const items = [
    { oid: 1, os: [{ pp: 999, pc: 1 }], resultNotPayData: [
      { pp: 10, pc: 2, is: 1, si: [{ pp: 700, pc: 3 }] },
      { pp: 10, pc: 1, back: true },
      { pp: 50, pc: 1, at: 2 },
      { pp: 50, pc: 1, at: '3' },
    ] },
    { oid: 2, os: [{ pp: 3, pc: 2 }] },
    { oid: 3, os: [{ pp: 999, pc: 1 }], resultNotPayData: [] },
    { oid: 4, back: true, os: [{ pp: 999, pc: 1 }] },
    { pp: 999, pc: 1, back: true },
    { pp: 999, pc: 1, at: 2 },
    { pp: 999, pc: 1, at: 3 },
  ];
  assert.equal(prices.calcUnpaidOrderAmount(items), 26);
});

test('zero scheme prices, time prices, exhausted rows and per-line cents keep their semantics', () => {
  const context = metadata();
  context.fcProductPrices[0].pay_amt = 0;
  const items = [
    { pid: 9, ae: 11, pp: 800, p2: 0, pc: 2 },
    { pp: 0, pa: '12.34', pc: 3, changeCount: 1 },
    { pp: 0, pa: 999, pc: 0 },
    { pp: 0, pa: 999, pc: '0' },
    { pp: '0.335', pc: 1 },
    { pp: '0.335', pc: 1 },
    { pp: '0.1', pc: 1 },
    { pp: '0.2', pc: 1 },
  ];
  assert.equal(prices.calcUnpaidOrderAmount(items, context), 13.32);
  assert.equal(prices.calcUnpaidOrderAmount([{ pid: 9, ae: 22, pp: 0, pa: 999, pc: 2 }], context), 999);
});

test('without a scheme the footer retains recorded actual and original prices without current business repricing', () => {
  const context = {
    cardInfo: { seatId: 1, seatType: 4 },
    businessData: [{ seatId: 1, sales_emp_id: 22, csm_cust_phone: '13800000000' }],
    businessEmpList: [{ emp_id: 22, status: 1 }],
  };
  const productInfo = { price: '100', bxBsMbPrice: '55' };
  assert.equal(prices.calcUnpaidOrderAmount([
    { pp: 100, p2: 80, pm: 70, pc: 2, productInfo },
    { pp: 100, pc: 2, productInfo },
    { pp: 12, pc: 1 },
  ], context), 372);
});

test('the Vue 2 footer follows wo/list summary and hides stale seat totals', async () => {
  const { calculateOrderSummary } = load('src/utils/orderSummary.js');
  const computed = pageSection('computed', { calculateOrderSummary });
  const store = Vue.observable({ state: { orderInfo: { currentCardInfo: { seatId: 1 } } } });
  const view = new Vue({ data: () => ({ turnOverInfo: { activeTurnOverCount: 1 },
    payTabInfo: {activePayId:-1}, orderSummaryKey: '[1,1]', orderSummaryInfo: { order_amt: 380000, payed_amt: 60000 } }),
    computed: { orderSummary: computed.orderSummary, unpaidOrderAmount: computed.unpaidOrderAmount } });
  view.$store = store;
  try {
    assert.equal(view.unpaidOrderAmount, '3200.00');
    view.orderSummaryInfo.payed_amt = 100000;
    await Vue.nextTick();
    assert.equal(view.unpaidOrderAmount, '2800.00');
    store.state.orderInfo.currentCardInfo.seatId = 2;
    await Vue.nextTick();
    assert.equal(view.unpaidOrderAmount, '--');
  } finally { view.$destroy(); }
});

test('the unpaid amount label binds to the reactive total and the page template compiles', () => {
  assert.match(page.template.content, /未结账金额[\s\S]*?¥\s*\{\{\s*unpaidOrderAmount\s*\}\}/);
  assert.deepEqual(compiler.compile(page.template.content).errors, []);
});

test('a successful response without unpaid orders clears rows from the previous response', async () => {
  const response = { code: 1, data: {} };
  const loggedErrors = [];
  const methods = pageSection('methods', {
    api_money: { reqGetCardPayInfo: async () => response },
    console: { log(...args) { if (args.some(arg => arg instanceof Error)) loggedErrors.push(args); } },
    setTimeout() {},
  });
  const context = {
    ...methods, cashierRequestId: 0,
    $store: { state: { orderInfo: { currentCardInfo: { seatId: 1 } }, cardPageInfo: { resResultDataObj: { orderPersonInfo: [] } } } },
    turnOverInfo: { activeTurnOverCount: 1, turnOverTabList: [0, 1] },
    notPayData: { notPayOrderList: screenshotItems(), choosePayOrderList: screenshotItems() },
    $refs: { footBar: { cardInfo: {} } }, $forceUpdate() {},
    maskedPhone: () => '', updatePaymentCashiers() {}, loadOrderSummary() {},
  };
  let callbackCalled = false;
  await methods.getOrderInfo.call(context, () => { callbackCalled = true; });
  assert.equal(loggedErrors.length, 0);
  assert.equal(callbackCalled, true, 'the request must reach its successful completion');
  assert.equal(context.notPayData.notPayOrderList.length, 0);
  assert.equal(context.notPayData.choosePayOrderList.length, 0);
  assert.equal(context.cardAllOrderInfo[0].list.length, 0);
});
