# Flutter 迁移基线与跨平台底座 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立可审计的 Vue 迁移基线和可运行的 Windows、Web、Android Flutter 底座，并用真实登录、WebSocket、扫码和测试小票验证迁移关卡 A/B/C。

**Architecture:** 本计划只实现批准设计中的阶段 0 和阶段 1。现有 Vue 保持不变；新增 `migration/flutter` 台账、`flutter_workspace` Pub workspace、共享协议/会话/权限/实时同步包、平台设备适配包和三个薄应用壳。业务页面、收银闭环及 ERP/BMS 等领域分别在可行性通过后编写独立计划。

**Tech Stack:** Flutter 3.47.0、Dart Pub workspace、Riverpod、go_router、Dio、web_socket_channel、crypto、printing/pdf、flutter_secure_storage、Node.js 内建测试、GitLab CI。

---

## Scope and execution rules

- Work from a dedicated worktree created with `superpowers:using-git-worktrees`; do not implement directly in the dirty `dev` worktree.
- Branch name: `feature/flutter-foundation`.
- Preserve the existing Vue build and runtime behavior. Root Vue `package.json` is not modified by this plan.
- Never commit account passwords, machine authorization codes, `tk`, `stk`, payment codes, member PII, captured production payloads, or diagnostic logs.
- All runtime fixtures committed to the repository are synthetic or explicitly sanitized.
- Use FVM 4.3.0 to pin Flutter 3.47.0. The repository lockfile, not floating dependency constraints, is the resolved dependency source of truth.
- The plan stops after the feasibility report. It does not implement order creation, payment, refund, inventory writes, silent ESC/POS, or full sync dataset transformation.

## Planned file map

### Migration control plane

- `migration/flutter/README.md`: ledger rules, statuses, platform meanings, review workflow.
- `migration/flutter/capabilities.json`: user-visible capability ledger.
- `migration/flutter/protocols.json`: HTTP/WebSocket contract ledger.
- `migration/flutter/permissions.json`: permission-source ledger.
- `migration/flutter/generated/source-inventory.json`: deterministic static inventory.
- `migration/flutter/generated/coverage.md`: generated coverage summary.
- `tools/flutter_migration_inventory/source_inventory.js`: route/API/state/permission extraction.
- `tools/flutter_migration_inventory/validate_ledgers.js`: schema and cross-reference validation.
- `tools/flutter_migration_inventory/generate_report.js`: deterministic Markdown report.
- `tests/flutterMigrationInventory.test.js`: Node tests for extraction and ledgers.

### Flutter workspace

- `flutter_workspace/.fvmrc`: Flutter SDK pin.
- `.gitignore`: generated Flutter/FVM artifacts.
- `flutter_workspace/pubspec.yaml`: root Pub workspace and shared dependency resolution.
- `flutter_workspace/pubspec.lock`: committed exact dependency resolution.
- `flutter_workspace/analysis_options.yaml`: shared analyzer rules.
- `flutter_workspace/apps/{windows_app,web_app,android_app}`: thin platform shells.
- `flutter_workspace/packages/foundation`: result, failure, connection state, redaction.
- `flutter_workspace/packages/protocol`: exact HTTP request compatibility.
- `flutter_workspace/packages/session`: terminal authorization and employee login.
- `flutter_workspace/packages/realtime_sync`: `/sync` lifecycle and reconciliation state.
- `flutter_workspace/packages/permissions`: role/module normalization and decisions.
- `flutter_workspace/packages/design_system`: shared status and diagnostic UI.
- `flutter_workspace/packages/device_bridge_platform_interface`: scanner/printer contracts.
- `flutter_workspace/packages/device_bridge_windows`: Windows device implementation.
- `flutter_workspace/packages/device_bridge_android`: Android device implementation.
- `flutter_workspace/packages/device_bridge_web`: Web device implementation.
- `flutter_workspace/tool/verify_boundaries.js`: architectural import guard.
- `flutter_workspace/tool/check.sh`: Linux/macOS/Web/Android quality command.
- `flutter_workspace/tool/check.ps1`: Windows quality command.
- `.gitlab-ci.yml`: Web/Android and Windows jobs.
- `docs/flutter-migration/feasibility-report.md`: evidence for gates A/B/C.

## Approved-spec coverage

| Approved design section | This plan |
| --- | --- |
| Platform positioning and shared-core structure | Tasks 3, 4, 10 |
| Protocol compatibility | Tasks 1, 2, 6, 7 |
| Permission model | Tasks 2 and 8 |
| Scanner and printer boundaries | Task 11 |
| Online-only and reconciliation behavior | Tasks 5, 9, 10 |
| Migration ledgers | Tasks 1 and 2 |
| Stage 0 baseline | Tasks 1 and 2 |
| Stage 1 feasibility | Tasks 3 through 13 |
| Contract, permission, integration, and parity tests | Tasks 2, 6 through 13 |
| Typed errors | Tasks 5, 6, 9, 11 |
| Flutter Web same-origin constraints | Tasks 10, 12, 13 |
| Dependency, branch, CI, observability, and drift rules | Tasks 3, 4, 10, 12, 13 |
| Gates A/B/C | Task 13 |
| Windows cashier vertical slice and later business domains | Deliberately excluded; each receives a separate plan after Task 13 passes |

## Task 1: Build deterministic Vue source inventory

**Files:**
- Create: `tools/flutter_migration_inventory/source_inventory.js`
- Create: `tests/flutterMigrationInventory.test.js`
- Create: `migration/flutter/generated/source-inventory.json`

- [ ] **Step 1: Write failing extraction tests**

Create `tests/flutterMigrationInventory.test.js` with focused synthetic sources before scanning the real repository:

```js
const assert = require('node:assert/strict');
const test = require('node:test');
const {
  extractRoutes,
  extractApiCalls,
  extractCues,
  buildInventory,
} = require('../tools/flutter_migration_inventory/source_inventory');

test('extractRoutes reads path, name, title, and component from router source', () => {
  const source = `
    { path: '/moneyCard', name: 'moneyCard', meta: { title: '收银' },
      component: () => import('@/views/Money/moneyCard.vue') }
  `;
  assert.deepEqual(extractRoutes('src/router/money/index.js', source), [{
    path: '/moneyCard',
    name: 'moneyCard',
    title: '收银',
    component: 'src/views/Money/moneyCard.vue',
    source: 'src/router/money/index.js:2',
  }]);
});

test('extractApiCalls records request method, base key, and endpoint', () => {
  const source = "reqGetAllData: params => axios.post(`${base.htgl}/sync_base/all`, params),";
  assert.deepEqual(extractApiCalls('src/api/Book/index.js', source), [{
    symbol: 'reqGetAllData',
    method: 'POST',
    baseKey: 'htgl',
    path: '/sync_base/all',
    source: 'src/api/Book/index.js:1',
  }]);
});

test('extractCues records permission, storage, websocket, and device locations', () => {
  const source = `
    if (user.roleIds.includes(5)) localStorage.setItem('tk', token);
    const socket = new WebSocket(url);
    atool.startQrCodeScan();
  `;
  const cues = extractCues('src/example.js', source);
  assert.deepEqual(cues.map(cue => cue.kind), [
    'permission', 'storage', 'websocket', 'device',
  ]);
});

test('buildInventory discovers the current repository without timestamps', () => {
  const inventory = buildInventory(process.cwd());
  assert.equal(inventory.schemaVersion, 1);
  assert.ok(inventory.routes.length >= 150);
  assert.ok(inventory.apiModules.length >= 60);
  assert.ok(inventory.routes.some(route => route.path === '/moneyCard'));
  assert.ok(inventory.apiCalls.some(call => call.path === '/auth/login'));
  assert.equal(Object.hasOwn(inventory, 'generatedAt'), false);
});
```

