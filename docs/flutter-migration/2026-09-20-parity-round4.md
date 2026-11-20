# 2026-09-20 第四轮：真实ERP、收银报表与Android启动

总目标仍未完成。主仓最新HEAD为2fd74959，Flutter工作树仍为feature/flutter-foundation的未提交实现；未改动原Web业务代码或真实后台数据。

## 本轮实现

- S8.P2.T02：真实新建入库，仓库/供应商/物料辅助数据、数量金额、发票类型、专票src_amts与除1.13净额、平行数组、失败保留及成功刷新。
- S8.P3.T04：真实新建出库，所选仓库库存和物料、单位/数量/价格、数量上限、切仓确认清空、失败保留及成功刷新。
- S8.P3.T01原整页任务改为“其他出库列表/筛选/单据操作”，仍待接入；没有把新建完成等同列表日期/类型/分页、类似创建、红冲或反审核都完成。
- ERP全部loader经user/machine/erp类型/online/generation守卫，并按当前erp或erpAdmin发送客户端头；两端主程序已注入。
- 新增5个真实报表：支付记录、线上支付汇总、区域实时营收、业绩日报表、优惠明细表。含原筛选、分页、金额单位、优惠嵌套明细、导出和线上汇总打印；报表支持数5→10，其余27仍不可用。
- 支付记录会员查询/换绑/解绑保持原营业日id>0、pi含自助禁止写、c空或-禁解绑；未注册手机号按原规则仍可绑定。六个类型化回调贯通CardTableScreen和Web/Android入口，读取/导出/写操作隔离旧会话和迟到结果。
- 区域取原始全部有效区域按dsp，不使用卡台可见区域；员工不错误过滤status，保留namePy/code搜索。

## 交叉复核与修复

- 付款编辑撤权精准移除原DialogRoute，不能按栈顶pop掉后来打开的登录页。
- 区域选项纳入有效但无当前可见卡台的区域。
- “解绑成功未刷新”的初始复核判断已撤回：原按钮wrapper本已刷新。代码仅整理成成功后内部刷新，取消不额外查询，不能将此误报为旧缺陷。
- ProtocolClient二进制导出只解码含%的header名称，中文fallback及原生中文header不误交Uri解码，非法编码安全回退；鉴权、大小和路径清洗保留。

## 验证

- 固定Flutter3.47.0 / --no-pub / CommandLineTools。
- 全工作区831/831测试通过；全局分析0 error、0 warning、135 info（非全绿静态验收）。
- Node代理/看板8项通过，依赖边界0违规，git diff --check通过。
- 独立复核ERP未发现本轮必须修P1/P2；报表两项确证问题已补测修复。
- 未执行真实库存、会员换绑、打印或付款操作。

日志：/tmp/shouyin-round4-verify.4xqgBC/。

## Android真实构建与启动

此前构建问题已越过：Java直接访问Maven/Gradle插件仓库返回200，隔离Gradle home、Java17.0.16、单次daemon和单worker配置可重复构建成功。没有取消TLS验证或改全局代理，未声称唯一定位了旧TLS失败的单一成因。

第一次Gradle配置检查13m50s成功，首次APK365s；最终本机地址调试APK再次构建26.9s成功。APK为arm64 debug、minSdk24/targetSdk36，安装到emulator-5554成功，MainActivity启动Status ok且持续resumed/focused、进程存在。

最终调试参数使用127.0.0.1:8183及ADB reverse映射，符合既有开发地址白名单；没有把10.0.2.2冒充被允许的loopback地址。由模拟器通过映射请求/__health实测200与status:ok。此包依赖开发电脑服务及映射，不是发布版或离线包。

APK：flutter_workspace/apps/android_app/build/app/outputs/flutter-apk/app-debug.apk。临时Gradle home为/tmp/shouyin-gradle-sep20.9wKXbw，缓存保留；无用旧Gradle daemon已停止。测试用IPv6桥已撤除，最终不依赖它。

桌面控制工具未识别qemu模拟器窗口，因此本轮端侧证明是实际安装、Activity/进程和网络记录，不是全部屏幕视觉/登录验收。最终PID4886的flutter/AndroidRuntime错误级日志未见错误；此结论仅限本次启动窗口，不代表所有业务无错。

## 真实原Web会话与新遗漏

先前“未登录”仅是新建的in-app浏览器标签页。现找到Chrome中已登录的原版后台，已只读确认价格方案页面，未改变当前配置和选中方案。

发现完整价格方案/金额链遗漏，已新增6个任务，详见[价格链路差异](2026-09-20-fc-price-gap.md)。这些P1/P2仍未实现，不能把当前构建和831项测试作为正式收银上线通过的依据。

看板当前299项（新增价格6项、拆出出库新建1项）：10未开始、39待接入、247已编码未确认、2已确认、1不移植。用户的两项已确认保留，未自动代验收。仍须继续全部原Web功能、权限、Windows及真实端侧对照。
