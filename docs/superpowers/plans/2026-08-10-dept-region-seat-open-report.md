# 部门实时订台 / 区域开台报表 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在咨客系统“更多功能”中增加可查询、汇总并导出部门实时订台和区域当日开台数量的双表报表。

**Architecture:** 新增独立 Vue 抽屉组件承载查询、展示和导出，`cardMachine.vue` 仅管理入口与显隐；`src/api/Book/index.js` 沿用现有请求封装。部门缩进、数量归一化和后端合计行识别放在 CommonJS 纯函数工具中，使用项目现有 Node Test Runner 做测试驱动验证；前端不自行计算合计。

**Tech Stack:** Vue 2.6、Element UI、Less、Axios、Node.js `node:test`。

---

## 文件结构

- Create: `src/utils/deptRegionSeatOpenReport.js` — 数量归一化、后端合计行识别和部门层级格式化。
- Create: `tests/deptRegionSeatOpenReport.test.js` — 纯函数行为测试。
- Modify: `src/api/Book/index.js` — 查询、导出接口方法。
- Create: `src/components/book/machine/drawerDeptRegionSeatOpen.vue` — 报表抽屉、数据加载和导出。
- Create: `src/style/book/machine/drawerDeptRegionSeatOpen.less` — 双表布局和现有深色抽屉风格。
- Modify: `src/views/Book/cardMachine.vue` — “更多功能”入口、显隐状态和组件挂载。
- Create: `tests/deptRegionSeatOpenIntegration.test.js` — API、组件和页面接线契约测试。

### Task 1: 报表纯逻辑

**Files:**
- Create: `tests/deptRegionSeatOpenReport.test.js`
- Create: `src/utils/deptRegionSeatOpenReport.js`

- [ ] **Step 1: 写失败测试**

```js
const assert = require('assert');
const test = require('node:test');

const {
  formatDepartmentName,
  isTotalRow,
  toSafeCount,
} = require('../src/utils/deptRegionSeatOpenReport');

test('converts leading department spaces into indentation', () => {
  assert.deepStrictEqual(formatDepartmentName('订台一部'), {
    name: '订台一部',
    indent: 0,
  });
  assert.deepStrictEqual(formatDepartmentName('  一部一组'), {
    name: '一部一组',
    indent: 2,
  });
  assert.deepStrictEqual(formatDepartmentName('\u3000二部一组'), {
    name: '二部一组',
    indent: 2,
  });
});

test('normalizes invalid counts to zero', () => {
  assert.strictEqual(toSafeCount(6), 6);
  assert.strictEqual(toSafeCount('4'), 4);
  assert.strictEqual(toSafeCount(undefined), 0);
  assert.strictEqual(toSafeCount('invalid'), 0);
  assert.strictEqual(toSafeCount(Infinity), 0);
});

test('recognizes backend total rows by zero id', () => {
  assert.strictEqual(isTotalRow({ id: 0 }), true);
  assert.strictEqual(isTotalRow({ id: '0' }), true);
  assert.strictEqual(isTotalRow({ id: 1 }), false);
  assert.strictEqual(isTotalRow(null), false);
});
```

- [ ] **Step 2: 运行测试并确认因工具模块缺失而失败**

Run: `node --test tests/deptRegionSeatOpenReport.test.js`

Expected: FAIL，错误包含 `Cannot find module '../src/utils/deptRegionSeatOpenReport'`。

- [ ] **Step 3: 写最小实现**

```js
function toSafeCount(value) {
  const count = Number(value);
  return Number.isFinite(count) ? count : 0;
}

function isTotalRow(item) {
  return Boolean(item) && Number(item.id) === 0;
}

function formatDepartmentName(value) {
  const rawName = value === undefined || value === null ? '' : String(value);
  const leadingWhitespace = rawName.match(/^[\s\u3000]*/)[0];
  const indent = Array.from(leadingWhitespace).reduce((total, char) => {
    return total + (char === '\u3000' ? 2 : 1);
  }, 0);

  return {
    name: rawName.replace(/^[\s\u3000]+/, ''),
    indent,
  };
}

module.exports = {
  formatDepartmentName,
  isTotalRow,
  toSafeCount,
};
```

- [ ] **Step 4: 运行测试并确认通过**

Run: `node --test tests/deptRegionSeatOpenReport.test.js`

Expected: 3 tests PASS。

- [ ] **Step 5: 提交纯逻辑**

```bash
git add tests/deptRegionSeatOpenReport.test.js src/utils/deptRegionSeatOpenReport.js
git commit -m "test(book): define dept region report calculations"
```

### Task 2: 查询与导出接口

**Files:**
- Create: `tests/deptRegionSeatOpenIntegration.test.js`
- Modify: `src/api/Book/index.js`

