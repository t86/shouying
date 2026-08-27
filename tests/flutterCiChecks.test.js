'use strict';

const assert = require('node:assert/strict');
const childProcess = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

const repositoryRoot = path.resolve(__dirname, '..');
const shellCheck = path.join(repositoryRoot, 'flutter_workspace/tool/check.sh');
const powershellCheck = path.join(repositoryRoot, 'flutter_workspace/tool/check.ps1');
const pipeline = path.join(repositoryRoot, '.gitlab-ci.yml');

function read(file) {
  return fs.readFileSync(file, 'utf8');
}

function assertOrdered(source, snippets) {
  let cursor = -1;
  for (const snippet of snippets) {
    const next = source.indexOf(snippet, cursor + 1);
    assert.notEqual(next, -1, `missing ordered command: ${snippet}`);
    assert.ok(next > cursor, `command is out of order: ${snippet}`);
    cursor = next;
  }
}

function makeShellFixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'flutter-check-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const workspace = path.join(root, 'flutter_workspace');
  const tool = path.join(workspace, 'tool');
  const bin = path.join(root, 'stub-bin');
  fs.mkdirSync(tool, { recursive: true });
  for (const member of [
    'packages/device_bridge_android',
    'packages/device_bridge_platform_interface',
    'packages/device_bridge_web',
    'packages/device_bridge_windows',
    'packages/design_system',
    'packages/foundation',
    'packages/permissions',
    'packages/protocol',
    'packages/realtime_sync',
    'packages/session',
    'apps/android_app',
    'apps/web_app',
    'apps/windows_app',
  ]) fs.mkdirSync(path.join(workspace, member), { recursive: true });
  fs.mkdirSync(path.join(root, 'tests'), { recursive: true });
  fs.mkdirSync(bin, { recursive: true });
  fs.copyFileSync(shellCheck, path.join(tool, 'check.sh'));
  fs.chmodSync(path.join(tool, 'check.sh'), 0o755);

  const stub = [
    '#!/bin/sh',
    'entry="$(basename "$0")|$PWD|$*"',
    'printf "%s\\n" "$entry" >> "$CHECK_LOG"',
    'case "$entry" in',
    '  *"${CHECK_FAIL_PATTERN:-__never__}"*) exit 42 ;;',
    'esac',
  ].join('\n');
  for (const command of ['fvm', 'node', 'git']) {
    const target = path.join(bin, command);
    fs.writeFileSync(target, `${stub}\n`, { mode: 0o755 });
  }
  return { root, workspace, bin, script: path.join(tool, 'check.sh') };
}

function runFixture(fixture, options = {}) {
  const log = path.join(fixture.root, 'commands.log');
  const unrelatedCwd = fs.mkdtempSync(path.join(os.tmpdir(), 'flutter-check-cwd-'));
  const result = childProcess.spawnSync(fixture.script, [], {
    cwd: unrelatedCwd,
    encoding: 'utf8',
    env: {
      ...process.env,
      PATH: `${fixture.bin}${path.delimiter}${process.env.PATH}`,
      CHECK_LOG: log,
      CHECK_FAIL_PATTERN: options.failPattern || '',
    },
  });
  fs.rmSync(unrelatedCwd, { recursive: true, force: true });
  return {
    ...result,
    commands: fs.existsSync(log) ? read(log).trim().split('\n') : [],
  };
}

function parseYamlScalar(source) {
  if (source.startsWith("'") && source.endsWith("'")) {
    return source.slice(1, -1).replaceAll("''", "'");
  }
  if (source.startsWith('"') && source.endsWith('"')) return JSON.parse(source);
  if (source === 'true') return true;
  if (source === 'false') return false;
  if (source === 'null' || source === '~') return null;
  if (/^-?\d+$/.test(source)) return Number(source);
  return source;
}

function parsePipelineSubset(source) {
  const lines = source.split(/\r?\n/)
    .map((raw) => ({ raw, indent: raw.match(/^ */)[0].length, text: raw.trim() }))
    .filter((line) => line.text && !line.text.startsWith('#'));

  function parseBlock(start, indent) {
    const list = lines[start]?.indent === indent && lines[start].text.startsWith('- ');
    const value = list ? [] : {};
    let index = start;
    while (index < lines.length && lines[index].indent === indent) {
      const line = lines[index];
      if (list) {
        if (!line.text.startsWith('- ')) break;
        const scalar = line.text.slice(2).trim();
        if (scalar) {
          value.push(parseYamlScalar(scalar));
          index += 1;
        } else if (lines[index + 1]?.indent > indent) {
          const child = parseBlock(index + 1, lines[index + 1].indent);
          value.push(child.value);
          index = child.index;
        } else {
          value.push(null);
          index += 1;
        }
        continue;
      }

      if (line.text.startsWith('- ')) break;
      const separator = line.text.indexOf(':');
      assert.notEqual(separator, -1, `invalid YAML mapping line: ${line.raw}`);
      const key = line.text.slice(0, separator).trim();
      const scalar = line.text.slice(separator + 1).trim();
      if (scalar) {
        value[key] = parseYamlScalar(scalar);
        index += 1;
      } else if (lines[index + 1]?.indent > indent) {
        const child = parseBlock(index + 1, lines[index + 1].indent);
        value[key] = child.value;
        index = child.index;
      } else {
        value[key] = null;
        index += 1;
      }
    }
    return { value, index };
  }

  return parseBlock(0, 0).value;
}

