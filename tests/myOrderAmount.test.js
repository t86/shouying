const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const parser = require('@babel/parser');
const compiler = require('vue-template-compiler');
const Vue = require('vue');
const orderDetailAdapter = require('../src/utils/orderDetailAdapter');

const root = path.join(__dirname, '..');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const priceScope = {};
vm.runInNewContext(read('src/utils/fcPrice.js').replace(/export /g, ''), priceScope);
function loadMixin(file, dependencies = {}) {
  const scope = { ...dependencies, module: { exports: {} } };
  vm.runInNewContext(read(file).replace(/^import .*;\s*$/gm, '').replace('export default', 'module.exports ='), scope);
  return scope.module.exports;
}
const fcPriceMixin = loadMixin('src/components/order/fcPriceMixin.js', { getFcPrice: priceScope.getFcPrice });
const myOrderAmountMixin = loadMixin('src/components/order/myOrderAmountMixin.js');
const lookups = {
  getProductInfo: id => ({ id, name: 'Product ' + id }),
  getProductInfoFromGroup: id => ({ id }),
  getOrderPersonInfo: id => ({ id, name: 'Employee ' + id }),
};
function metadata() {
  return {
    businessData: [{ seatId: 31, turnoverCnt: 2 }],
    fcPlanEmployees: [{ emp_id: 11, plan_id: 1, status: 1 }, { emp_id: 22, plan_id: 2, status: 1 }],
    fcProductPrices: [{ prd_id: 9, plan_id: 1, pay_amt: 77700, status: 1 }, { prd_id: 9, plan_id: 2, pay_amt: 60000, status: 1 }],
  };
}
function screenshotRows() {
  return [
    { id: 1, pid: 9, ae: 11, wei: 11, pp: '800', p2: '777', pa: '777', pc: 1, s: 1 },
    { id: 2, pid: 10, ae: 11, wei: 11, pp: '0.10', p2: '0.10', pa: '0.10', pc: 1, s: 1 },
    { id: 3, pid: 9, ae: 22, wei: 22, pp: '800', p2: '800', pa: '800', pc: 1, s: 1 },
    { id: 4, pid: 12, ae: 11, wei: 11, pp: '0', pa: '800', pc: 1, s: 5 },
  ];
}
function response(records = screenshotRows()) {
  return { code: 1, data: { records, pay_info: { order_amt: 237710, payed_amt: 80000, yh_amt: 0 } } };
}
function createView(name) {
  let nextResponse = response();
  const requests = [];
  const script = compiler.parseComponent(read('src/views/Order/orderMeal/' + name + '.vue')).script.content;
  const ast = parser.parse(script, { sourceType: 'module' });
  const optionsNode = ast.program.body.find(node => node.type === 'ExportDefaultDeclaration').declaration;
  const options = vm.runInNewContext('(' + script.slice(optionsNode.start, optionsNode.end) + ')', {
    fcPriceMixin, myOrderAmountMixin, authStatus: {},
    api_order: { async reqGetOrderList(params) { requests.push(params); return nextResponse; } },
    common_order: lookups, common_book: lookups,
    normalizeOrderDetailResponse: orderDetailAdapter.normalizeOrderDetailResponse,
    orderDetailLookups: lookups,
    add: '', sub: '', addDisabled: '', subDisabled: '', shoppingCarMore: '', sanJiao: '',
    drawerMyOrder: {}, drawerPrintOrder: {}, HeaderInfo: {},
    console: { log() {}, warn() {} },
  });
  // Lifecycle hooks attach browser listeners; exercise the actual loader explicitly instead.
  delete options.created;
  delete options.mounted;
  delete options.beforeDestroy;
  const store = Vue.observable({ state: {
    userInfo: { emp_id: 11, roleIds: [], sys_modules: [], upper_emp_id: 0 },
    orderInfo: { currentCardInfo: { seatId: '31' } },
    cardPageInfo: { resResultDataObj: metadata() },
  } });
  const view = new Vue({ ...options, beforeCreate() { this.$store = store; } });
  view.$message = { warning(message) { assert.fail(message); } };
  return { view, requests, respond(value) { nextResponse = value; } };
}
function assertAmounts(view, allAmt, notPayAmt, giveAmt = '0.00') {
  assert.equal(view.amt.allAmt, allAmt);
  assert.equal(view.amt.notPayAmt, notPayAmt);
  assert.equal(view.amt.giveAmt, giveAmt);
}

