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

test('dept-region seat report drawer declares the requested report behavior', () => {
  const source = readSource('src/components/book/machine/drawerDeptRegionSeatOpen.vue');

  assert.match(source, /部门实时订台\/区域开台表/);
  assert.match(source, /最后刷新时间/);
  assert.match(source, /部门实时订台数/);
  assert.match(source, /区域开台总数/);
  assert.match(source, /isTotalRow/);
  assert.match(source, /reqGetDeptRegionSeatOpenList/);
  assert.match(source, /reqExportDeptRegionSeatOpenList/);
  assert.doesNotMatch(source, /deptTotal|regionTotal|getCountTotal/);
  assert.doesNotMatch(source, /\bcomputed\s*:/);
  assert.doesNotMatch(source, /\.reduce\s*\(/);
  assert.doesNotMatch(source, /class=["']report-row\s+report-total["']/);

  for (const listName of ['deptList', 'regionList']) {
    assert.match(
      source,
      new RegExp(
        `v-for="\\(item, index\\) in ${listName}"[\\s\\S]*?class="report-row"[\\s\\S]*?:class="\\{ 'report-total': isTotal\\(item\\) \\}"`
      )
    );
  }
});

test('dept-region seat report rows share one grid column definition', () => {
  const source = readSource('src/style/book/machine/drawerDeptRegionSeatOpen.less');
  const gridTemplates = [...source.matchAll(/grid-template-columns\s*:\s*([^;]+);/g)]
    .map(([, value]) => value.trim());

  assert.match(source, /\.report-table\s*\{[\s\S]*?--report-columns\s*:/);
  assert.match(
    source,
    /\.report-row\s*\{[\s\S]*?grid-template-columns\s*:\s*var\(--report-columns\)/
  );
  assert.deepEqual(gridTemplates, ['var(--report-columns)']);
  assert.match(
    source,
    /\.report-row\s*>\s*:first-child\s*\{[\s\S]*?justify-content\s*:\s*flex-start/
  );
  assert.match(
    source,
    /\.report-row\s*>\s*:last-child\s*\{[\s\S]*?justify-content\s*:\s*center/
  );
});
