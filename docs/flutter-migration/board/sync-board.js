#!/usr/bin/env node
/**
 * Flutter 移植看板同步：
 *   node docs/flutter-migration/board/sync-board.js --from-wbs
 *   node docs/flutter-migration/board/sync-board.js --from-json
 *   node docs/flutter-migration/board/sync-board.js --from-md
 *
 * 真值默认是 tasks.json。看板页 index.html 内嵌同一份数据，可双击打开。
 */
'use strict';

const fs = require('node:fs');
const path = require('node:path');

const BOARD_DIR = __dirname;
const ROOT = path.resolve(BOARD_DIR, '../../..');
const WBS_PATH = path.join(
  ROOT,
  'docs/superpowers/plans/2026-09-14-flutter-migration-task-breakdown.md',
);
const JSON_PATH = path.join(BOARD_DIR, 'tasks.json');
const MD_PATH = path.join(ROOT, 'docs/flutter-migration/BOARD.md');
const HTML_PATH = path.join(BOARD_DIR, 'index.html');
const TEMPLATE_PATH = path.join(BOARD_DIR, 'index.template.html');

const STATUSES = [
  '未开始',
  '入口已列·待接入',
  '已编码·未确认',
  'Web已接线·Android待接线',
  '已确认',
  '不移植',
];

const SYSTEMS = [
  { id: 'M0', name: '横切底座', vue: '登录 / 同步 / 设备 / 三端壳' },
  { id: 'S1', name: '预定系统', vue: 'src/router/book/index.js' },
  { id: 'S2', name: '点单系统', vue: 'src/router/order/index.js' },
  { id: 'S3', name: '收银系统', vue: 'src/router/money/index.js' },
  { id: 'S4', name: '会员系统', vue: 'src/router/vip/index.js · navList.js' },
  { id: 'S5', name: '存酒系统', vue: 'src/router/wine/index.js' },
  { id: 'S6', name: '排队', vue: 'src/router/queue/index.js' },
  { id: 'S7', name: 'BMS 门店后台', vue: 'src/router/bms/index.js（重构前注释之前）' },
  { id: 'S8', name: 'ERP 仓库', vue: 'src/router/erp/index.js（重构前注释之前）' },
  { id: 'S9', name: '超级账号', vue: 'src/views/ManagementSystem/appinfo' },
];

