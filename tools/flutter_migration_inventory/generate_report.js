'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { validateLedgers } = require('./validate_ledgers');

function readLedger(root, name) {
  return JSON.parse(fs.readFileSync(path.join(root, 'migration/flutter', name), 'utf8'));
}

function escape(value) {
  return String(value ?? '').replaceAll('\\', '\\\\').replaceAll('|', '\\|').replaceAll('\r', '\\r').replaceAll('\n', '\\n');
}

function compare(a, b) { return a < b ? -1 : a > b ? 1 : 0; }

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
    ...Object.keys(statusCounts).sort(compare).map((status) => `- ${escape(status)}: ${statusCounts[status]}`),
    '',
    '| ID | Domain | Windows | Web | Android | Status | Protocol count | Permission count | Source count |',
    '| --- | --- | --- | --- | --- | --- | ---: | ---: | ---: |',
    ...capabilities.slice().sort((a, b) => compare(a.id, b.id)).map((capability) => [
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

function atomicWrite(output, content, fsOps = fs) {
  const directory = path.dirname(output);
  if (fsOps.lstatSync(directory).isSymbolicLink()) throw new Error('generated directory must not be a symlink');
  if (fsOps.existsSync(output) && fsOps.lstatSync(output).isSymbolicLink()) throw new Error('coverage output must not be a symlink');
  const relative = path.relative(path.resolve(directory), path.resolve(output));
  if (relative.startsWith('..') || path.isAbsolute(relative)) throw new Error('coverage output escapes generated directory');
  const temp = path.join(directory, `.coverage-${process.pid}-${Date.now()}-${Math.random().toString(16).slice(2)}.tmp`);
  let fd;
  try {
    fd = fsOps.openSync(temp, 'wx', 0o600);
    fsOps.writeSync(fd, content, null, 'utf8');
    if (fsOps.fsyncSync) fsOps.fsyncSync(fd);
    fsOps.closeSync(fd); fd = undefined;
    fsOps.renameSync(temp, output);
  } catch (error) {
    if (fd !== undefined) { try { fsOps.closeSync(fd); } catch {} }
    try { fsOps.unlinkSync(temp); } catch {}
    throw error;
  }
}

function generateReport(root = process.cwd(), options = {}) {
  const result = validateLedgers(root);
  if (result.errors.length) return { ...result, report: null };
  const ledgerDir = path.join(root, 'migration/flutter');
  const report = buildReport(readLedger(root, 'capabilities.json'), readLedger(root, 'protocols.json'), readLedger(root, 'permissions.json'));
  const output = path.join(ledgerDir, 'generated/coverage.md');
  fs.mkdirSync(path.dirname(output), { recursive: true });
  try { atomicWrite(output, report, options.fs || fs); } catch (error) { return { ...result, report: null, errors: [error.message] }; }
  return { ...result, report, output };
}

if (require.main === module) {
  const result = generateReport(process.cwd());
  if (result.errors.length) { process.stderr.write(`${result.errors.join('\n')}\n`); process.exitCode = 1; }
  else process.stdout.write(`Generated ${path.relative(process.cwd(), result.output)}\n`);
}

module.exports = { buildReport, generateReport };
