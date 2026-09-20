const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const Vue = require('vue');
const read = file => fs.readFileSync(path.join(__dirname, '..', file), 'utf8');
const getFcPrice = Function(read('src/utils/fcPrice.js').replace(/export /g, '') + ';return getFcPrice;')();
const transformCardDataHandle = Function(read('src/utils/transformCardData.js').replace(/export /g, '') + ';return transformCardDataHandle;')();
const resResultDataArr = Function('return ' + read('src/utils/config/card.js').match(/export const resResultDataArr = (\[[\s\S]*?\n\])/)[1])();

function setup(cached = {}, options = {}) {
  const storage = new Map(Object.entries({ tk: 'test-token', refreshAllLocalTime: '20260916160000',
    websocketTimeMessageTime: '20260916160000', frontVersion: 'test', ...options.storage }));
  const state = Vue.observable({ cardPageInfo: { resResultDataObj: { areaInfo: [], ...cached } } });
  const calls = { full: 0, delta: 0, events: [] };
  const ds = { 14: [], 18: [['1']], 23: ['1'], 43: ['test'],
    58: [['9', '3', '77700', '1']], 59: [['3', '11', '1']] };
  const dependencies = {
    resResultDataArr, transformCardDataHandle, CODE_INVALID: 'invalid',
    window: { addEventListener() {} }, eventVue: { $emit(event) { calls.events.push(event); } }, console: { log() {} },
    localStorage: { getItem: key => storage.get(key), setItem: (key, value) => storage.set(key, value) },
    api_card: {
      async reqGetAllData() { calls.full++; return options.response || { code: 1, data: { ts: '20260916170000', ds } }; },
      async reqGetUpdateData() { calls.delta++; return { code: 1, data: { ts: '20260916170001', ds: {} } }; },
    },
    globalError: { handleError(error) { throw error; } },
  };
  const source = read('src/websocket/websocket.js').replace(/^import .*;\s*$/gm, '')
    .replace('export default class WebSocketClient', 'return class WebSocketClient');
  const Socket = Function(...Object.keys(dependencies), source)(...Object.values(dependencies));
  Socket.prototype.initAllData = function () {};
  const client = new Socket({ $set: Vue.set, $observer: { subscribe() {} }, $route: { name: 'test' },
    $message: { warning() {} }, $store: { state, commit(name, value) {
      if (name === 'updateResResultDataObj') state.cardPageInfo.resResultDataObj = value;
    } } });
  client.socket = { send() {} };
  client.websocketHasConnect = function () {};
  return { client, calls, state, ds };
}

test('old populated cache and advanced sync cursor must still fetch existing scheme metadata', async () => {
  const { client, calls, state } = setup();
  const view = new Vue({ computed: { price() { return getFcPrice(9, 11, 0, state.cardPageInfo.resResultDataObj); } } });
  assert.equal(view.price, null);
  await client.openHandle();
  await Vue.nextTick();
  assert.equal(calls.full, 1);
  assert.equal(calls.delta, 0);
  assert.equal(view.price, 777);
  await client.openHandle();
  assert.equal(calls.full, 1, 'a fully migrated cache resumes ordinary incremental sync');
  assert.equal(calls.delta, 1);
  view.$destroy();
});

test('empty arrays written by the earlier frontend are not proof of a complete full sync', async () => {
  const { client, calls } = setup({ fcProductPrices: [], fcPlanEmployees: [] });
  await client.getUpdateData();
  assert.equal(calls.full, 1);
  assert.equal(calls.delta, 0);
});

test('full-load default entry performs a request instead of reading the empty response placeholder', async () => {
  const { client, calls, state } = setup();
  await client.getAllData();
  assert.equal(calls.full, 1);
  assert.equal(getFcPrice(9, 11, 0, state.cardPageInfo.resResultDataObj), 777);
});

test('failed or incomplete snapshots must not mark the cache as having scheme data', async () => {
  for (const response of [{ code: 0, msg: 'test failure' }, { code: 1, data: {
    ts: '20260916170000', ds: { 18: [['1']], 23: ['1'], 43: ['test'] },
  } }]) {
    const { client, calls } = setup({}, { response });
    await client.openHandle();
    await client.openHandle();
    assert.equal(calls.full, 2);
    assert.equal(calls.delta, 0);
  }
});

for (const route of ['myOrder', 'oldMyOrder', 'payOrder']) {
  test(route + ' reloads recorded amounts once after current-table updates, not scheme updates', () => {
    const { client, calls, state } = setup({ businessData: [{ seatId: 31 }] });
    state.orderInfo = { currentCardInfo: { seatId: 31 } };
    client.vue.$route.name = route;
    client.updateTabListData = () => {};
    client.updateCardListData = () => {};
    const businessRow = id => [id, ...Array(33).fill('')];
    client.updateCardList({ 14: [businessRow(31), businessRow(32)] });
    assert.deepEqual(calls.events, [route === 'payOrder' ? 'reloadPayOrderList' : 'reloadMyOrderTableData']);
    calls.events.length = 0;
    client.updateCardList({ 14: [businessRow(32)] });
    client.updateCardList({ 58: [[9, 3, 12300, 1]], 59: [[3, 11, 1]] });
    assert.deepEqual(calls.events, []);
  });
}

const migratedSchemeCache = { fcPriceMetadataVersion: 1, fcProductPrices: [], fcPlanEmployees: [] };

for (const entry of ['openHandle', 'getUpdateData', 'getAllData']) {
  test(entry + ' refreshes old business amount cache once even with migrated scheme metadata', async () => {
    const { client, calls, state } = setup(migratedSchemeCache);
    await client[entry]();
    assert.equal(calls.full, 1);
    assert.equal(state.cardPageInfo.resResultDataObj.businessAmountMetadataVersion, 1);
    await client.getUpdateData();
    assert.equal(calls.full, 1);
    assert.equal(calls.delta, 1);
  });
}

test('business amount migration accepts old backend rows without discount column', async () => {
  const { client, calls, ds } = setup(migratedSchemeCache);
  ds[14] = [[31, ...Array(37).fill('')]];
  await client.openHandle();
  await client.openHandle();
  assert.equal(calls.full, 1);
  assert.equal(calls.delta, 1);
});

test('already migrated business amounts use incremental sync immediately', async () => {
  const { client, calls } = setup({ ...migratedSchemeCache, businessAmountMetadataVersion: 1, businessData: [] });
  await client.openHandle();
  assert.equal(calls.full, 0);
  assert.equal(calls.delta, 1);
});

test('failed or missing business snapshots cannot mark amount migration complete', async () => {
  for (const response of [{ code: 0 }, { code: 1, data: { ts: '20260916170000', ds: {
    18: [['1']], 23: ['1'], 43: ['test'], 58: [], 59: [],
  } } }]) {
    const { client, calls, state } = setup(migratedSchemeCache, { response });
    await client.openHandle();
    assert.notEqual(state.cardPageInfo.resResultDataObj.businessAmountMetadataVersion, 1);
    await client.openHandle();
    assert.equal(calls.full, 2);
  }
});
