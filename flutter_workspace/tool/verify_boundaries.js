#!/usr/bin/env node
const fs = require('node:fs');
const path = require('node:path');

const SKIP = new Set(['.dart_tool', 'build', 'vendor', 'node_modules']);

function tokenize(source) {
  const tokens = []; let i = 0; let blockDepth = 0; let currentLine = 1;
  const advance = (start) => { currentLine += (source.slice(start, i).match(/\n/g) || []).length; };
  while (i < source.length) {
    if (source.startsWith('//', i)) { const start = i; i = source.indexOf('\n', i + 2); if (i < 0) break; advance(start); continue; }
    if (source.startsWith('/*', i)) { const start = i; blockDepth = 1; i += 2; while (i < source.length && blockDepth) { if (source.startsWith('/*', i)) { blockDepth += 1; i += 2; } else if (source.startsWith('*/', i)) { blockDepth -= 1; i += 2; } else i += 1; } advance(start); continue; }
    const start = i; const raw = source[i] === 'r' && (source[i + 1] === "'" || source[i + 1] === '"');
    const quoteAt = raw ? i + 1 : i;
    if (source[quoteAt] === "'" || source[quoteAt] === '"') {
      const quote = source[quoteAt]; const triple = source.slice(quoteAt, quoteAt + 3) === quote.repeat(3); const endMark = triple ? quote.repeat(3) : quote;
      i = quoteAt + endMark.length; let value = '';
      while (i < source.length && !source.startsWith(endMark, i)) {
        if (!raw && source.startsWith('${', i)) { i = skipInterpolation(source, i + 2); continue; }
        if (source[i] === '\\' && !raw) { value += source[i]; value += source[i + 1] || ''; i += 2; } else { value += source[i]; i += 1; }
      }
      i += endMark.length; tokens.push({ type: 'string', value, raw, start, line: currentLine }); advance(start); continue;
    }
    if (/[A-Za-z_$]/.test(source[i])) { i += 1; while (i < source.length && /[\w$]/.test(source[i])) i += 1; tokens.push({ type: 'word', value: source.slice(start, i), start, line: currentLine }); advance(start); continue; }
    tokens.push({ type: 'punct', value: source[i], start, line: currentLine }); i += 1; advance(start);
  }
  return tokens;
}

function skipInterpolation(source, i) {
  let depth = 1;
  while (i < source.length && depth) {
    if (source.startsWith('//', i)) { i = source.indexOf('\n', i + 2); if (i < 0) return source.length; continue; }
    if (source.startsWith('/*', i)) {
      let commentDepth = 1; i += 2;
      while (i < source.length && commentDepth > 0) {
        if (source.startsWith('/*', i)) { commentDepth += 1; i += 2; }
        else if (source.startsWith('*/', i)) { commentDepth -= 1; i += 2; }
        else i += 1;
      }
      continue;
    }
    if (source[i] === "'" || source[i] === '"') { const q = source[i]; i += 1; while (i < source.length && source[i] !== q) { if (source[i] === '\\') i += 2; else i += 1; } i += 1; continue; }
    if (source[i] === '{') depth += 1; else if (source[i] === '}') depth -= 1; i += 1;
  }
  return i;
}

function directives(source) {
  const tokens = tokenize(source); const found = [];
  for (let i = 0; i < tokens.length; i += 1) {
    if (tokens[i].type !== 'word' || !['import', 'export'].includes(tokens[i].value)) continue;
    const uris = []; let end = i + 1;
    while (end < tokens.length && tokens[end].value !== ';') {
      if (tokens[end].type === 'string' && !uris.length) uris.push(tokens[end]);
      if (tokens[end].type === 'word' && tokens[end].value === 'if') {
        let cursor = end + 1; let depth = 0;
        while (cursor < tokens.length && tokens[cursor].value !== ';') { if (tokens[cursor].value === '(') depth += 1; else if (tokens[cursor].value === ')') { depth -= 1; if (!depth) { cursor += 1; break; } } cursor += 1; }
        while (tokens[cursor]?.type === 'punct' && /\s/.test(tokens[cursor].value)) cursor += 1;
        if (tokens[cursor]?.type === 'string') uris.push(tokens[cursor]);
      }
      end += 1;
    }
    if (uris.length) found.push(...uris.map((uri) => { const decoded = uri.raw ? { value: uri.value, invalid: false } : decodeUri(uri.value); return { uri: decoded.value, invalid: decoded.invalid, line: tokens[i].line, start: tokens[i].start }; }));
    i = end;
  }
  return found;
}