function parseYaml(file) {
  const script = [
    "require 'json'",
    "require 'yaml'",
    'puts JSON.generate(YAML.safe_load(File.read(ARGV.fetch(0)), aliases: true))',
  ].join('; ');
  const result = childProcess.spawnSync('ruby', ['-e', script, file], { encoding: 'utf8' });
  if (result.error?.code === 'ENOENT') return parsePipelineSubset(read(file));
  assert.equal(result.status, 0, result.stderr);
  return JSON.parse(result.stdout);
}

test('portable pipeline parser agrees with the platform YAML parser', () => {
  const actual = parseYaml(pipeline);
  const portable = parsePipelineSubset(read(pipeline));
  assert.deepEqual(portable.stages, actual.stages);
  for (const key of [
    '.linux-flutter',
    'migration-ledger',
    'flutter-test',
    'flutter-web-android',
    'flutter-windows',
  ]) {
    assert.deepEqual(portable[key], actual[key]);
  }
});

test('creates executable local checks and a parseable GitLab pipeline', () => {
  for (const file of [shellCheck, powershellCheck, pipeline]) {
    assert.equal(fs.existsSync(file), true, `${path.relative(repositoryRoot, file)} must exist`);
  }
  assert.notEqual(fs.statSync(shellCheck).mode & 0o111, 0, 'check.sh must be executable');
  assert.doesNotThrow(() => parseYaml(pipeline));
});

test('check.sh resolves roots from itself and runs the complete gate in order', (t) => {
  const fixture = makeShellFixture(t);
  const result = runFixture(fixture);
  assert.equal(result.status, 0, `${result.stdout}\n${result.stderr}`);

  const root = fixture.root;
  const workspace = fixture.workspace;
  assert.deepEqual(result.commands, [
    `fvm|${workspace}|dart pub get --enforce-lockfile`,
    `node|${root}|--test ${root}/tests/flutterMigrationInventory.test.js ${root}/tests/flutterWorkspaceStructure.test.js ${root}/tests/flutterCiChecks.test.js`,
    `node|${root}|${root}/tools/flutter_migration_inventory/validate_ledgers.js`,
    `node|${root}|${root}/tools/flutter_migration_inventory/source_inventory.js`,
    `node|${root}|${root}/tools/flutter_migration_inventory/generate_report.js`,
    `git|${root}|diff --exit-code -- migration/flutter/generated/source-inventory.json migration/flutter/generated/coverage.md`,
    `node|${workspace}|--test ${workspace}/tool/verify_boundaries.test.js`,
    `node|${workspace}|${workspace}/tool/verify_boundaries.js ${workspace}`,
    `fvm|${workspace}|dart format --output=none --set-exit-if-changed .`,
    `fvm|${workspace}|dart analyze`,
    `fvm|${workspace}|flutter test packages/design_system packages/device_bridge_android packages/device_bridge_platform_interface packages/device_bridge_web packages/device_bridge_windows packages/foundation packages/permissions packages/protocol packages/realtime_sync packages/session apps/android_app apps/web_app apps/windows_app`,
    `fvm|${workspace}/apps/web_app|flutter build web --release`,
    `fvm|${workspace}/apps/android_app|flutter build apk --release`,
  ]);
});

test('check.sh stops immediately after the first failed native command', (t) => {
  const fixture = makeShellFixture(t);
  const result = runFixture(fixture, { failPattern: 'dart analyze' });
  assert.equal(result.status, 42);
  assert.match(result.commands.at(-1), /dart analyze$/);
  assert.equal(result.commands.some((command) => command.includes('flutter test')), false);
  assert.equal(result.commands.some((command) => command.includes('flutter build')), false);
});