for (const name of ['myOrder', 'newMyOrder']) {
  test(name + ' uses recorded prices and pa including zero regardless of current metadata', async () => {
    const { view, respond } = createView(name);
    respond(response([
      ...screenshotRows(),
      { id: 5, pid: 9, ae: 22, wei: 22, pp: 800, p2: 0, pa: 0, pc: 1, s: 1 },
    ]));
    try {
      await view.getOrderedData();
      assert.deepEqual(Array.from(view.orderList, row => view.getSubtotal(row)), ['777.00', '0.10', '800.00', '800.00', '0.00']);
      assert.equal(view.getDisplayPrice(view.orderList[4]), '0.00');
      view.$store.state.cardPageInfo.resResultDataObj.fcProductPrices[1].pay_amt = 50000;
      await Vue.nextTick();
      assert.equal(view.getDisplayPrice(view.orderList[2]), '800.00');
      assertAmounts(view, '2377.10', '1577.10');
    } finally { view.$destroy(); }
  });

  test(name + ' keeps backend before-discount total and reports discount separately from gifts', async () => {
    const { view, respond } = createView(name);
    const data = response();
    data.data.pay_info = { order_amt: 240010, payed_amt: 80000, payed_val_amt: 80000, payed_free_amt: 0, yh_amt: 123 };
    respond(data);
    try {
      view.$store.state.userInfo.sys_modules = [6];
      await view.getOrderedData();
      assert.equal(view.orderList.length, 3);
      assertAmounts(view, '2400.10', '1577.10', '1.23');
      assert.equal(view.amt.discountAmt, '23.00');
      assert.match(read('src/views/Order/orderMeal/' + name + '.vue'), /amt\.discountAmt/);
    } finally { view.$destroy(); }
  });

  test(name + ' shows paid row original prices and refreshes all totals from a new response', async () => {
    const { view, respond } = createView(name);
    const data = response([{ id: 1, pid: 9, pp: 800, p2: 700, pa: 700, pc: 1, s: 5 }]);
    data.data.pay_info = { order_amt: 80000, payed_free_amt: 10000, yh_amt: 0 };
    respond(data);
    try {
      await view.getOrderedData();
      assertAmounts(view, '800.00', '0.00');
      assert.equal(view.amt.discountAmt, '100.00');
      assert.equal(view.getSubtotal(view.orderList[0]), '700.00');
      const template = compiler.parseComponent(read('src/views/Order/orderMeal/' + name + '.vue')).template.content;
      assert.doesNotMatch(template, /item\.s != 5 && fc(?:OrderOriginal|SubtotalOriginal)/);
      respond({ code: 2 });
      await view.getOrderedData();
      assertAmounts(view, '0.00', '0.00');
      assert.equal(view.amt.discountAmt, '0.00');
    } finally { view.$destroy(); }
  });

  test(name + ' excludes returns and gifts from unpaid and uses recorded p2 only when pa is absent', async () => {
    const { view, respond } = createView(name);
    respond({ code: 1, data: { records: [
      { id: 1, pid: 9, pp: 800, p2: 600, pc: 2, s: 1 },
      { id: 2, pid: 9, pp: 800, p2: 600, pa: 0, pc: 1, s: 1, at: 2 },
      { id: 3, pid: 9, pp: 800, p2: 600, pa: 600, pc: 0, s: 1, bs: [{ id: 4, pc: 1, pa: 600 }] },
    ] } });
    try {
      await view.getOrderedData();
      assert.equal(view.amt.notPayAmt, '1200.00');
      assert.equal(view.getDisplayPrice({ pp: 0, p2: 0 }), '时价');
    } finally { view.$destroy(); }
  });
}

for (const name of ['myOrder', 'newMyOrder']) {
  test(name + ' accounts for unpaid and settled discounts once, excluding gifts', async () => {
    const { view, respond } = createView(name);
    const unpaid = { id: 1, pid: 9, pp: 800, p2: 777, pa: 777, pc: 1, s: 1 };
    const settled = { id: 2, pid: 9, pp: 1000, p2: 200, pa: 200, pc: 1, s: 5 };
    const gift = { id: 3, pid: 9, pp: 800, p2: 0, pa: 0, pc: 1, at: 2, s: 1 };
    const cases = [
      [[unpaid], { order_amt: 80000, payed_val_amt: 0, payed_free_amt: 0 }, '23.00'],
      [[settled], { order_amt: 100000, payed_val_amt: 20000, payed_free_amt: 80000 }, '800.00'],
      [[unpaid, settled, gift], { order_amt: 180000, payed_val_amt: 20000, payed_free_amt: 80000, yh_amt: 80000 }, '823.00'],
      [[{ ...unpaid, p2: 0, pa: 0 }], { order_amt: 80000, payed_val_amt: 0, payed_free_amt: 0 }, '800.00'],
      [[], { order_amt: 0, payed_val_amt: 0, payed_free_amt: 10000 }, '0.00'],
      [[unpaid, settled, gift], { payed_free_amt: 80000, yh_amt: 80000 }, '823.00'],
      [[unpaid, gift], { order_amt: 80000, payed_val_amt: null, payed_free_amt: 0 }, '23.00'],
      [[gift], { yh_amt: 80000, payed_free_amt: 0 }, '0.00'],
    ];
    try {
      for (const [records, pay_info, discount] of cases) {
        respond({ code: 1, data: { records, pay_info } });
        await view.getOrderedData();
        assert.equal(view.amt.discountAmt, discount, JSON.stringify(pay_info));
      }
    } finally { view.$destroy(); }
  });
}