function normalizeStatus(raw) {
  if (!raw) return '未开始';
  const text = String(raw).trim();
  const tagged = text.match(/`([^`]+)`/);
  if (tagged) {
    const hit = STATUSES.find((s) => tagged[1].includes(s));
    if (hit) return hit;
  }
  const leading = STATUSES.find((s) => text.startsWith(s));
  if (leading) return leading;
  return '未开始';
}

function systemIdOf(taskId) {
  const m = String(taskId).match(/^(M\d+|S\d+)/);
  return m ? m[1] : 'M0';
}

function pageIdOf(taskId) {
  const m = String(taskId).match(/^(M\d+\.P\d+|S\d+\.P\d+)/);
  return m ? m[1] : systemIdOf(taskId);
}

function parseDetailLines(lines, start) {
  const details = { vue: '', flutter: '', api: '', done: '', note: '' };
  let i = start;
  const extra = [];
  while (i < lines.length) {
    const line = lines[i];
    if (/^#{1,4} /.test(line) || /^- \[[ xX]\] \*\*/.test(line) || line.startsWith('| ')) {
      break;
    }
    const m = line.match(/^\s+-\s+(Vue|Flutter|API|完成|对照|数据|规格|路由|平台|清台|备注|分组)[:：]\s*(.*)$/);
    if (m) {
      if (m[1] === '分组') {
        details.group = m[2];
        i += 1;
        continue;
      }
      const key = { Vue: 'vue', Flutter: 'flutter', API: 'api', 完成: 'done', 对照: 'note', 数据: 'note', 规格: 'note', 路由: 'note', 平台: 'note', 清台: 'note', 备注: 'note' }[m[1]];
      if (key === 'note') {
        if (m[1] === '备注') extra.push(m[2]);
        else extra.push(line.trim().replace(/^- /, ''));
      }
      else details[key] = details[key] ? `${details[key]}；${m[2]}` : m[2];
    } else if (line.trim() && !line.startsWith('---') && !line.startsWith('每个 Rxx')) {
      extra.push(line.trim().replace(/^- /, ''));
    } else if (!line.trim()) {
      if (extra.length || details.vue || details.api) break;
    }
    i += 1;
  }
  if (extra.length) details.note = [details.note, ...extra].filter(Boolean).join(' ');
  return { details, next: i };
}

function parseCheckboxTasks(markdown) {
  const lines = markdown.split(/\r?\n/);
  const tasks = [];
  let systemName = '';
  let pageId = '';
  let pageName = '';
  let group = '';

  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    const sys = line.match(/^## (M\d+|S\d+)\s+(.+)$/);
    if (sys) {
      systemName = sys[2].replace(/（.*）/, '').trim();
      continue;
    }
    const page = line.match(/^### ((?:M|S)\d+\.P\d+)\s+(.+)$/);
    if (page) {
      pageId = page[1];
      pageName = page[2].trim();
      group = '';
      continue;
    }
    const h3plain = line.match(/^### (.+)$/);
    if (h3plain && !line.startsWith('### 0.')) {
      pageName = h3plain[1].trim();
      group = '';
      continue;
    }
    const grp = line.match(/^#### (.+)$/);
    if (grp) {
      group = grp[1].trim();
      continue;
    }

    const task = line.match(/^- \[([ xX])\] \*\*(\S+)\s+(.+?)\*\*(?:\s+`([^`]+)`)?(.*)$/);
    if (!task) continue;
    const id = task[2];
    if (id === 'S3.P1.Rxx.a' || id === 'S3.P1.Rxx.b' || id === 'S3.P1.Rxx.c') continue;
    if (id === 'S8.P5.T01～T09') continue;

    const titleAndRest = task[3];
    const status = normalizeStatus(task[4] || task[5] || '');
    const inline = (task[5] || '').replace(/^[—–-]\s*/, '').trim();
    const { details, next } = parseDetailLines(lines, i + 1);
    i = next - 1;
    if (inline && !details.api && !details.vue) {
      details.note = [inline, details.note].filter(Boolean).join(' ');
      if (inline.includes('POST ') || inline.includes('/')) details.api = details.api || inline;
    }

    tasks.push({
      id,
      title: titleAndRest.replace(/`/g, '').trim(),
      status,
      system: systemIdOf(id),
      page: pageIdOf(id) || pageId,
      pageName,
      group: details.group ?? group,
      vue: details.vue,
      flutter: details.flutter,
      api: details.api || (inline.includes('POST') ? inline : ''),
      done: details.done,
      note: details.note,
    });
  }
  return tasks;
}

function parsePipeTable(block) {
  const rows = block
    .split('\n')
    .map((l) => l.trim())
    .filter((l) => l.startsWith('|') && !/^\|\s*-+/.test(l));
  if (rows.length < 2) return [];
  const header = rows[0]
    .split('|')
    .map((c) => c.trim())
    .filter(Boolean);
  return rows.slice(1).map((row) => {
    const cols = row
      .split('|')
      .map((c) => c.trim())
      .filter((_, idx, arr) => idx > 0 && idx < arr.length - 1);
    const obj = {};
    header.forEach((h, i) => {
      obj[h] = cols[i] || '';
    });
    return obj;
  });
}

function expandCashierReports(markdown, existingIds) {
  const match = markdown.match(/#### 更多功能 37 项[\s\S]*?\n\n每个 Rxx/);
  if (!match) return [];
  const table = match[0].slice(match[0].indexOf('| ID |'));
  const rows = parsePipeTable(table);
  return rows
    .map((row) => {
      const rid = row.ID || row.Id;
      if (!rid) return null;
      const id = `S3.P1.${rid}`;
      if (existingIds.has(id)) return null;
      const rawStatus = row['状态'] || '';
      let status = normalizeStatus(rawStatus);
      if (/同上|入口/.test(rawStatus)) status = '入口已列·待接入';
      if (rid === 'R22') status = '入口已列·待接入';
      return {
        id,
        title: row['菜单'] || rid,
        status,
        system: 'S3',
        page: 'S3.P1',
        pageName: '`/moneyCard` 收银卡台首页',
        group: '更多功能',
        vue: row.Vue ? `src/components/money/${row.Vue}` : '',
        flutter: 'packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart',
        api: [row['读 API'], row['导出/打印 API']].filter((s) => s && s !== '—' && s !== '无').join(' ； '),
        done: '查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线',
        note: row['状态'] || '',
      };
    })
    .filter(Boolean);
}

function expandErpReports(markdown, existingIds) {
  const match = markdown.match(/### S8\.P5 报表[\s\S]*?\n- \[ \] \*\*S8\.P5/);
  if (!match) return [];
  const tableStart = match[0].indexOf('| 任务 |');
  if (tableStart < 0) return [];
  const rows = parsePipeTable(match[0].slice(tableStart));
  return rows
    .map((row) => {
      const tid = row['任务'];
      if (!tid) return null;
      const id = `S8.P5.${tid}`;
      if (existingIds.has(id)) return null;
      return {
        id,
        title: `${row['路由'] || tid} 报表`.trim(),
        status: '未开始',
        system: 'S8',
        page: 'S8.P5',
        pageName: '报表（查询 + 导出）',
        group: '',
        vue: row.Vue ? `src/views/ManagementSystem/ERP/rpt_erp/${row.Vue}` : '',
        flutter: 'packages/features/erp 报表 Screen',
        api: [row['读 API'], row['导出']].filter(Boolean).join(' ； '),
        done: '查询+导出列与 Vue 一致；参数接口 POST /rpt_erp/param_items',
        note: '',
      };
    })
    .filter(Boolean);
}

function parseWbs(markdown) {
  const tasks = parseCheckboxTasks(markdown);
  const ids = new Set(tasks.map((t) => t.id));
  tasks.push(...expandCashierReports(markdown, ids));
  expandErpReports(markdown, ids).forEach((t) => {
    if (!ids.has(t.id)) tasks.push(t);
  });
  return dedupe(tasks);
}

function dedupe(tasks) {
  const seen = new Set();
  return tasks.filter((t) => {
    if (seen.has(t.id)) return false;
    seen.add(t.id);
    return true;
  });
}

function parseBoardMd(markdown) {
  return parseCheckboxTasks(markdown);
}

function boardDocument(tasks) {
  const bySystem = new Map();
  for (const t of tasks) {
    if (!bySystem.has(t.system)) bySystem.set(t.system, []);
    bySystem.get(t.system).push(t);
  }
  const counts = countByStatus(tasks);
  const lines = [
    '# Flutter 移植看板',
    '',
    '> 看板服务：`http://127.0.0.1:8791/`（`node docs/flutter-migration/board/server.js`）。页面改状态会立刻写入本文件和 `board/tasks.json`。',
    '>',
    '> 代理人改状态：`node docs/flutter-migration/board/sync-board.js --set ID=状态`',
    '> 验收人确认：看板页勾选，或 `--set ID=已确认 --allow-confirm`。代理人不得代标已确认。',
    '>',
    `> 统计：共 ${tasks.length} 项；` +
      STATUSES.map((s) => `${s} ${counts[s] || 0}`).join(' · '),
    '',
  ];

  for (const sys of SYSTEMS) {
    const list = bySystem.get(sys.id) || [];
    if (!list.length) continue;
    const sysCounts = countByStatus(list);
    lines.push(`## ${sys.id} ${sys.name}`);
    lines.push('');
    lines.push(`对照：${sys.vue}  ·  ${list.length} 项  ·  已确认 ${sysCounts['已确认'] || 0}  ·  已编码未确认 ${sysCounts['已编码·未确认'] || 0}  ·  未开始 ${sysCounts['未开始'] || 0}`);
    lines.push('');
    let page = '';
    for (const t of list) {
      if (t.page !== page) {
        page = t.page;
        lines.push(`### ${t.page} ${t.pageName || ''}`.trim());
        lines.push('');
      }
      const box = t.status === '已确认' || t.status === '不移植' ? '[x]' : '[ ]';
      lines.push(`- ${box} **${t.id} ${t.title}** \`${t.status}\``);
      if (t.vue) lines.push(`  - Vue: ${t.vue}`);
      if (t.flutter) lines.push(`  - Flutter: ${t.flutter}`);
      if (t.api) lines.push(`  - API: ${t.api}`);
      if (t.done) lines.push(`  - 完成: ${t.done}`);
      if (t.note) lines.push(`  - 备注: ${t.note}`);
      lines.push(`  - 分组: ${t.group || ''}`);
    }
    lines.push('');
  }
  return `${lines.join('\n').trim()}\n`;
}

function countByStatus(tasks) {
  const c = {};
  for (const s of STATUSES) c[s] = 0;
  for (const t of tasks) c[t.status] = (c[t.status] || 0) + 1;
  return c;
}

function payload(tasks, now = new Date()) {
  return {
    version: 1,
    updated: [now.getFullYear(), now.getMonth() + 1, now.getDate()]
      .map((part, index) => String(part).padStart(index === 0 ? 4 : 2, '0')).join('-'),
    sourcePlan: 'docs/superpowers/plans/2026-09-14-flutter-migration-task-breakdown.md',
    statuses: STATUSES,
    systems: SYSTEMS,
    tasks,
  };
}

function writeOutputs(data) {
  fs.mkdirSync(BOARD_DIR, { recursive: true });
  fs.writeFileSync(JSON_PATH, `${JSON.stringify(data, null, 2)}\n`);
  fs.writeFileSync(MD_PATH, boardDocument(data.tasks));
  const template = fs.readFileSync(TEMPLATE_PATH, 'utf8');
  if (!template.includes('__TASKS_JSON__')) {
    throw new Error('index.template.html missing __TASKS_JSON__ placeholder');
  }
  const injected = template.replace(
    '__TASKS_JSON__',
    JSON.stringify(data).replace(/</g, '\\u003c'),
  );
  fs.writeFileSync(HTML_PATH, injected);
  return data;
}

function loadBoard() {
  return JSON.parse(fs.readFileSync(JSON_PATH, 'utf8'));
}

function applyStatusChange(id, status, { allowConfirm = false, actor = 'agent' } = {}) {
  if (!STATUSES.includes(status)) {
    const err = new Error(`invalid status: ${status}`);
    err.code = 'INVALID_STATUS';
    throw err;
  }
  if (status === '已确认' && !allowConfirm) {
    const err = new Error('已确认只能由验收人标记');
    err.code = 'CONFIRM_FORBIDDEN';
    throw err;
  }
  const data = loadBoard();
  const task = (data.tasks || []).find((t) => t.id === id);
  if (!task) {
    const err = new Error(`task not found: ${id}`);
    err.code = 'NOT_FOUND';
    throw err;
  }
  const prev = task.status;
  if (prev === status) {
    return { id, prev, status, actor, changed: false, board: data };
  }
  task.status = status;
  const next = payload(data.tasks);
  writeOutputs(next);
  return { id, prev, status, actor, changed: true, board: next };
}

function parseSetArgs(argv) {
  const sets = [];
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--set' && argv[i + 1]) {
      sets.push(argv[i + 1]);
      i += 1;
    } else if (arg.startsWith('--set=')) {
      sets.push(arg.slice('--set='.length));
    }
  }
  return sets.map((raw) => {
    const idx = raw.indexOf('=');
    if (idx < 1) {
      throw new Error(`--set 需要 ID=状态，收到 ${raw}`);
    }
    return { id: raw.slice(0, idx), status: raw.slice(idx + 1) };
  });
}

