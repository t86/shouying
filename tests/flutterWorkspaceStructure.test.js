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

const packageDescriptions = {
  foundation: 'Internal shared foundations for Shouyin Flutter applications.',
  protocol: 'Internal protocol contracts for Shouyin service communication.',
  session: 'Internal session lifecycle coordination for Shouyin Flutter applications.',
  realtime_sync: 'Internal real-time state synchronization for Shouyin Flutter applications.',
  permissions: 'Internal permission policy coordination for Shouyin Flutter applications.',
  design_system: 'Internal design foundations shared by Shouyin Flutter applications.',
  device_bridge_platform_interface: 'Internal platform contracts for Shouyin device integrations.',
  device_bridge_windows: 'Internal Windows boundary for Shouyin device integrations.',
  device_bridge_android: 'Internal Android boundary for Shouyin device integrations.',
  device_bridge_web: 'Internal Web boundary for Shouyin device integrations.',
};

const packages = Object.keys(packageDescriptions);

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
  const options = readWorkspaceFile('analysis_options.yaml');
  const optionRows = options.split('\n').map((line) => ({ indent: line.match(/^\s*/)[0].length, text: line.trim() }));
  const optionLines = optionRows.map((row) => row.text);
  const rowFor = (text) => optionRows.find((row) => row.text === text);
  assert.equal(rowFor('include: package:flutter_lints/flutter.yaml').indent, 0);
  assert.equal(rowFor('analyzer:').indent, 0);
  assert.equal(rowFor('exclude:').indent, 2);
  assert.equal(rowFor('linter:').indent, 0);
  assert.equal(rowFor('rules:').indent, 2);
  for (const entry of ['build/**', 'android/**', 'ios/**', 'web/**', 'windows/**', 'macos/**', 'linux/**']) {
    const row = rowFor(`- ${entry}`);
    assert.equal(row?.indent, 4, `${entry} must be nested under analyzer.exclude`);
  }
  assert.match(options, /^include:\s*package:flutter_lints\/flutter\.yaml\s*$/m);
  for (const rule of ['avoid_print', 'cancel_subscriptions', 'close_sinks', 'discarded_futures', 'unawaited_futures', 'use_build_context_synchronously', 'always_use_package_imports']) {
    assert.equal(rowFor(`${rule}: true`)?.indent, 4, `${rule} must be nested under linter.rules`);
  }
});

test('routes every member through the shared analyzer configuration', () => {
  const members = [
    ...Object.keys(apps).map((name) => `apps/${name}`),
    ...packages.map((name) => `packages/${name}`),
  ];

  for (const member of members) {
    const relativePath = `${member}/analysis_options.yaml`;
    const meaningfulLines = readWorkspaceFile(relativePath)
      .split('\n')
      .map((line) => line.replace(/\s+#.*$/, '').trim())
      .filter((line) => line && !line.startsWith('#'));

    assert.deepEqual(
      meaningfulLines,
      ['include: ../../analysis_options.yaml'],
      `${relativePath} must only include the shared analyzer configuration`,
    );
  }
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

test('marks every internal package as non-publishable', () => {
  for (const packageName of packages) {
    const relativePath = `packages/${packageName}/pubspec.yaml`;
    assert.match(
      readWorkspaceFile(relativePath),
      /^publish_to:\s*["']?none["']?\s*$/m,
      `${relativePath} must set publish_to: none`,
    );
  }
});

test('removes generated placeholders from internal packages', () => {
  const generatedPlaceholders = /class Calculator|\baddOne\b|TODO:|A new Flutter package project/;

  for (const [packageName, description] of Object.entries(packageDescriptions)) {
    const packageRoot = path.join(workspaceRoot, 'packages', packageName);
    const generatedTest = path.join(packageRoot, 'test', `${packageName}_test.dart`);
    const license = path.join(packageRoot, 'LICENSE');
    const relativeFiles = [
      `packages/${packageName}/lib/${packageName}.dart`,
      `packages/${packageName}/README.md`,
      `packages/${packageName}/CHANGELOG.md`,
      `packages/${packageName}/pubspec.yaml`,
    ];

    if (fs.existsSync(generatedTest)) {
      relativeFiles.push(path.relative(workspaceRoot, generatedTest));
    }

    const contents = relativeFiles.map((relativePath) => readWorkspaceFile(relativePath));
    assert.doesNotMatch(
      contents.join('\n'),
      generatedPlaceholders,
      `${packageName} must not retain generated package placeholders`,
    );
    assert.equal(fs.existsSync(generatedTest), false, `${packageName} generated calculator test must be removed`);
    assert.equal(fs.existsSync(license), false, `${packageName} placeholder license must be removed`);

    const librarySource = contents[0];
    const nonCommentLibraryLines = librarySource
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith('///'));
    assert.equal(librarySource.includes(`/// ${description}`), true, `${packageName} must document its responsibility`);
    assert.deepEqual(nonCommentLibraryLines, ['library;'], `${packageName} must not declare a placeholder API`);

    assert.equal(contents[1].includes(description), true, `${packageName} README must be package-specific`);
    assert.equal(contents[2].includes(`\`${packageName}\``), true, `${packageName} changelog must be package-specific`);
    assert.equal(
      contents[3].includes(`description: "${description}"`),
      true,
      `${packageName} pubspec description must be package-specific`,
    );
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
