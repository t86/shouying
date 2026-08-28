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
const snapshotCheck = path.join(repositoryRoot, 'flutter_workspace/tool/snapshot_migration_state.js');
const pipeline = path.join(repositoryRoot, '.gitlab-ci.yml');

function detectPowerShell(spawn = childProcess.spawnSync) {
  for (const executable of ['pwsh', 'powershell.exe']) {
    const probe = spawn(
      executable,
      ['-NoLogo', '-NoProfile', '-NonInteractive', '-Command', '$PSVersionTable.PSVersion.ToString()'],
      { encoding: 'utf8' },
    );
    if (probe.status === 0) return executable;
  }
  return null;
}

const powerShellExecutable = detectPowerShell();
const hasPowerShell = powerShellExecutable !== null;

test('PowerShell detection prefers pwsh and falls back to Windows PowerShell', () => {
  const calls = [];
  const fallback = detectPowerShell((command) => {
    calls.push(command);
    return { status: command === 'powershell.exe' ? 0 : 1 };
  });
  assert.equal(fallback, 'powershell.exe');
  assert.deepEqual(calls, ['pwsh', 'powershell.exe']);

  calls.length = 0;
  const preferred = detectPowerShell((command) => {
    calls.push(command);
    return { status: 0 };
  });
  assert.equal(preferred, 'pwsh');
  assert.deepEqual(calls, ['pwsh']);
  assert.equal(detectPowerShell(() => ({ status: 1 })), null);
});

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
  fs.copyFileSync(snapshotCheck, path.join(tool, 'snapshot_migration_state.js'));
  fs.chmodSync(path.join(tool, 'check.sh'), 0o755);
  const trackedFile = path.join(workspace, 'tracked.txt');
  fs.writeFileSync(trackedFile, 'clean\n');

  const commandStub = [
    '#!/bin/sh',
    'entry="$(basename "$0")|$PWD|$*"',
    'printf "%s\\n" "$entry" >> "$CHECK_LOG"',
    'case "$1" in */snapshot_migration_state.js) exec "$CHECK_REAL_NODE" "$@" ;; esac',
    'if [ "${CHECK_DIRTY_AFTER_BUILD:-0}" = "1" ] && [ "$(basename "$0")" = "fvm" ]; then',
    '  case "$*" in flutter\\ build\\ *) printf "dirty\\n" >> "$CHECK_TRACKED_FILE" ;; esac',
    'fi',
    'case "$entry" in',
    '  *"${CHECK_FAIL_PATTERN:-__never__}"*) exit 42 ;;',
    'esac',
  ].join('\n');
  for (const command of ['fvm', 'node']) {
    const target = path.join(bin, command);
    fs.writeFileSync(target, `${commandStub}\n`, { mode: 0o755 });
  }
  const realGit = childProcess.spawnSync('sh', ['-c', 'command -v git'], { encoding: 'utf8' }).stdout.trim();
  assert.notEqual(realGit, '', 'git is required for the shell behavior fixture');
  const gitStub = [
    '#!/bin/sh',
    'if [ "$1" != "ls-files" ]; then',
    '  entry="git|$PWD|$*"',
    '  printf "%s\\n" "$entry" >> "$CHECK_LOG"',
    'fi',
    'exec "$CHECK_REAL_GIT" "$@"',
  ].join('\n');
  fs.writeFileSync(path.join(bin, 'git'), `${gitStub}\n`, { mode: 0o755 });
  for (const args of [
    ['init', '--quiet'],
    ['config', 'user.name', 'Fixture'],
    ['config', 'user.email', 'fixture@example.invalid'],
    ['add', '.'],
    ['commit', '--quiet', '-m', 'fixture'],
  ]) {
    const result = childProcess.spawnSync(realGit, args, { cwd: root, encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
  }
  return {
    root,
    workspace,
    bin,
    realGit,
    trackedFile,
    script: path.join(tool, 'check.sh'),
  };
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
      CHECK_DIRTY_AFTER_BUILD: options.dirtyAfterBuild ? '1' : '0',
      CHECK_TRACKED_FILE: fixture.trackedFile,
      CHECK_REAL_GIT: fixture.realGit,
      CHECK_REAL_NODE: process.execPath,
    },
  });
  fs.rmSync(unrelatedCwd, { recursive: true, force: true });
  return {
    ...result,
    commands: fs.existsSync(log) ? read(log).trim().split('\n') : [],
  };
}

function makePowerShellFixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'flutter-ps-check-'));
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
  fs.copyFileSync(powershellCheck, path.join(tool, 'check.ps1'));
  fs.copyFileSync(snapshotCheck, path.join(tool, 'snapshot_migration_state.js'));
  const trackedFile = path.join(workspace, 'tracked.txt');
  fs.writeFileSync(trackedFile, 'clean\n');

  let realGit;
  if (process.platform === 'win32') {
    const result = childProcess.spawnSync('where.exe', ['git.exe'], { encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
    realGit = result.stdout.split(/\r?\n/).find(Boolean);
  } else {
    realGit = childProcess.spawnSync('sh', ['-c', 'command -v git'], { encoding: 'utf8' }).stdout.trim();
  }
  assert.notEqual(realGit, '', 'git is required for the PowerShell behavior fixture');

  if (process.platform === 'win32') {
    const fvmStub = [
      '@echo off',
      'set "entry=fvm|%CD%|%*"',
      '>>"%CHECK_LOG%" echo %entry%',
      'if "%CHECK_DIRTY_AFTER_BUILD%"=="1" if /I "%~1"=="flutter" if /I "%~2"=="build" >>"%CHECK_TRACKED_FILE%" echo dirty',
      'if /I "%CHECK_FAIL_PATTERN%"=="dart analyze" if /I "%~1"=="dart" if /I "%~2"=="analyze" exit /b 42',
      'exit /b 0',
    ].join('\r\n');
    fs.writeFileSync(path.join(bin, 'fvm.cmd'), `${fvmStub}\r\n`);
    const nodeStub = [
      '@echo off',
      '>>"%CHECK_LOG%" echo node^|%CD%^|%*',
      'if /I not "%~nx1"=="snapshot_migration_state.js" goto node_done',
      '"%CHECK_REAL_NODE%" %*',
      'exit /b %ERRORLEVEL%',
      ':node_done',
      'exit /b 0',
    ].join('\r\n');
    fs.writeFileSync(path.join(bin, 'node.cmd'), `${nodeStub}\r\n`);
    const gitStub = [
      '@echo off',
      'if /I "%~1"=="ls-files" goto git_run',
      '>>"%CHECK_LOG%" echo git^|%CD%^|%*',
      ':git_run',
      '"%CHECK_REAL_GIT%" %*',
      'exit /b %ERRORLEVEL%',
    ].join('\r\n');
    fs.writeFileSync(path.join(bin, 'git.cmd'), `${gitStub}\r\n`);
  } else {
    const nativeStub = [
      '#!/bin/sh',
      'entry="$(basename "$0")|$PWD|$*"',
      'printf "%s\\n" "$entry" >> "$CHECK_LOG"',
      'case "$1" in */snapshot_migration_state.js) exec "$CHECK_REAL_NODE" "$@" ;; esac',
      'if [ "${CHECK_DIRTY_AFTER_BUILD:-0}" = "1" ] && [ "$(basename "$0")" = "fvm" ]; then',
      '  case "$*" in flutter\\ build\\ windows\\ *) printf "dirty\\n" >> "$CHECK_TRACKED_FILE" ;; esac',
      'fi',
      'case "$entry" in *"${CHECK_FAIL_PATTERN:-__never__}"*) exit 42 ;; esac',
    ].join('\n');
    for (const command of ['fvm', 'node']) fs.writeFileSync(path.join(bin, command), `${nativeStub}\n`, { mode: 0o755 });
    const gitStub = [
      '#!/bin/sh',
      'if [ "$1" != "ls-files" ]; then printf "git|%s|%s\\n" "$PWD" "$*" >> "$CHECK_LOG"; fi',
      'exec "$CHECK_REAL_GIT" "$@"',
    ].join('\n');
    fs.writeFileSync(path.join(bin, 'git'), `${gitStub}\n`, { mode: 0o755 });
  }

  for (const args of [
    ['init', '--quiet'],
    ['config', 'user.name', 'Fixture'],
    ['config', 'user.email', 'fixture@example.invalid'],
    ['add', '.'],
    ['commit', '--quiet', '-m', 'fixture'],
  ]) {
    const result = childProcess.spawnSync(realGit, args, { cwd: root, encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
  }
  return {
    root,
    workspace,
    bin,
    realGit,
    trackedFile,
    script: path.join(tool, 'check.ps1'),
  };
}

function runPowerShellFixture(fixture, options = {}) {
  const log = path.join(fixture.root, 'commands.log');
  const unrelatedCwd = fs.mkdtempSync(path.join(os.tmpdir(), 'flutter-ps-cwd-'));
  const result = childProcess.spawnSync(
    powerShellExecutable,
    ['-NoLogo', '-NoProfile', '-NonInteractive', '-File', fixture.script],
    {
      cwd: unrelatedCwd,
      encoding: 'utf8',
      env: {
        ...process.env,
        PATH: `${fixture.bin}${path.delimiter}${process.env.PATH}`,
        CHECK_LOG: log,
        CHECK_FAIL_PATTERN: options.failPattern || '__never__',
        CHECK_DIRTY_AFTER_BUILD: options.dirtyAfterBuild ? '1' : '0',
        CHECK_TRACKED_FILE: fixture.trackedFile,
        CHECK_REAL_GIT: fixture.realGit,
        CHECK_REAL_NODE: process.execPath,
      },
    },
  );
  fs.rmSync(unrelatedCwd, { recursive: true, force: true });
  return {
    ...result,
    commands: fs.existsSync(log) ? read(log).trim().split(/\r?\n/) : [],
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

function makeFvmBootstrapFixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'fvm-bootstrap-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const workspace = path.join(root, 'flutter_workspace');
  const bin = path.join(root, 'bin');
  const log = path.join(root, 'fvm.log');
  fs.mkdirSync(workspace, { recursive: true });
  fs.mkdirSync(bin, { recursive: true });
  if (process.platform === 'win32') {
    const stub = [
      '@echo off',
      '>>"%FVM_LOG%" echo fvm^|%CD%^|%*',
      'if /I "%~1"=="install" if "%FVM_FAIL_INSTALL%"=="1" exit /b 42',
      'if /I "%~1"=="flutter" if /I "%~2"=="--version" if "%FVM_FAIL_VERSION%"=="1" exit /b 43',
      'if /I "%~1"=="flutter" if /I "%~2"=="--version" echo Flutter %FVM_REPORTED_VERSION% fixture',
      'exit /b 0',
    ].join('\r\n');
    fs.writeFileSync(path.join(bin, 'fvm.cmd'), `${stub}\r\n`);
  } else {
    const stub = [
      '#!/bin/sh',
      'printf "fvm|%s|%s\\n" "$PWD" "$*" >> "$FVM_LOG"',
      'if [ "$1" = "install" ] && [ "${FVM_FAIL_INSTALL:-0}" = "1" ]; then exit 42; fi',
      'if [ "$1" = "flutter" ] && [ "$2" = "--version" ] && [ "${FVM_FAIL_VERSION:-0}" = "1" ]; then exit 43; fi',
      'if [ "$1" = "flutter" ] && [ "$2" = "--version" ]; then printf "Flutter %s fixture\\n" "$FVM_REPORTED_VERSION"; fi',
    ].join('\n');
    fs.writeFileSync(path.join(bin, 'fvm'), `${stub}\n`, { mode: 0o755 });
  }
  return { root, workspace, bin, log };
}

function fvmBootstrapEnvironment(fixture, options = {}) {
  return {
    ...process.env,
    PATH: `${fixture.bin}${path.delimiter}${process.env.PATH}`,
    CI_PROJECT_DIR: fixture.root,
    FLUTTER_VERSION: '3.47.0',
    FVM_LOG: fixture.log,
    FVM_FAIL_INSTALL: options.failInstall ? '1' : '0',
    FVM_FAIL_VERSION: options.failVersion ? '1' : '0',
    FVM_REPORTED_VERSION: options.reportedVersion || '3.47.0',
  };
}

function bootstrapLog(fixture) {
  return fs.existsSync(fixture.log) ? read(fixture.log).trim().split(/\r?\n/) : [];
}

function assertFvmBootstrapLog(fixture, expectedArguments) {
  const entries = bootstrapLog(fixture).map((line) => {
    const [command, cwd, ...args] = line.split('|');
    return { command, cwd, args: args.join('|') };
  });
  assert.deepEqual(entries.map((entry) => entry.args), expectedArguments);
  for (const entry of entries) {
    assert.equal(entry.command, 'fvm');
    assert.equal(fs.realpathSync(entry.cwd), fs.realpathSync(fixture.workspace));
  }
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
  for (const file of [shellCheck, powershellCheck, snapshotCheck, pipeline]) {
    assert.equal(fs.existsSync(file), true, `${path.relative(repositoryRoot, file)} must exist`);
  }
  if (process.platform !== 'win32') {
    assert.notEqual(fs.statSync(shellCheck).mode & 0o111, 0, 'check.sh must be executable');
  }
  assert.doesNotThrow(() => parseYaml(pipeline));
});

test('check.sh resolves roots from itself and runs the complete gate in order', {
  skip: process.platform === 'win32',
}, (t) => {
  const fixture = makeShellFixture(t);
  const result = runFixture(fixture);
  assert.equal(result.status, 0, `${result.stdout}\n${result.stderr}`);

  const root = fixture.root;
  const workspace = fixture.workspace;
  assert.deepEqual(result.commands, [
    `fvm|${workspace}|dart pub get --enforce-lockfile`,
    `node|${root}|--test ${root}/tests/flutterMigrationInventory.test.js ${root}/tests/flutterWorkspaceStructure.test.js ${root}/tests/flutterCiChecks.test.js ${root}/tests/flutterFeasibilityReport.test.js ${root}/tests/flutterWebDevProxy.test.js`,
    `node|${root}|${root}/tools/flutter_migration_inventory/validate_ledgers.js`,
    `node|${root}|${root}/tools/flutter_migration_inventory/source_inventory.js`,
    `node|${root}|${root}/tools/flutter_migration_inventory/generate_report.js`,
    `git|${root}|diff --exit-code -- migration/flutter/generated/source-inventory.json migration/flutter/generated/coverage.md`,
    `node|${workspace}|--test ${workspace}/tool/verify_boundaries.test.js`,
    `node|${workspace}|${workspace}/tool/verify_boundaries.js ${workspace}`,
    `fvm|${workspace}|dart format --output=none --set-exit-if-changed .`,
    `fvm|${workspace}|dart analyze`,
    `fvm|${workspace}|flutter test packages/design_system packages/device_bridge_android packages/device_bridge_platform_interface packages/device_bridge_web packages/device_bridge_windows packages/foundation packages/permissions packages/protocol packages/realtime_sync packages/session apps/android_app apps/web_app apps/windows_app`,
    `node|${root}|${workspace}/tool/snapshot_migration_state.js`,
    `fvm|${workspace}/apps/web_app|flutter build web --release`,
    `fvm|${workspace}/apps/android_app|flutter build apk --release`,
    `node|${root}|${workspace}/tool/snapshot_migration_state.js`,
  ]);
});

test('check.sh stops immediately after the first failed native command', {
  skip: process.platform === 'win32',
}, (t) => {
  const fixture = makeShellFixture(t);
  const result = runFixture(fixture, { failPattern: 'dart analyze' });
  assert.equal(result.status, 42);
  assert.match(result.commands.at(-1), /dart analyze$/);
  assert.equal(result.commands.some((command) => command.includes('flutter test')), false);
  assert.equal(result.commands.some((command) => command.includes('flutter build')), false);
});

test('check.sh fails when a build changes a tracked migration file', {
  skip: process.platform === 'win32',
}, (t) => {
  const fixture = makeShellFixture(t);
  const result = runFixture(fixture, { dirtyAfterBuild: true });
  assert.equal(result.status, 1);
  assert.match(result.commands.at(-1), /node\|.*\|.*snapshot_migration_state\.js$/);
  assert.equal(read(fixture.trackedFile), 'clean\ndirty\ndirty\n');
});

test('check.sh permits unchanged pre-existing staged, unstaged, and untracked state', {
  skip: process.platform === 'win32',
}, (t) => {
  const fixture = makeShellFixture(t);
  fs.appendFileSync(fixture.trackedFile, 'staged-before-run\n');
  let result = childProcess.spawnSync(
    fixture.realGit,
    ['add', 'flutter_workspace/tracked.txt'],
    { cwd: fixture.root, encoding: 'utf8' },
  );
  assert.equal(result.status, 0, result.stderr);
  fs.appendFileSync(fixture.trackedFile, 'unstaged-before-run\n');
  fs.writeFileSync(
    path.join(fixture.workspace, 'pre-existing-untracked.txt'),
    'untracked-before-run\n',
  );

  result = runFixture(fixture);
  assert.equal(result.status, 0, `${result.stdout}\n${result.stderr}`);
  assert.equal(
    read(fixture.trackedFile),
    'clean\nstaged-before-run\nunstaged-before-run\n',
  );
});

test('PowerShell check uses checked native calls in the same required order', () => {
  const source = read(powershellCheck);
  assert.match(source, /\$MyInvocation\.MyCommand\.Path/);
  assert.match(source, /Set-StrictMode -Version Latest/);
  assert.match(source, /\$LASTEXITCODE/);
  assert.match(source, /throw/);
  assertOrdered(source, [
    "@('dart', 'pub', 'get', '--enforce-lockfile')",
    "@('--test', $InventoryTest, $WorkspaceStructureTest, $CiChecksTest, $FeasibilityTest, $WebDevProxyTest)",
    "@($LedgerValidator)",
    "@($InventoryGenerator)",
    "@($ReportGenerator)",
    "@('diff', '--exit-code', '--', 'migration/flutter/generated/source-inventory.json', 'migration/flutter/generated/coverage.md')",
    "@('--test', $BoundaryTest)",
    "@($BoundaryCli, $WorkspaceRoot)",
    "@('dart', 'format', '--output=none', '--set-exit-if-changed', '.')",
    "@('dart', 'analyze')",
    "@('flutter', 'test') + $FlutterMembers",
    '$BuildStateBefore = Get-MigrationStateSnapshot',
    "@('flutter', 'build', 'windows', '--release')",
    '$BuildStateAfter = Get-MigrationStateSnapshot',
  ]);
});

test('Windows hosts provide pwsh for the PowerShell behavior gate', {
  skip: process.platform !== 'win32',
}, () => {
  assert.notEqual(powerShellExecutable, null, 'PowerShell is required on the Windows runner');
});

test('check.ps1 resolves roots and runs every checked command in order', {
  skip: !hasPowerShell,
}, (t) => {
  const fixture = makePowerShellFixture(t);
  const result = runPowerShellFixture(fixture);
  assert.equal(result.status, 0, `${result.stdout}\n${result.stderr}`);
  const normalized = result.commands.map((command) => command.replaceAll('\\', '/').replaceAll('"', ''));
  const root = fixture.root.replaceAll('\\', '/');
  const workspace = fixture.workspace.replaceAll('\\', '/');
  assert.deepEqual(normalized, [
    `fvm|${workspace}|dart pub get --enforce-lockfile`,
    `node|${root}|--test ${root}/tests/flutterMigrationInventory.test.js ${root}/tests/flutterWorkspaceStructure.test.js ${root}/tests/flutterCiChecks.test.js ${root}/tests/flutterFeasibilityReport.test.js ${root}/tests/flutterWebDevProxy.test.js`,
    `node|${root}|${root}/tools/flutter_migration_inventory/validate_ledgers.js`,
    `node|${root}|${root}/tools/flutter_migration_inventory/source_inventory.js`,
    `node|${root}|${root}/tools/flutter_migration_inventory/generate_report.js`,
    `git|${root}|diff --exit-code -- migration/flutter/generated/source-inventory.json migration/flutter/generated/coverage.md`,
    `node|${workspace}|--test ${workspace}/tool/verify_boundaries.test.js`,
    `node|${workspace}|${workspace}/tool/verify_boundaries.js ${workspace}`,
    `fvm|${workspace}|dart format --output=none --set-exit-if-changed .`,
    `fvm|${workspace}|dart analyze`,
    `fvm|${workspace}|flutter test ${workspace}/packages/design_system ${workspace}/packages/device_bridge_android ${workspace}/packages/device_bridge_platform_interface ${workspace}/packages/device_bridge_web ${workspace}/packages/device_bridge_windows ${workspace}/packages/foundation ${workspace}/packages/permissions ${workspace}/packages/protocol ${workspace}/packages/realtime_sync ${workspace}/packages/session ${workspace}/apps/android_app ${workspace}/apps/web_app ${workspace}/apps/windows_app`,
    `node|${root}|${workspace}/tool/snapshot_migration_state.js`,
    `fvm|${workspace}/apps/windows_app|flutter build windows --release`,
    `node|${root}|${workspace}/tool/snapshot_migration_state.js`,
  ]);
});

test('check.ps1 stops on the first failure and rejects tracked build changes', {
  skip: !hasPowerShell,
}, (t) => {
  let fixture = makePowerShellFixture(t);
  let result = runPowerShellFixture(fixture, { failPattern: 'dart analyze' });
  assert.equal(result.status, 1);
  assert.match(result.commands.at(-1), /dart analyze$/);
  assert.equal(result.commands.some((command) => command.includes('flutter build')), false);

  fixture = makePowerShellFixture(t);
  result = runPowerShellFixture(fixture, { dirtyAfterBuild: true });
  assert.equal(result.status, 1);
  assert.match(result.commands.at(-1), /snapshot_migration_state\.js$/);

  fixture = makePowerShellFixture(t);
  fs.appendFileSync(fixture.trackedFile, 'staged-before-run\n');
  result = childProcess.spawnSync(
    fixture.realGit,
    ['add', 'flutter_workspace/tracked.txt'],
    { cwd: fixture.root, encoding: 'utf8' },
  );
  assert.equal(result.status, 0, result.stderr);
  fs.appendFileSync(fixture.trackedFile, 'unstaged-before-run\n');
  fs.writeFileSync(
    path.join(fixture.workspace, 'pre-existing-untracked.txt'),
    'untracked-before-run\n',
  );
  result = runPowerShellFixture(fixture);
  assert.equal(result.status, 0, `${result.stdout}\n${result.stderr}`);
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
  assert.equal(
    config['.linux-flutter'].image,
    'ghcr.io/cirruslabs/flutter:3.44.0@sha256:46691e311715845de03a3ba4753a475476936805b29431b1f00f1816981033f8',
  );
  assert.equal(config.variables.FLUTTER_VERSION, '3.47.0');
  assert.doesNotMatch(config['.linux-flutter'].image, /flutter:3\.47\.0(?:$|@)/);
  assert.match(config['.linux-flutter'].before_script.join('\n'), /fvm install "\$FLUTTER_VERSION"/);
  assert.match(config['.linux-flutter'].before_script.join('\n'), /grep -F "Flutter \$FLUTTER_VERSION "/);
  const windowsBootstrap = config['flutter-windows'].before_script.find((command) => (
    command.includes('Push-Location')
  ));
  assert.match(windowsBootstrap, /CI_PROJECT_DIR.*flutter_workspace/);
  assert.match(windowsBootstrap, /\$LASTEXITCODE/);
  assert.match(windowsBootstrap, /FlutterVersionOutput/);
  assert.match(windowsBootstrap, /finally\s*\{\s*Pop-Location\s*\}/);
  for (const job of ['migration-ledger', 'flutter-test', 'flutter-web-android']) {
    assert.equal(config[job].extends, '.linux-flutter');
  }
  assert.deepEqual(config['flutter-windows'].tags, ['windows']);
});

test('Linux FVM bootstrap runs in the workspace, propagates failure, and restores cwd', (t) => {
  const config = parseYaml(pipeline);
  const command = config['.linux-flutter'].before_script.find((item) => item.includes('fvm install'));
  const fixture = makeFvmBootstrapFixture(t);
  const wrapper = `${command}\nbootstrap_code=$?\npwd\nexit $bootstrap_code`;
  let result = childProcess.spawnSync('/bin/sh', ['-c', wrapper], {
    cwd: fixture.root,
    encoding: 'utf8',
    env: fvmBootstrapEnvironment(fixture),
  });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(
    fs.realpathSync(result.stdout.trim().split(/\r?\n/).at(-1)),
    fs.realpathSync(fixture.root),
  );
  assertFvmBootstrapLog(fixture, ['install 3.47.0', 'flutter --version']);

  fs.writeFileSync(fixture.log, '');
  result = childProcess.spawnSync('/bin/sh', ['-c', wrapper], {
    cwd: fixture.root,
    encoding: 'utf8',
    env: fvmBootstrapEnvironment(fixture, { failInstall: true }),
  });
  assert.equal(result.status, 42);
  assert.equal(
    fs.realpathSync(result.stdout.trim().split(/\r?\n/).at(-1)),
    fs.realpathSync(fixture.root),
  );
  assertFvmBootstrapLog(fixture, ['install 3.47.0']);

  fs.writeFileSync(fixture.log, '');
  result = childProcess.spawnSync('/bin/sh', ['-c', wrapper], {
    cwd: fixture.root,
    encoding: 'utf8',
    env: fvmBootstrapEnvironment(fixture, { failVersion: true }),
  });
  assert.equal(result.status, 43);
  assert.equal(
    fs.realpathSync(result.stdout.trim().split(/\r?\n/).at(-1)),
    fs.realpathSync(fixture.root),
  );
  assertFvmBootstrapLog(fixture, ['install 3.47.0', 'flutter --version']);

  fs.writeFileSync(fixture.log, '');
  result = childProcess.spawnSync('/bin/sh', ['-c', wrapper], {
    cwd: fixture.root,
    encoding: 'utf8',
    env: fvmBootstrapEnvironment(fixture, { reportedVersion: '3.46.0' }),
  });
  assert.equal(result.status, 1);
  assert.equal(
    fs.realpathSync(result.stdout.trim().split(/\r?\n/).at(-1)),
    fs.realpathSync(fixture.root),
  );
});

test('Windows FVM bootstrap runs in the workspace and restores cwd on failure', {
  skip: !hasPowerShell,
}, (t) => {
  const config = parseYaml(pipeline);
  const command = config['flutter-windows'].before_script.find((item) => item.includes('Push-Location'));
  const fixture = makeFvmBootstrapFixture(t);
  const wrapper = [
    '$BootstrapCode = 0',
    `try { ${command} } catch { $BootstrapCode = 73 }`,
    'Write-Output ((Get-Location).Path)',
    'exit $BootstrapCode',
  ].join('; ');
  let result = childProcess.spawnSync(
    powerShellExecutable,
    ['-NoLogo', '-NoProfile', '-NonInteractive', '-Command', wrapper],
    {
      cwd: fixture.root,
      encoding: 'utf8',
      env: fvmBootstrapEnvironment(fixture),
    },
  );
  assert.equal(result.status, 0, `${result.stdout}\n${result.stderr}`);
  assert.equal(
    fs.realpathSync(result.stdout.trim().split(/\r?\n/).at(-1)),
    fs.realpathSync(fixture.root),
  );
  assertFvmBootstrapLog(fixture, ['install 3.47.0', 'flutter --version']);

  fs.writeFileSync(fixture.log, '');
  result = childProcess.spawnSync(
    powerShellExecutable,
    ['-NoLogo', '-NoProfile', '-NonInteractive', '-Command', wrapper],
    {
      cwd: fixture.root,
      encoding: 'utf8',
      env: fvmBootstrapEnvironment(fixture, { failInstall: true }),
    },
  );
  assert.equal(result.status, 73);
  assert.equal(
    fs.realpathSync(result.stdout.trim().split(/\r?\n/).at(-1)),
    fs.realpathSync(fixture.root),
  );

  fs.writeFileSync(fixture.log, '');
  result = childProcess.spawnSync(
    powerShellExecutable,
    ['-NoLogo', '-NoProfile', '-NonInteractive', '-Command', wrapper],
    {
      cwd: fixture.root,
      encoding: 'utf8',
      env: fvmBootstrapEnvironment(fixture, { failVersion: true }),
    },
  );
  assert.equal(result.status, 73);
  assert.equal(
    fs.realpathSync(result.stdout.trim().split(/\r?\n/).at(-1)),
    fs.realpathSync(fixture.root),
  );

  fs.writeFileSync(fixture.log, '');
  result = childProcess.spawnSync(
    powerShellExecutable,
    ['-NoLogo', '-NoProfile', '-NonInteractive', '-Command', wrapper],
    {
      cwd: fixture.root,
      encoding: 'utf8',
      env: fvmBootstrapEnvironment(fixture, { reportedVersion: '3.46.0' }),
    },
  );
  assert.equal(result.status, 73);
  assert.equal(
    fs.realpathSync(result.stdout.trim().split(/\r?\n/).at(-1)),
    fs.realpathSync(fixture.root),
  );
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
  assert.match(source, /3\.44\.0.*bootstrap.*FVM.*3\.47\.0/is);
});

test('pins every app analyzer file to the Flutter 3.47 migrated form', () => {
  const expected = [
    'analyzer:',
    '  exclude:',
    '    - build/**',
    '    - android/**',
    '    - ios/**',
    '    - web/**',
    '    - windows/**',
    '    - macos/**',
    '    - linux/**',
    'include: ../../analysis_options.yaml',
    '',
  ].join('\n');
  for (const app of ['android_app', 'web_app', 'windows_app']) {
    assert.equal(
      read(path.join(repositoryRoot, `flutter_workspace/apps/${app}/analysis_options.yaml`)),
      expected,
      `${app} must be pre-normalized before release builds`,
    );
  }
});

test('pins the Windows registrant to the current native plugin set', () => {
  const generatedRoot = path.join(
    repositoryRoot,
    'flutter_workspace/apps/windows_app/windows/flutter',
  );
  const registrant = read(path.join(generatedRoot, 'generated_plugin_registrant.cc'));
  const cmake = read(path.join(generatedRoot, 'generated_plugins.cmake'));
  const pluginBlock = /list\(APPEND FLUTTER_PLUGIN_LIST\n([\s\S]*?)\n\)/.exec(cmake)?.[1];
  const plugins = pluginBlock
    ?.split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);

  assert.deepEqual(plugins, ['flutter_secure_storage_windows', 'printing']);
  assert.match(registrant, /#include <flutter_secure_storage_windows\/flutter_secure_storage_windows_plugin\.h>/);
  assert.match(registrant, /#include <printing\/printing_plugin\.h>/);
  assert.match(registrant, /FlutterSecureStorageWindowsPluginRegisterWithRegistrar/);
  assert.match(registrant, /PrintingPluginRegisterWithRegistrar/);
  assert.doesNotMatch(
    `${registrant}\n${cmake}`,
    /(?:[A-Za-z]:\\Users\\|\/Users\/|BEGIN [A-Z ]+ PRIVATE KEY|SHOUYIN_(?:API|ONLINE|WS)_BASE)/,
  );
});

test('migration snapshot distinguishes index, worktree, and nonignored untracked changes', (t) => {
  const { snapshotDigest } = require('../flutter_workspace/tool/snapshot_migration_state');
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'migration-snapshot-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  fs.mkdirSync(path.join(root, 'flutter_workspace/apps/web_app'), { recursive: true });
  fs.mkdirSync(path.join(root, 'migration/flutter/generated'), { recursive: true });
  fs.writeFileSync(
    path.join(root, '.gitignore'),
    'flutter_workspace/**/build/\n',
  );
  const tracked = path.join(root, 'flutter_workspace/tracked.txt');
  fs.writeFileSync(tracked, 'base\n');
  fs.writeFileSync(path.join(root, 'migration/flutter/generated/report.md'), 'report\n');
  for (const args of [
    ['init', '--quiet'],
    ['config', 'user.name', 'Fixture'],
    ['config', 'user.email', 'fixture@example.invalid'],
    ['add', '.'],
    ['commit', '--quiet', '-m', 'fixture'],
  ]) {
    const result = childProcess.spawnSync('git', args, { cwd: root, encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
  }

  const baseline = snapshotDigest(root);
  fs.appendFileSync(tracked, 'pre-existing unstaged\n');
  const unstaged = snapshotDigest(root);
  assert.notEqual(unstaged, baseline);
  assert.equal(snapshotDigest(root), unstaged, 'unchanged pre-existing dirt must be stable');

  let result = childProcess.spawnSync('git', ['add', 'flutter_workspace/tracked.txt'], {
    cwd: root,
    encoding: 'utf8',
  });
  assert.equal(result.status, 0, result.stderr);
  const staged = snapshotDigest(root);
  assert.notEqual(staged, unstaged, 'staging must change the snapshot even when content is unchanged');

  fs.writeFileSync(path.join(root, 'flutter_workspace/untracked.txt'), 'new\n');
  const untracked = snapshotDigest(root);
  assert.notEqual(untracked, staged);

  fs.mkdirSync(path.join(root, 'flutter_workspace/apps/web_app/build'), { recursive: true });
  fs.writeFileSync(path.join(root, 'flutter_workspace/apps/web_app/build/output.bin'), 'ignored\n');
  assert.equal(snapshotDigest(root), untracked, 'ignored build outputs must not affect the snapshot');
});
