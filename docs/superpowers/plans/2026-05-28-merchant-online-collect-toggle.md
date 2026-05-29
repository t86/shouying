# Merchant Online Collect Toggle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Add a merchant-level online collection enable/disable control to cashier merchant management, with correct single-list behavior in multi-entity mode.

**Architecture:** Extend the merchant management drawer to render a dedicated online-collection section backed by `org/get_cnl_cfg_grp` response data and a new `org/save_cnl_cfg_openclose` write API. Keep this state isolated from existing default-merchant, threshold, hour-limit, and seat-binding configuration so closing a merchant only affects actual online collection availability.

**Tech Stack:** Vue 2, Element UI, existing `api/money` axios wrappers, LESS in single-file Vue component styles.

---

### Task 1: Add API bindings and response parsing

**Files:**
- Modify: `src/api/money/index.js`
- Modify: `src/components/money/drawerMerchant.vue`

- [x] **Step 1: Add the new open/close save API wrapper**

Add this method near the existing `get_cnl_cfg_grp` wrapper in `src/api/money/index.js`:

```js
  // 保存商户号线上收款开关
  save_cnl_cfg_openclose: (params) =>
    axios.post(`${base.htgl}/org/save_cnl_cfg_openclose`, params),
```

- [x] **Step 2: Add local state for merchant online collect status**

In `src/components/money/drawerMerchant.vue` `data()`, add:

```js
      onlineCollectMerchants: [],
      closedMerchantIds: [],
```

- [x] **Step 3: Normalize merchant online collect data from group response**

Inside `getMerchantGroup()`, after `this.groupData = res.data`, parse the new close-list field into local state and build line items from `cnl_cfg_def`:

```js
        const closedIds = res.data.closed_cnl_cfg_ids || res.data.close_cnl_cfg_ids || [];
        this.closedMerchantIds = closedIds.map(id => id * 1);
        this.onlineCollectMerchants = (res.data.cnl_cfg_def || []).map(item => ({
          ...item,
          onlineCollectEnabled: !this.closedMerchantIds.includes(item.id * 1),
          savingOpenClose: false,
        }));
```

- [x] **Step 4: Run a focused build to verify the parsing code compiles**

Run:

```bash
NODE_OPTIONS=--openssl-legacy-provider npx vue-cli-service build --mode development --dest /tmp/shouyin-build-check-merchant-plan-task1
```

Expected: build succeeds; existing repo warnings may remain.

- [x] **Step 5: Commit the API/parsing slice**

```bash
git add src/api/money/index.js src/components/money/drawerMerchant.vue
git commit -m "feat(money): add merchant online collect api bindings"
```

### Task 2: Render the online-collection control section

**Files:**
- Modify: `src/components/money/drawerMerchant.vue`

- [x] **Step 1: Add a dedicated section before the existing merchant configuration blocks**

Insert a new section near the top of the drawer body template so it is visible in both single-entity and multi-entity scenarios:

```html
      <div class="merchant fs14 merchant-online-collect-section">
        <div class="coll merchant-online-header" layout="row" layout-align="space-between center">
          <div class="value merchant-online-title">
            <span>线上收款功能</span>
          </div>
        </div>
        <div class="red-color fs12 m-l-10 p-l-10 m-t-2">关闭开关则该商户号不能进行线上收款</div>
        <div class="merchant-online-list" v-if="onlineCollectMerchants.length > 0">
          <div
            class="merchant-online-item"
            v-for="item in onlineCollectMerchants"
            :key="item.id"
          >
            <div class="merchant-online-item-text">
              {{ formatOnlineMerchantText(item) }}
            </div>
            <el-switch
              :value="item.onlineCollectEnabled"
              :loading="item.savingOpenClose"
              active-text="开"
              inactive-text="关"
              active-color="#67c23a"
              inactive-color="#dcdfe6"
              @change="handleOnlineCollectToggle(item, $event)"
            />
          </div>
        </div>
      </div>
```

- [x] **Step 2: Add a formatter method for merchant display text**

In `methods`, add:

