const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = process.cwd();
const reportRelativePath = 'docs/flutter-migration/feasibility-report.md';
const evidenceRelativePath = 'docs/flutter-migration/feasibility-evidence.json';
const gateFields = [
  'App commit',
  'Flutter version',
  'Platform version',
  'Test date',
  'Result',
  'Evidence path',
  'Sanitized error',
  'Decision',
];
const evidenceFields = [
  'id',
  'appCommit',
  'sanitizedCommand',
  'exitCode',
  'platformSummary',
  'relativeArtifact',
  'sha256',
  'resultSummary',
];
const allowedResults = new Set(['pass', 'fail', 'blocked-by-environment']);

function readRequired(relativePath) {
  const absolutePath = path.join(root, relativePath);
  assert.equal(fs.existsSync(absolutePath), true, `${relativePath} must exist`);
  return fs.readFileSync(absolutePath, 'utf8');
}

function parseGate(report, gate, nextHeading) {
  const start = report.indexOf(`## Gate ${gate}`);
  assert.notEqual(start, -1, `Gate ${gate} section must exist`);
  const end = nextHeading ? report.indexOf(nextHeading, start) : report.length;
  assert.notEqual(end, -1, `${nextHeading} must follow Gate ${gate}`);
  const section = report.slice(start, end);
  const rows = section.split('\n')
    .filter((line) => line.startsWith('|'))
    .map((line) => line.split('|').slice(1, -1).map((cell) => cell.trim()))
    .filter(([field]) => field !== 'Field' && !/^-+$/.test(field));

  rows.forEach((row) => assert.equal(row.length, 2, `Gate ${gate} rows must have two cells`));
  const fields = rows.map(([field]) => field);
  assert.deepEqual([...new Set(fields)].sort(), [...gateFields].sort(), `Gate ${gate} fields must match the allowlist`);
  assert.equal(fields.length, gateFields.length, `Gate ${gate} fields must not be duplicated`);
  return Object.fromEntries(rows);
}

