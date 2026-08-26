'use strict';

const fs = require('node:fs');
const path = require('node:path');

const STATUSES = new Set(['discovered', 'defined', 'implemented', 'protocol-equal', 'permission-equal', 'exception-equal', 'platform-verified', 'accepted']);
const PLATFORMS = ['windows', 'web', 'android'];
const SCOPES = new Set(['required', 'degraded', 'approved', 'out-of-scope']);
const ID_RE = /^[A-Z][A-Z0-9-]*$/;
const BAD_TEXT = /[\u0000-\u001f\u007f\r\n]/;

function readJson(file, errors) {
  try { return JSON.parse(fs.readFileSync(file, 'utf8')); }
  catch (error) { errors.push(`${path.basename(file)}: invalid JSON (${error.message})`); return []; }
}

function textField(record, field, label, errors) {
  const valid = typeof record[field] === 'string' && record[field].length > 0 && !BAD_TEXT.test(record[field]);
  if (!valid) errors.push(`${label}: ${field} must be a non-empty string without control characters`);
  return valid;
}

function stringArray(record, field, label, errors) {
  if (!Array.isArray(record[field])) { errors.push(`${label}: ${field} must be an array`); return false; }
  let valid = true; const seen = new Set();
  record[field].forEach((value, index) => {
    if (typeof value !== 'string') { errors.push(`${label}: ${field} must contain only strings (index ${index})`); valid = false; return; }
    if (BAD_TEXT.test(value)) { errors.push(`${label}: ${field}[${index}] contains control characters`); valid = false; }
    if (seen.has(value)) { errors.push(`${label}: ${field} contains duplicate value ${value}`); valid = false; }
    seen.add(value);
  });
  return valid;
}

function platformsField(record, label, errors) {
  if (!record.platforms || typeof record.platforms !== 'object' || Array.isArray(record.platforms)) { errors.push(`${label}: platforms must be an object`); return false; }
  let valid = Object.keys(record.platforms).sort().join(',') === PLATFORMS.slice().sort().join(',');
  if (!valid) errors.push(`${label}: ${record.id} platforms must contain exactly windows, web, android`);
  PLATFORMS.forEach((platform) => { if (!SCOPES.has(record.platforms[platform])) { errors.push(`${label}: ${record.id} platform ${platform} has invalid scope ${record.platforms[platform]}`); valid = false; } });
  return valid;
}

function protocolFields(record, label, errors) {
  let valid = textField(record, 'path', label, errors);
  if (!['http', 'websocket'].includes(record.kind)) { errors.push(`${label}: kind must be http or websocket`); valid = false; }
  if (!record.request || typeof record.request !== 'object' || Array.isArray(record.request)) { errors.push(`${label}: request must be an object`); valid = false; }
  if (!record.response || typeof record.response !== 'object' || Array.isArray(record.response)) { errors.push(`${label}: response must be an object`); valid = false; }
  if (record.kind === 'http' && !['GET', 'POST'].includes(record.method)) { errors.push(`${label}: method must be GET or POST for http`); valid = false; }
  if (record.kind === 'websocket' && Object.hasOwn(record, 'method')) { errors.push(`${label}: websocket must not have method`); valid = false; }
  return valid;
}

function validateRecords(data, name, type, errors, declared) {
  const records = []; const required = type === 'capability' ? ['domain', 'platforms', 'permissions', 'protocols', 'sources', 'status'] : type === 'protocol' ? ['kind', 'path', 'request', 'response', 'sources', 'status'] : ['name', 'rule', 'sources', 'status'];
  if (!Array.isArray(data)) { errors.push(`${name}: top-level value must be an array`); return records; }
  const ids = new Set();
  data.forEach((record, index) => {
    const label = `${name}[${index}]`;
    if (!record || typeof record !== 'object' || Array.isArray(record)) { errors.push(`${label}: record must be an object`); return; }
    let valid = true;
    if (typeof record.id !== 'string' || !record.id) { errors.push(`${label}: id must be a non-empty string`); valid = false; }
    else if (!ID_RE.test(record.id) || BAD_TEXT.test(record.id)) { errors.push(`${label}: id must match ${ID_RE} and be single-line ASCII`); valid = false; }
    else { declared.add(record.id); if (ids.has(record.id)) { errors.push(`${label}: duplicate id ${record.id}`); valid = false; } ids.add(record.id); }
    required.forEach((field) => { if (!Object.hasOwn(record, field)) { errors.push(`${label}: missing required field ${field}`); valid = false; } });
    if (typeof record.status !== 'string' || !STATUSES.has(record.status)) { errors.push(`${label}: invalid status ${record.status}`); valid = false; }
    if (type === 'capability') {
      valid = textField(record, 'name', label, errors) && valid;
      valid = textField(record, 'domain', label, errors) && valid;
      valid = stringArray(record, 'sources', label, errors) && valid;
      valid = stringArray(record, 'protocols', label, errors) && valid;
      valid = stringArray(record, 'permissions', label, errors) && valid;
      valid = platformsField(record, label, errors) && valid;
    } else if (type === 'protocol') {
      valid = protocolFields(record, label, errors) && valid;
      valid = stringArray(record, 'sources', label, errors) && valid;
    } else {
      valid = textField(record, 'name', label, errors) && valid;
      valid = textField(record, 'rule', label, errors) && valid;
      valid = stringArray(record, 'sources', label, errors) && valid;
    }
    if (valid) { Object.defineProperty(record, '_ledgerIndex', { value: index, enumerable: false }); records.push(record); }
  });
  return records;
}

