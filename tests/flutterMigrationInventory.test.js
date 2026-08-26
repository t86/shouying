const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const childProcess = require('node:child_process');

const {
  extractRoutes,
  extractApiCalls,
  extractCues,
  buildInventory,
} = require('../tools/flutter_migration_inventory/source_inventory');
const inventoryModule = require('../tools/flutter_migration_inventory/source_inventory');
const { validateLedgers } = require('../tools/flutter_migration_inventory/validate_ledgers');
const { buildReport, generateReport } = require('../tools/flutter_migration_inventory/generate_report');

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

test('keeps axios calls owned by the API method across control-flow blocks', () => {
  const source = [
    '  requestEmpList(data) {',
    '    if (data) {',
    '      return axios.post(`${base.htgl}/emp/list`, data);',
    '    }',
    '  },',
    '  requestNext(data) {',
    '    try { return axios.binaryFileGet(`${base.htgl}/emp/next`, data); }',
    '    catch (error) { return error; }',
    '  },',
    '  requestArrow: data => axios.post(`${base.htgl}/emp/arrow`, data),',
  ].join('\n');
  assert.deepEqual(extractApiCalls('src/api/example.js', source), [
    { symbol: 'requestEmpList', method: 'POST', baseKey: 'htgl', path: '/emp/list', source: 'src/api/example.js:3' },
    { symbol: 'requestNext', method: 'GET', baseKey: 'htgl', path: '/emp/next', source: 'src/api/example.js:7' },
    { symbol: 'requestArrow', method: 'POST', baseKey: 'htgl', path: '/emp/arrow', source: 'src/api/example.js:10' },
  ]);
  assert.equal(extractApiCalls('src/api/example.js', source).some((call) => ['if', 'try', 'catch'].includes(call.symbol)), false);
});

test('masks JavaScript and Vue comments while preserving comment-like strings', () => {
  const source = [
    'const url = "// sessionStorage authStatus";',
    "const html = '<!-- print WebSocket -->';",
    'const live = true; // sessionStorage authStatus',
    '/*',
    '  <!-- authStatus print axios.post(`${base.htgl}/commented`, data) -->',
    '*/',
    '<!--',
    '  authStatus print axios.post(`${base.htgl}/html`, data)',
    '-->',
    'const active = getAuthStatus && cardWebsocketPath; reqPrintYH2Order();',
  ].join('\n');
  const cues = extractCues('src/views/newFootBar.vue', source);
  assert.deepEqual(cues, [
    { kind: 'permission', source: 'src/views/newFootBar.vue:10' },
    { kind: 'websocket', source: 'src/views/newFootBar.vue:10' },
    { kind: 'device', source: 'src/views/newFootBar.vue:10' },
  ]);
  assert.equal(extractApiCalls('src/views/example.vue', source).length, 0);
  for (const file of ['src/views/newFootBar.vue:110', 'src/views/authorizationWithNoPwd.vue:14', 'src/views/authorizationWithNoPwd.vue:30', 'src/views/sind.vue:546']) {
    assert.equal(cues.some((cue) => cue.source === file), false);
  }
});

test('keeps active Vue directive expressions visible to cue extraction', () => {
  assert.deepEqual(extractCues('x.vue', '<div v-if="$store.state.userInfo.authStatus === 4">'), [
    { kind: 'permission', source: 'x.vue:1' },
  ]);
  assert.deepEqual(extractCues('x.vue', '<!-- <div v-if="$store.state.userInfo.authStatus === 4"> -->'), []);
});

test('handles escaped template backticks without masking following active cues', () => {
  const source = [
    'const text = `escaped \\` // not a comment ${value}`;',
    'const live = localStorage.getItem("x"); new WebSocket(url);',
  ].join('\n');
  assert.deepEqual(extractCues('x.vue', source), [
    { kind: 'storage', source: 'x.vue:2' },
    { kind: 'websocket', source: 'x.vue:2' },
  ]);
});