function decodeUri(value) {
  let result = ''; let invalid = false;
  for (let i = 0; i < value.length; i += 1) {
    if (value[i] !== '\\') { result += value[i]; continue; }
    if (value[i + 1] === 'x' && /^[0-9a-fA-F]{2}$/.test(value.slice(i + 2, i + 4))) { result += String.fromCodePoint(parseInt(value.slice(i + 2, i + 4), 16)); i += 3; continue; }
    if (value[i + 1] === 'u') {
      if (value[i + 2] === '{') { const close = value.indexOf('}', i + 3); const hex = close < 0 ? '' : value.slice(i + 3, close); const code = Number.parseInt(hex, 16); if (hex && hex.length <= 6 && /^[0-9a-fA-F]+$/.test(hex) && code <= 0x10ffff && !(code >= 0xd800 && code <= 0xdfff)) { result += String.fromCodePoint(code); i = close; continue; } }
      else if (/^[0-9a-fA-F]{4}$/.test(value.slice(i + 2, i + 6))) { result += String.fromCodePoint(parseInt(value.slice(i + 2, i + 6), 16)); i += 5; continue; }
    }
    invalid = true; result += value[i];
  }
  return { value: result, invalid };
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
      if (match.invalid) rule = 'invalid-import-uri';
      if (isDomain && (/^package:(?:flutter(?:_riverpod)?|dio)\//.test(specifier) || /(?:^|[/\\])(?:data|presentation)(?:[/\\]|$)/.test(specifier))) {
        rule = 'domain-forbidden-import';
      }
      if (/^package:/.test(specifier)) {
        const parsed = /^package:([^/]+)\/(.*)$/.exec(specifier);
        const targetPackage = parsed && packageByName.get(parsed[1]);
        if (parsed && member?.kind === 'packages' && appNames.has(parsed[1])) rule = 'package-boundary';
        if (parsed && targetPackage && member && targetPackage !== member && parsed[2] !== `${parsed[1]}.dart`) rule = 'package-boundary';
        if (parsed && parsed[2].startsWith('src/') && (!member || targetPackage !== member)) rule = 'package-boundary';
      } else if (/^(?:file:|[A-Za-z]:[\\/]|\\\\|\/)/.test(specifier)) {
        rule = 'package-boundary';
      } else if (member && specifier.startsWith('.')) {
        const target = path.resolve(path.dirname(file), specifier);
        const targetMember = members.find((m) => target === m.root || target.startsWith(`${m.root}${path.sep}`));
        if (!targetMember || targetMember !== member) rule = 'package-boundary';
        if (isPresentation && targetMember === member && target.includes(`${path.sep}presentation${path.sep}`) && target.includes(`${path.sep}src${path.sep}`)) {
          const sourceParts = path.relative(member.lib, file).split(path.sep);
          const targetParts = path.relative(member.lib, target).split(path.sep);
          if (sourceParts[1] && targetParts[1] && sourceParts[1] !== targetParts[1]) rule = 'package-boundary';
        }
      }
      if (match.invalid) rule = 'invalid-import-uri';
      if (rule) results.push({ file: rel, line: match.line, rule, import: specifier });
    }
  }
  const unique = new Map(results.map((item) => [`${item.file}\0${item.line}\0${item.rule}\0${item.import}`, item]));
  return [...unique.values()].sort((a, b) => (a.file < b.file ? -1 : a.file > b.file ? 1 : a.line - b.line || (a.rule < b.rule ? -1 : a.rule > b.rule ? 1 : 0)));
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
