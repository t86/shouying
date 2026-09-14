const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const source = fs.readFileSync(
  path.join(__dirname, '../src/components/money/drawerPayRecord.vue'), 'utf8',
);
const script = source.match(/<script>([\s\S]*?)<\/script>/)[1]
  .replace(/^import .*;$/gm, '')
  .replace('export default', 'module.exports =');
const sandbox = { module: { exports: {} } };
vm.runInNewContext(script, sandbox);
const methods = sandbox.module.exports.methods;

test('places the record cashier after payment time and before amount', () => {
  assert.match(source, /label="付款时间"[\s\S]*?prop="pe"\s+label="结账人"[\s\S]*?:formatter="formatCashier"[\s\S]*?label="付款金额"/);
});

test('uses the historical cashier name, including on self-service payment records', () => {
  for (const pi of ['现金', '微信', '支付宝', '自助支付']) {
    assert.equal(methods.formatCashier.call(methods, { pe: ' 张三 ', pi }), '张三');
  }
  assert.equal(methods.formatCashier.call(methods, { pe: '自助收银', pi: '微信' }), '自助收银');
});

test('only falls back to self-service for explicitly self-service records', () => {
  for (const pe of [undefined, null, '', ' ', '-', '--']) {
    assert.equal(methods.formatCashier.call(methods, { pe, pi: '自助支付' }), '自助收银');
    for (const pi of ['现金', '微信', '支付宝', undefined]) {
      assert.equal(methods.formatCashier.call(methods, { pe, pi }), '--');
    }
  }
});
