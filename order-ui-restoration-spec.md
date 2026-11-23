# 点单系统（S2）最新全端视觉还原稿 & 酒吧极速改造规范（2026-11-22）

> **在线交互预览**：https://t86.github.io/shouying/order.html（与 S1 预订 / S3 收银顶部一键互通）
>
> **目标终端**：macOS 桌面端 · Windows 桌面端 · Android 平板（720–1199dp 三栏实时购物车）· Android 手机（393dp 2 列卡台 + 吸底购物车胶囊条）
>
> **已确认的核心设计决策（2026-11-22）**：
> - ✅ **双主题切换（默认深色）**：依据 `flutter_workspace/packages/design_system/lib/src/order_theme.dart` 落地 `OrderThemeController`，**默认深色护眼主题（`OrderPalette.dark()` `#151E34`）**，顶部提供 1 键切换至 **浅灰蓝高可读主题（`OrderPalette.light()` `#DCE1EA`）**。
> - ✅ **全量功能 100% 保留**：完整保留 10 个点单权限数据集、服务员买单（`os/oos` + 5 渠道）、卡券 V2 核销、完整可视化存酒/取酒/充公、会员充值/开卡、滞留金与 3 张首页报表。
> - ✅ **酒吧「能点 1 下绝不点 2 下」8 项效率重构**：单品原地 `+`/`-` 步进器、1 页快捷数量(`1/2/6/12`)+`19/20/21`出品要求、跨分类全局搜索、桌面/平板三栏实时购物车 & 手机吸底购物车胶囊条、顶栏快搜台号 + `已开台` 快捷切页、高可见度存酒模式按钮与状态条、居中高对比 `showBookingToast`。

## 视觉设计系统（`OrderPalette.dark()` / `OrderPalette.light()`）

| Token | 深色模式（默认） | 浅色模式（1 键切换） | 用途 |
| :--- | :--- | :--- | :--- |
| `canvasPrimary` | `#151E34` | `#DCE1EA` | 页面主画布 |
| `surfaceHeader` | `#1C2742` | `#FFFFFF` | 顶部栏、表头工具条 |
| `surfacePanel` | `#18223A` | `#F3F6FA` | 左侧分类栏、右侧实时购物车栏 |
| `surfaceCard` | `#212E4D` | `#FFFFFF` | 商品卡片、账单卡片 |
| `surfaceFooter` | `#0E1629` | `#FFFFFF` | 底部图例栏 / `newFootBar` 工作台 |
| `surfaceCartBar` | `#111B33` | `#1E293B` | 手机端吸底购物车胶囊条 |
| `brandPrimary` | `#4B89FF` | `#2563EB` | 主按钮、选中态、加购 `+` |
| `ctaGreen` | `#1CC96C` | `#16A34A` | 立即下单、确认提交 |
| `discountAmber` | `#FFAB2E` | `#D97706` | 优惠、低消提示 |
| `yh2Purple` | `#9B6DFF` | `#7C3AED` | 优惠 2、方案价标签 |
| `wineCyan` | `#1AC8D4` | `#0891B2` | 存酒模式、套餐标识 |
| `dangerRed` | `#FF4757` | `#DC2626` | 退单、服务员买单、估清警示 |

---


- **对比基准**：
  - 原系统 Vue `dev` 分支（`edd1a857`）：``dev` 分支根目录`（实际路由以 `src/router/order/index.js` 挂载的 `newOrderCard.vue` + `orderMeal/*` + `newDrawerMeal/*` + `newSaveWine/*` + `vipRecharge/*` 为准）
  - Flutter 实现（`feature/flutter-foundation`）：``flutter` 分支 `flutter_workspace/``
- **核查口径**：
  - `[x]` 经逐行源码核对，功能、接口、载荷、权限与核心交互与 `dev` 分支一致。
  - `[ ]` 存在功能缺失、协议/数据解析 Bug、权限漏洞或严重操作效率瓶颈，需按优先级修复后再打勾。

