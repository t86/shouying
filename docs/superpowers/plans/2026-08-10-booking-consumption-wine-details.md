# 预订系统查看消费与存取酒明细 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在门店规则配置中增加两个咨客明细权限，并让预订系统按权限和卡台状态只读查看指定翻台流水的消费与存取酒明细。

**Architecture:** 把配置归一化、状态可见性、翻台标签和订单响应转换放入 CommonJS 纯函数模块，通过项目现有 Node Test Runner 做测试驱动验证。后台规则页只负责读写开关；通用明细弹窗通过 `wo/list` 读取并缓存流水数据；`cardMachine.vue` 只负责加载权限、生成菜单和打开弹窗，点单系统继续复用同一订单转换函数。

**Tech Stack:** Vue 2.6、Element UI、Less、Axios、CommonJS、Node.js `node:test`。

---

## 文件结构

- Create: `src/utils/bookingDetailAccess.js` — 配置归一化、保存字段、卡台状态矩阵、翻台标签和菜单 ID。
- Create: `tests/bookingDetailAccess.test.js` — 配置与入口规则的纯函数测试。
- Modify: `src/views/ManagementSystem/BMS/terminalRules/terminalRules.vue` — 两个子开关及读写逻辑。
- Create: `tests/terminalRulesBookingDetails.test.js` — 规则页源码契约测试。
- Create: `src/utils/orderDetailAdapter.js` — `wo/list` 安全默认值、消费记录/退单/套餐转换及展示字段。
- Create: `tests/orderDetailAdapter.test.js` — 订单与存取酒响应转换测试。
- Modify: `src/views/Order/orderMeal/newMyOrder.vue` — 改用共享订单转换函数，保持原操作界面。
- Create: `src/components/order/myOrder/readonlyConsumptionTable.vue` — 只读消费表格。
- Create: `src/components/order/myOrder/readonlyWineTable.vue` — 只读存取酒表格。
- Create: `src/components/book/machine/bookingDetailDialog.vue` — 翻台标签、请求、缓存、竞态保护和两个只读表格。
- Create: `src/style/book/machine/bookingDetailDialog.less` — 明细弹窗布局和深色主题样式。
- Modify: `src/utils/config/card.js` — 新增两个卡台菜单项。
- Modify: `src/views/Book/cardMachine.vue` — 配置加载、入口生成和弹窗接线。
- Create: `tests/bookingDetailIntegration.test.js` — 组件和卡台页接线契约测试。

### Task 1: 配置、入口矩阵与翻台标签纯逻辑

**Files:**
- Create: `tests/bookingDetailAccess.test.js`
- Create: `src/utils/bookingDetailAccess.js`

- [ ] **Step 1: 写失败测试**

```js
const assert = require('assert');
const test = require('node:test');

const {
  BOOKING_DETAIL_OPTION_IDS,
  buildTurnoverTabs,
  getBookingDetailOptionIds,
  getBookingDetailSaveFields,
  normalizeBookingDetailConfig,
} = require('../src/utils/bookingDetailAccess');

test('normalizes enabled detail permissions only when amounts are unrestricted', () => {
  assert.deepStrictEqual(normalizeBookingDetailConfig({
    limit_book_csm_amt: 2,
    enable_book_csm_dtl: 1,
    enable_book_wine_dtl: 1,
  }), {
    amountsRestricted: false,
    consumptionEnabled: true,
    wineEnabled: true,
  });

  assert.deepStrictEqual(normalizeBookingDetailConfig({
    limit_book_csm_amt: 1,
    enable_book_csm_dtl: 1,
    enable_book_wine_dtl: 1,
  }), {
    amountsRestricted: true,
    consumptionEnabled: false,
    wineEnabled: false,
  });

  assert.deepStrictEqual(normalizeBookingDetailConfig({}), {
    amountsRestricted: true,
    consumptionEnabled: false,
    wineEnabled: false,
  });
});

test('forces both saved permissions off while amount restriction is enabled', () => {
  assert.deepStrictEqual(getBookingDetailSaveFields({
    notShowAmt: true,
    consumptionEnabled: true,
    wineEnabled: true,
  }), {
    enable_book_csm_dtl: 2,
    enable_book_wine_dtl: 2,
  });

  assert.deepStrictEqual(getBookingDetailSaveFields({
    notShowAmt: false,
    consumptionEnabled: true,
    wineEnabled: false,
  }), {
    enable_book_csm_dtl: 1,
    enable_book_wine_dtl: 2,
  });
});

test('shows independent entries for eligible table states', () => {
  const bothEnabled = {
    amountsRestricted: false,
    consumptionEnabled: true,
    wineEnabled: true,
  };

  assert.deepStrictEqual(getBookingDetailOptionIds(bothEnabled, 1, 0), []);
  assert.deepStrictEqual(getBookingDetailOptionIds(bothEnabled, 1, 2), [
    BOOKING_DETAIL_OPTION_IDS.consumption,
    BOOKING_DETAIL_OPTION_IDS.wine,
  ]);
  assert.deepStrictEqual(getBookingDetailOptionIds(bothEnabled, 3, 3), []);
  assert.deepStrictEqual(getBookingDetailOptionIds(bothEnabled, 8, 3), []);
  assert.deepStrictEqual(getBookingDetailOptionIds(bothEnabled, 4, 0), [26, 27]);
  assert.deepStrictEqual(getBookingDetailOptionIds(bothEnabled, 5, 0), [26, 27]);
  assert.deepStrictEqual(getBookingDetailOptionIds(bothEnabled, 6, 0), [26, 27]);
  assert.deepStrictEqual(getBookingDetailOptionIds(bothEnabled, 7, 0), [26, 27]);

  assert.deepStrictEqual(getBookingDetailOptionIds({
    ...bothEnabled,
    wineEnabled: false,
  }, 5, 0), [26]);
});

test('builds newest-first turnover tabs with a safe first-flow fallback', () => {
  assert.deepStrictEqual(buildTurnoverTabs('A01', 3), [
    { turnoverCnt: 3, label: 'A01-003' },
    { turnoverCnt: 2, label: 'A01-002' },
    { turnoverCnt: 1, label: 'A01-001' },
  ]);
  assert.deepStrictEqual(buildTurnoverTabs('A01', 0), [
    { turnoverCnt: 0, label: 'A01-001' },
  ]);
});
```

