const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const test = require('node:test');

const readSource = relativePath => fs.readFileSync(
  path.join(__dirname, '..', relativePath),
  'utf8',
);

function loadVueOptions(relativePath, dependencies = {}) {
  const source = readSource(relativePath);
  const scriptMatch = source.match(/<script>([\s\S]*?)<\/script>/);
  assert.ok(scriptMatch, `${relativePath} must contain a script block`);

  const script = scriptMatch[1]
    .replace(/^import\s+[^;]+;\s*$/gm, '')
    .replace(/export default/, 'return');
  const names = Object.keys(dependencies);
  return Function(...names, script)(...names.map(name => dependencies[name]));
}

function deferred() {
  let resolve;
  let reject;
  const promise = new Promise((resolvePromise, rejectPromise) => {
    resolve = resolvePromise;
    reject = rejectPromise;
  });
  return { promise, resolve, reject };
}

function flushPromises() {
  return new Promise(resolve => setImmediate(resolve));
}

function createDialogHarness(responseFactory) {
  const calls = [];
  const warnings = [];
  const emitted = [];
  const bindingChecks = [];
  const commonOrder = {
    getProductInfo(value) {
      bindingChecks.push(this === commonOrder);
      return { name: `product-${value}` };
    },
    getProductInfoFromGroup(value) {
      bindingChecks.push(this === commonOrder);
      return { name: `group-${value}` };
    },
  };
  const commonBook = {
    getOrderPersonInfo(value) {
      bindingChecks.push(this === commonBook);
      return { name: `person-${value}` };
    },
  };
  const bookingDetailAccess = require('../src/utils/bookingDetailAccess');
  const actualAdapter = require('../src/utils/orderDetailAdapter');
  const orderDetailAdapter = {
    ...actualAdapter,
    normalizeOrderDetailResponse(data, lookups) {
      lookups.getProductInfo(1);
      lookups.getProductInfoFromGroup(2);
      lookups.getOrderPersonInfo(3);
      return actualAdapter.normalizeOrderDetailResponse(data, lookups);
    },
  };
  const apiOrder = {
    reqGetOrderList(params) {
      calls.push(params);
      return responseFactory(params, calls.length);
    },
  };
  const options = loadVueOptions('src/components/book/machine/bookingDetailDialog.vue', {
    apiOrder,
    commonBook,
    commonOrder,
    bookingDetailAccess,
    orderDetailAdapter,
    readonlyConsumptionTable: {},
    readonlyWineTable: {},
  });
  const vm = {
    value: true,
    mode: 'consumption',
    cardInfo: { id: '88', name: 'A01', turnoverCnt: 3 },
    $message: { warning: message => warnings.push(message) },
    $emit: (...args) => emitted.push(args),
    ...options.data(),
  };

  Object.entries(options.methods).forEach(([name, method]) => {
    vm[name] = method.bind(vm);
  });
  Object.entries(options.computed).forEach(([name, computed]) => {
    const getter = typeof computed === 'function' ? computed : computed.get;
    Object.defineProperty(vm, name, { configurable: true, get: () => getter.call(vm) });
  });

  return { bindingChecks, calls, emitted, options, vm, warnings };
}

test('readonly tables expose required columns and display fields without actions', () => {
  const consumption = readSource('src/components/order/myOrder/readonlyConsumptionTable.vue');
  const wine = readSource('src/components/order/myOrder/readonlyWineTable.vue');

  ['状态', '名称', '数量', '单价(元)', '小计(元)', '服务员', '点单时间'].forEach(label => {
    assert.ok(consumption.includes(label), `missing consumption label: ${label}`);
  });
  ['productInfo', 'item.pc', 'item.p2', 'item.pp', 'item.pa', 'personInfo', 'item.ot', 'item.si'].forEach(field => {
    assert.match(consumption, new RegExp(field.replace('.', '\\.')));
  });
  ['结', '退', '惠', '惠2', '暂无数据'].forEach(label => assert.match(consumption, new RegExp(label)));
  assert.doesNotMatch(consumption, /退单|批量优惠|打印消费单|\$emit|\$store|\$route|@click/);

  ['类型', '名称', '规格', '数量', '存\/取酒操作人', '存\/取酒操作时间'].forEach(label => {
    assert.match(wine, new RegExp(label));
  });
  ['item.t', 'item.p', 'item.u', 'item.c', 'item.n', 'item.o', '存', '取', '暂无数据'].forEach(field => {
    assert.match(wine, new RegExp(field.replace('.', '\\.')));
  });
  assert.doesNotMatch(wine, /\$emit|\$store|\$route|@click/);
});

