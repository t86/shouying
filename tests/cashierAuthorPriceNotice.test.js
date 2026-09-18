const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

function loadMethod(file, name, nextName, responses) {
  const source = fs.readFileSync(path.join(__dirname, '..', file), 'utf8');
  const start = source.indexOf(`async ${name}()`);
  const body = source.slice(source.indexOf('{', start) + 1, source.indexOf(nextName, start)).replace(/\},\s*$/, '');
  const api = { chg_wkorder_auther: async () => {
    const response = responses.shift();
    if (response instanceof Error) throw response;
    return response;
  } };
  return new Function('api_money', `return async function() {${body}}`)(api);
}

function context() {
  const messages = [];
  const events = [];
  return {
    messages, events,
    $store: { state: { orderInfo: { currentCardInfo: { seatId: 1 } } } },
    currentItemInfo: { id: 2 }, formData: { aes: { sales_emp_id: 3 } },
    autherInfo: { id: 3 }, authOrderList: [{ id: 2, checked: true }],
    $message: Object.fromEntries(['success', 'warning', 'error'].map(type => [type, message => messages.push({ type, message })])),
    $parent: { $parent: { getOrderInfo: () => events.push('refresh') } },
    onCancelDrawer: () => events.push('close'), onCancelDialog: () => events.push('close'),
    $emit: event => events.push(event),
  };
}

for (const flag of [1, '1', 2, undefined]) {
  test(`single authorization handles amount flag ${flag}`, async () => {
    const ctx = context();
    await loadMethod('src/components/order/myOrder/drawerMyOrder.vue', 'changeShouquan', 'async changeWkorderWaiter', [{ code: 1, data: { amt_chged: flag } }]).call(ctx);
    assert.equal(ctx.messages.filter(m => m.message.includes('商品折后价格已更新')).length, Number(flag == 1));
    assert.deepEqual(ctx.events, ['refresh', 'close']);
  });
}
test('single failure ignores amount flag and does not refresh', async () => {
  const ctx = context();
  await loadMethod('src/components/order/myOrder/drawerMyOrder.vue', 'changeShouquan', 'async changeWkorderWaiter', [{ code: 0, msg: '失败', data: { amt_chged: 1 } }]).call(ctx);
  assert.deepEqual(ctx.messages, [{ type: 'warning', message: '失败' }]);
  assert.deepEqual(ctx.events, []);
});

for (const [name, responses, changed, success] of [
  ['changed once across multiple orders', [{ code: 1, data: { amt_chged: 1 } }, { code: 1, data: { amt_chged: '1' } }], true, true],
  ['unchanged and missing data', [{ code: 1, data: { amt_chged: 2 } }, { code: 1 }], false, true],
  ['partial failure preserves price notice', [{ code: 1, data: { amt_chged: 1 } }, new Error('failed')], true, true],
  ['failure flag cannot create notice', [{ code: 1 }, { code: 0, data: { amt_chged: 1 } }], false, true],
  ['all failed', [{ code: 0, data: { amt_chged: 1 } }], false, false],
]) {
  test(`batch ${name}`, async () => {
    const ctx = context();
    ctx.authOrderList = responses.map((_, id) => ({ id, checked: true }));
    await loadMethod('src/components/money/drawerBatchUpdateAuther.vue', 'onSubmit', '\n    onCancelDialog()', responses.slice()).call(ctx);
    assert.equal(ctx.messages.filter(m => m.message.includes('商品折后价格已更新')).length, Number(changed));
    assert.deepEqual(ctx.events, success ? ['success', 'close'] : []);
    assert.equal(ctx.loading, false);
  });
}
