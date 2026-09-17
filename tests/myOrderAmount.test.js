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
  test(name + ' loads the screenshot rows and sums current subtotals without subtracting paid money twice', async () => {
    const { view, requests } = createView(name);
    try {
      assertAmounts(view, '0.00', '0.00');
      await view.getOrderedData();
      assert.deepEqual(JSON.parse(JSON.stringify(requests)), [{ seat_id: 31, turnover_cnt: 2 }]);
      assert.deepEqual(Array.from(view.orderList, row => view.getSubtotal(row)), ['777.00', '0.10', '600.00', '800.00']);
      assertAmounts(view, '2177.10', '1377.10');
      assert.equal(view.amountOrderList[2].pa, '800', 'display correction must preserve the API amount');
      assert.equal(view.amountOrderList[3].s, 5);
    } finally { view.$destroy(); }
  });

  test(name + ' keeps whole-table amount scope when actual permission filtering hides other employees', async () => {
    const { view } = createView(name);
    try {
      view.$store.state.userInfo.sys_modules = [6];
      await view.getOrderedData();
      assert.deepEqual(Array.from(view.orderList, row => row.id), [1, 2, 4]);
      assert.equal(view.amountOrderList.length, 4);
      assertAmounts(view, '2177.10', '1377.10');
    } finally { view.$destroy(); }
  });

  test(name + ' updates totals reactively for metadata and quantities while paid and returned prices remain recorded', async () => {
    const { view, respond } = createView(name);
    respond(response([
      ...screenshotRows().slice(0, 3),
      { id: 4, pid: 9, ae: 22, wei: 22, pp: 800, p2: 700, pa: 700, pc: 1, s: '5' },
      { id: 5, pid: 9, ae: 22, wei: 22, pp: 800, p2: 650, pa: 650, pc: 1, s: 1, back: true },
    ]));
    try {
      await view.getOrderedData();
      assertAmounts(view, '2077.10', '1377.10');
      assert.equal(view.getDisplayPrice(view.amountOrderList[3]), '700.00');
      assert.equal(view.getSubtotal(view.amountOrderList[4]), '650.00');
      view.$store.state.cardPageInfo.resResultDataObj.fcProductPrices[1].pay_amt = 50000;
      await Vue.nextTick();
      assertAmounts(view, '1977.10', '1277.10');
      assert.equal(view.getSubtotal(view.amountOrderList[3]), '700.00');
      assert.equal(view.getDisplayPrice(view.amountOrderList[4]), '650.00');
      view.amountOrderList[2].pc = 2;
      await Vue.nextTick();
      assertAmounts(view, '2477.10', '1777.10');
      view.$store.state.cardPageInfo.resResultDataObj.fcProductPrices[1].pay_amt = 0;
      await Vue.nextTick();
      assertAmounts(view, '1477.10', '777.10');
      view.$store.state.cardPageInfo.resResultDataObj.fcProductPrices = [];
      await Vue.nextTick();
      assertAmounts(view, '2277.10', '1577.10', '0.00');
    } finally { view.$destroy(); }
  });

  test(name + ' ignores gift, zero-quantity and return rows and preserves unmatched recorded amounts', async () => {
    const { view, respond } = createView(name);
    const rows = [
      { id: 1, pid: 9, ae: 22, wei: 22, pp: 800, pa: 800, pc: 1, at: 2, s: 1 },
      { id: 2, pid: 9, ae: 22, wei: 22, pp: 800, pa: 800, pc: 1, at: '3', s: 1 },
      { id: 3, pid: 99, ae: 22, wei: 22, pp: 800, pa: 800, pc: 0, s: 1 },
      { id: 4, pid: 99, ae: 22, wei: 22, pp: 800, pa: 800, pc: 0, s: 1, bs: [{ id: 5, pa: 800, pc: 1 }] },
      { id: 6, pid: 99, ae: 22, wei: 22, pp: 800, pa: '12.34', pc: 1, s: 1 },
      { id: 7, pid: 99, ae: 22, wei: 22, pp: 800, pa: 0, pc: 1, s: 1 },
    ];
    const data = response(rows);
    data.data.pay_info.yh_amt = 123;
    respond(data);
    try {
      await view.getOrderedData();
      assert.ok(view.amountOrderList.some(row => row.back), 'loader must expand API return rows');
      assertAmounts(view, '12.34', '12.34', '1.23');
    } finally { view.$destroy(); }
  });

  test(name + ' treats split paid and unpaid records independently and yields zero after all rows settle', async () => {
    const { view, respond } = createView(name);
    const rows = [
      { id: 8, pid: 9, ae: 22, wei: 22, pp: 800, pa: 800, pc: 1, s: 1 },
      { id: 8, pid: 9, ae: 22, wei: 22, pp: 800, pa: 800, pc: 1, s: 5 },
    ];
    respond(response(rows));
    try {
      await view.getOrderedData();
      assertAmounts(view, '1400.00', '600.00');
      view.amountOrderList[0].s = 5;
      await Vue.nextTick();
      assertAmounts(view, '1600.00', '0.00');
    } finally { view.$destroy(); }
  });

  test(name + ' clears previous totals after empty records and no-participation responses', async () => {
    const { view, respond } = createView(name);
    try {
      await view.getOrderedData();
      assertAmounts(view, '2177.10', '1377.10');
      respond(response([]));
      await view.getOrderedData();
      assertAmounts(view, '0.00', '0.00');
      assert.equal(view.orderList.length, 0);
      const data = response();
      data.data.pay_info.yh_amt = 100;
      respond(data);
      await view.getOrderedData();
      assertAmounts(view, '2177.10', '1377.10', '1.00');
      respond({ code: 2 });
      await view.getOrderedData();
      assertAmounts(view, '0.00', '0.00');
      assert.equal(view.orderList.length, 0);
      assert.equal(view.amountOrderList.length, 0);
    } finally { view.$destroy(); }
  });
}
