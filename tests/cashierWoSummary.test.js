const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const parser = require('@babel/parser');
const compiler = require('vue-template-compiler');
const page = compiler.parseComponent(fs.readFileSync('src/views/Money/payOrder.vue', 'utf8'));
function methods(api) {
  const ast = parser.parse(page.script.content, { sourceType: 'module' });
  const options = ast.program.body.find(n => n.type === 'ExportDefaultDeclaration').declaration;
  const value = options.properties.find(n => n.key.name === 'methods').value;
  return vm.runInNewContext('(' + page.script.content.slice(value.start, value.end) + ')', { api_order: api });
}
function context(api) {
  return { ...methods(api), orderSummaryRequestId: 0, orderSummaryInfo: null, orderSummaryKey: '',
    $store: { state: { orderInfo: { currentCardInfo: { seatId: 2 } } } },
    turnOverInfo: { activeTurnOverCount: 1 } };
}
test('cashier summary requests wo/list for selected seat and turnover', async () => {
  let params;
  const info = { discount_amt: 120000, order_amt: 380000, payed_amt: 60000 };
  const ctx = context({ reqGetOrderList: async p => { params = p; return { code: 1, data: { pay_info: info } }; } });
  await ctx.loadOrderSummary();
  assert.equal(params.seat_id, 2);
  assert.equal(params.turnover_cnt, 1);
  assert.equal(ctx.orderSummaryInfo, info);
});
test('late responses cannot overwrite newer requests or another seat/turnover', async () => {
  const resolves = [];
  const ctx = context({ reqGetOrderList: () => new Promise(resolve => resolves.push(resolve)) });
  const first = ctx.loadOrderSummary();
  const second = ctx.loadOrderSummary();
  resolves[1]({ code: 1, data: { pay_info: { order_amt: 20 } } });
  await second;
  resolves[0]({ code: 1, data: { pay_info: { order_amt: 10 } } });
  await first;
  assert.equal(ctx.orderSummaryInfo.order_amt, 20);
  const third = ctx.loadOrderSummary();
  ctx.turnOverInfo.activeTurnOverCount = 0;
  resolves[2]({ code: 1, data: { pay_info: { order_amt: 30 } } });
  await third;
  assert.equal(ctx.orderSummaryInfo, null);
});
test('failed or missing summaries remain unavailable rather than showing zero', async () => {
  for (const response of [{ code: 0 }, { code: 1, data: {} }]) {
    const ctx = context({ reqGetOrderList: async () => response });
    await ctx.loadOrderSummary();
    assert.equal(ctx.orderSummaryInfo, null);
  }
  const ctx = context({ reqGetOrderList: async () => { throw new Error('offline'); } });
  await ctx.loadOrderSummary();
  assert.equal(ctx.orderSummaryInfo, null);
});
test('cashier template shows all four summary values and still compiles', () => {
  for (const name of ['allAmt', 'giveAmt', 'discountAmt']) assert.match(page.template.content, new RegExp('orderSummary\\.' + name));
  assert.match(page.template.content, /unpaidOrderAmount/);
  assert.deepEqual(compiler.compile(page.template.content).errors, []);
});
