# Flutter 移植看板

> 看板服务：`http://127.0.0.1:8791/`（`node docs/flutter-migration/board/server.js`）。页面改状态会立刻写入本文件和 `board/tasks.json`。
>
> 代理人改状态：`node docs/flutter-migration/board/sync-board.js --set ID=状态`
> 验收人确认：看板页勾选，或 `--set ID=已确认 --allow-confirm`。代理人不得代标已确认。
>
> 统计：共 305 项；未开始 4 · 入口已列·待接入 0 · 已编码·未确认 298 · Web已接线·Android待接线 0 · 已确认 2 · 不移植 1

## M0 横切底座

对照：登录 / 同步 / 设备 / 三端壳  ·  20 项  ·  已确认 0  ·  已编码未确认 19  ·  未开始 1

### M0.P1 终端授权与员工登录

- [ ] **M0.P1.T01 终端授权码换会话** `已编码·未确认`
  - Vue: `src/views/Thelogin/Thelogin.vue`；API `POST /term/auth`（见 `UtilAuth/term`）
  - Flutter: `packages/session/` + 三端 `main.dart` 授权码输入
  - 完成: 错误码/文案与 Vue 一致；失败不写入凭据
  - 备注: [2026-09-20 续轮修复] 原版9种终端均进入开发代理allowlist并按原register映射授权；Android直连开发映射对齐，生产授权约束不变。会员真实授权已到登录页；登录前可切换系统。 详见2026-09-20-parity-round2.md。
  - 分组: 
- [ ] **M0.P1.T02 工号密码登录** `已编码·未确认`
  - Vue: `Thelogin.vue`；API `POST /auth/login`
  - Flutter: `SessionRepository` / `SessionApi`
  - 完成: `tk`/`stk`/`tt` 写入安全存储；角色进入系统选择
  - 备注: [2026-09-20 源码差异审计] 实页核对：原系统9个选择含会员及两种ERP角色；Flutter为8项，缺会员独立入口且合并ERP。原点单登录页版本1.0.202609181250尚待用户登录，不能宣称登录业务闭环通过。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 续轮修复] 新增会员独立登录落地；ERP仓库管理员与ERP管理员保留不同client/tt和默认落地；BMS进入工号规则页。两端生命周期测试覆盖。角色菜单权限仍另行对照，不能视为全系统验收。 详见2026-09-20-parity-round2.md。
  - 分组: 
- [ ] **M0.P1.T03 退出登录清会话** `已编码·未确认`
  - Vue: 各卡台页「退出登录」
  - Flutter: `card_table_screen.dart` 账户菜单 + `SessionRepository`
  - 完成: 清凭据、停 WebSocket、回到登录
  - 分组: 
- [ ] **M0.P1.T04 修改登录密码** `已编码·未确认`
  - Vue: 账户菜单「修改密码」；API `POST /emp/chg_pwd`（`src/api/BMS/emp/index.js`）
  - Flutter: `account_password_screen.dart` / `account_passwords.dart`；三端 `changePassword`
  - 完成: 旧密+新密校验、成功文案、失败关闭；Win/Web/Android 均接线
  - 备注: [2026-09-20 源码差异审计] BMS 改密原先无请求却提示成功；本轮移除假成功并明确尚未接入。收银已有改密链路不能代表BMS入口已完成。证据 bms_nav_screen.dart:188。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 第三轮] BMS/ERP已复用真实/emp/chg_pwd回调，源ManagementSystem成功仅清空关闭不退出；原点单重登行为保留。异常可重试、旧结果不误关新路由，关闭清敏感输入。Web/Android主入口已注入，未真实改密码；Windows仍待接线。 详见2026-09-20-parity-round3.md。
  - 分组: 
- [ ] **M0.P1.T05 授权密码开关** `已编码·未确认`
  - Vue: 点单/收银账户菜单「授权密码」
  - Flutter: `account_passwords.dart`；`authPasswordEnabled` / `changeAuthPassword`
  - 完成: 预定系统不出现该项；点单/收银与 Vue 一致
  - 备注: [2026-09-20 续轮核验] 两端点单/收银已真实接线，预定不展示。核对旧版API与密码散列合同；读取状态未就绪/失败或非法enabled禁止提交，可重试；迟到成功不关闭后来页面，NaN按旧版拒绝。自动化通过，未执行真实密码变更。
  - 分组: 
### M0.P2 实时同步与权限

- [ ] **M0.P2.T01 WebSocket /sync 连接/心跳/重连** `已编码·未确认`
  - Vue: `src/websocket/websocket.js`；API `POST /sync_base/all`、`/sync_base/increment`
  - Flutter: `packages/realtime_sync/` + `card_table_event_feed.dart`
  - 完成: `blocked`/`reconciling`/`online` 三态；写操作在非 `online` 失败关闭
  - 备注: [2026-09-20 操作作用域轮] 点单/收款各写入口加入当前营业日/翻台/在线作用域，正常4→5不锁页，旧异步尝试不复活，pending请求不因重连提前解锁；当前14推送自动刷新订单/汇总/购物车并合并读取。全套1010通过，详见2026-09-20-operation-scope.md。
  - 分组: 
- [ ] **M0.P2.T02 岗位模块权限 13/41 与安全模式 54** `已编码·未确认`
  - Vue: Vuex `userInfo` / `cardPageInfo.resResultDataObj`
  - Flutter: `packages/permissions/` + `legacy_card_table_store.dart`
  - 完成: 缺失/损坏元数据不默认放行；安全模式隐藏点单/收银「更多」，不隐藏预定更多、充值、存酒入口
  - 备注: [2026-09-20 第三轮] 管理端独立归一化dataset13/41/54，不依赖卡台14/18；BMS安全人员、ERP client/module25、普通Wine菜单按源metadata。未知/离线隐藏，已核验同账号基线在成功增量对账后恢复；坏数据仍须完整快照。A→B直接登录停止旧同步并重建、关闭旧管理路由，3Nav按用户identity重建。BMS/Wine/ERP全路径隔离；全项目其它业务权限仍待逐页实测。 详见2026-09-20-parity-round3.md。 [2026-09-20 本轮闭环] BMS/Wine/ERP直属菜单已区分在线会话与角色资料完整性；扩展授权仍要求资料完整，人员安全模式不放开。三系统手机抽屉导航已接，离线卸载业务内容。
  - 分组: 
- [ ] **M0.P2.T03 营业日开启/关闭状态** `已编码·未确认`
  - Vue: `POST /wkd/get`、`/wkd/start`；`src/api/Book/index.js`
  - Flutter: `business_day_api.dart`；预定可开营业日，点单/收银仅提示联系咨客
  - 完成: 未开业空台菜单与 Vue `getCardOptions` 一致
  - 分组: 
### M0.P3 设备

- [ ] **M0.P3.T01 HID 扫码（Win/Android）** `已编码·未确认`
  - Vue: `src/mixin/swipingCard.js`
  - Flutter: `device_bridge_platform_interface` + windows/android 实现
  - 完成: 回车结束、防抖；业务页真正吃码在各支付/会员叶任务中验收
  - 分组: 
- [ ] **M0.P3.T02 测试小票打印** `已编码·未确认`
  - Vue: 各 `prt_*` 接口
  - Flutter: `device_bridge_*` PrinterService
  - 完成: Win 队列/ESC-POS；Web 浏览器打印降级；打印失败不回滚已成功支付
  - 分组: 
- [ ] **M0.P3.T03 相机扫码（仅 Android 无外设兜底）** `已编码·未确认`
  - Flutter: `device_bridge_android`；Web 不承诺静默 USB
  - 分组: 
- [ ] **M0.P3.T05 桌面客户端原生图片选择与上传验收** `已编码·未确认`
  - Vue: BMS/uploadProImg
  - Flutter: 桌面客户端壳及图片picker适配
  - API: 沿用图片上传合同
  - 备注: Web file input与Android SAF已接；Windows/macOS原生文件选择未实现，不能据跨端Dart视图存在宣称桌面上传已验收。 [2026-09-22 其他agent增量核验与修复] 已核实Windows runner中有ProductImagePicker C++及MethodChannel接线，静态检查未发现确定P1/P2；Windows真实编译/原生选图未验证，macOS实现仍缺。不能由Dart测试通过推断桌面上传完成。
  - 分组: 
- [ ] **M0.P3.T04 员工卡原生读卡与授权结果接入** `未开始`
  - Vue: src/mixin/swipingCard.js; order/myOrder/drawerMyOrder.vue getCodeAndPwd
  - Flutter: device_bridge_* 与授权弹窗
  - API: 读取cardNo/password后pass_type=2，密码沿原协议MD5大写
  - 完成: 从真实设备取得卡结果并传业务授权，不以手工输入冒充硬件支持；取消监听、身份隔离、敏感信息不日志；Windows/Android分别验证
  - 备注: 2026-09-20新增明确剩余范围：退单已提供账号授权及已有卡码输入，但当前无真实员工卡读取接线，不能与普通HID扫码完成状态混淆。需按原输入协议确认可复用HID或其他原生读卡能力。
  - 分组: 授权设备
### M0.P4 三端壳

- [ ] **M0.P4.T01 Windows 壳接入 CardTableScreen** `已编码·未确认`
  - Flutter: 参照 `web_app/lib/main.dart` 的 `ShellDependencies`，接到 `apps/windows_app/lib/main.dart`
  - 完成: Windows 能登录并进入预定/点单/收银卡台页，与 Web 同一套回调
  - 备注: （当前 `windows_app` 未 import `card_table`） [2026-09-20 源码差异审计] Windows 未接新增 BMS/ERP/Wine/SuperAdmin 导航与报表读接口；Web/Android代码存在不等于三端交付。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 其他agent增量核验与修复] 已核实其他agent增加了CardTableScreen及部分营业日回调，旧“未import card_table”说明已过时；本轮补同账号登录identity、旧路由清理及在线/代际保护。Windows点单、收款、开启营业日等大量业务回调仍未接齐，保留待接入；无Windows原生编译运行验收。 [2026-09-22 共享业务壳增量复核] Android/Windows已改用native_client_shell共享业务入口并注入各自设备服务，保留权限、会话与营业日保护；Windows不再仅有卡台骨架。Windows生命周期widget 12项、Android 23项通过；Windows原生编译、硬件及九系统实际运行尚未验收。
  - 分组: 
- [ ] **M0.P4.T02 Web 开发代理 --no-pub** `已编码·未确认`
  - Flutter: `flutter_workspace/tool/web_dev_runner.js` → `http://127.0.0.1:8183/`
  - 分组: 
- [ ] **M0.P4.T03 Android 业务回调与 Web 对齐** `已编码·未确认`
  - API: （报表/排队等 Android 缺）
  - 完成: Web 已有的 loader，Android 同等声明并传入 `CardTableScreen`（Android 台账未批准的功能除外）
  - 备注: （报表/排队等 Android 缺） 对照: `web_app/lib/main.dart` `ShellDependencies` vs `android_app/lib/main.dart` [2026-09-20 源码差异审计] Android模拟器已启动；新版构建曾被旧全局7890代理拒绝，目前尝试临时Gradle home，尚无新版运行验收证据。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 最终验证补充] Web/Android报表online/session/generation回调和转单已接线，8文件60/60测试通过；全仓静态分析无error/warning但INFO140。临时Gradle home下载Gradle成功后，Kotlin2.2.21依赖仍遭TLS handshake终止，APK未构建完成。 [2026-09-20 续轮修复] Android源代码已接9类终端、VIP入口、BMS会话守卫及Wine导出。全工作区745测试通过但不是Android端侧验收；APK仍被Gradle/Kotlin依赖TLS下载阻断。 详见2026-09-20-parity-round2.md。 [2026-09-20 第三轮] Web/Android均接管理权限feed、同一导航observer和真实改密；双端集成测试覆盖实时安全模式、直接换员工、旧改密表单清理、跨系统URL拒绝。全工作区801测试通过，不代表Android APK已运行验收（构建依赖网络仍阻断）。 详见2026-09-20-parity-round3.md。 [2026-09-20 最新运行验证] 早期Gradle阻断已解决；本轮Android APK构建、安装emulator-5554并启动成功，Web同步更新。全套1010测试通过，不等同所有业务人工验收；尚未完成项见后续对照文档。
  - 分组: 
### M0.P5 价格方案与金额一致性

- [ ] **M0.P5.T01 历史成交价与赠送金额快照** `已编码·未确认`
  - Vue: src/utils/orderItemPrice.js
  - Flutter: packages/card_table/lib/src/pay_order_models.dart; order_meal.dart; pay_order_screen.dart
  - API: pp / p2 / pa / pc / at
  - 完成: 整行用历史pa；拆分用p2回退pp；显式0有效；pp=0仍为时价；at=2/3小计0；退款不按现行方案重算
  - 备注: 2026-09-20：历史pp/p2/pa/pc/at、显式0、缺pc与0区分、时价及赠送金额模型已对齐；历史不受实时方案重算，专项回归通过。退款接口完整授权与分类规则仍属S2.P4.T02/S3.P2.T03，不代表真实退款已闭环。
  - 分组: 价格一致性
- [ ] **M0.P5.T02 价格方案58/59实时元数据** `已编码·未确认`
  - Vue: src/utils/transformCardData.js; src/websocket/websocket.js
  - Flutter: packages/card_table/lib/src/fc_price.dart; legacy_card_table_store.dart
  - API: 58 [prd_id,plan_id,pay_amt,status]; 59 [plan_id,emp_id,status]
  - 完成: 完整/增量复合键更新、status过滤、会话隔离；区分缺数据与无方案
  - 备注: 2026-09-20：58/59复合键全量/增量、状态失效、显式零价、未知与合法空数据区分及回放已编码；8项专项测试通过。旧卡台快照仍可展示，未知方案禁止新增的页面接线另属M0.P5.T03；尚待双端人工确认。
  - 分组: 价格一致性
- [ ] **M0.P5.T03 新点单员工方案选价与请求** `已编码·未确认`
  - Vue: src/utils/fcPrice.js; src/components/order/fcPriceMixin.js
  - Flutter: packages/card_table/lib/src/fc_price.dart; order_meal_screen.dart; card_table_screen.dart
  - API: /wsc/add_prd; /wsc/add_hl
  - 完成: 授权人优先且不回退点单人方案；合法0保留；不同商品/接口使用原prd_price或prd_amt规则
  - 备注: 2026-09-20：实时方案加购、0价、未知门禁、身份失效及各类型字段已接线，历史不重新定价。用户截图另发现缺原价展示，已补灰色划线原价+红色方案价、同价/无方案不重复及实时变价；35项点单页测试通过，已更新Web及安装Android。仍待用户实页确认，不把此前金额测试等同展示验收。
  - 分组: 价格一致性
- [ ] **M0.P5.T04 点单与收银pay_info四项汇总** `已编码·未确认`
  - Vue: src/utils/orderSummary.js
  - Flutter: packages/card_table/lib/src/order_meal.dart; order_meal_loader.dart; order_meal_screen.dart; pay_order_models.dart; pay_order_api.dart; pay_order_screen.dart
  - API: /wo/list pay_info（整数分）
  - 完成: 折前=discount_amt+order_amt；赠送=yh_amt；优惠=discount_amt+payed_free_amt；未结=order_amt-payed_amt；与本次勾选应收分开
  - 备注: 2026-09-20：四项pay_info汇总接入点单/收银，两main与会话守卫接线；缺pay_info显示--，过期结果丢弃，PC营销组合隐藏。续轮将旧底栏单独接/wo/chk_order_can_see和metadata56督查区域，身份/权限变化撤销旧结果，保留宽窄安全模式差异，不混用新摘要条件。人工验收待做。
  - 分组: 价格一致性

## S1 预定系统

对照：src/router/book/index.js  ·  37 项  ·  已确认 0  ·  已编码未确认 36  ·  未开始 0

### S1.P1 `/cardMachine` 卡台信息

- [ ] **S1.P1.T01 日期栏 / 区域 / 搜索 / 图例** `已编码·未确认`
  - Vue: `cardMachine.vue` `canDoList` 日期、区域、搜索（卡台/客人/手机/订位人）
  - Flutter: `card_table_screen.dart`、`card_region_selector.dart`
  - 完成: 默认「全部」；搜索字段与 Vue 一致；营业日未开仍可看台
  - 分组: 
- [ ] **S1.P1.T02 卡台点击菜单定位在卡片旁** `已编码·未确认`
  - Vue: 菜单宽 172px、色 `#08080A` / `#32b9ff`，相对卡片偏移
  - Flutter: `showGeneralDialog` + `_CardMenuLayoutDelegate`（禁止再改回 BottomSheet）
  - 完成: widget 测试点 `CardTableScreen.cardMenuKey`
  - 分组: 
- [ ] **S1.P1.T03 菜单可见性 1:1 getCardOptions** `已编码·未确认`
  - Vue: `cardMachine.vue` 约 1206 行；选项 id 见 `src/utils/config/card.js`
  - Flutter: `card_table_screen.dart` 组菜单逻辑
  - 完成: 状态 1/2/4/5/6/7/8 × 线上/线下 × 置顶 × 清台权限 × 取消必点灰显 与 Vue 相同；线上预留不出现「取消预留」
  - 分组: 
- [ ] **S1.P1.T04 预留（空台 id=1）表单** `已编码·未确认`
  - Vue: `src/components/book/reserved/drawerReserved.vue`；`POST /bk/batch_new`（不是 `/bk/new`）
  - Flutter: `_CardForm.reserve`；`BookingCardWriteAction.createReserve`
  - 完成: 手机号非空必须 11 位「请输入正确的手机号」；`book_day` yyyy-mm-dd；`is_this_wkday` 首日=1 否则=2；成功「新增成功」
  - 分组: 
- [ ] **S1.P1.T05 开台（空台 id=2）表单** `已编码·未确认`
  - Vue: 开台表单；空台 `POST /bk/direct_open` `{seat_id,...}`
  - Flutter: `_CardForm.open`；`openEmpty`
  - 完成: 人数 &lt;1 拦截；成功「开台成功！」
  - 分组: 
- [ ] **S1.P1.T06 预定开台（预留台 id=2）** `已编码·未确认`
  - Vue: `POST /bk/open` `{id: bookId,...}`；线上订台确认文案「线上订台{name}，开台后不能撤台，是否确认开台？」
  - Flutter: `openReserve`
  - 完成: 确认框文案与 body 字段 1:1
  - 分组: 
- [ ] **S1.P1.T07 修改预留（id=8）** `已编码·未确认`
  - Vue: `POST /bk/get` 拉详情，`POST /bk/save` 保存
  - Flutter: `getBookDetail` / `BookingBookDetail.fromWire`；`updateReserve`
  - 完成: 成功「修改成功」；`second_sales_name` 发字符串（Vue 有 `Number(...)` 的 bug，不要复刻）
  - 分组: 
- [ ] **S1.P1.T08 锁定 / 取消锁定（id=5/6）** `已编码·未确认`
  - Flutter: `lock` / `unlock`
  - API: `POST /bk/lock`、`/bk/unlock`
  - 完成: 确认文案与 Vue `showConfirmHandle` 一致
  - 分组: 
- [ ] **S1.P1.T09 撤台（id=12）** `已编码·未确认`
  - Flutter: `cancelOpen`
  - API: `POST /bk/cancel_open`
  - 分组: 
