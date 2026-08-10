const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

function readSource(relativePath) {
  return fs.readFileSync(path.join(__dirname, '..', relativePath), 'utf8');
}

function loadBookApi(mockAxios) {
  const source = readSource('src/api/Book/index.js')
    .replace(/^import base[^\n]*\n/m, 'const base = testBase;\n')
    .replace(/^import axios[^\n]*\n/m, 'const axios = mockAxios;\n')
    .replace('export default', 'module.exports =');
  const sandbox = {
    module: { exports: {} },
    testBase: { htgl: 'https://htgl.example.test' },
    mockAxios
  };

  vm.runInNewContext(source, sandbox, { filename: 'src/api/Book/index.js' });

  return sandbox.module.exports;
}

test('book API exposes dept-region seat report read and export endpoints', () => {
  const calls = [];
  const mockAxios = {
    post(url, params) {
      calls.push({ method: 'post', url, params });
      return 'read-result';
    },
    binaryFilePost(url, params) {
      calls.push({ method: 'binaryFilePost', url, params });
      return 'export-result';
    }
  };
  const bookApi = loadBookApi(mockAxios);
  const params = { departmentId: 7 };

  assert.equal(typeof bookApi.reqGetDeptRegionSeatOpenList, 'function');
  assert.equal(typeof bookApi.reqExportDeptRegionSeatOpenList, 'function');
  assert.equal(bookApi.reqGetDeptRegionSeatOpenList(params), 'read-result');
  assert.equal(bookApi.reqExportDeptRegionSeatOpenList(params), 'export-result');
  assert.deepEqual(
    calls.map(({ method, url }) => ({ method, url })),
    [
      {
        method: 'post',
        url: 'https://htgl.example.test/sel/rpt/get_dept_region_seat_open_list'
      },
      {
        method: 'binaryFilePost',
        url: 'https://htgl.example.test/sel/rpt/exp_dept_region_seat_open_list'
      }
    ]
  );
  assert.strictEqual(calls[0].params, params);
  assert.strictEqual(calls[1].params, params);
});