- [ ] **Step 2: Run the focused test and verify failure**

Run: `node --test tests/flutterMigrationInventory.test.js`

Expected: FAIL with `Cannot find module '../tools/flutter_migration_inventory/source_inventory'`.

- [ ] **Step 3: Implement the inventory extractor**

Create `tools/flutter_migration_inventory/source_inventory.js`. Use only Node built-ins. Export the four functions used by the tests and a CLI entry point. The key behavior is:

```js
const fs = require('node:fs');
const path = require('node:path');

function lineNumber(source, offset) {
  return source.slice(0, offset).split('\n').length;
}

function toSourcePath(component) {
  return component.startsWith('@/') ? `src/${component.slice(2)}` : component;
}

function extractRoutes(file, source) {
  const lines = source.split('\n');
  const routes = [];
  for (let index = 0; index < lines.length; index += 1) {
    const pathMatch = lines[index].match(/^\s*path:\s*['"`]([^'"`]+)['"`]/);
    if (!pathMatch || lines[index].trimStart().startsWith('//')) continue;
    const window = lines.slice(index, index + 18).join('\n');
    const name = window.match(/\bname:\s*['"]([^'"]+)['"]/);
    const title = window.match(/\btitle:\s*['"]([^'"]*)['"]/);
    const component = window.match(/['"](@\/[^'"]+\.vue)['"]/);
    routes.push({
      path: pathMatch[1],
      name: name ? name[1] : '',
      title: title ? title[1] : '',
      component: component ? toSourcePath(component[1]) : '',
      source: `${file}:${index + 1}`,
    });
  }
  return routes;
}

function extractApiCalls(file, source) {
  const calls = [];
  const pattern = /([A-Za-z_$][\w$]*)\s*(?::|\([^)]*\)\s*\{)[\s\S]{0,180}?axios\.(post|get|binaryFilePost|binaryFileGet)\(\s*`\$\{base\.([\w]+)\}([^`]+)`/g;
  for (const match of source.matchAll(pattern)) {
    const transport = match[2];
    calls.push({
      symbol: match[1],
      method: transport.toLowerCase().includes('get') ? 'GET' : 'POST',
      baseKey: match[3],
      path: match[4],
      source: `${file}:${lineNumber(source, match.index)}`,
    });
  }
  return calls;
}

const cueRules = [
  ['permission', /authStatus|roleIds|sub_permissions|sysRole|permission/i],
  ['storage', /localStorage|sessionStorage/],
  ['websocket', /WebSocket|websocket/i],
  ['device', /\batool\b|startQrCodeScan|card_scan|print/i],
];

function extractCues(file, source) {
  const cues = [];
  source.split('\n').forEach((line, index) => {
    for (const [kind, pattern] of cueRules) {
      if (pattern.test(line)) cues.push({ kind, source: `${file}:${index + 1}` });
    }
  });
  return cues;
}

function walk(root, directory, predicate, result = []) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const absolute = path.join(directory, entry.name);
    if (entry.isDirectory()) walk(root, absolute, predicate, result);
    if (entry.isFile() && predicate(absolute)) result.push(path.relative(root, absolute));
  }
  return result.sort();
}

function buildInventory(root) {
  const codeFiles = walk(root, path.join(root, 'src'), file => /\.(js|vue)$/.test(file));
  const routerFiles = codeFiles.filter(file => file.startsWith('src/router/') && file.endsWith('.js'));
  const apiModules = codeFiles.filter(file => file.startsWith('src/api/') && file.endsWith('.js'));
  const read = file => fs.readFileSync(path.join(root, file), 'utf8');
  return {
    schemaVersion: 1,
    vueFiles: codeFiles.filter(file => file.endsWith('.vue')),
    routes: routerFiles.flatMap(file => extractRoutes(file, read(file))),
    apiModules,
    apiCalls: apiModules.flatMap(file => extractApiCalls(file, read(file))),
    cues: codeFiles.flatMap(file => extractCues(file, read(file))),
  };
}

if (require.main === module) {
  const root = path.resolve(__dirname, '../..');
  const output = path.join(root, 'migration/flutter/generated/source-inventory.json');
  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, `${JSON.stringify(buildInventory(root), null, 2)}\n`);
}

module.exports = { extractRoutes, extractApiCalls, extractCues, buildInventory };
```

- [ ] **Step 4: Run the focused test and generate the inventory**

Run:

```bash
node --test tests/flutterMigrationInventory.test.js
node tools/flutter_migration_inventory/source_inventory.js
```

Expected: tests PASS and `migration/flutter/generated/source-inventory.json` contains `/moneyCard`, `/auth/login`, storage cues, WebSocket cues, and device cues.

- [ ] **Step 5: Verify deterministic output**

Run:

```bash
cp migration/flutter/generated/source-inventory.json /tmp/shouyin-source-inventory.json
node tools/flutter_migration_inventory/source_inventory.js
cmp /tmp/shouyin-source-inventory.json migration/flutter/generated/source-inventory.json
```

Expected: `cmp` exits 0 with no output.

- [ ] **Step 6: Commit**

```bash
git add tools/flutter_migration_inventory/source_inventory.js tests/flutterMigrationInventory.test.js migration/flutter/generated/source-inventory.json
git commit -m "test: inventory Vue migration sources"
```

## Task 2: Create validated migration ledgers and coverage report

**Files:**
- Create: `migration/flutter/README.md`
- Create: `migration/flutter/capabilities.json`
- Create: `migration/flutter/protocols.json`
- Create: `migration/flutter/permissions.json`
- Create: `tools/flutter_migration_inventory/validate_ledgers.js`
- Create: `tools/flutter_migration_inventory/generate_report.js`
- Modify: `tests/flutterMigrationInventory.test.js`
- Create: `migration/flutter/generated/coverage.md`

- [ ] **Step 1: Add failing ledger validation tests**

Append tests that load all three ledgers and assert:

```js
const {
  validateLedgers,
} = require('../tools/flutter_migration_inventory/validate_ledgers');

test('migration ledgers have unique ids, valid source references, and explicit platform scope', () => {
  const result = validateLedgers(process.cwd());
  assert.deepEqual(result.errors, []);
  assert.ok(result.capabilityCount >= 5);
  assert.ok(result.protocolCount >= 5);
  assert.ok(result.permissionCount >= 3);
});
```

- [ ] **Step 2: Run the test and verify failure**

Run: `node --test tests/flutterMigrationInventory.test.js`

Expected: FAIL because `validate_ledgers.js` and ledger files do not exist.

- [ ] **Step 3: Create the initial ledgers**

Create machine-readable JSON with no secrets. Initial capability IDs are:

```json
[
  {
    "id": "AUTH-TERM-001",
    "name": "终端授权",
    "domain": "session",
    "sources": ["src/views/Thelogin/Thelogin.vue", "src/api/UtilAuth/term/index.js"],
    "protocols": ["HTTP-TERM-AUTH"],
    "permissions": [],
    "platforms": {"windows": "required", "web": "required", "android": "required"},
    "status": "defined"
  },
  {
    "id": "AUTH-LOGIN-001",
    "name": "员工登录",
    "domain": "session",
    "sources": ["src/views/Thelogin/Thelogin.vue", "src/api/UtilAuth/auth/index.js"],
    "protocols": ["HTTP-AUTH-LOGIN"],
    "permissions": ["PERM-ROLE-001"],
    "platforms": {"windows": "required", "web": "required", "android": "required"},
    "status": "defined"
  },
  {
    "id": "SYNC-CONNECT-001",
    "name": "实时同步连接与恢复",
    "domain": "realtime_sync",
    "sources": ["src/websocket/websocket.js", "src/api/Book/index.js"],
    "protocols": ["WS-SYNC", "HTTP-SYNC-ALL", "HTTP-SYNC-INCREMENT"],
    "permissions": [],
    "platforms": {"windows": "required", "web": "required", "android": "required"},
    "status": "defined"
  },
  {
    "id": "DEVICE-SCAN-001",
    "name": "HID 扫码诊断",
    "domain": "device",
    "sources": ["src/mixin/swipingCard.js"],
    "protocols": [],
    "permissions": [],
    "platforms": {"windows": "required", "web": "degraded", "android": "required"},
    "status": "defined"
  },
  {
    "id": "DEVICE-PRINT-001",
    "name": "系统打印测试小票",
    "domain": "device",
    "sources": ["src/plugins/print/Print.js"],
    "protocols": [],
    "permissions": [],
    "platforms": {"windows": "required", "web": "degraded", "android": "required"},
    "status": "defined"
  }
]
```

Create `protocols.json` with exact initial facts:

- `HTTP-TERM-AUTH`: `POST /term/auth`, JSON body `{code}`, optional `tt`, response code `1` yields `data.tk`, `data.am`, `data.id`, `data.n`.
- `HTTP-AUTH-LOGIN`: `POST /auth/login`, headers `tk` and `tt`, JSON body `{code, passwd, client_name, pt}`; `passwd` is uppercase MD5.
- `HTTP-SYNC-ALL`: `POST /sync_base/all`, headers `tk` and `tt`.
- `HTTP-SYNC-INCREMENT`: `POST /sync_base/increment`, JSON body `{last_sync_time}`.
- `WS-SYNC`: connect to `{wsBase}/sync`; first socket payload is `JSON.stringify(tk)`; envelopes use `{p,t,d}`.

Create `permissions.json` with:

- `PERM-ROLE-001`: active role IDs from dataset 13 filtered by `station_id` and `status == 1`.
- `PERM-MODULE-001`: active module IDs from dataset 41 filtered by `station_id` and `status == 1`.
- `PERM-SUB-001`: employee sub-permissions are referenced by Vuex but absent from the current `resResultDataArr`; status remains `discovered` until runtime capture identifies its source.

- [ ] **Step 4: Implement validation**

`validate_ledgers.js` must reject duplicate IDs, missing source files, unknown protocol/permission references, invalid statuses, or a missing platform key. Valid enums:

```js
const capabilityStatuses = new Set([
  'discovered', 'defined', 'implemented', 'protocol-equal',
  'permission-equal', 'exception-equal', 'platform-verified', 'accepted',
]);
const platformScopes = new Set(['required', 'degraded', 'approved', 'out-of-scope']);
```

Return `{ errors, capabilityCount, protocolCount, permissionCount }` and exit 1 from the CLI when `errors` is non-empty.

- [ ] **Step 5: Implement and generate coverage**

`generate_report.js` must sort capabilities by ID and produce a Markdown table containing ID, domain, Windows, Web, Android, status, protocol count, permission count, and source count. Do not include generation timestamps.

Run:

```bash
node tools/flutter_migration_inventory/validate_ledgers.js
node tools/flutter_migration_inventory/generate_report.js
node --test tests/flutterMigrationInventory.test.js
```

Expected: validator exits 0, tests PASS, and `coverage.md` contains all five capability IDs.

- [ ] **Step 6: Document ledger workflow**

`migration/flutter/README.md` must define status transitions, platform scope meanings, evidence requirements, sanitization rules, and the rule that Vue changes must update affected capability rows.

- [ ] **Step 7: Commit**

```bash
git add migration/flutter tools/flutter_migration_inventory tests/flutterMigrationInventory.test.js
git commit -m "docs: establish Flutter migration ledgers"
```

## Task 3: Pin Flutter and scaffold the Pub workspace

**Files:**
- Create: `flutter_workspace/.fvmrc`
- Modify: `.gitignore`
- Create: `flutter_workspace/pubspec.yaml`
- Create: `flutter_workspace/pubspec.lock`
- Create: `flutter_workspace/analysis_options.yaml`
- Create: `flutter_workspace/apps/windows_app/**`
- Create: `flutter_workspace/apps/web_app/**`
- Create: `flutter_workspace/apps/android_app/**`
- Create: `flutter_workspace/packages/{foundation,protocol,session,realtime_sync,permissions,design_system}/**`
- Create: `flutter_workspace/packages/{device_bridge_platform_interface,device_bridge_windows,device_bridge_android,device_bridge_web}/**`
- Create: `tests/flutterWorkspaceStructure.test.js`

- [ ] **Step 1: Write the failing workspace structure test**

Create a Node test that asserts `flutter_workspace/.fvmrc` pins `3.47.0`, the root workspace lists `apps/*` and `packages/*`, all expected members have `resolution: workspace`, only the workspace root owns `pubspec.lock`, and no generated app still contains the counter-demo string.

- [ ] **Step 2: Run the structure test and verify failure**

Run: `node --test tests/flutterWorkspaceStructure.test.js`

Expected: FAIL because `flutter_workspace/.fvmrc` and the workspace members do not exist.

- [ ] **Step 3: Install and pin the toolchain**

First create `flutter_workspace/pubspec.yaml` with only:

```yaml
name: shouyin_flutter_workspace
publish_to: none
environment:
  sdk: ">=3.13.0 <4.0.0"
```

Then run:

```bash
dart pub global activate fvm 4.3.0
cd flutter_workspace
fvm use 3.47.0 --force
fvm flutter --version
```

Expected: output starts with `Flutter 3.47.0` and `flutter_workspace/.fvmrc` contains `"flutter": "3.47.0"`.

- [ ] **Step 4: Add generated paths to `.gitignore`**

Append:

```gitignore
flutter_workspace/.fvm/
flutter_workspace/.dart_tool/
flutter_workspace/build/
flutter_workspace/**/.dart_tool/
flutter_workspace/**/build/
flutter_workspace/**/coverage/
flutter_workspace/**/.flutter-plugins
flutter_workspace/**/.flutter-plugins-dependencies
```

Do not ignore `flutter_workspace/.fvmrc`, `pubspec.lock`, Windows runner files, Android Gradle files, or Web assets.

- [ ] **Step 5: Generate platform apps and packages**

From `flutter_workspace` run:

```bash
fvm flutter create --org com.xmsj.shouyin --project-name shouyin_windows --platforms=windows apps/windows_app
fvm flutter create --org com.xmsj.shouyin --project-name shouyin_web --platforms=web apps/web_app
fvm flutter create --org com.xmsj.shouyin --project-name shouyin_android --platforms=android apps/android_app
fvm flutter create --template=package packages/foundation
fvm flutter create --template=package packages/protocol
fvm flutter create --template=package packages/session
fvm flutter create --template=package packages/realtime_sync
fvm flutter create --template=package packages/permissions
fvm flutter create --template=package packages/design_system
fvm flutter create --template=package packages/device_bridge_platform_interface
fvm flutter create --template=package packages/device_bridge_windows
fvm flutter create --template=package packages/device_bridge_android
fvm flutter create --template=package packages/device_bridge_web
```

