const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

function createLookup(request) {
  const source = fs.readFileSync(path.join(__dirname, '../src/components/money/drawerOrderLookup.vue'), 'utf8');
  const script = source.match(/<script>([\s\S]*?)<\/script>/)[1]
    .replace(/^import .*;$/gm, '').replace('export default', 'return');
  const options = Function('api_money', script)({ reqGetOnlinePayOrderInfo: request });
  const messages = [];
  const vm = {
    ...options.data(),
    $message: { warning: text => messages.push(text), error: text => messages.push(text) },
    $emit() {},
  };
  for (const [name, method] of Object.entries(options.methods)) vm[name] = method.bind(vm);
  return { vm, messages, options };
}

test('opening and empty queries do not request orders; complete order numbers remain strings', async () => {
  const calls = [];
  const records = [{ id: '001234567890123456789', et: '2026-09-10 10:30', ps: '支付成功', pds: '商品A×2\n商品B×1', ws: '小王' }];
  const { vm, options, messages } = createLookup(async params => {
    calls.push(params);
    return { code: 1, data: { records } };
  });
  options.watch.showDrawer.call(vm, true);
  assert.equal(vm.visible, true);
  assert.equal(calls.length, 0);
  vm.orderNo = '   ';
  await vm.queryOrder();
  assert.equal(calls.length, 0);
  assert.match(messages[0], /完整订单号/);
  vm.orderNo = ' 001234567890123456789 ';
  await vm.queryOrder();
  assert.deepEqual(calls, [{ order_no: '001234567890123456789' }]);
  assert.deepEqual(vm.records, records);
  assert.equal(vm.loading, false);
});

test('reset invalidates pending results and allows a fresh query', async () => {
  let finishFirst;
  const { vm } = createLookup(params => params.order_no === 'old'
    ? new Promise(resolve => { finishFirst = resolve; })
    : Promise.resolve({ code: 1, data: { records: [{ id: 'new' }] } }));
  vm.orderNo = 'old';
  const pending = vm.queryOrder();
  vm.reset();
  assert.equal(vm.searched, false);
  assert.equal(vm.orderNo, '');
  vm.orderNo = 'new';
  await vm.queryOrder();
  finishFirst({ code: 1, data: { records: [{ id: 'old' }] } });
  await pending;
  assert.deepEqual(vm.records, [{ id: 'new' }]);
});

test('empty results and failures clear previous rows and show appropriate messages', async () => {
  for (const result of [{ code: 1, data: {} }, { code: 2, msg: '订单不存在' }, new Error('offline')]) {
    const { vm, messages } = createLookup(async () => {
      if (result instanceof Error) throw result;
      return result;
    });
    vm.records = [{ id: 'previous' }];
    vm.orderNo = '123';
    await vm.queryOrder();
    assert.deepEqual(vm.records, []);
    assert.equal(vm.loading, false);
    if (result.code === 1) assert.equal(messages.length, 0);
    else assert.equal(messages.length, 1);
  }
});

test('closing the drawer discards an in-flight result', async () => {
  let finish;
  const { vm } = createLookup(() => new Promise(resolve => { finish = resolve; }));
  vm.orderNo = '123';
  const pending = vm.queryOrder();
  vm.handleClose();
  finish({ code: 1, data: { records: [{ id: '123' }] } });
  await pending;
  assert.equal(vm.visible, false);
  assert.deepEqual(vm.records, []);
  assert.equal(vm.loading, false);
});