- [ ] **Step 1: 写 API 路径失败测试**

```js
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const test = require('node:test');

const readSource = (relativePath) => fs.readFileSync(
  path.join(__dirname, '..', relativePath),
  'utf8'
);

test('book API exposes dept-region seat report read and export endpoints', () => {
  const source = readSource('src/api/Book/index.js');

  assert.match(source, /reqGetDeptRegionSeatOpenList:\s*params\s*=>\s*axios\.post\(`\$\{base\.htgl\}\/sel\/rpt\/get_dept_region_seat_open_list`,\s*params\)/);
  assert.match(source, /reqExportDeptRegionSeatOpenList:\s*params\s*=>\s*axios\.binaryFilePost\(`\$\{base\.htgl\}\/sel\/rpt\/exp_dept_region_seat_open_list`,\s*params\)/);
});
```

- [ ] **Step 2: 运行测试并确认因接口方法缺失而失败**

Run: `node --test tests/deptRegionSeatOpenIntegration.test.js`

Expected: FAIL，失败断言指向 `reqGetDeptRegionSeatOpenList`。

- [ ] **Step 3: 在现有实时汇总接口旁增加两个方法**

```js
  reqGetSeatOpening: params => axios.post(`${base.htgl}/sel/rpt/get_seat_opening_list`, params),
  reqGetDeptRegionSeatOpenList: params => axios.post(`${base.htgl}/sel/rpt/get_dept_region_seat_open_list`, params),

  reqExportOpenCardExcel: params => axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_seat_open_log`, params),
  reqExportSeatOpening: params => axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_seat_opening_list`, params),
  reqExportDeptRegionSeatOpenList: params => axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_dept_region_seat_open_list`, params),
```

- [ ] **Step 4: 运行 API 契约测试并确认通过**

Run: `node --test tests/deptRegionSeatOpenIntegration.test.js`

Expected: 1 test PASS。

- [ ] **Step 5: 提交 API 改动**

```bash
git add tests/deptRegionSeatOpenIntegration.test.js src/api/Book/index.js
git commit -m "feat(book): add dept region seat report APIs"
```

### Task 3: 双表报表抽屉

**Files:**
- Modify: `tests/deptRegionSeatOpenIntegration.test.js`
- Create: `src/components/book/machine/drawerDeptRegionSeatOpen.vue`
- Create: `src/style/book/machine/drawerDeptRegionSeatOpen.less`

- [ ] **Step 1: 增加组件契约失败测试**

```js
test('dept-region report drawer renders refresh time, both tables, totals, and export', () => {
  const source = readSource('src/components/book/machine/drawerDeptRegionSeatOpen.vue');

  assert.match(source, /部门实时订台\/区域开台表/);
  assert.match(source, /最后刷新时间/);
  assert.match(source, /部门实时订台数/);
  assert.match(source, /区域开台总数/);
  assert.match(source, /isTotalRow/);
  assert.doesNotMatch(source, /deptTotal|regionTotal|getCountTotal/);
  assert.match(source, /reqGetDeptRegionSeatOpenList/);
  assert.match(source, /reqExportDeptRegionSeatOpenList/);
});

test('dept-region report uses one shared column grid for headers, rows, and totals', () => {
  const source = readSource('src/style/book/machine/drawerDeptRegionSeatOpen.less');

  assert.match(source, /--report-columns:/);
  assert.match(source, /grid-template-columns:\s*var\(--report-columns\)/);
  assert.match(source, /\.report-row\s*>\s*div:first-child[\s\S]*justify-content:\s*flex-start/);
  assert.match(source, /\.report-row\s*>\s*div:last-child[\s\S]*justify-content:\s*center/);
});
```

- [ ] **Step 2: 运行测试并确认因组件文件缺失而失败**

Run: `node --test tests/deptRegionSeatOpenIntegration.test.js`

Expected: FAIL，错误包含 `ENOENT` 和 `drawerDeptRegionSeatOpen.vue`。

- [ ] **Step 3: 创建抽屉组件**

创建完整组件：

```vue
<template>
  <div class="dept-region-seat-open-report">
    <el-drawer
      title="部门实时订台/区域开台表"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="90%"
    >
      <div class="report-toolbar" layout="row" layout-align="space-between center">
        <strong>最后刷新时间：{{ nowTime || '--' }}</strong>
        <button class="export" @click="exportExcelHandle">导出Excel</button>
      </div>

      <section class="report-section">
        <h3>部门实时订台数</h3>
        <div class="report-table">
          <div class="report-row report-head">
            <div>订台部门</div><div>实时订台数量</div>
          </div>
          <div v-if="deptList.length === 0" class="report-empty">暂无数据</div>
          <div
            v-for="(item, index) in deptList"
            :key="`dept-${item.id}-${index}`"
            class="report-row"
            :class="{ 'report-total': isTotal(item) }"
          >
            <div :style="departmentNameStyle(item)">{{ departmentName(item) }}</div>
            <div>{{ safeCount(item.c) }}</div>
          </div>
        </div>
      </section>

      <div class="report-divider"></div>

      <section class="report-section">
        <h3>区域开台总数</h3>
        <div class="report-table">
          <div class="report-row report-head"><div>区域</div><div>开台总数</div></div>
          <div v-if="regionList.length === 0" class="report-empty">暂无数据</div>
          <div
            v-for="(item, index) in regionList"
            :key="`region-${item.id}-${index}`"
            class="report-row"
            :class="{ 'report-total': isTotal(item) }"
          >
            <div>{{ rowName(item) }}</div><div>{{ safeCount(item.c) }}</div>
          </div>
        </div>
      </section>

      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="closeDrawerHandle">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import apiBook from '@/api/Book';
