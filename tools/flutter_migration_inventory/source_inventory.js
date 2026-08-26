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

function withoutBlockComments(source) {
  return source.replace(/\/\*[\s\S]*?\*\//g, (comment) => comment.replace(/[^\n]/g, ' '));
}

function withoutComments(source) {
  return withoutBlockComments(source).replace(/(^|\n)[ \t]*\/\/[^\n]*/g, (comment, prefix) => `${prefix}${' '.repeat(comment.length - prefix.length)}`);
}

function extractRoutes(file, source) {
  const lines = withoutComments(source).split('\n');
  const routes = [];
  let depth = 0;
  for (let index = 0; index < lines.length; index += 1) {
    const depthBefore = depth;
    const pathMatch = lines[index].match(/^\s*path:\s*['"`]([^'"`]*)['"`]/);
    if (!pathMatch) {
      depth += (lines[index].match(/{/g) || []).length - (lines[index].match(/}/g) || []).length;
      continue;
    }
    const routeDepth = depthBefore;
    let scanDepth = depthBefore;
    let end = index;
    for (; end < lines.length; end += 1) {
      scanDepth += (lines[end].match(/{/g) || []).length - (lines[end].match(/}/g) || []).length;
      if (end > index && scanDepth < routeDepth) break;
    }
    let window = lines.slice(index, end + 1).join('\n');
    const childrenStart = window.search(/\bchildren\s*:/);
    if (childrenStart >= 0) window = window.slice(0, childrenStart);
    const nameMatch = window.match(/\bname:\s*['"`]([^'"`]*)['"`]/);
    const titleMatch = window.match(/\btitle:\s*['"`]([^'"`]*)['"`]/);
    const componentMatch = window.match(/['"`](@\/[^'"`]+\.vue)/);
    if (!componentMatch) continue;
    routes.push({
      path: pathMatch[1],
      ...(nameMatch ? { name: nameMatch[1] } : {}),
      ...(titleMatch ? { title: titleMatch[1] } : {}),
      component: toSourcePath(componentMatch[1]),
      source: sourceLine(file, index + 1),
    });
    depth += (lines[index].match(/{/g) || []).length - (lines[index].match(/}/g) || []).length;
  }
  return routes;
}

function extractApiCalls(file, source) {
  const calls = [];
  const masked = withoutComments(source);
  const declarations = [];
  const declarationPattern = /^\s*([A-Za-z_$][\w$]*)\s*:\s*(?:(?:\([^)]*\)|[A-Za-z_$][\w$]*)\s*=>|\([^)]*\)\s*\{)/gm;
  let declaration;
  while ((declaration = declarationPattern.exec(masked))) {
    declarations.push({ symbol: declaration[1], offset: declaration.index });
  }
  const methodPattern = /^\s*([A-Za-z_$][\w$]*)\s*\([^)]*\)\s*\{/gm;
  while ((declaration = methodPattern.exec(masked))) {
    declarations.push({ symbol: declaration[1], offset: declaration.index });
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
  withoutComments(source).split('\n').forEach((line, index) => {
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