- [ ] **Step 2: 运行测试并确认因模块缺失而失败**

Run: `node --test tests/bookingDetailAccess.test.js`

Expected: FAIL，错误包含 `Cannot find module '../src/utils/bookingDetailAccess'`。

- [ ] **Step 3: 写最小实现**

```js
const BOOKING_DETAIL_OPTION_IDS = Object.freeze({
  consumption: 26,
  wine: 27,
});

const DETAIL_VISIBLE_STATUSES = [4, 5, 6, 7];

function normalizeBookingDetailConfig(data) {
  const source = data || {};
  const amountsRestricted = Number(source.limit_book_csm_amt) !== 2;

  return {
    amountsRestricted,
    consumptionEnabled: !amountsRestricted && Number(source.enable_book_csm_dtl) === 1,
    wineEnabled: !amountsRestricted && Number(source.enable_book_wine_dtl) === 1,
  };
}

function getBookingDetailSaveFields(state) {
  const source = state || {};
  const childPermissionsAllowed = !source.notShowAmt;

  return {
    enable_book_csm_dtl: childPermissionsAllowed && source.consumptionEnabled ? 1 : 2,
    enable_book_wine_dtl: childPermissionsAllowed && source.wineEnabled ? 1 : 2,
  };
}

function isBookingDetailStatusVisible(status, turnoverCnt) {
  const normalizedStatus = Number(status);
  if (normalizedStatus === 1) return Number(turnoverCnt) > 0;
  return DETAIL_VISIBLE_STATUSES.includes(normalizedStatus);
}

function getBookingDetailOptionIds(config, status, turnoverCnt) {
  const source = config || {};
  if (source.amountsRestricted || !isBookingDetailStatusVisible(status, turnoverCnt)) {
    return [];
  }

  const ids = [];
  if (source.consumptionEnabled) ids.push(BOOKING_DETAIL_OPTION_IDS.consumption);
  if (source.wineEnabled) ids.push(BOOKING_DETAIL_OPTION_IDS.wine);
  return ids;
}

function buildTurnoverTabs(seatName, turnoverCnt) {
  const count = Math.max(0, Number(turnoverCnt) || 0);
  if (count === 0) {
    return [{ turnoverCnt: 0, label: `${seatName}-001` }];
  }

  return Array.from({ length: count }, (_, index) => {
    const current = count - index;
    return {
      turnoverCnt: current,
      label: `${seatName}-${String(current).padStart(3, '0')}`,
    };
  });
}

module.exports = {
  BOOKING_DETAIL_OPTION_IDS,
  buildTurnoverTabs,
  getBookingDetailOptionIds,
  getBookingDetailSaveFields,
  isBookingDetailStatusVisible,
  normalizeBookingDetailConfig,
};
```

- [ ] **Step 4: 运行测试并确认通过**

Run: `node --test tests/bookingDetailAccess.test.js`

Expected: 4 tests PASS。

- [ ] **Step 5: 提交纯逻辑**

```bash
git add tests/bookingDetailAccess.test.js src/utils/bookingDetailAccess.js
git commit -m "test(book): define booking detail access rules"
```

### Task 2: 后台规则配置两个子开关

**Files:**
- Create: `tests/terminalRulesBookingDetails.test.js`
- Modify: `src/views/ManagementSystem/BMS/terminalRules/terminalRules.vue:19-29,181-202,232-280,296-303`

- [ ] **Step 1: 写规则页失败契约测试**

