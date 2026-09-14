const assert = require('node:assert/strict');
const fs = require('node:fs');
const test = require('node:test');
const path = require('node:path');

test('转台路径保留最近三个台号，空记录留空，WebSocket 更新后重新计算', () => {
  const source = fs.readFileSync(path.join(__dirname, '../src/components/common/cardTransferHistory.vue'), 'utf8');
  const script = source.match(/<script>([\s\S]*?)<\/script>/)[1];
  const options = Function(script.replace('export default', 'return'))();
  const context = { history: '1-2-3-4-5' };
  const getNames = () => options.computed.recentSeats.call(context);
  assert.deepEqual(getNames(), ['5', '4', '3']);
  context.history = '卡台一 - 卡台二';
  assert.deepEqual(getNames(), ['卡台二', '卡台一']);
  context.history = '1-2-3-4-5-6';
  assert.deepEqual(getNames(), ['6', '5', '4']);
  for (const history of [null, undefined, '', '  ', '-']) {
    context.history = history;
    assert.deepEqual(getNames(), []);
  }
});