- [ ] **S1.P1.T10 取消预留（id=15，仅线下）** `已编码·未确认`
  - Flutter: `cancelReserve`
  - API: `POST /bk/cancel`
  - 分组: 
- [ ] **S1.P1.T11 置顶 / 取消置顶（id=18/19）** `已编码·未确认`
  - Flutter: `pin` / `unpin`
  - API: `POST /bk/top_seat_dsp`、`/bk/cancel_top_seat_dsp`
  - 分组: 
- [ ] **S1.P1.T12 取消必点（id=24）** `已编码·未确认`
  - Flutter: `disableMustOrder`；无必点商品或 business[37] 时灰显
  - API: `POST /bk/disable_csm_must_ord`
  - 分组: 
- [ ] **S1.P1.T13 修改低消（id=10）** `已编码·未确认`
  - Flutter: `updateMinConsume`
  - API: `POST /bk/chg_csm_mca`
  - 分组: 
- [ ] **S1.P1.T14 修改订位人（id=11）** `已编码·未确认`
  - Flutter: `updateSales`
  - API: `POST /bk/chg_sales`
  - 分组: 
- [ ] **S1.P1.T15 修改卡台标记（id=20）** `已编码·未确认`
  - Flutter: `updateMark`
  - API: `POST /bk/set_seat_mark`；标记列表 dataset 31
  - 分组: 
- [ ] **S1.P1.T16 修改备注（id=21）** `已编码·未确认`
  - Flutter: `updateRemark`
  - API: `POST /bk/chg_open_seat_remark`
  - 分组: 
- [ ] **S1.P1.T17 修改服务员（id=23）** `已编码·未确认`
  - Flutter: `updateWaiter`
  - API: `POST /sel/chg_csm_waiter`
  - 分组: 
- [ ] **S1.P1.T18 查看卡台详情（id=14）只读** `已编码·未确认`
  - Vue: 详情弹层；Flutter: 只读 dialog，无写
  - 分组: 
- [ ] **S1.P1.T19 清台（id=16）** `已编码·未确认`
  - Vue: 已结 + `showAmt` id=5 `param1==2`；`POST /sel/seat_clean`
  - Flutter: `clearSeat`；`canClearSeat`
  - 分组: 
- [ ] **S1.P1.T20 转为线下卡台（id=17）** `已编码·未确认`
  - Vue: 空台且 `showOnlineText`；`POST /bk/conv_ol_seat_local`
  - Flutter: `convertOffline`
  - 分组: 
- [ ] **S1.P1.T21 转台（id=7）开台/预留** `已编码·未确认`
  - Flutter: `_CardForm.transfer`；`transferOpen` / `transferReserve`
  - API: `POST /bk/chg_csm_seat`（开台）、`POST /bk/chg_seat`（预留）
  - 分组: 
- [ ] **S1.P1.T22 修改翻台订位人（id=4）历史表** `已编码·未确认`
  - Vue: `turnoverCnt==0` 先警告「当前卡台没有翻过台！」；有翻台则 `POST /bk/get_his_sales` 列表、`POST /bk/chg_his_sales` 保存
  - Flutter: 零翻台警告已做；缺历史表 UI
  - 完成: 表格列/保存字段与 Vue 一致
  - 分组: 
- [ ] **S1.P1.T23 复台（id=25）** `已编码·未确认`
  - Vue: `POST /sel/get_seat_turnback_list`、`POST /sel/seat_turn_back`；组件 `src/components/money/drawerChooseTurnback.vue`
  - Flutter: 菜单项已画，写入未接
  - 完成: 仅空台+有可复流水；成功后刷新卡台
  - 分组: 
- [ ] **S1.P1.T24 查看消费明细（id=26）** `已编码·未确认`
  - Vue: `src/components/book/machine/bookingDetailDialog.vue` mode=`consumption`
  - 完成: 只读列与 Vue 一致，不在此页做退款
  - 分组: 
- [ ] **S1.P1.T25 查看存取酒明细（id=27）** `已编码·未确认`
  - Vue: 同上 mode=`wine`
  - 分组: 
- [ ] **S1.P1.T26 多台预留加台（id=22）** `已编码·未确认`
  - Vue: `drawerReserved.vue` + `src/components/book/reserved/chooseCard.vue`
  - API: 仍走 `POST /bk/batch_new`（多 `seat_id`）
  - 完成: 可勾选多个空台一次提交
  - 分组: 
- [x] **S1.P1.T27 修改开台类型（id=13）** `不移植`
  - API: `POST /bk/chg_open_type`
  - 分组: 
- [ ] **S1.P1.R01 开台记录** `已编码·未确认`
  - Vue: `src/components/book/machine/drawerOpenCard.vue`
  - Flutter: `SeatOpenLogRow`；Web `loadSeatOpenLog`
  - API: `POST /sel/rpt/get_seat_open_log`；导出 `POST /sel/rpt/exp_seat_open_log`；筛选项 `POST /bk/get_seat_open_log_params`
  - 完成: 列顺序/筛选/导出与 Vue 一致；Android 同样接线（若台账批准）
  - 分组: 
- [ ] **S1.P1.R02 转台记录** `已编码·未确认`
  - Vue: `src/components/book/machine/fullPageZTOrder.vue` / `cardDrawerZTOrder.vue`
  - API: `POST /bk/get_chg_seat_log`
  - 分组: 
- [ ] **S1.P1.R03 预留记录** `已编码·未确认`
  - Vue: `src/components/book/machine/drawerReservedRecord.vue`
  - API: `POST /sel/rpt/get_book_list`；导出 `/sel/rpt/exp_book_list`
  - 分组: 
- [ ] **S1.P1.R04 线上预订记录** `已编码·未确认`
  - API: `POST /sel/rpt/get_ol_book_list`（收银侧同接口，预定入口单独接）
  - 分组: 
- [ ] **S1.P1.R05 入客数据实时汇总** `已编码·未确认`
  - Vue: `src/components/book/machine/drawerSeatOpening.vue`
  - API: `POST /sel/rpt/get_seat_opening_list`；导出 `/sel/rpt/exp_seat_opening_list`
  - 分组: 
- [ ] **S1.P1.R06 部门实时订台/区域开台** `已编码·未确认`
  - Vue: `src/components/book/machine/drawerDeptRegionSeatOpen.vue`
  - API: `POST /sel/rpt/get_dept_region_seat_open_list`；导出 `/sel/rpt/exp_dept_region_seat_open_list`
  - 备注: 规格: `docs/superpowers/specs/2026-08-10-dept-region-seat-open-report-design.md`
  - 分组: 
- [ ] **S1.P1.R07 排队详情（叫号/到店/过号）** `已编码·未确认`
  - Vue: `src/components/book/machine/drawerQueue.vue`
  - Flutter: `booking_queue.dart` / `booking_queue_screen.dart`；Web `queueCall`/`queueArrive`/`queueExpired`
  - API: `POST /custq/call`、`/custq/arrive`、`/custq/expired`；导出 `/custq/exp_cust_queue_list`
  - 分组: 
### S1.P2 `/reserved` 预留信息

