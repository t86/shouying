const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

function load(relative, dependencies = {}) {
  const source = fs.readFileSync(path.join(__dirname, '..', relative), 'utf8');
  const exports = [...source.matchAll(/export (?:const|function) (\w+)/g)].map(match => match[1]);
  const code = source.replace(/^import[\s\S]*?;\s*$/gm, '').replace(/export /g, '');
  return Function(...Object.keys(dependencies), code + '\nreturn {' + exports.join(',') + '}')(...Object.values(dependencies));
}

function fixture() {
  return {
    fcPlanEmployees: [{ plan_id: '1', emp_id: '11', status: '1' }, { plan_id: '2', emp_id: '22', status: '1' }],
    fcProductPrices: [{ prd_id: '9', plan_id: '1', pay_amt: '3300', status: '1' }, { prd_id: '9', plan_id: '2', pay_amt: '6300', status: '1' }],
  };
}

test('author plan takes priority and waiter is used only when author is absent', () => {
  const { getFcPrice } = load('src/utils/fcPrice.js');
  const metadata = fixture();
  assert.equal(getFcPrice(9, 11, 22, metadata), 33);
  assert.equal(getFcPrice(9, 0, 22, metadata), 63);
  assert.equal(getFcPrice(9, null, 22, metadata), 63);
  assert.equal(getFcPrice(9, 99, 22, metadata), null);
  assert.equal(getFcPrice(10, 11, 22, metadata), null);
});

test('inactive metadata is ignored; zero prices are valid; invalid amounts are not free prices', () => {
  const { getFcPrice } = load('src/utils/fcPrice.js');
  const metadata = fixture();
  metadata.fcProductPrices[0].pay_amt = '0';
  assert.equal(getFcPrice(9, 11, 22, metadata), 0);
  for (const invalid of ['', null, 'NaN', '-1', '33.5']) {
    metadata.fcProductPrices[0].pay_amt = invalid;
    assert.equal(getFcPrice(9, 11, 22, metadata), null);
  }
  metadata.fcProductPrices[0].pay_amt = '3300';
  metadata.fcProductPrices[0].status = '3';
  assert.equal(getFcPrice(9, 11, 22, metadata), null);
  metadata.fcProductPrices[0].status = '1';
  metadata.fcPlanEmployees[0].status = '2';
  assert.equal(getFcPrice(9, 11, 22, metadata), null);
  assert.equal(getFcPrice(9, 11, 22, {}), null);
});

test('scheme overrides member/room prices, supports time-priced items and selected quantities', () => {
  const { getFcPrice } = load('src/utils/fcPrice.js');
  const functions = load('src/utils/orderItemPrice.js', { getFcPrice, getProductPrice: () => '80' });
  const ctx = fixture();
  const item = { pid: 9, ae: 11, wei: 22, pp: '100', p2: '80', pm: '70', pa: '160', pc: 2, at: 0 };
  assert.equal(functions.resolveUnitPrice(item, ctx), 33);
  assert.equal(functions.calcItemAmount(item, ctx), 66);
  assert.equal(functions.calcItemAmount({ ...item, changeCount: 1 }, ctx), 33);
  assert.equal(functions.calcItemAmount({ ...item, pp: '0' }, ctx), 66);
  assert.equal(functions.isTimePriceItem({ ...item, pp: '0' }, ctx), true, 'scheme prices must not allow splitting a time-priced item');
  assert.equal(functions.calcItemAmount({ ...item, at: 2 }, ctx), 0);
  assert.equal(functions.resolveUnitPrice(item, {}), 80);
  assert.equal(functions.calcRefundAmount(item, ctx), 160, 'refund retains the existing recorded-price path');
  const storeContext = functions.buildPriceContextFromStore({ state: { cardPageInfo: { resResultDataObj: ctx } } });
  assert.equal(functions.resolveUnitPrice(item, storeContext), 33);
});

test('metadata 58/59 transformation preserves composite ids, cents and status', () => {
  const { transformCardDataHandle } = load('src/utils/transformCardData.js');
  assert.deepEqual(transformCardDataHandle([['9', '1', '0', '1']], 58), [{ prd_id: '9', plan_id: '1', pay_amt: '0', status: '1' }]);
  assert.deepEqual(transformCardDataHandle([['1', '11', '3']], 59), [{ plan_id: '1', emp_id: '11', status: '3' }]);
});

test('WebSocket full/incremental metadata uses composite keys and reacts to insert, update and invalidation', async () => {
  const Vue = require('vue');
  const { getFcPrice } = load('src/utils/fcPrice.js');
  const { transformCardDataHandle } = load('src/utils/transformCardData.js');
  const config = fs.readFileSync(path.join(__dirname, '../src/utils/config/card.js'), 'utf8');
  const resResultDataArr = Function('return ' + config.match(/export const resResultDataArr = (\[[\s\S]*?\n\])/)[1])();
  assert.equal(resResultDataArr[58], 'fcProductPrices');
  assert.equal(resResultDataArr[59], 'fcPlanEmployees');
  const source = fs.readFileSync(path.join(__dirname, '../src/websocket/websocket.js'), 'utf8')
    .replace(/^import .*;\s*$/gm, '').replace('export default class WebSocketClient', 'return class WebSocketClient');
  const dependencies = { resResultDataArr, transformCardDataHandle, CODE_INVALID: 'invalid',
    window: { addEventListener() {} }, eventVue: { $emit() {} },
    globalError: { handleError(error) { throw error; } }, localStorage: { setItem() {} } };
  const Socket = Function(...Object.keys(dependencies), source)(...Object.values(dependencies));
  Socket.prototype.initAllData = function () {};
  const metadata = Vue.observable({});
  const client = new Socket({
    $set: Vue.set, $observer: { subscribe() {} }, $route: { name: 'test' },
    $store: { state: { cardPageInfo: { resResultDataObj: metadata } }, commit() {} },
  });
  const view = new Vue({ computed: { price: () => getFcPrice(9, 11, 0, metadata) } });
  assert.equal(view.price, null);
  // Full-load assignments use the same registered fields.
  metadata.fcPlanEmployees = transformCardDataHandle([['1', '11', '1']], 59);
  client.updateCardList({ 58: [['9', '1', '3300', '1'], ['9', '2', '6300', '1']] });
  await Vue.nextTick();
  assert.equal(view.price, 33);
  assert.equal(metadata.fcProductPrices.length, 2);
  client.updateCardList({ 58: [['9', '1', '0', '1']] });
  await Vue.nextTick();
  assert.equal(view.price, 0);
  assert.equal(metadata.fcProductPrices.length, 2);
  client.updateCardList({ 59: [['1', '11', '3'], ['2', '11', '1']] });
  await Vue.nextTick();
  assert.equal(view.price, 63);
  assert.equal(metadata.fcPlanEmployees.length, 2);
  client.updateCardList({ 58: [['9', '2', '6300', '2']] });
  await Vue.nextTick();
  assert.equal(view.price, null);
  view.$destroy();
});