- [ ] **Step 6: Configure native Pub workspace resolution**

Create the root `pubspec.yaml`:

```yaml
name: shouyin_flutter_workspace
publish_to: none
environment:
  sdk: ">=3.13.0 <4.0.0"
workspace:
  - apps/*
  - packages/*
dev_dependencies:
  flutter_lints: any
```

Add to every member:

```yaml
resolution: workspace
environment:
  sdk: ">=3.13.0 <4.0.0"
```

Replace generated demo entry points with a minimal `MaterialApp` displaying the platform app name. Remove generated counter tests and add one smoke test per app asserting that name is visible.

- [ ] **Step 7: Resolve once and verify one lockfile**

Run:

```bash
fvm dart pub get
fvm dart pub workspace list
find apps packages \( -name pubspec.lock -o -path '*/.dart_tool/package_config.json' \)
```

Expected: workspace list includes three apps and ten packages; the `find` command has no output; `flutter_workspace/pubspec.lock` exists.

- [ ] **Step 8: Run tests and commit**

Run:

```bash
node --test tests/flutterWorkspaceStructure.test.js
cd flutter_workspace
fvm dart analyze
fvm flutter test apps/windows_app apps/web_app apps/android_app
```

Expected: all commands exit 0.

Commit:

```bash
git add .gitignore flutter_workspace tests/flutterWorkspaceStructure.test.js
git commit -m "build: scaffold Flutter platform workspace"
```

## Task 4: Enforce architecture boundaries

**Files:**
- Create: `flutter_workspace/tool/verify_boundaries.js`
- Create: `flutter_workspace/tool/verify_boundaries.test.js`
- Modify: `flutter_workspace/analysis_options.yaml`

- [ ] **Step 1: Write failing boundary tests**

Test these violations using temporary fixture files:

- a `domain/` file importing `package:flutter`, Dio, Riverpod, `data/`, or `presentation/`;
- a package importing `apps/`;
- a `presentation/` file importing another feature's internal `src/` path.

Also test a valid dependency from `application` to `domain`.

- [ ] **Step 2: Run and verify failure**

Run: `node --test flutter_workspace/tool/verify_boundaries.test.js`

Expected: FAIL because the guard does not exist.

- [ ] **Step 3: Implement the guard**

The guard recursively scans `.dart` files and reports `file:line` plus the violated rule. Export `findBoundaryViolations(root)` for tests and exit 1 from the CLI when violations exist.

Rules:

```js
const forbiddenDomainImports = [
  'package:flutter/', 'package:flutter_riverpod/', 'package:dio/',
  '/data/', '/presentation/',
];
```

All imports from another package must use its public `package:name/name.dart` entry point; importing another package's `lib/src` is invalid.

- [ ] **Step 4: Configure analyzer**

Use `flutter_lints` and enable `avoid_print`, `cancel_subscriptions`, `close_sinks`, `discarded_futures`, `unawaited_futures`, `use_build_context_synchronously`, and `always_use_package_imports`.

- [ ] **Step 5: Verify and commit**

Run:

```bash
node --test flutter_workspace/tool/verify_boundaries.test.js
node flutter_workspace/tool/verify_boundaries.js flutter_workspace
cd flutter_workspace && fvm dart analyze
```

Expected: tests PASS, guard prints `0 boundary violations`, analyzer exits 0.

Commit:

```bash
git add flutter_workspace/tool flutter_workspace/analysis_options.yaml
git commit -m "test: enforce Flutter package boundaries"
```

## Task 5: Implement foundation result, failure, connection state, and redaction

**Files:**
- Create: `flutter_workspace/packages/foundation/lib/foundation.dart`
- Create: `flutter_workspace/packages/foundation/lib/src/app_failure.dart`
- Create: `flutter_workspace/packages/foundation/lib/src/result.dart`
- Create: `flutter_workspace/packages/foundation/lib/src/connection_phase.dart`
- Create: `flutter_workspace/packages/foundation/lib/src/redactor.dart`
- Replace: `flutter_workspace/packages/foundation/test/foundation_test.dart`

- [ ] **Step 1: Write failing unit tests**

Tests must assert:

```dart
test('result exposes either value or typed failure', () {
  const ok = Success<int>(3);
  const failed = FailureResult<int>(
    AppFailure(kind: FailureKind.network, code: 'network.unavailable', safeMessage: '网络不可用'),
  );
  expect(ok.valueOrNull, 3);
  expect(failed.failureOrNull?.kind, FailureKind.network);
});

test('redactor removes tokens, passwords, phone numbers, and payment codes', () {
  final text = Redactor.redact({
    'tk': 'token-value',
    'passwd': 'HASH',
    'phone': '13800138000',
    'payment_code': '123456789012345678',
    'route': '/auth/login',
  });
  expect(text, contains('/auth/login'));
  expect(text, isNot(contains('token-value')));
  expect(text, isNot(contains('13800138000')));
  expect(text, isNot(contains('123456789012345678')));
});

test('only online allows writes', () {
  expect(ConnectionPhase.online.allowsWrites, isTrue);
  expect(ConnectionPhase.blocked.allowsWrites, isFalse);
  expect(ConnectionPhase.reconciling.allowsWrites, isFalse);
});
```

- [ ] **Step 2: Run and verify failure**

Run: `cd flutter_workspace && fvm flutter test packages/foundation`

Expected: FAIL because the foundation types do not exist.

- [ ] **Step 3: Implement minimal immutable types**

Use these public shapes consistently in all later tasks:

```dart
enum FailureKind { network, authentication, business, protocol, realtime, device, unknown }

final class AppFailure {
  const AppFailure({required this.kind, required this.code, required this.safeMessage});
  final FailureKind kind;
  final String code;
  final String safeMessage;
}

sealed class Result<T> {
  const Result();
  T? get valueOrNull => this is Success<T> ? (this as Success<T>).value : null;
  AppFailure? get failureOrNull =>
      this is FailureResult<T> ? (this as FailureResult<T>).failure : null;
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);
  final AppFailure failure;
}

enum ConnectionPhase { online, blocked, reconciling }

extension ConnectionPhaseWriteAccess on ConnectionPhase {
  bool get allowsWrites => this == ConnectionPhase.online;
}
```

`Redactor.redact` recursively copies maps/lists, replaces sensitive-key values with `[REDACTED]`, and masks 11-digit mobile numbers and digit strings of 16 or more characters in free text.

- [ ] **Step 4: Export public API, verify, and commit**

Run:

```bash
cd flutter_workspace
fvm flutter test packages/foundation
fvm dart analyze packages/foundation
```

Expected: PASS and analyzer exits 0.

Commit:

```bash
git add flutter_workspace/packages/foundation
git commit -m "feat: add Flutter foundation primitives"
```

## Task 6: Implement exact request context and HTTP compatibility

**Files:**
- Modify: `flutter_workspace/packages/protocol/pubspec.yaml`
- Create: `flutter_workspace/packages/protocol/lib/protocol.dart`
- Create: `flutter_workspace/packages/protocol/lib/src/api_config.dart`
- Create: `flutter_workspace/packages/protocol/lib/src/client_kind.dart`
- Create: `flutter_workspace/packages/protocol/lib/src/credential_store.dart`
- Create: `flutter_workspace/packages/protocol/lib/src/header_policy.dart`
- Create: `flutter_workspace/packages/protocol/lib/src/request_gate.dart`
- Create: `flutter_workspace/packages/protocol/lib/src/protocol_client.dart`
- Replace: `flutter_workspace/packages/protocol/test/protocol_test.dart`

