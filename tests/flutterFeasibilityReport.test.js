const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = process.cwd();
const reportPath = path.join(root, 'docs/flutter-migration/feasibility-report.md');

function gateSection(report, gate, nextGate) {
  const start = report.indexOf(`## Gate ${gate}`);
  assert.notEqual(start, -1, `Gate ${gate} section must exist`);
  const end = nextGate ? report.indexOf(`## Gate ${nextGate}`, start) : report.length;
  assert.notEqual(end, -1, `Gate ${nextGate} section must follow Gate ${gate}`);
  return report.slice(start, end);
}

test('records every live feasibility gate as blocked by missing environment evidence', () => {
  assert.equal(fs.existsSync(reportPath), true, 'the sanitized feasibility report must exist');
  const report = fs.readFileSync(reportPath, 'utf8');

  assert.doesNotMatch(report, /not-run/i);
  assert.doesNotMatch(
    report,
    /^\|\s*(?:credential|password|token|machine code|raw payload)\b/im,
    'the report must not define fields that invite sensitive values',
  );

  for (const [gate, nextGate] of [['A', 'B'], ['B', 'C'], ['C', null]]) {
    const section = gateSection(report, gate, nextGate);
    assert.match(section, /\| App commit \| `[0-9a-f]{40}` \|/);
    assert.match(section, /\| Flutter version \| `3\.47\.0` \|/);
    assert.match(section, /\| Platform version \| [^\n|]+ \|/);
    assert.match(section, /\| Test date \| `2026-08-27` \|/);
    assert.match(section, /\| Result \| `blocked-by-environment` \|/);
    assert.match(section, /\| Evidence path \| [^\n|]+ \|/);
    assert.match(section, /\| Sanitized error \| [^\n|]+ \|/);
    assert.match(section, /\| Decision \| [^\n|]+ \|/);
  }
});

test('does not advance capability status without all required live platform evidence', () => {
  const capabilities = JSON.parse(fs.readFileSync(
    path.join(root, 'migration/flutter/capabilities.json'),
    'utf8',
  ));

  assert.deepEqual(
    capabilities.map(({ id, status }) => [id, status]),
    [
      ['AUTH-TERM-001', 'defined'],
      ['AUTH-LOGIN-001', 'defined'],
      ['SYNC-CONNECT-001', 'defined'],
      ['DEVICE-SCAN-001', 'defined'],
      ['DEVICE-PRINT-001', 'defined'],
    ],
  );
});
