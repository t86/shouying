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

function extractMethodBody(source, signature) {
  const signatureIndex = source.indexOf(signature);
  assert.notEqual(signatureIndex, -1, `missing method: ${signature}`);

  const bodyStart = source.indexOf('{', signatureIndex);
  let depth = 1;
  for (let index = bodyStart + 1; index < source.length; index += 1) {
    if (source[index] === '{') depth += 1;
    if (source[index] === '}') depth -= 1;
    if (depth === 0) return source.slice(bodyStart + 1, index);
  }

  assert.fail(`unterminated method: ${signature}`);
}

function compileCardMachineMethod(signature, args, dependencies = {}) {
  const source = readSource('src/views/Book/cardMachine.vue');
  const body = extractMethodBody(source, signature);
  const dependencyNames = Object.keys(dependencies);
  const factory = Function(
    ...dependencyNames,
    `return ${signature.startsWith('async ') ? 'async ' : ''}function(${args.join(', ')}) {${body}}`,
  );
  return factory(...dependencyNames.map(name => dependencies[name]));
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

test('consumption display helpers match newMyOrder monetary fallback behavior', () => {
  const { methods } = loadVueOptions('src/components/order/myOrder/readonlyConsumptionTable.vue');

  for (const p2 of [null, '', false, 0]) {
    assert.equal(methods.displayPrice({ pp: 12.5, p2 }), '12.50');
  }
  assert.equal(methods.displayPrice({ pp: 12.5, p2: 8 }), '8.00');
  assert.equal(methods.displayPrice({ pp: 0, p2: 8 }), '时价');

  assert.equal(methods.subtotal({ pp: 12.5, pc: 2, pa: null }), '25.00');
  assert.equal(methods.subtotal({ pp: 12.5, pc: 2, pa: undefined }), '25.00');
  assert.equal(methods.subtotal({ pp: 12.5, pc: 2, pa: 0 }), '0.00');
  assert.equal(methods.subtotal({ pp: 12.5, pc: 2, pa: 18 }), '18.00');
  assert.equal(methods.subtotal({ pp: 12.5, pc: 2, pa: null, at: 2 }), '0.00');
  assert.equal(methods.subtotal({ pp: 12.5, pc: 2, pa: null, at: 3 }), '0.00');
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

test('loading masks only the detail area so turnover tabs remain interactive', () => {
  const source = readSource('src/components/book/machine/bookingDetailDialog.vue');
  const template = source.match(/<template>([\s\S]*?)<\/template>/)[1];

  assert.match(template, /<div\s+class="detail-scroll"\s+v-loading="loading"\s*>/);
  assert.doesNotMatch(template, /class="booking-detail-content"[^>]*v-loading/);
  assert.match(template, /<div class="turnover-tabs">/);
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

test('footer close followed by Element dialog close emits input false exactly once', () => {
  const footer = createDialogHarness(() => Promise.resolve({ code: 1, data: {} }));
  footer.vm.requestClose();
  footer.vm.requestClose();
  footer.vm.closeDialog();
  assert.deepEqual(footer.emitted, [['input', false]]);

  const dialogChrome = createDialogHarness(() => Promise.resolve({ code: 1, data: {} }));
  dialogChrome.vm.closeDialog();
  assert.deepEqual(dialogChrome.emitted, [['input', false]]);
});

test('footer close button requests closure instead of running dialog cleanup directly', () => {
  const source = readSource('src/components/book/machine/bookingDetailDialog.vue');
  const template = source.match(/<template>([\s\S]*?)<\/template>/)[1];
  const footer = template.match(/<span slot="footer"[\s\S]*?<\/span>/)[0];

  assert.match(footer, /<el-button\s+@click="requestClose"\s*>\s*关闭\s*<\/el-button>/);
  assert.doesNotMatch(footer, /@click="closeDialog"/);
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

test('card options define exact booking detail entries at the menu tail', () => {
  const source = readSource('src/utils/config/card.js');

  assert.match(source, /id:\s*25[\s\S]*?id:\s*26,\s*\n\s*name:\s*'查看消费明细',\s*\n\s*icon:\s*icon3[\s\S]*?id:\s*27,\s*\n\s*name:\s*'查看存取酒明细',\s*\n\s*icon:\s*icon14/);
});

test('card machine registers the detail dialog and initializes access fail closed', () => {
  const source = readSource('src/views/Book/cardMachine.vue');

  assert.match(source, /<booking-detail-dialog\s+v-model="bookingDetailDialog\.visible"\s+:mode="bookingDetailDialog\.mode"\s+:card-info="bookingDetailDialog\.cardInfo"\s*\/>/);
  assert.match(source, /import bookingDetailDialog from ['"]@\/components\/book\/machine\/bookingDetailDialog\.vue['"];?/);
  assert.match(source, /import bookingDetailAccess from ['"]@\/utils\/bookingDetailAccess['"];?[\s\S]*?const\s*\{\s*getBookingDetailOptionIds,\s*normalizeBookingDetailConfig,?\s*\}\s*=\s*bookingDetailAccess;/);
  assert.match(source, /bookingDetailConfig:\s*normalizeBookingDetailConfig\(\)/);
  assert.match(source, /bookingDetailDialog:\s*\{\s*visible:\s*false,\s*mode:\s*['"]consumption['"],\s*cardInfo:\s*\{\},?\s*\}/);
  assert.match(source, /components:\s*\{[\s\S]*?bookingDetailDialog/);
  assert.match(source, /mounted\(\)\s*\{\s*this\.loadBookingDetailConfig\(\);/);
});

test('config loading fails closed and rebuilds cards only after a valid response', async () => {
  const bookingDetailAccess = require('../src/utils/bookingDetailAccess');
  const loadBookingDetailConfig = compileCardMachineMethod(
    'async loadBookingDetailConfig()',
    [],
    { normalizeBookingDetailConfig: bookingDetailAccess.normalizeBookingDetailConfig },
  );
  const cardInfo = [{ id: 88 }];
  const businessData = [{ seatId: 88, bizStatus: '4' }];
  const pending = deferred();
  const rebuilds = [];
  const vm = {
    bookingDetailConfig: bookingDetailAccess.normalizeBookingDetailConfig({
      limit_book_csm_amt: 2,
      enable_book_csm_dtl: 1,
      enable_book_wine_dtl: 1,
    }),
    $api: { BMS: { terminalRules: { reqGetTime: () => pending.promise } } },
    $store: { state: { cardPageInfo: { resResultDataObj: { cardInfo, businessData } } } },
    getCardList: (...args) => rebuilds.push(args),
  };

  const loading = loadBookingDetailConfig.call(vm);
  assert.deepEqual(vm.bookingDetailConfig, bookingDetailAccess.normalizeBookingDetailConfig());
  assert.deepEqual(rebuilds, []);

  pending.resolve({
    code: 1,
    data: { limit_book_csm_amt: 2, enable_book_csm_dtl: 1, enable_book_wine_dtl: 2 },
  });
  await loading;
  assert.deepEqual(vm.bookingDetailConfig, {
    amountsRestricted: false,
    consumptionEnabled: true,
    wineEnabled: false,
  });
  assert.deepEqual(rebuilds, [[cardInfo, businessData]]);

  vm.$api.BMS.terminalRules.reqGetTime = async () => ({
    code: 0,
    data: { limit_book_csm_amt: 2, enable_book_csm_dtl: 1, enable_book_wine_dtl: 1 },
  });
  await loadBookingDetailConfig.call(vm);
  assert.deepEqual(vm.bookingDetailConfig, bookingDetailAccess.normalizeBookingDetailConfig());
  assert.equal(rebuilds.length, 1);

  const originalConsoleLog = console.log;
  console.log = () => {};
  try {
    vm.$api.BMS.terminalRules.reqGetTime = async () => { throw new Error('network'); };
    await loadBookingDetailConfig.call(vm);
  } finally {
    console.log = originalConsoleLog;
  }
  assert.deepEqual(vm.bookingDetailConfig, bookingDetailAccess.normalizeBookingDetailConfig());
  assert.equal(rebuilds.length, 1);
});

test('detail options preserve status-menu order and precede pin actions', () => {
  const { getBookingDetailOptionIds } = require('../src/utils/bookingDetailAccess');
  const cardOptions = Array.from({ length: 27 }, (_, index) => ({ id: index + 1 }));
  const getCardOptions = compileCardMachineMethod(
    'getCardOptions(status, platform_id, showOnlineText, turnoverCnt, topNum)',
    ['status', 'platform_id', 'showOnlineText', 'turnoverCnt', 'topNum'],
    { getBookingDetailOptionIds, cardOptions },
  );
  const vm = {
    bookingDetailConfig: {
      amountsRestricted: false,
      consumptionEnabled: true,
      wineEnabled: true,
    },
    modelVisible: false,
    dateTab: { activeIndex: 0 },
    $store: { state: { cardPageInfo: { resResultDataObj: { showAmt: [] } } } },
  };

  assert.deepEqual(
    getCardOptions.call(vm, '4', 0, false, 6, 1).map(option => option.id),
    [10, 11, 7, 12, 14, 4, 20, 21, 23, 24, 26, 27, 18, 19],
  );
});

test('detail option clicks clone card info, select mode and return before the legacy drawer', async () => {
  const optionsClickHandle = compileCardMachineMethod(
    'async optionsClickHandle(optionsInfo, cardInfo, index)',
    ['optionsInfo', 'cardInfo', 'index'],
  );
  const sourceCard = { id: 88, name: 'A01', bizStatus: '4', turnoverCnt: 3 };
  const vm = {
    bookingDetailDialog: { visible: false, mode: 'consumption', cardInfo: {} },
    drawer: { showDrawer: false, cardInfo: {}, formStatus: 0 },
    showOrHideOptionHandle() {},
  };

  const originalConsoleLog = console.log;
  console.log = () => {};
  try {
    await optionsClickHandle.call(vm, { id: 26 }, sourceCard, 0);
  } finally {
    console.log = originalConsoleLog;
  }
  assert.deepEqual(vm.bookingDetailDialog, {
    visible: true,
    mode: 'consumption',
    cardInfo: sourceCard,
  });
  assert.notEqual(vm.bookingDetailDialog.cardInfo, sourceCard);
  assert.equal(vm.drawer.showDrawer, false);
  assert.deepEqual(sourceCard, { id: 88, name: 'A01', bizStatus: '4', turnoverCnt: 3 });

  vm.bookingDetailDialog.visible = false;
  console.log = () => {};
  try {
    await optionsClickHandle.call(vm, { id: 27 }, sourceCard, 0);
  } finally {
    console.log = originalConsoleLog;
  }
  assert.deepEqual(vm.bookingDetailDialog, {
    visible: true,
    mode: 'wine',
    cardInfo: sourceCard,
  });
  assert.notEqual(vm.bookingDetailDialog.cardInfo, sourceCard);
  assert.equal(vm.drawer.showDrawer, false);
});
