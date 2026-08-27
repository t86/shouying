#!/usr/bin/env node
'use strict';

const childProcess = require('node:child_process');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const SCOPES = ['flutter_workspace', 'migration/flutter/generated'];

function runGit(root, args) {
  const result = childProcess.spawnSync('git', args, {
    cwd: root,
    encoding: null,
    maxBuffer: 64 * 1024 * 1024,
  });
  if (result.status !== 0) throw new Error('git snapshot command failed');
  return result.stdout;
}

function nullSeparated(buffer) {
  const values = [];
  let start = 0;
  for (let index = 0; index < buffer.length; index += 1) {
    if (buffer[index] !== 0) continue;
    if (index > start) values.push(buffer.subarray(start, index).toString('utf8'));
    start = index + 1;
  }
  if (start < buffer.length) values.push(buffer.subarray(start).toString('utf8'));
  return values;
}

function indexEntries(root) {
  const entries = new Map();
  for (const record of nullSeparated(runGit(root, [
    'ls-files',
    '-s',
    '-z',
    '--',
    ...SCOPES,
  ]))) {
    const separator = record.indexOf('\t');
    if (separator < 0) throw new Error('invalid git index record');
    const metadata = record.slice(0, separator);
    const file = record.slice(separator + 1);
    const current = entries.get(file) || [];
    current.push(metadata);
    entries.set(file, current);
  }
  for (const metadata of entries.values()) metadata.sort();
  return entries;
}

function hashFile(file) {
  const hash = crypto.createHash('sha256');
  const buffer = Buffer.allocUnsafe(64 * 1024);
  const descriptor = fs.openSync(file, 'r');
  try {
    let bytesRead;
    do {
      bytesRead = fs.readSync(descriptor, buffer, 0, buffer.length, null);
      if (bytesRead > 0) hash.update(buffer.subarray(0, bytesRead));
    } while (bytesRead > 0);
  } finally {
    fs.closeSync(descriptor);
  }
  return hash.digest('hex');
}

function worktreeEntry(root, relativePath) {
  const absolutePath = path.join(root, ...relativePath.split('/'));
  let stat;
  try {
    stat = fs.lstatSync(absolutePath);
  } catch (error) {
    if (error.code === 'ENOENT' || error.code === 'ENOTDIR') return { type: 'missing' };
    throw error;
  }
  const mode = stat.mode & 0o7777;
  if (stat.isSymbolicLink()) {
    return {
      type: 'symlink',
      mode,
      content: crypto.createHash('sha256').update(fs.readlinkSync(absolutePath)).digest('hex'),
    };
  }
  if (stat.isFile()) {
    return {
      type: 'file',
      mode,
      size: stat.size,
      content: hashFile(absolutePath),
    };
  }
  return { type: stat.isDirectory() ? 'directory' : 'other', mode };
}

function buildSnapshot(root) {
  const repositoryRoot = path.resolve(root);
  const rootStat = fs.lstatSync(repositoryRoot);
  if (!rootStat.isDirectory() || rootStat.isSymbolicLink()) {
    throw new Error('repository root must be a real directory');
  }
  const index = indexEntries(repositoryRoot);
  const files = nullSeparated(runGit(repositoryRoot, [
    'ls-files',
    '-z',
    '--cached',
    '--others',
    '--exclude-standard',
    '--',
    ...SCOPES,
  ]));
  return {
    schemaVersion: 1,
    scopes: SCOPES,
    entries: [...new Set(files)].sort().map((relativePath) => ({
      path: relativePath,
      index: index.get(relativePath) || [],
      worktree: worktreeEntry(repositoryRoot, relativePath),
    })),
  };
}

function snapshotDigest(root) {
  return crypto
    .createHash('sha256')
    .update(JSON.stringify(buildSnapshot(root)))
    .digest('hex');
}

if (require.main === module) {
  const repositoryRoot = path.resolve(__dirname, '..', '..');
  try {
    process.stdout.write(`${snapshotDigest(repositoryRoot)}\n`);
  } catch (_) {
    process.stderr.write('Unable to snapshot migration state.\n');
    process.exitCode = 1;
  }
}

module.exports = { buildSnapshot, snapshotDigest };
