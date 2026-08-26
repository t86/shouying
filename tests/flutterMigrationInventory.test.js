const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

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

test('associates multiline calls with the owning declaration and excludes comments', () => {
  const source = [
    '  // reqComment: params => axios.post(`${base.htgl}/store/admin_items`, params),',
    '  reqGetGiveSaleCate: (params) =>',
    '    axios.get(`${base.htgl}/station/get_yh_priv`, params),',
    '  reqExportWine: (params) =>',
    '    axios.binaryFilePost(',
    '      `${base.htgl}/wine/rpt/export`, params),',
    '  /*',
    '  reqBlock: params => axios.post(`${base.htgl}/store/admin_items`, params),',
    '  */',
  ].join('\n');
  assert.deepEqual(extractApiCalls('src/api/example.js', source), [
    { symbol: 'reqGetGiveSaleCate', method: 'GET', baseKey: 'htgl', path: '/station/get_yh_priv', source: 'src/api/example.js:3' },
    { symbol: 'reqExportWine', method: 'POST', baseKey: 'htgl', path: '/wine/rpt/export', source: 'src/api/example.js:5' },
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

test('bounds nested route metadata to each route object', () => {
  const source = [
    '  {',
    "    path: '/parent', meta: { title: '' },",
    "    component: () => import('@/views/Parent.vue'),",
    '    children: [{',
    "      path: '/child', meta: { title: '子项' },",
    "      component: () => import('@/views/Child.vue')",
    '    }]',
    '  },',
    '  {',
    "    path: '/bare',",
    "    component: () => import('@/views/Bare.vue')",
    '  },',
  ].join('\n');
  assert.deepEqual(extractRoutes('src/router/example.js', source), [
    { path: '/parent', title: '', component: 'src/views/Parent.vue', source: 'src/router/example.js:2' },
    { path: '/child', title: '子项', component: 'src/views/Child.vue', source: 'src/router/example.js:5' },
    { path: '/bare', component: 'src/views/Bare.vue', source: 'src/router/example.js:10' },
  ]);
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

test('extracts active camel-case cues case-insensitively and ignores comments', () => {
  const source = [
    'const getAuthStatus = roleIds && cardWebsocketPath;',
    'const reqPrintYH2Order = atool.startQrCodeScan();',
    '// getAuthStatus cardWebsocketPath reqPrintYH2Order localStorage',
    '/* WebSocket permission sessionStorage */',
  ].join('\n');
  assert.deepEqual(extractCues('src/views/Example.vue', source), [
    { kind: 'permission', source: 'src/views/Example.vue:1' },
    { kind: 'websocket', source: 'src/views/Example.vue:1' },
    { kind: 'device', source: 'src/views/Example.vue:2' },
  ]);
});

test('traversal excludes generated/vendor files and symlinks', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'inventory-'));
  fs.mkdirSync(path.join(root, 'src', 'api'), { recursive: true });
  fs.mkdirSync(path.join(root, 'src', 'vendor'), { recursive: true });
  fs.mkdirSync(path.join(root, 'src', 'generated'), { recursive: true });
  fs.writeFileSync(path.join(root, 'src', 'api', 'active.js'), 'export default {}');
  fs.writeFileSync(path.join(root, 'src', 'vendor', 'ignored.js'), 'ignored');
  fs.writeFileSync(path.join(root, 'src', 'generated', 'ignored.js'), 'ignored');
  try {
    fs.symlinkSync(path.join(root, 'src', 'api', 'active.js'), path.join(root, 'src', 'link.js'));
  } catch (error) {
    fs.rmSync(root, { recursive: true, force: true });
    return;
  }
  const inventory = buildInventory(root);
  assert.deepEqual(inventory.apiModules, ['src/api/active.js']);
  assert.deepEqual(inventory.vueFiles, []);
  fs.rmSync(root, { recursive: true, force: true });
});

test('builds a stable repository inventory without generated metadata', () => {
  const inventory = buildInventory(process.cwd());
  assert.equal(inventory.schemaVersion, 1);
  assert.ok(inventory.routes.length >= 150);
  assert.ok(inventory.apiModules.length >= 60);
  assert.ok(inventory.routes.some((route) => route.path === '/moneyCard'));
  assert.ok(inventory.apiCalls.some((call) => call.path === '/auth/login'));
  assert.equal(Object.hasOwn(inventory, 'generatedAt'), false);
  const generated = JSON.parse(fs.readFileSync(
    path.join(process.cwd(), 'migration/flutter/generated/source-inventory.json'), 'utf8',
  ));
  assert.deepEqual(generated, inventory);
});
