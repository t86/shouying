'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');
const { once } = require('node:events');

test('unchanged Markdown events never revert newer JSON task updates', async (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'flutter-board-watch-'));
  const board = path.join(root, 'docs/flutter-migration/board');
  fs.mkdirSync(board, {recursive: true});
  for (const name of ['server.js', 'sync-board.js']) {
    fs.copyFileSync(path.join(__dirname, '../docs/flutter-migration/board', name), path.join(board, name));
  }
  fs.writeFileSync(path.join(board, 'index.template.html'), '__TASKS_JSON__');
  const sync = require(path.join(board, 'sync-board.js'));
  const task = {id:'S1.P1.T01',title:'Test',status:'未开始',system:'S1',page:'S1.P1',pageName:'Test',group:'Test',note:'old'};
  sync.writeOutputs(sync.payload([task]));
  const {server} = require(path.join(board, 'server.js')).createBoardServer();
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  t.after(async () => {
    await new Promise(resolve => server.close(resolve));
    fs.rmSync(root, {recursive: true, force: true});
  });
  await new Promise(resolve => setTimeout(resolve, 450));
  const updated = sync.payload([{...task,status:'已编码·未确认',note:'new implementation'}]);
  fs.writeFileSync(sync.JSON_PATH, JSON.stringify(updated));
  // Editors and filesystem watchers may report a change without changed bytes.
  fs.utimesSync(sync.MD_PATH, new Date(), new Date());
  await new Promise(resolve => setTimeout(resolve, 650));
  assert.equal(sync.loadBoard().tasks[0].status, '已编码·未确认');
  assert.equal(sync.loadBoard().tasks[0].note, 'new implementation');
  // A real human Markdown edit must still import.
  fs.writeFileSync(sync.MD_PATH, sync.boardDocument([{...task,note:'edited in Markdown'}]));
  await new Promise(resolve => setTimeout(resolve, 650));
  assert.equal(sync.loadBoard().tasks[0].note, 'edited in Markdown');
});
