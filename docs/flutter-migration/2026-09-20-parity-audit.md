# 2026-09-20 Flutter / Vue 等价性审计与修复记录

## 结论与验收边界

后续进展见 [第二轮实现与验证](2026-09-20-parity-round2.md)：下文保留首轮发现时的快照，BMS T01/T10/T11/T12、Wine导出、九系统入口已有后续修复；不是仍全部未修。任务实时状态以看板为准，总目标仍未完成。

当前不是完整移植：页面、入口、接口类存在，不能等同于业务已接通或三端验收。已确认的两项 S2.P1.T08、S2.P1.T09 保留，不批量标记完成。

本轮是抽样和高风险审计，不是292项任务逐项全量验收。两份看板各追加74项审计备注、将50项明确未接通任务降级；最终共52项待接入、233项已编码未确认、4项未开始、2项已确认、1项不移植。未被本轮修改状态的任务，不代表已获新的验收证据。

本次对比源码主仓 HEAD `d8a12c97` 与实际 Flutter 工作树 HEAD `1ca34798` 加未提交改动。Vue 源位于 `/Volumes/WORK/xuzheng/shouyin/src`；实际 Flutter 位于 `/Users/tl/.config/superpowers/worktrees/shouyin/feature-flutter-foundation/flutter_workspace`。以下 Flutter 相对路径均从 flutter_workspace 起，Vue 路径从主仓起。

本次静态审计未调用真实后端，未办理收款、库存、权限或密码写操作。端点存在仅是源证据，不代表请求体、响应字段、分页、权限或生产行为都正确。

## 本轮实际修复

| 范围 / 任务 | 已完成 | 仍未完成 |
| --- | --- | --- |
| 收银 S3.P2.T02/T04/T09 | 应收按选中商品计算；金额不超过剩余应收；写入失败可见；成功刷新清单；未足额或清单失效禁结账；换台与迟到响应保护；转单字段 wk_order_ids/prd_cnts/total_amt（分）及套餐字段 order_dtl_id/dest_dtl_prd_ids/dest_dtl_prd_sel_cnts/dest_requirements 对齐 | 动态支付渠道、专用支付、套餐要求编辑；部分模型 isLocked/discountType 仍占位 |
| 专用支付 S3.P2.T05–T08 | 未接通的会员/挂账/预付/滞留/抹零禁用；通用 API 禁止 5/6/10/202/500/9999 冒充专用流程 | 必须分别接入专用读取、授权、余额、确认与失败处理 |
| 收银报表 S3.P1.R01–R37 | 仅班结表、售出日报表、鸡尾酒明细表、鸡尾酒汇总表、低消进度统计表有默认条件读取；其余32项返回 report.unavailable，零猜测接口请求；读取失败/重试、权限撤销清空及迟到响应保护 | 5项也不是完整报表：班结与售出日报仅当前营业日全部默认条件；自定义筛选、打印、导出未完成；Windows未接线 |
| ERP S8.P2.T02、S8.P3.T01 | 从 erp_in_views.dart:39、erp_out_views.dart:39 移除示例 m_1、固定数量/价格的真实提交，改为明确尚未接入提示；保留已有单据浏览 | 真实物料检索选择、数量/价格、验证和新建提交 |
| BMS 改密 M0.P1.T04 | bms_nav_screen.dart:188 移除无API请求却显示密码修改成功的路径，不再收集无用密码 | BmsLoader没有改密契约，当前明确提示尚未接入，需走原系统 |

主要支付代码在 `packages/card_table/lib/src/pay_money_drawer.dart`、`pay_order_api.dart`、`pay_order_loader.dart`、`pay_order_screen.dart`；报表在 `cashier_reports.dart`、`cashier_reports_screens.dart`。精确变更以本轮工作树 diff 为准。

## 独立复核追加修复（S3.P2.T02/T04/T09）

首次修复后独立复核仍发现三个P1，已补修并再次只读复核闭合：底部结账曾绕过抽屉足额校验；010/0500/06等渠道号曾绕过字符串禁用；加渠道/转单弹窗曾在切台后混用旧表单和新卡台。现在所有结账入口统一抽屉，最终提交重新读取服务端收款清单并以分核对合法金额与足额，保留原Web合法零元结算；渠道ID严格解析为正整数后按数值过滤；全部8个异步写表单核对卡台及翻台轮次。23项支付定向测试通过。未进行真实收款，不能等同完整支付验收。

