#!/usr/bin/env node
const fs = require('node:fs');
const path = require('node:path');

const SKIP = new Set(['.dart_tool', 'build', 'generated', 'vendor', 'node_modules']);

function stripComments(source) {
  let out = '';
  let state = 'code';
  let quote = '';
  for (let i = 0; i < source.length; i += 1) {
    const c = source[i]; const n = source[i + 1];
    if (state === 'line') { if (c === '\n') { state = 'code'; out += c; } else out += ' '; continue; }
    if (state === 'block') { if (c === '*' && n === '/') { out += '  '; i += 1; state = 'code'; } else out += c === '\n' ? '\n' : ' '; continue; }
    if (state === 'string') { out += c; if (c === '\\') { out += n || ''; i += 1; } else if (c === quote) state = 'code'; continue; }
    if (c === '/' && n === '/') { out += '  '; i += 1; state = 'line'; continue; }
    if (c === '/' && n === '*') { out += '  '; i += 1; state = 'block'; continue; }
    if (c === "'" || c === '"') { state = 'string'; quote = c; out += c; continue; }
    out += c;
  }
  return out;
}

function lineAt(source, index) { return source.slice(0, index).split('\n').length; }

function walk(root, current = root, files = []) {
  for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
    if (SKIP.has(entry.name)) continue;
    const full = path.join(current, entry.name);
    if (entry.isSymbolicLink()) continue;
    if (entry.isDirectory()) walk(root, full, files);
    else if (entry.isFile() && entry.name.endsWith('.dart')) files.push(full);
  }
  return files;
}

function memberInfo(root) {
  const members = [];
  for (const kind of ['apps', 'packages']) {
    const dir = path.join(root, kind);
    if (!fs.existsSync(dir) || !fs.statSync(dir).isDirectory()) continue;
    for (const name of fs.readdirSync(dir)) {
      const memberRoot = path.join(dir, name);
      if (!fs.statSync(memberRoot).isDirectory()) continue;
      let packageName = name;
      try { const pub = fs.readFileSync(path.join(memberRoot, 'pubspec.yaml'), 'utf8'); packageName = /^name:\s*([\w-]+)/m.exec(pub)?.[1] || name; } catch {}
      members.push({ kind, name, packageName, root: memberRoot, lib: path.join(memberRoot, 'lib') });
    }
  }
  return members;
}

function findBoundaryViolations(root) {
  const absoluteRoot = path.resolve(root);
  let rootStat;
  try { rootStat = fs.lstatSync(absoluteRoot); } catch { throw new Error('invalid or missing scan root'); }
  if (rootStat.isSymbolicLink()) throw new Error('symlink scan root is not allowed');
  if (!rootStat.isDirectory()) throw new Error('scan root must be a real directory');
  const members = memberInfo(absoluteRoot);
  const appNames = new Set(members.filter((m) => m.kind === 'apps').map((m) => m.packageName));
  const packageByName = new Map(members.map((m) => [m.packageName, m]));
  const results = [];

  for (const file of walk(absoluteRoot).sort()) {
    const rel = path.relative(absoluteRoot, file).split(path.sep).join('/');
    const source = fs.readFileSync(file, 'utf8');
    const clean = stripComments(source);
    const member = members.find((m) => file === m.root || file.startsWith(`${m.root}${path.sep}`));
    const isDomain = rel.split('/').includes('domain');
    const isPresentation = rel.split('/').includes('presentation');
    const directive = /\b(import|export)\s*(['"])([\s\S]*?)\2/g;
    let match;
    while ((match = directive.exec(clean))) {
      const before = clean.slice(0, match.index).replace(/\s+$/, '');
      if (before && !/[;{}:]$/.test(before)) continue;
      const specifier = match[3];
      let rule = null;
      if (isDomain && (/^package:(?:flutter(?:_riverpod)?|dio)\//.test(specifier) || /(?:^|[/\\])(?:data|presentation)(?:[/\\]|$)/.test(specifier))) {
        rule = 'domain-forbidden-import';
      }
      if (/^package:/.test(specifier)) {
        const parsed = /^package:([^/]+)\/(.*)$/.exec(specifier);
        if (parsed && member?.kind === 'packages' && appNames.has(parsed[1])) rule = 'package-boundary';
        if (parsed && parsed[2].startsWith('src/') && (!member || packageByName.get(parsed[1]) !== member)) rule = 'package-boundary';
      } else if (member && (specifier.startsWith('.') || specifier.startsWith('/'))) {
        const target = path.resolve(path.dirname(file), specifier);
        const targetMember = members.find((m) => target === m.root || target.startsWith(`${m.root}${path.sep}`));
        if (targetMember?.kind === 'apps' && member.kind === 'packages') rule = 'package-boundary';
        if (targetMember && targetMember !== member && target.startsWith(`${targetMember.lib}${path.sep}src${path.sep}`)) rule = 'package-boundary';
        if (isPresentation && targetMember === member && target.includes(`${path.sep}presentation${path.sep}`) && target.includes(`${path.sep}src${path.sep}`)) rule = 'package-boundary';
      }
      if (rule) results.push({ file: rel, line: lineAt(source, match.index), rule, import: specifier });
    }
  }
  const unique = new Map(results.map((item) => [`${item.file}\0${item.line}\0${item.rule}\0${item.import}`, item]));
  return [...unique.values()].sort((a, b) => a.file.localeCompare(b.file) || a.line - b.line || a.rule.localeCompare(b.rule));
}

if (require.main === module) {
  const root = process.argv[2] || path.resolve(__dirname, '..');
  try {
    const found = findBoundaryViolations(root);
    if (!found.length) { console.log('0 boundary violations'); process.exit(0); }
    for (const item of found) console.log(`${item.file}:${item.line} [${item.rule}] ${item.import}`);
    process.exit(1);
  } catch (error) { console.error(error.message); process.exit(1); }
}

module.exports = { findBoundaryViolations };