```js
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const test = require('node:test');

const source = fs.readFileSync(
  path.join(__dirname, '../src/views/ManagementSystem/BMS/terminalRules/terminalRules.vue'),
  'utf8'
);

test('renders both booking detail switches only while amount restriction is off', () => {
  assert.match(source, /v-if="!notShowAmt"/);
  assert.match(source, /预订系统查看消费明细/);
  assert.match(source, /v-model="bookingConsumptionEnabled"/);
  assert.match(source, /预订系统查看存取酒明细/);
  assert.match(source, /v-model="bookingWineEnabled"/);
});

test('reads and saves the two org business config fields', () => {
  assert.match(source, /normalizeBookingDetailConfig\(res\.data\)/);
  assert.match(source, /getBookingDetailSaveFields/);
  assert.match(source, /enable_book_csm_dtl/);
  assert.match(source, /enable_book_wine_dtl/);
});

test('clears both child switches when amount restriction turns on', () => {
  assert.match(source, /notShowAmt\(newVal\)/);
  assert.match(source, /this\.bookingConsumptionEnabled = false/);
  assert.match(source, /this\.bookingWineEnabled = false/);
});
```

- [ ] **Step 2: 运行测试并确认缺少开关而失败**

Run: `node --test tests/terminalRulesBookingDetails.test.js`

Expected: 3 tests FAIL，首个失败断言指向 `v-if="!notShowAmt"`。

- [ ] **Step 3: 在金额限制说明后增加子开关**

```vue
        <div v-if="!notShowAmt" class="booking-detail-switches">
          <div>
            <span>预订系统查看消费明细</span>
            <el-switch
              v-model="bookingConsumptionEnabled"
              active-text="开"
              inactive-text="关"
            />
          </div>
          <div>
            <span>预订系统查看存取酒明细</span>
            <el-switch
              v-model="bookingWineEnabled"
              active-text="开"
              inactive-text="关"
            />
          </div>
        </div>
```

- [ ] **Step 4: 接入配置纯函数**

在脚本顶部增加：

```js
import bookingDetailAccess from '@/utils/bookingDetailAccess';

const {
  getBookingDetailSaveFields,
  normalizeBookingDetailConfig,
} = bookingDetailAccess;
```

在 `data()` 中增加：

```js
      bookingConsumptionEnabled: false,
      bookingWineEnabled: false,
```

在 `getTime()` 成功分支读取：

```js
          const bookingDetails = normalizeBookingDetailConfig(res.data);
          this.bookingConsumptionEnabled = bookingDetails.consumptionEnabled;
          this.bookingWineEnabled = bookingDetails.wineEnabled;
```

在 `submitHandle()` 组装参数前创建字段并展开：

```js
      const bookingDetailFields = getBookingDetailSaveFields({
        notShowAmt: this.notShowAmt,
        consumptionEnabled: this.bookingConsumptionEnabled,
        wineEnabled: this.bookingWineEnabled,
      });

      const params = {
        // 保留当前全部字段
        bind_cust: this.bingGuest ? 1 : 2,
        ...bookingDetailFields,
      };
```

在 `watch` 中增加：

```js
    notShowAmt(newVal) {
      if (!newVal) return;
      this.bookingConsumptionEnabled = false;
      this.bookingWineEnabled = false;
    },
```

- [ ] **Step 5: 增加子开关对齐样式**

```less
  .booking-detail-switches {
    display: inline-block;
    margin-left: 100px;
    vertical-align: top;

    > div {
      min-width: 360px;
    }

    span {
      display: inline-block;
      width: 220px;
    }
  }
```

- [ ] **Step 6: 运行规则测试和纯逻辑测试**

Run: `node --test tests/bookingDetailAccess.test.js tests/terminalRulesBookingDetails.test.js`

Expected: 7 tests PASS。

- [ ] **Step 7: 提交后台配置改动**

```bash
git add tests/terminalRulesBookingDetails.test.js src/views/ManagementSystem/BMS/terminalRules/terminalRules.vue
git commit -m "feat(bms): configure booking detail access"
```

### Task 3: 共享 `wo/list` 响应转换

**Files:**
- Create: `tests/orderDetailAdapter.test.js`
- Create: `src/utils/orderDetailAdapter.js`
- Modify: `src/views/Order/orderMeal/newMyOrder.vue:267-343`

- [ ] **Step 1: 写失败测试**