## P1 契约差异：不能直接当作已完成

1. **S7.P1.T01 工号规则字段错误**：`bms_staff_views.dart:64` 和 `bms_models.dart:27` 使用 prefix/start_no/step/bit_len；Vue `src/views/ManagementSystem/BMS/genRule/genRule.vue:78` 使用 passwd_use_code/fixed_passwd/code_length。需重新对齐读写模型，不是只补一个字段。
2. **S7.P1.T10 批量重置密码**：`bms_api.dart:95` 发 ids；Vue `src/views/ManagementSystem/BMS/emp/emp.vue:176` 发 emp_ids。建议小改 payload 并增加真实请求体断言。
3. **S7.P1.T11/T12 入职审批与商务订位人**：`bms_api.dart:104/113/126/135` 中 onboarding_list/audit_onboarding/business_list/set_business 未见 Vue 源契约。Vue `src/api/BMS/emp/index.js:150–162` 使用 get_emp_rz_list、emp_rz_approve_batch_yes/deny；`src/api/BMS/emp/businessEmp.js:7–17` 使用 get_bs_sales_list/batch_add_bs_sales/remove_bs_sales。单条布尔切换不能替代原批量业务。
4. **S5.P5.T01、S5.P6.T01、S5.P11.T03 存酒导出**：`wine_api.dart:274–325` 使用4个无源依据的 /wine/export_* 路径，返回 void，界面仅提示指令下发。Vue `src/api/wine/index.js:47/69/88/413` 使用 binaryFilePost，对应 /wine/rpt/exp_wine_invt、/wine/rpt/exp_wine_invt_expired、/wine/exp_wine_invt_grid、/wine/rpt/exp_unreturned_wine_list。必须走正确端点并生成可下载文件。
5. **S7.P7.T04/T05 短信**：`bms_api.dart:715/724` 的 /sms/account、/sms/records 与 Vue `src/api/BMS/messageConfig/index.js:6–18` 的 /sms_mgr/get_acct_info、get_sms_records/get_sms_record_dtls 不符。

## P2 功能与保护缺口

| 任务 | 当前证据 | 修复方向 |
| --- | --- | --- |
| S7.P0.T01 | BMS groups固定全量展示；BmsNavScreen无权限入参；Vue ManagementSystem.vue:386按client/safeMode/roleIds/sys_modules筛选 | 接入同一权限快照并测撤权；只能证明UI不等价，不能据此断言后端越权 |
| S7.P2.T05 | bms_product_views.dart:323点击上传只提示已打开图片选择器 | 接入文件选择、上传、失败和刷新；现为入口 |
| S7.P6.T01–T05 | bms_rules_reports_views.dart:9–100五页只有静态文字，没有读取/保存 | 分页补契约和交互，不能继续以已就绪文案冒充实现 |
| S7.P7.T06 | bms_wine_sms_views.dart:461短信结果为静态已就绪 | 对齐 /sms_mgr/get_mobile_send_rst |
| S7.P2.T06 | /prd/taocan_templates未见Vue源支持，页面仅列模板 | 对照原模板端点及编辑流程后实现 |
| S8.P3.T02 | erp_out_views.dart的调拨新建只收两个仓库ID和备注，无物料明细/验证/失败显示 | 在明细录入和契约完整前不得称调拨闭环 |
| 跨域会话保护 | VIP vip_pages_loader.dart:717有登录/在线/generation/身份变化检查；BMS直接透传且无machine时默认orgManager；ERP和超管保存session但未做同类保护；Wine wine_loader.dart:138只查user/machine存在 | 分域补会话失效、离线、换身份后的结果隔离；持有session对象不是保护已完成 |
| 收银回退入口 | card_table_screen.dart中_pendingFeature共15处匹配（含定义），覆盖改密/授权密码/会员/消费与收款/点单/充值/更多菜单/卡台动作 | 多数是callback缺失回退，不能简单算成14个缺失功能；需逐入口联测。定义明确不会提交业务数据 |

相关新域文件未发现显式 TODO 不代表没有缺口；缺口主要藏在静态文本、固定值、宽松默认模型和仅提示成功的回调里。

## 各域覆盖判断

