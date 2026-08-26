const test = require('node:test');
const assert = require('node:assert/strict');

const {
  extractRoutes,
  extractApiCalls,
  extractCues,
  buildInventory,
} = require('../tools/flutter_migration_inventory/source_inventory');
const inventoryModule = require('../tools/flutter_migration_inventory/source_inventory');

test('extracts a route and its nearby metadata', () => {
  const source = [
    '  {',
    "    path: '/moneyCard', name: 'moneyCard', meta: { title: '收银' },",
    "    component: () => import('@/views/Money/moneyCard.vue') },",
  ].join('\n');

  assert.deepEqual(extractRoutes('src/router/money/index.js', source), [{
    path: '/moneyCard',
    name: 'moneyCard',
    title: '收银',
    component: 'src/views/Money/moneyCard.vue',
    source: 'src/router/money/index.js:2',
  }]);
});

test('extracts axios API calls and base key', () => {
  const result = extractApiCalls(
    'src/api/Book/index.js',
    'reqGetAllData: params => axios.post(`${base.htgl}/sync_base/all`, params),',
  );

  assert.deepEqual(result, [{
    symbol: 'reqGetAllData',
    method: 'POST',
    baseKey: 'htgl',
    path: '/sync_base/all',
    source: 'src/api/Book/index.js:1',
  }]);
});

test('extracts indented and multiline arrow API declarations', () => {
  const source = [
    '  reqFoo: params => axios.post(`${base.htgl}/foo`, params),',
    '  reqBar: params =>',
    '    axios.get(`${base.auth}/bar`, params),',
  ].join('\n');
  assert.deepEqual(extractApiCalls('src/api/example.js', source), [
    { symbol: 'reqFoo', method: 'POST', baseKey: 'htgl', path: '/foo', source: 'src/api/example.js:1' },
    { symbol: 'reqBar', method: 'GET', baseKey: 'auth', path: '/bar', source: 'src/api/example.js:3' },
  ]);
});

test('maps binary methods and retains method-style API declarations', () => {
  const source = [
    '  exportFile(data) {',
    '    return axios.binaryFileGet(`${base.htgl}/export`, data);',
    '  },',
    '  importFile(data) {',
    '    return axios.binaryFilePost(`${base.htgl}/import`, data);',
    '  },',
  ].join('\n');
  assert.deepEqual(extractApiCalls('src/api/example.js', source), [
    { symbol: 'exportFile', method: 'GET', baseKey: 'htgl', path: '/export', source: 'src/api/example.js:2' },
    { symbol: 'importFile', method: 'POST', baseKey: 'htgl', path: '/import', source: 'src/api/example.js:5' },
  ]);
});

test('ignores routes inside block comments while preserving real source lines', () => {
  const source = [
    '/*',
    "  path: '/ignored-unstarred', component: () => import('@/views/No.vue')",
    '*/',
    '/*',
    " * path: '/ignored-starred', component: () => import('@/views/No.vue')",
    ' */',
    '  {',
    "    path: '/real', name: 'real', meta: { title: '真实' },",
    "    component: () => import('@/views/Real.vue') },",
  ].join('\n');
  assert.deepEqual(extractRoutes('src/router/example.js', source), [{
    path: '/real', name: 'real', title: '真实', component: 'src/views/Real.vue', source: 'src/router/example.js:8',
  }]);
});

test('exports only the inventory public API', () => {
  assert.deepEqual(Object.keys(inventoryModule).sort(), [
    'buildInventory', 'extractApiCalls', 'extractCues', 'extractRoutes',
  ]);
});

test('extracts cues in deterministic rule order, including multiple cues per line', () => {
  const source = [
    'const roleIds = authStatus && localStorage.getItem("roles");',
    'const ws = new WebSocket(url); sessionStorage.setItem("x", "y");',
    'atool.startQrCodeScan(); card_scan(); print();',
  ].join('\n');

  assert.deepEqual(extractCues('src/views/Example.vue', source), [
    { kind: 'permission', source: 'src/views/Example.vue:1' },
    { kind: 'storage', source: 'src/views/Example.vue:1' },
    { kind: 'storage', source: 'src/views/Example.vue:2' },
    { kind: 'websocket', source: 'src/views/Example.vue:2' },
    { kind: 'device', source: 'src/views/Example.vue:3' },
  ]);
});

test('builds a stable repository inventory without generated metadata', () => {
  const inventory = buildInventory(process.cwd());
  assert.equal(inventory.schemaVersion, 1);
  assert.ok(inventory.routes.length >= 150);
  assert.ok(inventory.apiModules.length >= 60);
  assert.ok(inventory.routes.some((route) => route.path === '/moneyCard'));
  assert.ok(inventory.apiCalls.some((call) => call.path === '/auth/login'));
  assert.equal(Object.hasOwn(inventory, 'generatedAt'), false);
});