```js
const assert = require('assert');
const test = require('node:test');

const {
  createDetailRequestState,
  getDetailCacheKey,
  normalizeOrderDetailResponse,
  transformConsumptionRecords,
} = require('../src/utils/orderDetailAdapter');

const lookups = {
  getProductInfo: id => ({ id, name: `商品${id}` }),
  getProductInfoFromGroup: id => ({ id, name: `明细${id}` }),
  getOrderPersonInfo: id => ({ id, name: `员工${id}` }),
};

test('maps products, people, set details and returned records without mutating input', () => {
  const records = [{
    id: 1,
    pid: 10,
    wei: 20,
    ae: 30,
    pc: 1,
    is: 1,
    si: [{ i: 11 }],
    bs: [{ id: 2, pc: 1 }],
  }];

  const result = transformConsumptionRecords(records, lookups);

  assert.strictEqual(result.length, 2);
  assert.strictEqual(result[0].productInfo.name, '商品10');
  assert.strictEqual(result[0].personInfo.name, '员工20');
  assert.strictEqual(result[0].authInfo.name, '员工30');
  assert.strictEqual(result[0].si[0].groupInfo.name, '明细11');
  assert.strictEqual(result[1].back, true);
  assert.strictEqual(records[0].productInfo, undefined);
});

test('uses safe defaults for missing response sections', () => {
  assert.deepStrictEqual(normalizeOrderDetailResponse(undefined, lookups), {
    consumptionRows: [],
    wineRows: [],
    payInfo: {
      allAmt: '0.00',
      giveAmt: '0.00',
      notPayAmt: '0.00',
    },
  });
});

test('maps records, wine operations and cent-based pay totals', () => {
  const result = normalizeOrderDetailResponse({
    records: [{ id: 1, pid: 10, wei: 0, pc: 1 }],
    wine_ops: [{ t: 1, p: '青岛啤酒' }],
    pay_info: { order_amt: 1200, yh_amt: 200, payed_amt: 500 },
  }, lookups);

  assert.strictEqual(result.consumptionRows.length, 1);
  assert.deepStrictEqual(result.wineRows, [{ t: 1, p: '青岛啤酒' }]);
  assert.deepStrictEqual(result.payInfo, {
    allAmt: '12.00',
    giveAmt: '2.00',
    notPayAmt: '7.00',
  });
});

test('builds stable cache keys from seat and turnover', () => {
  assert.strictEqual(getDetailCacheKey('100', 3), '100:3');
});

test('caches loaded flows and invalidates older async requests', () => {
  const state = createDetailRequestState();
  const firstRequest = state.startRequest();
  state.set('100:3', { consumptionRows: [{ id: 1 }] });

  assert.deepStrictEqual(state.get('100:3'), { consumptionRows: [{ id: 1 }] });
  assert.strictEqual(state.isCurrent(firstRequest), true);

  const secondRequest = state.startRequest();
  assert.strictEqual(state.isCurrent(firstRequest), false);
  assert.strictEqual(state.isCurrent(secondRequest), true);

  state.clear();
  assert.strictEqual(state.get('100:3'), undefined);
  assert.strictEqual(state.isCurrent(secondRequest), false);
});
```

- [ ] **Step 2: 运行测试并确认因模块缺失而失败**

Run: `node --test tests/orderDetailAdapter.test.js`

Expected: FAIL，错误包含 `Cannot find module '../src/utils/orderDetailAdapter'`。

- [ ] **Step 3: 写共享转换实现**

```js
function safeArray(value) {
  return Array.isArray(value) ? value : [];
}

function safePerson(getOrderPersonInfo, id, fallbackName) {
  if (Number(id) === 0 && fallbackName) return { name: fallbackName };
  return getOrderPersonInfo(id) || {};
}

function mapSetItems(items, getProductInfoFromGroup) {
  return safeArray(items).map(item => ({
    ...item,
    groupInfo: getProductInfoFromGroup(item.i) || {},
  }));
}

function mapConsumptionItem(item, lookups) {
  const source = item || {};
  return {
    ...source,
    productInfo: lookups.getProductInfo(source.pid) || {},
    personInfo: safePerson(lookups.getOrderPersonInfo, source.wei, '自助'),
    authInfo: lookups.getOrderPersonInfo(source.ae) || {},
    showList: false,
    si: mapSetItems(source.si, lookups.getProductInfoFromGroup),
  };
}

function transformConsumptionRecords(records, lookups) {
  const result = [];
  safeArray(records).forEach(source => {
    const parent = mapConsumptionItem(source, lookups);
    const backs = safeArray(source.bs).map(back => mapConsumptionItem({
      ...source,
      ...back,
      bs: undefined,
      back: true,
      si: back.si || source.si,
    }, lookups));

    if (backs.length === 0 || Number(parent.pc) !== 0) result.push(parent);
    result.push(...backs);
  });
  return result;
}

function moneyFromCents(value) {
  return ((Number(value) || 0) / 100).toFixed(2);
}

function normalizeOrderDetailResponse(data, lookups) {
  const source = data || {};
  const payInfo = source.pay_info || {};
  const orderAmt = Number(payInfo.order_amt) || 0;
  const paidAmt = Number(payInfo.payed_amt) || 0;

  return {
    consumptionRows: transformConsumptionRecords(source.records, lookups),
    wineRows: safeArray(source.wine_ops).map(item => ({ ...item })),
    payInfo: {
      allAmt: moneyFromCents(orderAmt),
      giveAmt: moneyFromCents(payInfo.yh_amt),
      notPayAmt: moneyFromCents(orderAmt - paidAmt),
    },
  };
}

function getDetailCacheKey(seatId, turnoverCnt) {
  return `${Number(seatId)}:${Number(turnoverCnt)}`;
}

function createDetailRequestState() {
  let cache = Object.create(null);
  let version = 0;

  return {
    startRequest() {
      version += 1;
      return version;
    },
    isCurrent(requestVersion) {
      return requestVersion === version;
    },
    get(key) {
      return cache[key];
    },
    set(key, value) {
      cache[key] = value;
    },
    clear() {
      cache = Object.create(null);
      version += 1;
    },
  };
}

module.exports = {
  createDetailRequestState,
  getDetailCacheKey,
  normalizeOrderDetailResponse,
  transformConsumptionRecords,
};
```

