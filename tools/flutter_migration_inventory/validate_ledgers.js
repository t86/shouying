'use strict';

const fs = require('node:fs');
const path = require('node:path');

const STATUSES = new Set([
  'discovered', 'defined', 'implemented', 'protocol-equal', 'permission-equal',
  'exception-equal', 'platform-verified', 'accepted',
]);
const PLATFORM_KEYS = ['windows', 'web', 'android'];
const PLATFORM_SCOPES = new Set(['required', 'degraded', 'approved', 'out-of-scope']);

function readJson(file, errors) {
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch (error) {
    errors.push(`${path.basename(file)}: invalid JSON (${error.message})`);
    return [];
  }
}

function validateRecords(data, name, errors) {
  if (!Array.isArray(data)) {
    errors.push(`${name}: top-level value must be an array`);
    return [];
  }
  const ids = new Set();
  data.forEach((record, index) => {
    if (!record || typeof record !== 'object' || Array.isArray(record)) {
      errors.push(`${name}[${index}]: record must be an object`);
      return;
    }
    if (typeof record.id !== 'string' || !record.id) {
      errors.push(`${name}[${index}]: id must be a non-empty string`);
    } else if (ids.has(record.id)) {
      errors.push(`${name}: duplicate id ${record.id}`);
    } else {
      ids.add(record.id);
    }
    if (typeof record.status !== 'string' || !STATUSES.has(record.status)) {
      errors.push(`${name}: ${record.id || `[${index}]`} has invalid status ${record.status}`);
    }
  });
  return data;
}

function sourceIsSafe(sourceRoot, source) {
  if (typeof source !== 'string' || !source || path.isAbsolute(source)) return false;
  const normalized = path.posix.normalize(source.replaceAll('\\', '/'));
  if (normalized === '..' || normalized.startsWith('../')) return false;
  const absolute = path.resolve(sourceRoot, normalized);
  const relative = path.relative(path.resolve(sourceRoot), absolute);
  if (relative.startsWith('..') || path.isAbsolute(relative)) return false;
  let cursor = path.resolve(sourceRoot);
  for (const segment of relative.split(path.sep).filter(Boolean)) {
    cursor = path.join(cursor, segment);
    try {
      if (fs.lstatSync(cursor).isSymbolicLink()) return false;
    } catch { return false; }
  }
  try { return fs.statSync(absolute).isFile(); } catch { return false; }
}

function validateSources(records, name, sourceRoot, errors) {
  records.forEach((record) => {
    if (!Array.isArray(record.sources)) {
      errors.push(`${name}: ${record.id} sources must be an array`);
      return;
    }
    record.sources.forEach((source) => {
      if (!sourceIsSafe(sourceRoot, source)) {
        const reason = typeof source === 'string' && !path.isAbsolute(source) && !source.includes('..')
          ? 'does not exist' : 'is not a safe repository-relative path';
        errors.push(`${name}: ${record.id} source ${reason}: ${source}`);
      }
    });
  });
}

function validateLedgers(root, options = {}) {
  const ledgerDir = options.ledgerDir ? path.resolve(options.ledgerDir) : path.resolve(root, 'migration/flutter');
  const sourceRoot = options.sourceRoot ? path.resolve(options.sourceRoot) : path.resolve(root);
  const errors = [];
  const capabilities = validateRecords(readJson(path.join(ledgerDir, 'capabilities.json'), errors), 'capabilities.json', errors);
  const protocols = validateRecords(readJson(path.join(ledgerDir, 'protocols.json'), errors), 'protocols.json', errors);
  const permissions = validateRecords(readJson(path.join(ledgerDir, 'permissions.json'), errors), 'permissions.json', errors);
  validateSources(capabilities, 'capabilities.json', sourceRoot, errors);
  validateSources(protocols, 'protocols.json', sourceRoot, errors);
  validateSources(permissions, 'permissions.json', sourceRoot, errors);
  const protocolIds = new Set(protocols.map((record) => record.id));
  const permissionIds = new Set(permissions.map((record) => record.id));
  capabilities.forEach((record) => {
    if (!Array.isArray(record.protocols)) errors.push(`capabilities.json: ${record.id} protocols must be an array`);
    else record.protocols.forEach((id) => { if (!protocolIds.has(id)) errors.push(`capabilities.json: ${record.id} references unknown protocol ${id}`); });
    if (!Array.isArray(record.permissions)) errors.push(`capabilities.json: ${record.id} permissions must be an array`);
    else record.permissions.forEach((id) => { if (!permissionIds.has(id)) errors.push(`capabilities.json: ${record.id} references unknown permission ${id}`); });
    if (!record.platforms || typeof record.platforms !== 'object' || Array.isArray(record.platforms)) {
      errors.push(`capabilities.json: ${record.id} platforms must be an object`);
    } else {
      const keys = Object.keys(record.platforms).sort();
      if (keys.join(',') !== PLATFORM_KEYS.slice().sort().join(',')) errors.push(`capabilities.json: ${record.id} platforms must contain exactly windows, web, android`);
      PLATFORM_KEYS.forEach((platform) => {
        if (record.platforms[platform] !== undefined && !PLATFORM_SCOPES.has(record.platforms[platform])) errors.push(`capabilities.json: ${record.id} platform ${platform} has invalid scope ${record.platforms[platform]}`);
      });
    }
  });
  return {
    errors: [...new Set(errors)].sort(),
    capabilityCount: capabilities.length,
    protocolCount: protocols.length,
    permissionCount: permissions.length,
  };
}

if (require.main === module) {
  const result = validateLedgers(process.cwd());
  if (result.errors.length) { process.stderr.write(`${result.errors.join('\n')}\n`); process.exitCode = 1; }
  else process.stdout.write(`Validated ledgers: capabilities=${result.capabilityCount} protocols=${result.protocolCount} permissions=${result.permissionCount}\n`);
}

module.exports = { validateLedgers };
