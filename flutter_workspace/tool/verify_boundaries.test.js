const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const childProcess = require('node:child_process');

const { findBoundaryViolations } = require('./verify_boundaries');

function workspace(files) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'flutter-boundaries-'));
  for (const [name, source] of Object.entries(files)) {
    const file = path.join(root, name);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, source);
  }
  return root;
}

function violations(files) { return findBoundaryViolations(workspace(files)); }

test('rejects forbidden domain dependencies and relative layers', () => {
  const found = violations({
    'packages/other/pubspec.yaml': 'name: other\n',
    'packages/foundation/lib/domain/model.dart': [
      "import 'package:flutter/material.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';",
      "import 'package:dio/dio.dart';", "import '../data/repository.dart';", "import '../presentation/view.dart';",
    ].join('\n'),
  });
  assert.equal(found.length, 5);
  assert.ok(found.every((item) => item.rule === 'domain-forbidden-import'));
});

test('rejects package app imports and cross-package internals', () => {
  const found = violations({
    'apps/web_app/pubspec.yaml': 'name: web_app\n',
    'packages/foundation/lib/src/a.dart': ["import '../../../other/lib/src/internal.dart';", "import 'package:web_app/main.dart';", "import 'package:other/src/internal.dart';"].join('\n'),
    'packages/other/lib/src/internal.dart': 'library;\n',
  });
  assert.equal(found.length, 3);
  assert.ok(found.every((item) => item.rule === 'package-boundary'));
});

test('allows public cross-package and same-package application imports', () => {
  const found = violations({
    'packages/foundation/lib/foundation.dart': "export 'src/internal.dart';\n",
    'packages/other/lib/other.dart': 'library;\n',
    'packages/foundation/lib/application/service.dart': ["import '../domain/model.dart';", "import '../domain/src/secret.dart';", "import 'package:foundation/foundation.dart';"].join('\n'),
    'packages/foundation/lib/domain/model.dart': 'library;\n',
  });
  assert.deepEqual(found, []);
});

test('rejects presentation cross-feature internal relative imports', () => {
  const found = violations({
    'packages/foundation/lib/presentation/a/view.dart': "import '../b/src/private.dart';\n",
    'packages/foundation/lib/presentation/b/src/private.dart': 'library;\n',
  });
  assert.equal(found.length, 1);
  assert.equal(found[0].rule, 'package-boundary');
});

test('ignores comments and strings, and parses multiline single/double directives', () => {
  const found = violations({
    'packages/foundation/lib/a.dart': ["// import 'package:flutter/material.dart';", 'const text = "export \'package:dio/dio.dart\';";', "/* import 'package:flutter/material.dart'; */", 'import\n  "package:foundation/foundation.dart"\n  show Foo;', "export 'package:other/src/internal.dart';"].join('\n'),
  });
  assert.equal(found.length, 1);
  assert.equal(found[0].line, 7);
});

test('ignores raw and triple strings, nested comments, and checks conditional URIs', () => {
  const found = violations({
    'packages/foundation/pubspec.yaml': 'name: foundation\n',
    'packages/foundation/lib/domain/a.dart': [
      "final a = r'import \'package:dio/dio.dart\';';",
      "final b = ''' export 'package:flutter/material.dart'; ''';",
      '/* outer /* nested import \'package:dio/dio.dart\'; */ still comment */',
      "import 'stub.dart' if (dart.library.io) 'package:dio/dio.dart' if (dart.library.html) 'package:foundation/foundation.dart';",
    ].join('\n'),
  });
  assert.deepEqual(found.map((item) => item.import), ['package:dio/dio.dart']);
});

test('rejects package data paths and cross-package internals while allowing same-feature src', () => {
  const found = violations({
    'packages/other/pubspec.yaml': 'name: other\n',
    'packages/foundation/lib/presentation/feature/src/view.dart': [
      "import './private.dart';",
      "import 'package:other/data/value.dart';",
      "import 'package:other/src/private.dart';",
    ].join('\n'),
    'packages/other/lib/other.dart': 'library;\n',
  });
  assert.deepEqual(found.map((item) => item.import), ['package:other/data/value.dart', 'package:other/src/private.dart']);
});

test('rejects public package data and presentation layers from a domain file', () => {
  const found = violations({
    'packages/other/pubspec.yaml': 'name: other\n',
    'packages/foundation/lib/domain/model.dart': [
      "import 'package:other/data/value.dart';",
      "import 'package:other/presentation/value.dart';",
    ].join('\n'),
  });
  assert.deepEqual(found.map((item) => item.import), ['package:other/data/value.dart', 'package:other/presentation/value.dart']);
});