- [ ] **Step 4: 运行转换测试并确认通过**

Run: `node --test tests/orderDetailAdapter.test.js`

Expected: 5 tests PASS。

- [ ] **Step 5: 让点单系统使用共享转换**

在 `newMyOrder.vue` 增加：

```js
import orderDetailAdapter from '@/utils/orderDetailAdapter';

const { normalizeOrderDetailResponse } = orderDetailAdapter;
```

把 `getOrderedData()` 成功分支中从金额换算到 `wineList` 赋值的重复转换替换为：

```js
          const detailData = normalizeOrderDetailResponse(res.data, {
            getProductInfo: common_order.getProductInfo.bind(common_order),
            getProductInfoFromGroup: common_order.getProductInfoFromGroup.bind(common_order),
            getOrderPersonInfo: common_book.getOrderPersonInfo.bind(common_book),
          });

          this.amt = detailData.payInfo;
          this.orderList = this.applyPermissionFilter(detailData.consumptionRows);
          this.wineList = detailData.wineRows;
```

- [ ] **Step 6: 运行转换测试并构建点单页面**

Run: `node --test tests/orderDetailAdapter.test.js && ./node_modules/.bin/vue-cli-service build`

Expected: 5 tests PASS，构建退出码为 0。

- [ ] **Step 7: 提交共享转换**

```bash
git add tests/orderDetailAdapter.test.js src/utils/orderDetailAdapter.js src/views/Order/orderMeal/newMyOrder.vue
git commit -m "refactor(order): share read-only detail mapping"
```

### Task 4: 只读表格与通用明细弹窗

**Files:**
- Create: `tests/bookingDetailIntegration.test.js`
- Create: `src/components/order/myOrder/readonlyConsumptionTable.vue`
- Create: `src/components/order/myOrder/readonlyWineTable.vue`
- Create: `src/components/book/machine/bookingDetailDialog.vue`
- Create: `src/style/book/machine/bookingDetailDialog.less`

- [ ] **Step 1: 写组件失败契约测试**

```js
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const test = require('node:test');

const readSource = relativePath => fs.readFileSync(
  path.join(__dirname, '..', relativePath),
  'utf8'
);

test('readonly tables expose required consumption and wine columns without actions', () => {
  const consumption = readSource('src/components/order/myOrder/readonlyConsumptionTable.vue');
  const wine = readSource('src/components/order/myOrder/readonlyWineTable.vue');

  ['状态', '名称', '数量', '单价', '小计', '服务员', '点单时间'].forEach(label => {
    assert.match(consumption, new RegExp(label));
  });
  assert.doesNotMatch(consumption, /退单|批量优惠|打印消费单/);

  ['类型', '名称', '规格', '数量', '存\/取酒操作人', '存\/取酒操作时间'].forEach(label => {
    assert.match(wine, new RegExp(label));
  });
});

test('booking detail dialog reads selected turnover, caches data and protects against stale responses', () => {
  const source = readSource('src/components/book/machine/bookingDetailDialog.vue');

  assert.match(source, /buildTurnoverTabs/);
  assert.match(source, /reqGetOrderList/);
  assert.match(source, /getDetailCacheKey/);
  assert.match(source, /createDetailRequestState/);
  assert.match(source, /detailRequestState/);
  assert.match(source, /查看消费明细/);
  assert.match(source, /查看存取酒明细/);
  assert.match(source, /readonly-consumption-table/);
  assert.match(source, /readonly-wine-table/);
});
```

- [ ] **Step 2: 运行测试并确认因组件文件缺失而失败**

Run: `node --test tests/bookingDetailIntegration.test.js`

Expected: FAIL，错误包含 `ENOENT` 和 `readonlyConsumptionTable.vue`。

- [ ] **Step 3: 创建只读消费表格**

组件只接收 `rows`，用 `item.productInfo.name`、`item.pc`、`item.p2 || item.pp`、`item.pa`、`item.personInfo.name` 和 `item.ot` 展示数据；套餐子项使用 `item.si`。状态徽标严格保留 `结、退、惠、惠2`，并在空列表时显示“暂无数据”。组件不定义点击操作或修改事件。

