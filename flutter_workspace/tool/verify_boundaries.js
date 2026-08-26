#!/usr/bin/env node
const fs = require('node:fs');
const path = require('node:path');

const SKIP = new Set(['.dart_tool', 'build', 'generated', 'vendor', 'node_modules']);

function tokenize(source) {
  const tokens = []; let i = 0; let blockDepth = 0;
  const line = (at) => lineAt(source, at);
  while (i < source.length) {
    if (source.startsWith('//', i)) { i = source.indexOf('\n', i + 2); if (i < 0) break; continue; }
    if (source.startsWith('/*', i)) { blockDepth = 1; i += 2; while (i < source.length && blockDepth) { if (source.startsWith('/*', i)) { blockDepth += 1; i += 2; } else if (source.startsWith('*/', i)) { blockDepth -= 1; i += 2; } else i += 1; } continue; }
    const start = i; const raw = source[i] === 'r' && (source[i + 1] === "'" || source[i + 1] === '"');
    const quoteAt = raw ? i + 1 : i;
    if (source[quoteAt] === "'" || source[quoteAt] === '"') {
      const quote = source[quoteAt]; const triple = source.slice(quoteAt, quoteAt + 3) === quote.repeat(3); const endMark = triple ? quote.repeat(3) : quote;
      i = quoteAt + endMark.length; let value = '';
      while (i < source.length && !source.startsWith(endMark, i)) { if (source[i] === '\\' && !raw) { value += source[i + 1] || ''; i += 2; } else { value += source[i]; i += 1; } }
      i += endMark.length; tokens.push({ type: 'string', value, start, line: line(start) }); continue;
    }
    if (/[A-Za-z_$]/.test(source[i])) { i += 1; while (i < source.length && /[\w$]/.test(source[i])) i += 1; tokens.push({ type: 'word', value: source.slice(start, i), start, line: line(start) }); continue; }
    tokens.push({ type: 'punct', value: source[i], start, line: line(start) }); i += 1;
  }
  return tokens;
}

function directives(source) {
  const tokens = tokenize(source); const found = [];
  for (let i = 0; i < tokens.length; i += 1) {
    if (tokens[i].type !== 'word' || !['import', 'export'].includes(tokens[i].value)) continue;
    const uris = []; let end = i + 1;
    for (; end < tokens.length && tokens[end].value !== ';'; end += 1) if (tokens[end].type === 'string') uris.push(tokens[end]);
    if (uris.length) found.push(...uris.map((uri) => ({ uri: uri.value, line: tokens[i].line, start: tokens[i].start })));
    i = end;
  }
  return found;
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
    let dirEntries; try { dirEntries = fs.readdirSync(dir, { withFileTypes: true }); } catch { continue; }
    for (const entry of dirEntries) {
      if (entry.isSymbolicLink() || !entry.isDirectory()) continue;
      const name = entry.name;
      const memberRoot = path.join(dir, name);
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
    const member = members.find((m) => file === m.root || file.startsWith(`${m.root}${path.sep}`));
    const isDomain = rel.split('/').includes('domain');
    const isPresentation = rel.split('/').includes('presentation');
    for (const match of directives(source)) {
      const specifier = match.uri;
      let rule = null;
      const isFileUri = specifier.startsWith('.') || specifier.startsWith('/');
      if (isDomain && (/^package:(?:flutter(?:_riverpod)?|dio)\//.test(specifier) || (isFileUri && /(?:^|[/\\])(?:data|presentation)(?:[/\\]|$)/.test(specifier)))) {
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
        if (isPresentation && targetMember === member && target.includes(`${path.sep}presentation${path.sep}`) && target.includes(`${path.sep}src${path.sep}`)) {
          const sourceParts = path.relative(member.lib, file).split(path.sep);
          const targetParts = path.relative(member.lib, target).split(path.sep);
          if (sourceParts[1] && targetParts[1] && sourceParts[1] !== targetParts[1]) rule = 'package-boundary';
        }
      }
      if (rule) results.push({ file: rel, line: match.line, rule, import: specifier });
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