function mergeById(base, overlay) {
  const map = new Map(base.map((t) => [t.id, t]));
  for (const t of overlay) {
    const prev = map.get(t.id);
    if (!prev) {
      map.set(t.id, t);
      continue;
    }
    map.set(t.id, { ...prev, ...t, id: t.id });
  }
  return [...map.values()];
}

function main(argv) {
  const setPairs = parseSetArgs(argv);
  if (setPairs.length) {
    const allowConfirm = argv.includes('--allow-confirm');
    const results = setPairs.map((pair) =>
      applyStatusChange(pair.id, pair.status, { allowConfirm, actor: 'cli' }),
    );
    for (const r of results) {
      process.stdout.write(`${r.id}: ${r.prev} → ${r.status}${r.changed ? '' : ' (unchanged)'}\n`);
    }
    return;
  }

  const fromWbs = argv.includes('--from-wbs');
  const fromMd = argv.includes('--from-md');
  const fromJson = argv.includes('--from-json') || (!fromWbs && !fromMd);

  let tasks;
  if (fromWbs) {
    const markdown = fs.readFileSync(WBS_PATH, 'utf8');
    tasks = parseWbs(markdown);
    if (fs.existsSync(JSON_PATH)) {
      const prev = JSON.parse(fs.readFileSync(JSON_PATH, 'utf8'));
      const prevMap = new Map((prev.tasks || []).map((t) => [t.id, t.status]));
      tasks = tasks.map((t) => {
        const old = prevMap.get(t.id);
        if (old && old !== t.status && old === '已确认') return { ...t, status: old };
        return t;
      });
    }
  } else if (fromMd) {
    const markdown = fs.readFileSync(MD_PATH, 'utf8');
    tasks = parseBoardMd(markdown);
  } else {
    const data = JSON.parse(fs.readFileSync(JSON_PATH, 'utf8'));
    tasks = data.tasks;
  }

  const data = payload(dedupe(tasks));
  writeOutputs(data);
  const c = countByStatus(data.tasks);
  process.stdout.write(
    `synced ${data.tasks.length} tasks → tasks.json, BOARD.md, index.html\n` +
      STATUSES.map((s) => `  ${s}: ${c[s] || 0}`).join('\n') +
      '\n',
  );
}

module.exports = {
  STATUSES,
  BOARD_DIR,
  JSON_PATH,
  MD_PATH,
  HTML_PATH,
  parseWbs,
  parseBoardMd,
  parseCheckboxTasks,
  boardDocument,
  normalizeStatus,
  expandCashierReports,
  expandErpReports,
  payload,
  writeOutputs,
  loadBoard,
  applyStatusChange,
  parseSetArgs,
  countByStatus,
};

if (require.main === module) {
  main(process.argv.slice(2));
}
