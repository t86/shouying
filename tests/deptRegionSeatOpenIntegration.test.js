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

function loadDeptRegionSeatOpenDrawer(mockApiBook, mockReportUtils, globals = {}) {
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
    sandboxReportUtils: mockReportUtils,
    console: { log() {} },
    ...globals
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

function createDeferred() {
  let resolve;
  let reject;
  const promise = new Promise((resolvePromise, rejectPromise) => {
    resolve = resolvePromise;
    reject = rejectPromise;
  });

  return { promise, resolve, reject };
}

const reportUtilsMock = {
  formatDepartmentName(value) {
    const name = value == null ? '' : String(value);
    const leadingSpaces = name.match(/^\s*/)[0].length;
    return { name: name.slice(leadingSpaces), indent: leadingSpaces };
  },
  isTotalRow: item => Boolean(item) && Number(item.id) === 0
};

async function runJsonBlobExport(response) {
  const warnings = [];
  let createObjectURLCalls = 0;
  let appendCalls = 0;
  let clickCalls = 0;
  const drawerOptions = loadDeptRegionSeatOpenDrawer(
    { reqExportDeptRegionSeatOpenList: async () => response },
    reportUtilsMock,
    {
      Blob,
      window: {
        URL: {
          createObjectURL() {
            createObjectURLCalls += 1;
            return 'blob:should-not-download';
          },
          revokeObjectURL() {}
        }
      },
      document: {
        body: {
          appendChild() {
            appendCalls += 1;
          }
        },
        createElement: () => ({
          click() {
            clickCalls += 1;
          }
        })
      }
    }
  );
  const context = createDrawerContext(drawerOptions);
  context.$message.warning = message => warnings.push(message);

  await context.exportExcelHandle();

  return { warnings, createObjectURLCalls, appendCalls, clickCalls };
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
  assert.equal((source.match(/\{\{\s*item\.c\s*\}\}/g) || []).length, 2);
  assert.doesNotMatch(source, /\bsafeCount\b|\btoSafeCount\b/);
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
      isTotalRow: item => Number(item.id) === 0
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

test('dept-region seat report ignores an older response that finishes last', async () => {
  const firstRequest = createDeferred();
  const secondRequest = createDeferred();
  const requests = [firstRequest, secondRequest];
  const drawerOptions = loadDeptRegionSeatOpenDrawer(
    { reqGetDeptRegionSeatOpenList: () => requests.shift().promise },
    reportUtilsMock
  );
  const context = createDrawerContext(drawerOptions);
  const firstLoad = context.getReportData();
  const secondLoad = context.getReportData();
  const deptRowsB = [{ id: 2, n: '部门 B', c: 2 }];
  const regionRowsB = [{ id: 20, n: '区域 B', c: 20 }];

  secondRequest.resolve({
    code: 1,
    data: { now_time: 'B', dept_list: deptRowsB, region_list: regionRowsB }
  });
  await secondLoad;
  firstRequest.resolve({
    code: 1,
    data: {
      now_time: 'A',
      dept_list: [{ id: 1, n: '部门 A', c: 1 }],
      region_list: [{ id: 10, n: '区域 A', c: 10 }]
    }
  });
  await firstLoad;

  assert.equal(context.nowTime, 'B');
  assert.strictEqual(context.deptList, deptRowsB);
  assert.strictEqual(context.regionList, regionRowsB);
});

test('dept-region seat report warns for the latest read failure but not a stale one', async () => {
  const firstRequest = createDeferred();
  const secondRequest = createDeferred();
  const requests = [firstRequest, secondRequest];
  const warnings = [];
  const drawerOptions = loadDeptRegionSeatOpenDrawer(
    { reqGetDeptRegionSeatOpenList: () => requests.shift().promise },
    reportUtilsMock
  );
  const context = createDrawerContext(drawerOptions);
  context.$message.warning = message => warnings.push(message);
  const staleLoad = context.getReportData();
  const currentLoad = context.getReportData();

  secondRequest.reject(new Error('current request failed'));
  await currentLoad;
  assert.deepEqual(warnings, ['读取报表失败，请稍后重试']);

  firstRequest.reject(new Error('stale request failed'));
  await staleLoad;
  assert.deepEqual(warnings, ['读取报表失败，请稍后重试']);
});

test('dept-region seat report always cleans up a failed export', async () => {
  const warnings = [];
  const revokedUrls = [];
  const removedLinks = [];
  const body = {
    appendChild(link) {
      link.parentNode = this;
    },
    removeChild(link) {
      removedLinks.push(link);
      link.parentNode = null;
    }
  };
  const link = {
    parentNode: null,
    click() {
      throw new Error('click failed');
    }
  };
  const drawerOptions = loadDeptRegionSeatOpenDrawer(
    {
      reqExportDeptRegionSeatOpenList: async () => ({
        fileName: 'report.xlsx',
        bytes: 'content'
      })
    },
    reportUtilsMock,
    {
      window: {
        URL: {
          createObjectURL: () => 'blob:report',
          revokeObjectURL: url => revokedUrls.push(url)
        }
      },
      document: {
        body,
        createElement: () => link
      },
      Blob: function Blob() {}
    }
  );
  const context = createDrawerContext(drawerOptions);
  context.$message.warning = message => warnings.push(message);

  await context.exportExcelHandle();

  assert.deepEqual(removedLinks, [link]);
  assert.deepEqual(revokedUrls, ['blob:report']);
  assert.deepEqual(warnings, ['导出失败，请稍后重试']);
});

test('dept-region seat report warns instead of downloading a JSON Blob error', async () => {
  const jsonError = new Blob(
    [JSON.stringify({ code: 0, msg: '暂无可导出数据' })],
    { type: 'application/json' }
  );
  const result = await runJsonBlobExport(jsonError);

  assert.deepEqual(result.warnings, ['暂无可导出数据']);
  assert.equal(result.createObjectURLCalls, 0);
  assert.equal(result.appendCalls, 0);
  assert.equal(result.clickCalls, 0);
});

for (const [description, content] of [
  ['successful object', JSON.stringify({ code: 1 })],
  ['null payload', 'null']
]) {
  test(`dept-region seat report rejects a JSON Blob with a ${description}`, async () => {
    const response = new Blob([content], { type: 'application/json' });
    const result = await runJsonBlobExport(response);

    assert.deepEqual(result.warnings, ['导出失败，请稍后重试']);
    assert.equal(result.createObjectURLCalls, 0);
    assert.equal(result.appendCalls, 0);
    assert.equal(result.clickCalls, 0);
  });
}

test('department indentation is added on top of the shared cell padding', () => {
  const drawerOptions = loadDeptRegionSeatOpenDrawer({}, reportUtilsMock);
  const context = createDrawerContext(drawerOptions);
  const topLevelStyle = context.departmentNameStyle({ id: 1, n: '订台一部' });
  const childStyle = context.departmentNameStyle({ id: 2, n: '  订台二部' });
  const totalStyle = context.departmentNameStyle({ id: 0, n: '任意名称' });

  assert.equal(topLevelStyle.paddingLeft, '16px');
  assert.equal(totalStyle.paddingLeft, '16px');
  assert.ok(Number.parseInt(childStyle.paddingLeft, 10) > 16);
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
  assert.match(source, /\.report-row\s*>\s*\*\s*\{[\s\S]*?padding\s*:\s*0\s+16px/);
  assert.match(
    source,
    /\.report-row\s*>\s*:first-child\s*\{[\s\S]*?justify-content\s*:\s*flex-start/
  );
  assert.match(
    source,
    /\.report-row\s*>\s*:last-child\s*\{[\s\S]*?justify-content\s*:\s*center/
  );
});

test('card machine exposes the dept-region seat report from more functions', () => {
  const source = readSource('src/views/Book/cardMachine.vue');

  assert.match(
    source,
    /<span>入客数据实时汇总<\/span>[\s\S]*?<div\s+class="option-item"\s+@click="showOrHideDeptRegionSeatOpenDrawer"\s*>[\s\S]*?<img\s+:src="imgSrc\.openCard"[^>]*>[\s\S]*?<span>部门实时订台\/区域开台<\/span>/
  );
  assert.match(
    source,
    /<drawer-seat-opening[\s\S]*?\/>[\s\S]*?<drawer-dept-region-seat-open\s+:showDrawer="showDeptRegionSeatOpenDrawer"\s+@showOrHideDrawer="showOrHideDeptRegionSeatOpenDrawer"\s*\/>/
  );
  assert.match(
    source,
    /import drawerDeptRegionSeatOpen from "@\/components\/book\/machine\/drawerDeptRegionSeatOpen";\s*\/\/ 部门实时订台\/区域开台表/
  );
  assert.match(source, /showDeptRegionSeatOpenDrawer:\s*false/);
  assert.match(
    source,
    /showOrHideDeptRegionSeatOpenDrawer\s*\(showDrawer\)\s*\{[\s\S]*?typeof showDrawer === "boolean"[\s\S]*?this\.showDeptRegionSeatOpenDrawer = showDrawer;[\s\S]*?this\.showDeptRegionSeatOpenDrawer = !this\.showDeptRegionSeatOpenDrawer;/
  );
  assert.match(source, /components:\s*\{[\s\S]*?drawerDeptRegionSeatOpen,/);
});