test('readonly tables accept rows as their only prop', () => {
  const consumption = loadVueOptions('src/components/order/myOrder/readonlyConsumptionTable.vue');
  const wine = loadVueOptions('src/components/order/myOrder/readonlyWineTable.vue');

  assert.deepEqual(Object.keys(consumption.props), ['rows']);
  assert.deepEqual(Object.keys(wine.props), ['rows']);
  assert.deepEqual(consumption.props.rows.default(), []);
  assert.deepEqual(wine.props.rows.default(), []);
});

test('booking dialog exposes the exact read-only shell and mode contract', () => {
  const source = readSource('src/components/book/machine/bookingDetailDialog.vue');
  const { options } = createDialogHarness(() => Promise.resolve({ code: 1, data: {} }));

  assert.deepEqual(Object.keys(options.props), ['value', 'mode', 'cardInfo']);
  assert.equal(options.props.mode.validator('consumption'), true);
  assert.equal(options.props.mode.validator('wine'), true);
  assert.equal(options.props.mode.validator('other'), false);
  assert.match(source, /<el-dialog/);
  assert.match(source, /查看消费明细/);
  assert.match(source, /查看存取酒明细/);
  assert.match(source, /readonly-consumption-table/);
  assert.match(source, /readonly-wine-table/);
  assert.match(source, /buildTurnoverTabs/);
  assert.match(source, /reqGetOrderList/);
  assert.match(source, /getDetailCacheKey/);
  assert.match(source, /createDetailRequestState/);
  assert.match(source, /normalizeOrderDetailResponse/);
  assert.doesNotMatch(source, /\$router|\$route|\$store|currentCardInfo|退单|批量优惠|打印消费单/);
});

test('opening builds newest-first tabs, selects newest and normalizes bound lookups', async () => {
  const { bindingChecks, calls, options, vm } = createDialogHarness(() => Promise.resolve({
    code: 1,
    data: { records: [{ id: 1, pid: 1, wei: 3 }], wine_ops: [{ id: 'wine' }] },
  }));

  options.watch.value.call(vm, true);
  await flushPromises();

  assert.deepEqual(vm.turnoverTabs.map(tab => tab.turnoverCnt), [3, 2, 1]);
  assert.equal(vm.selectedTurnoverCnt, 3);
  assert.deepEqual(calls, [{ seat_id: 88, turnover_cnt: 3 }]);
  assert.equal(vm.consumptionRows.length, 1);
  assert.deepEqual(vm.wineRows, [{ id: 'wine' }]);
  assert.ok(bindingChecks.length >= 3);
  assert.equal(bindingChecks.every(Boolean), true);
  assert.equal(vm.loading, false);
});

test('switching tabs lazy-loads and caches successful responses by seat and turnover', async () => {
  const { calls, vm } = createDialogHarness(params => Promise.resolve({
    code: 1,
    data: { records: [{ id: `row-${params.turnover_cnt}` }] },
  }));

  await vm.openDialog();
  await vm.selectTurnover(2);
  await vm.selectTurnover(3);

  assert.deepEqual(calls, [
    { seat_id: 88, turnover_cnt: 3 },
    { seat_id: 88, turnover_cnt: 2 },
  ]);
  assert.equal(vm.consumptionRows[0].id, 'row-3');
  assert.equal(vm.loading, false);
});

test('cache hits supersede in-flight requests without leaving loading stuck', async () => {
  const slow = deferred();
  const { calls, vm } = createDialogHarness((params) => {
    if (params.turnover_cnt === 2) return slow.promise;
    return Promise.resolve({ code: 1, data: { records: [{ id: 'cached-newest' }] } });
  });

  await vm.openDialog();
  const pending = vm.selectTurnover(2);
  assert.equal(vm.loading, true);
  await vm.selectTurnover(3);
  assert.equal(vm.loading, false);
  assert.equal(vm.consumptionRows[0].id, 'cached-newest');

  slow.resolve({ code: 1, data: { records: [{ id: 'stale' }] } });
  await pending;
  assert.equal(vm.consumptionRows[0].id, 'cached-newest');
  assert.equal(vm.loading, false);
  assert.equal(calls.length, 2);
});

