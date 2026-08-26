'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { validateLedgers } = require('./validate_ledgers');

function readLedger(root, name) {
  return JSON.parse(fs.readFileSync(path.join(root, 'migration/flutter', name), 'utf8'));
}

function escape(value) { return String(value ?? '').replaceAll('|', '\\|'); }

function buildReport(capabilities, protocols, permissions) {
  const protocolIds = new Set(protocols.map((record) => record.id));
  const permissionIds = new Set(permissions.map((record) => record.id));
  const statusCounts = {};
  capabilities.forEach((capability) => { statusCounts[capability.status] = (statusCounts[capability.status] || 0) + 1; });
  const lines = [
    '# Flutter Migration Coverage',
    '',
    `Capabilities: ${capabilities.length} | Protocols: ${protocols.length} | Permissions: ${permissions.length}`,
    '',
    '## Status counts',
    '',
    ...Object.keys(statusCounts).sort().map((status) => `- ${escape(status)}: ${statusCounts[status]}`),
    '',
    '| ID | Domain | Windows | Web | Android | Status | Protocol count | Permission count | Source count |',
    '| --- | --- | --- | --- | --- | --- | ---: | ---: | ---: |',
    ...capabilities.slice().sort((a, b) => a.id.localeCompare(b.id)).map((capability) => [
      capability.id,
      capability.domain,
      capability.platforms.windows,
      capability.platforms.web,
      capability.platforms.android,
      capability.status,
      (capability.protocols || []).filter((id) => protocolIds.has(id)).length,
      (capability.permissions || []).filter((id) => permissionIds.has(id)).length,
      (capability.sources || []).length,
    ].map(escape).join(' | ')).map((row) => `| ${row} |`),
    '',
  ];
  return lines.join('\n');
}

function generateReport(root = process.cwd()) {
  const result = validateLedgers(root);
  if (result.errors.length) return { ...result, report: null };
  const ledgerDir = path.join(root, 'migration/flutter');
  const report = buildReport(readLedger(root, 'capabilities.json'), readLedger(root, 'protocols.json'), readLedger(root, 'permissions.json'));
  const output = path.join(ledgerDir, 'generated/coverage.md');
  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, report);
  return { ...result, report, output };
}

if (require.main === module) {
  const result = generateReport(process.cwd());
  if (result.errors.length) { process.stderr.write(`${result.errors.join('\n')}\n`); process.exitCode = 1; }
  else process.stdout.write(`Generated ${path.relative(process.cwd(), result.output)}\n`);
}

module.exports = { buildReport, generateReport };
