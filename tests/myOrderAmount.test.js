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
const summaryScope = {};
vm.runInNewContext(read('src/utils/orderSummary.js').replace(/export /g, ''), summaryScope);
const myOrderAmountMixin = loadMixin('src/components/order/myOrderAmountMixin.js', {calculateOrderSummary: summaryScope.calculateOrderSummary});
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
  test(name + ' uses the specified wo/list summary formulas in cents', async () => {
    const {view,respond}=createView(name);
    try {
      respond({code:1,data:{records:screenshotRows(),pay_info:{order_amt:380000,discount_amt:120000,payed_amt:60000,payed_free_amt:1000,yh_amt:123}}});
      await view.getOrderedData();
      assertAmounts(view,'5000.00','4400.00','1.23');
      assert.equal(view.amt.discountAmt,'1210.00');
      // API signed values are used as returned; never silently change addition to subtraction.
      respond({code:1,data:{records:[],pay_info:{order_amt:'380000',discount_amt:'120000',payed_amt:'-60000',payed_free_amt:'0',yh_amt:'0'}}});
      await view.getOrderedData();
      assertAmounts(view,'5000.00','3200.00');
      assert.equal(view.amt.discountAmt,'1200.00');
    } finally {view.$destroy();}
  });
  test(name + ' preserves zero and treats missing summary fields as zero without deriving from rows', async () => {
    const {view,respond}=createView(name);
    try {
      respond({code:1,data:{records:screenshotRows(),pay_info:{order_amt:0,discount_amt:0,payed_amt:0,payed_free_amt:0}}});
      await view.getOrderedData();assertAmounts(view,'0.00','0.00');assert.equal(view.amt.discountAmt,'0.00');
      respond({code:1,data:{records:screenshotRows()}});
      await view.getOrderedData();assertAmounts(view,'0.00','0.00');
      respond({code:2});await view.getOrderedData();assertAmounts(view,'0.00','0.00');
    } finally {view.$destroy();}
  });
  test(name + ' keeps recorded item prices and template valid', async () => {
    const {view}=createView(name);
    try {
      await view.getOrderedData();
      assert.equal(view.getDisplayPrice({pp:800,p2:0}),'0.00');
      assert.equal(view.getSubtotal({pp:800,p2:777,pa:700,pc:1}),'700.00');
      const template=compiler.parseComponent(read('src/views/Order/orderMeal/'+name+'.vue')).template.content;
      assert.deepEqual(compiler.compile(template).errors,[]);
    } finally {view.$destroy();}
  });
}