function sourceError(root, source) {
  if (typeof source !== 'string') return 'source must be a string';
  if (/^\\\\/.test(source)) return 'UNC source path';
  if (/^[A-Za-z]:/.test(source)) return 'drive-letter source path';
  if (path.posix.isAbsolute(source)) return 'absolute source path';
  const normalized = path.posix.normalize(source.replaceAll('\\', '/'));
  if (normalized === '..' || normalized.startsWith('../')) return 'traversal source path';
  const absolute = path.resolve(root, normalized); const relative = path.relative(path.resolve(root), absolute);
  if (relative.startsWith('..') || path.isAbsolute(relative)) return 'escape source path';
  let cursor = path.resolve(root);
  for (const part of relative.split(path.sep).filter(Boolean)) { cursor = path.join(cursor, part); try { if (fs.lstatSync(cursor).isSymbolicLink()) return 'symlink source path'; } catch { return 'source does not exist'; } }
  try { if (!fs.statSync(absolute).isFile()) return 'source is not a regular file'; } catch { return 'source does not exist'; }
  return null;
}

function validateSources(records, name, root, errors) { records.forEach((record) => record.sources.forEach((source) => { const reason = sourceError(root, source); if (reason) errors.push(`${name}[${record._ledgerIndex}]: ${record.id} ${reason}: ${source}`); })); }

function trustPath(root, target) {
  const base = path.resolve(root); const absolute = path.resolve(target); const relative = path.relative(base, absolute);
  if (relative.startsWith('..') || path.isAbsolute(relative)) return 'path escapes repository root';
  let cursor = base;
  try { if (fs.lstatSync(cursor).isSymbolicLink()) return 'repository root must not be a symlink'; } catch (error) { return `repository root unavailable: ${error.message}`; }
  for (const part of relative.split(path.sep).filter(Boolean)) { cursor = path.join(cursor, part); try { if (fs.lstatSync(cursor).isSymbolicLink()) return `symlink path component: ${path.relative(base, cursor)}`; } catch { break; } }
  return null;
}

function validateLedgers(root, options = {}) {
  const ledgerDir = path.resolve(options.ledgerDir || path.join(root, 'migration/flutter')); const sourceRoot = path.resolve(options.sourceRoot || root); const errors = []; const declared = { protocol: new Set(), permission: new Set() };
  const trustError = trustPath(root, ledgerDir); if (trustError) return { errors: [trustError], capabilityCount: 0, protocolCount: 0, permissionCount: 0 };
  const capabilities = validateRecords(readJson(path.join(ledgerDir, 'capabilities.json'), errors), 'capabilities.json', 'capability', errors, new Set());
  const protocols = validateRecords(readJson(path.join(ledgerDir, 'protocols.json'), errors), 'protocols.json', 'protocol', errors, declared.protocol);
  const permissions = validateRecords(readJson(path.join(ledgerDir, 'permissions.json'), errors), 'permissions.json', 'permission', errors, declared.permission);
  validateSources(capabilities, 'capabilities.json', sourceRoot, errors); validateSources(protocols, 'protocols.json', sourceRoot, errors); validateSources(permissions, 'permissions.json', sourceRoot, errors);
  const validProtocols = new Set(protocols.map((record) => record.id)); const validPermissions = new Set(permissions.map((record) => record.id));
  capabilities.forEach((record) => { const label = `capabilities.json[${record._ledgerIndex}]`; record.protocols.forEach((id) => { if (!validProtocols.has(id)) errors.push(`${label}: ${record.id} references ${declared.protocol.has(id) ? 'invalid' : 'unknown'} protocol ${id}`); }); record.permissions.forEach((id) => { if (!validPermissions.has(id)) errors.push(`${label}: ${record.id} references ${declared.permission.has(id) ? 'invalid' : 'unknown'} permission ${id}`); }); });
  return { errors: [...new Set(errors)].sort(), capabilityCount: capabilities.length, protocolCount: protocols.length, permissionCount: permissions.length };
}

if (require.main === module) { const result = validateLedgers(process.cwd()); if (result.errors.length) { process.stderr.write(`${result.errors.join('\n')}\n`); process.exitCode = 1; } else process.stdout.write(`Validated ledgers: capabilities=${result.capabilityCount} protocols=${result.protocolCount} permissions=${result.permissionCount}\n`); }
module.exports = { validateLedgers };