```js
    formatOnlineMerchantText(item) {
      const merchantNo = item.n || '';
      const holderName = item.un || item.u || item.hn || '';
      const bankNo = item.bn || item.no || item.acct_no || '';
      return [merchantNo, holderName, bankNo].filter(Boolean).join(' -- ');
    },
```

- [x] **Step 3: Add styles for the new section**

Append scoped styles in `src/components/money/drawerMerchant.vue`:

```less
.merchant-online-collect-section {
  padding-bottom: 10px;

  .merchant-online-list {
    margin-top: 12px;
  }

  .merchant-online-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    padding: 14px 10px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.12);
  }

  .merchant-online-item-text {
    flex: 1;
    line-height: 22px;
    word-break: break-all;
  }
}
```

- [x] **Step 4: Run the build to verify template/style changes**

Run:

```bash
NODE_OPTIONS=--openssl-legacy-provider npx vue-cli-service build --mode development --dest /tmp/shouyin-build-check-merchant-plan-task2
```

Expected: build succeeds; existing repo warnings may remain.

- [x] **Step 5: Commit the UI slice**

```bash
git add src/components/money/drawerMerchant.vue
git commit -m "feat(money): render merchant online collect toggles"
```

### Task 3: Save toggle state with rollback on failure

**Files:**
- Modify: `src/components/money/drawerMerchant.vue`

- [x] **Step 1: Add the toggle handler**

In `methods`, add:

```js
    async handleOnlineCollectToggle(item, enabled) {
      const previous = item.onlineCollectEnabled;
      item.onlineCollectEnabled = enabled;
      item.savingOpenClose = true;

      try {
        const res = await api_money.save_cnl_cfg_openclose({
          cnl_cfg_id: item.id * 1,
          status: enabled ? 1 : 2,
        });

        if (res.code !== 1) {
          item.onlineCollectEnabled = previous;
          this.$message.warning(res.msg || '保存失败');
          return;
        }

        if (enabled) {
          this.closedMerchantIds = this.closedMerchantIds.filter(id => id !== item.id * 1);
        } else if (!this.closedMerchantIds.includes(item.id * 1)) {
          this.closedMerchantIds.push(item.id * 1);
        }

        this.$message.success('设置成功');
      } catch (error) {
        item.onlineCollectEnabled = previous;
        this.$message.warning('保存失败，请稍后重试');
        console.log('保存商户号线上收款开关失败', error);
      } finally {
        item.savingOpenClose = false;
      }
    },
```

- [x] **Step 2: Verify the new section does not affect legacy save flows**

Review these existing methods and ensure no extra validation or branching is added:

```js
saveMerchantConfig()
saveGlobalConfig()
onSubmit()
```

Expected: they remain behaviorally unchanged.

- [x] **Step 3: Run the build for final verification**

Run:

```bash
NODE_OPTIONS=--openssl-legacy-provider npx vue-cli-service build --mode development --dest /tmp/shouyin-build-check-merchant-plan-final
```

Expected: build succeeds; existing repo warnings may remain.

- [x] **Step 4: Commit the save-flow slice**

```bash
git add src/components/money/drawerMerchant.vue
git commit -m "feat(money): save merchant online collect status"
```

### Task 4: Manual behavior review

**Files:**
- Review: `src/components/money/drawerMerchant.vue`
- Review: `src/api/money/index.js`

- [x] **Step 1: Check single-entity behavior**

Confirm the drawer shows:

- one online-collection section
- all merchants listed once
- existing merchant config blocks still visible below

- [x] **Step 2: Check multi-entity behavior**

Confirm the drawer shows:

- the online-collection section as a single unified list
- `全局配置 / 主体A / 主体B` tabs still work
- toggles are not duplicated per entity tab

- [x] **Step 3: Check failure behavior in code**

Verify `handleOnlineCollectToggle()` restores the prior state when:

- API returns `code !== 1`
- request throws

- [x] **Step 4: Final commit if review caused edits**

```bash
git add src/components/money/drawerMerchant.vue src/api/money/index.js
git commit -m "chore(money): polish merchant online collect toggles"
```
