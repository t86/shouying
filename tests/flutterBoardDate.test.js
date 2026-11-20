'use strict';
const assert = require('node:assert/strict');
const test = require('node:test');
const { execFileSync } = require('node:child_process');
const path = require('node:path');

test('board update day follows local calendar across UTC midnight offset', () => {
  const modulePath = path.resolve(__dirname, '../docs/flutter-migration/board/sync-board.js');
  const output = execFileSync(process.execPath, ['-e',
    `const {payload}=require(${JSON.stringify(modulePath)}); console.log(JSON.stringify(['2026-09-20T16:30:00Z','2026-09-21T16:30:00Z'].map(t=>payload([],new Date(t)).updated)));`],
    { env: {...process.env, TZ:'Asia/Shanghai'}, encoding:'utf8' });
  assert.deepEqual(JSON.parse(output), ['2026-09-21', '2026-09-22']);
});