- BMS：API/loader/导航存在，但只证明页面骨架与部分CRUD。抽取65个两段式端点字面量，7个未在Vue全源找到；至少7个页面为静态/假回调（五个报表配置、图片上传、短信结果）。
- ERP：抽取67个两段式端点均在Vue全源出现；不证明payload、字段、分页正确。两个示例物料写路径已安全禁用；调拨、物料选择和失败反馈仍不足。
- Wine：大部分页面有session loader及API；抽取50个两段式端点，4个导出路径不符，文件交付未实现。
- VIP：大量真实回调和较完整session保护已存在，但本轮未逐一验证约70个动作请求体，且系统选择缺会员独立入口；不能给完整等价结论。
- Superadmin：API/loader/screen已存在，11个抽取端点在Vue源出现；看板S9.P1/P2/P3原为未开始，保留并补注，不能把代码存在自动升级为已确认。
- Web/Android：主程序已有BMS/ERP/Wine/SuperAdmin入口代码。Windows主程序未接这些导航与报表读取；三端共用组件不是三端接线证明。

端点统计仅覆盖上述API文件中匹配到的两段式字面量，不是全系统接口覆盖率；不统计动态拼接、多层路径等，不得转换成完成百分比。

## 实页与启动证据（2026-09-20）

主代理实页核对：原Web系统选择9项——门店后台、预定、点单、收银、会员、物料ERP仓库管理员、物料ERP管理员、存酒-仓库、叫号大屏；已选点单到版本1.0.202609181250登录页，等待用户登录。

Flutter 8183选择页8项——预定、点单、收银、存酒、排队、门店后台、ERP仓库、超管中心。缺会员独立入口，ERP两个角色合并；即使VIP代码存在也未证明入口闭环。相关看板 M0.P1.T02、S3.P1.T04、S4.P1.T01。

Web服务已启动；Android模拟器已启动。新版构建先被旧全局7890代理拒绝，改用临时Gradle home后Gradle已下载成功，但plugins.gradle.org/repo.maven.apache.org多个Kotlin2.2.21依赖下载被TLS handshake终止，APK仍未构建完成。模拟器启动不等于新版运行。启动、能看到页面、业务接通、真实写入验收是不同证据层级。

最终启动补充：Web已用本轮最新代码重启并编译成功，入口8183、Flutter调试服务8184。Android重试已结束（exit1，TLS依赖下载），当前网络下不再继续重试；未交付新版APK运行结果。

## 验证与追踪

最终合并验证（包含独立复核补修）：8个测试文件（支付3、报表2、域安全1、Web/Android生命周期各1）共68/68通过；固定Flutter3.47.0，DEVELOPER_DIR=/Library/Developer/CommandLineTools。域安全3项另行复跑全部通过。开发代理、依赖边界检查器、看板往返共27项Node测试通过，实际工作区扫描0个边界违规。完整dart analyze汇总INFO140，无error/warning；flutter analyze严格模式exit1，不能称全绿。最终补修后Web再次热重启编译成功。

Web与Android报表回调已接入同一sync协议客户端，校验online/session identity/generation并隔离迟到响应；两端转单回调也已接线。证据 apps/web_app/lib/main.dart:890/2171、apps/android_app/lib/main.dart:855/2136，card_table_screen.dart:447/742；Android生命周期包含报表菜单读取、断连禁读及重连恢复测试。Windows仍未接线。

首次测试曾受Xcode license及旧shader测试缓存阻断。旧build/unit_test_assets/shaders已由支付工作包移至/tmp/shouyin-test-assets.FdPlqo并重新生成；域安全测试另用NoSplash测试主题避免依赖着色器资产，不更改生产主题。不得把这些启动/资产故障误报为业务逻辑失败。

看板对已经证明只有入口/占位的任务降为“入口已列·待接入”，保留两条“已确认”。其余“已编码·未确认”不代表可上线。每条任务追加本次可读审计备注，原备注/来源/分组不覆盖。

两份docs/flutter-migration在修改前分别备份至：
- /tmp/shouyin-sep20-board-backup.NlWYpn/main
- /tmp/shouyin-sep20-board-backup.NlWYpn/worktree

JSON作为真值，按board/README.md与sync-board.js说明使用 --from-json 生成BOARD.md和内嵌数据index.html；两仓分别生成，不用一侧覆盖另一侧。不运行会改线上文件的flutterMigrationBoard测试。
