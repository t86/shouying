'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const {
  parseWbs,
  parseBoardMd,
  boardDocument,
  normalizeStatus,
  applyStatusChange,
  parseSetArgs,
  JSON_PATH,
  MD_PATH,
  HTML_PATH,
  loadBoard,
} = require('../docs/flutter-migration/board/sync-board.js');
const { createBoardServer } = require('../docs/flutter-migration/board/server.js');

const WBS = path.join(
  __dirname,
  '../docs/superpowers/plans/2026-09-14-flutter-migration-task-breakdown.md',
);

test('normalizeStatus maps known tags', () => {
  assert.equal(normalizeStatus('已编码·未确认'), '已编码·未确认');
  assert.equal(normalizeStatus('（诊断级）'), '未开始');
  assert.equal(normalizeStatus('入口已列·待接入（回调空）'), '入口已列·待接入');
  assert.equal(normalizeStatus('入口在；点单已确认版无导出，收银必须有导出'), '未开始');
});

test('parseWbs extracts leaf tasks with vue/api and expands cashier reports', () => {
  const markdown = fs.readFileSync(WBS, 'utf8');
  const tasks = parseWbs(markdown);
  const byId = Object.fromEntries(tasks.map((t) => [t.id, t]));

  assert.ok(tasks.length >= 200, `got ${tasks.length}`);
  assert.equal(byId['M0.P4.T01'].status, '未开始');
  assert.equal(byId['S2.P1.T08'].status, '已确认');
  assert.equal(byId['S2.P1.T09'].status, '已确认');
  assert.equal(byId['S3.P1.R14'].status, '入口已列·待接入');
  assert.equal(byId['S3.P1.R01'].status, '入口已列·待接入');
  assert.equal(byId['S1.P1.T04'].status, '已编码·未确认');
  assert.match(byId['S1.P1.T04'].api || byId['S1.P1.T04'].vue, /batch_new|drawerReserved/);
  assert.ok(byId['S3.P1.R01'], 'cashier R01 expanded');
  assert.equal(byId['S3.P1.R01'].title, '班结表');
  assert.match(byId['S3.P1.R01'].api, /wkd\/get_bj/);
  assert.ok(byId['S8.P5.T01'], 'erp report T01 expanded');
  assert.equal(byId['S3.P1.Rxx.a'], undefined);
  assert.equal(byId['S8.P5.T01～T09'], undefined);
  assert.equal(new Set(tasks.map((t) => t.id)).size, tasks.length);
});

test('board markdown round-trips ids and statuses', () => {
  const markdown = fs.readFileSync(WBS, 'utf8');
  const tasks = parseWbs(markdown);
  const md = boardDocument(tasks);
  const again = parseBoardMd(md);
  assert.equal(again.length, tasks.length);
  assert.equal(again.find((t) => t.id === 'S2.P1.T08').status, '已确认');
  assert.equal(again.find((t) => t.id === 'M0.P4.T01').status, '未开始');
});

function snapshotBoard() {
  return {
    json: fs.readFileSync(JSON_PATH),
    md: fs.readFileSync(MD_PATH),
    html: fs.readFileSync(HTML_PATH),
  };
}

function restoreBoard(snap) {
  fs.writeFileSync(JSON_PATH, snap.json);
  fs.writeFileSync(MD_PATH, snap.md);
  fs.writeFileSync(HTML_PATH, snap.html);
}

test('applyStatusChange writes disk and forbids 已确认 without allowConfirm', (t) => {
  const snap = snapshotBoard();
  t.after(() => restoreBoard(snap));
  assert.throws(
    () => applyStatusChange('M0.P4.T01', '已确认'),
    (err) => err.code === 'CONFIRM_FORBIDDEN',
  );
  const result = applyStatusChange('M0.P4.T01', '已编码·未确认');
  assert.equal(result.changed, true);
  assert.equal(loadBoard().tasks.find((x) => x.id === 'M0.P4.T01').status, '已编码·未确认');
  assert.match(fs.readFileSync(MD_PATH, 'utf8'), /M0\.P4\.T01[\s\S]*已编码·未确认/);
});

test('parseSetArgs reads ID=status pairs', () => {
  assert.deepEqual(parseSetArgs(['--set', 'M0.P4.T01=已编码·未确认']), [
    { id: 'M0.P4.T01', status: '已编码·未确认' },
  ]);
});

test('board server POST /api/status persists to tasks.json', async (t) => {
  const snap = snapshotBoard();
  t.after(() => restoreBoard(snap));
  const { server } = createBoardServer();
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const { port } = server.address();
  const post = await fetch(`http://127.0.0.1:${port}/api/status`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id: 'M0.P4.T01', status: '已编码·未确认' }),
  });
  assert.equal(post.status, 200);
  const body = await post.json();
  assert.equal(body.status, '已编码·未确认');
  const health = await (await fetch(`http://127.0.0.1:${port}/api/health`)).json();
  assert.equal(health.ok, true);
  assert.equal(loadBoard().tasks.find((x) => x.id === 'M0.P4.T01').status, '已编码·未确认');
  const denied = await fetch(`http://127.0.0.1:${port}/api/status`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id: 'M0.P4.T01', status: '已确认' }),
  });
  assert.equal(denied.status, 409);
});