test('rejects normalized package data and presentation layers but allows public external imports', () => {
  const found = violations({
    'packages/foundation/pubspec.yaml': 'name: foundation\n',
    'packages/foundation/lib/domain/model.dart': [
      "import 'package:foundation/data/value.dart';",
      "import 'package:external/presentation/value.dart';",
      "import 'package:external/public.dart';",
    ].join('\n'),
  });
  assert.deepEqual(found.map((item) => item.import), [
    'package:foundation/data/value.dart', 'package:external/presentation/value.dart',
  ]);
});

test('decodes Dart URI escapes and rejects malformed import URI escapes', () => {
  const found = violations({
    'packages/other/pubspec.yaml': 'name: other\n',
    'packages/foundation/lib/domain/model.dart': [
      "import 'package:\\x6fther/extra.dart';",
      "import '\\u0070ackage:other/extra.dart';",
      "import '\\x66ile:///tmp/a.dart';",
      "import 'package:other/\\q.dart';",
      "import r'package:\\x6fther/extra.dart';",
    ].join('\n'),
  });
  assert.deepEqual(found.map((item) => item.rule), [
    'package-boundary', 'package-boundary', 'package-boundary', 'invalid-import-uri',
  ]);
  assert.equal(found.at(-1).import, 'package:other/\\q.dart');
});

test('rejects invalid braced Unicode escapes while allowing six-digit public entrypoint escapes', () => {
  const found = violations({
    'packages/other/pubspec.yaml': 'name: other\n',
    'packages/foundation/lib/model.dart': [
      "import '\\u{000070}';",
      "import 'package:\\u{00000070}ackage:external/public.dart';",
      "import 'package:\\u{0000000}other/extra.dart';",
      "import 'package:\\u{110000}/extra.dart';",
      "import 'package:\\u{d800}/extra.dart';",
    ].join('\n'),
  });
  assert.equal(found.length, 4);
  assert.ok(found.every((item) => item.rule === 'invalid-import-uri'));
});

test('handles nested comments inside interpolation and scans active code afterward', () => {
  const found = violations({
    'packages/foundation/lib/domain/model.dart': [
      'final value = "${foo(/* outer /* import \'package:dio/dio.dart\'; */ still */ 1)}";',
      "import 'package:dio/dio.dart';",
    ].join('\n'),
  });
  assert.equal(found.length, 1);
  assert.equal(found[0].line, 2);
});

test('keeps outer interpolation comments intact through nested terminators', () => {
  const found = violations({
    'packages/foundation/lib/domain/model.dart': [
      'final value = "${foo(/* outer /* import \'package:dio/dio.dart\'; */ } } \'package:dio/dio.dart\'; /* close outer */ 1)}";',
      "import 'package:dio/dio.dart';",
    ].join('\n'),
  });
  assert.equal(found.length, 1);
  assert.equal(found[0].line, 2);
});

test('enforces exact public entrypoints and rejects normalized URI bypasses', () => {
  const found = violations({
    'packages/foundation/lib/domain/model.dart': [
      "import 'package:other/other.dart';",
      "import 'package:other/extra.dart';",
      "import 'package:other/src/private.dart';",
      "import 'package:other/data/value.dart';",
      "import 'package:other/presentation/value.dart';",
      "import 'package:\\u0064io/dio.dart';",
      "import 'file:///tmp/a.dart';",
    ].join('\n'),
    'packages/other/lib/other.dart': 'library;\n',
  });
  assert.deepEqual(found.map((item) => item.import), [
    'package:other/extra.dart', 'package:other/src/private.dart',
    'package:other/data/value.dart', 'package:other/presentation/value.dart',
    'package:dio/dio.dart', 'file:///tmp/a.dart',
  ]);
});

test('rejects cross-member and outside relative paths and scans generated directories', () => {
  const found = violations({
    'packages/a/lib/domain/model.dart': "import '../../../b/lib/extra.dart';\nimport '../../../outside.dart';\n",
    'packages/b/lib/extra.dart': 'library;\n',
    'packages/a/lib/generated/domain/generated.dart': "import 'package:dio/dio.dart';\n",
  });
  assert.equal(found.length, 3);
  assert.ok(found.some((item) => item.file.includes('generated/domain')));
});

test('ignores import-looking text in interpolated Dart strings', () => {
  const found = violations({
    'packages/foundation/lib/domain/model.dart': [
      'final value = "${foo("import \'package:dio/dio.dart\';")}";',
      'final nested = "${foo("${bar(\'import \\\'package:dio/dio.dart\\\';\')}")}";',
      'final raw = r"import \'package:dio/dio.dart\';";',
      'final triple = \'\'\'import \'package:dio/dio.dart\';\'\'\';',
    ].join('\n'),
  });
  assert.deepEqual(found, []);
});

