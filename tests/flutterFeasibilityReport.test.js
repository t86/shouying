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
const evidenceSchemas = new Map([
  ['WEB-RELEASE-BUILD-001', {
    command: 'cd flutter_workspace/apps/web_app && fvm flutter build web --release',
    resultKind: 'prose',
  }],
  ['WEB-RUNTIME-001', {
    command: 'serve the Web release bundle on a fresh localhost origin and inspect it with Chrome',
    resultKind: 'web-runtime',
  }],
  ['ANDROID-DEBUG-BUILD-001', {
    command: 'cd flutter_workspace/apps/android_app && fvm flutter build apk --debug',
    resultKind: 'prose',
  }],
  ['ANDROID-RELEASE-BUILD-001', {
    command: 'cd flutter_workspace/apps/android_app && fvm flutter build apk --release',
    resultKind: 'prose',
  }],
  ['ANDROID-RUNTIME-001', {
    command: 'adb install -r <debug-apk>; adb shell am start <package/.MainActivity>; inspect resumed and focused activities',
    resultKind: 'android-runtime',
  }],
  ['WINDOWS-ENV-001', { command: 'fvm flutter devices', resultKind: 'prose' }],
  ['AUTH-ENV-001', { command: 'controlled prerequisite review for Gate A', resultKind: 'prose' }],
  ['DEVICE-ENV-001', { command: 'controlled prerequisite review for Gate B', resultKind: 'prose' }],
  ['WEB-DEPLOY-ENV-001', { command: 'controlled prerequisite review for Gate C', resultKind: 'prose' }],
]);

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