- [ ] **S1.P2.T01 当日预留 / 其它预留两个 Tab 列表** `已编码·未确认`
  - Vue: `reserved.vue` tabs；`tabContent.vue`
  - Flutter: 新建 `booking_reserved_screen.dart` + loader；三端路由挂 `/reserved`
  - API: 预留列表走 Book 预留查询（以 `tabContent.vue` 内实际 POST 为准，执行时抄 path/body）
  - 完成: 两 Tab 数据源、行字段、点行进修改预留与 Vue 一致
  - 备注: [2026-09-28 闭环对齐] 解决2026-09-22复审缺口：ProtocolBookingCardApi.getReservedList 已接入多格式预留时间解析（parseBookingDateTime）与精准日期过滤体系（matchesBookingDateFilter），彻底隔绝当日（isToday=true）、明天（futureType=1）、未来7天（futureType=2）、全部（futureType=3）数据；补齐 ResGetBookListItem 与 /bk/* 报表字段映射；12项 API 单元测试与 3 项页面交互单测全量通过。
  - 分组: 
- [ ] **S1.P2.T02 从预留页回预订管理** `已编码·未确认`
  - Vue: 「预订管理」→ `/cardMachine`
  - 分组: 
- [ ] **S1.P2.T03 预留页修改密码/退出** `已编码·未确认`
  - 备注: 复用 M0.P1.T03/T04，不要复制一套会话逻辑
  - 分组: 

## S2 点单系统

对照：src/router/order/index.js  ·  39 项  ·  已确认 2  ·  已编码未确认 37  ·  未开始 0

### S2.P1 `/orderCard` 点单卡台首页

- [ ] **S2.P1.T01 浅色主题、默认「我的卡台」、无日期栏、无搜索** `已编码·未确认`
  - Vue: `newOrderCard.vue` + `style/order/newOrderCard.less`
  - 完成: 「我的卡台」= dataset14[14] 订位人或 14[20] 历史服务员精确匹配登录员工
  - 分组: 
- [ ] **S2.P1.T02 区域选择（含「其它」溢出）** `已编码·未确认`
  - Flutter: `card_region_selector.dart`
  - 分组: 
- [ ] **S2.P1.T03 空台/锁台/预留不可点单提示** `已编码·未确认`
  - 完成: 正常模式点击开台进入点单；不要弹出存取酒菜单
  - 分组: 
- [ ] **S2.P1.T04 存酒模式入口（模块 1）** `已编码·未确认`
  - Vue: 存酒模式才展示存/取/充公；`src/components/order/newSaveWine/**`
  - 完成: 非存酒模式绝不出现这三项
  - 分组: 
- [ ] **S2.P1.T05 会员充值入口（模块 91/92/93 任一）** `已编码·未确认`
  - Vue: `src/components/order/vipRecharge/drawerVipRecharge.vue`
  - Flutter: `vip_recharge.dart` / `vip_recharge_screen.dart` / loader
  - 完成: 搜卡、规则、下单、支付、轮询与 Vue 字段一致（充值闭环细节见 S2.P1.T06）
  - 分组: 
- [ ] **S2.P1.T06 会员充值支付与状态轮询** `已编码·未确认`
  - 完成: 与 Vue 成功/失败弹窗一致；断网禁止下单
  - 备注: 对照 `vip_recharge.dart` 现有 `createVipOrder` / `createVipPay` / `pollVipOrderStatus`
  - 分组: 
- [ ] **S2.P1.T07 底部更多：低消进度统计表** `已编码·未确认`
  - Vue: `src/components/money/newDrawerMinDetail.vue`
  - Flutter: `minimum_consumption_report*.dart`
  - API: `POST /wo/get_seat_zy_csm_list` 无 query/body
  - 完成: 12 列与规格 `docs/superpowers/plans/2026-08-31-order-home-functional-parity.md` 一致；**不要**给点单加导出
  - 分组: 
- [x] **S2.P1.T08 底部更多：鸡尾酒明细表** `已确认`
  - Vue: 点单侧鸡尾酒明细（无收银导出按钮）
  - Flutter: `cocktail_detail_report*.dart`
  - API: 以现网点单抽屉内 POST 为准（与收银 `/sel/rpt/get_hl_list` 区分是否带导出）
  - 备注: [2026-09-22 其他agent增量核验与修复] 保留用户已有确认状态；本次新增历史sa/a原价方案价显示及合计、390横滚回归已通过，但新增部分未人工确认。固定左三列/新列序/删除线视觉尚未同步。
  - 分组: 
- [x] **S2.P1.T09 底部更多：估清商品（模块 5）** `已确认`
  - Vue: 估清列表；API `POST /sel/get_prd_sold_outs`、`/sel/set_prd_sold_out`、`/sel/del_prd_sold_out`、`/sel/add_prd_sold_out`
  - Flutter: `sold_out_products*.dart`
  - 备注: [2026-09-22 收银首页补齐] 保留此前确认状态；新增PC/PAD目录正确分流，并加强撤权/断线/退出时旧估清确认失效。新增行为仍待真实验收；未因本轮代码完成增加用户确认。 详见2026-09-22-cashier-reports-soldout.md。
  - 分组: 
- [ ] **S2.P1.T10 个人开台/抵达计数 dataset 39 的 30/31** `已编码·未确认`
  - 完成: 按卡台累计，不用全场、不数状态 4 冒充
  - 分组: 
### S2.P2 `/orderMeal/orderMealList` 点单

- [ ] **S2.P2.T01 分类导航 + 商品列表（含估清灰显）** `已编码·未确认`
  - Vue: `orderMealNav.vue`、`productList.vue`、`newProductListGQ.vue`
  - Flutter: 扩展 `order_meal_screen.dart`
  - 完成: 一级/二级分类、搜索、估清不可点与 Vue 一致
  - 备注: 数据: 同步元数据商品树，不另造目录接口
  - 分组: 
- [ ] **S2.P2.T02 单品加入购物车** `已编码·未确认`
  - Flutter: `ProtocolOrderMealApi.addProduct`
  - API: `POST /wsc/add_prd` `{seat_id,prd_id,prd_cnt,prd_price,auth_type,prd_amt,requirement}`
  - 分组: 
- [ ] **S2.P2.T03 套餐加入购物车（选组）** `已编码·未确认`
  - Vue: `newDrawerMeal/groupProduct.vue`、`groupProduct2.vue`
  - API: `POST /wsc/add_set`
  - 完成: 必选组/可选组/数量规则与 Vue 一致
  - 备注: [2026-09-20 后续源码核验] 当前只检查候选数并提交全部明细，缺各可选组sum(selectedCount)==grpSelCnt及模板展开；不能视为选组已还原。 见2026-09-20-order-authorization-and-sets.md；未执行真实请求。 [2026-09-20 本轮闭环] 套餐选组、要求、模板、库存与实时会员/商务/包厢实际价已接；套餐不受无关FC未知状态阻断。已完成源码/自动化核对，真实加购结果仍待验收。
  - 分组: 
- [ ] **S2.P2.T04 时价特饮/小费/赔偿** `已编码·未确认`
  - Vue: `newDrawerMeal/singleProduct.vue` 时价分支
  - API: `POST /wsc/add_hl`
  - 分组: 
- [ ] **S2.P2.T05 优惠/赠送加入购物车** `已编码·未确认`
  - API: `POST /wsc/add_yh`；授权流程见购物车
  - 备注: [2026-09-20 后续源码核验] 当前新增优惠仍走旧/wsc/add_yh；最新路由newDrawerMeal营销分支用/wsc/add_prd+auth_type=2+prd_price，待按实际分支重接。 见2026-09-20-order-authorization-and-sets.md；未执行真实请求。
  - 分组: 
- [ ] **S2.P2.T06 优惠2 加入购物车** `已编码·未确认`
  - API: `POST /wsc/add_yh2`；`src/components/order/newDrawerMeal/drawerYH2Submit.vue`
  - 分组: 
- [ ] **S2.P2.T07 单品/套餐要求** `已编码·未确认`
  - Vue: `drawerChooseRequireInfo.vue`
  - API: `POST /wsc/add_requirement`、`/wsc/add_set_requirement`
  - 分组: 
- [ ] **S2.P2.T08 更改套餐明细** `已编码·未确认`
  - API: `POST /wsc/chg_set_dtl`
  - 备注: [2026-09-20 后续源码核验] 当前换购物车套餐把旧dtl_prd_id填成目标商品ID，缺si旧明细与合法组选择；待修正真实旧项选择和请求。 见2026-09-20-order-authorization-and-sets.md；未执行真实请求。 [2026-09-20] 已按真实旧si选择原明细并提交旧gid/商品/要求与目标数组，写前重新核对，非人工验收。
  - 分组: 
- [ ] **S2.P2.T09 绑定当台服务员** `已编码·未确认`
  - API: `POST /wo/set_csm_waiter`
  - 分组: 
- [ ] **S2.P2.T10 绑定客人手机** `已编码·未确认`
  - API: `POST /wo/get_cust_items_for_csm`、`/wo/set_csm_cust`、轮询 `/wo/get_set_csm_cust_rst`
  - 分组: 
### S2.P3 `/orderMeal/shoppingCart` 购物车

- [ ] **S2.P3.T01 购物车列表与改数量** `已编码·未确认`
  - Flutter: `listItems` / `setCount` / `cartCount`
  - API: `POST /wsc/get_items`、`/wsc/set_cnt`（0=删除）、`/wsc/get_item_cnt`
  - 完成: 角标数量与列表一致；count=0 行消失
  - 分组: 
- [ ] **S2.P3.T02 购物车下单** `已编码·未确认`
  - API: `POST /wsc/order`
  - 完成: 成功清车并跳转我的点单；失败展示服务端 msg
  - 分组: 
- [ ] **S2.P3.T03 购物车转优惠（单项，含授权）** `已编码·未确认`
  - Vue: `newShoppingCart/authorization.vue`
  - API: `POST /wsc/to_yh`
  - 分组: 
- [ ] **S2.P3.T04 购物车批量转优惠2** `已编码·未确认`
  - API: `POST /wsc/to_yh2`
  - 分组: 
- [ ] **S2.P3.T05 并台（优惠2）** `已编码·未确认`
  - Vue: `newDrawerMeal/drawerBj/**`
  - API: `POST /sel/move_order`
  - 分组: 
### S2.P4 `/orderMeal/myOrder` 我的点单

- [ ] **S2.P4.T01 已下单列表** `已编码·未确认`
  - API: `POST /wo/list`（Flutter `loadOrderItems` 需与 Vue 字段对齐）
  - 分组: 
- [ ] **S2.P4.T02 未结账退单** `已编码·未确认`
  - API: `POST /wo/back`；线上未付 `POST /wo/ol_unpay_back`
  - 完成: 已付款不可退（与 Vue 一致）；数量键盘见 `docs/superpowers/specs/2026-08-13-order-refund-quantity-keyboard-design.md`
  - 备注: 2026-09-20续轮：已补原数量/特殊金额分流、理由键盘、code2账号/已有卡码授权、成功刷新与失败保留。提交前重读订单/类型，断线身份翻台或坏数据使旧弹窗失效；取消复核中尝试不得后续发送。普通back_amt保持空，特殊用原pa或受限输入，不受赠送显示0影响。真实员工卡读取另列M0.P3.T04未完成；未做真实退单，仍待双端确认。详见2026-09-20-refund-gap.md。
  - 分组: 
- [ ] **S2.P4.T03 下单后赠送** `已编码·未确认`
  - API: `POST /wo/yh_prd`；`drawerGiveHeMoreForOrder.vue`
  - 分组: 
- [ ] **S2.P4.T04 下单后改套餐明细** `已编码·未确认`
  - API: `POST /wo/set_chg`
  - 备注: [2026-09-20 后续源码核验] 当前已下单套餐order_dtl_id误用父订单ID，须保留si[].id；另缺收银/非收银接口分支及非收银授权流程。 见2026-09-20-order-authorization-and-sets.md；未执行真实请求。 [2026-09-20] 已用真实si.id，收银/非收银授权分流，库存及旧项复核；员工卡仅卡码/密码输入，实体读卡未完成。
  - 分组: 
- [ ] **S2.P4.T05 已下单转优惠2** `已编码·未确认`
  - API: `POST /wo/yh2_prd`
  - 分组: 
- [ ] **S2.P4.T06 补打出品小票** `已编码·未确认`
  - API: `POST /wo/reprt_cp`
  - 分组: 
- [ ] **S2.P4.T07 手工打印/补打消费单** `已编码·未确认`
  - Vue: `newDrawerPrintOrder.vue`
  - API: `POST /wo/prt_csm_bill`、`POST /sel/sy_prt_csm_bill`
  - 分组: 
- [ ] **S2.P4.T08 服务员买单二维码** `已编码·未确认`
  - Vue: `newDrawerShowOrderList.vue`、`newDrawerPayQR.vue`、`choosePayTypeDialog.vue`
  - API: `POST /wo/get_waiter_olpay_todo_orders`、`/wo/do_waiter_olpay_with_orders`、`/wo/do_continue_waiter_olpay_with_orders`、`/wo/chk_waiter_olpay_with_orders`、`/wo/cancel_waiter_olpay`、`/wo/get_waiter_olpay_status`
  - 备注: [2026-09-20 操作作用域轮] 已从仅显示pay_url改为真实QR编码和元金额，保留4模块静区，过期/作用域变更精准关闭页面，15分钟关闭不宣称后台取消。付款方式选择、状态轮询、继续/取消接口仍待完整对照，不能把渲染二维码视为整项完成。
  - 分组: 
- [ ] **S2.P4.T09 核销卡券（收银端点单页按钮）** `已编码·未确认`
  - Vue: `newFootBar.vue`「核销卡券」；`drawerRedeemCoupon.vue` / `drawerRedeemCoupon2.vue`
  - API: 以抽屉内 `$api.money` 调用为准（含 `/sel/rpt/get_kq_csm_list` 相关退核销）
  - 分组: 
- [ ] **S2.P4.T10 底栏更多：充值 / 滞留金 / 清台 / 转台** `已编码·未确认`
  - Vue: `newFootBar.vue` `moreClick` command d/a/b/c
  - Flutter: packages/card_table/lib/src/order_meal_screen.dart (_onMore/onOpenVipRecharge/onOpenLateDeposit/onTransferSeat)；card_table_screen.dart 连线会员充值、追加滞留金与转台；双端 Shell 注入 OrderLateDepositLoader
  - API: 清台: `POST /sel/seat_clean`；转台: `POST /bk/chg_csm_seat`；滞留金: `POST /sel/late_fee_create`；充值: `POST /sel/vip_order_create`
  - 完成: 对齐 Vue newFootBar.vue:1039-1084，点单底栏充值/滞留金/清台/转台四入口全部接通；清台带未结单拦截，转台调用 BookingCardWriteAction.transferOpen 并安全退出返回卡台，滞留金与会员充值弹出生产级操作屏
  - 备注: 清台: `POST /sel/seat_clean`；转台复用 S1 转台 API；滞留金见 S3.P2；充值复用 S2.P1.T05 [2026-09-22 实际入口复审] 点单更多里的充值/滞留金/转台仍直接未接入提示；不能以首页有会员充值替代点单页功能。依据order_meal_screen._onMore与源components/order/newFootBar.vue:1039–1084。待接专用流程。 详见2026-09-22-reachable-gaps-audit.md。 [2026-09-28 点单底栏更多交付] 已在 OrderMealScreen 补齐 onOpenVipRecharge、onOpenLateDeposit、onTransferSeat；CardTableScreen 完整接驳 VipRechargeScreen、OrderLateDepositScreen 及转台弹窗提交与刷新；ShellDependencies 注入 OrderLateDepositLoader 单例保护；自动化单测 100% 通过。
  - 分组: 
### S2.P5 `/orderMeal/choosedList` 已选列表

- [ ] **S2.P5.T01 已选只读汇总** `已编码·未确认`
  - 完成: 字段/合计与 Vue 一致；无额外写接口则不要发明写
  - 分组: 
### S2.P6 点单内存酒（模式切换后）

- [ ] **S2.P6.T01 存酒两步单** `已编码·未确认`
  - API: `POST /wine/get_csms_f_cj`、`/wine/get_csm_cj_invt`、`/wine/get_sc_csm_cj`、`/wine/add_sc_csm_cj_prd`、`/wine/add_sc_csm_auth_cj_prd`、`/wine/mod_sc_csm_cj_prd`、`/wine/valid_phone_not_blacklist`、`/wine/new_cj_bef_in`
  - 分组: 
- [ ] **S2.P6.T02 取酒** `已编码·未确认`
  - API: `POST /wine/get_qj_invt`、`/wine/new_qj_bef_out`、`/wine/get_wine_cust_by_phone4`
  - 分组: 
- [ ] **S2.P6.T03 消费充公** `已编码·未确认`
  - API: `POST /wine/new_csm_cg_bef_in`
  - 分组: 

## S3 收银系统

对照：src/router/money/index.js  ·  62 项  ·  已确认 0  ·  已编码未确认 62  ·  未开始 0

### S3.P1 `/moneyCard` 收银卡台首页

- [ ] **S3.P1.T01 无日期栏、默认全部、搜索卡台/客人/手机尾四位** `已编码·未确认`
  - 分组: 
- [ ] **S3.P1.T02 点击开台进结账（消费明细与收款）** `已编码·未确认`
  - Vue: 进 `/payOrder`
  - Flutter: 现 `_pendingFeature('消费明细与收款')` → 改为打开 S3.P2
  - 分组: 
- [ ] **S3.P1.T03 异议单列表角标与抽屉** `已编码·未确认`
  - Vue: `src/components/money/drawerNeedBackOrderList/drawerNeedBackOrderList.vue`
  - API: `POST /yy/list`、`/yy/retry`、`/yy/process`
  - 分组: 
- [ ] **S3.P1.T04 会员系统入口** `已编码·未确认`
  - Vue: 进 `/vipNav`；Flutter 现 `_pendingFeature('会员系统')` → 打开 S4
  - 备注: [2026-09-20 源码差异审计] 实页对照：原系统选择9项含会员独立入口；Flutter 8项无会员独立入口，ERP两角色也合并。VIP代码存在不代表系统选择至登录/会员业务入口闭环已验收。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。
  - 分组: 
- [ ] **S3.P1.T05 安全模式隐藏「更多」** `已编码·未确认`
  - 分组: 
### S3.P2 `/payOrder` 结账页

- [ ] **S3.P2.T01 翻台 Tab + 支付单 Tab +「全部消费」** `已编码·未确认`
  - Flutter: 新建 `pay_order_screen.dart`（不要塞进卡台页）
  - API: `POST /sel/csm_orders`
  - 分组: 
- [ ] **S3.P2.T02 未结订单表（改套餐明细、转单）** `已编码·未确认`
  - Vue: `notPayOrder.vue`
  - API: `POST /sel/chg_prd_set_dtl`、`/sel/move_wk_order`
  - 备注: [2026-09-20 源码差异审计] 本轮修复选中商品应收、金额封顶、失败显示、成功刷新、足额及清单有效性结账门禁、换台/迟到响应；转单与套餐字段已对齐Vue。专用支付、动态渠道与套餐要求编辑仍未完成。15项支付定向测试通过，不等同完整支付验收。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 实际入口复审] Card入口PayOrderScreen未传moveOrder，直接/payOrder有回调不能覆盖卡台入口。正在补双入口及源选台流程回归。 详见2026-09-22-reachable-gaps-audit.md。 [2026-09-22 可达缺口修复验证] 未结转单已接Card与直达路由；真实卡台/数量选择、原始锁单l>0检查与fresh重读、页面/身份/协议边界守卫。未知结果本页锁定，自动刷新不解锁，显式核实读取成功才能再操作；尚无跨页持久锁。已结整笔分支另见S3.P2.T20。全量1614通过，未真实转单。 详见2026-09-22-reachable-gaps-audit.md。
  - 分组: 
- [ ] **S3.P2.T03 已结订单表（退单、改渠道）** `已编码·未确认`
  - Vue: `payedOrder.vue`
  - Flutter: packages/card_table/lib/src/paid_order_refund.dart; paid_order_refund_dialog.dart; pay_order_screen.dart; pay_order_api.dart
  - API: `POST /sel/pay_order_back`、`/sel/get_chg_pay_cnls`、`/sel/move_payed_wk_order`
  - 备注: 2026-09-20：已结商品退单按真实pay_id与六字段接入，多选数量/历史价/特殊金额、滞留金强确认、fresh预检及取消保护；仅收银当前付款单，空台和历史禁止。渠道变更/重新支付三空数组流程仍待做，不代表整项验收。见2026-09-20-paid-refund-and-session.md，未执行真实退款。
  - 分组: 
- [ ] **S3.P2.T04 待结算购物车：加/删渠道** `已编码·未确认`
  - API: `POST /sel/cart_items`、`/sel/cart_add_cnl`、`/sel/cart_del_cnl`、`/sel/cart_begin_process`
  - 备注: [2026-09-20 源码差异审计] 本轮修复选中商品应收、金额封顶、失败显示、成功刷新、足额及清单有效性结账门禁、换台/迟到响应；转单与套餐字段已对齐Vue。专用支付、动态渠道与套餐要求编辑仍未完成。15项支付定向测试通过，不等同完整支付验收。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。
  - 分组: 
- [ ] **S3.P2.T05 滞留金入购物车** `已编码·未确认`
  - Vue: `newDrawerAddBookAmt.vue` / `drawerMerchantConfig.vue`
  - API: `POST /sel/cart_add_late_cnl`、`/sel/get_seat_late_cnls`、`/sel/new_late_cnl`、`/sel/del_late_cnl`、`/sel/refund_late_cnl`、`/sel/chg_late_cnl_seat`
  - 备注: [2026-09-20 源码差异审计] 本轮安全收敛：滞留金/抹零/会员/预付等专用支付未接入，已禁止走通用渠道提交；需要专用流程与契约，不能把入口作为已实现。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。
  - 分组: 
- [ ] **S3.P2.T06 抹零（授权渠道 pay_cnl_id=10）** `已编码·未确认`
  - API: `POST /sel/cart_add_auth_cnl`
  - 备注: [2026-09-20 源码差异审计] 本轮安全收敛：滞留金/抹零/会员/预付等专用支付未接入，已禁止走通用渠道提交；需要专用流程与契约，不能把入口作为已实现。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。
  - 分组: 
- [ ] **S3.P2.T07 会员卡渠道** `已编码·未确认`
  - Vue: `drawerChooseVipCard.vue`
  - API: `POST /sel/get_phone_mb_cards`、`/sel/cart_add_mb_card_cnl`、`/sel/get_usable_mb_card_cnl`、`/sel/get_mb_card_f_csm`、`/sel/valid_cust_srv_code`
  - 备注: [2026-09-20 源码差异审计] 本轮安全收敛：滞留金/抹零/会员/预付等专用支付未接入，已禁止走通用渠道提交；需要专用流程与契约，不能把入口作为已实现。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。
  - 分组: 
- [ ] **S3.P2.T08 预订金渠道** `已编码·未确认`
  - Vue: `drawerChooseYudingjin.vue`
  - API: `POST /sel/get_phone_prepays_f_csm`、`/sel/cart_add_prepay_cnl`、`/sel/get_seat_prepay_bal`
  - 备注: [2026-09-20 源码差异审计] 本轮安全收敛：滞留金/抹零/会员/预付等专用支付未接入，已禁止走通用渠道提交；需要专用流程与契约，不能把入口作为已实现。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。
  - 分组: 
- [ ] **S3.P2.T09 结账提交** `已编码·未确认`
  - API: `POST /sel/pay_order`
  - 完成: 金额/渠道与购物车一致；失败关闭不猜测
  - 备注: [2026-09-20 源码差异审计] 本轮修复选中商品应收、金额封顶、失败显示、成功刷新、足额及清单有效性结账门禁、换台/迟到响应；转单与套餐字段已对齐Vue。专用支付、动态渠道与套餐要求编辑仍未完成。15项支付定向测试通过，不等同完整支付验收。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。
  - 分组: 
- [ ] **S3.P2.T10 客人付款码支付** `已编码·未确认`
  - Vue: `customerPaymentScanDialog.vue`
  - API: `POST /sel/customer_payment_code_pay`、`/sel/valid_pay_code`
  - 分组: 
- [ ] **S3.P2.T11 打印结算单** `已编码·未确认`
  - API: `POST /sel/prt_sel_bill`；优惠2 `POST /wo/prt_csm_yh2_bill`
  - 完成: 打印失败不回滚支付
  - 分组: 
- [ ] **S3.P2.T12 清台** `已编码·未确认`
  - API: `POST /sel/seat_clean`
  - 分组: 
- [ ] **S3.P2.T13 切换先后买单** `已编码·未确认`
  - API: `POST /sel/chg_settle_mode`
  - 分组: 
- [ ] **S3.P2.T14 线上订单转线下 / 强制转滞留金** `已编码·未确认`
  - API: `POST /sel/conv_ol_order_local`、`/sel/conv_ol_pay_local_late`、`/sel/get_conv_ol_to_org_status`、`/sel/conv_ol_pay_to_late`、`/sel/get_ol_oper_rst`
  - 分组: 
- [ ] **S3.P2.T15 强制取消服务员买单** `已编码·未确认`
  - API: `POST /sel/force_cancel_waiter_olpay`
  - 分组: 
- [ ] **S3.P2.T16 线上单立即出品** `已编码·未确认`
  - API: `POST /sel/ol_order_do_cp`
  - 分组: 
- [ ] **S3.P2.T17 批量改服务员 / 授权人** `已编码·未确认`
  - Vue: `drawerBatchUpdateWaiter.vue`、`drawerBatchUpdateAuther.vue`
  - API: `POST /sel/chg_wkorder_waiter`、`/sel/chg_wkorder_auther`
  - 备注: [2026-09-22 实际入口复审] 三个真实构造点都未传批改回调；且原API逐条order_id而新模型使用order_ids数组，筛选范围也需按已结/全部、授权类at=8精确恢复。正在修复，不代表已可用。 详见2026-09-22-reachable-gaps-audit.md。 [2026-09-22 可达缺口修复验证] 恢复已结/全部消费页签批改；下单人排除退单/线上、授权人仅at=8，逐条order_id接口而非order_ids数组。真实员工选择及wei/ae/si.dpi原订单信息、sc*dpc*pc套餐数量已接；未知ID不冒充自助。部分失败不报全成功、边界失效停止后续提交，移动窄屏已测。全量1614通过，未真实批改。 详见2026-09-22-reachable-gaps-audit.md。
  - 分组: 
- [ ] **S3.P2.T18 滞留金管理（收银底栏）** `已编码·未确认`
  - Vue: `drawerMerchantConfig.vue`；API 同 T05 管理接口
  - 分组: 
- [ ] **S3.P2.T19 从收银进点单** `已编码·未确认`
  - Vue: `newFootBar.vue` 收银「点单」→ `orderMealList`
  - 分组: 
- [ ] **S3.P2.T20 已结整笔转单** `已编码·未确认`
  - Vue: src/views/Money/payOrder.vue:304、1600、1647
  - Flutter: packages/card_table/lib/src/pay_order_screen.dart (onMovePaidPayOrder/paidTransfersNeedingVerification/onVerifyPaidTransfer)；双入口（/moneyCard 与 /payOrder）直通；SessionBoundPayOrderLoader 与 ProtocolPayOrderApi
  - API: POST /sel/move_payed_wk_order；seat_id/dest_seat_id/pay_id/total_amt(分)
  - 完成: 按原已结页签资格、整笔金额及选台规则；双入口接线；状态重读与权限/身份/页面/未知结果保护；已通过 10 项专项自动化测试
  - 备注: [2026-09-22 实际入口复审] 本轮已修未结商品转单，不能替代原已结整笔分支。src/api/money/index.js:53有独立API；金额源Math.round(amts.p*100)。尚未接入，新增独立任务避免被普通转单状态掩盖。 [2026-09-28 已结整笔转单交付] 已实现协议 POST /sel/move_payed_wk_order，已结页签整笔转单对话框、目标空台过滤、原单金额分转元、双端 Shell 连线及锁定保护，10项专项测试与全量结账单测全部通过。
  - 分组: 
### S3.P1 `/moneyCard` 收银卡台首页

- [ ] **S3.P1.R01 班结表** `已编码·未确认`
  - Vue: src/components/money/`drawerStopClass.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /wkd/get_bj` ； `POST /wkd/prt_bj`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: `入口已列·待接入` [2026-09-20 源码差异审计] 仅默认条件真实读取；自定义筛选/打印/导出未完成。班结/售出日报限当前营业日；失败重试/权限撤销/迟到响应已有保护。12项报表定向测试通过，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。
  - 分组: 
- [ ] **S3.P1.R02 售出日报表** `已编码·未确认`
  - Vue: src/components/money/`dayReport.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_sold_out_rpt_items` + `/sel/rpt/get_sold_out_rpt` ； `/sel/rpt/prt_sold_out_rpt`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 仅默认条件真实读取；自定义筛选/打印/导出未完成。班结/售出日报限当前营业日；失败重试/权限撤销/迟到响应已有保护。12项报表定向测试通过，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。
  - 分组: 
- [ ] **S3.P1.R03 商品出库表** `已编码·未确认`
  - Vue: src/components/money/`drawerShangpinchuku.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_rpt_prd_out_list` ； `/sel/rpt/exp_rpt_prd_out_list`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-21 续轮] 按当前caller接get_rpt_prd_out_list/exp_rpt_prd_out_list，key/start_day/end_day，默认本地时间减8小时日期；真实二进制保存、无伪造分页，未真实服务验收。 详见2026-09-21-images-sout-reports.md。
  - 分组: 
- [ ] **S3.P1.R04 查询优惠额度** `已编码·未确认`
  - Vue: src/components/money/`drawerYHCount/index.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/get_auth_emp_free_limit`（刷卡授权）
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 增量复核] 已实现授权额度查询及适用商品详情，原接口get_auth_emp_free_limit/get_fl_act_prds；保留原值口径，不误除100。凭据仅本次请求使用且不导出，退出/撤权/会话变化失效，回退动画期间禁止迟发。8项针对性测试通过；卡号/卡密为手工录入，原生读卡与真实账号验收待完成。
  - 分组: 
- [ ] **S3.P1.R05 线上支付汇总** `已编码·未确认`
  - Vue: src/components/money/`drawerOnlineTotal.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/get_ol_pay_bill` ； `/sel/prt_ol_pay_bill`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 第四轮] 已接真实线上支付汇总、金额单位与原字段、导出及打印回调；联网/会话隔离，未执行实际打印或后台写入。 详见2026-09-20-parity-round4.md。
  - 分组: 
- [ ] **S3.P1.R06 支付记录** `已编码·未确认`
  - Vue: src/components/money/`drawerPayRecord.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/get_pay_list` ； 改客人 `/sel/get_cust_info_by_phonenum` `/sel/chg_pay_cust`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 第四轮] 已接真实支付记录分页/关键词与会员查询、换绑/解绑（未注册手机号也按原规则允许）；营业日id>0、自助记录禁止、无会员禁止解绑；失败不伪更新，撤权精准关闭原DialogRoute不误关新登录。 详见2026-09-20-parity-round4.md。
  - 分组: 
- [ ] **S3.P1.R07 区域实时营收** `已编码·未确认`
  - Vue: src/components/money/`drawerRegionRealtimeIncome.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_region_real_amts` ； `/sel/rpt/exp_region_real_amts`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 第四轮] 已接区域实时营收查询与导出，区域来自全部原始有效areaInfo按dsp排序，含无当前可见卡台的区域，不再误用卡台筛选范围。 详见2026-09-20-parity-round4.md。
  - 分组: 
- [ ] **S3.P1.R08 业绩日报表** `已编码·未确认`
  - Vue: src/components/money/`drawerKpiReport.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_yj_rpt` ； `/sel/rpt/exp_yj_rpt`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 第四轮] 已接业绩分组1–5、真实部门树、订位人姓名/工号/拼音检索、查询及导出；选项失败阻止相关查询，不伪装默认全量。 详见2026-09-20-parity-round4.md。
  - 分组: 
- [ ] **S3.P1.R09 转台记录** `已编码·未确认`
  - Vue: src/components/money/`drawerTurnOver.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /bk/get_chg_seat_log` ； 以抽屉为准
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-21 续轮] 按moneyCard实际导入book/machine/drawerTurnOver接/bk/get_chg_seat_log无body，多行记录与刷新时间；非同名翻台页，无导出/分页，不猜权限码。 详见2026-09-21-images-sout-reports.md。
  - 分组: 
- [ ] **S3.P1.R10 线上预订记录** `已编码·未确认`
  - Vue: src/components/money/`drawerOnlineBooking.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_ol_book_list` ； `/sel/rpt/exp_ol_book_list`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-21 续轮] 线上预订无body查询及无body二进制导出，原金额直接显示不自行除100；保留全部源列，无新增退款或修改动作。 详见2026-09-21-images-sout-reports.md。
  - 分组: 
- [ ] **S3.P1.R11 优惠明细表** `已编码·未确认`
  - Vue: src/components/money/`drawerYHDetail.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_yh_list` ； `/sel/rpt/exp_yh_list`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 第四轮] 已接优惠类型/关键词、嵌套明细、金额及导出；共享二进制客户端中文fallback/非法编码已修。 详见2026-09-20-parity-round4.md。
  - 分组: 
- [ ] **S3.P1.R12 当日卡券核销记录表** `已编码·未确认`
  - Vue: src/components/money/`drawerMtDyHx.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: POST /sel/rpt/get_kq_csm_list_for_back；/sel/rpt/exp_kq_csm_list_for_back；退券 /sel/cancel_kq_csm {kq_order_id}
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 历史/套餐/卡券闭环] 已按drawerMtDyHx实际_for_back查询/导出接入21列和退券；仅数值b=1可退，金额a/a2分转元，确认后预读核验同ID完整指纹。请求发起前锁券，过期/未知回包不清锁，自动重连查询不解锁，显式成功查询才核实恢复。营业日变化使旧确认失效（不是要求必须开营业日），三端身份/在线/代际/UI守卫到真实发送边界。未做真实退券。 详见2026-09-22-history-voucher-set.md；真实门店数据待验收。
  - 分组: 
- [ ] **S3.P1.R13 商品卡台销售表** `已编码·未确认`
  - Vue: src/components/money/`drawerKTSalesDetail.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_prd_set_sold_cnt` ； `/sel/rpt/exp_prd_set_sold_cnt`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-21 续轮] 商品卡台销售key查询/重置及相同筛选二进制导出；p为商品名不是价格，保留单品/套餐/合计数量，无虚构分页。 详见2026-09-21-images-sout-reports.md。
  - 分组: 
- [ ] **S3.P1.R14 鸡尾酒明细表** `已编码·未确认`
  - Vue: src/components/money/`drawerTYDetail.vue` / `newDrawerTYDetail.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_hl_list` ； `/sel/rpt/exp_hl_list`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 入口在；点单已确认版**无导出**，收银必须有导出 [2026-09-20 源码差异审计] 仅默认条件真实读取；自定义筛选/打印/导出未完成。班结/售出日报限当前营业日；失败重试/权限撤销/迟到响应已有保护。12项报表定向测试通过，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 其他agent增量核验与修复] 已同步历史记录sa/a双金额、无效原价回退与sa=0，金额完整显示；未依当前方案重算历史。原Web新固定列/列序与删除线视觉仍有差异，未进行真实报表验收。
  - 分组: 
- [ ] **S3.P1.R15 鸡尾酒汇总表** `已编码·未确认`
  - Vue: src/components/money/`drawerTYHZ.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_hl_rpt_sum_list` ； `/sel/rpt/exp_hl_rpt_sum_list`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 仅默认条件真实读取；自定义筛选/打印/导出未完成。班结/售出日报限当前营业日；失败重试/权限撤销/迟到响应已有保护。12项报表定向测试通过，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 其他agent增量核验与修复] 已同步历史记录原价sa/实际a与源合计口径，未使用当前价格方案；自动化通过但未真实报表验收。
  - 分组: 
- [ ] **S3.P1.R16 挂账账户** `已编码·未确认`
  - Vue: src/components/money/`drawerGZDetail/**`
  - Flutter: packages/card_table/lib/src/cashier_credit_accounts*.dart；card_table_screen.dart；Web/native_client_shell 持久 loader 接线
  - API: `POST /cnlacct/list` `/new` `/save` `/del` `/get_op_logs` `/return` `/get_orders`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 整合复核] 挂账账户已接更多菜单，搜索/增改删/日志/订单选择/六渠道还款与源顺序和金额单位对齐。余额与订单重读、会话/在线/页面派发守卫、持久loader的进行中/未知锁已回归，关页重开不解锁。全工作区1554项通过；未真实建账、还款或删除，待用户验收。详见2026-09-22-credit-merchant-print-integration.md。
  - 分组: 
- [ ] **S3.P1.R17 翻台记录** `已编码·未确认`
  - Vue: src/components/money/翻台抽屉（`showOrHideTurnOverDetailHandle`）
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_turnover_csm_list` ； `/sel/rpt/exp_turnover_cms_list`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 收银首页补齐] 对齐实际drawerTurnOver.vue：get_turnover_csm_list/exp_turnover_cms_list（保留cms拼写），无body，无虚构日期筛选，全部9列；复用错误/空态/重试、文件导出与会话隔离。 详见2026-09-22-cashier-reports-soldout.md。
  - 分组: 
- [ ] **S3.P1.R18 点单记录** `已编码·未确认`
  - Vue: src/components/money/`drawerOrder.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_order_prd_list` ； `/sel/rpt/exp_order_prd_list`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 收银首页补齐] 对齐drawerOrder.vue：get/exp_order_prd_list，21列及关键词、商品类型、是否自助、支付方式、营业类型；prd_type/biz_types取服务端选项；重置省略原undefined字段且is_cust:null，查询/导出参数一致。 详见2026-09-22-cashier-reports-soldout.md。
  - 分组: 
- [ ] **S3.P1.R19 历史点单记录** `已编码·未确认`
  - Vue: src/components/money/`drawerHistoryOrder.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_csm_his_wkday_items`、`/sel/rpt/get_csm_his` ； 以抽屉为准
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 历史/套餐/卡券闭环] 已实现营业日初始化、默认第一项/重置、指定wkday_id+key查询/导出、父流水和展开os订单明细，o/p及oa/pa分转元。无虚构卡台/类型筛选或打印；历史页面与实际回调已接三端。 详见2026-09-22-history-voucher-set.md；真实门店数据待验收。
  - 分组: 
- [ ] **S3.P1.R20 非鸡尾酒类补交报表** `已编码·未确认`
  - Vue: src/components/money/`drawerNotTYOrXF.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_relate_prd_list` ； `/sel/rpt/exp_relate_prd_list`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 收银首页补齐] 对齐drawerNotTYOrXF.vue：get/exp_relate_prd_list，保留orders十四列明细与pays渠道/笔数/金额独立表；仅pays有值也能展示。金额原值，不误除100。 详见2026-09-22-cashier-reports-soldout.md。
  - 分组: 
- [ ] **S3.P1.R21 修改订位人记录** `已编码·未确认`
  - Vue: src/components/money/`drawerUpdateBookEmp.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_csm_sales_chg_list` ； `/sel/rpt/exp_csm_sales_chg_list`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 收银首页补齐] 对齐drawerUpdateBookEmp.vue：get/exp_csm_sales_chg_list，保留全部十列；源日期/查询UI已注释，未添加虚假筛选。 详见2026-09-22-cashier-reports-soldout.md。
  - 分组: 
- [ ] **S3.P1.R22 估清商品** `已编码·未确认`
  - Vue: src/components/money/与点单共用
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: 同 S2.P1.T09
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 点单已确认；收银入口仍要接到同一套 Screen [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 收银首页补齐] 接入现有估清组件；收银不额外要求点单module5，点单保留该限制；安全模式/在线约束保留。查询/设置/解除使用当前系统身份（收银tt8、点单tt4），增加凭据等待后的UI/会话/generation发送边界检查；退出、权限变化、连接流错误/结束使旧操作失效。平台可见性由PC/PAD实际平台决定。负数估清数量旧Web未禁止、Flutter仍非负，已向用户确认业务含义，尚未取得答复。 详见2026-09-22-cashier-reports-soldout.md。
  - 分组: 
- [ ] **S3.P1.R23 盘盈盘亏** `已编码·未确认`
  - Vue: src/components/money/`drawerProfit/**`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/get_prd_profit_loss`、`/sel/do_prd_profit_loss`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: `入口已列·待接入` [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 盘盈盘亏/销售报告闭环] 完整接入盘盈盘亏查询/新增与三端共享回调，原4字段数组、3行默认草稿、切库清空、至少1行、商品搜索、空数量0/有符号整数/重复商品/同时盈亏语义保留。元数据2/3/4/16/30按库和物料关联，未分配库0/null忽略，不套PC/PAD或岗位限制；会话/在线/权限/元数据/退出发送前守卫，不确定写锁重复。卡台实际接线及快断快连/换流/换员工回归通过；无真实库存写入，待验收。 详见2026-09-22-sales-profit-loss.md；真实门店数据及导出文件仍待验证。
  - 分组: 
- [ ] **S3.P1.R24 商户号管理** `已编码·未确认`
  - Vue: src/components/money/`drawerMerchant.vue` `drawerMerChantInfo.vue`
  - Flutter: packages/card_table/lib/src/cashier_merchant_management*.dart、cashier_merchant_amounts.dart；三端壳接线
  - API: `POST /sel/get_cnl_cfg` `/sel/save_cnl_cfg` `/org/get_cnl_cfg_grp` `/org/save_cnl_cfg_grp` `/org/save_cnl_cfg_openclose` ； 时段阀值 `/sel/get_cnl_hour_amt` 等
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 整合复核] 已接商户管理菜单及dataset38底部单/双主体金额入口；原始金额传信息页，展示/10000。主体互斥/24时段/卡台绑定/线上与手动切换已接真实协议。阈值保留有符号整数；持久loader防关页重复写，仅显式匹配状态核实解锁；断线隐藏旧数据，金额更新不撤配置。R24 27项、全工作区1554项通过；未真实修改商户或支付路由，待验收。详见2026-09-22-credit-merchant-print-integration.md。
  - 分组: 
- [ ] **S3.P1.R25 低消进度统计表** `已编码·未确认`
  - Vue: src/components/money/`drawerMinDetail.vue`（**有导出**）
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /wo/get_seat_zy_csm_list` ； `/wo/exp_seat_zy_csm_list`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 点单版无导出；收银必须导出 [2026-09-20 源码差异审计] 仅默认条件真实读取；自定义筛选/打印/导出未完成。班结/售出日报限当前营业日；失败重试/权限撤销/迟到响应已有保护。12项报表定向测试通过，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。
  - 分组: 
- [ ] **S3.P1.R26 现抽明细表** `已编码·未确认`
  - Vue: src/components/money/`drawerXCDetail.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_xian_chou_list` ； `/sel/rpt/exp_xian_chou_list`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 盘盈盘亏/销售报告闭环] 按drawerXCDetail实现关键词查询及同条件Excel导出，字段按现网源码，金额直接展示原值，不误除100；无伪造日期/分页/打印。 详见2026-09-22-sales-profit-loss.md；真实门店数据及导出文件仍待验证。
  - 分组: 
- [ ] **S3.P1.R27 现抽汇总表** `已编码·未确认`
  - Vue: src/components/money/`drawerXCAllInfo.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_xian_chou_sum_list` ； `/sel/rpt/exp_xian_chou_sum_list`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 盘盈盘亏/销售报告闭环] 按drawerXCAllInfo实现关键词查询及同条件Excel导出；原抽成对象列实际o、抽成人列tn，保留源映射，未擅自交换；金额原值。 详见2026-09-22-sales-profit-loss.md；真实门店数据及导出文件仍待验证。
  - 分组: 
- [ ] **S3.P1.R28 非主营分类渠道** `已编码·未确认`
  - Vue: src/components/money/`drawerQDAllInfo.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_not_zy_cate_cnls` ； `/sel/rpt/exp_not_zy_cate_cnls`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 盘盈盘亏/销售报告闭环] 按drawerQDAllInfo实现完整固定列查询和Excel导出，无请求体与虚构筛选，金额保持元原值。 详见2026-09-22-sales-profit-loss.md；真实门店数据及导出文件仍待验证。
  - 分组: 
- [ ] **S3.P1.R29 分类渠道汇总表** `已编码·未确认`
  - Vue: src/components/money/`drawerCatQDAllInfo.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_jk_list` ； `/sel/rpt/exp_jk_list`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 盘盈盘亏/销售报告闭环] 按drawerCatQDAllInfo实现cnls动态列、按c类别分组、分类及总合计；同名渠道按ID区分。重复类别/渠道单元格取最后值，总计保留全部记录；总合计按源先组内再各组顺序相加，一分钱差异有红绿回归。 详见2026-09-22-sales-profit-loss.md；真实门店数据及导出文件仍待验证。
  - 分组: 
- [ ] **S3.P1.R30 部门销售明细表** `已编码·未确认`
  - Vue: src/components/money/`drawerXSDetail.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_waiter_sales_prd_amt_list` ； `/sel/rpt/exp_waiter_sales_prd_amt_list`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 盘盈盘亏/销售报告闭环] 按drawerXSDetail实现部门销售明细及Excel导出，完整固定列，金额原值；无body、无伪造日期/分页/打印或树过滤。 详见2026-09-22-sales-profit-loss.md；真实门店数据及导出文件仍待验证。
  - 分组: 
- [ ] **S3.P1.R31 部门销售汇总表** `已编码·未确认`
  - Vue: src/components/money/`drawerXSAllInfo.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_waiter_sales_prd_amt_sums` ； `/sel/rpt/exp_waiter_sales_prd_amt_sums`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 盘盈盘亏/销售报告闭环] 按drawerXSAllInfo实现部门销售汇总及Excel导出，完整固定列，金额原值；无body、无伪造日期/分页/打印或树过滤。 详见2026-09-22-sales-profit-loss.md；真实门店数据及导出文件仍待验证。
  - 分组: 
- [ ] **S3.P1.R32 套餐统计表** `已编码·未确认`
  - Vue: src/components/money/`drawerSetCount.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_set_cnt_items` + `/sel/rpt/get_set_cnt_rpt` ； `/sel/rpt/prt_set_cnt_rpt`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 历史/套餐/卡券闭环] 已实现two_cates/ss初始化树（不自动统计）、全选/部分选择、父类别覆盖其子套餐、状态0/1/5、prd_sets父行/ss明细和真实筛选打印。printQuery捕获当前参数并联合页面/账号/终端/连接代际，凭据等待及退出动画后零发送。不虚构导出，未做实际打印。 详见2026-09-22-history-voucher-set.md；真实门店数据待验收。
  - 分组: 
- [ ] **S3.P1.R33 挂账还款记录表** `已编码·未确认`
  - Vue: src/components/money/`drawerSetGZHK.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_cnl_account_rtn_list` ； 以抽屉为准
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 预订金/S9复核] 已按drawerSetGZHK实现查询/导出get/exp_cnl_account_rtn_list，无body与伪造筛选；金额m由分转元一次。独立合同审查通过，真实门店文件待验收。 详见2026-09-22-deposit-and-super-admin-audit.md。
  - 分组: 
- [ ] **S3.P1.R34 预订金流水表** `已编码·未确认`
  - Vue: src/components/money/`drawerSetYDJHistory.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_cust_prepay_log` ； 以抽屉为准
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 预订金/S9复核] 已按drawerSetYDJHistory实现日期默认当前时间减8小时、每页10条、查询保留页码、重置日期/页码但保留关键词；金额a/bb/ab分转元；二进制导出源确为同get_cust_prepay_log路径，未猜测exp接口。待真实文件验收。 详见2026-09-22-deposit-and-super-admin-audit.md。
  - 分组: 
- [ ] **S3.P1.R35 预订金余额表** `已编码·未确认`
  - Vue: src/components/money/`drawerSetYDJYE.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /sel/rpt/get_cust_prepay_bal` ； 以抽屉为准
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 预订金/S9复核] 已按drawerSetYDJYE实现余额分页/查询/导出，真实cust_id进入个人流水查询及导出，返回保留列表页码/关键词，旧详情回包不能覆盖列表。ub/la/ca/ba分转元；详情无伪造分页。待真实验收。 详见2026-09-22-deposit-and-super-admin-audit.md。
  - 分组: 
- [ ] **S3.P1.R36 结束营业日** `已编码·未确认`
  - Vue: src/components/money/`drawerStopStore.vue`
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /wkd/close` ； 班结打印 `/wkd/prt_bj`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 其他agent增量核验与修复] 本轮修复其他agent增量：三端共用会话/在线/generation loader；营业日/安全模式/连接变化使原确认失效；凭据读取和adapter发送前再检scope；关闭成功只退出原会话，不确定回包锁住本页重复关闭。未执行真实结束营业日。
  - 分组: 
- [ ] **S3.P1.R37 自动结束营业日** `已编码·未确认`
  - Vue: src/components/money/同抽屉 auto
  - Flutter: packages/card_table/lib/src/ 新建 *report* 三件套；菜单 card_page_menus.dart
  - API: `POST /wkd/auto_close_cfg`、`/wkd/save_auto_close`
  - 完成: 查询/空/错/重试；Vue 有导出或打印则实现；收银更多去掉「待接入」；Win/Web 接线
  - 备注: 同上 [2026-09-20 源码差异审计] 该报表未实现，返回 report.unavailable，不请求猜测接口。仅有入口，筛选/统计/打印/导出未完成，Windows未接线。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 其他agent增量核验与修复] 本轮修复未加载/失败仍能保存默认关闭的问题，读取成功后才允许编辑保存；失败可重试，原上下文失效后禁止提交，三端回调共用发送前与回包守卫。支持源数字字符串字段。
  - 分组: 

## S4 会员系统

对照：src/router/vip/index.js · navList.js  ·  27 项  ·  已确认 0  ·  已编码未确认 27  ·  未开始 0

### S4.P0 会员壳

- [ ] **S4.P0.T01 侧栏 + 返回收银卡台** `已编码·未确认`
  - Vue: `vipNav.vue` + `navList.js` id=0 返回、id=1 首页
  - Flutter: `vip_nav_screen.dart`；收银入口 S3.P1.T04 打开本壳
  - 分组: 
### S4.P1 `/vipManager` 会员管理

- [ ] **S4.P1.T01 会员卡列表/搜索** `已编码·未确认`
  - API: — `POST /mb/card/list`
  - 备注: — `POST /mb/card/list` [2026-09-20 源码差异审计] 实页对照：原系统选择9项含会员独立入口；Flutter 8项无会员独立入口，ERP两角色也合并。VIP代码存在不代表系统选择至登录/会员业务入口闭环已验收。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 续轮修复] 会员独立终端入口与VipNavScreen真实回调已接线，连接未就绪不进入操作页；原先收银内入口保留。真实员工登录与权限/操作逐项验收仍待完成。 详见2026-09-20-parity-round2.md。
  - 分组: 
- [ ] **S4.P1.T02 新建会员卡** `已编码·未确认`
  - API: — `/mb/card/get_params_f_new`、`/mb/card/new`；短信 `/sms/valid_send` `/sms/valid_chk` type 101
  - 备注: — `/mb/card/get_params_f_new`、`/mb/card/new`；短信 `/sms/valid_send` `/sms/valid_chk` type 101
  - 分组: 
- [ ] **S4.P1.T03 制卡开始/结束** `已编码·未确认`
  - API: — `/mb/card/mk_card_begin` `/mb/card/mk_card_end`
  - 备注: — `/mb/card/mk_card_begin` `/mb/card/mk_card_end`
  - 分组: 
- [ ] **S4.P1.T04 绑定手机名下卡** `已编码·未确认`
  - API: — `/mb/card/phone_mb_list`
  - 备注: — `/mb/card/phone_mb_list`
  - 分组: 
- [ ] **S4.P1.T05 页面内其它写操作（改绑、注销、改等级等）** `已编码·未确认`
  - 备注: 执行时逐个从 `vipManager.vue` 抄按钮 → 对 `src/api/vip/index.js` 的 path；一按钮一叶测试
  - 分组: 
### S4.P2 `/qwVip` 企微会员

- [ ] **S4.P2.T01 列表/筛选** `已编码·未确认`
  - API: — 以页面内实际 POST 为准
  - 备注: — 以页面内实际 POST 为准 [2026-09-22 实际入口复审] 企微会员查询按钮传空关键词，固定page1/size10无分页；对照qwVip.vue。此子功能未完成，须恢复真实筛选与分页。 详见2026-09-22-reachable-gaps-audit.md。 [2026-09-22 可达缺口修复验证] 企微查询按钮与Enter保留关键词；page_num/page_size10/key及row_cnt精确合同；查询/重置回第一页，上一/下一与总数、失败重试、迟到响应丢弃。独立VIP仍按源隐藏查询工具栏但保留分页。全量1614通过，真实门店数据待确认。 详见2026-09-22-reachable-gaps-audit.md。
  - 分组: 
- [ ] **S4.P2.T02 页面写操作** `已编码·未确认`
  - 备注: — 每按钮一任务，禁止合并成「其它」
  - 分组: 
### S4.P3 `/vipType` 会员卡类型

- [ ] **S4.P3.T01 类型列表** `已编码·未确认`
  - API: — `POST /mb/type/list` `/mb/type/get`
  - 备注: — `POST /mb/type/list` `/mb/type/get`
  - 分组: 
- [ ] **S4.P3.T02 新增/改名/默认/删除类型** `已编码·未确认`
  - API: — `/mb/type/new` `/chg_name` `/chg_def` `/del`
  - 备注: — `/mb/type/new` `/chg_name` `/chg_def` `/del`
  - 分组: 
- [ ] **S4.P3.T03 等级 CRUD + 经验阀值 + 卡券** `已编码·未确认`
  - API: — `/mb/type/get_level_list` `/new_level` `/chg_level_name` `/chg_level_pic` `/del_level` `/chg_mb_card_level_exp_td` `/chg_level_kq` `/get_mb_card_level_kqs`
  - 备注: — `/mb/type/get_level_list` `/new_level` `/chg_level_name` `/chg_level_pic` `/del_level` `/chg_mb_card_level_exp_td` `/chg_level_kq` `/get_mb_card_level_kqs`
  - 分组: 
- [ ] **S4.P3.T04 自动升级开/关** `已编码·未确认`
  - API: — `/mb/type/enable_autoupd` `/disable_autoupd`
  - 备注: — `/mb/type/enable_autoupd` `/disable_autoupd`
  - 分组: 
- [ ] **S4.P3.T05 自定义卡面** `已编码·未确认`
  - API: — `/mb/type/get_cust_cover_list` `/new_cust_cover` `/del_cust_cover`；图前缀 `/oss/get_pic_prefix`
  - 备注: — `/mb/type/get_cust_cover_list` `/new_cust_cover` `/del_cust_cover`；图前缀 `/oss/get_pic_prefix`
  - 分组: 
### S4.P4 `/vipNumRules` 会员卡号生成规则

- [ ] **S4.P4.T01 读规则 + 保存** `已编码·未确认`
  - API: — 以页面内 POST 为准（执行时从 vue 抄，写入本任务注释）
  - 备注: — 以页面内 POST 为准（执行时从 vue 抄，写入本任务注释） [2026-09-22 实际入口复审] 源vipAuth=client!=vip；独立VIP终端应隐藏卡号规则等受限操作，新版缺此门禁。正在按各业务vipAuth及module30例外修复，不可笼统全禁写。 详见2026-09-22-reachable-gaps-audit.md。 [2026-09-22 可达缺口修复验证] 按源vipAuth及module30精确恢复权限，不笼统全禁VIP：卡号规则/配置等受限，会员编辑例外及冻结/解冻保留。菜单与loader双层门禁、Protocol派发守卫、权限revision及创建时workspace scope覆盖撤权恢复旧弹窗。双main已接dataset41真实权限来源。全量1614通过，未真实改规则。 详见2026-09-22-reachable-gaps-audit.md。
  - 分组: 
### S4.P5 报表页（只读 + 导出）

- [ ] **S4.P5.T01 /makeMoneyToVip 充值记录** `已编码·未确认`
  - Vue: src/views/vip/makeMoneyToVip.vue
  - Flutter: packages/card_table/lib/src/vip_pages.dart & vip_pages_loader.dart
  - API: /mb/rpt/exp_deposit_log ； /mb/rpt/deposit_log
  - 备注: — `src/views/vip/makeMoneyToVip.vue` [2026-09-22 实际入口复审] VIP报表导出当前走JSON _post/_ack，未接收或保存Excel；原src/api/vip/index.js对应exp接口使用binaryFilePost。须恢复二进制导出及当前筛选/会话/保存守卫，不得以请求发出当交付。详见2026-09-22-reachable-gaps-audit.md。 [2026-09-24 VIP报表导出二进制闭环] 已接入 postBinary.canDispatch 二进制 Excel 导出与端侧文件保存守卫，覆盖9类会员报表及推荐人/类型/分页参数；自动化单测与组件测 100/100 全量通过。
  - 分组: 
- [ ] **S4.P5.T02 /lateDepositManage 滞留金管理** `已编码·未确认`
  - 备注: — `lateDepositManage.vue`（此页含管理写：按页面按钮再拆子任务）
  - 分组: 
- [ ] **S4.P5.T03 /payMoneyAll 消费记录** `已编码·未确认`
  - Vue: src/views/vip/payMoneyAll.vue
  - Flutter: packages/card_table/lib/src/vip_pages.dart & vip_pages_loader.dart
  - API: /mb/rpt/exp_consume_log ； /mb/rpt/consume_log
  - 备注: [2026-09-22 实际入口复审] VIP报表导出当前走JSON _post/_ack，未接收或保存Excel；原src/api/vip/index.js对应exp接口使用binaryFilePost。须恢复二进制导出及当前筛选/会话/保存守卫，不得以请求发出当交付。详见2026-09-22-reachable-gaps-audit.md。 [2026-09-24 VIP报表导出二进制闭环] 已接入 postBinary.canDispatch 二进制 Excel 导出与端侧文件保存守卫，覆盖9类会员报表及推荐人/类型/分页参数；自动化单测与组件测 100/100 全量通过。
  - 分组: 
- [ ] **S4.P5.T04 /vipPay 扣款记录** `已编码·未确认`
  - Vue: src/views/vip/vipPay.vue
  - Flutter: packages/card_table/lib/src/vip_pages.dart & vip_pages_loader.dart
  - API: /mb/rpt/exp_subtract_log ； /mb/rpt/subtract_log
  - 备注: [2026-09-22 实际入口复审] VIP报表导出当前走JSON _post/_ack，未接收或保存Excel；原src/api/vip/index.js对应exp接口使用binaryFilePost。须恢复二进制导出及当前筛选/会话/保存守卫，不得以请求发出当交付。详见2026-09-22-reachable-gaps-audit.md。 [2026-09-24 VIP报表导出二进制闭环] 已接入 postBinary.canDispatch 二进制 Excel 导出与端侧文件保存守卫，覆盖9类会员报表及推荐人/类型/分页参数；自动化单测与组件测 100/100 全量通过。
  - 分组: 
- [ ] **S4.P5.T05 /pointRecords 积分记录** `已编码·未确认`
  - Vue: src/views/vip/pointRecords.vue
  - Flutter: packages/card_table/lib/src/vip_pages.dart & vip_pages_loader.dart
  - API: /mb/rpt/exp_pt_log ； /mb/rpt/pt_log
  - 备注: [2026-09-22 实际入口复审] VIP报表导出当前走JSON _post/_ack，未接收或保存Excel；原src/api/vip/index.js对应exp接口使用binaryFilePost。须恢复二进制导出及当前筛选/会话/保存守卫，不得以请求发出当交付。详见2026-09-22-reachable-gaps-audit.md。 [2026-09-24 VIP报表导出二进制闭环] 已接入 postBinary.canDispatch 二进制 Excel 导出与端侧文件保存守卫，覆盖9类会员报表及推荐人/类型/分页参数；自动化单测与组件测 100/100 全量通过。
  - 分组: 
- [ ] **S4.P5.T06 /memberBalanceSum 会员卡余额汇总表** `已编码·未确认`
  - Vue: src/views/vip/memberBalanceSum.vue
  - Flutter: packages/card_table/lib/src/vip_pages.dart & vip_pages_loader.dart
  - API: /mb/rpt/exp_mb_card_bal_list ； /mb/rpt/mb_card_bal_list
  - 备注: [2026-09-22 实际入口复审] VIP报表导出当前走JSON _post/_ack，未接收或保存Excel；原src/api/vip/index.js对应exp接口使用binaryFilePost。须恢复二进制导出及当前筛选/会话/保存守卫，不得以请求发出当交付。详见2026-09-22-reachable-gaps-audit.md。 [2026-09-24 VIP报表导出二进制闭环] 已接入 postBinary.canDispatch 二进制 Excel 导出与端侧文件保存守卫，覆盖9类会员报表及推荐人/类型/分页参数；自动化单测与组件测 100/100 全量通过。
  - 分组: 
- [ ] **S4.P5.T07 /memberConsumeRank 会员消费排名表** `已编码·未确认`
  - Vue: src/views/vip/memberConsumeRank.vue
  - Flutter: packages/card_table/lib/src/vip_pages.dart & vip_pages_loader.dart
  - API: /mb/rpt/exp_mb_card_top_consume ； /mb/rpt/mb_card_top_consume
  - 备注: [2026-09-22 实际入口复审] VIP报表导出当前走JSON _post/_ack，未接收或保存Excel；原src/api/vip/index.js对应exp接口使用binaryFilePost。须恢复二进制导出及当前筛选/会话/保存守卫，不得以请求发出当交付。详见2026-09-22-reachable-gaps-audit.md。 [2026-09-24 VIP报表导出二进制闭环] 已接入 postBinary.canDispatch 二进制 Excel 导出与端侧文件保存守卫，覆盖9类会员报表及推荐人/类型/分页参数；自动化单测与组件测 100/100 全量通过。
  - 分组: 
- [ ] **S4.P5.T08 /customerRelationShipMaintence 客户关系维护表** `已编码·未确认`
  - Vue: src/views/vip/customerRelationShipMaintence.vue
  - Flutter: packages/card_table/lib/src/vip_pages.dart & vip_pages_loader.dart
  - API: /mb/rpt/exp_mb_card_consume_list ； /mb/rpt/mb_card_consume_list
  - 备注: [2026-09-22 实际入口复审] VIP报表导出当前走JSON _post/_ack，未接收或保存Excel；原src/api/vip/index.js对应exp接口使用binaryFilePost。须恢复二进制导出及当前筛选/会话/保存守卫，不得以请求发出当交付。详见2026-09-22-reachable-gaps-audit.md。 [2026-09-24 VIP报表导出二进制闭环] 已接入 postBinary.canDispatch 二进制 Excel 导出与端侧文件保存守卫，覆盖9类会员报表及推荐人/类型/分页参数；自动化单测与组件测 100/100 全量通过。
  - 分组: 
- [ ] **S4.P5.T09 /logoutRecordForm 注销记录表** `已编码·未确认`
  - Vue: src/views/vip/logoutRecordForm.vue
  - Flutter: packages/card_table/lib/src/vip_pages.dart & vip_pages_loader.dart
  - API: /mb/rpt/exp_mb_card_zx_list ； /mb/rpt/mb_card_zx_list
  - 备注: [2026-09-22 实际入口复审] VIP报表导出当前走JSON _post/_ack，未接收或保存Excel；原src/api/vip/index.js对应exp接口使用binaryFilePost。须恢复二进制导出及当前筛选/会话/保存守卫，不得以请求发出当交付。详见2026-09-22-reachable-gaps-audit.md。 [2026-09-24 VIP报表导出二进制闭环] 已接入 postBinary.canDispatch 二进制 Excel 导出与端侧文件保存守卫，覆盖9类会员报表及推荐人/类型/分页参数；自动化单测与组件测 100/100 全量通过。
  - 分组: 
- [ ] **S4.P5.T10 /changeLevelRecordForm 更改等级记录表** `已编码·未确认`
  - Vue: src/views/vip/changeLevelRecordForm.vue
  - Flutter: packages/card_table/lib/src/vip_pages.dart & vip_pages_loader.dart
  - API: /mb/rpt/exp_mb_card_updown_log ； /mb/rpt/mb_card_updown_log
  - 备注: [2026-09-22 实际入口复审] VIP报表导出当前走JSON _post/_ack，未接收或保存Excel；原src/api/vip/index.js对应exp接口使用binaryFilePost。须恢复二进制导出及当前筛选/会话/保存守卫，不得以请求发出当交付。详见2026-09-22-reachable-gaps-audit.md。 [2026-09-24 VIP报表导出二进制闭环] 已接入 postBinary.canDispatch 二进制 Excel 导出与端侧文件保存守卫，覆盖9类会员报表及推荐人/类型/分页参数；自动化单测与组件测 100/100 全量通过。
  - 分组: 
### S4.P6 不移植

- [ ] **S4.P6.X01 /pointManager 积分设置** `已编码·未确认`
  - 备注: （`navList.js` 已注释）
  - 分组: 
- [ ] **S4.P6.X02 /onlineMakeMoneyToVip 会员卡充值设置** `已编码·未确认`
  - 备注: （侧栏已注释；接口可被 S4.P3 规则抽屉引用时随抽屉做，不做独立页）
  - 分组: 
- [ ] **S4.P6.X03 /vipBillRules** `已编码·未确认`
  - 备注: （路由已注释）
  - 分组: 

## S5 存酒系统

对照：src/router/wine/index.js  ·  39 项  ·  已确认 0  ·  已编码未确认 39  ·  未开始 0

### S5.P0 存酒系统导航

- [ ] **S5.P0.T01 存酒直属菜单恢复与安卓窄屏导航** `已编码·未确认`
  - Vue: src/views/ManagementSystem/ManagementSystem.vue authority / wineNavList.js
  - Flutter: wine_nav_screen.dart / management_permissions.dart
  - API: 沿用各存酒页面原接口
  - 备注: 2026-09-20 用户反馈安卓菜单全空、标题溢出。已修直属菜单被未知角色元数据误拦；真实在线状态独立控制访问，跨系统授权继续校验。手机使用抽屉，桌面保留侧栏；入/出库窄屏回归。自动测试不代表全部存酒业务人工验收。详见2026-09-20-wine-menu-gap.md。
  - 分组: 
### S5.P1 `/wine/saveNeedToLib` 存酒待入库

- [ ] **S5.P1.T01 列表** `已编码·未确认`
  - API: — `POST /wine/get_cj_bef_in`
  - 备注: — `POST /wine/get_cj_bef_in`
  - 分组: 
- [ ] **S5.P1.T02 批量确认入库** `已编码·未确认`
  - API: — `/wine/confirm_cj_bef_in`
  - 备注: — `/wine/confirm_cj_bef_in`
  - 分组: 
- [ ] **S5.P1.T03 批量驳回** `已编码·未确认`
  - API: — `/wine/back_cj_bef_in`
  - 备注: — `/wine/back_cj_bef_in`
  - 分组: 
- [ ] **S5.P1.T04 仓库改单** `已编码·未确认`
  - API: — `/wine/chg_cj_bef_in`
  - 备注: — `/wine/chg_cj_bef_in` [2026-09-20] 真实合同复查：改单缺bef_in_id、模式/关联及完整商品明细，见2026-09-20-wine-contract-gaps.md。 [2026-09-20 完整改单续轮] 已接完整15字段、真实关联卡台/流水和非关联卡台/订位人、原明细复制/删除、规格/克数/数量/有效期、客人及时间编辑；实时5/24分别提供员工/营业日，按当前旧版保留员工1/2/3集合。日期/失效选项/取消/会话/原单变化已补回归，独立源码复核通过。原接口未传授权凭据，前端确认不能称为后台验证；自动读卡未接，未执行真实改单。见2026-09-20-save-edit-and-paging.md。
  - 分组: 
- [ ] **S5.P1.T05 待改订位人列表** `已编码·未确认`
  - API: — `/wine/get_chg_sales_emp_list`
  - 备注: — `/wine/get_chg_sales_emp_list`
  - 分组: 
### S5.P2 `/wine/getNeedToLib` 取酒待出库

- [ ] **S5.P2.T01 列表** `已编码·未确认`
  - API: — `POST /wine/get_qj_bef_out`
  - 备注: — `POST /wine/get_qj_bef_out`
  - 分组: 
- [ ] **S5.P2.T02 批量确认出库** `已编码·未确认`
  - API: — `/wine/confirm_qj_bef_out`
  - 备注: — `/wine/confirm_qj_bef_out` [2026-09-20 续轮核验] 批量确认已捕获会话身份/代际及不可变真实ids，取消/断线/换人/同账号重登拒绝旧操作，迟到结果不刷新新页；API保持ids合同，已补回归。
  - 分组: 
- [ ] **S5.P2.T03 批量驳回** `已编码·未确认`
  - API: — `/wine/back_qj_bef_out`
  - 备注: — `/wine/back_qj_bef_out` [2026-09-20 续轮核验] 批量驳回保留bef_out_ids合同；弹层及回包复核会话和选中记录，取消/换人/断线拒绝旧操作；不再展示后端未接受的原因输入。
  - 分组: 
- [ ] **S5.P2.T04 授权确认** `已编码·未确认`
  - API: — `/wine/confirm_auth_qj_bef_out`
  - 备注: — `/wine/confirm_auth_qj_bef_out` [2026-09-20] 已接真实库存/数量与need_waiter_auth，账号/卡码授权及取消/失败保留草稿已测；自动读卡未接，未验证真实写入。
  - 分组: 
### S5.P3 `/wine/saveLib` 存酒库

- [ ] **S5.P3.T01 列表** `已编码·未确认`
  - API: — `POST /wine/get_wine_invt`；导出 `/wine/rpt/exp_wine_invt`
  - 备注: — `POST /wine/get_wine_invt`；导出 `/wine/rpt/exp_wine_invt`
  - 分组: 
- [ ] **S5.P3.T02 过期延期** `已编码·未确认`
  - API: — `/wine/delay_wine_invt2`
  - 备注: — `/wine/delay_wine_invt2`
  - 分组: 
- [ ] **S5.P3.T03 库存充公** `已编码·未确认`
  - API: — `/wine/cg_wine_invt`
  - 备注: — `/wine/cg_wine_invt`
  - 分组: 
### S5.P4 `/wine/saveLibChild` 存酒库子订单

- [ ] **S5.P4.T01 列表** `已编码·未确认`
  - API: — `POST /wine/rpt/get_wine_invt_sub_order`
  - 备注: — `POST /wine/rpt/get_wine_invt_sub_order`
  - 分组: 
### S5.P5 `/wine/passTime` 过期待处理

- [ ] **S5.P5.T01 列表+导出** `已编码·未确认`
  - API: — `/wine/get_wine_invt_expired`；导出 `/wine/rpt/exp_wine_invt_expired`
  - 备注: — `/wine/get_wine_invt_expired`；导出 `/wine/rpt/exp_wine_invt_expired` [2026-09-20 源码差异审计] 导出仍未完成：Flutter 使用无源依据的 /wine/export_* 且返回 void，仅提示指令下发；Vue 使用 binaryFilePost 到 /wine/rpt/exp_* 或 /wine/exp_wine_invt_grid，需交付文件。证据 wine_api.dart:274-325。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 续轮修复] 导出子功能已改真实二进制接口及文件交付，后端JSON错误不会另存Excel；页面成功需保存成功。列表/业务全链路仍待真实验收。 详见2026-09-20-parity-round2.md。
  - 分组: 
- [ ] **S5.P5.T02 过期充公** `已编码·未确认`
  - API: — `/wine/cg_expired_wine_invt`
  - 备注: — `/wine/cg_expired_wine_invt`
  - 分组: 
- [ ] **S5.P5.T03 过期延期** `已编码·未确认`
  - API: — `/wine/delay_wine_invt`
  - 备注: — `/wine/delay_wine_invt`
  - 分组: 
### S5.P6 `/wine/saveLibAllData` 存酒库库存

- [ ] **S5.P6.T01 网格+明细+导出** `已编码·未确认`
  - API: — `/wine/get_wine_invt_grid` `/wine/get_wine_invt_grid_dtl` `/wine/exp_wine_invt_grid`
  - 备注: — `/wine/get_wine_invt_grid` `/wine/get_wine_invt_grid_dtl` `/wine/exp_wine_invt_grid` [2026-09-20 源码差异审计] 导出仍未完成：Flutter 使用无源依据的 /wine/export_* 且返回 void，仅提示指令下发；Vue 使用 binaryFilePost 到 /wine/rpt/exp_* 或 /wine/exp_wine_invt_grid，需交付文件。证据 wine_api.dart:274-325。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 续轮修复] 库存网格/明细导出按原接口body保存真实文件，Web触发下载，原生显示应用下载目录实际路径；无覆盖旧文件。Android公共下载/分享入口和真实端侧下载仍待验证。 详见2026-09-20-parity-round2.md。
  - 分组: 
### S5.P7 `/wine/toStore` 待充公 · `/wine/storeLib` 充公库 · `/wine/toStoreDetail` 充公出库单

- [ ] **S5.P7.T01 待充公列表与操作** `已编码·未确认`
  - API: — 从 `toStore.vue` 抄全部 POST
  - 备注: — 从 `toStore.vue` 抄全部 POST
  - 分组: 
- [ ] **S5.P7.T02 充公库列表** `已编码·未确认`
  - 备注: — `storeLib.vue`
  - 分组: 
- [ ] **S5.P7.T03 充公出库单** `已编码·未确认`
  - 备注: — `toStoreDetail.vue`
  - 分组: 
### S5.P8 `/wine/userConfig` 用户管理

- [ ] **S5.P8.T01 客户列表** `已编码·未确认`
  - API: — `POST /wine/get_wine_cust_list`
  - 备注: — `POST /wine/get_wine_cust_list`
  - 分组: 
- [ ] **S5.P8.T02 改姓名/手机** `已编码·未确认`
  - API: — `/wine/save_wine_cust_name` `/wine/wine_chk_phone_usable` `/wine/chg_wine_cust_phone`
  - 备注: — `/wine/save_wine_cust_name` `/wine/wine_chk_phone_usable` `/wine/chg_wine_cust_phone`
  - 分组: 
- [ ] **S5.P8.T03 短信批量开关** `已编码·未确认`
  - API: — `/wine/batch_set_enable_sms`
  - 备注: — `/wine/batch_set_enable_sms`
  - 分组: 
- [ ] **S5.P8.T04 黑名单批量加/删/导入** `已编码·未确认`
  - API: — `/wine/batch_add_wine_blacklist` `/batch_del_wine_blacklist` `/exp_wine_blacklist_tpl` `/imp_wine_blacklist_chk`
  - 备注: — `/wine/batch_add_wine_blacklist` `/batch_del_wine_blacklist` `/exp_wine_blacklist_tpl` `/imp_wine_blacklist_chk`
  - 分组: 
### S5.P9 客户中心 `/wine/customSaveLib` 待入库 · `/wine/customGetLib` 取酒

- [ ] **S5.P9.T01 客户待入库** `已编码·未确认`
  - 备注: — `customSaveLib.vue` 内接口
  - 分组: 
- [ ] **S5.P9.T02 客户取酒** `已编码·未确认`
  - 备注: — `customGetLib.vue` 内接口
  - 分组: 
### S5.P10 报表

- [ ] **S5.P10.T01 /wine/saveAndGetReport 存取酒记录** `已编码·未确认`
  - 分组: 
- [ ] **S5.P10.T02 /wine/passTimeLongReport 延期记录** `已编码·未确认`
  - 分组: 
- [ ] **S5.P10.T03 /wine/toStoreOutReport 充公出库记录** `已编码·未确认`
  - 分组: 
- [ ] **S5.P10.T04 /wine/saveAllDataReport 入库统计** `已编码·未确认`
  - 分组: 
- [ ] **S5.P10.T05 /wine/getAllDataReport 出库统计** `已编码·未确认`
  - 分组: 
- [ ] **S5.P10.T06 /wine/toStoreAllDataReport 充公统计** `已编码·未确认`
  - 分组: 
- [ ] **S5.P10.T07 /wine/saveWineSearch 存酒查询** `已编码·未确认`
  - 分组: 
- [ ] **S5.P10.T08 /wine/nowInvtReport 日实时库存** `已编码·未确认`
  - 分组: 
### S5.P11 借还

- [ ] **S5.P11.T01 借酒页面与多商品借酒表单** `已编码·未确认`
  - 备注: — `borrowWine.vue` [2026-09-20] 列表字段已修；多商品及真实员工表单待完成，旧错误body被校验拒绝。wine_borrow_form_test两项预期红测尚未绿，不是完整迁移。 [2026-09-20 本轮闭环] 真实员工和商品选择、多商品数组、库存预检、失败保留草稿与取消/会话失效防护已接。此前两项红测已修复；日期与分页仍未实现，独立跟踪S5.P11.T04，整页尚非已确认。
  - 分组: 
- [ ] **S5.P11.T02 还酒页面与多商品还酒表单** `已编码·未确认`
  - 备注: — `returnWine.vue` [2026-09-20] 列表字段已修；多商品/员工/数量约束表单待完成，不能把旧手填表单视为还原。 [2026-09-20 本轮闭环] 真实员工、未还库存选择及多商品归还表单已接；日期与分页仍未实现，独立跟踪S5.P11.T04。未执行真实还酒写入。
  - 分组: 
- [ ] **S5.P11.T04 借还列表日期筛选与分页** `已编码·未确认`
  - Vue: wine/borrowWine/borrowWine.vue 与 returnWine/returnWine.vue
  - Flutter: wine_borrow_return_views.dart / wine_api.dart
  - API: /wine/get_wine_borrow_return_list
  - 备注: 2026-09-20 核对：旧版7天/30天/近3个月/日期范围以及page_num/page_size/row_cnt完整分页尚未移植；Flutter仅首20条，空日期。新增借还表单的实现不代表本项完成。 [2026-09-20 续轮核验] 已接近7/30/90天、起止日期、搜索重置页1、真实row_cnt分页与跨页序号；分页沿用已提交查询，迟到响应/会话变化不覆盖新结果。手机与借还表单集成回归通过，未作真实业务写入。
  - 分组: 
- [ ] **S5.P11.T03 /wine/unreturnedWine 未还酒水** `已编码·未确认`
  - 备注: — `unreturnedWine.vue` [2026-09-20 源码差异审计] 导出仍未完成：Flutter 使用无源依据的 /wine/export_* 且返回 void，仅提示指令下发；Vue 使用 binaryFilePost 到 /wine/rpt/exp_* 或 /wine/exp_wine_invt_grid，需交付文件。证据 wine_api.dart:274-325。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 续轮修复] 未还页面按当前Vue实际caller导出/wine/exp_wine_borrow_invt_list且body为空；旧未使用rpt导出接口同时对齐。导出前后校验Wine身份、在线、session及generation。 详见2026-09-20-parity-round2.md。
  - 分组: 

## S6 排队

对照：src/router/queue/index.js  ·  1 项  ·  已确认 0  ·  已编码未确认 1  ·  未开始 0

### S6.P1 `/queue/bigScreen` 叫号大屏

- [ ] **S6.P1.T01 全屏只读大屏** `已编码·未确认`
  - Vue: `bigScreen.vue`；数据：实时同步排队类型列表
  - Flutter: 新建 `queue_big_screen.dart`；Web/Windows 路由；Android 默认不在范围除非台账批准
  - 完成: 五列字段与空态「暂无数据」；门店名+日期；随 `/sync` 更新
  - 分组: 

## S7 BMS 门店后台

对照：src/router/bms/index.js（重构前注释之前）  ·  50 项  ·  已确认 0  ·  已编码未确认 50  ·  未开始 0

### S7.P0 后台壳

- [ ] **S7.P0.T01 BMS 侧栏按角色模块渲染** `已编码·未确认`
  - Vue: `BMS.vue` 菜单
  - Flutter: packages/card_table/lib/src/bms_nav_screen.dart (BmsNavScreen)
  - 完成: 无模块则不显示；点菜单进对应页；Windows/Web 必做，Android 默认不在范围
  - 备注: [2026-09-20 源码差异审计] BMS 固定展示所有菜单，未对齐 Vue client/roleIds/sys_modules/safeMode 筛选。证据 bms_nav_screen.dart groups 与 ManagementSystem.vue:386。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 第三轮] 已按原ManagementSystem/storeNavList过滤BMS安全模式人员；无权限快照不加载，无权限initialPage也拦截。撤权精准关闭owned弹窗/短信详情/改密，不误关新登录及其popup；主程序observer已接同一实例。 详见2026-09-20-parity-round3.md。
  - 分组: 
### S7.P1 人员

- [ ] **S7.P1.T01 /BMS/codeRules 工号生成规则读/存** `已编码·未确认`
  - Vue: `codeRules/codeRules.vue`；API `POST /emp/gen_rule` `/emp/save_gen_rule`（`src/api/BMS/genRule/index.js`）
  - Flutter: packages/card_table/lib/src/bms_staff_views.dart
  - 备注: [2026-09-20 源码差异审计] 工号规则模型字段不匹配：Flutter prefix/start_no/step/bit_len；Vue passwd_use_code/fixed_passwd/code_length。证据 bms_staff_views.dart:64、Vue BMS/genRule/genRule.vue:78。待重做契约。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 续轮修复] 已实现原Web passwd_use_code/fixed_passwd/code_length读写和2–8位校验，失败不覆盖默认值；契约及组件测试通过。 详见2026-09-20-parity-round2.md。
  - 分组: 
- [ ] **S7.P1.T02 /BMS/stationConfig 岗位列表** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_staff_views.dart
  - API: — `POST /station/list`（`src/api/BMS/station/index.js`）
  - 备注: — `POST /station/list`（`src/api/BMS/station/index.js`）
  - 分组: 
- [ ] **S7.P1.T03 岗位新建/详情/保存** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_staff_views.dart
  - API: — `/station/new` `/station/get` `/station/save`；抽屉 `drawerAddOrUpdateStation.vue`
  - 备注: — `/station/new` `/station/get` `/station/save`；抽屉 `drawerAddOrUpdateStation.vue`
  - 分组: 
- [ ] **S7.P1.T04 岗位有效/无效/删除** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_staff_views.dart
  - API: — `/station/disable` `/enable` 及删除接口
  - 备注: — `/station/disable` `/enable` 及删除接口
  - 分组: 
- [ ] **S7.P1.T05 岗位可点区域/可点商品/特饮/优惠商品范围** `已编码·未确认`
  - Vue: `drawerCanOrderArea.vue` `drawerCanOrderPrd.vue` `drawerCanTYPrd.vue` `drawerCanYHPrd.vue`
  - Flutter: packages/card_table/lib/src/bms_staff_views.dart
  - 分组: 
- [ ] **S7.P1.T06 岗位登录配置 / 看单 / ERP / 充值积分 / 角色授权 / 其它设置** `已编码·未确认`
  - Vue: `drawerLoginConfig.vue` `drawerLookOrder.vue` `drawerErpConfig.vue` `drawerRechargePointConfig.vue` `drawerRoleAuth.vue` `drawerSetConfig.vue`
  - Flutter: packages/card_table/lib/src/bms_staff_views.dart
  - 完成: 每个抽屉独立测试；权限字段与 Vue 提交 body 一致
  - 分组: 
- [ ] **S7.P1.T07 /BMS/employeeList 员工列表** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_staff_views.dart
  - API: — `POST /emp/list`（`src/api/BMS/emp/index.js`，body 用 `ids`）
  - 备注: — `POST /emp/list`（`src/api/BMS/emp/index.js`，body 用 `ids`）
  - 分组: 
- [ ] **S7.P1.T08 员工新建/编辑** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_staff_views.dart
  - API: — `/emp/new` `/emp/get` `/emp/save`；`drawerAddOrUpdate.vue`
  - 备注: — `/emp/new` `/emp/get` `/emp/save`；`drawerAddOrUpdate.vue`
  - 分组: 
- [ ] **S7.P1.T09 员工绑定/其它/导入/克隆/同组/下属** `已编码·未确认`
  - Vue: `drawerBindEmp.vue` `drawerEmpOther.vue` `drawerImportEmp.vue` `drawerMyClones.vue` `drawerMySameGroup.vue` `drawerMySubordinates.vue`
  - Flutter: packages/card_table/lib/src/bms_staff_views.dart
  - 分组: 
- [ ] **S7.P1.T10 批量重置密码** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_staff_views.dart
  - API: — `POST /emp/batch_reset_pwd`
  - 备注: — `POST /emp/batch_reset_pwd` [2026-09-20 源码差异审计] 批量重置密码 Flutter 发送 ids，Vue 使用 emp_ids。证据 bms_api.dart:95 与 Vue BMS/emp/emp.vue:176，尚未修复。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 续轮修复] 已修复批量重置字段emp_ids，添加确认、重复提交保护和真实失败反馈；未执行真实密码变更。 详见2026-09-20-parity-round2.md。
  - 分组: 
- [ ] **S7.P1.T11 /BMS/onboardingApproval 入职审批** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_staff_views.dart
  - API: — `dept/onboardingApproval/onboardingApproval.vue` 内接口
  - 备注: — `dept/onboardingApproval/onboardingApproval.vue` 内接口 [2026-09-20 源码差异审计] 当前 Flutter onboarding_list/audit_onboarding/business_list/set_business 无 Vue 源码契约；应按 get_emp_rz_list、emp_rz_approve_batch_yes/deny、get_bs_sales_list/batch_add_bs_sales/remove_bs_sales 对齐。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 续轮修复] 已实现原端点的状态分页、批量通过/驳回、编辑、部门岗位与上级选择；修复岗位compact字段n，失败保留输入。仍待真实账号端侧验收。 详见2026-09-20-parity-round2.md。
  - 分组: 
- [ ] **S7.P1.T12 /BMS/businessEmp 商务组订位人** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_staff_views.dart
  - API: — `src/api/BMS/emp/businessEmp.js`
  - 备注: — `src/api/BMS/emp/businessEmp.js` [2026-09-20 源码差异审计] 当前 Flutter onboarding_list/audit_onboarding/business_list/set_business 无 Vue 源码契约；应按 get_emp_rz_list、emp_rz_approve_batch_yes/deny、get_bs_sales_list/batch_add_bs_sales/remove_bs_sales 对齐。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 续轮修复] 已实现待选/已选订位人、部门关键词筛选、批量添加和删除，按原get_bs_sales_list/batch_add_bs_sales/remove_bs_sales契约；全部BMS loader加入会话/在线/epoch守卫。 详见2026-09-20-parity-round2.md。
  - 分组: 
### S7.P2 商品

- [ ] **S7.P2.T01 /BMS/prdConfig 一级分类 CRUD** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_product_views.dart
  - API: — `oneCateTable.vue`；API `src/api/BMS/ocate/index.js`
  - 备注: — `oneCateTable.vue`；API `src/api/BMS/ocate/index.js`
  - 分组: 
- [ ] **S7.P2.T02 二级分类 CRUD** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_product_views.dart
  - API: — `twoCateTable.vue`；`src/api/BMS/tcate/index.js`
  - 备注: — `twoCateTable.vue`；`src/api/BMS/tcate/index.js`
  - 分组: 
- [ ] **S7.P2.T03 商品列表/新建/保存/有效无效/删除** `已编码·未确认`
  - Vue: `prdTable.vue` `drawerAddOrUpdatePrd.vue`
  - Flutter: packages/card_table/lib/src/bms_product_views.dart
  - API: `POST /prd/list` `/prd/new` `/prd/get` `/prd/save` `/prd/disable` `/prd/enable` `/prd/del`（`src/api/BMS/Prd/index.js`）
  - 分组: 
- [ ] **S7.P2.T04 套餐商品 / 绑定 / 导入 / 出品库区域** `已编码·未确认`
  - Vue: `drawerAddOrUpdateGroupPrd.vue` `drawerBindPrd.vue` `drawerImportAll.vue` `setAreaLibrary.vue` `setTwoCategory.vue` `choosePrd.vue`
  - Flutter: packages/card_table/lib/src/bms_product_views.dart
  - API: `/prd/ass_items` `/prd/erp_prds` 等页面实际调用
  - 分组: 
- [ ] **S7.P2.T05 /BMS/uploadProImg 商品图片上传（Web/Android）** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_product_views.dart
  - API: — `uploadProImg/uploadProImg.vue`
  - 备注: — `uploadProImg/uploadProImg.vue` [2026-09-20 源码差异审计] 上传按钮仅显示已打开图片选择器，没有选择文件及上传调用。证据 bms_product_views.dart:323。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-21 续轮] 已接批量按名匹配/逐张OSS上传/最终绑定、缺图单品补传、默认图配置。Android原生SAF只读用户选择URI，以opaque句柄懒加载并有界读取；Web原生file input。签名与OSS隔离不携带tk/stk、HTTPS不降级；未真实上传/绑定，桌面原生选择见M0.P3.T05。 详见2026-09-21-images-sout-reports.md。
  - 分组: 
- [ ] **S7.P2.T06 /BMS/taocanTemplate 套餐可选组模板** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_product_views.dart
  - 备注: — `taocanTemplate.vue` [2026-09-20 源码差异审计] Flutter /prd/taocan_templates 未见 Vue 源码支持；模板页仅读取列表，不能视为完整编辑能力。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。
  - 分组: 
- [ ] **S7.P2.T07 小费特饮价格矩阵配置** `已编码·未确认`
  - Vue: src/views/ManagementSystem/BMS/fcPriceConfig
  - API: /prd/get_fc_prd_cfg_list; get_fc_prd_cfg_items; batch_add_fc_prd; batch_del_fc_prd; save_fc_prd_plan_price
  - 完成: 入口、商品检索添加/批删、方案列与逐格整数分保存，0价合法，成功响应才展示保存成功
  - 备注: 2026-09-20：商品管理入口、双Tab、矩阵逐格分金额保存（含0）、分类检索批加/批删已接真实接口。价格模块12项契约和界面测试通过；未改真实价格，人工验收待做。
  - 分组: 价格方案
- [ ] **S7.P2.T08 价格方案与员工归属管理** `已编码·未确认`
  - Vue: src/views/ManagementSystem/BMS/fcPriceConfig
  - API: /prd/get_fc_price_plan_list; get_fc_plan_emp_items; remove_emp_from_plan; new_fc_price_plan; save_fc_price_plan; batch_del_fc_price_plan
  - 完成: 新增编辑删除、部门关键词筛选、当前/被其它方案占用；立即移除与待保存添加分开，取消不回滚已生效移除
  - 备注: 2026-09-20：方案新建/编辑/删除、部门多选检索、当前成员和其它占用状态、立即移除与草稿分离已接真接口；取消编辑不伪造回滚移除。价格模块12项契约/界面测试通过，未改真实员工，人工验收待做。 [2026-09-22 增量复核] 对齐旧Web f179674d：仅其他方案占用员工可移除并添加；立即从旧方案移除，加入本地草稿，确定才保存到新方案，取消不恢复旧方案归属。独立语义审查通过；发现390宽度点击问题，正在补窄屏回归与修复，不能视为手机验收完成。 [2026-09-22 复测] FC窄屏布局已修复，390宽度回归验证按钮可点击并完成移除→本地选中→确定保存；全工作区1340项通过。仍待用户实际验收。
  - 分组: 价格方案
### S7.P3 卡台

- [ ] **S7.P3.T01 /BMS/cardConfig 区域 CRUD** `已编码·未确认`
  - Vue: `cardConfigTable/area.vue`；API `POST /region/list` 等 `src/api/BMS/region/index.js`
  - Flutter: packages/card_table/lib/src/bms_card_views.dart
  - 分组: 
- [ ] **S7.P3.T02 卡台 CRUD / 排序 / 二维码 / 必点商品** `已编码·未确认`
  - Vue: `card.vue` `drawerAddOrUpdateCard.vue` `drawerAddAllCard.vue` `drawerShowQr.vue` `drawerConfigOrderPrd.vue`
  - Flutter: packages/card_table/lib/src/bms_card_views.dart
  - API: `POST /seat/list` `/seat/new` `/seat/get` `/seat/save` `/seat/disable` `/seat/enable` `/seat/del` `/seat/move_dsp`（`src/api/BMS/seat/index.js`）
  - 分组: 
- [ ] **S7.P3.T03 /BMS/cardMinGroup 卡台抵消组** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_card_views.dart
  - API: — `cardMinGroup.vue`；API `src/api/BMS/seat_grp/index.js`
  - 备注: — `cardMinGroup.vue`；API `src/api/BMS/seat_grp/index.js`
  - 分组: 
- [ ] **S7.P3.T04 /BMS/cardTips 卡台标签** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_card_views.dart
  - API: — `cardTips.vue`；`src/api/BMS/cardTips/index.js`
  - 备注: — `cardTips.vue`；`src/api/BMS/cardTips/index.js`
  - 分组: 
- [ ] **S7.P3.T05 /BMS/arriveRules 计抵达规则** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_card_views.dart
  - API: — `arriveRules.vue`；`src/api/BMS/arriveRules/index.js`
  - 备注: — `arriveRules.vue`；`src/api/BMS/arriveRules/index.js`
  - 分组: 
### S7.P4 限额限量

- [ ] **S7.P4.T01 /BMS/prdGroupConfig 商品组** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_limit_views.dart
  - API: — `prdGroupConfig.vue`；`src/api/BMS/pgrp/index.js`
  - 备注: — `prdGroupConfig.vue`；`src/api/BMS/pgrp/index.js`
  - 分组: 
- [ ] **S7.P4.T02 /BMS/limitConfig 限额限量** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_limit_views.dart
  - API: — `limitConfig.vue` `drawerAddOrUpdateLimit.vue`；`src/api/BMS/freelmt/index.js`
  - 备注: — `limitConfig.vue` `drawerAddOrUpdateLimit.vue`；`src/api/BMS/freelmt/index.js`
  - 分组: 
### S7.P5 门店 / 支付 / 设备

- [ ] **S7.P5.T01 /BMS/store 门店信息读/存** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_store_device_views.dart
  - API: — `POST /org/get_info` `/org/save_info`；省市区 `/cfg/addr/provinces` `/cfg/addr/districts`
  - 备注: — `POST /org/get_info` `/org/save_info`；省市区 `/cfg/addr/provinces` `/cfg/addr/districts`
  - 分组: 
- [ ] **S7.P5.T02 /BMS/restore 营业日恢复** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_store_device_views.dart
  - API: — `POST /wkd/restore`；Vue `store/restore.vue`
  - 备注: — `POST /wkd/restore`；Vue `store/restore.vue`
  - 分组: 
- [ ] **S7.P5.T03 /BMS/payList 渠道管理** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_store_device_views.dart
  - API: — `POST /paycnl/list` `/paycnl/items` `/paycnl/add_used` `/paycnl/del_used` `/paycnl/new`（`src/api/BMS/paycnl/index.js`）
  - 备注: — `POST /paycnl/list` `/paycnl/items` `/paycnl/add_used` `/paycnl/del_used` `/paycnl/new`（`src/api/BMS/paycnl/index.js`）
  - 分组: 
- [ ] **S7.P5.T04 /BMS/printers 打印机 CRUD** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_store_device_views.dart
  - API: — `POST /printer/list` `/new` `/get` `/save` `/disable`（`src/api/BMS/printer/index.js`）
  - 备注: — `POST /printer/list` `/new` `/get` `/save` `/disable`（`src/api/BMS/printer/index.js`）
  - 分组: 
- [ ] **S7.P5.T05 /BMS/outLibConfig 出品库 CRUD** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_store_device_views.dart
  - API: — `POST /mklib/list` `/new` `/get` `/new_printer`（`src/api/BMS/mklib/index.js`）
  - 备注: — `POST /mklib/list` `/new` `/get` `/new_printer`（`src/api/BMS/mklib/index.js`）
  - 分组: 
- [ ] **S7.P5.T06 /BMS/bills 小票配置读/存** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_store_device_views.dart
  - API: — `POST /bill/get` `/bill/save`；预览 `bills/drawerPreview.vue`
  - 备注: — `POST /bill/get` `/bill/save`；预览 `bills/drawerPreview.vue`
  - 分组: 
- [ ] **S7.P5.T07 /BMS/terminalBms 终端列表/打印机/清设备/快捷码** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_store_device_views.dart
  - API: `POST /lic/list` `/lic/get_prts` `/lic/get_wine_store_prts` `/lic/save_prt` `/lic/clear_term` `/lic/gen_quick_code`
  - 分组: 
### S7.P6 报表配置 / 小程序 / 要求 / 理由 / 规则

- [ ] **S7.P6.T01 /BMS/reportTYConfig 鸡尾酒导出配置** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_rules_reports_views.dart
  - API: — `src/api/BMS/reportConfig/`
  - 备注: — `src/api/BMS/reportConfig/` [2026-09-20 源码差异审计] 页面只有静态文本，没有读取/保存配置。证据 bms_rules_reports_views.dart:9-100；原已编码状态不代表功能实现。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 真实配置续轮] 已接部门树、独立父子勾选、已配置禁选、按树顺序批量加入sheet及删除/刷新；失败保留选择，手机可操作。 共用29操作封闭合同及在线/身份/代际保护，源码与定向自动化复核通过；未执行真实门店配置写入。见2026-09-20-bms-report-configuration.md。
  - 分组: 
- [ ] **S7.P6.T02 /BMS/sealPrdConfig 销售商品统计设置** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_rules_reports_views.dart
  - 备注: [2026-09-20 源码差异审计] 页面只有静态文本，没有读取/保存配置。证据 bms_rules_reports_views.dart:9-100；原已编码状态不代表功能实现。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 真实配置续轮] 按原版纠正旧误名“分类渠道统计设置”；已接两级分类/名称拼音、20条候选分页、全选与已配禁选、批加/删除，保留商品名/分类/单价。 共用29操作封闭合同及在线/身份/代际保护，源码与定向自动化复核通过；未执行真实门店配置写入。见2026-09-20-bms-report-configuration.md。
  - 分组: 
- [ ] **S7.P6.T03 /BMS/statisticalGroupConfig 统计类别配置** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_rules_reports_views.dart
  - API: — `src/api/BMS/statistical/`
  - 备注: — `src/api/BMS/statistical/` [2026-09-20 源码差异审计] 页面只有静态文本，没有读取/保存配置。证据 bms_rules_reports_views.dart:9-100；原已编码状态不代表功能实现。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 真实配置续轮] 已接新建、改名、营业类型、批删、排序及分类/商品关联；补商品分类/类型/营业类型、查询重置。真实请求init1/2校验进入UI测试，失败不丢稿。 共用29操作封闭合同及在线/身份/代际保护，源码与定向自动化复核通过；未执行真实门店配置写入。见2026-09-20-bms-report-configuration.md。
  - 分组: 
- [ ] **S7.P6.T04 /BMS/channelGroupConfig 渠道类别配置** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_rules_reports_views.dart
  - API: — `src/api/BMS/channel/`
  - 备注: — `src/api/BMS/channel/` [2026-09-20 源码差异审计] 页面只有静态文本，没有读取/保存配置。证据 bms_rules_reports_views.dart:9-100；原已编码状态不代表功能实现。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 真实配置续轮] 已接新建/编辑、渠道归属锁定、批删及排序；写前复核归属，取消/会话变化拒绝旧提交。 共用29操作封闭合同及在线/身份/代际保护，源码与定向自动化复核通过；未执行真实门店配置写入。见2026-09-20-bms-report-configuration.md。
  - 分组: 
- [ ] **S7.P6.T05 /BMS/miniProgressConfig 高毛利商品配置** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_rules_reports_views.dart
  - API: — `src/api/BMS/miniProgressConfig/`
  - 备注: — `src/api/BMS/miniProgressConfig/` [2026-09-20 源码差异审计] 页面只有静态文本，没有读取/保存配置。证据 bms_rules_reports_views.dart:9-100；原已编码状态不代表功能实现。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 真实配置续轮] 用于服务员销售高毛利报表，不是推荐商品；已接真实配置/候选查询、分类分页、批加/删除、状态及价格显示，已配禁选与写前复核。 共用29操作封闭合同及在线/身份/代际保护，源码与定向自动化复核通过；未执行真实门店配置写入。见2026-09-20-bms-report-configuration.md。
  - 分组: 
- [ ] **S7.P6.T06 /BMS/requireConfig 要求类型+要求项** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_rules_reports_views.dart
  - API: `POST /cfg/rqm/tree` `/search` `/type_list` `/list`（`src/api/BMS/require/index.js`）
  - 分组: 
- [ ] **S7.P6.T07 理由四页（优惠/退单/退卡/取消优惠）** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_rules_reports_views.dart
  - API: `POST /rsn/list` `/rsn/new` `/rsn/save` `/rsn/del`；用页面 query/type 区分，不要做成四个包
  - 备注: 路由: `/BMS/YHReason` `/BMS/backReason` `/BMS/backVipCard` `/BMS/QXYHReason` 共用 `reason/reason.vue`
  - 分组: 
- [ ] **S7.P6.T08 /BMS/terminalRules 规则配置** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_rules_reports_views.dart
  - API: — `src/api/BMS/terminalRules/`
  - 备注: — `src/api/BMS/terminalRules/`
  - 分组: 
- [ ] **S7.P6.T09 /BMS/vipRules 会员卡规则** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_rules_reports_views.dart
  - API: — `terminalRules/vipRules.vue`
  - 备注: — `terminalRules/vipRules.vue`
  - 分组: 
### S7.P7 存酒设置 / 抽成 / 短信

- [ ] **S7.P7.T01 /BMS/saveConfig 存酒设置读/存** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_wine_sms_views.dart
  - API: — `POST /wine/cfg/get` `/wine/cfg/save`
  - 备注: — `POST /wine/cfg/get` `/wine/cfg/save`
  - 分组: 
- [ ] **S7.P7.T02 /BMS/wineInfo 可存酒水增删改过期** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_wine_sms_views.dart
  - API: — `/wine/cfg/prd_items` `/add_prds` `/del_prds` `/get_prds` `/set_prd_expired`
  - 备注: — `/wine/cfg/prd_items` `/add_prds` `/del_prds` `/get_prds` `/set_prd_expired`
  - 分组: 
- [ ] **S7.P7.T03 /BMS/cutPrd 抽成管理** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_wine_sms_views.dart
  - API: — `src/api/BMS/cutPrd/` + `cutPrdCom/**`
  - 备注: — `src/api/BMS/cutPrd/` + `cutPrdCom/**`
  - 分组: 
- [ ] **S7.P7.T04 /BMS/accountInfo 短信账户** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_wine_sms_views.dart
  - API: — `src/api/BMS/messageConfig/`
  - 备注: — `src/api/BMS/messageConfig/` [2026-09-20 源码差异审计] Flutter /sms/account、/sms/records 不匹配 Vue /sms_mgr/get_acct_info、get_sms_records/get_sms_record_dtls。证据 bms_api.dart:715/724 与 src/api/BMS/messageConfig/index.js。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 第三轮] 真实账户7字段无body查询已完成；self_check {mobile}已接确认提示及成功后60秒倒计时，Web沿用currentTime、native应用支持目录保存时间。失败不假成功，pending防重发；读记录失败可刷新重试，不以旧持久值覆盖内存冷却。全部验证用fake，未发真实短信。 详见2026-09-20-parity-round3.md。
  - 分组: 
- [ ] **S7.P7.T05 /BMS/messageDetail 短信明细** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_wine_sms_views.dart
  - 备注: [2026-09-20 源码差异审计] Flutter /sms/account、/sms/records 不匹配 Vue /sms_mgr/get_acct_info、get_sms_records/get_sms_record_dtls。证据 bms_api.dart:715/724 与 src/api/BMS/messageConfig/index.js。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 第三轮] 真实短信日账单支持日期/类型与分页，详情支持status/mobile、分页及模板p1..p6还原；详情route受管理权限撤销清理；请求失败可见可重试。 详见2026-09-20-parity-round3.md。
  - 分组: 
- [ ] **S7.P7.T06 /BMS/messageResult 短信结果查询** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/bms_wine_sms_views.dart
  - 备注: [2026-09-20 源码差异审计] 短信结果查询仅静态已就绪文字，无查询调用。证据 bms_wine_sms_views.dart:461；Vue 使用 /sms_mgr/get_mobile_send_rst。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 第三轮] 手机号发送结果查询已接/sms_mgr/get_mobile_send_rst，展示模板类型/内容/条数/时间/结果原因，不再静态已就绪。守卫沿用当前BMS会话/在线/generation。 详见2026-09-20-parity-round3.md。
  - 分组: 

## S8 ERP 仓库

对照：src/router/erp/index.js（重构前注释之前）  ·  27 项  ·  已确认 0  ·  已编码未确认 27  ·  未开始 0

### S8.P1 主数据

- [ ] **S8.P1.T01 /ERP/home 首页** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/erp_master_views.dart
  - API: — `src/views/ManagementSystem/ERP/home/home.vue`；`src/api/ERP/home/`
  - 备注: — `src/views/ManagementSystem/ERP/home/home.vue`；`src/api/ERP/home/`
  - 分组: 
- [ ] **S8.P1.T02 /ERP/erpLib 仓库管理 CRUD** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/erp_master_views.dart
  - API: — `erpLib/erpLib.vue`；`src/api/ERP/erpLib/` 与 `store/`
  - 备注: — `erpLib/erpLib.vue`；`src/api/ERP/erpLib/` 与 `store/`
  - 分组: 
- [ ] **S8.P1.T03 /ERP/mats 物料列表** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/erp_master_views.dart
  - API: — `POST /mat/cate_list` `/mat/list`（`src/api/ERP/mat/index.js`）
  - 备注: — `POST /mat/cate_list` `/mat/list`（`src/api/ERP/mat/index.js`）
  - 分组: 
- [ ] **S8.P1.T04 物料新建/保存/单位** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/erp_master_views.dart
  - API: — `/mat/new` `/mat/save`；页面内其余按钮各写一测
  - 备注: — `/mat/new` `/mat/save`；页面内其余按钮各写一测
  - 分组: 
- [ ] **S8.P1.T05 /ERP/comparePrd 商品对照** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/erp_master_views.dart
  - API: — `src/api/ERP/comparePrd/`
  - 备注: — `src/api/ERP/comparePrd/`
  - 分组: 
- [ ] **S8.P1.T06 /ERP/supplierConfig 供应商 CRUD** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/erp_master_views.dart
  - API: — `POST /supplier/list` `/new` `/get` `/save`（`src/api/ERP/supplier/index.js`）
  - 备注: — `POST /supplier/list` `/new` `/get` `/save`（`src/api/ERP/supplier/index.js`）
  - 分组: 
### S8.P2 入库

- [ ] **S8.P2.T01 /ERP/anotherInLib 其他入库列表** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/erp_in_views.dart
  - API: — `POST /sin/list`（`src/api/ERP/sin/index.js`）
  - 备注: — `POST /sin/list`（`src/api/ERP/sin/index.js`）
  - 分组: 
- [ ] **S8.P2.T02 其他入库新建/物料检索** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/erp_in_views.dart
  - API: — `/sin/new` `/sin/mat_items`；`record_type` 按 Vue
  - 备注: — `/sin/new` `/sin/mat_items`；`record_type` 按 Vue [2026-09-20 源码差异审计] 本轮已移除 m_1 等假物料、固定数量和单价的真实提交，改为明确尚未接入提示。已有单据浏览保留；真实物料检索选择/数量价格/校验仍待实现。证据 erp_in_views.dart:39；unwired_write_safety_test.dart。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 第四轮] 真实新建入库已实现仓库/供应商/物料辅助接口、单位数量金额、专票src_amts与除1.13净额、平行数组和失败保留/成功刷新；仅新建子流程，不替代列表高级操作验收。 详见2026-09-20-parity-round4.md。
  - 分组: 
- [ ] **S8.P2.T03 /ERP/changeInLib 调拨入库** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/erp_in_views.dart
  - API: — `src/api/ERP/sind/`；`inLib/changeInLib.vue`
  - 备注: — `src/api/ERP/sind/`；`inLib/changeInLib.vue`
  - 分组: 
- [ ] **S8.P2.T04 /ERP/applyForInLib 入库异议** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/erp_in_views.dart
  - API: — 以 `applyForInLib.vue` 内 POST 为准
  - 备注: — 以 `applyForInLib.vue` 内 POST 为准
  - 分组: 
### S8.P3 出库

- [ ] **S8.P3.T01 其他出库列表、筛选、类似创建及红冲** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/erp_out_views.dart
  - API: — `src/api/ERP/sout/`；`outLib/anotherOutLib.vue`
  - 备注: — `src/api/ERP/sout/`；`outLib/anotherOutLib.vue` [2026-09-20 源码差异审计] 本轮已移除其他出库 m_1 假物料与固定数量/价格提交，改为尚未接入提示。现有单据浏览保留，新建出库未完成。证据 erp_out_views.dart:39。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-20 第四轮] 原整页任务拆细：新建与物料检索移至S8.P3.T04，已实现并回归；本任务继续跟踪原列表日期/类型/分页、类似创建、红冲/反审核，不能以新建完成宣称整页完成。 详见2026-09-20-parity-round4.md。 [2026-09-21 续轮] 已接真实日期/record_type/备注分页、无ic复制通过仓库物料查询库存、整单cs与分项hc分开、hc2禁选及提交前复核；失败查询清旧单/选中项，成功旧表单精确关闭防重复。详情打印未接，独立S8.P3.T05，不能推断整页全部验收。 详见2026-09-21-images-sout-reports.md。
  - 分组: 
- [ ] **S8.P3.T05 其他出库详情原生打印** `已编码·未确认`
  - Vue: src/views/ManagementSystem/ERP/outLib/anotherInOutCom/drawerDetail.vue
  - Flutter: erp_sout_pdf.dart + erp_sout_workflow_views.dart；PdfDocumentPrinter 三端系统打印；Web/native_client_shell回调
  - API: 无专用打印API，内容来自get_f_view
  - 备注: 源仅已完成单据可打印DOM，包含单据头/明细/红冲记录。不能把list/copy/hc完成推论为已支持打印。 [2026-09-22 整合复核] 已完成详情重读→中文PDF→系统打印接线，只允许view且状态精确已完成。头/明细/红冲/原明细sa合计/签名及多页长文QA已覆盖；预置OFL中文字体无运行时下载。派发后未知或失去上下文保留防重复锁，明确取消可重试。全工作区1554项通过；交给平台不等于纸张输出，未实际打印，Windows原生仍待验收。详见2026-09-22-credit-merchant-print-integration.md。
  - 分组: 
- [ ] **S8.P3.T04 其他出库新建与物料检索** `已编码·未确认`
  - Vue: anotherInOutCom/drawerAddOutLib.vue
  - Flutter: packages/card_table/lib/src/erp_in_views.dart; erp_out_views.dart
  - API: /sout/store_items; /sout/mat_items; /sout/new
  - 完成: 真实仓库物料、单位/库存、数量/价格/金额、切仓清空、失败保留与成功刷新；守卫会话/在线/generation
  - 备注: 从S8.P3.T01整页任务拆出新建子流程，21项ERP相关测试覆盖；未真实修改库存，仍待端侧验收。
  - 分组: 
- [ ] **S8.P3.T02 /ERP/changeOutLib 调拨出库** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/erp_out_views.dart
  - API: — `src/api/ERP/soutd/`
  - 备注: — `src/api/ERP/soutd/` [2026-09-20 源码差异审计] 调拨出库仅两个仓库ID/备注，未包含物料明细、输入校验与失败提示，不构成完整调拨流程。证据 erp_out_views.dart _openNewSoutdDialog。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。
  - 分组: 
- [ ] **S8.P3.T03 /ERP/applyForOutLib 出库异议** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/erp_out_views.dart
  - API: — `src/api/ERP/soutdd_yy/`
  - 备注: — `src/api/ERP/soutdd_yy/`
  - 分组: 
### S8.P4 空瓶

- [ ] **S8.P4.T01 /ERP/emptyInLibOrder 空瓶入库单** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/erp_empty_bottle_views.dart
  - API: — `src/api/ERP/emptyLib/`
  - 备注: — `src/api/ERP/emptyLib/`
  - 分组: 
- [ ] **S8.P4.T02 /ERP/emptyLib 空瓶仓** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/erp_empty_bottle_views.dart
  - 分组: 
- [ ] **S8.P4.T03 /ERP/emptyOutLibOrder 空瓶出库单** `已编码·未确认`
  - Flutter: packages/card_table/lib/src/erp_empty_bottle_views.dart
  - 分组: 
### S8.P5 报表（查询 + 导出）

- [ ] **S8.P5.T01 /ERP/matLibNow 报表** `已编码·未确认`
  - Vue: src/views/ManagementSystem/ERP/rpt_erp/`rpt_erp/matLibNow.vue`
  - Flutter: packages/card_table/lib/src/erp_report_views.dart
  - API: `POST /rpt_erp/get_now_mat_invt` ； `/rpt_erp/exp_now_mat_invt`
  - 完成: 查询+导出列与 Vue 一致；参数接口 POST /rpt_erp/param_items
  - 备注: [2026-09-22 实际入口复审] 实际报表视图导出按钮仅SnackBar提示，没有导出API与文件生成；源rpt_erp对应页面有真实导出。重新列为待接入，保留已实现查询，不得提示导出成功。 详见2026-09-22-reachable-gaps-audit.md。 [2026-09-22 可达缺口修复验证] 查询/筛选/字段/导出已按各原Vue核实接通，复用postBinary+saveWineExport；明细导出带当前分页、PSI导出不带分页。汇总data数组/null与明细datas、其他records分开解析，不使用统一假响应；独立筛选选项保留。页面/角色/权限/身份/离线及凭据等待、发送与保存守卫有回归。全量1614通过；仅fake下载/保存测试，真实Excel仍待验收。 详见2026-09-22-reachable-gaps-audit.md。
  - 分组: 
- [ ] **S8.P5.T02 /ERP/matLib 报表** `已编码·未确认`
  - Vue: src/views/ManagementSystem/ERP/rpt_erp/`matLib.vue`
  - Flutter: packages/card_table/lib/src/erp_report_views.dart
  - API: `/rpt_erp/get_mat_invt` ； `/rpt_erp/exp_mat_invt`
  - 完成: 查询+导出列与 Vue 一致；参数接口 POST /rpt_erp/param_items
  - 备注: [2026-09-22 实际入口复审] 实际报表视图导出按钮仅SnackBar提示，没有导出API与文件生成；源rpt_erp对应页面有真实导出。重新列为待接入，保留已实现查询，不得提示导出成功。 详见2026-09-22-reachable-gaps-audit.md。 [2026-09-22 可达缺口修复验证] 查询/筛选/字段/导出已按各原Vue核实接通，复用postBinary+saveWineExport；明细导出带当前分页、PSI导出不带分页。汇总data数组/null与明细datas、其他records分开解析，不使用统一假响应；独立筛选选项保留。页面/角色/权限/身份/离线及凭据等待、发送与保存守卫有回归。全量1614通过；仅fake下载/保存测试，真实Excel仍待验收。 详见2026-09-22-reachable-gaps-audit.md。
  - 分组: 
- [ ] **S8.P5.T03 /ERP/inLibRep 报表** `已编码·未确认`
  - Vue: src/views/ManagementSystem/ERP/rpt_erp/`inLibRep.vue`
  - Flutter: packages/card_table/lib/src/erp_report_views.dart
  - API: `/rpt_erp/in_recs` ； `/rpt_erp/exp_in_recs`
  - 完成: 查询+导出列与 Vue 一致；参数接口 POST /rpt_erp/param_items
  - 备注: [2026-09-22 实际入口复审] 实际报表视图导出按钮仅SnackBar提示，没有导出API与文件生成；源rpt_erp对应页面有真实导出。重新列为待接入，保留已实现查询，不得提示导出成功。 详见2026-09-22-reachable-gaps-audit.md。 [2026-09-22 可达缺口修复验证] 查询/筛选/字段/导出已按各原Vue核实接通，复用postBinary+saveWineExport；明细导出带当前分页、PSI导出不带分页。汇总data数组/null与明细datas、其他records分开解析，不使用统一假响应；独立筛选选项保留。页面/角色/权限/身份/离线及凭据等待、发送与保存守卫有回归。全量1614通过；仅fake下载/保存测试，真实Excel仍待验收。 详见2026-09-22-reachable-gaps-audit.md。
  - 分组: 
- [ ] **S8.P5.T04 /ERP/outLibRep 报表** `已编码·未确认`
  - Vue: src/views/ManagementSystem/ERP/rpt_erp/`outLibRep.vue`
  - Flutter: packages/card_table/lib/src/erp_report_views.dart
  - API: `/rpt_erp/out_recs` ； `/rpt_erp/exp_out_recs`
  - 完成: 查询+导出列与 Vue 一致；参数接口 POST /rpt_erp/param_items
  - 备注: [2026-09-22 实际入口复审] 实际报表视图导出按钮仅SnackBar提示，没有导出API与文件生成；源rpt_erp对应页面有真实导出。重新列为待接入，保留已实现查询，不得提示导出成功。 详见2026-09-22-reachable-gaps-audit.md。 [2026-09-22 可达缺口修复验证] 查询/筛选/字段/导出已按各原Vue核实接通，复用postBinary+saveWineExport；明细导出带当前分页、PSI导出不带分页。汇总data数组/null与明细datas、其他records分开解析，不使用统一假响应；独立筛选选项保留。页面/角色/权限/身份/离线及凭据等待、发送与保存守卫有回归。全量1614通过；仅fake下载/保存测试，真实Excel仍待验收。 详见2026-09-22-reachable-gaps-audit.md。
  - 分组: 
- [ ] **S8.P5.T05 /ERP/inLibAllRep 报表** `已编码·未确认`
  - Vue: src/views/ManagementSystem/ERP/rpt_erp/`inLibAllRep.vue`
  - Flutter: packages/card_table/lib/src/erp_report_views.dart
  - API: `/rpt_erp/in_sum` ； `/rpt_erp/exp_in_sum`
  - 完成: 查询+导出列与 Vue 一致；参数接口 POST /rpt_erp/param_items
  - 备注: [2026-09-22 实际入口复审] 实际报表视图导出按钮仅SnackBar提示，没有导出API与文件生成；源rpt_erp对应页面有真实导出。重新列为待接入，保留已实现查询，不得提示导出成功。 详见2026-09-22-reachable-gaps-audit.md。 [2026-09-22 可达缺口修复验证] 查询/筛选/字段/导出已按各原Vue核实接通，复用postBinary+saveWineExport；明细导出带当前分页、PSI导出不带分页。汇总data数组/null与明细datas、其他records分开解析，不使用统一假响应；独立筛选选项保留。页面/角色/权限/身份/离线及凭据等待、发送与保存守卫有回归。全量1614通过；仅fake下载/保存测试，真实Excel仍待验收。 详见2026-09-22-reachable-gaps-audit.md。
  - 分组: 
- [ ] **S8.P5.T06 /ERP/outLibAllRep 报表** `已编码·未确认`
  - Vue: src/views/ManagementSystem/ERP/rpt_erp/`outLibAllRep.vue`
  - Flutter: packages/card_table/lib/src/erp_report_views.dart
  - API: `/rpt_erp/out_sum`（以 vue 为准） ； `/rpt_erp/exp_out_sum`
  - 完成: 查询+导出列与 Vue 一致；参数接口 POST /rpt_erp/param_items
  - 备注: [2026-09-22 实际入口复审] 实际报表视图导出按钮仅SnackBar提示，没有导出API与文件生成；源rpt_erp对应页面有真实导出。重新列为待接入，保留已实现查询，不得提示导出成功。 详见2026-09-22-reachable-gaps-audit.md。 [2026-09-22 可达缺口修复验证] 查询/筛选/字段/导出已按各原Vue核实接通，复用postBinary+saveWineExport；明细导出带当前分页、PSI导出不带分页。汇总data数组/null与明细datas、其他records分开解析，不使用统一假响应；独立筛选选项保留。页面/角色/权限/身份/离线及凭据等待、发送与保存守卫有回归。全量1614通过；仅fake下载/保存测试，真实Excel仍待验收。 详见2026-09-22-reachable-gaps-audit.md。
  - 分组: 
- [ ] **S8.P5.T07 /ERP/warehousePSI 报表** `已编码·未确认`
  - Vue: src/views/ManagementSystem/ERP/rpt_erp/`warehousePSI.vue`
  - Flutter: packages/card_table/lib/src/erp_report_views.dart
  - API: 以页面内 POST 为准 ； 以页面为准
  - 完成: 查询+导出列与 Vue 一致；参数接口 POST /rpt_erp/param_items
  - 备注: [2026-09-22 实际入口复审] 实际报表视图导出按钮仅SnackBar提示，没有导出API与文件生成；源rpt_erp对应页面有真实导出。重新列为待接入，保留已实现查询，不得提示导出成功。 详见2026-09-22-reachable-gaps-audit.md。 [2026-09-22 可达缺口修复验证] 查询/筛选/字段/导出已按各原Vue核实接通，复用postBinary+saveWineExport；明细导出带当前分页、PSI导出不带分页。汇总data数组/null与明细datas、其他records分开解析，不使用统一假响应；独立筛选选项保留。页面/角色/权限/身份/离线及凭据等待、发送与保存守卫有回归。全量1614通过；仅fake下载/保存测试，真实Excel仍待验收。 详见2026-09-22-reachable-gaps-audit.md。
  - 分组: 
- [ ] **S8.P5.T08 /ERP/emptyInLib 报表** `已编码·未确认`
  - Vue: src/views/ManagementSystem/ERP/rpt_erp/`emptyInLib.vue`
  - Flutter: packages/card_table/lib/src/erp_report_views.dart
  - API: `src/api/ERP/reportEmpty/` ； 以页面为准
  - 完成: 查询+导出列与 Vue 一致；参数接口 POST /rpt_erp/param_items
  - 备注: [2026-09-22 实际入口复审] 实际报表视图导出按钮仅SnackBar提示，没有导出API与文件生成；源rpt_erp对应页面有真实导出。重新列为待接入，保留已实现查询，不得提示导出成功。 详见2026-09-22-reachable-gaps-audit.md。 [2026-09-22 可达缺口修复验证] 查询/筛选/字段/导出已按各原Vue核实接通，复用postBinary+saveWineExport；明细导出带当前分页、PSI导出不带分页。汇总data数组/null与明细datas、其他records分开解析，不使用统一假响应；独立筛选选项保留。页面/角色/权限/身份/离线及凭据等待、发送与保存守卫有回归。全量1614通过；仅fake下载/保存测试，真实Excel仍待验收。 详见2026-09-22-reachable-gaps-audit.md。
  - 分组: 
- [ ] **S8.P5.T09 /ERP/emptyOutLib 报表** `已编码·未确认`
  - Vue: src/views/ManagementSystem/ERP/rpt_erp/`emptyOutLib.vue`
  - Flutter: packages/card_table/lib/src/erp_report_views.dart
  - API: 同上 ； 以页面为准
  - 完成: 查询+导出列与 Vue 一致；参数接口 POST /rpt_erp/param_items
  - 备注: [2026-09-22 实际入口复审] 实际报表视图导出按钮仅SnackBar提示，没有导出API与文件生成；源rpt_erp对应页面有真实导出。重新列为待接入，保留已实现查询，不得提示导出成功。 详见2026-09-22-reachable-gaps-audit.md。 [2026-09-22 可达缺口修复验证] 查询/筛选/字段/导出已按各原Vue核实接通，复用postBinary+saveWineExport；明细导出带当前分页、PSI导出不带分页。汇总data数组/null与明细datas、其他records分开解析，不使用统一假响应；独立筛选选项保留。页面/角色/权限/身份/离线及凭据等待、发送与保存守卫有回归。全量1614通过；仅fake下载/保存测试，真实Excel仍待验收。 详见2026-09-22-reachable-gaps-audit.md。
  - 分组: 

## S9 超级账号

对照：src/views/ManagementSystem/appinfo  ·  3 项  ·  已确认 0  ·  已编码未确认 0  ·  未开始 3

### S9.P1 超级账号（可选，待确认）

- [ ] **S9.P1 /ManagementSystem/appinfo/smgr 用户管理** `未开始`
  - Vue: `src/views/ManagementSystem/appinfo/smgr/smgr.vue`；API `src/api/UtilAuth/appinfo/`
  - 备注: 平台: 仅 Win/Web；Android 不在范围 [2026-09-20 源码差异审计] 静态审计已见 super_admin API/loader/screen，11个抽取端点可在Vue源中找到；Web/Android已有入口，Windows未接线。保留原状态，不因存在代码自动验收。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 预订金/S9复核] 独立审计发现缺少专用stk会话与权限守卫，普通会话不能代替超管授权；部门仅顶层的UI仍需补。已修API业务code判断、改密MD5字段与岗位ID类型、畸形可写ID拒绝，页面密码不再trim/强加6位限制。保留未开始表示未闭环，不自动确认。原计划S9可选，已询问本次验收范围。 详见2026-09-22-deposit-and-super-admin-audit.md。
  - 分组: 
### S9.P2 超级账号（可选，待确认）

- [ ] **S9.P2 /appinfo 超管登录** `未开始`
  - API: — `src/views/Thelogin/appinfo.vue`
  - 备注: — `src/views/Thelogin/appinfo.vue` [2026-09-20 源码差异审计] 静态审计已见 super_admin API/loader/screen，11个抽取端点可在Vue源中找到；Web/Android已有入口，Windows未接线。保留原状态，不因存在代码自动验收。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 预订金/S9复核] 已有登录页不等于可用：未持久化/隔离stk，成功跳转仍受普通员工路由拦截。已修重复提交、明文输入及时清空、异常恢复、返回动画迟到回调、原密码不trim。独立超管会话/路由仍未完成；原计划可选范围待用户确认。 详见2026-09-22-deposit-and-super-admin-audit.md。
  - 分组: 
### S9.P3 超级账号（可选，待确认）

- [ ] **S9.P3 /register 注册** `未开始`
  - 备注: — 仅当现网门店仍使用；执行前先确认是否还在用，停用则标不移植 [2026-09-20 源码差异审计] 静态审计已见 super_admin API/loader/screen，11个抽取端点可在Vue源中找到；Web/Android已有入口，Windows未接线。保留原状态，不因存在代码自动验收。 详见 docs/flutter-migration/2026-09-20-parity-audit.md。 [2026-09-22 预订金/S9复核] 实际为设备注册/register/machine。移除共享假机器码flutter-terminal-pos，未获取真实机器码不发送；修复业务失败误成功、auth_mode解析、旧机器回包。原生机器码与保存auth_mode/重新授权仍未闭环，原计划使用范围待确认。 详见2026-09-22-deposit-and-super-admin-audit.md。
  - 分组:
