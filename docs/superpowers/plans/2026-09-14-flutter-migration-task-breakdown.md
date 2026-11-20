# Flutter 全量移植任务拆分（系统 → 页面 → 叶任务）

> **进度看板服务：** `http://127.0.0.1:8791/`（`node docs/flutter-migration/board/server.js`）。页面改状态会立刻写入 [`BOARD.md`](../../flutter-migration/BOARD.md) 和 `board/tasks.json`。代理人用 `node docs/flutter-migration/board/sync-board.js --set ID=状态`。
>
> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> 本文是**主台账 / WBS**，不是单页 2–5 分钟 TDD 详案。执行某一个叶任务时：先按下方「叶任务标准做法」写失败测试，再改代码。每个系统开工前可再拆一份该系统的 TDD 详案。

**Goal:** 把 Vue 收银客户端按「系统 → 页面 → 可执行叶任务」拆完，每个最底层任务都能对照 Vue 源码、现有接口和 Flutter 落点独立完成，且业务/权限/API 1:1。

**Architecture:** 三个薄壳（`windows_app` / `web_app` / `android_app`）共享 `protocol` + `session` + `permissions` + `realtime_sync`。前台三系统当前实现集中在 `packages/card_table`；新域按同一模式新增 `*Api` / `*Loader` / `*Screen`，必要时再抽到 `packages/features/{booking,order,cashier,member,wine,queue,bms,erp}`。不改后端、不做离线、不把 WebView 当正式实现。

**Tech Stack:** Flutter 3.47.0（FVM）、Dart Pub workspace、Riverpod、go_router、Dio、web_socket_channel、flutter_test。对照系统是现有 Vue 2 + Element UI。测试命令一律加 `--no-pub`。

---

## 0. 怎么用这份台账

### 0.1 状态（只允许这些词）

| 标记 | 含义 |
| --- | --- |
| `未开始` | 无可用 Flutter 实现 |
| `已编码·未确认` | 包内有实现+测试，用户未点「已确认」 |
| `Web已接线·Android待接线` | Web `ShellDependencies` 已接，Android 根未接同一回调 |
| `入口已列·待接入` | 菜单/按钮已出现，点下去仍是 `_pendingFeature` |
| `已确认` | **仅用户**可改此状态。代理人不得代标 |
| `不移植` | 重构前遗留路由或已注释菜单，禁止当新功能做 |

当前**仅**点单「鸡尾酒明细表」「估清商品」为用户已确认（LOCAL-004 / LOCAL-005）。LOCAL-006/007/008/009 与预定弹窗**保持未确认**。

### 0.2 平台

- **Windows / Flutter Web：** 每个叶任务默认必做。
- **Android：** 只做迁移台账批准项；未批准的标「Android 不在范围」，不能标遗漏。
- 完成标准默认：Win+Web 行为与 Vue 一致；Android 另列接线任务。

### 0.3 叶任务标准做法（每个 `- [ ]` 都走一遍）

1. 打开「Vue 对照」文件，抄按钮文案、可见性、请求 path、body 字段、成功/失败文案。
2. 先写失败测试（API 契约或 widget），跑红：
   ```bash
   cd flutter_workspace
   .fvm/flutter_sdk/bin/flutter test --no-pub packages/<pkg>/test/<file>.dart
   ```
3. 最小实现：`Protocol*Api` 只走 `ProtocolClient.post`；UI 不解析原始字段；断网/`blocked` 禁止写。
4. 接线：`ShellDependencies` + `android_app/lib/main.dart` + `web_app/lib/main.dart` +（前台页）`windows_app/lib/main.dart`。
5. 回归：
   ```bash
   .fvm/flutter_sdk/bin/flutter test --no-pub packages/card_table
   .fvm/flutter_sdk/bin/flutter analyze --no-pub
   node tool/verify_boundaries.js
   ```
6. **不要**把任务标成用户已确认。

### 0.4 Flutter 落点约定

| 层 | 路径 |
| --- | --- |
| 协议 | `flutter_workspace/packages/protocol/` |
| 会话/登录 | `flutter_workspace/packages/session/` |
| 权限 | `flutter_workspace/packages/permissions/` |
| 实时同步 | `flutter_workspace/packages/realtime_sync/` |
| 前台卡台/点单/收银入口 | `flutter_workspace/packages/card_table/lib/src/` |
| 设备 | `packages/device_bridge_*` |
| 壳 | `apps/{android_app,web_app,windows_app}/lib/main.dart` |

新建报表/抽屉：`card_table/lib/src/<name>.dart` + `<name>_loader.dart` + `<name>_screen.dart` + `test/<name>_test.dart`。新业务域开工时再拆独立 package，不要把规则写进 widget。

### 0.5 对照范围

- **真值：** `src/router/*.js` 里**重构注释之前**的活路由 + 页面里未注释的菜单。
- **不要移植：** BMS/ERP「以下为重构之前代码」之后的旧路由；`orderCard.vue` / `oldShoppingCart` / `oldMyOrder`；VIP `navList.js` 里已注释项。
- **业务约束：** 不改后端；无离线写；权限以后端为准；UI 可以丑，功能必须 1:1。

### 0.6 建议开工顺序

1. M0 Windows 卡台壳接线（否则桌面无法跑前台）
2. S1 预定弹窗剩余项 → 报表 Android 接线 → 用户确认
3. S2 点单页（购物车/下单/退单/套餐/优惠）
4. S3 结账页（支付闭环）再做收银 37 张表
5. S4 会员、S5 存酒、S6 叫号大屏
6. S7 BMS、S8 ERP（Win/Web 全量）

---

## M0 横切底座（登录 / 同步 / 设备 / 三端壳）

### M0.P1 终端授权与员工登录

路由：`/` `src/views/home.vue`；`/Thelogin` `src/views/Thelogin/Thelogin.vue`。API：`src/api/UtilAuth/term/index.js`、`src/api/UtilAuth/auth/index.js`。

- [ ] **M0.P1.T01 终端授权码换会话** `已编码·未确认`
  - Vue: `src/views/Thelogin/Thelogin.vue`；API `POST /term/auth`（见 `UtilAuth/term`）
  - Flutter: `packages/session/` + 三端 `main.dart` 授权码输入
  - 完成: 错误码/文案与 Vue 一致；失败不写入凭据
- [ ] **M0.P1.T02 工号密码登录** `已编码·未确认`
  - Vue: `Thelogin.vue`；API `POST /auth/login`
  - Flutter: `SessionRepository` / `SessionApi`
  - 完成: `tk`/`stk`/`tt` 写入安全存储；角色进入系统选择
- [ ] **M0.P1.T03 退出登录清会话** `已编码·未确认`
  - Vue: 各卡台页「退出登录」
  - Flutter: `card_table_screen.dart` 账户菜单 + `SessionRepository`
  - 完成: 清凭据、停 WebSocket、回到登录
- [ ] **M0.P1.T04 修改登录密码** `入口已列·待接入`（回调空时 `_pendingFeature`）
  - Vue: 账户菜单「修改密码」；API `POST /emp/chg_pwd`（`src/api/BMS/emp/index.js`）
  - Flutter: `account_password_screen.dart` / `account_passwords.dart`；三端 `changePassword`
  - 完成: 旧密+新密校验、成功文案、失败关闭；Win/Web/Android 均接线
- [ ] **M0.P1.T05 授权密码开关** `入口已列·待接入`（点单/收银）
  - Vue: 点单/收银账户菜单「授权密码」
  - Flutter: `account_passwords.dart`；`authPasswordEnabled` / `changeAuthPassword`
  - 完成: 预定系统不出现该项；点单/收银与 Vue 一致

### M0.P2 实时同步与权限

- [ ] **M0.P2.T01 WebSocket `/sync` 连接/心跳/重连** `已编码·未确认`
  - Vue: `src/websocket/websocket.js`；API `POST /sync_base/all`、`/sync_base/increment`
  - Flutter: `packages/realtime_sync/` + `card_table_event_feed.dart`
  - 完成: `blocked`/`reconciling`/`online` 三态；写操作在非 `online` 失败关闭
- [ ] **M0.P2.T02 岗位模块权限 13/41 与安全模式 54** `已编码·未确认`
  - Vue: Vuex `userInfo` / `cardPageInfo.resResultDataObj`
  - Flutter: `packages/permissions/` + `legacy_card_table_store.dart`
  - 完成: 缺失/损坏元数据不默认放行；安全模式隐藏点单/收银「更多」，不隐藏预定更多、充值、存酒入口
- [ ] **M0.P2.T03 营业日开启/关闭状态** `已编码·未确认`
  - Vue: `POST /wkd/get`、`/wkd/start`；`src/api/Book/index.js`
  - Flutter: `business_day_api.dart`；预定可开营业日，点单/收银仅提示联系咨客
  - 完成: 未开业空台菜单与 Vue `getCardOptions` 一致

### M0.P3 设备

- [ ] **M0.P3.T01 HID 扫码（Win/Android）** `已编码·未确认`（诊断级）
  - Vue: `src/mixin/swipingCard.js`
  - Flutter: `device_bridge_platform_interface` + windows/android 实现
  - 完成: 回车结束、防抖；业务页真正吃码在各支付/会员叶任务中验收
- [ ] **M0.P3.T02 测试小票打印** `已编码·未确认`（诊断级）
  - Vue: 各 `prt_*` 接口
  - Flutter: `device_bridge_*` PrinterService
  - 完成: Win 队列/ESC-POS；Web 浏览器打印降级；打印失败不回滚已成功支付
- [ ] **M0.P3.T03 相机扫码（仅 Android 无外设兜底）** `已编码·未确认`
  - Flutter: `device_bridge_android`；Web 不承诺静默 USB

### M0.P4 三端壳

- [ ] **M0.P4.T01 Windows 壳接入 `CardTableScreen`** `未开始`（当前 `windows_app` 未 import `card_table`）
  - Flutter: 参照 `web_app/lib/main.dart` 的 `ShellDependencies`，接到 `apps/windows_app/lib/main.dart`
  - 完成: Windows 能登录并进入预定/点单/收银卡台页，与 Web 同一套回调
- [ ] **M0.P4.T02 Web 开发代理 `--no-pub`** `已编码·未确认`
  - Flutter: `flutter_workspace/tool/web_dev_runner.js` → `http://127.0.0.1:8183/`
- [ ] **M0.P4.T03 Android 业务回调与 Web 对齐** `未开始`（报表/排队等 Android 缺）
  - 对照: `web_app/lib/main.dart` `ShellDependencies` vs `android_app/lib/main.dart`
  - 完成: Web 已有的 loader，Android 同等声明并传入 `CardTableScreen`（Android 台账未批准的功能除外）

---

## S1 预定系统 Book

路由：`src/router/book/index.js`。菜单真值：`src/utils/config/card.js` `cardOptions` + `cardMachine.vue` `getCardOptions`。写接口：`src/api/Book/index.js`。Flutter 写枚举：`booking_card_api.dart` `BookingCardWriteAction`。

### S1.P1 `/cardMachine` 卡台信息

Vue: `src/views/Book/cardMachine.vue`。Flutter: `card_table_screen.dart` + `legacy_card_table_store.dart`（`BusinessSystem.booking`）。

#### 页面骨架

- [ ] **S1.P1.T01 日期栏 / 区域 / 搜索 / 图例** `已编码·未确认`
  - Vue: `cardMachine.vue` `canDoList` 日期、区域、搜索（卡台/客人/手机/订位人）
  - Flutter: `card_table_screen.dart`、`card_region_selector.dart`
  - 完成: 默认「全部」；搜索字段与 Vue 一致；营业日未开仍可看台
- [ ] **S1.P1.T02 卡台点击菜单定位在卡片旁** `已编码·未确认`
  - Vue: 菜单宽 172px、色 `#08080A` / `#32b9ff`，相对卡片偏移
  - Flutter: `showGeneralDialog` + `_CardMenuLayoutDelegate`（禁止再改回 BottomSheet）
  - 完成: widget 测试点 `CardTableScreen.cardMenuKey`
- [ ] **S1.P1.T03 菜单可见性 1:1 `getCardOptions`** `已编码·未确认`
  - Vue: `cardMachine.vue` 约 1206 行；选项 id 见 `src/utils/config/card.js`
  - Flutter: `card_table_screen.dart` 组菜单逻辑
  - 完成: 状态 1/2/4/5/6/7/8 × 线上/线下 × 置顶 × 清台权限 × 取消必点灰显 与 Vue 相同；线上预留不出现「取消预留」

#### 卡台弹窗写操作（选项 id）

- [ ] **S1.P1.T04 预留（空台 id=1）表单** `已编码·未确认`
  - Vue: `src/components/book/reserved/drawerReserved.vue`；`POST /bk/batch_new`（不是 `/bk/new`）
  - Flutter: `_CardForm.reserve`；`BookingCardWriteAction.createReserve`
  - 完成: 手机号非空必须 11 位「请输入正确的手机号」；`book_day` yyyy-mm-dd；`is_this_wkday` 首日=1 否则=2；成功「新增成功」
- [ ] **S1.P1.T05 开台（空台 id=2）表单** `已编码·未确认`
  - Vue: 开台表单；空台 `POST /bk/direct_open` `{seat_id,...}`
  - Flutter: `_CardForm.open`；`openEmpty`
  - 完成: 人数 &lt;1 拦截；成功「开台成功！」
- [ ] **S1.P1.T06 预定开台（预留台 id=2）** `已编码·未确认`
  - Vue: `POST /bk/open` `{id: bookId,...}`；线上订台确认文案「线上订台{name}，开台后不能撤台，是否确认开台？」
  - Flutter: `openReserve`
  - 完成: 确认框文案与 body 字段 1:1
- [ ] **S1.P1.T07 修改预留（id=8）** `已编码·未确认`
  - Vue: `POST /bk/get` 拉详情，`POST /bk/save` 保存
  - Flutter: `getBookDetail` / `BookingBookDetail.fromWire`；`updateReserve`
  - 完成: 成功「修改成功」；`second_sales_name` 发字符串（Vue 有 `Number(...)` 的 bug，不要复刻）
- [ ] **S1.P1.T08 锁定 / 取消锁定（id=5/6）** `已编码·未确认`
  - API: `POST /bk/lock`、`/bk/unlock`
  - Flutter: `lock` / `unlock`
  - 完成: 确认文案与 Vue `showConfirmHandle` 一致
- [ ] **S1.P1.T09 撤台（id=12）** `已编码·未确认`
  - API: `POST /bk/cancel_open`
  - Flutter: `cancelOpen`
- [ ] **S1.P1.T10 取消预留（id=15，仅线下）** `已编码·未确认`
  - API: `POST /bk/cancel`
  - Flutter: `cancelReserve`
- [ ] **S1.P1.T11 置顶 / 取消置顶（id=18/19）** `已编码·未确认`
  - API: `POST /bk/top_seat_dsp`、`/bk/cancel_top_seat_dsp`
  - Flutter: `pin` / `unpin`
- [ ] **S1.P1.T12 取消必点（id=24）** `已编码·未确认`
  - API: `POST /bk/disable_csm_must_ord`
  - Flutter: `disableMustOrder`；无必点商品或 business[37] 时灰显
- [ ] **S1.P1.T13 修改低消（id=10）** `已编码·未确认`
  - API: `POST /bk/chg_csm_mca`
  - Flutter: `updateMinConsume`
- [ ] **S1.P1.T14 修改订位人（id=11）** `已编码·未确认`
  - API: `POST /bk/chg_sales`
  - Flutter: `updateSales`
- [ ] **S1.P1.T15 修改卡台标记（id=20）** `已编码·未确认`
  - API: `POST /bk/set_seat_mark`；标记列表 dataset 31
  - Flutter: `updateMark`
- [ ] **S1.P1.T16 修改备注（id=21）** `已编码·未确认`
  - API: `POST /bk/chg_open_seat_remark`
  - Flutter: `updateRemark`
- [ ] **S1.P1.T17 修改服务员（id=23）** `已编码·未确认`
  - API: `POST /sel/chg_csm_waiter`
  - Flutter: `updateWaiter`
- [ ] **S1.P1.T18 查看卡台详情（id=14）只读** `已编码·未确认`
  - Vue: 详情弹层；Flutter: 只读 dialog，无写
- [ ] **S1.P1.T19 清台（id=16）** `已编码·未确认`
  - Vue: 已结 + `showAmt` id=5 `param1==2`；`POST /sel/seat_clean`
  - Flutter: `clearSeat`；`canClearSeat`
- [ ] **S1.P1.T20 转为线下卡台（id=17）** `已编码·未确认`
  - Vue: 空台且 `showOnlineText`；`POST /bk/conv_ol_seat_local`
  - Flutter: `convertOffline`
- [ ] **S1.P1.T21 转台（id=7）开台/预留** `已编码·未确认`
  - API: `POST /bk/chg_csm_seat`（开台）、`POST /bk/chg_seat`（预留）
  - Flutter: `_CardForm.transfer`；`transferOpen` / `transferReserve`
- [ ] **S1.P1.T22 修改翻台订位人（id=4）历史表** `入口已列·待接入`
  - Vue: `turnoverCnt==0` 先警告「当前卡台没有翻过台！」；有翻台则 `POST /bk/get_his_sales` 列表、`POST /bk/chg_his_sales` 保存
  - Flutter: 零翻台警告已做；缺历史表 UI
  - 完成: 表格列/保存字段与 Vue 一致
- [ ] **S1.P1.T23 复台（id=25）** `入口已列·待接入`
  - Vue: `POST /sel/get_seat_turnback_list`、`POST /sel/seat_turn_back`；组件 `src/components/money/drawerChooseTurnback.vue`
  - Flutter: 菜单项已画，写入未接
  - 完成: 仅空台+有可复流水；成功后刷新卡台
- [ ] **S1.P1.T24 查看消费明细（id=26）** `入口已列·待接入`
  - Vue: `src/components/book/machine/bookingDetailDialog.vue` mode=`consumption`
  - 完成: 只读列与 Vue 一致，不在此页做退款
- [ ] **S1.P1.T25 查看存取酒明细（id=27）** `入口已列·待接入`
  - Vue: 同上 mode=`wine`
- [ ] **S1.P1.T26 多台预留加台（id=22）** `未开始`
  - Vue: `drawerReserved.vue` + `src/components/book/reserved/chooseCard.vue`
  - API: 仍走 `POST /bk/batch_new`（多 `seat_id`）
  - 完成: 可勾选多个空台一次提交
- [ ] **S1.P1.T27 修改开台类型（id=13）** `未开始`（当前 `getCardOptions` 未挂 13，以 Vue 现网菜单为准；若现网没有则本任务标不移植）
  - API: `POST /bk/chg_open_type`

#### 底部「更多功能」7 张表

菜单源：`cardMachine.vue` + `card_page_menus.dart` `_booking`。实现：`booking_reports.dart` / `booking_reports_loader.dart` / `booking_report_screens.dart`、`booking_queue*.dart`。

- [ ] **S1.P1.R01 开台记录** `Web已接线·Android待接线`
  - Vue: `src/components/book/machine/drawerOpenCard.vue`
  - API: `POST /sel/rpt/get_seat_open_log`；导出 `POST /sel/rpt/exp_seat_open_log`；筛选项 `POST /bk/get_seat_open_log_params`
  - Flutter: `SeatOpenLogRow`；Web `loadSeatOpenLog`
  - 完成: 列顺序/筛选/导出与 Vue 一致；Android 同样接线（若台账批准）
- [ ] **S1.P1.R02 转台记录** `Web已接线·Android待接线`
  - Vue: `src/components/book/machine/fullPageZTOrder.vue` / `cardDrawerZTOrder.vue`
  - API: `POST /bk/get_chg_seat_log`
- [ ] **S1.P1.R03 预留记录** `Web已接线·Android待接线`
  - Vue: `src/components/book/machine/drawerReservedRecord.vue`
  - API: `POST /sel/rpt/get_book_list`；导出 `/sel/rpt/exp_book_list`
- [ ] **S1.P1.R04 线上预订记录** `Web已接线·Android待接线`
  - API: `POST /sel/rpt/get_ol_book_list`（收银侧同接口，预定入口单独接）
- [ ] **S1.P1.R05 入客数据实时汇总** `Web已接线·Android待接线`
  - Vue: `src/components/book/machine/drawerSeatOpening.vue`
  - API: `POST /sel/rpt/get_seat_opening_list`；导出 `/sel/rpt/exp_seat_opening_list`
- [ ] **S1.P1.R06 部门实时订台/区域开台** `Web已接线·Android待接线`
  - Vue: `src/components/book/machine/drawerDeptRegionSeatOpen.vue`
  - API: `POST /sel/rpt/get_dept_region_seat_open_list`；导出 `/sel/rpt/exp_dept_region_seat_open_list`
  - 规格: `docs/superpowers/specs/2026-08-10-dept-region-seat-open-report-design.md`
- [ ] **S1.P1.R07 排队详情（叫号/到店/过号）** `Web已接线·Android待接线`
  - Vue: `src/components/book/machine/drawerQueue.vue`
  - API: `POST /custq/call`、`/custq/arrive`、`/custq/expired`；导出 `/custq/exp_cust_queue_list`
  - Flutter: `booking_queue.dart` / `booking_queue_screen.dart`；Web `queueCall`/`queueArrive`/`queueExpired`

### S1.P2 `/reserved` 预留信息

Vue: `src/views/Book/reserved.vue` + `src/components/book/reserved/tabContent.vue`。Flutter: **尚未做独立路由页**（不要用卡台页冒充）。

- [ ] **S1.P2.T01 当日预留 / 其它预留两个 Tab 列表** `未开始`
  - Vue: `reserved.vue` tabs；`tabContent.vue`
  - API: 预留列表走 Book 预留查询（以 `tabContent.vue` 内实际 POST 为准，执行时抄 path/body）
  - Flutter: 新建 `booking_reserved_screen.dart` + loader；三端路由挂 `/reserved`
  - 完成: 两 Tab 数据源、行字段、点行进修改预留与 Vue 一致
- [ ] **S1.P2.T02 从预留页回预订管理** `未开始`
  - Vue: 「预订管理」→ `/cardMachine`
- [ ] **S1.P2.T03 预留页修改密码/退出** `未开始`
  - 复用 M0.P1.T03/T04，不要复制一套会话逻辑

---

## S2 点单系统 Order

路由：`src/router/order/index.js`。卡台真值：`src/views/Order/newOrderCard.vue`（**不要** `orderCard.vue`）。点单页：`src/views/Order/orderMeal/*` 的 **new** 组件。API：`src/api/order/index.js`、存酒 `src/api/saveWine/index.js`。

### S2.P1 `/orderCard` 点单卡台首页

Flutter: `card_table_screen.dart`（`BusinessSystem.order`）+ `order_card_display.dart`。

- [ ] **S2.P1.T01 浅色主题、默认「我的卡台」、无日期栏、无搜索** `已编码·未确认`
  - Vue: `newOrderCard.vue` + `style/order/newOrderCard.less`
  - 完成: 「我的卡台」= dataset14[14] 订位人或 14[20] 历史服务员精确匹配登录员工
- [ ] **S2.P1.T02 区域选择（含「其它」溢出）** `已编码·未确认`
  - Flutter: `card_region_selector.dart`
- [ ] **S2.P1.T03 空台/锁台/预留不可点单提示** `已编码·未确认`
  - 完成: 正常模式点击开台进入点单；不要弹出存取酒菜单
- [ ] **S2.P1.T04 存酒模式入口（模块 1）** `入口已列·待接入`
  - Vue: 存酒模式才展示存/取/充公；`src/components/order/newSaveWine/**`
  - 完成: 非存酒模式绝不出现这三项
- [ ] **S2.P1.T05 会员充值入口（模块 91/92/93 任一）** `已编码·未确认`
  - Vue: `src/components/order/vipRecharge/drawerVipRecharge.vue`
  - Flutter: `vip_recharge.dart` / `vip_recharge_screen.dart` / loader
  - 完成: 搜卡、规则、下单、支付、轮询与 Vue 字段一致（充值闭环细节见 S2.P1.T06）
- [ ] **S2.P1.T06 会员充值支付与状态轮询** `已编码·未确认`
  - 对照 `vip_recharge.dart` 现有 `createVipOrder` / `createVipPay` / `pollVipOrderStatus`
  - 完成: 与 Vue 成功/失败弹窗一致；断网禁止下单
- [ ] **S2.P1.T07 底部更多：低消进度统计表** `已编码·未确认`（点单无导出）
  - Vue: `src/components/money/newDrawerMinDetail.vue`
  - API: `POST /wo/get_seat_zy_csm_list` 无 query/body
  - Flutter: `minimum_consumption_report*.dart`
  - 完成: 12 列与规格 `docs/superpowers/plans/2026-08-31-order-home-functional-parity.md` 一致；**不要**给点单加导出
- [ ] **S2.P1.T08 底部更多：鸡尾酒明细表** `已确认`
  - Vue: 点单侧鸡尾酒明细（无收银导出按钮）
  - API: 以现网点单抽屉内 POST 为准（与收银 `/sel/rpt/get_hl_list` 区分是否带导出）
  - Flutter: `cocktail_detail_report*.dart`
- [ ] **S2.P1.T09 底部更多：估清商品（模块 5）** `已确认`
  - Vue: 估清列表；API `POST /sel/get_prd_sold_outs`、`/sel/set_prd_sold_out`、`/sel/del_prd_sold_out`、`/sel/add_prd_sold_out`
  - Flutter: `sold_out_products*.dart`
- [ ] **S2.P1.T10 个人开台/抵达计数 dataset 39 的 30/31** `已编码·未确认`
  - 完成: 按卡台累计，不用全场、不数状态 4 冒充

### S2.P2 `/orderMeal/orderMealList` 点单

Vue: `src/views/Order/orderMeal/orderMealList.vue` + `src/components/order/productList.vue` + `orderMealNav.vue` + `src/components/order/newDrawerMeal/**`。Flutter: `order_meal.dart` / `order_meal_screen.dart` / `order_meal_loader.dart`（目前仅单品加购/购物车数量/服务员/客人/已下单列表）。

- [ ] **S2.P2.T01 分类导航 + 商品列表（含估清灰显）** `未开始`（屏幕未按 Vue 分类树还原）
  - Vue: `orderMealNav.vue`、`productList.vue`、`newProductListGQ.vue`
  - 数据: 同步元数据商品树，不另造目录接口
  - Flutter: 扩展 `order_meal_screen.dart`
  - 完成: 一级/二级分类、搜索、估清不可点与 Vue 一致
- [ ] **S2.P2.T02 单品加入购物车** `已编码·未确认`
  - API: `POST /wsc/add_prd` `{seat_id,prd_id,prd_cnt,prd_price,auth_type,prd_amt,requirement}`
  - Flutter: `ProtocolOrderMealApi.addProduct`
- [ ] **S2.P2.T03 套餐加入购物车（选组）** `未开始`
  - Vue: `newDrawerMeal/groupProduct.vue`、`groupProduct2.vue`
  - API: `POST /wsc/add_set`
  - 完成: 必选组/可选组/数量规则与 Vue 一致
- [ ] **S2.P2.T04 时价特饮/小费/赔偿** `未开始`
  - Vue: `newDrawerMeal/singleProduct.vue` 时价分支
  - API: `POST /wsc/add_hl`
- [ ] **S2.P2.T05 优惠/赠送加入购物车** `未开始`
  - API: `POST /wsc/add_yh`；授权流程见购物车
- [ ] **S2.P2.T06 优惠2 加入购物车** `未开始`
  - API: `POST /wsc/add_yh2`；`src/components/order/newDrawerMeal/drawerYH2Submit.vue`
- [ ] **S2.P2.T07 单品/套餐要求** `未开始`
  - Vue: `drawerChooseRequireInfo.vue`
  - API: `POST /wsc/add_requirement`、`/wsc/add_set_requirement`
- [ ] **S2.P2.T08 更改套餐明细** `未开始`
  - API: `POST /wsc/chg_set_dtl`
- [ ] **S2.P2.T09 绑定当台服务员** `已编码·未确认`
  - API: `POST /wo/set_csm_waiter`
- [ ] **S2.P2.T10 绑定客人手机** `已编码·未确认`
  - API: `POST /wo/get_cust_items_for_csm`、`/wo/set_csm_cust`、轮询 `/wo/get_set_csm_cust_rst`

### S2.P3 `/orderMeal/shoppingCart` 购物车

Vue: `src/views/Order/orderMeal/newShoppingCart.vue` + `src/components/order/newShoppingCart/**`。不要移植 `oldShoppingCart`。

- [ ] **S2.P3.T01 购物车列表与改数量** `已编码·未确认`（API 有，完整 UI 未 1:1）
  - API: `POST /wsc/get_items`、`/wsc/set_cnt`（0=删除）、`/wsc/get_item_cnt`
  - Flutter: `listItems` / `setCount` / `cartCount`
  - 完成: 角标数量与列表一致；count=0 行消失
- [ ] **S2.P3.T02 购物车下单** `未开始`
  - API: `POST /wsc/order`
  - 完成: 成功清车并跳转我的点单；失败展示服务端 msg
- [ ] **S2.P3.T03 购物车转优惠（单项，含授权）** `未开始`
  - Vue: `newShoppingCart/authorization.vue`
  - API: `POST /wsc/to_yh`
- [ ] **S2.P3.T04 购物车批量转优惠2** `未开始`
  - API: `POST /wsc/to_yh2`
- [ ] **S2.P3.T05 并台（优惠2）** `未开始`
  - Vue: `newDrawerMeal/drawerBj/**`
  - API: `POST /sel/move_order`

### S2.P4 `/orderMeal/myOrder` 我的点单

Vue: `src/views/Order/orderMeal/newMyOrder.vue` + `src/components/order/myOrder/newDrawerMyOrder.vue`。

- [ ] **S2.P4.T01 已下单列表** `已编码·未确认`
  - API: `POST /wo/list`（Flutter `loadOrderItems` 需与 Vue 字段对齐）
- [ ] **S2.P4.T02 未结账退单** `未开始`
  - API: `POST /wo/back`；线上未付 `POST /wo/ol_unpay_back`
  - 完成: 已付款不可退（与 Vue 一致）；数量键盘见 `docs/superpowers/specs/2026-08-13-order-refund-quantity-keyboard-design.md`
- [ ] **S2.P4.T03 下单后赠送** `未开始`
  - API: `POST /wo/yh_prd`；`drawerGiveHeMoreForOrder.vue`
- [ ] **S2.P4.T04 下单后改套餐明细** `未开始`
  - API: `POST /wo/set_chg`
- [ ] **S2.P4.T05 已下单转优惠2** `未开始`
  - API: `POST /wo/yh2_prd`
- [ ] **S2.P4.T06 补打出品小票** `未开始`
  - API: `POST /wo/reprt_cp`
- [ ] **S2.P4.T07 手工打印/补打消费单** `未开始`
  - Vue: `newDrawerPrintOrder.vue`
  - API: `POST /wo/prt_csm_bill`、`POST /sel/sy_prt_csm_bill`
- [ ] **S2.P4.T08 服务员买单二维码** `未开始`
  - Vue: `newDrawerShowOrderList.vue`、`newDrawerPayQR.vue`、`choosePayTypeDialog.vue`
  - API: `POST /wo/get_waiter_olpay_todo_orders`、`/wo/do_waiter_olpay_with_orders`、`/wo/do_continue_waiter_olpay_with_orders`、`/wo/chk_waiter_olpay_with_orders`、`/wo/cancel_waiter_olpay`、`/wo/get_waiter_olpay_status`
- [ ] **S2.P4.T09 核销卡券（收银端点单页按钮）** `未开始`
  - Vue: `newFootBar.vue`「核销卡券」；`drawerRedeemCoupon.vue` / `drawerRedeemCoupon2.vue`
  - API: 以抽屉内 `$api.money` 调用为准（含 `/sel/rpt/get_kq_csm_list` 相关退核销）
- [ ] **S2.P4.T10 底栏更多：充值 / 滞留金 / 清台 / 转台** `未开始`
  - Vue: `newFootBar.vue` `moreClick` command d/a/b/c
  - 清台: `POST /sel/seat_clean`；转台复用 S1 转台 API；滞留金见 S3.P2；充值复用 S2.P1.T05

### S2.P5 `/orderMeal/choosedList` 已选列表

Vue: `src/views/Order/orderMeal/choosedList.vue`。

- [ ] **S2.P5.T01 已选只读汇总** `未开始`
  - 完成: 字段/合计与 Vue 一致；无额外写接口则不要发明写

### S2.P6 点单内存酒（模式切换后）

Vue: `src/components/order/newSaveWine/**`。API: `src/api/saveWine/index.js`。

- [ ] **S2.P6.T01 存酒两步单** `未开始`
  - API: `POST /wine/get_csms_f_cj`、`/wine/get_csm_cj_invt`、`/wine/get_sc_csm_cj`、`/wine/add_sc_csm_cj_prd`、`/wine/add_sc_csm_auth_cj_prd`、`/wine/mod_sc_csm_cj_prd`、`/wine/valid_phone_not_blacklist`、`/wine/new_cj_bef_in`
- [ ] **S2.P6.T02 取酒** `未开始`
  - API: `POST /wine/get_qj_invt`、`/wine/new_qj_bef_out`、`/wine/get_wine_cust_by_phone4`
- [ ] **S2.P6.T03 消费充公** `未开始`
  - API: `POST /wine/new_csm_cg_bef_in`

---

## S3 收银系统 Money

路由：`src/router/money/index.js`。卡台：`src/views/Money/moneyCard.vue`。结账：`src/views/Money/payOrder.vue`。API：`src/api/money/index.js`。更多菜单：`card_page_menus.dart` `_cashier`（37 项，已去掉注释项）。

### S3.P1 `/moneyCard` 收银卡台首页

- [ ] **S3.P1.T01 无日期栏、默认全部、搜索卡台/客人/手机尾四位** `已编码·未确认`
- [ ] **S3.P1.T02 点击开台进结账（消费明细与收款）** `入口已列·待接入`
  - Vue: 进 `/payOrder`
  - Flutter: 现 `_pendingFeature('消费明细与收款')` → 改为打开 S3.P2
- [ ] **S3.P1.T03 异议单列表角标与抽屉** `入口已列·待接入`
  - Vue: `src/components/money/drawerNeedBackOrderList/drawerNeedBackOrderList.vue`
  - API: `POST /yy/list`、`/yy/retry`、`/yy/process`
- [ ] **S3.P1.T04 会员系统入口** `入口已列·待接入`
  - Vue: 进 `/vipNav`；Flutter 现 `_pendingFeature('会员系统')` → 打开 S4
- [ ] **S3.P1.T05 安全模式隐藏「更多」** `已编码·未确认`

#### 更多功能 37 项（每张表：查询 + 导出/打印若 Vue 有）

| ID | 菜单 | Vue | 读 API | 导出/打印 API | 状态 |
| --- | --- | --- | --- | --- | --- |
| R01 | 班结表 | `drawerStopClass.vue` | `POST /wkd/get_bj` | `POST /wkd/prt_bj` | `入口已列·待接入` |
| R02 | 售出日报表 | `dayReport.vue` | `POST /sel/rpt/get_sold_out_rpt_items` + `/sel/rpt/get_sold_out_rpt` | `/sel/rpt/prt_sold_out_rpt` | 同上 |
| R03 | 商品出库表 | `drawerShangpinchuku.vue` | `POST /sel/rpt/get_rpt_prd_out_list` | `/sel/rpt/exp_rpt_prd_out_list` | 同上 |
| R04 | 查询优惠额度 | `drawerYHCount/index.vue` | `POST /sel/get_auth_emp_free_limit`（刷卡授权） | 无 | 同上 |
| R05 | 线上支付汇总 | `drawerOnlineTotal.vue` | `POST /sel/get_ol_pay_bill` | `/sel/prt_ol_pay_bill` | 同上 |
| R06 | 支付记录 | `drawerPayRecord.vue` | `POST /sel/get_pay_list` | 改客人 `/sel/get_cust_info_by_phonenum` `/sel/chg_pay_cust` | 同上 |
| R07 | 区域实时营收 | `drawerRegionRealtimeIncome.vue` | `POST /sel/rpt/get_region_real_amts` | `/sel/rpt/exp_region_real_amts` | 同上 |
| R08 | 业绩日报表 | `drawerKpiReport.vue` | `POST /sel/rpt/get_yj_rpt` | `/sel/rpt/exp_yj_rpt` | 同上 |
| R09 | 转台记录 | `drawerTurnOver.vue` | `POST /bk/get_chg_seat_log` | 以抽屉为准 | 同上 |
| R10 | 线上预订记录 | `drawerOnlineBooking.vue` | `POST /sel/rpt/get_ol_book_list` | `/sel/rpt/exp_ol_book_list` | 同上 |
| R11 | 优惠明细表 | `drawerYHDetail.vue` | `POST /sel/rpt/get_yh_list` | `/sel/rpt/exp_yh_list` | 同上 |
| R12 | 当日卡券核销记录表 | `drawerMtDyHx.vue` | `POST /sel/rpt/get_kq_csm_list` | `/sel/rpt/exp_kq_csm_list`；退核销 `/sel/cancel_kq_csm` | 同上 |
| R13 | 商品卡台销售表 | `drawerKTSalesDetail.vue` | `POST /sel/rpt/get_prd_set_sold_cnt` | `/sel/rpt/exp_prd_set_sold_cnt` | 同上 |
| R14 | 鸡尾酒明细表 | `drawerTYDetail.vue` / `newDrawerTYDetail.vue` | `POST /sel/rpt/get_hl_list` | `/sel/rpt/exp_hl_list` | 入口在；点单已确认版**无导出**，收银必须有导出 |
| R15 | 鸡尾酒汇总表 | `drawerTYHZ.vue` | `POST /sel/rpt/get_hl_rpt_sum_list` | `/sel/rpt/exp_hl_rpt_sum_list` | 同上 |
| R16 | 挂账账户 | `drawerGZDetail/**` | `POST /cnlacct/list` `/new` `/save` `/del` `/get_op_logs` `/return` `/get_orders` | — | 同上 |
| R17 | 翻台记录 | 翻台抽屉（`showOrHideTurnOverDetailHandle`） | `POST /sel/rpt/get_turnover_csm_list` | `/sel/rpt/exp_turnover_cms_list` | 同上 |
| R18 | 点单记录 | `drawerOrder.vue` | `POST /sel/rpt/get_order_prd_list` | `/sel/rpt/exp_order_prd_list` | 同上 |
| R19 | 历史点单记录 | `drawerHistoryOrder.vue` | `POST /sel/rpt/get_csm_his_wkday_items`、`/sel/rpt/get_csm_his` | 以抽屉为准 | 同上 |
| R20 | 非鸡尾酒类补交报表 | `drawerNotTYOrXF.vue` | `POST /sel/rpt/get_relate_prd_list` | `/sel/rpt/exp_relate_prd_list` | 同上 |
| R21 | 修改订位人记录 | `drawerUpdateBookEmp.vue` | `POST /sel/rpt/get_csm_sales_chg_list` | `/sel/rpt/exp_csm_sales_chg_list` | 同上 |
| R22 | 估清商品 | 与点单共用 | 同 S2.P1.T09 | — | 点单已确认；收银入口仍要接到同一套 Screen |
| R23 | 盘盈盘亏 | `drawerProfit/**` | `POST /sel/get_prd_profit_loss`、`/sel/do_prd_profit_loss` | — | `入口已列·待接入` |
| R24 | 商户号管理 | `drawerMerchant.vue` `drawerMerChantInfo.vue` | `POST /sel/get_cnl_cfg` `/sel/save_cnl_cfg` `/org/get_cnl_cfg_grp` `/org/save_cnl_cfg_grp` `/org/save_cnl_cfg_openclose` | 时段阀值 `/sel/get_cnl_hour_amt` 等 | 同上 |
| R25 | 低消进度统计表 | `drawerMinDetail.vue`（**有导出**） | `POST /wo/get_seat_zy_csm_list` | `/wo/exp_seat_zy_csm_list` | 点单版无导出；收银必须导出 |
| R26 | 现抽明细表 | `drawerXCDetail.vue` | `POST /sel/rpt/get_xian_chou_list` | `/sel/rpt/exp_xian_chou_list` | 同上 |
| R27 | 现抽汇总表 | `drawerXCAllInfo.vue` | `POST /sel/rpt/get_xian_chou_sum_list` | `/sel/rpt/exp_xian_chou_sum_list` | 同上 |
| R28 | 非主营分类渠道 | `drawerQDAllInfo.vue` | `POST /sel/rpt/get_not_zy_cate_cnls` | `/sel/rpt/exp_not_zy_cate_cnls` | 同上 |
| R29 | 分类渠道汇总表 | `drawerCatQDAllInfo.vue` | `POST /sel/rpt/get_jk_list` | `/sel/rpt/exp_jk_list` | 同上 |
| R30 | 部门销售明细表 | `drawerXSDetail.vue` | `POST /sel/rpt/get_waiter_sales_prd_amt_list` | `/sel/rpt/exp_waiter_sales_prd_amt_list` | 同上 |
| R31 | 部门销售汇总表 | `drawerXSAllInfo.vue` | `POST /sel/rpt/get_waiter_sales_prd_amt_sums` | `/sel/rpt/exp_waiter_sales_prd_amt_sums` | 同上 |
| R32 | 套餐统计表 | `drawerSetCount.vue` | `POST /sel/rpt/get_set_cnt_items` + `/sel/rpt/get_set_cnt_rpt` | `/sel/rpt/prt_set_cnt_rpt` | 同上 |
| R33 | 挂账还款记录表 | `drawerSetGZHK.vue` | `POST /sel/rpt/get_cnl_account_rtn_list` | 以抽屉为准 | 同上 |
| R34 | 预订金流水表 | `drawerSetYDJHistory.vue` | `POST /sel/rpt/get_cust_prepay_log` | 以抽屉为准 | 同上 |
| R35 | 预订金余额表 | `drawerSetYDJYE.vue` | `POST /sel/rpt/get_cust_prepay_bal` | 以抽屉为准 | 同上 |
| R36 | 结束营业日 | `drawerStopStore.vue` | `POST /wkd/close` | 班结打印 `/wkd/prt_bj` | 同上 |
| R37 | 自动结束营业日 | 同抽屉 auto | `POST /wkd/auto_close_cfg`、`/wkd/save_auto_close` | — | 同上 |

每个 Rxx 拆成三个可执行子步骤（执行时勾选）：

- [ ] **S3.P1.Rxx.a 读接口 DTO + 失败关闭测试**（path/body/列字段抄自对应 Vue）
- [ ] **S3.P1.Rxx.b Screen：查询/空/错/重试/关闭后回到卡台**
- [ ] **S3.P1.Rxx.c 导出或打印（仅当 Vue 有按钮）+ 三端接线；收银菜单去掉「待接入」**

### S3.P2 `/payOrder` 结账页

Vue: `src/views/Money/payOrder.vue` + `notPayOrder.vue` + `payedOrder.vue`。这是收银闭环，Win/Web 必做。

- [ ] **S3.P2.T01 翻台 Tab + 支付单 Tab +「全部消费」** `未开始`
  - API: `POST /sel/csm_orders`
  - Flutter: 新建 `pay_order_screen.dart`（不要塞进卡台页）
- [ ] **S3.P2.T02 未结订单表（改套餐明细、转单）** `未开始`
  - Vue: `notPayOrder.vue`
  - API: `POST /sel/chg_prd_set_dtl`、`/sel/move_wk_order`
- [ ] **S3.P2.T03 已结订单表（退单、改渠道）** `未开始`
  - Vue: `payedOrder.vue`
  - API: `POST /sel/pay_order_back`、`/sel/get_chg_pay_cnls`、`/sel/move_payed_wk_order`
- [ ] **S3.P2.T04 待结算购物车：加/删渠道** `未开始`
  - API: `POST /sel/cart_items`、`/sel/cart_add_cnl`、`/sel/cart_del_cnl`、`/sel/cart_begin_process`
- [ ] **S3.P2.T05 滞留金入购物车** `未开始`
  - Vue: `newDrawerAddBookAmt.vue` / `drawerMerchantConfig.vue`
  - API: `POST /sel/cart_add_late_cnl`、`/sel/get_seat_late_cnls`、`/sel/new_late_cnl`、`/sel/del_late_cnl`、`/sel/refund_late_cnl`、`/sel/chg_late_cnl_seat`
- [ ] **S3.P2.T06 抹零（授权渠道 pay_cnl_id=10）** `未开始`
  - API: `POST /sel/cart_add_auth_cnl`
- [ ] **S3.P2.T07 会员卡渠道** `未开始`
  - Vue: `drawerChooseVipCard.vue`
  - API: `POST /sel/get_phone_mb_cards`、`/sel/cart_add_mb_card_cnl`、`/sel/get_usable_mb_card_cnl`、`/sel/get_mb_card_f_csm`、`/sel/valid_cust_srv_code`
- [ ] **S3.P2.T08 预订金渠道** `未开始`
  - Vue: `drawerChooseYudingjin.vue`
  - API: `POST /sel/get_phone_prepays_f_csm`、`/sel/cart_add_prepay_cnl`、`/sel/get_seat_prepay_bal`
- [ ] **S3.P2.T09 结账提交** `未开始`
  - API: `POST /sel/pay_order`
  - 完成: 金额/渠道与购物车一致；失败关闭不猜测
- [ ] **S3.P2.T10 客人付款码支付** `未开始`
  - Vue: `customerPaymentScanDialog.vue`
  - API: `POST /sel/customer_payment_code_pay`、`/sel/valid_pay_code`
- [ ] **S3.P2.T11 打印结算单** `未开始`
  - API: `POST /sel/prt_sel_bill`；优惠2 `POST /wo/prt_csm_yh2_bill`
  - 完成: 打印失败不回滚支付
- [ ] **S3.P2.T12 清台** `未开始`（收银页按钮，权限同预定）
  - API: `POST /sel/seat_clean`
- [ ] **S3.P2.T13 切换先后买单** `未开始`
  - API: `POST /sel/chg_settle_mode`
- [ ] **S3.P2.T14 线上订单转线下 / 强制转滞留金** `未开始`
  - API: `POST /sel/conv_ol_order_local`、`/sel/conv_ol_pay_local_late`、`/sel/get_conv_ol_to_org_status`、`/sel/conv_ol_pay_to_late`、`/sel/get_ol_oper_rst`
- [ ] **S3.P2.T15 强制取消服务员买单** `未开始`
  - API: `POST /sel/force_cancel_waiter_olpay`
- [ ] **S3.P2.T16 线上单立即出品** `未开始`
  - API: `POST /sel/ol_order_do_cp`
- [ ] **S3.P2.T17 批量改服务员 / 授权人** `未开始`
  - Vue: `drawerBatchUpdateWaiter.vue`、`drawerBatchUpdateAuther.vue`
  - API: `POST /sel/chg_wkorder_waiter`、`/sel/chg_wkorder_auther`
- [ ] **S3.P2.T18 滞留金管理（收银底栏）** `未开始`
  - Vue: `drawerMerchantConfig.vue`；API 同 T05 管理接口
- [ ] **S3.P2.T19 从收银进点单** `未开始`
  - Vue: `newFootBar.vue` 收银「点单」→ `orderMealList`

---

## S4 会员系统 VIP

路由：`src/router/vip/index.js`。侧栏：`src/views/vip/navList.js` **未注释项必须移植；已注释但仍有真实页面/API 的也必须移植**（积分设置 `/pointManager`、会员卡充值设置 `/onlineMakeMoneyToVip`、结账规则随卡类型配置抽屉）。壳：`src/views/vip/vipNav.vue`。API：`src/api/vip/index.js`。Flutter：`packages/card_table/lib/src/vip_*`。

### S4.P0 会员壳

- [ ] **S4.P0.T01 侧栏 + 返回收银卡台** `未开始`
  - Vue: `vipNav.vue` + `navList.js` id=0 返回、id=1 首页
  - Flutter: `vip_nav_screen.dart`；收银入口 S3.P1.T04 打开本壳

### S4.P1 `/vipManager` 会员管理

Vue: `src/views/vip/vipManager.vue`。

- [ ] **S4.P1.T01 会员卡列表/搜索** `未开始` — `POST /mb/card/list`
- [ ] **S4.P1.T02 新建会员卡** `未开始` — `/mb/card/get_params_f_new`、`/mb/card/new`；短信 `/sms/valid_send` `/sms/valid_chk` type 101
- [ ] **S4.P1.T03 制卡开始/结束** `未开始` — `/mb/card/mk_card_begin` `/mb/card/mk_card_end`
- [ ] **S4.P1.T04 绑定手机名下卡** `未开始` — `/mb/card/phone_mb_list`
- [ ] **S4.P1.T05 页面内其它写操作（改绑、注销、改等级等）** `未开始`
  - 执行时逐个从 `vipManager.vue` 抄按钮 → 对 `src/api/vip/index.js` 的 path；一按钮一叶测试

### S4.P2 `/qwVip` 企微会员

Vue: `src/views/vip/qwVip.vue`。

- [ ] **S4.P2.T01 列表/筛选** `未开始` — 以页面内实际 POST 为准
- [ ] **S4.P2.T02 页面写操作** `未开始` — 每按钮一任务，禁止合并成「其它」

### S4.P3 `/vipType` 会员卡类型

Vue: `src/views/vip/vipType.vue`。

- [ ] **S4.P3.T01 类型列表** `未开始` — `POST /mb/type/list` `/mb/type/get`
- [ ] **S4.P3.T02 新增/改名/默认/删除类型** `未开始` — `/mb/type/new` `/chg_name` `/chg_def` `/del`
- [ ] **S4.P3.T03 等级 CRUD + 经验阀值 + 卡券** `未开始` — `/mb/type/get_level_list` `/new_level` `/chg_level_name` `/chg_level_pic` `/del_level` `/chg_mb_card_level_exp_td` `/chg_level_kq` `/get_mb_card_level_kqs`
- [ ] **S4.P3.T04 自动升级开/关** `未开始` — `/mb/type/enable_autoupd` `/disable_autoupd`
- [ ] **S4.P3.T05 自定义卡面** `未开始` — `/mb/type/get_cust_cover_list` `/new_cust_cover` `/del_cust_cover`；图前缀 `/oss/get_pic_prefix`

### S4.P4 `/vipNumRules` 会员卡号生成规则

Vue: `src/views/vip/vipNumRules.vue`。

- [ ] **S4.P4.T01 读规则 + 保存** `未开始` — 以页面内 POST 为准（执行时从 vue 抄，写入本任务注释）

### S4.P5 报表页（只读 + 导出）

每页：列表查询、分页、导出（若 Vue 有）。API 均在 `src/api/vip/index.js`，执行时从对应 vue 抄 path。

- [ ] **S4.P5.T01 `/makeMoneyToVip` 充值记录** `未开始` — `src/views/vip/makeMoneyToVip.vue`
- [ ] **S4.P5.T02 `/lateDepositManage` 滞留金管理** `未开始` — `lateDepositManage.vue`（此页含管理写：按页面按钮再拆子任务）
- [ ] **S4.P5.T03 `/payMoneyAll` 消费记录** `未开始`
- [ ] **S4.P5.T04 `/vipPay` 扣款记录** `未开始`
- [ ] **S4.P5.T05 `/pointRecords` 积分记录** `未开始`
- [ ] **S4.P5.T06 `/memberBalanceSum` 会员卡余额汇总表** `未开始`
- [ ] **S4.P5.T07 `/memberConsumeRank` 会员消费排名表** `未开始`
- [ ] **S4.P5.T08 `/customerRelationShipMaintence` 客户关系维护表** `未开始`
- [ ] **S4.P5.T09 `/logoutRecordForm` 注销记录表** `未开始`
- [ ] **S4.P5.T10 `/changeLevelRecordForm` 更改等级记录表** `未开始`

### S4.P6 积分 / 充值设置 / 结账规则（navList 注释项仍要移植）

- [ ] **S4.P6.X01 `/pointManager` 积分设置** `未开始` — `GET/POST /mb/card/get_pt_rule` `save_pt_rule` `{type_id, base_amt}`
- [ ] **S4.P6.X02 `/onlineMakeMoneyToVip` 会员卡充值设置** `未开始` — `/mb/deposit_rule/list|new|save|del`
- [ ] **S4.P6.X03 会员卡结账规则** `未开始` — `/mb/card/get_grp_mb_csm_rule_list` 等（独立页路由已注释，功能在卡类型「配置」抽屉 + 业务配置入口）

---

## S5 存酒系统 Wine（后台）

路由：`src/router/wine/index.js`（挂在 ManagementSystem）。API：`src/api/wine/index.js`。前台存取酒见 S2.P6。Flutter：开工时建 `packages/features/wine` 或 `card_table/lib/src/wine_*`。

### S5.P1 `/wine/saveNeedToLib` 存酒待入库

Vue: `src/views/ManagementSystem/wine/saveNeedToLib/saveNeedToLib.vue`。

- [ ] **S5.P1.T01 列表** `未开始` — `POST /wine/get_cj_bef_in`
- [ ] **S5.P1.T02 批量确认入库** `未开始` — `/wine/confirm_cj_bef_in`
- [ ] **S5.P1.T03 批量驳回** `未开始` — `/wine/back_cj_bef_in`
- [ ] **S5.P1.T04 仓库改单** `未开始` — `/wine/chg_cj_bef_in`
- [ ] **S5.P1.T05 待改订位人列表** `未开始` — `/wine/get_chg_sales_emp_list`

### S5.P2 `/wine/getNeedToLib` 取酒待出库

Vue: `getNeedToLib/getNeedToLib.vue`。

- [ ] **S5.P2.T01 列表** `未开始` — `POST /wine/get_qj_bef_out`
- [ ] **S5.P2.T02 批量确认出库** `未开始` — `/wine/confirm_qj_bef_out`
- [ ] **S5.P2.T03 批量驳回** `未开始` — `/wine/back_qj_bef_out`
- [ ] **S5.P2.T04 授权确认** `未开始` — `/wine/confirm_auth_qj_bef_out`

### S5.P3 `/wine/saveLib` 存酒库

- [ ] **S5.P3.T01 列表** `未开始` — `POST /wine/get_wine_invt`；导出 `/wine/rpt/exp_wine_invt`
- [ ] **S5.P3.T02 过期延期** `未开始` — `/wine/delay_wine_invt2`
- [ ] **S5.P3.T03 库存充公** `未开始` — `/wine/cg_wine_invt`

### S5.P4 `/wine/saveLibChild` 存酒库子订单

- [ ] **S5.P4.T01 列表** `未开始` — `POST /wine/rpt/get_wine_invt_sub_order`

### S5.P5 `/wine/passTime` 过期待处理

- [ ] **S5.P5.T01 列表+导出** `未开始` — `/wine/get_wine_invt_expired`；导出 `/wine/rpt/exp_wine_invt_expired`
- [ ] **S5.P5.T02 过期充公** `未开始` — `/wine/cg_expired_wine_invt`
- [ ] **S5.P5.T03 过期延期** `未开始` — `/wine/delay_wine_invt`

### S5.P6 `/wine/saveLibAllData` 存酒库库存

- [ ] **S5.P6.T01 网格+明细+导出** `未开始` — `/wine/get_wine_invt_grid` `/wine/get_wine_invt_grid_dtl` `/wine/exp_wine_invt_grid`

### S5.P7 `/wine/toStore` 待充公 · `/wine/storeLib` 充公库 · `/wine/toStoreDetail` 充公出库单

- [ ] **S5.P7.T01 待充公列表与操作** `未开始` — 从 `toStore.vue` 抄全部 POST
- [ ] **S5.P7.T02 充公库列表** `未开始` — `storeLib.vue`
- [ ] **S5.P7.T03 充公出库单** `未开始` — `toStoreDetail.vue`

### S5.P8 `/wine/userConfig` 用户管理

- [ ] **S5.P8.T01 客户列表** `未开始` — `POST /wine/get_wine_cust_list`
- [ ] **S5.P8.T02 改姓名/手机** `未开始` — `/wine/save_wine_cust_name` `/wine/wine_chk_phone_usable` `/wine/chg_wine_cust_phone`
- [ ] **S5.P8.T03 短信批量开关** `未开始` — `/wine/batch_set_enable_sms`
- [ ] **S5.P8.T04 黑名单批量加/删/导入** `未开始` — `/wine/batch_add_wine_blacklist` `/batch_del_wine_blacklist` `/exp_wine_blacklist_tpl` `/imp_wine_blacklist_chk`

### S5.P9 客户中心 `/wine/customSaveLib` 待入库 · `/wine/customGetLib` 取酒

- [ ] **S5.P9.T01 客户待入库** `未开始` — `customSaveLib.vue` 内接口
- [ ] **S5.P9.T02 客户取酒** `未开始` — `customGetLib.vue` 内接口

### S5.P10 报表

每页：查询 + 导出（Vue 有则做）。Vue 均在 `src/views/ManagementSystem/wine/<name>/`。

- [ ] **S5.P10.T01 `/wine/saveAndGetReport` 存取酒记录** `未开始`
- [ ] **S5.P10.T02 `/wine/passTimeLongReport` 延期记录** `未开始`
- [ ] **S5.P10.T03 `/wine/toStoreOutReport` 充公出库记录** `未开始`
- [ ] **S5.P10.T04 `/wine/saveAllDataReport` 入库统计** `未开始`
- [ ] **S5.P10.T05 `/wine/getAllDataReport` 出库统计** `未开始`
- [ ] **S5.P10.T06 `/wine/toStoreAllDataReport` 充公统计** `未开始`
- [ ] **S5.P10.T07 `/wine/saveWineSearch` 存酒查询** `未开始`
- [ ] **S5.P10.T08 `/wine/nowInvtReport` 日实时库存** `未开始`

### S5.P11 借还

- [ ] **S5.P11.T01 `/wine/borrowWine` 借酒** `未开始` — `borrowWine.vue`
- [ ] **S5.P11.T02 `/wine/returnWine` 还酒** `未开始` — `returnWine.vue`
- [ ] **S5.P11.T03 `/wine/unreturnedWine` 未还酒水** `未开始` — `unreturnedWine.vue`

---

## S6 排队 Queue

路由：`src/router/queue/index.js`。咨客排队操作已在 S1.P1.R07。本页是客用大屏。

### S6.P1 `/queue/bigScreen` 叫号大屏

Vue: `src/views/Queue/bigScreen.vue`（列：类型 / 当前叫号 / 当前取号 / 等待叫号 / 等待桌数）。数据来自同步 `QUEUE_TASK`，不是独立 REST 列表。

- [ ] **S6.P1.T01 全屏只读大屏** `未开始`
  - Vue: `bigScreen.vue`；数据：实时同步排队类型列表
  - Flutter: 新建 `queue_big_screen.dart`；Web/Windows 路由；Android 默认不在范围除非台账批准
  - 完成: 五列字段与空态「暂无数据」；门店名+日期；随 `/sync` 更新

---

## S7 BMS 门店后台

路由真值：`src/router/bms/index.js` **第 263 行注释之前**。壳：`src/views/ManagementSystem/BMS/BMS.vue`。API 聚合：`src/api/BMS/index.js`。Flutter：开工建 `packages/features/bms`。每个配置页标准四件套：**列表、新建、编辑保存、有效/无效或删除**；有抽屉的再按抽屉拆。

### S7.P0 后台壳

- [ ] **S7.P0.T01 BMS 侧栏按角色模块渲染** `未开始`
  - Vue: `BMS.vue` 菜单
  - 完成: 无模块则不显示；点菜单进对应页；Windows/Web 必做，Android 默认不在范围

### S7.P1 人员

- [ ] **S7.P1.T01 `/BMS/codeRules` 工号生成规则读/存** `未开始`
  - Vue: `codeRules/codeRules.vue`；API `POST /emp/gen_rule` `/emp/save_gen_rule`（`src/api/BMS/genRule/index.js`）
- [ ] **S7.P1.T02 `/BMS/stationConfig` 岗位列表** `未开始` — `POST /station/list`（`src/api/BMS/station/index.js`）
- [ ] **S7.P1.T03 岗位新建/详情/保存** `未开始` — `/station/new` `/station/get` `/station/save`；抽屉 `drawerAddOrUpdateStation.vue`
- [ ] **S7.P1.T04 岗位有效/无效/删除** `未开始` — `/station/disable` `/enable` 及删除接口
- [ ] **S7.P1.T05 岗位可点区域/可点商品/特饮/优惠商品范围** `未开始`
  - Vue: `drawerCanOrderArea.vue` `drawerCanOrderPrd.vue` `drawerCanTYPrd.vue` `drawerCanYHPrd.vue`
- [ ] **S7.P1.T06 岗位登录配置 / 看单 / ERP / 充值积分 / 角色授权 / 其它设置** `未开始`
  - Vue: `drawerLoginConfig.vue` `drawerLookOrder.vue` `drawerErpConfig.vue` `drawerRechargePointConfig.vue` `drawerRoleAuth.vue` `drawerSetConfig.vue`
  - 完成: 每个抽屉独立测试；权限字段与 Vue 提交 body 一致
- [ ] **S7.P1.T07 `/BMS/employeeList` 员工列表** `未开始` — `POST /emp/list`（`src/api/BMS/emp/index.js`，body 用 `ids`）
- [ ] **S7.P1.T08 员工新建/编辑** `未开始` — `/emp/new` `/emp/get` `/emp/save`；`drawerAddOrUpdate.vue`
- [ ] **S7.P1.T09 员工绑定/其它/导入/克隆/同组/下属** `未开始`
  - Vue: `drawerBindEmp.vue` `drawerEmpOther.vue` `drawerImportEmp.vue` `drawerMyClones.vue` `drawerMySameGroup.vue` `drawerMySubordinates.vue`
- [ ] **S7.P1.T10 批量重置密码** `未开始` — `POST /emp/batch_reset_pwd`
- [ ] **S7.P1.T11 `/BMS/onboardingApproval` 入职审批** `未开始` — `dept/onboardingApproval/onboardingApproval.vue` 内接口
- [ ] **S7.P1.T12 `/BMS/businessEmp` 商务组订位人** `未开始` — `src/api/BMS/emp/businessEmp.js`

### S7.P2 商品

- [ ] **S7.P2.T01 `/BMS/prdConfig` 一级分类 CRUD** `未开始` — `oneCateTable.vue`；API `src/api/BMS/ocate/index.js`
- [ ] **S7.P2.T02 二级分类 CRUD** `未开始` — `twoCateTable.vue`；`src/api/BMS/tcate/index.js`
- [ ] **S7.P2.T03 商品列表/新建/保存/有效无效/删除** `未开始`
  - Vue: `prdTable.vue` `drawerAddOrUpdatePrd.vue`
  - API: `POST /prd/list` `/prd/new` `/prd/get` `/prd/save` `/prd/disable` `/prd/enable` `/prd/del`（`src/api/BMS/Prd/index.js`）
- [ ] **S7.P2.T04 套餐商品 / 绑定 / 导入 / 出品库区域** `未开始`
  - Vue: `drawerAddOrUpdateGroupPrd.vue` `drawerBindPrd.vue` `drawerImportAll.vue` `setAreaLibrary.vue` `setTwoCategory.vue` `choosePrd.vue`
  - API: `/prd/ass_items` `/prd/erp_prds` 等页面实际调用
- [ ] **S7.P2.T05 `/BMS/uploadProImg` 批量上传商品图片** `未开始` — `uploadProImg/uploadProImg.vue`
- [ ] **S7.P2.T06 `/BMS/taocanTemplate` 套餐可选组模板** `未开始` — `taocanTemplate.vue`

### S7.P3 卡台

- [ ] **S7.P3.T01 `/BMS/cardConfig` 区域 CRUD** `未开始`
  - Vue: `cardConfigTable/area.vue`；API `POST /region/list` 等 `src/api/BMS/region/index.js`
- [ ] **S7.P3.T02 卡台 CRUD / 排序 / 二维码 / 必点商品** `未开始`
  - Vue: `card.vue` `drawerAddOrUpdateCard.vue` `drawerAddAllCard.vue` `drawerShowQr.vue` `drawerConfigOrderPrd.vue`
  - API: `POST /seat/list` `/seat/new` `/seat/get` `/seat/save` `/seat/disable` `/seat/enable` `/seat/del` `/seat/move_dsp`（`src/api/BMS/seat/index.js`）
- [ ] **S7.P3.T03 `/BMS/cardMinGroup` 卡台抵消组** `未开始` — `cardMinGroup.vue`；API `src/api/BMS/seat_grp/index.js`
- [ ] **S7.P3.T04 `/BMS/cardTips` 卡台标签** `未开始` — `cardTips.vue`；`src/api/BMS/cardTips/index.js`
- [ ] **S7.P3.T05 `/BMS/arriveRules` 计抵达规则** `未开始` — `arriveRules.vue`；`src/api/BMS/arriveRules/index.js`

### S7.P4 限额限量

- [ ] **S7.P4.T01 `/BMS/prdGroupConfig` 商品组** `未开始` — `prdGroupConfig.vue`；`src/api/BMS/pgrp/index.js`
- [ ] **S7.P4.T02 `/BMS/limitConfig` 限额限量** `未开始` — `limitConfig.vue` `drawerAddOrUpdateLimit.vue`；`src/api/BMS/freelmt/index.js`

### S7.P5 门店 / 支付 / 设备

- [ ] **S7.P5.T01 `/BMS/store` 门店信息读/存** `未开始` — `POST /org/get_info` `/org/save_info`；省市区 `/cfg/addr/provinces` `/cfg/addr/districts`
- [ ] **S7.P5.T02 `/BMS/restore` 营业日恢复** `未开始` — `POST /wkd/restore`；Vue `store/restore.vue`
- [ ] **S7.P5.T03 `/BMS/payList` 渠道管理** `未开始` — `POST /paycnl/list` `/paycnl/items` `/paycnl/add_used` `/paycnl/del_used` `/paycnl/new`（`src/api/BMS/paycnl/index.js`）
- [ ] **S7.P5.T04 `/BMS/printers` 打印机 CRUD** `未开始` — `POST /printer/list` `/new` `/get` `/save` `/disable`（`src/api/BMS/printer/index.js`）
- [ ] **S7.P5.T05 `/BMS/outLibConfig` 出品库 CRUD** `未开始` — `POST /mklib/list` `/new` `/get` `/new_printer`（`src/api/BMS/mklib/index.js`）
- [ ] **S7.P5.T06 `/BMS/bills` 小票配置读/存** `未开始` — `POST /bill/get` `/bill/save`；预览 `bills/drawerPreview.vue`
- [ ] **S7.P5.T07 `/BMS/terminalBms` 终端列表/打印机/清设备/快捷码** `未开始`
  - API: `POST /lic/list` `/lic/get_prts` `/lic/get_wine_store_prts` `/lic/save_prt` `/lic/clear_term` `/lic/gen_quick_code`

### S7.P6 报表配置 / 小程序 / 要求 / 理由 / 规则

- [ ] **S7.P6.T01 `/BMS/reportTYConfig` 鸡尾酒导出配置** `未开始` — `src/api/BMS/reportConfig/`
- [ ] **S7.P6.T02 `/BMS/sealPrdConfig` 分类渠道统计设置** `未开始`
- [ ] **S7.P6.T03 `/BMS/statisticalGroupConfig` 统计类别配置** `未开始` — `src/api/BMS/statistical/`
- [ ] **S7.P6.T04 `/BMS/channelGroupConfig` 渠道类别配置** `未开始` — `src/api/BMS/channel/`
- [ ] **S7.P6.T05 `/BMS/miniProgressConfig` 高毛利商品配置** `未开始` — `src/api/BMS/miniProgressConfig/`
- [ ] **S7.P6.T06 `/BMS/requireConfig` 要求类型+要求项** `未开始`
  - API: `POST /cfg/rqm/tree` `/search` `/type_list` `/list`（`src/api/BMS/require/index.js`）
- [ ] **S7.P6.T07 理由四页（优惠/退单/退卡/取消优惠）** `未开始`
  - 路由: `/BMS/YHReason` `/BMS/backReason` `/BMS/backVipCard` `/BMS/QXYHReason` 共用 `reason/reason.vue`
  - API: `POST /rsn/list` `/rsn/new` `/rsn/save` `/rsn/del`；用页面 query/type 区分，不要做成四个包
- [ ] **S7.P6.T08 `/BMS/terminalRules` 规则配置** `未开始` — `src/api/BMS/terminalRules/`
- [ ] **S7.P6.T09 `/BMS/vipRules` 会员卡规则** `未开始` — `terminalRules/vipRules.vue`

### S7.P7 存酒设置 / 抽成 / 短信

- [ ] **S7.P7.T01 `/BMS/saveConfig` 存酒设置读/存** `未开始` — `POST /wine/cfg/get` `/wine/cfg/save`
- [ ] **S7.P7.T02 `/BMS/wineInfo` 可存酒水增删改过期** `未开始` — `/wine/cfg/prd_items` `/add_prds` `/del_prds` `/get_prds` `/set_prd_expired`
- [ ] **S7.P7.T03 `/BMS/cutPrd` 抽成管理** `未开始` — `src/api/BMS/cutPrd/` + `cutPrdCom/**`
- [ ] **S7.P7.T04 `/BMS/accountInfo` 短信账户** `未开始` — `src/api/BMS/messageConfig/`
- [ ] **S7.P7.T05 `/BMS/messageDetail` 短信明细** `未开始`
- [ ] **S7.P7.T06 `/BMS/messageResult` 短信结果查询** `未开始`

### S7.P8 不移植（重构前旧路由）

以下路由在 `src/router/bms/index.js` 注释「以下为重构之前代码」之后，**禁止当作新页移植**（活页已覆盖同功能）：

`/BMS/printer` `/BMS/mklib` `/BMS/bill` `/BMS/Paycnl` `/BMS/region` `/BMS/Seat` `/BMS/seats/**` `/BMS/Ocate` `/BMS/tcate` `/BMS/Prd` `/BMS/Prds/**` `/BMS/genRule` `/BMS/station` `/BMS/dept/**` `/BMS/requires/**` `/BMS/seat_grp` `/BMS/pgrp` `/BMS/freelmt`

注释掉的 `/BMS/vipPrice` 同样不移植。

---

## S8 ERP 仓库

路由真值：`src/router/erp/index.js` **第 134 行注释之前**。API：`src/api/ERP/index.js`。Flutter：开工建 `packages/features/erp`。

### S8.P1 主数据

- [ ] **S8.P1.T01 `/ERP/home` 首页** `未开始` — `src/views/ManagementSystem/ERP/home/home.vue`；`src/api/ERP/home/`
- [ ] **S8.P1.T02 `/ERP/erpLib` 仓库管理 CRUD** `未开始` — `erpLib/erpLib.vue`；`src/api/ERP/erpLib/` 与 `store/`
- [ ] **S8.P1.T03 `/ERP/mats` 物料列表** `未开始` — `POST /mat/cate_list` `/mat/list`（`src/api/ERP/mat/index.js`）
- [ ] **S8.P1.T04 物料新建/保存/单位** `未开始` — `/mat/new` `/mat/save`；页面内其余按钮各写一测
- [ ] **S8.P1.T05 `/ERP/comparePrd` 商品对照** `未开始` — `src/api/ERP/comparePrd/`
- [ ] **S8.P1.T06 `/ERP/supplierConfig` 供应商 CRUD** `未开始` — `POST /supplier/list` `/new` `/get` `/save`（`src/api/ERP/supplier/index.js`）

### S8.P2 入库

- [ ] **S8.P2.T01 `/ERP/anotherInLib` 其他入库列表** `未开始` — `POST /sin/list`（`src/api/ERP/sin/index.js`）
- [ ] **S8.P2.T02 其他入库新建/物料检索** `未开始` — `/sin/new` `/sin/mat_items`；`record_type` 按 Vue
- [ ] **S8.P2.T03 `/ERP/changeInLib` 调拨入库** `未开始` — `src/api/ERP/sind/`；`inLib/changeInLib.vue`
- [ ] **S8.P2.T04 `/ERP/applyForInLib` 入库异议** `未开始` — 以 `applyForInLib.vue` 内 POST 为准

### S8.P3 出库

- [ ] **S8.P3.T01 `/ERP/anotherOutLib` 其他出库** `未开始` — `src/api/ERP/sout/`；`outLib/anotherOutLib.vue`
- [ ] **S8.P3.T02 `/ERP/changeOutLib` 调拨出库** `未开始` — `src/api/ERP/soutd/`
- [ ] **S8.P3.T03 `/ERP/applyForOutLib` 出库异议** `未开始` — `src/api/ERP/soutdd_yy/`

### S8.P4 空瓶

- [ ] **S8.P4.T01 `/ERP/emptyInLibOrder` 空瓶入库单** `未开始` — `src/api/ERP/emptyLib/`
- [ ] **S8.P4.T02 `/ERP/emptyLib` 空瓶仓** `未开始`
- [ ] **S8.P4.T03 `/ERP/emptyOutLibOrder` 空瓶出库单** `未开始`

### S8.P5 报表（查询 + 导出）

| 任务 | 路由 | Vue | 读 API | 导出 |
| --- | --- | --- | --- | --- |
| T01 | `/ERP/matLibNow` | `rpt_erp/matLibNow.vue` | `POST /rpt_erp/get_now_mat_invt` | `/rpt_erp/exp_now_mat_invt` |
| T02 | `/ERP/matLib` | `matLib.vue` | `/rpt_erp/get_mat_invt` | `/rpt_erp/exp_mat_invt` |
| T03 | `/ERP/inLibRep` | `inLibRep.vue` | `/rpt_erp/in_recs` | `/rpt_erp/exp_in_recs` |
| T04 | `/ERP/outLibRep` | `outLibRep.vue` | `/rpt_erp/out_recs` | `/rpt_erp/exp_out_recs` |
| T05 | `/ERP/inLibAllRep` | `inLibAllRep.vue` | `/rpt_erp/in_sum` | `/rpt_erp/exp_in_sum` |
| T06 | `/ERP/outLibAllRep` | `outLibAllRep.vue` | `/rpt_erp/out_sum`（以 vue 为准） | `/rpt_erp/exp_out_sum` |
| T07 | `/ERP/warehousePSI` | `warehousePSI.vue` | 以页面内 POST 为准 | 以页面为准 |
| T08 | `/ERP/emptyInLib` | `emptyInLib.vue` | `src/api/ERP/reportEmpty/` | 以页面为准 |
| T09 | `/ERP/emptyOutLib` | `emptyOutLib.vue` | 同上 | 以页面为准 |

- [ ] **S8.P5.T01～T09** 各报表按上表 `未开始`；参数接口 `POST /rpt_erp/param_items`

### S8.P6 不移植

注释「以下为重构之前代码」之后：`/ERP/supplier` `/ERP/mat/**` `/ERP/mat_unit` `/ERP/mat_spec` `/ERP/sin` `/ERP/sind` `/ERP/sindd_yy` `/ERP/sout` `/ERP/soutd` `/ERP/soutdd_yy` `/ERP/month_invs` `/ERP/in_recs` `/ERP/out_recs` `/ERP/in_sum` `/ERP/out_sum`。

---

## S9 超级账号（可选，非门店日常）

- [ ] **S9.P1 `/ManagementSystem/appinfo/smgr` 用户管理** `未开始`
  - Vue: `src/views/ManagementSystem/appinfo/smgr/smgr.vue`；API `src/api/UtilAuth/appinfo/`
  - 平台: 仅 Win/Web；Android 不在范围
- [ ] **S9.P2 `/appinfo` 超管登录** `未开始` — `src/views/Thelogin/appinfo.vue`
- [ ] **S9.P3 `/register` 注册** `未开始` — 仅当现网门店仍使用；执行前先确认是否还在用，停用则标不移植

---

## 覆盖核对（对照设计与路由）

| 设计/路由要求 | 对应任务 |
| --- | --- |
| Win/Web 全量、Android 台账、无离线、不改后端 | 0.2、0.3、全文完成标准 |
| 协议/权限/同步/设备 | M0 |
| Book `/cardMachine` `/reserved` | S1.P1 S1.P2 |
| Order 卡台 + orderMeal 新组件 | S2 |
| Money 卡台 + 结账 + 37 更多 | S3 |
| VIP `navList.js` 活页 | S4 |
| Wine 全部活路由 + 点单内存酒 | S5 + S2.P6 |
| Queue 大屏 | S6 |
| BMS 重构后活路由 | S7 |
| ERP 重构后活路由 | S8 |
| 预定弹窗 id 1–27（现网 `getCardOptions`） | S1.P1.T04–T26 |
| 点单已确认鸡尾酒/估清 | S2.P1.T08 T09 保持已确认 |
| Windows 尚未挂卡台 | M0.P4.T01 |
| Android 预定报表未接线 | S1.P1.R01–R07 |

执行某叶任务时若发现 Vue 还有未列出的按钮：在该页面下**追加**一条叶任务，不要默默做也不要丢进「其它」。

---

## 建议的下一份 TDD 详案（不要一次做完全文）

1. `docs/superpowers/plans/YYYY-MM-DD-windows-card-table-shell.md` ← M0.P4.T01
2. `docs/superpowers/plans/YYYY-MM-DD-booking-popup-remainder.md` ← S1.P1.T22–T26
3. `docs/superpowers/plans/YYYY-MM-DD-order-meal-cart-submit.md` ← S2.P2–P3
4. `docs/superpowers/plans/YYYY-MM-DD-cashier-pay-order.md` ← S3.P2
)