test('keeps the active newFootBar directive while excluding known HTML comments', () => {
  const inventory = buildInventory(process.cwd());
  assert.equal(inventory.cues.some((cue) => cue.source === 'src/components/order/newFootBar.vue:114' && cue.kind === 'permission'), true);
  for (const source of ['src/views/newFootBar.vue:110', 'src/views/authorizationWithNoPwd.vue:14', 'src/views/authorizationWithNoPwd.vue:30', 'src/views/sind.vue:546']) {
    assert.equal(inventory.cues.some((cue) => cue.source === source), false);
  }
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

test('extracts compact routes and parent properties after children without child bleed', () => {
  const source = [
    "{path:'/compact',name:'compact',component:()=>import('@/views/Compact.vue'),meta:{title:'紧凑'}},",
    "{path:'/ordered',children:[{path:'/nested',meta:{title:'子'},component:()=>import('@/views/Nested.vue')}],component:()=>import('@/views/Ordered.vue'),meta:{title:'父'}},",
  ].join('\n');
  assert.deepEqual(extractRoutes('src/router/example.js', source), [
    { path: '/compact', name: 'compact', title: '紧凑', component: 'src/views/Compact.vue', source: 'src/router/example.js:1' },
    { path: '/ordered', title: '父', component: 'src/views/Ordered.vue', source: 'src/router/example.js:2' },
    { path: '/nested', title: '子', component: 'src/views/Nested.vue', source: 'src/router/example.js:2' },
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

test('traversal excludes generated/vendor files and symlinks', (t) => {
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
    t.skip(`symlink unsupported: ${error.code || error.message}`);
    return;
  }
  try {
    fs.symlinkSync(path.join(root, 'src', 'api'), path.join(root, 'src', 'nested-link'));
  } catch (error) {
    fs.rmSync(root, { recursive: true, force: true });
    t.skip(`nested symlink unsupported: ${error.code || error.message}`);
    return;
  }
  const inventory = buildInventory(root);
  assert.deepEqual(inventory.apiModules, ['src/api/active.js']);
  assert.deepEqual(inventory.vueFiles, []);
  fs.rmSync(root, { recursive: true, force: true });
});

test('rejects a symlinked top-level src directory', (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'inventory-root-'));
  const realSrc = fs.mkdtempSync(path.join(os.tmpdir(), 'inventory-src-'));
  try {
    fs.symlinkSync(realSrc, path.join(root, 'src'));
  } catch (error) {
    fs.rmSync(root, { recursive: true, force: true });
    fs.rmSync(realSrc, { recursive: true, force: true });
    t.skip(`symlink unsupported: ${error.code || error.message}`);
    return;
  }
  assert.throws(() => buildInventory(root), /src directory must be real and contained/);
  fs.rmSync(root, { recursive: true, force: true });
  fs.rmSync(realSrc, { recursive: true, force: true });
});

test('builds a stable repository inventory without generated metadata', () => {
  const inventory = buildInventory(process.cwd());
  assert.equal(inventory.schemaVersion, 1);
  assert.ok(inventory.routes.length >= 150);
  assert.ok(inventory.apiModules.length >= 60);
  assert.ok(inventory.routes.some((route) => route.path === '/moneyCard'));
  assert.ok(inventory.apiCalls.some((call) => call.path === '/auth/login'));
  assert.equal(Object.hasOwn(inventory, 'generatedAt'), false);
  const generatedText = fs.readFileSync(
    path.join(process.cwd(), 'migration/flutter/generated/source-inventory.json'), 'utf8',
  );
  assert.equal(generatedText, `${JSON.stringify(inventory, null, 2)}\n`);
});

test('migration ledgers have unique ids, valid source references, and explicit platform scope', () => {
  const result = validateLedgers(process.cwd());
  assert.deepEqual(result.errors, []);
  assert.ok(result.capabilityCount >= 5);
  assert.ok(result.protocolCount >= 5);
  assert.ok(result.permissionCount >= 3);
});

test('protocol ledgers preserve typed login mode and websocket message direction', () => {
  const protocols = JSON.parse(fs.readFileSync(path.join(process.cwd(), 'migration/flutter/protocols.json'), 'utf8'));
  const login = protocols.find((protocol) => protocol.id === 'HTTP-AUTH-LOGIN');
  assert.deepEqual(login.request.body.pt, { type: 'number', allowed: [1, 2] });
  const sync = protocols.find((protocol) => protocol.id === 'WS-SYNC');
  assert.equal(sync.request.payload, 'JSON.stringify(tk)');
  assert.deepEqual(sync.response.envelope, { p: 'string', t: 'string', d: 'object' });
  assert.equal(Object.hasOwn(sync.request, 'envelope'), false);
});

function writeLedgerFixture(t, mutate) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'flutter-ledgers-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  fs.mkdirSync(path.join(root, 'migration', 'flutter'), { recursive: true });
  fs.mkdirSync(path.join(root, 'src'), { recursive: true });
  fs.writeFileSync(path.join(root, 'src', 'feature.js'), 'export default {}');
  const ledgers = {
    capabilities: [{
      id: 'CAP-001', name: 'Test capability', domain: 'test', sources: ['src/feature.js'], protocols: ['PRO-001'], permissions: [],
      platforms: { windows: 'required', web: 'degraded', android: 'required' }, status: 'defined',
    }],
    protocols: [{ id: 'PRO-001', kind: 'http', method: 'GET', path: '/test', request: {}, response: {}, sources: ['src/feature.js'], status: 'defined' }],
    permissions: [],
  };
  mutate?.(ledgers);
  for (const [name, data] of Object.entries(ledgers)) {
    fs.writeFileSync(path.join(root, 'migration', 'flutter', `${name}.json`), `${JSON.stringify(data, null, 2)}\n`);
  }
  return root;
}

test('reports duplicate IDs with ledger and ID', (t) => {
  const root = writeLedgerFixture(t, (ledgers) => { ledgers.capabilities.push({ ...ledgers.capabilities[0] }); });
  assert.match(validateLedgers(root).errors.join('\n'), /capabilities\.json\[1\]: duplicate id CAP-001/);
});

test('reports missing source files', (t) => {
  const root = writeLedgerFixture(t, (ledgers) => { ledgers.capabilities[0].sources = ['src/missing.js']; });
  assert.match(validateLedgers(root).errors.join('\n'), /capabilities\.json\[0\]: CAP-001 source does not exist: src\/missing\.js/);
});

test('reports unknown protocol and permission references', (t) => {
  const root = writeLedgerFixture(t, (ledgers) => {
    ledgers.capabilities[0].protocols = ['PRO-MISSING'];
    ledgers.capabilities[0].permissions = ['PERM-MISSING'];
  });
  const errors = validateLedgers(root).errors.join('\n');
  assert.match(errors, /CAP-001 references unknown protocol PRO-MISSING/);
  assert.match(errors, /CAP-001 references unknown permission PERM-MISSING/);
});

test('reports missing and invalid platform scope', (t) => {
  const root = writeLedgerFixture(t, (ledgers) => {
    delete ledgers.capabilities[0].platforms.web;
    ledgers.capabilities[0].platforms.windows = 'maybe';
  });
  const errors = validateLedgers(root).errors.join('\n');
  assert.match(errors, /CAP-001 platforms must contain exactly windows, web, android/);
  assert.match(errors, /CAP-001 platform windows has invalid scope maybe/);
});

test('reports missing platform key and invalid status', (t) => {
  const root = writeLedgerFixture(t, (ledgers) => {
    delete ledgers.capabilities[0].platforms;
    ledgers.protocols[0].status = 'unknown';
  });
  const errors = validateLedgers(root).errors.join('\n');
  assert.match(errors, /capabilities\.json\[0\]: missing required field platforms/);
  assert.match(errors, /protocols\.json\[0\]: invalid status unknown/);
});

test('rejects malformed records in every ledger without throwing', (t) => {
  const root = writeLedgerFixture(t, (ledgers) => {
    ledgers.capabilities = [null, [], 'scalar', { id: 'CAP-MISSING' }];
    ledgers.protocols = [null, [], 'scalar', { id: 'PRO-MISSING' }];
    ledgers.permissions = [null, [], 'scalar', { id: 'PERM-MISSING' }];
  });
  const result = validateLedgers(root);
  assert.ok(result.errors.length > 0);
  assert.equal(result.errors.every((error) => /(?:capabilities|protocols|permissions)\.json\[\d+\]/.test(error)), true);
});

test('returns exact deterministic errors for a multi-error malformed fixture', (t) => {
  const root = writeLedgerFixture(t, (ledgers) => {
    ledgers.capabilities = [null, { id: 'CAP-BAD' }];
    ledgers.protocols = [{ id: 'PRO-BAD', status: 'unknown' }];
    ledgers.permissions = ['bad'];
  });
  assert.deepEqual(validateLedgers(root).errors, [
    'capabilities.json[0]: record must be an object',
    'capabilities.json[1]: domain must be a non-empty string without control characters',
    'capabilities.json[1]: missing required field domain',
    'capabilities.json[1]: missing required field permissions',
    'capabilities.json[1]: missing required field platforms',
    'capabilities.json[1]: missing required field protocols',
    'capabilities.json[1]: missing required field sources',
    'capabilities.json[1]: missing required field status',
    'capabilities.json[1]: name must be a non-empty string without control characters',
    'capabilities.json[1]: permissions must be an array',
    'capabilities.json[1]: protocols must be an array',
    'capabilities.json[1]: sources must be an array',
    'permissions.json[0]: record must be an object',
    'protocols.json[0]: invalid status unknown',
    'protocols.json[0]: kind must be http or websocket',
    'protocols.json[0]: missing required field kind',
    'protocols.json[0]: missing required field path',
    'protocols.json[0]: missing required field request',
    'protocols.json[0]: missing required field response',
    'protocols.json[0]: missing required field sources',
    'protocols.json[0]: path must be a non-empty string without control characters',
    'protocols.json[0]: request must be an object',
    'protocols.json[0]: response must be an object',
    'protocols.json[0]: sources must be an array',
  ]);
});

test('rejects schema violations, control characters and duplicate relations', (t) => {
  const root = writeLedgerFixture(t, (ledgers) => {
    ledgers.capabilities[0].id = 'bad id';
    ledgers.capabilities[0].name = 'bad\nname';
    ledgers.capabilities[0].sources = ['src/feature.js', 'src/feature.js'];
    ledgers.capabilities[0].protocols = ['PRO-001', 'PRO-001'];
    ledgers.capabilities[0].permissions = [1];
    ledgers.protocols[0].kind = 'tcp';
    ledgers.protocols.push({ ...ledgers.protocols[0], id: 'PRO-002', kind: 'http', method: 'DELETE' });
    ledgers.protocols[0].request = 'body';
  });
  const errors = validateLedgers(root).errors;
  assert.ok(errors.some((error) => error.includes('id must match')));
  assert.ok(errors.some((error) => error.includes('name must be a non-empty string without control characters')));
  assert.ok(errors.some((error) => error.includes('sources contains duplicate value')));
  assert.ok(errors.some((error) => error.includes('protocols contains duplicate value')));
  assert.ok(errors.some((error) => error.includes('permissions must contain only strings')));
  assert.ok(errors.some((error) => error.includes('kind must be http or websocket')));
  assert.ok(errors.some((error) => error.includes('method must be GET or POST')));
  assert.ok(errors.some((error) => error.includes('request must be an object')));
});

test('distinguishes references to declared-invalid records from unknown records', (t) => {
  const root = writeLedgerFixture(t, (ledgers) => {
    ledgers.protocols[0].id = 'PRO-001';
    ledgers.protocols[0].kind = 'bad';
    ledgers.permissions.push({ id: 'PERM-001', name: 'x', sources: ['src/feature.js'], status: 'bad', rule: 'x' });
    ledgers.capabilities[0].protocols = ['PRO-001', 'PRO-MISSING'];
    ledgers.capabilities[0].permissions = ['PERM-001', 'PERM-MISSING'];
  });
  const errors = validateLedgers(root).errors.join('\n');
  assert.match(errors, /references invalid protocol PRO-001/);
  assert.match(errors, /references unknown protocol PRO-MISSING/);
  assert.match(errors, /references invalid permission PERM-001/);
  assert.match(errors, /references unknown permission PERM-MISSING/);
});

test('rejects POSIX, Windows, UNC, traversal and symlink source paths', (t) => {
  const root = writeLedgerFixture(t, (ledgers) => {
    ledgers.capabilities[0].sources = ['/etc/passwd', 'C:\\secret.js', '\\\\server\\share\\x', '../escape.js'];
  });
  const errors = validateLedgers(root).errors.join('\n');
  assert.match(errors, /absolute source path/);
  assert.match(errors, /drive-letter source path/);
  assert.match(errors, /UNC source path/);
  assert.match(errors, /traversal source path/);
});

test('buildReport escapes backslashes, pipes and newlines and sorts by code units', () => {
  const report = buildReport([
    { id: 'Z', domain: 'a\\b|c\nd', platforms: { windows: 'required', web: 'degraded', android: 'required' }, status: 'defined', protocols: [], permissions: [], sources: [] },
    { id: 'A', domain: 'safe', platforms: { windows: 'required', web: 'required', android: 'required' }, status: 'defined', protocols: [], permissions: [], sources: [] },
  ], [], []);
  assert.ok(report.indexOf('| A |') < report.indexOf('| Z |'));
  assert.match(report, /a\\\\b\\\|c\\n?d/);
});

test('CLI success and failures have deterministic exit behavior', (t) => {
  const root = writeLedgerFixture(t);
  const validator = path.join(process.cwd(), 'tools/flutter_migration_inventory/validate_ledgers.js');
  const generator = path.join(process.cwd(), 'tools/flutter_migration_inventory/generate_report.js');
  const success = childProcess.spawnSync(process.execPath, [validator], { cwd: process.cwd(), encoding: 'utf8' });
  assert.equal(success.status, 0);
  assert.equal(success.stderr, '');
  const bad = path.join(root, 'migration/flutter/capabilities.json');
  fs.writeFileSync(bad, '{}\n');
  const failure = childProcess.spawnSync(process.execPath, [validator], { cwd: root, encoding: 'utf8' });
  assert.equal(failure.status, 1);
  assert.doesNotMatch(failure.stderr, /TypeError|at /);
  const genFailure = childProcess.spawnSync(process.execPath, [generator], { cwd: root, encoding: 'utf8' });
  assert.equal(genFailure.status, 1);
  assert.doesNotMatch(genFailure.stderr, /TypeError|at /);
});

test('generator preserves an existing report and refuses a symlink target', (t) => {
  const root = writeLedgerFixture(t);
  const output = path.join(root, 'migration/flutter/generated/coverage.md');
  fs.mkdirSync(path.dirname(output), { recursive: true });
  const target = path.join(root, 'outside.md');
  fs.writeFileSync(target, 'sentinel\n');
  fs.symlinkSync(target, output);
  const result = generateReport(root);
  assert.equal(result.errors.length, 1);
  assert.match(result.errors[0], /must not be a symlink/);
  assert.equal(fs.readFileSync(target, 'utf8'), 'sentinel\n');
});
