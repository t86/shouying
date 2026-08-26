const fs = require('node:fs');
const path = require('node:path');

function lineNumber(source, offset) {
  return source.slice(0, offset).split('\n').length;
}

function toSourcePath(component) {
  return component.startsWith('@/') ? `src/${component.slice(2)}` : component;
}

function sourceLine(file, line) {
  return `${file}:${line}`;
}

function maskComments(source) {
  const result = source.split('');
  let state = 'normal';
  for (let index = 0; index < source.length; index += 1) {
    const character = source[index];
    const next = source[index + 1];
    if (state === 'normal') {
      if (source.startsWith('<!--', index)) { state = 'html'; result[index] = result[index + 1] = result[index + 2] = result[index + 3] = ' '; index += 3; }
      else if (character === '/' && next === '/') { state = 'line'; result[index] = result[index + 1] = ' '; index += 1; }
      else if (character === '/' && next === '*') { state = 'block'; result[index] = result[index + 1] = ' '; index += 1; }
      else if (character === "'") state = 'single';
      else if (character === '"') state = 'double';
      else if (character === '`') state = 'template';
    } else if (state === 'line') {
      if (character === '\n') state = 'normal'; else result[index] = ' ';
    } else if (state === 'block') {
      if (character === '*' && next === '/') { result[index] = result[index + 1] = ' '; index += 1; state = 'normal'; }
      else if (character !== '\n') result[index] = ' ';
    } else if (state === 'html') {
      if (source.startsWith('-->', index)) { result[index] = result[index + 1] = result[index + 2] = ' '; index += 2; state = 'normal'; }
      else if (character !== '\n') result[index] = ' ';
    } else if ((state === 'single' || state === 'double') && character === '\\') {
      index += 1;
    } else if (state === 'single' && character === "'") state = 'normal';
    else if (state === 'double' && character === '"') state = 'normal';
    else if (state === 'template' && character === '`') state = 'normal';
  }
  return result.join('');
}

