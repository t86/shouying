const test = require('node:test');
const assert = require('node:assert/strict');
const childProcess = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const repositoryRoot = path.join(__dirname, '..');
const workspaceRoot = path.join(repositoryRoot, 'flutter_workspace');

const apps = {
  windows_app: '收银 Windows 客户端',
  web_app: '收银 Web 客户端',
  android_app: '收银 Android 客户端',
};

const packages = [
  'foundation',
  'protocol',
  'session',
  'realtime_sync',
  'permissions',
  'design_system',
  'device_bridge_platform_interface',
  'device_bridge_windows',
  'device_bridge_android',
  'device_bridge_web',
];

function assertFile(relativePath) {
  const absolutePath = path.join(workspaceRoot, relativePath);
  assert.equal(fs.existsSync(absolutePath), true, `${relativePath} must exist`);
  return absolutePath;
}

function readWorkspaceFile(relativePath) {
  return fs.readFileSync(assertFile(relativePath), 'utf8');
}

function assertWorkspaceSdkConstraint(pubspec, relativePath) {
  assert.match(
    pubspec,
    /^\s+sdk:\s*["']?>=3\.13\.0 <4\.0\.0["']?\s*$/m,
    `${relativePath} must require Dart >=3.13.0 <4.0.0`,
  );
}

function listDirectories(relativePath) {
  const absolutePath = assertFile(relativePath);
  return fs.readdirSync(absolutePath, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort();
}

function findMemberArtifacts(memberRoot, predicate, found = []) {
  for (const entry of fs.readdirSync(memberRoot, { withFileTypes: true })) {
    const entryPath = path.join(memberRoot, entry.name);
    if (entry.isDirectory()) {
      findMemberArtifacts(entryPath, predicate, found);
    } else if (predicate(entryPath)) {
      found.push(path.relative(workspaceRoot, entryPath));
    }
  }
  return found;
}

test('pins Flutter 3.47.0 for the workspace', () => {
  const fvmConfig = JSON.parse(readWorkspaceFile('.fvmrc'));
  assert.equal(fvmConfig.flutter, '3.47.0');
});

test('declares a native Pub workspace with the required SDK range', () => {
  const pubspec = readWorkspaceFile('pubspec.yaml');
  assertWorkspaceSdkConstraint(pubspec, 'pubspec.yaml');
  assert.match(
    pubspec,
    /^workspace:\s*\n\s+- apps\/\*\s*\n\s+- packages\/\*\s*$/m,
    'pubspec.yaml must include apps/* and packages/* workspace entries',
  );
});

test('keeps Flutter 3.47 analyzer exclusions stable', () => {
  assert.equal(
    readWorkspaceFile('analysis_options.yaml'),
    [
      'analyzer:',
      '  exclude:',
      '    - build/**',
      '    - android/**',
      '    - ios/**',
      '    - web/**',
      '    - windows/**',
      '    - macos/**',
      '    - linux/**',
      'include: package:flutter_lints/flutter.yaml',
      '',
    ].join('\n'),
  );
});

test('contains exactly the expected app and package members', () => {
  assert.deepEqual(listDirectories('apps'), Object.keys(apps).sort());
  assert.deepEqual(listDirectories('packages'), [...packages].sort());
});

test('uses workspace resolution and the required SDK range in every member', () => {
  const members = [
    ...Object.keys(apps).map((name) => `apps/${name}`),
    ...packages.map((name) => `packages/${name}`),
  ];

  for (const member of members) {
    const relativePath = `${member}/pubspec.yaml`;
    const pubspec = readWorkspaceFile(relativePath);
    assert.match(pubspec, /^resolution:\s+workspace\s*$/m, `${relativePath} must use workspace resolution`);
    assertWorkspaceSdkConstraint(pubspec, relativePath);
  }
});

test('keeps dependency resolution artifacts only at the workspace root', () => {
  assertFile('pubspec.lock');

  const memberRoots = [path.join(workspaceRoot, 'apps'), path.join(workspaceRoot, 'packages')];
  for (const memberRoot of memberRoots) {
    assert.equal(fs.existsSync(memberRoot), true, `${path.relative(workspaceRoot, memberRoot)} must exist`);
  }

  const nestedLocks = memberRoots.flatMap((memberRoot) => findMemberArtifacts(
    memberRoot,
    (filePath) => path.basename(filePath) === 'pubspec.lock',
  ));
  const nestedPackageConfigs = memberRoots.flatMap((memberRoot) => findMemberArtifacts(
    memberRoot,
    (filePath) => filePath.endsWith(`${path.sep}.dart_tool${path.sep}package_config.json`),
  ));

  assert.deepEqual(nestedLocks, [], `unexpected member lockfiles: ${nestedLocks.join(', ')}`);
  assert.deepEqual(
    nestedPackageConfigs,
    [],
    `unexpected member package configs: ${nestedPackageConfigs.join(', ')}`,
  );
});

test('uses focused smoke apps instead of the generated counter demo', () => {
  const generatedDemoStrings = /Flutter Demo Home Page|_counter|incrementCounter/;

  for (const [app, label] of Object.entries(apps)) {
    const mainSource = readWorkspaceFile(`apps/${app}/lib/main.dart`);
    const testSource = readWorkspaceFile(`apps/${app}/test/widget_test.dart`);

    assert.doesNotMatch(mainSource, generatedDemoStrings, `${app} main.dart must not contain counter demo code`);
    assert.doesNotMatch(testSource, generatedDemoStrings, `${app} widget test must not contain counter demo code`);
    assert.match(mainSource, new RegExp(label), `${app} must display its platform label`);
    assert.match(testSource, new RegExp(label), `${app} smoke test must verify its platform label`);
  }
});

test('tracks the generated Android Gradle wrapper', () => {
  const wrapperFiles = [
    'apps/android_app/android/gradlew',
    'apps/android_app/android/gradlew.bat',
    'apps/android_app/android/gradle/wrapper/gradle-wrapper.jar',
    'apps/android_app/android/gradle/wrapper/gradle-wrapper.properties',
  ];

  for (const wrapperFile of wrapperFiles) {
    assertFile(wrapperFile);
    const ignoreCheck = childProcess.spawnSync(
      'git',
      ['check-ignore', '--no-index', '--quiet', `flutter_workspace/${wrapperFile}`],
      { cwd: repositoryRoot },
    );
    assert.equal(ignoreCheck.status, 1, `${wrapperFile} must not be ignored`);
  }

  const androidGitignore = readWorkspaceFile('apps/android_app/android/.gitignore');
  const ignoreEntries = androidGitignore
    .split('\n')
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith('#'));
  assert.equal(ignoreEntries.includes('gradle-wrapper.jar'), false);
  assert.equal(ignoreEntries.includes('/gradlew'), false);
  assert.equal(ignoreEntries.includes('/gradlew.bat'), false);

  const gradlewMode = fs.statSync(path.join(workspaceRoot, wrapperFiles[0])).mode;
  assert.notEqual(gradlewMode & 0o111, 0, 'android/gradlew must be executable');
});