function inlineValue(value) {
  const match = value.match(/^`([^`]*)`$/);
  return match ? match[1] : value;
}

function assertIsoDate(value, label) {
  assert.match(value, /^\d{4}-\d{2}-\d{2}$/, `${label} must use ISO YYYY-MM-DD`);
  const parsed = new Date(`${value}T00:00:00.000Z`);
  assert.equal(Number.isNaN(parsed.valueOf()), false, `${label} must be a real date`);
  assert.equal(parsed.toISOString().slice(0, 10), value, `${label} must be a real calendar date`);
}

function assertSanitized(text, label) {
  assert.doesNotMatch(text, /\b(?:https?|wss?):\/\/[^\s)'"`]+/i, `${label} must not contain a URL or full endpoint`);
  assert.doesNotMatch(text, /(?:\/Users\/|\/Volumes\/|\/tmp\/|\b[A-Za-z]:[\\/])/, `${label} must not contain a machine path`);
  assert.doesNotMatch(
    text,
    /(?:^|[\s{[,;])(?:tk|stk|tt|token|password|credential|machineCode)\s*(?:=|:)/i,
    `${label} must not contain a sensitive assignment`,
  );
  assert.doesNotMatch(text, /"(?:payload|rawPayload|endpoint|url)"\s*:/i, `${label} must not contain a sensitive JSON key`);
  assert.doesNotMatch(text, /^\|\s*(?:payload|rawPayload|endpoint|url)\s*\|/im, `${label} must not contain a sensitive table key`);
  assert.doesNotMatch(text, /\b1[3-9]\d{9}\b/, `${label} must not contain a mainland China mobile number`);
  assert.doesNotMatch(text, /\b\d{18,24}\b/, `${label} must not contain a payment-code-shaped number`);
}

function parseCoverageStatuses(source) {
  const statuses = new Map();
  source.split('\n').filter((line) => /^\| [A-Z]/.test(line)).forEach((line) => {
    const cells = line.split('|').slice(1, -1).map((cell) => cell.trim());
    if (cells.length >= 6) statuses.set(cells[0], cells[5]);
  });
  return statuses;
}

test('validates dynamic gate tables and resolves every evidence reference', () => {
  const report = readRequired(reportRelativePath);
  const evidenceSource = readRequired(evidenceRelativePath);
  const evidenceDocument = JSON.parse(evidenceSource);

  assert.deepEqual(Object.keys(evidenceDocument).sort(), ['evidence', 'schemaVersion']);
  assert.equal(evidenceDocument.schemaVersion, 1);
  assert.equal(Array.isArray(evidenceDocument.evidence), true);

  const evidenceById = new Map();
  for (const record of evidenceDocument.evidence) {
    assert.deepEqual(Object.keys(record).sort(), [...evidenceFields].sort(), `${record.id ?? 'unknown evidence'} fields must match the allowlist`);
    assert.match(record.id, /^[A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*-\d{3}$/);
    assert.equal(evidenceById.has(record.id), false, `duplicate evidence id ${record.id}`);
    assert.match(record.appCommit, /^[0-9a-f]{40}$/);
    assert.equal(typeof record.sanitizedCommand, 'string');
    assert.doesNotMatch(record.sanitizedCommand, /[\r\n]/);
    assert.ok(record.sanitizedCommand.length > 0);
    assert.ok(record.exitCode === null || (Number.isInteger(record.exitCode) && record.exitCode >= 0));
    assert.equal(typeof record.platformSummary, 'string');
    assert.ok(record.platformSummary.length > 0);
    assert.equal(typeof record.resultSummary, 'string');
    assert.ok(record.resultSummary.length > 0);
    if (record.relativeArtifact === null) {
      assert.equal(record.sha256, null, `${record.id} without an artifact must not invent a hash`);
    } else {
      assert.equal(typeof record.relativeArtifact, 'string');
      assert.equal(path.posix.isAbsolute(record.relativeArtifact), false);
      assert.equal(record.relativeArtifact.includes('\\'), false);
      assert.equal(record.relativeArtifact.split('/').includes('..'), false);
      assert.match(record.sha256, /^[0-9a-f]{64}$/);
    }
    evidenceById.set(record.id, record);
  }

  const gates = {
    A: parseGate(report, 'A', '## Gate B'),
    B: parseGate(report, 'B', '## Gate C'),
    C: parseGate(report, 'C', '## Capability decision'),
  };
  const referencedIds = new Set();
  for (const [gate, fields] of Object.entries(gates)) {
    assert.match(inlineValue(fields['App commit']), /^[0-9a-f]{40}$/);
    assert.match(inlineValue(fields['Flutter version']), /^\d+\.\d+\.\d+$/);
    assertIsoDate(inlineValue(fields['Test date']), `Gate ${gate} date`);
    assert.equal(allowedResults.has(inlineValue(fields.Result)), true, `Gate ${gate} result is unsupported`);
    assert.match(fields['Evidence path'], new RegExp(evidenceRelativePath.replaceAll('.', '\\.')));
    const ids = fields['Evidence path'].match(/\b[A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*-\d{3}\b/g) ?? [];
    assert.ok(ids.length > 0, `Gate ${gate} must reference persistent evidence IDs`);
    ids.forEach((id) => {
      assert.equal(evidenceById.has(id), true, `Gate ${gate} references unknown evidence ${id}`);
      assert.equal(
        evidenceById.get(id).appCommit,
        inlineValue(fields['App commit']),
        `Gate ${gate} and ${id} must reference the same application commit`,
      );
      referencedIds.add(id);
    });
  }
  assert.deepEqual([...referencedIds].sort(), [...evidenceById.keys()].sort(), 'every evidence record must support at least one gate');

  assertSanitized(report, 'feasibility report');
  assertSanitized(evidenceSource, 'feasibility evidence');
});

test('derives capability and generated coverage status from live gate results', () => {
  const report = readRequired(reportRelativePath);
  const gates = {
    A: parseGate(report, 'A', '## Gate B'),
    B: parseGate(report, 'B', '## Gate C'),
    C: parseGate(report, 'C', '## Capability decision'),
  };
  const gatePassed = Object.fromEntries(
    Object.entries(gates).map(([gate, fields]) => [gate, inlineValue(fields.Result) === 'pass']),
  );
  const capabilities = JSON.parse(readRequired('migration/flutter/capabilities.json'));
  const coverageStatuses = parseCoverageStatuses(readRequired('migration/flutter/generated/coverage.md'));
  const authIds = new Set(['AUTH-TERM-001', 'AUTH-LOGIN-001', 'SYNC-CONNECT-001']);
  const deviceIds = new Set(['DEVICE-SCAN-001', 'DEVICE-PRINT-001']);

  for (const capability of capabilities) {
    const mayBePlatformVerified = authIds.has(capability.id)
      ? gatePassed.A && gatePassed.C
      : deviceIds.has(capability.id) && gatePassed.B;
    const expectedStatus = mayBePlatformVerified ? 'platform-verified' : 'defined';
    assert.equal(capability.status, expectedStatus, `${capability.id} status must follow its live gate evidence`);
    assert.equal(coverageStatuses.get(capability.id), capability.status, `${capability.id} coverage status must match its ledger`);
  }
});