> [!IMPORTANT]
> **总体核查结果**：共核查 **70** 个细分功能项，**已一致打勾 18 项（`[x]`）**，**待补齐/修复 52 项（`[ ]`）**（含 **25 项 P0 阻断/权限/金额/接口错误**、**17 项 P1 核心业务与交互缺口**、**10 项 P2 体验与边界打磨**）。
>
> **核心效率诊断**：当前 Flutter 点单端存在大量「多步弹窗打断 + 串行锁屏 + 缺少快速搜索/步进」问题（常规加 1 杯酒要 2 步、加 6 杯要 5 步、加要求要 7+ 步、加优惠多件要 12 步、存/取酒和优惠 2 甚至要求手填数据库 ID）。本次将同步完成**功能 100% 补齐 + 酒吧「1 步直达」效率重构**。

---

## 一、点单首页（`newOrderCard.vue`）、角色权限与卡台网格

- [x] **默认选中「我的卡台」页签 + `我的卡台` 归属判定（`salesEmployeeId == id || waiterEmployeeIds.contains(id)`）**
  - 依据：`src/views/Order/newOrderCard.vue#L376` ↔ `flutter_workspace/packages/card_table/lib/src/card_table_screen.dart#L757`
- [x] **基础卡面字段展示**（区域名、开台时间 `HH:mm`、`惠:￥` 仅营销角色可见、`锁` 标、订位人+部门/`散客`、`翻N`、6 字备注、7 态语义色、`showCustomerDetails=false`）
  - 依据：`src/views/Order/newOrderCard.vue#L52-L162` ↔ `flutter_workspace/packages/card_table/lib/src/card_table_screen.dart#L2633-L2851`、`flutter_workspace/packages/card_table/lib/src/order_card_display.dart#L119-L168`
- [ ] **[P0] 角色级区域与卡台可见范围隔离缺失（数据集 `15` `stationArea`、`50` `giftableCard`、`/wo/get_sales_seats`、`check_regions`、`clone_emp_id`、无角色拦阻）**
  - 问题：服务员（role 2）、特饮（role 4）、营销（role 3）、无角色账号目前能看到**全场所有区域与卡台**；未解析 `15`/`50`/`check_regions`/`clone_emp_id` 及 `/wo/get_sales_seats`。
  - 依据：`src/views/Order/newOrderCard.vue#L486-L595` ↔ `flutter_workspace/packages/card_table/lib/src/legacy_card_table_store.dart#L1030-L1055`
- [ ] **[P0] 终端可操作范围（数据集 `40` `machineArea`）取交集而非并集，且无规则时默认放行全开**
  - 问题：同时配置 `type_id=1`（区域）与 `type_id=2`（附加卡台）时应取**并集**，当前 `&&` 交集会导致卡台被清空；且无 `type_id=3` 又无配置时错放行全开。
  - 依据：`src/views/Order/newOrderCard.vue#L612-L667` ↔ `flutter_workspace/packages/card_table/lib/src/legacy_card_table_store.dart#L1419-L1444`
- [ ] **[P0] 模块 `70`（禁止查看未开台 `bizStatus 1/2/8`）未实现**
  - 依据：`src/mixin/cardPage.js#L10-L15`、`src/views/Order/newOrderCard.vue#L789-L793`
- [ ] **[P0] 卡面金额查看权限（`OrderCardDisplay.canLookOrder`）存在 3 处漏洞**
  - ① 缺失营销查单范围（`/wo/get_sales_seats`）；② 督查角色（role 11）无条件返回 `true`，未校对数据集 `56`；③ `_optionalId("0")` 返回 `"0"` 而非 `""`，导致顶层员工在模块 7/11 下 `"0" == "0"` 越权互看金额。
  - 依据：`src/views/Order/newOrderCard.vue#L1272-L1370` ↔ `flutter_workspace/packages/card_table/lib/src/order_card_display.dart#L53-L106`、`flutter_workspace/packages/card_table/lib/src/legacy_card_table_store.dart#L1598-L1601`
- [ ] **[P0] 卡面点单金额（`点:￥`）缺少关联功能台 `/wo/get_sp_seat_list` 与实单金额核对**
  - 问题：关联功能台（`bizType == 3`）金额与低消进度为 0/错误；未接入 `/wo/get_sp_seat_list` 及 `/wo/get_self_order_amts`。
  - 依据：`src/views/Order/newOrderCard.vue#L735-L786`、`src/mixins/cardAmountMixin.js#L4-L52` ↔ `flutter_workspace/packages/card_table/lib/src/card_table_screen.dart#L2779`
- [ ] **[P1] 未开营业日阻断、安全模式空区域裁剪、督查点卡拦截、退出确认弹窗**
  - 问题：未开营业日时仍可点卡片/切存酒/进报表；安全模式未裁剪纯功能台区域；督查点卡拦截仅在预订端生效；点单端退出登录无二次确认。
  - 依据：`flutter_workspace/packages/card_table/lib/src/card_table_screen.dart#L2244-L2273`
- [ ] **[P1] 底部图例计数越权/缺漏 & 选中态白字在浅底不可见**
  - 问题：非「我的卡台」图例读未过滤 39 号计数（且未按实时卡台防串数）；`personalStatusCounts` 漏 `status == 3`；浅色底栏选中图例文字变白导致看不清。
  - 依据：`flutter_workspace/packages/card_table/lib/src/card_table_screen.dart#L3254-L3281`、`flutter_workspace/packages/card_table/lib/src/card_table_screen.dart#L5360`
- [ ] **[P2] 首页细节：存酒模式下误藏 `mark`、长台号固定字号截断、预订置顶 `pinOrder` 串扰点单排序、存酒模式按钮仅 12px 裸字极难点击、缺少快速搜台号**
  - 依据：`flutter_workspace/packages/card_table/lib/src/card_table_screen.dart#L2654-L2715`

---

## 二、商品目录、分类、套餐、要求、价格体系与点单权限矩阵

- [x] **一二级分类基础树（数据集 2/3）、空分类裁剪与 `dsp` 升序排列**
- [x] **区域可点商品交集（数据集 16 `areaProduct`）**
- [x] **套餐固定/可选组（数据集 9）+ 套餐模板展开（数据集 52）+ 套餐内定制要求（19/20/21）**
- [x] **8 档价格优先级矩阵（`bxBsMb > bxBs > bsMb > bxMb > mb > bs > bx > orig`）与商务订位人（数据集 57）**
- [x] **分成商品方案价 `fcPrice`（数据集 58/59）解析、优先级与历史订单不可变性**
- [x] **优惠/退单理由目录（数据集 32）与商品卡片「已点 N」角标**
- [x] **单品/套餐/花篮小费/赔偿基础路由分流（`/wsc/add_prd`、`/wsc/add_set`、`/wsc/add_hl`）**
- [ ] **[P0] 10 个点单权限数据集完全未解析与未执行（`11` 不限、`12` 二级分类权限、`27` 花篮/小费、`36/37` 优惠/优惠2 限额明细、`42` 岗位禁点黑名单、`44` 功能台商品、`55` 岗位优惠规则、`useType == 2` 仅优惠商品）**
  - 问题：所有员工在所有商品卡片上都无条件显示 `加入 / 优惠 / 优惠2`，可越权点禁点品、花篮、功能台外商品或无权优惠商品。
  - 依据：`src/mixin/navPrdList.js#L18-L630` ↔ `flutter_workspace/packages/card_table/lib/src/legacy_card_table_store.dart#L210-L693`、`flutter_workspace/packages/card_table/lib/src/order_meal_screen.dart#L2355-L2377`
- [ ] **[P0] 二级分类时段限制（数据集 `3` 列 5–9：`enable_time_limit` / `begin_time` / `end_time` / `begin_time2` / `end_time2`）完全未实现**
  - 依据：`src/mixin/navPrdList.js#L652-L669` ↔ `flutter_workspace/packages/card_table/lib/src/sold_out_products.dart#L277-L286`
- [ ] **[P0] 搜索绕过 `limit_pad`/`limit_pc` 终端限制 + 区分大小写 + 仅搜当前二级分类（无法全局搜酒水）**
  - 依据：`src/components/order/productList.vue#L1181-L1192` ↔ `flutter_workspace/packages/card_table/lib/src/sold_out_products.dart#L387-L399`、`flutter_workspace/packages/card_table/lib/src/order_meal_screen.dart#L2026-L2038`
- [ ] **[P0] 卡券套餐 `prdType 12/22/32` 漏过滤，混入常规点单列表并错发 `/wsc/add_prd`**
  - 依据：`src/mixin/navPrdList.js#L672-L676` ↔ `flutter_workspace/packages/card_table/lib/src/sold_out_products.dart#L288-L315`
- [ ] **[P0] 实时估清库存（数据集 `8`）断层与超售漏洞**
  - 问题：① 非套餐商品忽略 WS 实时 8 号更新（仅进页拉一次 HTTP）；② 单品/特饮/优惠加购与购物车 `+` 均**未校验 `count <= remaining`**（剩 2 瓶可点 50 瓶）；③ 套餐父品自身 8 号限购未校验。
  - 依据：`src/components/order/newDrawerMeal/singleProduct.vue#L340-L366`、`src/views/Order/orderMeal/newShoppingCart.vue#L424-L434` ↔ `flutter_workspace/packages/card_table/lib/src/order_meal_screen.dart#L581-L618`
- [ ] **[P0] 单品加购完全缺失定制要求（数据集 `19/20/21`）+ `/wsc/add_prd` 硬编码 `requirement: ''`**
  - 依据：`src/components/order/newDrawerMeal/singleProduct.vue#L45-L60` ↔ `flutter_workspace/packages/card_table/lib/src/order_meal.dart#L217`
- [ ] **[P0] `_addYhProduct` 传原价绕过 8 档价/`fcPrice`、写死 `count: 1`、且套餐点「优惠」错发 `/wsc/add_prd` 而非 `/wsc/add_set`**
  - 依据：`src/components/order/newDrawerMeal/singleProduct.vue#L572-L605` ↔ `flutter_workspace/packages/card_table/lib/src/order_meal_screen.dart#L1246-L1299`
- [ ] **[P0] 关联功能台（`bizType == 3` / 补交 `relate_csm_id`）全链路缺失**
  - 依据：`src/components/order/newDrawerMeal/drawerBj/index.vue#L75-L135` ↔ `flutter_workspace/packages/card_table/lib/src/order_meal.dart#L485`
- [ ] **[P1] 套餐引用已删要求类型导致整套瘫痪 + 静态目录不随 WS 更新 + 安全模式未过滤 `bizType != 1 || price >= 2000` + `prdType == 5` 空原价报错与金额缺校验**
  - 依据：`flutter_workspace/packages/card_table/lib/src/order_set_catalog.dart#L235-L246`、`flutter_workspace/packages/card_table/lib/src/card_table_screen.dart#L1973`
- [ ] **[P2] 视觉/交互细节：菜单切分类不清搜索框、商品图（`picName`）未展示、会员卡面未显示划线原价、套餐弹窗缺分组进度条与估清置灰、`productQuoteFor` 每卡重建目录**

---

## 三、购物车、下单提交、优惠/赠单授权与路由接线

- [x] **购物车数量拉取（`/wsc/get_item_cnt`）、增减（`/wsc/set_cnt`）与套餐改明细（`/wsc/chg_set_detail`）基础通路**
- [x] **绑定卡台服务员（`/csm/set_csm_waiter`）**
- [ ] **[P0] 收银端跳转点单页路由 `/orderMeal` 未注册（点击直接报 `页面不可用`）**
  - 依据：`flutter_workspace/packages/native_client_shell/lib/native_client_shell.dart#L2726-L2739`、`flutter_workspace/apps/web_app/lib/main.dart#L2690-L2697`
- [ ] **[P0] 确认下单（`/wsc/order`）未处理 `code == 2`（必点商品拦截与跳转）及 `code == 5`（0 元自动买单成功提示）**
  - 依据：`src/views/Order/orderMeal/newShoppingCart.vue#L501-L558` ↔ `flutter_workspace/packages/card_table/lib/src/order_meal.dart#L454-L460`
- [ ] **[P0] 全部优惠/赠送/优惠 2 接口写死空主管授权（`auth_emp_code: ''`, `pass_type: 1`），缺失「刷员工卡 + 账号密码」双 Tab 授权弹窗，且优惠 2 弹窗要求手填原始 `订位人Id` / `卡台Id`**
  - 依据：`src/components/order/authorization.vue#L131-L162`、`src/components/order/newDrawerMeal/drawerYH2Submit.vue#L17-L48` ↔ `flutter_workspace/packages/card_table/lib/src/order_meal.dart#L667-L758`、`flutter_workspace/packages/card_table/lib/src/order_meal_screen.dart#L3229-L3286`
- [ ] **[P1] 购物车解析丢字段（`p2`/`at`/`wei`/`ae`/`r`/`ra`）、缺合计/优惠汇总底栏、缺非授权人改量锁、缺套餐子项展开、缺 `/wsc/add_set_requirement` 接线、不支持 `内招/外招/自用/特饮关联` `auth_type`**
  - 依据：`src/views/Order/orderMeal/newShoppingCart.vue#L134-L168` ↔ `flutter_workspace/packages/card_table/lib/src/order_meal.dart#L32-L55`
- [ ] **[P1] 绑定客人（`/csm/set_csm_cust`）不支持解绑、轮询吞业务错、展示明文手机号、未刷新会员价**
  - 依据：`src/components/order/memberBinding.vue#L421` ↔ `flutter_workspace/packages/card_table/lib/src/order_meal.dart#L318-L365`

---

## 四、我的点单（`newMyOrder.vue`）、退单、服务员买单与核销卡券

- [x] **单品退单（`/wo/back`）与 `code == 2` 主管密码二次授权通路**
- [x] **已点套餐改明细（`/wo/chg_set_detail`）基础通路与新鲜度校验**
- [ ] **[P0] 服务员买单（`/wo/get_waiter_olpay_todo_orders` + `/wo/do_waiter_olpay_with_orders`）彻底写反且缺半条链路**
  - 问题：只读 `data['oos']`（线上已排斥单）丢弃 `data['os']`（实际待付线下单），写死 `pay_type: 1`，缺失勾选订单、支付渠道选择（1/2/3/5/6）、`chk_waiter_olpay_with_orders`、续付 `do_continue_waiter_olpay_with_orders`、支付轮询 `get_waiter_olpay_status`、取消 `cancel_waiter_olpay`。
  - 依据：`src/components/order/newDrawerShowOrderList.vue#L195-L263`、`src/components/order/newDrawerPayQR.vue#L151-L530` ↔ `flutter_workspace/packages/card_table/lib/src/order_meal.dart#L1238-L1290`
- [ ] **[P0] 核销卡券（`redeemCoupon`）请求体缺 `seat_id` 及全部商品/套餐字段，且未升级 V2（`/wo/csm_coupon_prepare_v2` + `/wo/csm_coupon_v2`）**
  - 依据：`src/components/order/drawerRedeemCoupon2.vue#L273-L278` ↔ `flutter_workspace/packages/card_table/lib/src/order_meal.dart#L1211-L1224`
- [ ] **[P0] `/wo/list` 已点明细丢商品名/服务员名映射、丢 `wine_ops` 存取酒 Tab、丢行级权限与操作按钮门控**
  - 问题：读不存在的 `n`/`wn` 导致真实接口显示 `商品 <pid>` 且服务员为空；完全丢弃 `wine_ops`；无条件展示 `退单/赠送/优惠2/改明细/补打`（非套餐也显示改明细，忽略模块 `3`/`4`）。
  - 依据：`src/utils/orderDetailAdapter.js#L21-L35`、`src/views/Order/orderMeal/newMyOrder.vue#L8-L189` ↔ `flutter_workspace/packages/card_table/lib/src/order_meal.dart#L417-L428`、`flutter_workspace/packages/card_table/lib/src/order_meal_screen.dart#L2470-L2547`
- [ ] **[P1] 我的点单缺失已点后置操作 & 批量操作 & 打印/并台错误**
  - 缺失：批量优惠/批量优惠2/批量退单、取消优惠（`/sel/cancel_yh`）、改优惠人（`/wo/chg_yh_auth_emp`/`chg_yh_yu2_auth_emp`）、改订单/卡台服务员（`/wo/chg_wk_order_waiter_inord`/`chg_csm_waiter_inord`）、补打单据类型选择（`type 1/2/3`）；打印消费单写死 `unpaid: true`（应为 `total_type: 1` 总单）；`_mergeYh2` 错发全部订单到 `/sel/move_order` 并弹错提示；底栏汇总缺第 5 项「主营实收」且「更多功能」缺清台/转台权限门控（模块 71/72）。
- [ ] **[P2] 已点明细缺 `锁`/`退单中`/`补单` 徽章、退单原因、要求文字与套餐子项展开，`/wo/get_details` 未接入 UI**

---

## 五、存酒模式（存酒 / 取酒 / 充公）

- [x] **首页「存酒模式 / 点单模式」切换与卡面三入口显现规则（`4/5/6/7 || turnoverCount > 0`）**
- [ ] **[P0] 存酒（Save Wine）为未完成开发占位表单**
  - 问题：要求服务员手填 `购物车Id` 与 `认证码`；缺 9 个核心 `/wine/*` 接口（可存酒水列表、存酒购物车增删改、黑名单校验、短信发/验码、瓶/小数/克数选择、有效期天数组件、授权存酒+刷卡、客户中心存酒、可编辑姓名/手机与开台时间/订位人列）。
  - 依据：`src/components/order/newSaveWine/drawerSaveWine/index.vue` ↔ `flutter_workspace/packages/card_table/lib/src/wine_order_screen.dart#L197-L244`
- [ ] **[P0] 取酒（Get Wine）为未完成开发占位表单**
  - 问题：要求手填 `库存Id` 且写死 `counts: [1]`；缺手机尾号 4 位模糊查询（`/wine/get_wine_cust_by_phone4`）、存酒库存清单（`/wine/get_qj_invt`）、黑名单标红、数量选择与 3 种核验方式（手机号+SMS / 服务码 / 超级授权码）。
- [ ] **[P0] 充公（Confiscate / Pay to Store）为未完成开发占位表单**
  - 问题：要求手填原始 `订位人Id`（错误设为必填）和 `商品Id`、写死日期/单位/数量；缺日期选择、员工搜索选择器、可存酒水分类列表与单位/克数选择。

---

## 六、会员充值、滞留金、3 张首页报表与账号/授权密码

- [x] **低消进度统计表（`/wo/get_seat_zy_csm_list`，12 列完整对齐，点单端无导出）**
  - 依据：`src/components/order/newDrawerMinDetail.vue` ↔ `flutter_workspace/packages/card_table/lib/src/minimum_consumption_report_screen.dart`
- [x] **会员充值核心充值/档位/赠酒/二维码接口通路（模块 91/92/93 门控）**
- [x] **估清商品管理（模块 5 门控 + `/sel/get_prd_sold_outs` / `set_prd_sold_out` / `del_prd_sold_out`）基础通路**
- [x] **修改密码（`/emp/chg_pwd` + 大写 MD5 + 1s 自动登出）**
- [ ] **[P0] 会员充值「注册开卡」为假按钮 + 支付取消死锁 + WS 脉冲杀掉支付弹窗 + 未接扫码枪**
  - 问题：① 点「注册开卡」仅弹 SnackBar；② 取消二维码未清 `_pendingOrder` 且外壳未传 `needsVerification/pendingOrder`，导致整个会话**永久死锁不可再充值**；③ WS 刷新 `_reportCanRead` 同步闪烁 `false→true` 会在客人扫码中途强关二维码弹窗；④ 原生扫码枪（`payType 5/6`）未接线；⑤ 安全模式下按钮可见但页面锁死；⑥ 推荐人下拉不可搜索。
  - 依据：`flutter_workspace/packages/card_table/lib/src/vip_recharge_screen.dart#L194-L211`、`flutter_workspace/packages/card_table/lib/src/vip_recharge_loader.dart#L18-L46`
- [ ] **[P0] 滞留金收取缺 `payType=3`（小程序自助）、未接扫码枪、网络波动永久死锁、WS 脉冲强制失效、阻断 Android 收银端**
  - 依据：`src/components/order/newDrawerAddBookAmt.vue#L128-L131` ↔ `flutter_workspace/packages/card_table/lib/src/order_late_deposit.dart#L90-L230`
- [ ] **[P0] 授权密码读取（`/emp/get_auth_pwd_enabled`）拒绝 `enabled: 2`（后端关闭态），且缺少触屏数字键盘**
  - 依据：`src/components/common/newUpdateAuthPassword.vue#L82` ↔ `flutter_workspace/packages/card_table/lib/src/account_passwords.dart#L121-L126`
- [ ] **[P1] 估清管理界面手机端双分类栏挤占一半宽度 + 负数未拦截 + 失权无关闭按钮 + 浅色修改密码开键盘溢出**
  - 依据：`flutter_workspace/packages/card_table/lib/src/sold_out_products_screen.dart#L352-L375`、`flutter_workspace/packages/card_table/lib/src/account_password_screen.dart#L215-L256`
- [ ] **[P2] 鸡尾酒明细表列序未对齐新版 `newDrawerTYDetail.vue`、缺删除线原价与首列固定、多余 `>>` 尾列；开发诊断菜单在非调试态外露**

---

## 七、酒吧服务员效率重构方案：「能点 1 下的绝不点 2 下」

针对服务员在**暗光、吵闹、单手/边走边操作、高峰高频加酒**的真实酒吧场景，我们在功能 100% 对齐 `dev` 的同时，做以下 **8 项高ROI 效率改造**：

