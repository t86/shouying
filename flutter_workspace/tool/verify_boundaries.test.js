const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

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