import reportUtils from '@/utils/deptRegionSeatOpenReport';

const {
  formatDepartmentName,
  isTotalRow,
  toSafeCount,
} = reportUtils;

export default {
  props: {
    showDrawer: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      show: false,
      nowTime: '',
      deptList: [],
      regionList: [],
    };
  },
  watch: {
    showDrawer(newValue) {
      this.show = newValue;
      if (newValue) this.getTableData();
    },
  },
  methods: {
    resetTableData() {
      this.nowTime = '';
      this.deptList = [];
      this.regionList = [];
    },
    async getTableData() {
      this.resetTableData();
      try {
        const res = await apiBook.reqGetDeptRegionSeatOpenList({});
        if (res.code !== 1) {
          this.$message.warning(res.msg);
          return;
        }

        const data = res.data || {};
        this.nowTime = data.now_time || '';
        this.deptList = Array.isArray(data.dept_list) ? data.dept_list : [];
        this.regionList = Array.isArray(data.region_list) ? data.region_list : [];
      } catch (error) {
        console.log('读取部门实时订台区域开台表失败', error);
      }
    },
    safeCount(value) {
      return toSafeCount(value);
    },
    isTotal(item) {
      return isTotalRow(item);
    },
    rowName(item) {
      return isTotalRow(item) ? '合计' : (item.n || '');
    },
    departmentName(item) {
      return isTotalRow(item) ? '合计' : formatDepartmentName(item.n).name;
    },
    departmentNameStyle(item) {
      const indent = isTotalRow(item) ? 0 : formatDepartmentName(item.n).indent;
      return { paddingLeft: `${20 + indent * 8}px` };
    },
    async exportExcelHandle() {
      try {
        const res = await apiBook.reqExportDeptRegionSeatOpenList({});
        if (res.msg) {
          this.$message.warning(res.msg);
          return;
        }

        const url = window.URL.createObjectURL(new Blob([res], {
          type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        }));
        const link = document.createElement('a');
        document.body.appendChild(link);
        link.href = url;
        link.setAttribute(
          'download',
          res.fileName ? decodeURIComponent(res.fileName) : '部门实时订台区域开台表.xlsx'
        );
        link.click();
        document.body.removeChild(link);
        window.URL.revokeObjectURL(url);
      } catch (error) {
        console.log('导出excel失败', error);
      }
    },
    closeDrawerHandle() {
      this.$emit('showOrHideDrawer', false);
    },
  },
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/common/elementFormBtn.less";
@import "../../../style/book/machine/drawerDeptRegionSeatOpen.less";
</style>
```

- [ ] **Step 4: 创建专用 Less 样式**

```less
.dept-region-seat-open-report {
  color: rgba(255, 255, 255, .8);

  .report-toolbar {
    padding: 0 24px 20px;
    font-size: 16px;

    .export {
      width: 100px;
      height: 32px;
      border: none;
      border-radius: 30px;
      background: #4b89ff;
      color: #fff;
      cursor: pointer;
    }
  }

  .report-section { margin: 0 24px 24px; }
  .report-section h3 { margin: 0 0 12px; color: #fff; }
  .report-table {
    --report-columns: minmax(0, 1fr) minmax(180px, 1fr);
    border: 1px solid #3b465b;
  }
  .report-row {
    display: grid;
    grid-template-columns: var(--report-columns);
    min-height: 44px;
  }
  .report-row > div { display: flex; align-items: center; padding: 0 20px; border-right: 1px solid #3b465b; border-bottom: 1px solid #3b465b; }
  .report-row > div:first-child { justify-content: flex-start; }
  .report-row > div:last-child { justify-content: center; border-right: 0; }
  .report-head { background: #182037; color: rgba(255, 255, 255, .55); }
  .report-total { color: #ffad45; }
  .report-empty { padding: 24px; text-align: center; border-bottom: 1px solid #3b465b; }
  .report-divider { margin: 8px 24px 24px; border-top: 1px dashed rgba(255, 255, 255, .35); }
}
```

- [ ] **Step 5: 运行逻辑与组件契约测试**

Run: `node --test tests/deptRegionSeatOpenReport.test.js tests/deptRegionSeatOpenIntegration.test.js`

Expected: 全部 PASS。

- [ ] **Step 6: 提交组件**

```bash
git add tests/deptRegionSeatOpenIntegration.test.js src/components/book/machine/drawerDeptRegionSeatOpen.vue src/style/book/machine/drawerDeptRegionSeatOpen.less
git commit -m "feat(book): add dept region seat report drawer"
```

### Task 4: 接入咨客系统“更多功能”

**Files:**
- Modify: `tests/deptRegionSeatOpenIntegration.test.js`
- Modify: `src/views/Book/cardMachine.vue`

- [ ] **Step 1: 增加页面接线失败测试**

```js
test('card machine exposes and mounts the dept-region seat report', () => {
  const source = readSource('src/views/Book/cardMachine.vue');

  assert.match(source, />部门实时订台\/区域开台</);
  assert.match(source, /showDeptRegionSeatOpenDrawer/);
  assert.match(source, /showOrHideDeptRegionSeatOpenDrawer/);
  assert.match(source, /drawerDeptRegionSeatOpen/);
});
```

- [ ] **Step 2: 运行测试并确认因入口未接入而失败**

Run: `node --test tests/deptRegionSeatOpenIntegration.test.js`

Expected: FAIL，失败断言指向菜单文字或显隐状态。

- [ ] **Step 3: 增加菜单和组件挂载**

在“入客数据实时汇总”后增加：

```vue
<div class="option-item" @click="showOrHideDeptRegionSeatOpenDrawer">
  <img :src="imgSrc.openCard" alt />
  <span>部门实时订台/区域开台</span>
</div>
```

在现有 `<drawer-seat-opening>` 后增加：

```vue
<drawer-dept-region-seat-open
  :showDrawer="showDeptRegionSeatOpenDrawer"
  @showOrHideDrawer="showOrHideDeptRegionSeatOpenDrawer"
/>
```

- [ ] **Step 4: 增加状态、方法、导入和注册**

```js
import drawerDeptRegionSeatOpen from '@/components/book/machine/drawerDeptRegionSeatOpen';

// data
showDeptRegionSeatOpenDrawer: false,

// methods
showOrHideDeptRegionSeatOpenDrawer() {
  this.showDeptRegionSeatOpenDrawer = !this.showDeptRegionSeatOpenDrawer;
},

// components
drawerDeptRegionSeatOpen,
```

- [ ] **Step 5: 运行全部新增测试**

Run: `node --test tests/deptRegionSeatOpenReport.test.js tests/deptRegionSeatOpenIntegration.test.js`

Expected: 全部 PASS。

- [ ] **Step 6: 提交页面接线**

```bash
git add tests/deptRegionSeatOpenIntegration.test.js src/views/Book/cardMachine.vue
git commit -m "feat(book): expose dept region seat report"
```

### Task 5: 完整验证与代码审查

**Files:**
- Verify only; fixes remain limited to files listed above.

- [ ] **Step 1: 运行项目全部 Node 测试**

Run: `node --test tests/*.test.js`

Expected: 全部 PASS，无未处理异常。

- [ ] **Step 2: 运行生产构建**

Run: `./node_modules/.bin/vue-cli-service build`

Expected: build exit code 0；允许记录项目既有体积警告，但不允许新增编译错误。

- [ ] **Step 3: 检查补丁质量和工作区边界**

Run: `git diff --check 1fd211ca..HEAD && git status --short`

Expected: `git diff --check` 无输出；`package.json`、`.opencode/`、`coverage/` 等用户原有改动仍未被提交。

- [ ] **Step 4: 使用 `superpowers:requesting-code-review` 审查本次实现**

重点检查：接口字段映射、0 值展示、`id === 0` 后端合计行、无前端求和、表头/数据/合计列对齐、部门缩进不改变列宽、重复打开刷新、下载资源释放、父子组件关闭事件，以及是否意外修改现有报表。

- [ ] **Step 5: 如审查产生修复，重新运行测试和构建并单独提交**

```bash
git add src/api/Book/index.js src/utils/deptRegionSeatOpenReport.js src/components/book/machine/drawerDeptRegionSeatOpen.vue src/style/book/machine/drawerDeptRegionSeatOpen.less src/views/Book/cardMachine.vue tests/deptRegionSeatOpenReport.test.js tests/deptRegionSeatOpenIntegration.test.js
git commit -m "fix(book): address dept region report review"
```