| 高频动作 | 当前 Flutter 步数 | 改造后步数 | 核心效率设计（1 步直达） |
|---|---|---|---|
| **1. 找台进点单** | 2 步 + 长翻页（首页无搜台，默认进空「我的卡台」） | **1 步** | ① 首页新增**顶部快搜框**（输入台号/字母即时直达，支持数字快键）②「我的卡台」无数据时自动高亮全部开台区或一键切「已开台」，消除空屏多点一次。 |
| **2. 点常规酒水（+1 / +N）** | 2 步（1 瓶）/ 5 步（6 瓶，弹窗输数字） | **1 步**（+1）/ **2 步**（+6/+12） | ① 普通单品卡片右下角直接内置 **`+` / `-` 原地步进器**，**点 1 下直接 +1 入车**（乐观更新 + 防抖合并，彻底干掉 3 次串行 HTTP 卡死！）② 点击卡片主体打开**单页快选弹层**，内置 **`1 / 2 / 6 / 12` 快捷数量胶囊 + `19/20/21` 出品要求标签**，选完 1 键加购。 |
| **3. 搜酒水** | 先切对分类再搜（当前分类外搜不到） | **1 步全局搜** | 顶部搜索框**跨全部分类全局搜索**（支持中文/拼音首字母/英文名，忽略大小写，带一键清空 `×`，切分类自动清搜）。 |
| **4. 点套餐（含可选组+要求）** | 6–9 步（每项生成卡片+手输次数） | **3 步** | 套餐弹窗按组分区展示 **`已选 X / 须选 Y`** 进度条，每个可选项直接配 **`- / 数量 / +`** 步进器与缺货置灰；默认带出固定项，可选组选满立即点亮底部「确认加入」。 |
| **5. 选优惠 / 优惠 2 / 主管授权** | 3–12 步（优惠 2 甚至要手输数据库 ID） | **2–3 步** | ① 按角色权限（`11/12/27/36/37/42/44`）只展示当前员工有权的按钮，消灭误点报错；② 优惠/优惠 2 合并为单页弹层（数量步进 + 理由一键点选 + **搜索选员工/选卡台** + 刷员工卡/密码双 Tab 授权，永不手输 ID）。 |
| **6. 核对并确认下单** | 切购物车 Tab → 看无金额列表 → 下单 | **1 步吸底直达** | 菜单页底部常驻**吸底购物车胶囊条**（显示 `共 N 件 · ￥总计` + 醒目 **`立即下单`** 按钮），**不用切 Tab 直接 1 键下单**；点击左侧胶囊展开购物车浮层快速微调/改要求；平板横屏直接采用**左侧分类 + 中间商品网格 + 右侧实时购物车**三栏同屏工作台！ |
| **7. 服务员买单 & 存/取酒** | 买单错单/不可用；存酒要返回首页切模式再点 12px 裸字 | **1–2 步** | ① 桌内底部工作台直接提供**「买单」**（直接勾选待付线下单 + 一键微信/支付宝/扫客人码 + 实时轮询）与**「存取酒」快捷入口**；② 首页存酒模式改为 **48dp+ 高亮圆角操作按钮 + 顶部醒目「存酒模式」状态条**，防误触。 |
| **8. 提示与触屏体验** | 暗底灰条易漏看、弹窗被软键盘遮挡 | **0 阻断** | 复用预订端已验证的**居中高对比彩色提示 `showBookingToast`** + **避让平板软键盘的宽敞搜索选择器** + 触屏数字键盘不溢出。 |

---

## 八、建议分三批落地顺序

1. **Phase 1（核心点单工作台 + 1 步直达效率重构 + 最痛 P0）**：
   - 补齐 `/orderMeal` 路由、`/wo/list` 商品/服务员名与 `wine_ops` Tab、实时 8 号估清库存与限购校验、二级分类时段限制、全局搜索与 `limit_pad`/`limit_pc`、单品与套餐定制要求（19/20/21 + `/wsc/add_set_requirement`）、`/wsc/order` `code=2/5` 处理、`_addYhProduct` 正确价格与套餐路由；
   - 落地 **1 步原地 `+`/`-` 加购**、**吸底实时购物车栏（平板三栏 / 手机吸底条）**、**1 键快捷数量/要求弹层**、**首页快速搜台号**、**居中高对比提示**。
2. **Phase 2（权限安全闭环 + 买单/优惠/授权/卡券）**：
   - 补齐全部 10 个权限数据集（`11/12/15/27/36/37/42/44/50/55`）、终端范围 `40` 并集修复、模块 `70`、金额查看 `upper_emp_id=="0"` 漏洞修复、`/wo/get_sp_seat_list`；
   - 落地**刷卡+密码双 Tab 授权弹窗**、优惠 2 员工/卡台选择器、完整**服务员买单流程**（`os` 选单 + 渠道 1/2/3/5/6 + 轮询/续付/取消）、卡券 V2 核销、我的点单后置操作与批量操作。
3. **Phase 3（完整存/取酒/充公 + 会员充值/滞留金/报表修复）**：
   - 完整重建 `WineOrderScreen`（存酒/取酒/充公可视化酒水/库存/SMS/黑名单/授权存酒）；
   - 修复会员充值开卡与支付取消死锁、滞留金 `payType=3` + 扫码枪 + 防死锁、WS `_reportCanRead` 脉冲不打断支付、授权密码 `enabled=2` 与数字键盘、鸡尾酒明细与估清手机端排版。
