const test = require('node:test');
const assert = require('node:assert/strict');

const {
  transformConsumptionRecords,
  normalizeOrderDetailResponse,
  getDetailCacheKey,
  createDetailRequestState,
} = require('../src/utils/orderDetailAdapter');

const lookups = {
  getProductInfo: (id) => (id === 1 ? { id, name: '主菜' } : undefined),
  getProductInfoFromGroup: (id) => (id === 11 ? { id, name: '套餐菜' } : undefined),
  getOrderPersonInfo: (id) => ({ id, name: `员工${id}` }),
};

test('enriches consumption rows, package children, and return rows without mutating API data', () => {
  const records = [{
    id: 'parent',
    pid: 1,
    wei: 9,
    ae: 8,
    is: 1,
    pc: 2,
    si: [{ i: 11 }],
    bs: [{ id: 'return', pc: 1, si: [{ i: 11, returned: true }] }],
  }];
  const snapshot = structuredClone(records);

  assert.deepEqual(transformConsumptionRecords(records, lookups), [
    {
      id: 'parent',
      pid: 1,
      wei: 9,
      ae: 8,
      is: 1,
      pc: 2,
      si: [{ i: 11, groupInfo: { id: 11, name: '套餐菜' } }],
      productInfo: { id: 1, name: '主菜' },
      personInfo: { id: 9, name: '员工9' },
      authInfo: { id: 8, name: '员工8' },
      showList: false,
    },
    {
      id: 'return',
      pid: 1,
      wei: 9,
      ae: 8,
      is: 1,
      pc: 1,
      si: [{ i: 11, returned: true, groupInfo: { id: 11, name: '套餐菜' } }],
      productInfo: { id: 1, name: '主菜' },
      personInfo: { id: 9, name: '员工9' },
      authInfo: { id: 8, name: '员工8' },
      showList: false,
      back: true,
    },
  ]);
  assert.deepEqual(records, snapshot);
});

test('uses self-service, lookup fallbacks, and parent package detail for return rows', () => {
  assert.deepEqual(transformConsumptionRecords([{
    id: 'returned-only',
    pid: 404,
    wei: 0,
    ae: 404,
    pc: 0,
    si: [{ i: 404 }],
    bs: [{ id: 'return-without-si' }],
  }], lookups), [{
    id: 'return-without-si',
    pid: 404,
    wei: 0,
    ae: 404,
    pc: 0,
    si: [{ i: 404, groupInfo: {} }],
    productInfo: {},
    personInfo: { name: '自助' },
    authInfo: { id: 404, name: '员工404' },
    showList: false,
    back: true,
  }]);
});

test('normalizes malformed parent and return package details to arrays without mutating input', () => {
  const records = [
    { id: 'malformed-parent', pc: 1, si: { unexpected: true } },
    {
      id: 'parent-with-malformed-return',
      pc: 0,
      si: [{ i: 11 }],
      bs: [{ id: 'malformed-return', si: { unexpected: true } }],
    },
  ];
  const snapshot = structuredClone(records);
  const rows = transformConsumptionRecords(records, lookups);

  assert.deepEqual(rows.map((row) => row.si), [[], []]);
  assert.equal(rows[1].back, true);
  assert.deepEqual(records, snapshot);
});

test('normalizes missing or malformed response data to safe defaults', () => {
  const safeResponse = {
    consumptionRows: [],
    wineRows: [],
    payInfo: { allAmt: '0.00', giveAmt: '0.00', notPayAmt: '0.00' },
  };

  assert.deepEqual(normalizeOrderDetailResponse(undefined, lookups), safeResponse);
  assert.deepEqual(normalizeOrderDetailResponse(null, lookups), safeResponse);
  assert.deepEqual(normalizeOrderDetailResponse({ records: {}, wine_ops: null, pay_info: null }, lookups), safeResponse);
});

test('normalizes wine rows and converts payment cents without exposing API arrays', () => {
  const data = {
    records: [],
    wine_ops: [{ id: 1 }],
    pay_info: { order_amt: 1234, yh_amt: 34, payed_amt: 200 },
  };
  const result = normalizeOrderDetailResponse(data, lookups);

  assert.deepEqual(result, {
    consumptionRows: [],
    wineRows: [{ id: 1 }],
    payInfo: { allAmt: '12.34', giveAmt: '0.34', notPayAmt: '10.34' },
  });
  assert.notEqual(result.wineRows, data.wine_ops);
});

test('creates stable cache keys', () => {
  assert.equal(getDetailCacheKey('100', 3), '100:3');
});

test('caches values and invalidates stale requests when cleared', () => {
  const state = createDetailRequestState();
  const first = state.startRequest();
  const second = state.startRequest();

  assert.equal(state.isCurrent(first), false);
  assert.equal(state.isCurrent(second), true);
  state.set('100:3', { id: 'cached' });
  assert.deepEqual(state.get('100:3'), { id: 'cached' });

  state.clear();
  assert.equal(state.get('100:3'), undefined);
  assert.equal(state.isCurrent(second), false);
  assert.equal(state.isCurrent(state.startRequest()), true);
});