```vue
<template>
  <div class="readonly-detail-table consumption-table">
    <div class="detail-head detail-row">
      <div>状态</div><div>名称</div><div>数量</div><div>单价(元)</div>
      <div>小计(元)</div><div>服务员</div><div>点单时间</div>
    </div>
    <div v-if="rows.length === 0" class="detail-empty">暂无数据</div>
    <div v-for="item in rows" :key="item.id" class="detail-group">
      <div class="detail-row">
        <div class="status-cell">
          <span v-if="item.s == 5" class="badge settled">结</span>
          <span v-if="item.back" class="badge returned">退</span>
          <span v-if="item.at == 2" class="badge discount">惠</span>
          <span v-if="item.at == 3" class="badge discount">惠2</span>
        </div>
        <div>{{ item.productInfo && item.productInfo.name }}</div>
        <div>{{ item.pc }}</div>
        <div>{{ displayPrice(item) }}</div>
        <div>{{ subtotal(item) }}</div>
        <div>{{ item.personInfo && item.personInfo.name }}</div>
        <div>{{ orderTime(item.ot) }}</div>
      </div>
      <div v-for="(detail, index) in item.si" :key="`${item.id}-${index}`" class="detail-row set-detail">
        <div></div>
        <div>{{ detail.groupInfo && detail.groupInfo.name }}{{ detail.r ? `（${detail.r}）` : '' }}</div>
        <div>{{ detail.s && detail.c ? detail.s * detail.c * item.pc : detail.sc * detail.dpc * item.pc }}</div>
        <div></div><div></div><div></div><div></div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    rows: { type: Array, default: () => [] },
  },
  methods: {
    displayPrice(item) {
      if (Number(item.pp) === 0) return '时价';
      return Number(item.p2 !== undefined ? item.p2 : item.pp || 0).toFixed(2);
    },
    subtotal(item) {
      if (item.at == 2 || item.at == 3) return '0.00';
      return Number(item.pa !== undefined ? item.pa : (item.pp || 0) * (item.pc || 0)).toFixed(2);
    },
    orderTime(value) {
      return value ? String(value).slice(7) : '';
    },
  },
};
</script>
```

- [ ] **Step 4: 创建只读存取酒表格**

```vue
<template>
  <div class="readonly-detail-table wine-table">
    <div class="detail-head detail-row">
      <div>类型</div><div>名称</div><div>规格</div><div>数量</div>
      <div>存/取酒操作人</div><div>存/取酒操作时间</div>
    </div>
    <div v-if="rows.length === 0" class="detail-empty">暂无数据</div>
    <div v-for="(item, index) in rows" :key="`${item.t}-${index}`" class="detail-row">
      <div><span class="badge" :class="item.t == 1 ? 'save' : 'take'">{{ item.t == 1 ? '存' : '取' }}</span></div>
      <div>{{ item.p }}</div><div>{{ item.u }}</div><div>{{ item.c }}</div>
      <div>{{ item.n }}</div><div>{{ item.o }}</div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    rows: { type: Array, default: () => [] },
  },
};
</script>
```

- [ ] **Step 5: 创建通用明细弹窗**

弹窗 props 为 `value`、`mode` 和 `cardInfo`。`mode` 只允许 `consumption` 或 `wine`；打开时生成倒序翻台标签并加载第一项，关闭时调用 `detailRequestState.clear()` 清空缓存并使在途请求失效。核心请求实现如下：

```js
import apiOrder from '@/api/order';
import commonBook from '@/utils/common/book';
import commonOrder from '@/utils/common/order';
import bookingDetailAccess from '@/utils/bookingDetailAccess';
import orderDetailAdapter from '@/utils/orderDetailAdapter';

const { buildTurnoverTabs } = bookingDetailAccess;
const {
  createDetailRequestState,
  getDetailCacheKey,
  normalizeOrderDetailResponse,
} = orderDetailAdapter;

// data()
return {
  loading: false,
  turnoverTabs: [],
  selectedTurnoverCnt: 0,
  consumptionRows: [],
  wineRows: [],
  payInfo: { allAmt: '0.00', giveAmt: '0.00', notPayAmt: '0.00' },
  detailRequestState: createDetailRequestState(),
};

// computed
lookups() {
  return {
    getProductInfo: commonOrder.getProductInfo.bind(commonOrder),
    getProductInfoFromGroup: commonOrder.getProductInfoFromGroup.bind(commonOrder),
    getOrderPersonInfo: commonBook.getOrderPersonInfo.bind(commonBook),
  };
}

// methods
openDialog() {
  this.detailRequestState.clear();
  this.turnoverTabs = buildTurnoverTabs(this.cardInfo.name || '', this.cardInfo.turnoverCnt);
  this.selectedTurnoverCnt = this.turnoverTabs[0].turnoverCnt;
  this.loadSelectedTurnover();
}

closeDialog() {
  this.detailRequestState.clear();
  this.resetDetailData();
  this.$emit('input', false);
}

async loadSelectedTurnover() {
  const requestVersion = this.detailRequestState.startRequest();
  const cacheKey = getDetailCacheKey(this.cardInfo.id, this.selectedTurnoverCnt);
  const cached = this.detailRequestState.get(cacheKey);
  if (cached) {
    this.applyDetailData(cached);
    return;
  }

  this.loading = true;
  try {
    const res = await apiOrder.reqGetOrderList({
      seat_id: Number(this.cardInfo.id),
      turnover_cnt: Number(this.selectedTurnoverCnt),
    });
    if (!this.detailRequestState.isCurrent(requestVersion)) return;
    if (res.code !== 1) {
      this.resetDetailData();
      this.$message.warning(res.msg || '明细获取失败');
      return;
    }

    const detailData = normalizeOrderDetailResponse(res.data, this.lookups);
    this.detailRequestState.set(cacheKey, detailData);
    this.applyDetailData(detailData);
  } catch (error) {
    if (!this.detailRequestState.isCurrent(requestVersion)) return;
    this.resetDetailData();
    this.$message.warning('明细获取失败');
    console.log('预订系统读取卡台明细失败', error);
  } finally {
    if (this.detailRequestState.isCurrent(requestVersion)) this.loading = false;
  }
}
```