test('PowerShell check uses checked native calls in the same required order', () => {
  const source = read(powershellCheck);
  assert.match(source, /\$MyInvocation\.MyCommand\.Path/);
  assert.match(source, /Set-StrictMode -Version Latest/);
  assert.match(source, /\$LASTEXITCODE/);
  assert.match(source, /throw/);
  assertOrdered(source, [
    "@('dart', 'pub', 'get', '--enforce-lockfile')",
    "@('--test', $InventoryTest, $WorkspaceStructureTest, $CiChecksTest)",
    "@($LedgerValidator)",
    "@($InventoryGenerator)",
    "@($ReportGenerator)",
    "@('diff', '--exit-code', '--', 'migration/flutter/generated/source-inventory.json', 'migration/flutter/generated/coverage.md')",
    "@('--test', $BoundaryTest)",
    "@($BoundaryCli, $WorkspaceRoot)",
    "@('dart', 'format', '--output=none', '--set-exit-if-changed', '.')",
    "@('dart', 'analyze')",
    "@('flutter', 'test') + $FlutterMembers",
    "@('flutter', 'build', 'windows', '--release')",
  ]);
});

test('local checks never enable tracing or dump environment variables', () => {
  for (const file of [shellCheck, powershellCheck]) {
    const source = read(file);
    assert.doesNotMatch(source, /\bprintenv\b|\bGet-ChildItem\s+Env:|\bset\s+-x\b|\bset\s+-o\s+xtrace\b/i);
  }
});

test('GitLab defines four jobs across validate, build, and windows stages', () => {
  const config = parseYaml(pipeline);
  assert.deepEqual(config.stages, ['validate', 'build', 'windows']);
  const reserved = new Set(['stages', 'variables', 'default', 'workflow', 'include']);
  const jobs = Object.keys(config)
    .filter((key) => !key.startsWith('.') && !reserved.has(key))
    .sort();
  assert.deepEqual(jobs, ['flutter-test', 'flutter-web-android', 'flutter-windows', 'migration-ledger']);
  assert.equal(config['migration-ledger'].stage, 'validate');
  assert.equal(config['flutter-test'].stage, 'validate');
  assert.equal(config['flutter-web-android'].stage, 'build');
  assert.equal(config['flutter-windows'].stage, 'windows');
  assert.equal(config['.linux-flutter'].image, 'ghcr.io/cirruslabs/flutter:3.47.0');
  for (const job of ['migration-ledger', 'flutter-test', 'flutter-web-android']) {
    assert.equal(config[job].extends, '.linux-flutter');
  }
  assert.deepEqual(config['flutter-windows'].tags, ['windows']);
});

test('GitLab caches only Pub/FVM inputs and retains every platform artifact for seven days', () => {
  const config = parseYaml(pipeline);
  const expectedCachePaths = ['.cache/pub/', '.cache/fvm/'];
  assert.deepEqual(config['.linux-flutter'].cache.paths, expectedCachePaths);
  assert.deepEqual(config['flutter-windows'].cache.paths, expectedCachePaths);
  for (const job of ['flutter-web-android', 'flutter-windows']) {
    assert.equal(config[job].artifacts.expire_in, '7 days');
  }
  assert.deepEqual(config['flutter-web-android'].artifacts.paths, [
    'flutter_workspace/apps/web_app/build/web/',
    'flutter_workspace/apps/android_app/build/app/outputs/flutter-apk/app-release.apk',
  ]);
  assert.deepEqual(config['flutter-windows'].artifacts.paths, [
    'flutter_workspace/apps/windows_app/build/windows/x64/runner/Release/',
  ]);
  const cached = JSON.stringify([config['.linux-flutter'].cache, config['flutter-windows'].cache]);
  assert.doesNotMatch(cached, /(?:^|[\\/])build[\\/]/);
});

test('ordinary CI contains deterministic checks but no live backend configuration', () => {
  const source = read(pipeline);
  assert.match(source, /--enforce-lockfile/);
  assert.match(source, /verify_boundaries\.test\.js/);
  assert.match(source, /dart format --output=none --set-exit-if-changed \./);
  assert.match(source, /dart analyze/);
  assert.match(source, /flutter test/);
  assert.match(source, /flutter build web --release/);
  assert.match(source, /flutter build apk --release/);
  assert.match(source, /check\.ps1/);
  assert.doesNotMatch(source, /SHOUYIN_(?:API|ONLINE|WS)_BASE|--dart-define/);
});

test('migration README documents deterministic local and CI entry points', () => {
  const source = read(path.join(repositoryRoot, 'migration/flutter/README.md'));
  assert.match(source, /node tools\/flutter_migration_inventory\/source_inventory\.js/);
  assert.match(source, /flutter_workspace\/tool\/check\.sh/);
  assert.match(source, /flutter_workspace\\tool\\check\.ps1/);
  for (const job of ['migration-ledger', 'flutter-test', 'flutter-web-android', 'flutter-windows']) {
    assert.match(source, new RegExp(`\\b${job}\\b`));
  }
  assert.match(source, /no live backend URLs, credentials, terminal identifiers, or device secrets/i);
});
