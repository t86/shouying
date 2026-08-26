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

function extractRoutes(file, source) {
  const lines = source.split('\n');
  const routes = [];
  for (let index = 0; index < lines.length; index += 1) {
    const pathMatch = lines[index].match(/^\s*path:\s*['"`]([^'"`]+)['"`]/);
    if (!pathMatch || /^\s*\/\//.test(lines[index]) || /^\s*\*/.test(lines[index])) continue;
    const window = lines.slice(index, index + 18).join('\n');
    const nameMatch = window.match(/\bname:\s*['"`]([^'"`]+)['"`]/);
    const titleMatch = window.match(/\btitle:\s*['"`]([^'"`]+)['"`]/);
    const componentMatch = window.match(/['"`](@\/[^'"`]+\.vue)/);
    if (!componentMatch) continue;
    routes.push({
      path: pathMatch[1],
      ...(nameMatch ? { name: nameMatch[1] } : {}),
      ...(titleMatch ? { title: titleMatch[1] } : {}),
      component: toSourcePath(componentMatch[1]),
      source: sourceLine(file, index + 1),
    });
  }
  return routes;
}

function extractApiCalls(file, source) {
  const calls = [];
  const lines = source.split('\n');
  const expression = /(?:axios\.)?(binaryFilePost|binaryFileGet|post|get)\s*\(\s*`\$\{base\.([A-Za-z0-9_$]+)\}([^`]+)`/g;
  const add = (symbol, method, baseKey, apiPath, line) => {
    const normalizedMethod = method === 'get' || method === 'binaryFileGet' ? 'GET' : 'POST';
    calls.push({ symbol, method: normalizedMethod, baseKey, path: apiPath, source: sourceLine(file, line) });
  };
  for (let lineIndex = 0; lineIndex < lines.length; lineIndex += 1) {
    const line = lines[lineIndex];
    let match;
    expression.lastIndex = 0;
    while ((match = expression.exec(line))) {
      const before = line.slice(0, match.index);
      let symbolMatch = before.match(/(?:^|[,{]\s*)([A-Za-z_$][\w$]*)\s*(?::|\([^)]*\)\s*\{)/);
      if (!symbolMatch) {
        for (let previous = lineIndex; previous >= Math.max(0, lineIndex - 8) && !symbolMatch; previous -= 1) {
          symbolMatch = lines[previous].match(/^\s*([A-Za-z_$][\w$]*)\s*\([^)]*\)\s*\{/);
        }
      }
      if (symbolMatch) add(symbolMatch[1], match[1], match[2], match[3], lineIndex + 1);
    }
  }
  return calls;
}

function extractCues(file, source) {
  const cues = [];
  const rules = [
    ['permission', /authStatus|roleIds|sub_permissions|sysRole|permission/],
    ['storage', /localStorage|sessionStorage/],
    ['websocket', /WebSocket|websocket/],
    ['device', /atool|startQrCodeScan|card_scan|print/],
  ];
  source.split('\n').forEach((line, index) => {
    rules.forEach(([kind, pattern]) => {
      if (pattern.test(line)) cues.push({ kind, source: sourceLine(file, index + 1) });
    });
  });
  return cues;
}

function walk(directory, root, files = []) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
    const fullPath = path.join(directory, entry.name);
    if (entry.isDirectory()) walk(fullPath, root, files);
    else if (/\.(?:js|vue)$/.test(entry.name)) files.push(path.relative(root, fullPath).split(path.sep).join('/'));
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

module.exports = { lineNumber, toSourcePath, extractRoutes, extractApiCalls, extractCues, buildInventory };