- [ ] **Step 1: Add dependencies**

Run from `flutter_workspace/packages/protocol`:

```bash
fvm dart pub add dio crypto
fvm dart pub add foundation --path ../foundation
fvm dart pub add --dev http_mock_adapter
```

Use workspace-local `foundation`; confirm `pubspec.lock` changes only at `flutter_workspace/pubspec.lock`.

- [ ] **Step 2: Write failing client mapping and header tests**

Cover exact terminal values:

```dart
expect(ClientKind.orgManager.termType, 1);
expect(ClientKind.booking.termType, 2);
expect(ClientKind.order.termType, 4);
expect(ClientKind.cashier.termType, 8);
expect(ClientKind.vip.termType, 16);
expect(ClientKind.erp.termType, 32);
expect(ClientKind.erpAdmin.termType, 64);
expect(ClientKind.wine.termType, 256);
expect(ClientKind.queueDisplay.termType, 512);
expect(ClientKind.superAdmin.termType, isNull);
```

Use an in-memory credential store and `MockDioAdapter` to assert:

- timeout is 12 seconds;
- body is JSON and `Content-Type` is `application/json`;
- `tk` and `stk` are attached only when non-empty;
- `tt` is attached for a client with a terminal type;
- response codes 11/12 clear `tk` and return authentication failure;
- response codes 14/15 clear `stk` and return authentication failure;
- a transport exception returns network failure without leaking the body.

- [ ] **Step 3: Run and verify failure**

Run: `cd flutter_workspace && fvm flutter test packages/protocol`

Expected: FAIL because protocol classes do not exist.

- [ ] **Step 4: Implement configuration and credentials**

`ApiConfig` reads non-secret endpoints supplied by the app:

```dart
final class ApiConfig {
  const ApiConfig({required this.apiBase, required this.onlineBase, required this.websocketBase});
  final Uri apiBase;
  final Uri onlineBase;
  final Uri websocketBase;
}
```

`CredentialStore` declares `readTk`, `writeTk`, `clearTk`, `readStk`, `writeStk`, and `clearStk`. Keep platform storage implementation outside `protocol`.

- [ ] **Step 5: Implement header policy and duplicate gate**

`ClientKind` contains both existing `client_name` and `tt`. `HeaderPolicy.headersFor` returns `Accept`, `Content-Type`, optional `tk`, optional `stk`, and optional `tt`. It omits `tt` for `onlineBase` requests and `superAdmin`.

`RequestGate` uses an injected clock. First request is allowed; `sel/csm_orders` requires more than 100ms since the previous request; other URLs reproduce the existing greater-than-zero-millisecond gate.

- [ ] **Step 6: Implement ProtocolClient**

Expose only:

```dart
Future<Result<Map<String, Object?>>> get(
  String path, {
  Map<String, Object?> query = const {},
  required ClientKind client,
});

Future<Result<Map<String, Object?>>> post(
  String path, {
  Map<String, Object?> body = const {},
  required ClientKind client,
});
```

Do not add general retry. Decode only top-level JSON objects. A non-object body returns `protocol.invalid_top_level`. Apply code 11/12 and 14/15 invalidation before returning the response.

- [ ] **Step 7: Verify contract and commit**

Run:

```bash
cd flutter_workspace
fvm flutter test packages/protocol
fvm dart analyze packages/protocol
```

Expected: all protocol tests PASS.

Commit:

```bash
git add flutter_workspace/packages/protocol flutter_workspace/pubspec.lock
git commit -m "feat: add compatible Flutter protocol client"
```

## Task 7: Implement terminal authorization and employee login

**Files:**
- Modify: `flutter_workspace/packages/session/pubspec.yaml`
- Create: `flutter_workspace/packages/session/lib/session.dart`
- Create: `flutter_workspace/packages/session/lib/src/session_models.dart`
- Create: `flutter_workspace/packages/session/lib/src/session_api.dart`
- Create: `flutter_workspace/packages/session/lib/src/session_repository.dart`
- Create: `flutter_workspace/packages/session/lib/src/login_view_model.dart`
- Replace: `flutter_workspace/packages/session/test/session_test.dart`

- [ ] **Step 1: Add dependencies**

Run:

```bash
cd flutter_workspace/packages/session
fvm dart pub add crypto flutter_riverpod
fvm dart pub add foundation --path ../foundation
fvm dart pub add protocol --path ../protocol
```

- [ ] **Step 2: Write failing terminal authorization tests**

With a fake `ProtocolClient`, assert `authorizeMachine('MACHINE-001')` posts `/term/auth` with `{code: 'MACHINE-001'}`, stores returned `tk`, and maps `am` to the correct `ClientKind`. Missing `tk`, `am`, `id`, or `n` returns `protocol.term_auth_shape`.

- [ ] **Step 3: Write failing login tests**

Assert account login posts:

```dart
{
  'code': '000001',
  'passwd': md5.convert(utf8.encode('123456')).toString().toUpperCase(),
  'client_name': 'money',
  'pt': 1,
}
```

Assert blank account/password is rejected before transport, code other than `1` becomes a business failure using the server `msg`, and success requires `data.station_id` and `data.name`.

- [ ] **Step 4: Run and verify failure**

Run: `cd flutter_workspace && fvm flutter test packages/session`

Expected: FAIL because session implementation does not exist.

- [ ] **Step 5: Implement immutable session models and repository**

Public models:

```dart
final class MachineSession {
  const MachineSession({required this.machineId, required this.machineName, required this.client});
  final String machineId;
  final String machineName;
  final ClientKind client;
}

final class UserSession {
  const UserSession({required this.employeeId, required this.name, required this.stationId});
  final String employeeId;
  final String name;
  final String stationId;
}
```

`SessionRepository` owns current machine/user values in memory and exposes streams. It delegates token persistence to `CredentialStore`. `logout` calls `/auth/logout`, then clears in-memory state even if the network request fails.

- [ ] **Step 6: Implement LoginViewModel**

State includes `idle`, `authorizingMachine`, `readyForLogin`, `loggingIn`, `authenticated`, and `failure`. Commands are `authorizeMachine`, `login`, and `logout`. Prevent concurrent submissions.

- [ ] **Step 7: Verify and commit**

Run:

```bash
cd flutter_workspace
fvm flutter test packages/session
fvm dart analyze packages/session
```

Expected: PASS.

Commit:

```bash
git add flutter_workspace/packages/session flutter_workspace/pubspec.lock
git commit -m "feat: add Flutter terminal and login session"
```

## Task 8: Implement permission normalization

**Files:**
- Modify: `flutter_workspace/packages/permissions/pubspec.yaml`
- Create: `flutter_workspace/packages/permissions/lib/permissions.dart`
- Create: `flutter_workspace/packages/permissions/lib/src/permission_models.dart`
- Create: `flutter_workspace/packages/permissions/lib/src/permission_normalizer.dart`
- Create: `flutter_workspace/packages/permissions/lib/src/permission_engine.dart`
- Replace: `flutter_workspace/packages/permissions/test/permissions_test.dart`

- [ ] **Step 1: Add the foundation dependency**

Run:

```bash
cd flutter_workspace/packages/permissions
fvm dart pub add foundation --path ../foundation
```

- [ ] **Step 2: Write failing normalization tests**

Use synthetic datasets matching Vue transforms:

```dart
final roles = [
  {'station_id': 7, 'sys_role_id': 5, 'status': 1},
  {'station_id': 7, 'sys_role_id': 11, 'status': 3},
  {'station_id': 8, 'sys_role_id': 6, 'status': 1},
];
final modules = [
  {'station_id': 7, 'sys_module_id': 101, 'status': 1},
  {'station_id': 7, 'sys_module_id': 102, 'status': 3},
];
```

For station 7, expect role IDs `{5}`, module IDs `{101}`, no inactive rows, and deterministic deduplication.

- [ ] **Step 3: Write failing decision tests**

Define `PermissionRequirement` with required role/module/sub-permission sets and `PermissionDecision` with `allowed`, `reason`, and `effectiveScope`. Assert deny-by-default when permission data is unavailable and distinct denial reasons for role and module failures.

- [ ] **Step 4: Run and verify failure**

Run: `cd flutter_workspace && fvm flutter test packages/permissions`

Expected: FAIL because permission types do not exist.

- [ ] **Step 5: Implement and export**

Keep this task limited to roles/modules and optional pre-normalized sub-permissions. Product, region, limit, and secondary-authorization rules stay represented in `permissions.json` as discovered capabilities and receive separate domain plans.

- [ ] **Step 6: Verify and commit**

Run:

```bash
cd flutter_workspace
fvm flutter test packages/permissions
fvm dart analyze packages/permissions
```

Expected: PASS.

Commit:

```bash
git add flutter_workspace/packages/permissions flutter_workspace/pubspec.lock
git commit -m "feat: normalize Flutter role permissions"
```

## Task 9: Implement realtime connection and reconciliation state

**Files:**
- Modify: `flutter_workspace/packages/realtime_sync/pubspec.yaml`
- Create: `flutter_workspace/packages/realtime_sync/lib/realtime_sync.dart`
- Create: `flutter_workspace/packages/realtime_sync/lib/src/sync_envelope.dart`
- Create: `flutter_workspace/packages/realtime_sync/lib/src/sync_api.dart`
- Create: `flutter_workspace/packages/realtime_sync/lib/src/socket_transport.dart`
- Create: `flutter_workspace/packages/realtime_sync/lib/src/realtime_controller.dart`
- Replace: `flutter_workspace/packages/realtime_sync/test/realtime_sync_test.dart`

- [ ] **Step 1: Add dependencies**

Run:

```bash
cd flutter_workspace/packages/realtime_sync
fvm dart pub add web_socket_channel
fvm dart pub add foundation --path ../foundation
fvm dart pub add protocol --path ../protocol
```

- [ ] **Step 2: Write failing envelope tests**

Assert `{p: 1, t: '20260826010101', d: {...}}` maps to a data event, `p: 2` maps to heartbeat, and `p: 3` maps to server error. Non-object, missing `p`, or invalid `t` returns `protocol.websocket_envelope`.

- [ ] **Step 3: Write failing lifecycle tests with fakes**

Use an injected fake socket, fake clock, and fake timer scheduler. Verify:

- connection target is `{websocketBase}/sync`;
- the first socket payload is `jsonEncode(tk)`, including JSON quotes;
- a valid message updates the last-message time and sync cursor;
- no message for 65 seconds enters `reconciling` and reconnects;
- reconnect delay is 3 seconds, matching current `reset` behavior;
- auth error text clears `tk` and enters `blocked`;
- successful reconnect calls `/sync_base/increment` with `last_sync_time` before returning `online`;
- no cursor triggers `/sync_base/all`;
- writes remain disabled throughout `reconciling`.

- [ ] **Step 4: Run and verify failure**

Run: `cd flutter_workspace && fvm flutter test packages/realtime_sync`

Expected: FAIL because realtime implementation does not exist.

- [ ] **Step 5: Implement transport and controller**

`SocketTransport` is an interface so tests never open a real socket. The production adapter wraps `WebSocketChannel.connect`. `RealtimeController` emits `ConnectionPhase`, `SyncEnvelope`, and cursor streams; it does not transform the 58 compressed sync datasets in this plan.

Recognize these authorization errors exactly:

```text
第一个消息必须为授权信息
未发现授权信息
授权信息未找到或已过期
```

- [ ] **Step 6: Verify and commit**

Run:

```bash
cd flutter_workspace
fvm flutter test packages/realtime_sync
fvm dart analyze packages/realtime_sync
```

Expected: PASS.

Commit:

```bash
git add flutter_workspace/packages/realtime_sync flutter_workspace/pubspec.lock
git commit -m "feat: add Flutter realtime reconciliation"
```

## Task 10: Build shared login and diagnostics shell

**Files:**
- Modify: `flutter_workspace/packages/design_system/pubspec.yaml`
- Create: `flutter_workspace/packages/design_system/lib/design_system.dart`
- Create: `flutter_workspace/packages/design_system/lib/src/connection_banner.dart`
- Create: `flutter_workspace/packages/design_system/lib/src/diagnostic_panel.dart`
- Create: `flutter_workspace/packages/session/lib/src/login_screen.dart`
- Create: `flutter_workspace/packages/session/lib/src/flutter_secure_credential_store.dart`
- Modify: `flutter_workspace/apps/windows_app/lib/main.dart`
- Modify: `flutter_workspace/apps/web_app/lib/main.dart`
- Modify: `flutter_workspace/apps/android_app/lib/main.dart`
- Add tests under each affected package/app.

- [ ] **Step 1: Add dependencies**

From `flutter_workspace`, run:

```bash
for app in windows_app web_app android_app; do
  cd "apps/$app"
  fvm dart pub add flutter_riverpod go_router
  fvm dart pub add foundation --path ../../packages/foundation
  fvm dart pub add protocol --path ../../packages/protocol
  fvm dart pub add session --path ../../packages/session
  fvm dart pub add realtime_sync --path ../../packages/realtime_sync
  fvm dart pub add permissions --path ../../packages/permissions
  fvm dart pub add design_system --path ../../packages/design_system
  cd ../..
done
cd packages/design_system
fvm dart pub add flutter_riverpod
fvm dart pub add foundation --path ../foundation
cd ../session
fvm dart pub add flutter_secure_storage
fvm dart pub add design_system --path ../design_system
```

- [ ] **Step 2: Write failing UI tests**

Cover:

- machine code is required before terminal authorization;
- account and password are required before login;
- password is never shown in diagnostics;
- concurrent login tap is disabled;
- `blocked` displays a persistent red connection banner and disables write commands;
- `reconciling` displays “正在恢复服务端状态” and disables write commands;
- authenticated route redirects to `/diagnostics`;
- Windows/Web use wide two-column diagnostics layout;
- Android uses single-column touch layout.

- [ ] **Step 3: Run and verify failure**

Run:

```bash
cd flutter_workspace
fvm flutter test packages/design_system packages/session apps/windows_app apps/web_app apps/android_app
```

Expected: FAIL because shared screens and routing are absent.

- [ ] **Step 4: Implement platform configuration**

Each app reads:

```dart
const apiBase = String.fromEnvironment('SHOUYIN_API_BASE');
const onlineBase = String.fromEnvironment('SHOUYIN_ONLINE_BASE');
const websocketBase = String.fromEnvironment('SHOUYIN_WS_BASE');
```

Startup fails with a visible configuration screen when any value is blank or not an absolute HTTP/WS URI. Do not compile credentials or machine codes into the app.

- [ ] **Step 5: Implement composition and routing**

