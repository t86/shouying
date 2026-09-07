const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

function loadOrderApi(mockAxios) {
  const source = fs.readFileSync(
    path.join(__dirname, '../src/api/order/index.js'),
    'utf8',
  )
    .replace(/^import base[^\n]*\n/m, 'const base = testBase;\n')
    .replace(/^import axios[^\n]*\n/m, 'const axios = mockAxios;\n')
    .replace('export default', 'module.exports =');

  const sandbox = {
    module: { exports: {} },
    testBase: { htgl: 'https://example.test' },
    mockAxios,
  };

  vm.runInNewContext(source, sandbox, { filename: 'src/api/order/index.js' });
  return sandbox.module.exports;
}

test('unwraps shopping-cart rows from the records response shape', async () => {
  const records = [{ id: 1, pid: 2 }];
  const api = loadOrderApi({
    post: async () => ({ code: 1, data: { records } }),
  });

  const response = await api.reqGetShoppingList({ id: 3 });

  assert.strictEqual(response.data, records);
});

test('keeps the legacy shopping-cart array response compatible', async () => {
  const records = [{ id: 4, pid: 5 }];
  const api = loadOrderApi({
    post: async () => ({ code: 1, data: records }),
  });

  const response = await api.reqGetShoppingList({ id: 6 });

  assert.strictEqual(response.data, records);
});