`value` watcher 在变为 `true` 时调用 `openDialog()`；`selectedTurnoverCnt` 只通过翻台按钮赋值并调用 `loadSelectedTurnover()`。模板使用 `el-dialog`，标题由 `mode` 映射为“查看消费明细”或“查看存取酒明细”，顶部按钮遍历 `turnoverTabs`；内容区按 `mode` 挂载对应只读表格，底部只保留“关闭”按钮。

- [ ] **Step 6: 创建弹窗样式**

`bookingDetailDialog.less` 定义：弹窗宽度 `90vw`、内容最小高度 `520px`、翻台按钮激活色 `#20a0d8`、表头七列/六列网格、滚动区、状态圆形徽标、套餐明细缩进和空态居中。所有选择器以 `.booking-detail-dialog` 或 `.readonly-detail-table` 为根，避免污染点单页面。

- [ ] **Step 7: 运行组件契约测试和构建**

Run: `node --test tests/bookingDetailIntegration.test.js tests/orderDetailAdapter.test.js && ./node_modules/.bin/vue-cli-service build`

Expected: 7 tests PASS，构建退出码为 0。

- [ ] **Step 8: 提交只读明细组件**

```bash
git add tests/bookingDetailIntegration.test.js src/components/order/myOrder/readonlyConsumptionTable.vue src/components/order/myOrder/readonlyWineTable.vue src/components/book/machine/bookingDetailDialog.vue src/style/book/machine/bookingDetailDialog.less
git commit -m "feat(book): add read-only booking detail dialog"
```

### Task 5: 预订卡台菜单与弹窗接线

**Files:**
- Modify: `tests/bookingDetailIntegration.test.js`
- Modify: `src/utils/config/card.js:7-28,126-255`
- Modify: `src/views/Book/cardMachine.vue:433-516,519-559,571-650,958-964,1158-1246,1249-1425,1882-1910`

- [ ] **Step 1: 增加卡台页失败契约测试**

```js
test('card options define both booking detail entries', () => {
  const source = readSource('src/utils/config/card.js');
  assert.match(source, /id:\s*26[\s\S]*name:\s*'查看消费明细'/);
  assert.match(source, /id:\s*27[\s\S]*name:\s*'查看存取酒明细'/);
});

test('card machine loads access config, appends eligible options and opens the dialog', () => {
  const source = readSource('src/views/Book/cardMachine.vue');
  assert.match(source, /loadBookingDetailConfig/);
  assert.match(source, /reqGetTime/);
  assert.match(source, /getBookingDetailOptionIds/);
  assert.match(source, /bookingDetailConfig/);
  assert.match(source, /booking-detail-dialog/);
  assert.match(source, /case 26/);
  assert.match(source, /case 27/);
});
```

- [ ] **Step 2: 运行测试并确认缺少菜单项而失败**

Run: `node --test tests/bookingDetailIntegration.test.js`

Expected: 新增 2 tests FAIL，首个失败断言指向菜单 ID 26。

- [ ] **Step 3: 定义两个菜单项**

在 `cardOptions` 尾部、ID 25 后增加：

```js
  {
    id: 26,
    name: '查看消费明细',
    icon: icon3,
  },
  {
    id: 27,
    name: '查看存取酒明细',
    icon: icon14,
  },
```

- [ ] **Step 4: 在卡台页挂载明细弹窗和依赖**

模板在其他卡台弹窗旁增加：

```vue
    <booking-detail-dialog
      v-model="bookingDetailDialog.visible"
      :mode="bookingDetailDialog.mode"
      :card-info="bookingDetailDialog.cardInfo"
    />
```