All apps wrap `MaterialApp.router` in `ProviderScope`; `go_router` routes are `/login`, `/diagnostics`, and `/diagnostics/devices`. Authentication redirect uses `SessionRepository`. Platform apps differ only in composition values and window/layout selection.

- [ ] **Step 6: Implement secure credential adapters**

Implement `FlutterSecureCredentialStore` in `session` with `flutter_secure_storage`, then inject it from each app. On Web use session storage mode for `stk` and existing-compatible persistent storage for `tk`; document that browser security remains bounded by same-origin Web storage. Unit tests override this provider with in-memory credentials.

- [ ] **Step 7: Verify and commit**

Run:

```bash
cd flutter_workspace
fvm flutter test packages/design_system packages/session apps/windows_app apps/web_app apps/android_app
fvm dart analyze
```

Expected: PASS.

Commit:

```bash
git add flutter_workspace/apps flutter_workspace/packages/design_system flutter_workspace/packages/session flutter_workspace/pubspec.lock
git commit -m "feat: add Flutter login diagnostic shells"
```

## Task 11: Add HID scanner and system-print feasibility adapters

**Files:**
- Modify: platform device package `pubspec.yaml` files.
- Create: `flutter_workspace/packages/device_bridge_platform_interface/lib/device_bridge_platform_interface.dart`
- Create: `flutter_workspace/packages/device_bridge_platform_interface/lib/src/scanner_service.dart`
- Create: `flutter_workspace/packages/device_bridge_platform_interface/lib/src/printer_service.dart`
- Create: `flutter_workspace/packages/device_bridge_platform_interface/lib/src/test_receipt.dart`
- Create platform implementations under `device_bridge_windows`, `device_bridge_android`, and `device_bridge_web`.
- Create: `flutter_workspace/packages/design_system/lib/src/device_diagnostics_screen.dart`
- Modify: `flutter_workspace/apps/windows_app/lib/main.dart`
- Modify: `flutter_workspace/apps/web_app/lib/main.dart`
- Modify: `flutter_workspace/apps/android_app/lib/main.dart`
- Add unit/widget tests for interfaces, HID buffering, test receipt, and diagnostics.

- [ ] **Step 1: Add dependencies**

From `flutter_workspace`, run:

```bash
cd packages/device_bridge_platform_interface
fvm dart pub add foundation --path ../foundation
cd ../device_bridge_windows
fvm dart pub add printing pdf esc_pos_utils_plus
fvm dart pub add foundation --path ../foundation
fvm dart pub add device_bridge_platform_interface --path ../device_bridge_platform_interface
cd ../device_bridge_android
fvm dart pub add printing pdf esc_pos_utils_plus mobile_scanner
fvm dart pub add foundation --path ../foundation
fvm dart pub add device_bridge_platform_interface --path ../device_bridge_platform_interface
cd ../device_bridge_web
fvm dart pub add printing pdf
fvm dart pub add foundation --path ../foundation
fvm dart pub add device_bridge_platform_interface --path ../device_bridge_platform_interface
cd ../design_system
fvm dart pub add device_bridge_platform_interface --path ../device_bridge_platform_interface
cd ../../apps/windows_app
fvm dart pub add device_bridge_windows --path ../../packages/device_bridge_windows
cd ../web_app
fvm dart pub add device_bridge_web --path ../../packages/device_bridge_web
cd ../android_app
fvm dart pub add device_bridge_android --path ../../packages/device_bridge_android
```

Use `printing` and `pdf` for the system-print feasibility path, `esc_pos_utils_plus` for LAN ESC/POS bytes, and `mobile_scanner` for Android camera scanning. Do not add raw USB/Bluetooth printer transport in this plan; LAN ESC/POS proves the vendor-neutral command path without a manufacturer SDK. HID uses Flutter `HardwareKeyboard`.

- [ ] **Step 2: Write failing HID tests**

Use an injected stream of key events and fake clock. Assert:

- characters received within 50ms are buffered;
- Enter emits one scan and clears the buffer;
- a gap over 100ms resets the buffer and treats input as manual;
- scans shorter than 3 characters are rejected;
- focus changes do not destroy the scanner service;
- emitted scan values are never written to logs.

For Android camera input, inject a fake barcode stream and assert empty values are ignored, the same value is suppressed for 500ms, controller disposal closes the stream, and camera permission denial maps to `device.camera_permission` without crashing the diagnostics screen.

- [ ] **Step 3: Write failing printing tests**

Assert `TestReceipt` contains app version, platform, 58/80mm choice, Chinese text “打印测试成功”, timestamp supplied by an injected clock, and a QR payload containing only a random diagnostic ID. Mock `PrinterService` and verify success/failure status without affecting session state. For LAN ESC/POS, run a loopback `ServerSocket`, assert the adapter connects to the configured host/port, sends initialization/content/cut bytes, closes the socket, and maps refusal/timeout to `device.lan_printer_unavailable`.

- [ ] **Step 4: Run and verify failure**

Run:

```bash
cd flutter_workspace
fvm flutter test packages/device_bridge_platform_interface packages/device_bridge_windows packages/device_bridge_android packages/device_bridge_web packages/design_system
```

Expected: FAIL because device interfaces and implementations are absent.

- [ ] **Step 5: Implement federated-style interfaces**

Public API:

```dart
abstract interface class ScannerService {
  Stream<String> get scans;
  void start();
  void stop();
}

enum ReceiptPaperWidth { mm58, mm80 }

sealed class PrinterTarget {
  const PrinterTarget();
}

final class SystemPrinterTarget extends PrinterTarget {
  const SystemPrinterTarget();
}

final class LanEscPosTarget extends PrinterTarget {
  const LanEscPosTarget({required this.host, this.port = 9100, required this.paperWidth});
  final String host;
  final int port;
  final ReceiptPaperWidth paperWidth;
}

abstract interface class PrinterService {
  Future<Result<void>> printTestReceipt(TestReceipt receipt, PrinterTarget target);
}
```

`PrinterTarget` has `SystemPrinterTarget` and `LanEscPosTarget(host, port, paperWidth)` variants. Windows and Android scanner adapters use the common HID buffer. Android also exposes a camera scanner backed by `mobile_scanner`. Web scanner is marked degraded but supports focused keyboard input. System-printer adapters call `Printing.layoutPdf`; Web therefore opens the browser print path and does not claim silent printing. Windows and Android implement LAN ESC/POS over TCP; Web rejects that target with `device.target_unsupported`.

Each app overrides the `ScannerService` and `PrinterService` providers with its matching platform package. No app imports another platform's implementation.

- [ ] **Step 6: Implement device diagnostics screen**

Show scanner status, Android camera launch/close controls, last scan masked to first/last two characters, printer target selector, LAN host/port, paper width selector, print-test button, and typed device failure. Never show or persist full payment-like scan values.

- [ ] **Step 7: Verify and commit**

Run all device and UI tests plus analyzer. Expected: PASS.

Commit:

```bash
git add flutter_workspace/packages/device_bridge_* flutter_workspace/packages/design_system flutter_workspace/pubspec.lock
git commit -m "feat: add Flutter scanner and print diagnostics"
```

## Task 12: Add reproducible checks and GitLab jobs

**Files:**
- Create: `flutter_workspace/tool/check.sh`
- Create: `flutter_workspace/tool/check.ps1`
- Create: `.gitlab-ci.yml`
- Modify: `migration/flutter/README.md`

- [ ] **Step 1: Write the local check scripts**

Both scripts perform, in order:

1. `fvm dart pub get --enforce-lockfile`.
2. Node migration inventory tests.
3. Ledger validation and regeneration; fail when generated files differ.
4. Boundary tests and boundary CLI.
5. `fvm dart format --output=none --set-exit-if-changed .`.
6. `fvm dart analyze`.
7. All Flutter package/app tests.
8. Platform build appropriate for the host.

Each script resolves the repository root from its own location before invoking Node tests under the root `tests/` directory, so it does not depend on the caller's current working directory.

`check.sh` builds Web release and Android release APK. `check.ps1` builds Windows release. Scripts stop on the first failure and never print environment variables.

- [ ] **Step 2: Run the non-Windows script**

Run: `cd flutter_workspace && ./tool/check.sh`

Expected: all checks exit 0, `apps/web_app/build/web` and Android release APK are produced under ignored build directories.

- [ ] **Step 3: Add GitLab CI**

Create stages `validate`, `build`, and `windows`. Use a Flutter 3.47.0 container for Linux jobs and a runner tagged `windows` for PowerShell. Cache Pub and FVM directories, never build-cache application outputs across branches, and retain Web/APK/Windows artifacts for seven days.

Jobs:

- `migration-ledger`: Node tests, ledger validation, deterministic report check.
- `flutter-test`: lockfile, boundary, format, analyze, all tests.
- `flutter-web-android`: Web release and Android release APK.
- `flutter-windows`: `check.ps1` on Windows runner.

No live backend credentials are configured in ordinary CI jobs.

- [ ] **Step 4: Verify pipeline syntax and local checks**

Run the repository's available GitLab lint mechanism if configured. If no lint endpoint is available, parse `.gitlab-ci.yml` with the runner's built-in CI lint before merging and attach the lint result to the PR. Re-run `check.sh` locally.

Expected: local command exits 0; pipeline creates all four jobs and does not expose protected variables.

- [ ] **Step 5: Commit**

```bash
git add .gitlab-ci.yml flutter_workspace/tool migration/flutter/README.md
git commit -m "ci: verify Flutter migration foundation"
```

## Task 13: Execute live feasibility gates and record evidence

**Files:**
- Create: `docs/flutter-migration/feasibility-report.md`
- Modify: `migration/flutter/capabilities.json`
- Modify: `migration/flutter/generated/coverage.md`

- [ ] **Step 1: Create a sanitized evidence report before live runs**

The report has sections A/B/C and records app commit, Flutter version, platform version, test date, result, evidence path, sanitized error, and decision. Initial state is `not-run`; no credential or raw payload fields exist.

- [ ] **Step 2: Run Gate A on Web and Android/macOS development hosts**

Use environment-specific endpoints through `--dart-define`:

```bash
cd flutter_workspace/apps/web_app
fvm flutter run -d chrome \
  --dart-define=SHOUYIN_API_BASE=http://nls-dev.xmsjznwl.com/server \
  --dart-define=SHOUYIN_ONLINE_BASE=https://ncrmyun-dev.xmsjznwl.com/server \
  --dart-define=SHOUYIN_WS_BASE=ws://nls-dev.xmsjznwl.com/server
```

Enter the machine code and test credentials manually. Verify terminal authorization, login request headers, response handling, WebSocket authentication, heartbeat, forced disconnect, incremental reconciliation, and logout. Repeat on an Android device, scanning a non-payment QR code once through the camera and once through a HID scanner. Save only redacted screenshots and diagnostic exports outside the repository unless approved for sanitized commit.

- [ ] **Step 3: Run Gate A/B on Windows**

On a Windows machine:

```powershell
cd flutter_workspace\apps\windows_app
fvm flutter run -d windows `
  --dart-define=SHOUYIN_API_BASE=http://nls-dev.xmsjznwl.com/server `
  --dart-define=SHOUYIN_ONLINE_BASE=https://ncrmyun-dev.xmsjznwl.com/server `
  --dart-define=SHOUYIN_WS_BASE=ws://nls-dev.xmsjznwl.com/server
```

Verify login/sync, scan three known non-payment barcodes through a HID scanner, print both 58mm and 80mm test receipts through a Windows-installed printer, send one test receipt to a LAN ESC/POS printer, disconnect each printer path, confirm typed failure, reconnect, and print again.

On Android, send a test receipt to the same LAN ESC/POS printer. If no standards-compliant LAN printer is available, record Gate B as `blocked-by-environment`; do not mark ESC/POS compatibility as passed from unit tests alone.

- [ ] **Step 4: Run Gate C on Web**

Verify same-origin deployment under `/shouyin-v2/`, refresh/deep-link behavior, back/forward navigation, Chinese IME, browser print, file download, no CORS change, and release initial-load behavior. Confirm the default JavaScript build is used and no COOP/COEP header change is required.

- [ ] **Step 5: Record gate decisions and update capability statuses**

Allowed outcomes are `pass`, `fail`, or `blocked-by-environment`. A failure records the reproducible symptom and stops expansion into business feature plans. A pass advances:

- `AUTH-TERM-001`, `AUTH-LOGIN-001`, `SYNC-CONNECT-001` to `platform-verified` only after all required platforms pass.
- `DEVICE-SCAN-001`, `DEVICE-PRINT-001` to `platform-verified` after Windows and Android pass; Web remains explicitly degraded.

Regenerate coverage and validate ledgers.

- [ ] **Step 6: Run final verification**

Run:

```bash
node --test tests/*.test.js
node tools/flutter_migration_inventory/validate_ledgers.js
node tools/flutter_migration_inventory/generate_report.js
cd flutter_workspace
./tool/check.sh
git diff --check
```

On Windows also run `./tool/check.ps1`. Expected: all automated checks exit 0 and the feasibility report contains a non-`not-run` result for every gate.

- [ ] **Step 7: Commit**

```bash
git add docs/flutter-migration/feasibility-report.md migration/flutter
git commit -m "docs: record Flutter feasibility gates"
```

## Completion criteria

This plan is complete only when:

- deterministic source inventory and validated ledgers exist;
- Flutter 3.47.0 and one workspace lockfile are committed;
- three platform shells build;
- terminal authorization and employee login use the existing backend unchanged;
- `tk`, `stk`, `tt`, error codes, timeout, duplicate gate, and JSON encoding have contract tests;
- WebSocket auth, heartbeat, reconnect, full/increment decision, and write blocking have tests;
- role/module normalization has tests;
- Windows HID scanning, Android camera scanning, Windows system printing, and Windows/Android LAN ESC/POS have real-device evidence;
- Web same-origin and browser constraints are verified;
- GitLab jobs and local check scripts pass;
- feasibility report declares pass/fail/blocked for gates A/B/C without secrets.

If all gates pass, the next implementation plan is `Windows 收银纵向闭环`, starting with sync dataset normalization,营业状态、卡台列表、商品选择、订单写入、支付状态机 and receipt model. If any gate fails, resolve that gate with a focused design and plan before adding business features.

## References

- Approved design: `docs/superpowers/specs/2026-08-25-flutter-cross-platform-migration-design.md`
- Flutter releases: <https://docs.flutter.dev/release/release-notes>
- Pub workspaces: <https://dart.dev/tools/pub/workspaces>
- Flutter architecture: <https://docs.flutter.dev/app-architecture/guide>
- Flutter platform integration: <https://docs.flutter.dev/platform-integration>
- Flutter plugin packages: <https://docs.flutter.dev/packages-and-plugins/developing-packages>
- Flutter Web deployment: <https://docs.flutter.dev/deployment/web>
- Flutter Windows deployment: <https://docs.flutter.dev/deployment/windows>
