# 挂账、商户与出库打印增量整合

## 核实起点

原 Web 基线 4b5379e8；Flutter 工作树基线 1ca34798，包含多人未提交工作。本轮保留既有改动，不以整个工作树 diff 归因单个 agent。

独立核实发现：R16 挂账账户、R24 商户管理已有页面与协议实现，但尚未从收银入口调用；S8.P3.T05 已有 PDF 及详情打印逻辑，但 Web 和原生壳未传打印回调。组件完成不等于用户可用。

包目录下独立复跑 56 项功能测试及 3 项 PDF 桥测试通过；相关生产代码定向静态检查无问题。首次从 workspace 根直接执行包内测试时，PDF 资源路径不成立；改用实际 package 运行上下文后通过，未用删除断言规避。真实账号、打印设备未验收。

## 兼容性与安全边界

- 商户阈值：原 drawerMerchant.vue 使用 parseInt，未禁止负数。新增实现不能因负阈值让旧配置整页加载失败；修复目标是仅额度字段支持有界有符号整数，ID、小时及枚举仍按各自范围校验。
- 挂账还款：保留六渠道及原金额单位、分配顺序；确认前后、凭据等待后的身份/在线/页面检查不能被入口接线绕过。未知结果锁须由持久 loader 保留，重开页面不能解除。
- ERP：仅详情 view 且 status 精确为“已完成”允许打印。重新读取详情后生成 PDF，包含单据头、明细、红冲和签名栏；金额单位元，合计为明细 sa 合计，不减红冲、不以头部金额替代。
- 系统打印返回成功仅表示交给平台，不证明纸张输出。已派发后页面变化或异常可能无法判断结果，不能当成尚未派发而开放盲目重试；明确取消可以重试。
- 本轮不真实建账、还款、变更商户配置、出库或打印。

## 整合进度

三端 PDF 适配器复用现有系统打印服务，独立注入替身的 3 项回归通过。Web、Android/Windows 共享壳均接入持久挂账/商户 loader；收银更多菜单进入专用页面，不再走通用未实现报表。两个 loader 懒加载并跨页面复用，关页重开不能绕过进行中/未知结果保护。

商户底部金额按 dataset38 的单/双主体解析，展示 amt/10000，向信息页传原始 amt/g_amt；全量、增量、失效、重连、换身份和换事件流均有清除规则。普通金额刷新不撤销正在编辑的配置。金额 store 发出变更通知以立即清除断线旧数，底部按钮窄高度溢出已由红测复现并修正。

ERP 双壳已把详情打印回调接到现有 printerServiceProvider，使用 PdfDocumentPrinter，缺少能力时明确报错，不伪装成功。应用级测试通过替换原 provider 的打印底层验证实际回调调用及失效零派发。打印异常或派发后失去上下文统一保留结果未知保护，明确取消仍可重试。

R24 补齐 loader 级锁：普通初始化不解锁，显式 verify 根据最后写操作分别重读 config(entity)、switchState 或 groups；读取失败、页面/身份/连接失效都不能清锁。断线后正文隐藏旧配置、金额及小时记录，待明确重读成功才恢复。

定向回归：R24 27 项；Card 接线 4 项、Android 23 项、Web 24 项、Windows 壳 12 项。后者是 widget/协议验证，不代表 Windows 原生编译或现场打印通过。全量回归和构建结果见下节；本记录不代表现场验收。

旧 Web 的 merchantOnlineCollect、cashierCardAmount、cashierTabAmounts 共 28 项基线回归通过；仅用于确认原规则，不能替代 Flutter 端验收。

## 测试运行环境

新增 PDF 包资源暴露了 workspace 根执行所有测试时的资产上下文问题。check.sh、check.ps1 和 GitLab flutter-test 改为在各含 test 目录的成员中串行执行 flutter test --no-pub；没有 test 目录的共享原生壳通过 Android/Windows 应用测试覆盖。包测试失败立即中止，不继续构建。对应 Node fixture 先红后绿；本机未安装 PowerShell，不能把静态/fixture 覆盖说成 Windows 原生运行通过。

Node CI gate：19 项通过、4 项环境跳过。模块边界 0 违规，看板安全回归 3 项通过。

## 最终自动化检查

主代理独立逐包复跑 14 个成员，共 1554 项通过，无失败（/tmp/shouyin-management-integration-full.log）。完整静态检查无 error/warning，161 条 info（/tmp/shouyin-management-integration-analyze.log）。三项任务更新为“已编码·未确认”，两份看板同步保留用户确认状态：304 项中未开始 4、待接入 0、已编码未确认 297、已确认 2、不移植 1。

员工卡原生读卡、可选超管范围、真实账号全流程、Windows 原生与实际硬件仍未验收。看板编码状态不能作为整体移植完成证据。

Android debug APK 构建成功（/tmp/shouyin-management-integration-build.log），已安装启动 emulator-5554，确认应用进程存在，APK 包含中文字体及 OFL 许可。构建仍有既有 Kotlin 插件迁移提示，不作已消除声明。Web 热重启完成，字体资源 HTTP 200、10596232 bytes；运行态业务页面仍需登录后验收。