function maskLiterals(source) {
  return source.replace(/(['"`])(?:\\.|(?!\1)[\s\S])*\1/g, (literal) => literal.replace(/[^\n]/g, ' '));
}

function maskChildren(source) {
  const child = source.search(/\bchildren\s*:/);
  if (child < 0) return source;
  const start = source.indexOf('[', child);
  if (start < 0) return source;
  let depth = 0;
  for (let index = start; index < source.length; index += 1) {
    if (source[index] === '[') depth += 1;
    else if (source[index] === ']') {
      depth -= 1;
      if (depth === 0) return `${source.slice(0, start)}${source.slice(start, index + 1).replace(/[^\n]/g, ' ')}${source.slice(index + 1)}`;
    }
  }
  return source;
}

function extractRoutes(file, source) {
  const masked = maskComments(source);
  const structure = maskLiterals(masked);
  const routes = [];
  const ranges = [];
  const stack = [];
  for (let index = 0; index < structure.length; index += 1) {
    if (structure[index] === '{') stack.push(index);
    else if (structure[index] === '}' && stack.length) ranges.push({ start: stack.pop(), end: index });
  }
  const pathPattern = /\bpath:\s*['"`]([^'"`]*)['"`]/g;
  let pathMatch;
  while ((pathMatch = pathPattern.exec(masked))) {
    const object = ranges.filter((range) => range.start < pathMatch.index && range.end > pathMatch.index).sort((a, b) => b.start - a.start)[0];
    if (!object) continue;
    const window = maskChildren(masked.slice(object.start, object.end + 1));
    const nameMatch = window.match(/\bname:\s*['"`]([^'"`]*)['"`]/);
    const titleMatch = window.match(/\btitle:\s*['"`]([^'"`]*)['"`]/);
    const componentMatch = window.match(/['"`](@\/[^'"`]+\.vue)/);
    if (!componentMatch) continue;
    routes.push({
      path: pathMatch[1],
      ...(nameMatch ? { name: nameMatch[1] } : {}),
      ...(titleMatch ? { title: titleMatch[1] } : {}),
      component: toSourcePath(componentMatch[1]),
      source: sourceLine(file, lineNumber(source, pathMatch.index)),
    });
  }
  return routes;
}

function extractApiCalls(file, source) {
  const calls = [];
  const masked = maskComments(source);
  const declarations = [];
  const declarationPattern = /^\s*([A-Za-z_$][\w$]*)\s*:\s*(?:(?:\([^)]*\)|[A-Za-z_$][\w$]*)\s*=>|\([^)]*\)\s*\{)/gm;
  let declaration;
  while ((declaration = declarationPattern.exec(masked))) {
    declarations.push({ symbol: declaration[1], offset: declaration.index });
  }
  const methodPattern = /^\s*([A-Za-z_$][\w$]*)\s*\([^)]*\)\s*\{/gm;
  const reserved = new Set(['if', 'for', 'while', 'switch', 'catch', 'try', 'finally', 'with']);
  while ((declaration = methodPattern.exec(masked))) {
    if (!reserved.has(declaration[1])) declarations.push({ symbol: declaration[1], offset: declaration.index });
  }
  declarations.sort((left, right) => left.offset - right.offset);
  const expression = /(?:axios\.)?(binaryFilePost|binaryFileGet|post|get)\s*\(\s*`\$\{base\.([A-Za-z0-9_$]+)\}([^`]*)`/g;
  const add = (symbol, method, baseKey, apiPath, line) => {
    const normalizedMethod = method === 'get' || method === 'binaryFileGet' ? 'GET' : 'POST';
    calls.push({ symbol, method: normalizedMethod, baseKey, path: apiPath, source: sourceLine(file, line) });
  };
  let match;
  while ((match = expression.exec(masked))) {
    const declarationForCall = declarations.filter((candidate) => candidate.offset <= match.index).at(-1);
    const nextDeclaration = declarations.find((candidate) => candidate.offset > (declarationForCall?.offset ?? -1));
    if (declarationForCall && (!nextDeclaration || match.index < nextDeclaration.offset)) {
      add(declarationForCall.symbol, match[1], match[2], match[3], lineNumber(source, match.index));
    }
  }
  return calls;
}

function extractCues(file, source) {
  const cues = [];
  const rules = [
    ['permission', /authstatus|getauthstatus|roleids|sub_permissions|sysrole|permission/i],
    ['storage', /localstorage|sessionstorage/i],
    ['websocket', /websocket/i],
    ['device', /atool|startqrcodescan|card_scan|print/i],
  ];
  maskLiterals(maskComments(source)).split('\n').forEach((line, index) => {
    rules.forEach(([kind, pattern]) => {
      if (pattern.test(line)) cues.push({ kind, source: sourceLine(file, index + 1) });
    });
  });
  return cues;
}

function walk(directory, root, files = []) {
  const excluded = new Set(['node_modules', 'vendor', 'generated', 'dist', 'build']);
  for (const entry of fs.readdirSync(directory, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
    if (excluded.has(entry.name)) continue;
    const fullPath = path.join(directory, entry.name);
    if (entry.isDirectory()) walk(fullPath, root, files);
    else if (entry.isFile() && /\.(?:js|vue)$/.test(entry.name)) files.push(path.relative(root, fullPath).split(path.sep).join('/'));
  }
  return files;
}

function buildInventory(root) {
  const sourceRoot = path.join(root, 'src');
  const rootReal = fs.realpathSync(root);
  const sourceStat = fs.lstatSync(sourceRoot);
  if (sourceStat.isSymbolicLink() || fs.realpathSync(sourceRoot) !== path.join(rootReal, 'src')) {
    throw new Error('src directory must be real and contained');
  }
  const files = walk(sourceRoot, root).sort();
  const vueFiles = files.filter((file) => file.endsWith('.vue'));
  const routes = [];
  const apiCalls = [];
  files.forEach((file) => {
    const source = fs.readFileSync(path.join(root, file), 'utf8');
    if (file.startsWith('src/router/') && file.endsWith('.js')) routes.push(...extractRoutes(file, source));
    if (file.startsWith('src/api/') && file.endsWith('.js')) apiCalls.push(...extractApiCalls(file, source));
  });
  const cues = [];
  files.forEach((file) => {
    const source = fs.readFileSync(path.join(root, file), 'utf8');
    cues.push(...extractCues(file, source));
  });
  return {
    schemaVersion: 1,
    vueFiles,
    routes,
    apiModules: files.filter((file) => file.startsWith('src/api/') && file.endsWith('.js')),
    apiCalls,
    cues,
  };
}

if (require.main === module) {
  const root = path.resolve(__dirname, '..', '..');
  const output = path.join(root, 'migration/flutter/generated/source-inventory.json');
  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, `${JSON.stringify(buildInventory(root), null, 2)}\n`);
}

module.exports = { extractRoutes, extractApiCalls, extractCues, buildInventory };
