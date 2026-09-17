const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const root = path.join(__dirname, '..');

function fixture() {
  let now = 1000;
  const store = {
    state: { requestInfo: {} },
    commit(type, value) {
      assert.equal(type, 'updateRequestInfo');
      this.state.requestInfo = value;
    },
  };
  class TestDate extends Date {
    constructor() { super(now); }
  }
  const throttleSource = fs.readFileSync(path.join(root, 'src/request/intercept.js'), 'utf8')
    .replace(/^import store[^\n]*\n/m, '')
    .replace('export const canRequest', 'const canRequest');
  const canRequest = vm.runInNewContext(throttleSource + '\ncanRequest;', {
    store,
    Date: TestDate,
  });
  const calls = [];
  const apiSource = fs.readFileSync(path.join(root, 'src/api/money/index.js'), 'utf8')
    .replace(/^import base[^\n]*\n/m, '')
    .replace(/^import axios[^\n]*\n/m, '')
    .replace('export default', 'module.exports =');
  const module = { exports: {} };
  vm.runInNewContext(apiSource, {
    module,
    base: { htgl: 'https://example.test/api' },
    axios: {
      async post(url, params) {
        if (!canRequest(url)) throw new Error('request throttled');
        calls.push({ url, params });
        return { code: 1, data: { seat_id: params.seat_id } };
      },
    },
  });
  return { canRequest, api: module.exports, calls, store, advance(ms) { now += ms; } };
}

test('concurrent homepage card reads and an immediate detail read all pass the real URL throttle', async () => {
  const { api, calls, store } = fixture();
  const params = [
    { seat_id: 3, turnover_cnt: 0 },
    { seat_id: 4, turnover_cnt: 0 },
    { seat_id: 5, turnover_cnt: 1 },
    { seat_id: 3, turnover_cnt: 0 },
  ];
  const responses = await Promise.all(params.map(item => api.reqGetCardPayInfo(item)));
  assert.deepEqual(responses.map(response => response.data.seat_id), [3, 4, 5, 3]);
  assert.deepEqual(calls.map(call => call.params), params);
  assert.equal(Object.keys(store.state.requestInfo).length, 0, 'read queries do not reserve the URL throttle slot');
});

test('payment writes retain duplicate protection while unrelated endpoints remain independent', async () => {
  const { api, canRequest, advance } = fixture();
  await api.reqPayOrder({ seat_id: 3 });
  await assert.rejects(api.reqPayOrder({ seat_id: 4 }), /request throttled/);
  const otherEndpoint = 'https://example.test/api/prd/list';
  assert.equal(canRequest(otherEndpoint), true);
  assert.equal(canRequest(otherEndpoint), false, 'existing same-millisecond duplicate behavior stays intact');
  advance(1);
  await api.reqPayOrder({ seat_id: 4 });
  assert.equal(canRequest(otherEndpoint), true);
});

test('only the exact read endpoint is exempt, including a query string or fragment', () => {
  const { canRequest, advance } = fixture();
  for (const url of [
    'sel/csm_orders',
    '/sel/csm_orders',
    'https://example.test/api/sel/csm_orders',
    'https://example.test/api/sel/csm_orders?seat_id=3',
    'https://example.test/api/sel/csm_orders#details',
  ]) {
    assert.equal(canRequest(url), true);
    assert.equal(canRequest(url), true);
  }
  const differentEndpoint = 'https://example.test/api/sel/csm_orders_back';
  assert.equal(canRequest(differentEndpoint), true);
  assert.equal(canRequest(differentEndpoint), false);
  advance(100);
  assert.equal(canRequest(differentEndpoint), false, 'the prior interval for other matching URLs is preserved');
  advance(1);
  assert.equal(canRequest(differentEndpoint), true);
});

test('order-home detail reads allow concurrent cards while order mutations retain duplicate protection', () => {
  const { canRequest } = fixture();
  for (const url of ['wo/list', '/wo/list', 'https://example.test/api/wo/list?seat_id=3']) {
    assert.equal(canRequest(url), true);
    assert.equal(canRequest(url), true);
    assert.equal(canRequest(url), true, 'opening the order detail immediately is also allowed');
  }
  for (const path of ['wo/back', 'wo/yh_prd', 'wo/list_other']) {
    const url = 'https://example.test/api/' + path;
    assert.equal(canRequest(url), true);
    assert.equal(canRequest(url), false);
  }
});
