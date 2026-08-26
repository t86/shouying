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

function parseYamlSubset(source) {
  const root = {};
  const stack = [{ indent: -1, value: root }];
  for (const rawLine of source.split('\n')) {
    const line = rawLine.replace(/\s+#.*$/, '');
    if (!line.trim()) continue;
    const indent = line.match(/^\s*/)[0].length;
    const text = line.trim();
    while (stack.at(-1).indent >= indent) stack.pop();
    const parent = stack.at(-1).value;
    if (text.startsWith('- ')) {
      assert.equal(Array.isArray(parent), true, `list item must have a list parent: ${text}`);
      parent.push(text.slice(2));
      continue;
    }
    const separator = text.indexOf(':');
    assert.notEqual(separator, -1, `unsupported YAML line: ${text}`);
    const key = text.slice(0, separator).trim();
    const scalar = text.slice(separator + 1).trim();
    const value = scalar ? scalar.replace(/^['"]|['"]$/g, '') : (key === 'exclude' ? [] : {});
    parent[key] = value;
    stack.push({ indent, value });
  }
  return root;
}

function yamlPath(value, pathParts) {
  return pathParts.reduce((current, key) => current?.[key], value);
}

function assertAnalyzerShape(source) {
  const parsed = parseYamlSubset(source);
  assert.equal(yamlPath(parsed, ['include']), 'package:flutter_lints/flutter.yaml');
  assert.deepEqual(yamlPath(parsed, ['analyzer', 'exclude']), ['build/**', 'android/**', 'ios/**', 'web/**', 'windows/**', 'macos/**', 'linux/**']);
  const rules = yamlPath(parsed, ['linter', 'rules']);
  assert.equal(typeof rules, 'object');
  for (const rule of ['avoid_print', 'cancel_subscriptions', 'close_sinks', 'discarded_futures', 'unawaited_futures', 'use_build_context_synchronously', 'always_use_package_imports']) assert.equal(rules[rule], 'true');
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
  assertAnalyzerShape(options);
  assert.throws(() => assertAnalyzerShape('analyzer:\n  errors:\n    - build/**\ninclude: package:flutter_lints/flutter.yaml\nlinter:\n  diagnostics:\n    avoid_print: true\n'), /AssertionError|list item/);
  assert.throws(() => assertAnalyzerShape('analyzer:\n  exclude:\n    - build/**\ninclude: package:flutter_lints/flutter.yaml\nlinter:\n  rules:\n    avoid_print: true\n'), /AssertionError|strictEqual/);
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

    assert.equal(meaningfulLines[meaningfulLines.length - 1], 'include: ../../analysis_options.yaml', `${relativePath} must include shared analyzer configuration`);
    const local = parseYamlSubset(readWorkspaceFile(relativePath));
    const analyzer = local.analyzer;
    if (analyzer) assert.deepEqual(analyzer, { exclude: ['build/**', 'android/**', 'ios/**', 'web/**', 'windows/**', 'macos/**', 'linux/**'] }, `${relativePath} local analyzer must only contain canonical excludes`);
    assert.equal(local.linter, undefined, `${relativePath} must not override linter rules`);
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
    const license = path.join(packageRoot, 'LICENSE');
    const relativeFiles = [
      `packages/${packageName}/lib/${packageName}.dart`,
      `packages/${packageName}/README.md`,
      `packages/${packageName}/CHANGELOG.md`,
      `packages/${packageName}/pubspec.yaml`,
    ];

    const packageSources = findMemberArtifacts(packageRoot, (filePath) => /\.(dart|md|yaml)$/.test(filePath));
    const contents = [...relativeFiles.map((relativePath) => readWorkspaceFile(relativePath)), ...packageSources.map((relativePath) => fs.readFileSync(path.join(workspaceRoot, relativePath), 'utf8'))];
    assert.doesNotMatch(
      contents.join('\n'),
      generatedPlaceholders,
      `${packageName} must not retain generated package placeholders`,
    );
    if (fs.existsSync(license)) assert.doesNotMatch(fs.readFileSync(license, 'utf8'), /TODO:/, `${packageName} license must not be a placeholder`);

    const librarySource = contents[0];
    const nonCommentLibraryLines = librarySource
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith('///'));
    assert.equal(librarySource.includes(`/// ${description}`), true, `${packageName} must document its responsibility`);

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
