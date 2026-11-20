'use strict';
const assert = require('node:assert/strict');
const test = require('node:test');
const { boardDocument, parseBoardMd } = require('../docs/flutter-migration/board/sync-board.js');
test('board notes and groups survive repeated markdown round trips', () => {
  const initial = { id:'S4.P1.T05', title:'资料维护', system:'S4', page:'S4.P1', pageName:'会员', group:'资料', status:'未开始', vue:'source', flutter:'', api:'', done:'', note:'原始备注' };
  let tasks=[initial];
  for(let i=0;i<5;i++) tasks=parseBoardMd(boardDocument(tasks));
  assert.equal(tasks[0].note, initial.note);
  assert.equal(tasks[0].group, initial.group);
});
