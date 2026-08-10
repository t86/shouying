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

function loadDeptRegionSeatOpenDrawer(mockApiBook, mockReportUtils) {
  const componentSource = readSource('src/components/book/machine/drawerDeptRegionSeatOpen.vue');
  const scriptMatch = componentSource.match(/<script>([\s\S]*?)<\/script>/);
  assert.ok(scriptMatch, 'drawer should have a script block');

  const script = scriptMatch[1]
    .replace(/^import api_book[^\n]*\n/m, 'const api_book = sandboxApiBook;\n')
    .replace(/^import reportUtils[^\n]*\n/m, 'const reportUtils = sandboxReportUtils;\n')
    .replace('export default', 'module.exports =');
  const sandbox = {
    module: { exports: {} },
    sandboxApiBook: mockApiBook,
    sandboxReportUtils: mockReportUtils
  };

  vm.runInNewContext(script, sandbox, {
    filename: 'src/components/book/machine/drawerDeptRegionSeatOpen.vue'
  });

  return sandbox.module.exports;
}

function createDrawerContext(drawerOptions) {
  const context = drawerOptions.data.call({ showDrawer: false });
  context.$message = { warning() {} };

  for (const [name, method] of Object.entries(drawerOptions.methods)) {
    context[name] = method.bind(context);
  }

  return context;
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

test('dept-region seat report preserves server-owned rows without synthesizing totals', async () => {
  const deptRows = [{ id: 11, n: '订台一部', c: 3 }];
  const regionRows = [{ id: 21, n: '大厅', c: 5 }];
  let response = {
    code: 1,
    data: {
      now_time: '2026-08-10 10:48:00',
      dept_list: deptRows,
      region_list: regionRows
    }
  };
  const drawerOptions = loadDeptRegionSeatOpenDrawer(
    { reqGetDeptRegionSeatOpenList: async () => response },
    {
      formatDepartmentName: value => ({ name: value, indent: 0 }),
      isTotalRow: item => Number(item.id) === 0,
      toSafeCount: Number
    }
  );
  const context = createDrawerContext(drawerOptions);

  await context.getReportData();

  assert.strictEqual(context.deptList, deptRows);
  assert.deepEqual(context.deptList, deptRows);
  assert.strictEqual(context.regionList, regionRows);
  assert.deepEqual(context.regionList, regionRows);
  assert.equal(context.deptList.length, 1);
  assert.equal(context.regionList.length, 1);
  assert.equal(context.deptList.some(item => Number(item.id) === 0), false);
  assert.equal(context.regionList.some(item => Number(item.id) === 0), false);

  const deptRowsWithTotal = [
    { id: 12, n: '订台二部', c: 7 },
    { id: 0, n: '后端名称不展示', c: '19' }
  ];
  const regionRowsWithTotal = [
    { id: 22, n: '包房区', c: 4 },
    { id: '0', n: '后端名称不展示', c: '23' }
  ];
  response = {
    code: 1,
    data: {
      now_time: '2026-08-10 10:49:00',
      dept_list: deptRowsWithTotal,
      region_list: regionRowsWithTotal
    }
  };

  await context.getReportData();

  assert.strictEqual(context.deptList, deptRowsWithTotal);
  assert.deepEqual(context.deptList, deptRowsWithTotal);
  assert.strictEqual(context.regionList, regionRowsWithTotal);
  assert.deepEqual(context.regionList, regionRowsWithTotal);
  assert.equal(context.deptList[1].c, '19');
  assert.equal(context.regionList[1].c, '23');
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