脚本增加：

```js
import bookingDetailDialog from '@/components/book/machine/bookingDetailDialog.vue';
import bookingDetailAccess from '@/utils/bookingDetailAccess';

const {
  getBookingDetailOptionIds,
  normalizeBookingDetailConfig,
} = bookingDetailAccess;
```

并在 `components` 注册 `bookingDetailDialog`。

- [ ] **Step 5: 增加失败关闭的权限状态和弹窗状态**

```js
      bookingDetailConfig: normalizeBookingDetailConfig(),
      bookingDetailDialog: {
        visible: false,
        mode: 'consumption',
        cardInfo: {},
      },
```

加载方法：

```js
    async loadBookingDetailConfig() {
      this.bookingDetailConfig = normalizeBookingDetailConfig();
      try {
        const res = await this.$api.BMS.terminalRules.reqGetTime();
        if (res.code !== 1) return;
        this.bookingDetailConfig = normalizeBookingDetailConfig(res.data);
        this.getCardList(
          this.$store.state.cardPageInfo.resResultDataObj.cardInfo,
          this.$store.state.cardPageInfo.resResultDataObj.businessData
        );
      } catch (error) {
        console.log('预订系统读取明细权限失败', error);
      }
    },
```

在 `mounted()` 最前面调用 `this.loadBookingDetailConfig()`。

- [ ] **Step 6: 把明细菜单追加到现有状态菜单**

在 `getCardOptions()` 的状态 switch 结束后、置顶菜单追加前增加：

```js
      optionsIdArr.push(...getBookingDetailOptionIds(
        this.bookingDetailConfig,
        status,
        turnoverCnt
      ));
```

继续沿用现有 `optionsIdArr.push(18)` 和取消置顶逻辑，最终通过 `cardOptions.find` 转成菜单对象。

- [ ] **Step 7: 处理两个入口点击**

在 `optionsClickHandle` switch 中增加并立即返回，避免落入原有 `cardDrawer`：

```js
        case 26:
          this.bookingDetailDialog = {
            visible: true,
            mode: 'consumption',
            cardInfo: { ...cardInfo },
          };
          return;
        case 27:
          this.bookingDetailDialog = {
            visible: true,
            mode: 'wine',
            cardInfo: { ...cardInfo },
          };
          return;
```

- [ ] **Step 8: 运行全部功能测试和构建**

Run: `node --test tests/bookingDetailAccess.test.js tests/terminalRulesBookingDetails.test.js tests/orderDetailAdapter.test.js tests/bookingDetailIntegration.test.js && ./node_modules/.bin/vue-cli-service build`

Expected: 16 tests PASS，构建退出码为 0。

- [ ] **Step 9: 提交预订系统接线**

```bash
git add tests/bookingDetailIntegration.test.js src/utils/config/card.js src/views/Book/cardMachine.vue
git commit -m "feat(book): expose configured detail entries"
```

### Task 6: 回归验证、审查和交付

**Files:**
- Review: 本计划涉及的全部源文件与测试文件。

- [ ] **Step 1: 运行全部 Node 测试**

Run: `node --test tests/*.test.js`

Expected: 所有测试 PASS，0 failures。

- [ ] **Step 2: 运行生产构建**

Run: `./node_modules/.bin/vue-cli-service build`

Expected: 退出码为 0；允许保留项目已有的 bundle-size warning，不允许新增编译错误。

- [ ] **Step 3: 检查改动完整性和工作区边界**

Run: `git diff --check && git status --short && git log --oneline -6`

Expected: `git diff --check` 无输出；`package.json`、`.opencode/`、`coverage/` 等原有用户改动未被纳入功能提交；最近提交只包含本计划列出的文件。

- [ ] **Step 4: 按需求矩阵人工验收**

在开发环境验证：

1. 金额限制开启时两个子开关关闭并隐藏，保存请求两个字段均为 `2`。
2. 金额限制关闭时两个子开关能独立保存为 `1/2`。
3. 普通空台、锁定、预订/预留卡台无明细入口。
4. 带翻台空台以及状态 4、5、6、7 的卡台按配置显示入口。
5. 多翻台标签按新到旧显示，默认最新；切换回来不重复请求。
6. 消费明细含套餐、退单、优惠状态但没有操作按钮。
7. 存取酒明细来自 `wine_ops`，无数据和接口失败时弹窗稳定。

- [ ] **Step 5: 使用代码审查技能检查需求遗漏与回归风险**

审查重点：配置失败是否默认关闭、状态 1 的例外是否只允许 `turnoverCnt > 0`、状态 3/8 是否始终隐藏、ID 26/27 是否不会落入原抽屉、异步旧响应是否被丢弃、点单页改用共享转换后数据结构是否保持兼容。

- [ ] **Step 6: 修复审查发现并重新执行 Steps 1-3**

只有全部测试和构建再次通过，才报告功能完成。