test('handles large source with linear line tracking', () => {
  const lines = Array.from({ length: 200000 }, () => 'final value = 1;').join('\n');
  const root = workspace({ 'packages/foundation/lib/domain/model.dart': `${lines}\nimport 'package:dio/dio.dart';\n` });
  const found = findBoundaryViolations(root);
  assert.equal(found.length, 1);
  assert.equal(found[0].line, 200001);
});

test('sorts violations by file, line, and rule without duplicates', () => {
  const found = violations({
    'packages/z/lib/domain/z.dart': "import 'package:dio/dio.dart';\n",
    'packages/a/lib/domain/a.dart': "import 'package:flutter/material.dart';\nimport 'package:flutter/material.dart';\n",
  });
  assert.deepEqual(found.map(({ file, line, rule }) => ({ file, line, rule })), [
    { file: 'packages/a/lib/domain/a.dart', line: 1, rule: 'domain-forbidden-import' },
    { file: 'packages/a/lib/domain/a.dart', line: 2, rule: 'domain-forbidden-import' },
    { file: 'packages/z/lib/domain/z.dart', line: 1, rule: 'domain-forbidden-import' },
  ]);
});

test('walks only regular dart files and handles symlink roots deterministically', () => {
  const root = workspace({
    'packages/foundation/lib/domain/a.dart': "import 'package:dio/dio.dart';\n",
    'packages/foundation/build/generated.dart': "import 'package:dio/dio.dart';\n",
    'packages/foundation/lib/domain/a.txt': "import 'package:dio/dio.dart';\n",
  });
  fs.symlinkSync(path.join(root, 'packages/foundation/lib/domain/a.dart'), path.join(root, 'link.dart'));
  assert.equal(findBoundaryViolations(root).length, 1);
  assert.throws(() => findBoundaryViolations(path.join(root, 'link.dart')), /real directory|symlink/i);
});

test('deduplicates identical violations on the same source line', () => {
  const root = workspace({ 'packages/foundation/lib/domain/a.dart': "import 'package:dio/dio.dart'; import 'package:dio/dio.dart';\n" });
  const found = findBoundaryViolations(root);
  assert.equal(found.length, 1);
});

test('CLI has deterministic success, violation, and invalid-root behavior', () => {
  const clean = workspace({});
  const script = path.join(__dirname, 'verify_boundaries.js');
  let result = childProcess.spawnSync(process.execPath, [script, clean], { encoding: 'utf8' });
  assert.equal(result.status, 0); assert.equal(result.stdout, '0 boundary violations\n'); assert.equal(result.stderr, '');
  const bad = workspace({ 'packages/foundation/lib/domain/a.dart': "import 'package:dio/dio.dart';\n" });
  result = childProcess.spawnSync(process.execPath, [script, bad], { encoding: 'utf8' });
  assert.equal(result.status, 1); assert.match(result.stdout, /packages\/foundation\/lib\/domain\/a\.dart:1 \[domain-forbidden-import\] package:dio\/dio\.dart\n/); assert.equal(result.stderr, '');
  for (const root of [path.join(clean, 'missing'), path.join(clean, 'file.txt')]) {
    if (root.endsWith('file.txt')) fs.writeFileSync(root, 'x');
    result = childProcess.spawnSync(process.execPath, [script, root], { encoding: 'utf8' });
    assert.equal(result.status, 1); assert.doesNotMatch(result.stderr, / at |stack|Node\.js/); assert.doesNotMatch(result.stdout, / at |stack|Node\.js/);
  }
  const symlinkRoot = path.join(clean, 'symlink-root');
  try {
    fs.symlinkSync(clean, symlinkRoot, 'dir');
  } catch (error) {
    if (['EACCES', 'EPERM', 'ENOTSUP'].includes(error.code)) return;
    throw error;
  }
  result = childProcess.spawnSync(process.execPath, [script, symlinkRoot], { encoding: 'utf8' });
  assert.equal(result.status, 1);
  assert.equal(result.stdout, '');
  assert.equal(result.stderr, 'symlink scan root is not allowed\n');
  assert.doesNotMatch(result.stderr, /\nat /);
});

test('skips member directory symlinks and broken symlinks', () => {
  const root = workspace({ 'packages/real/lib/domain/a.dart': "import 'package:dio/dio.dart';\n" });
  fs.symlinkSync(path.join(root, 'packages', 'real'), path.join(root, 'packages', 'linked'));
  fs.symlinkSync(path.join(root, 'missing'), path.join(root, 'packages', 'broken'));
  assert.equal(findBoundaryViolations(root).length, 1);
});