function assertSanitizedString(text, label) {
  assert.equal(typeof text, 'string', `${label} must be a string`);
  assert.doesNotMatch(text, /\b(?:https?|wss?):\/\/[^\s)'"`]+/i, `${label} must not contain a URL or full endpoint`);
  assert.doesNotMatch(
    text,
    /(?:\/Users\/|\/Volumes\/|\/tmp\/|\/home\/|\/root\/|\/opt\/|\/etc\/|\/mnt\/|\/srv\/|\/private\/|\/var\/|\b[A-Za-z]:[\\/]|\\\\[^\\\s]+\\[^\\\s]+)/,
    `${label} must not contain a machine path`,
  );
  assert.doesNotMatch(
    text,
    /\b(?:Proxy-Authorization|Authorization|Cookie|Set-Cookie)\s*:/i,
    `${label} must not contain an authentication or cookie header`,
  );
  assert.doesNotMatch(
    text,
    /(?:^|[\s{[,;])["']?(?:(?:session[\s_-]?)?secret|access[\s_-]?token|refresh[\s_-]?token|session[\s_-]?token|token|api[\s_-]?key|password|credentials?|machine[\s_-]?code|tk|stk|tt|https?[\s_-]?proxy|all[\s_-]?proxy|proxy[\s_-]?(?:host|port))["']?\s*[:=]/i,
    `${label} must not contain a sensitive assignment`,
  );
  assert.doesNotMatch(
    text,
    /\b(?:raw[\s_-]*(?:request|response|body|payload)|(?:request|response)[\s_-]?body)\s*[:=]/i,
    `${label} must not contain a raw transport assignment`,
  );
  assert.doesNotMatch(
    text,
    /\b[A-Za-z_][A-Za-z0-9_.-]*\s*[:=]\s*[\[{]/,
    `${label} must not contain an object or array assignment`,
  );
  assert.doesNotMatch(text, /\{[^{}\r\n]*:[^{}\r\n]*\}|\[[^\[\]\r\n]*\]/, `${label} must not contain a JSON fragment`);
  assert.doesNotMatch(text, /"(?:payload|rawPayload|endpoint|url)"\s*:/i, `${label} must not contain a sensitive JSON key`);
  assert.doesNotMatch(text, /^\|\s*(?:payload|rawPayload|endpoint|url)\s*\|/im, `${label} must not contain a sensitive table key`);
  assert.doesNotMatch(text, /\b1[3-9]\d{9}\b/, `${label} must not contain a mainland China mobile number`);
  assert.doesNotMatch(text, /\b\d{18,24}\b/, `${label} must not contain a payment-code-shaped number`);
}

function assertSanitizedStrings(value, label) {
  if (typeof value === 'string') {
    assertSanitizedString(value, label);
    return;
  }
  if (Array.isArray(value)) {
    value.forEach((item, index) => assertSanitizedStrings(item, `${label}[${index}]`));
    return;
  }
  if (value && typeof value === 'object') {
    Object.entries(value).forEach(([key, item]) => assertSanitizedStrings(item, `${label}.${key}`));
  }
}

function assertSafeProse(value, label) {
  assertSanitizedString(value, label);
  assert.ok(value.length > 0, `${label} must not be empty`);
  assert.doesNotMatch(value, /[\r\n]/, `${label} must be one line`);
  assert.doesNotMatch(
    value,
    /\b[A-Za-z_][A-Za-z0-9_.-]*\s*[:=]/,
    `${label} must be prose without assignments`,
  );
  assert.doesNotMatch(value, /[\[\]{}]/, `${label} must be prose without object or array syntax`);
}

function parseRuntimeSummary(value, expectedKeys, label) {
  assert.doesNotMatch(value, /[\r\n]/, `${label} must be one line`);
  const values = new Map();
  value.split('; ').forEach((part) => {
    const match = part.match(/^([A-Za-z][A-Za-z0-9]*)=([^;]+)$/);
    assert.notEqual(match, null, `${label} must contain only scalar key=value pairs`);
    assert.equal(values.has(match[1]), false, `${label} must not repeat ${match[1]}`);
    assertSanitizedString(match[2], `${label}.${match[1]}`);
    values.set(match[1], match[2]);
  });
  assert.deepEqual([...values.keys()].sort(), [...expectedKeys].sort(), `${label} keys must match the allowlist`);
  return values;
}

function assertEvidencePositiveFormat(record) {
  const label = `evidence ${record.id}`;
  assertSanitizedStrings(record, label);
  const schema = evidenceSchemas.get(record.id);
  assert.notEqual(schema, undefined, `${record.id} needs an explicit evidence schema`);
  assert.equal(record.sanitizedCommand, schema.command, `${record.id} command is not allowlisted`);
  assertSafeProse(record.platformSummary, `${label}.platformSummary`);

  if (schema.resultKind === 'web-runtime') {
    const values = parseRuntimeSummary(
      record.resultSummary,
      ['title', 'blocker', 'consoleErrorCount'],
      `${label}.resultSummary`,
    );
    assert.match(values.get('title'), /^[\p{L}\p{N} ._-]{1,80}$/u);
    assert.match(values.get('blocker'), /^[\p{L}\p{N} ._-]{1,80}$/u);
    assert.match(values.get('consoleErrorCount'), /^\d{1,4}$/);
  } else if (schema.resultKind === 'android-runtime') {
    const values = parseRuntimeSummary(
      record.resultSummary,
      ['package', 'activity', 'resumed', 'focused'],
      `${label}.resultSummary`,
    );
    assert.match(values.get('package'), /^[a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*)+$/);
    assert.match(values.get('activity'), /^\.[A-Za-z][A-Za-z0-9_]*$/);
    assert.match(values.get('resumed'), /^(?:true|false)$/);
    assert.match(values.get('focused'), /^(?:true|false)$/);
  } else {
    assert.equal(schema.resultKind, 'prose');
    assertSafeProse(record.resultSummary, `${label}.resultSummary`);
  }
}

function parseCoverageStatuses(source) {
  const statuses = new Map();
  source.split('\n').filter((line) => /^\| [A-Z]/.test(line)).forEach((line) => {
    const cells = line.split('|').slice(1, -1).map((cell) => cell.trim());
    if (cells.length >= 6) statuses.set(cells[0], cells[5]);
  });
  return statuses;
}

function parseCapabilityDecision(report) {
  const start = report.indexOf('## Capability decision');
  const end = report.indexOf('## Residual non-blocking build warnings', start);
  assert.notEqual(start, -1, 'Capability decision section must exist');
  assert.notEqual(end, -1, 'Residual warning section must follow Capability decision');
  const rows = report.slice(start, end).split('\n')
    .filter((line) => line.startsWith('|'))
    .map((line) => line.split('|').slice(1, -1).map((cell) => cell.trim()))
    .filter(([field]) => field !== 'Capability' && !/^-+$/.test(field));
  const decisions = new Map();
  rows.forEach((cells) => {
    assert.equal(cells.length, 3, 'Capability decision rows must have three cells');
    const id = inlineValue(cells[0]);
    assert.equal(decisions.has(id), false, `duplicate Capability decision ${id}`);
    decisions.set(id, { status: inlineValue(cells[1]), reason: cells[2] });
  });
  return decisions;
}

function parseGateDecision(value, gate) {
  const match = value.match(
    /^status=([a-z-]+); capabilities=([A-Z][A-Z0-9-]*(?:,[A-Z][A-Z0-9-]*)*); action=(.+)$/,
  );
  assert.notEqual(match, null, `Gate ${gate} Decision must use the stable status/capabilities/action format`);
  return {
    status: match[1],
    capabilities: match[2].split(','),
    action: match[3],
  };
}

test('rejects sensitive mutation corpus without rejecting safe migration prose', () => {
  const attacks = [
    'Authorization: Bearer abc.def',
    'Cookie: sid=x',
    'sessionSecret=x',
    'apiKey=x',
    'proxyHost=127.0.0.1',
    '/home/user/file',
    'C:\\Users\\name\\file',
    '\\\\server\\share\\file',
    'raw response={...}',
    'requestBody=[...]',
    'secret=x',
    'Authorization: Basic YWJj',
    'Proxy-Authorization: Basic YWJj',
    'HTTP_PROXY=corp-proxy.internal:8080',
    'raw response: {"employee":"alice"}',
    'result={"employee":"alice"}',
    'access_token=x',
    'refreshToken=x',
    'session_token=x',
    'HTTPS_PROXY=corp-proxy.internal:8443',
    'ALL_PROXY=corp-proxy.internal:1080',
    'Set-Cookie: sid=x',
  ];

  attacks.forEach((value) => {
    assert.throws(
      () => assertSanitizedString(value, 'mutation corpus'),
      assert.AssertionError,
      `sanitizer must reject ${value}`,
    );
  });
  assert.doesNotThrow(() => assertSanitizedString('no raw backend payload', 'safe prose'));
  assert.doesNotThrow(() => assertSanitizedString('/shouyin-v2/', 'safe application path'));
});

test('fails closed for uncontrolled evidence commands and summary shapes', () => {
  const records = JSON.parse(readRequired(evidenceRelativePath)).evidence;
  const byId = new Map(records.map((record) => [record.id, record]));
  records.forEach((record) => assert.doesNotThrow(() => assertEvidencePositiveFormat(record)));

  const mutations = [
    { ...byId.get('WEB-RELEASE-BUILD-001'), sanitizedCommand: 'curl target' },
    {
      ...byId.get('WEB-RUNTIME-001'),
      resultSummary: 'title=收银 Web 客户端; blocker=应用配置不可用; consoleErrorCount=0; unexpected=x',
    },
    {
      ...byId.get('WEB-RUNTIME-001'),
      resultSummary: 'title=收银 Web 客户端; blocker=应用配置不可用; consoleErrorCount=zero',
    },
    {
      ...byId.get('ANDROID-RUNTIME-001'),
      resultSummary: 'package=invalid; activity=.MainActivity; resumed=true; focused=true',
    },
    { ...byId.get('ANDROID-DEBUG-BUILD-001'), resultSummary: 'status=ok' },
    { ...byId.get('WINDOWS-ENV-001'), resultSummary: '{"employee":"alice"}' },
  ];
  mutations.forEach((record) => {
    assert.throws(
      () => assertEvidencePositiveFormat(record),
      assert.AssertionError,
      `${record.id} mutation must be rejected`,
    );
  });
});

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
    assertEvidencePositiveFormat(record);
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
  assert.deepEqual(
    [...evidenceById.keys()].sort(),
    [...evidenceSchemas.keys()].sort(),
    'evidence additions require an explicit positive schema',
  );

  const gates = {
    A: parseGate(report, 'A', '## Gate B'),
    B: parseGate(report, 'B', '## Gate C'),
    C: parseGate(report, 'C', '## Capability decision'),
  };
  const referencedIds = new Set();
  for (const [gate, fields] of Object.entries(gates)) {
    assertSanitizedStrings(fields, `Gate ${gate}`);
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

  assertSanitizedString(report, 'feasibility report');
  assertSanitizedStrings(evidenceDocument, 'feasibility evidence');
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
  const reportStatuses = parseCapabilityDecision(report);
  const authIds = new Set(['AUTH-TERM-001', 'AUTH-LOGIN-001', 'SYNC-CONNECT-001']);
  const deviceIds = new Set(['DEVICE-SCAN-001', 'DEVICE-PRINT-001']);
  const gateCapabilityIds = {
    A: [...authIds],
    B: [...deviceIds],
    C: [...authIds],
  };
  const statusById = new Map(capabilities.map((capability) => [capability.id, capability.status]));

  assert.deepEqual([...reportStatuses.keys()].sort(), [...statusById.keys()].sort());

  for (const capability of capabilities) {
    const mayBePlatformVerified = authIds.has(capability.id)
      ? gatePassed.A && gatePassed.C
      : deviceIds.has(capability.id) && gatePassed.B;
    const expectedStatus = mayBePlatformVerified ? 'platform-verified' : 'defined';
    assert.equal(capability.status, expectedStatus, `${capability.id} status must follow its live gate evidence`);
    assert.equal(reportStatuses.get(capability.id).status, capability.status, `${capability.id} report status must match its ledger`);
    assert.equal(coverageStatuses.get(capability.id), capability.status, `${capability.id} coverage status must match its ledger`);
  }

  for (const [gate, fields] of Object.entries(gates)) {
    const decision = parseGateDecision(fields.Decision, gate);
    assert.deepEqual([...new Set(decision.capabilities)].sort(), [...gateCapabilityIds[gate]].sort());
    assert.equal(decision.capabilities.length, gateCapabilityIds[gate].length, `Gate ${gate} Decision must not duplicate capabilities`);
    const currentStatuses = new Set(decision.capabilities.map((id) => statusById.get(id)));
    assert.equal(currentStatuses.size, 1, `Gate ${gate} capabilities must share one current status`);
    assert.equal(decision.status, [...currentStatuses][0], `Gate ${gate} Decision must state the current capability status`);
    if (!gatePassed[gate]) {
      assert.doesNotMatch(fields.Decision, /(?:advance|推进|platform-verified)/i, `Gate ${gate} cannot promise advancement when it did not pass`);
    }
    if (decision.status === 'platform-verified') {
      decision.capabilities.forEach((id) => {
        const allRequiredGatesPassed = authIds.has(id)
          ? gatePassed.A && gatePassed.C
          : gatePassed.B;
        assert.equal(allRequiredGatesPassed, true, `${id} cannot be platform-verified before all required gates pass`);
      });
    }
  }
});