test('stale responses cannot overwrite the currently selected turnover', async () => {
  const older = deferred();
  const newer = deferred();
  const { vm } = createDialogHarness(params => (
    params.turnover_cnt === 3 ? older.promise : newer.promise
  ));

  const first = vm.openDialog();
  const second = vm.selectTurnover(2);
  older.resolve({ code: 1, data: { records: [{ id: 'stale-3' }] } });
  await first;
  assert.deepEqual(vm.consumptionRows, []);
  assert.equal(vm.loading, true);

  newer.resolve({ code: 1, data: { records: [{ id: 'current-2' }] } });
  await second;
  assert.equal(vm.consumptionRows[0].id, 'current-2');
  assert.equal(vm.loading, false);
});

test('closing clears data and cache, invalidates requests and emits input false', async () => {
  const pendingResponse = deferred();
  const { calls, emitted, vm } = createDialogHarness((params, callNumber) => (
    callNumber === 1 ? Promise.resolve({ code: 1, data: { records: [{ id: 'cached' }] } }) : pendingResponse.promise
  ));

  await vm.openDialog();
  const pending = vm.selectTurnover(2);
  vm.closeDialog();
  assert.deepEqual(vm.consumptionRows, []);
  assert.deepEqual(vm.wineRows, []);
  assert.deepEqual(vm.payInfo, { allAmt: '0.00', giveAmt: '0.00', notPayAmt: '0.00' });
  assert.equal(vm.loading, false);
  assert.deepEqual(emitted, [['input', false]]);

  pendingResponse.resolve({ code: 1, data: { records: [{ id: 'late' }] } });
  await pending;
  assert.deepEqual(vm.consumptionRows, []);

  await vm.openDialog();
  assert.equal(calls.length, 3, 'reopening must not reuse the previous dialog session cache');
});

test('ordinary API failures warn, show empty data, stop loading and keep dialog open', async () => {
  const { emitted, vm, warnings } = createDialogHarness(() => Promise.resolve({ code: 0, msg: '服务失败' }));
  vm.consumptionRows = [{ id: 'old' }];

  await vm.openDialog();

  assert.deepEqual(vm.consumptionRows, []);
  assert.deepEqual(warnings, ['服务失败']);
  assert.deepEqual(emitted, []);
  assert.equal(vm.loading, false);
});

test('thrown API errors warn, show empty data, stop loading and keep dialog open', async () => {
  const originalConsoleError = console.error;
  console.error = () => {};
  try {
    const { emitted, vm, warnings } = createDialogHarness(() => Promise.reject(new Error('network')));
    vm.wineRows = [{ id: 'old' }];

    await vm.openDialog();

    assert.deepEqual(vm.wineRows, []);
    assert.deepEqual(warnings, ['明细获取失败']);
    assert.deepEqual(emitted, []);
    assert.equal(vm.loading, false);
  } finally {
    console.error = originalConsoleError;
  }
});

test('dialog styles are scoped under detail roots and include required layout values', () => {
  const source = readSource('src/style/book/machine/bookingDetailDialog.less');

  assert.match(source, /\.booking-detail-dialog\s*\{/);
  assert.match(source, /\.readonly-detail-table\s*\{/);
  assert.match(source, /width:\s*90vw/);
  assert.match(source, /min-height:\s*520px/);
  assert.match(source, /#20a0d8/i);
  assert.match(source, /repeat\(7,/);
  assert.match(source, /repeat\(6,/);
  assert.match(source, /overflow-y:\s*auto/);
  assert.match(source, /\.badge/);
  assert.match(source, /\.set-detail/);
  assert.match(source, /\.detail-empty/);
  assert.doesNotMatch(source, /^(?!\s|\.booking-detail-dialog|\.readonly-detail-table|\/|\*|$)[^{\n]+\{/m);
});
