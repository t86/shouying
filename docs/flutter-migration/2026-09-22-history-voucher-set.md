# 历史点单、套餐统计与卡券记录（2026-09-22）

原Web基线4b5379e8；保留当前Flutter工作树全部其他改动，不改变后端。

## R19 历史点单

先无body get_csm_his_wkday_items，records取首个营业日；查询/导出为get_csm_his、exp_csm_his，传wkday_id/key。支持切换营业日、查询、重置、父流水与os明细展开；父o/p和子oa/pa按分转换。源没有独立卡台/类型筛选与打印，未擅加。

## R32 套餐统计

get_set_cnt_items初始化two_cates/ss，不自动统计；全选all=1且IDs空，部分选择all=2，父类别已选时排除其子套餐重复ID，状态0/1/5。查询get_set_cnt_rpt与打印prt_set_cnt_rpt同一组筛选；prd_sets父行、ss子行按源展示，不重复合计。源没有导出。

打印新增typed query回调，联通Web及Android/Windows共享壳；SessionBoundCashierReportPrinter在凭据等待后、协议发送边界联合当前账号/终端/在线/连接代际和页面守卫。真实延迟凭据、同账号重登、断线/epoch及页面失效零发送已测。

## R12 当日卡券核销记录

修正任务板旧接口名：实际drawerMtDyHx使用get_kq_csm_list_for_back与exp_kq_csm_list_for_back，参数type_id(0/12/22/32)/key；退券cancel_kq_csm传kq_order_id。21列齐全，a/a2分转元，t映射券类型。退券资格仅数值b=1（不把字符串1当真）。

确认后重新查询，核验同ID/完整行指纹/资格，再提交；日切产生访问失效脉冲，未擅加营业日必须>0门槛。请求前预留待确认标记，明确成功/业务拒绝且仍属当前页面才清除；失效或未知回包保留锁。断线恢复自动读取不会清锁，须显式成功查询核实后才能重试。

## 复核发现并修复的异步边界

- pending退券→断线恢复→自动查询仍b1→旧请求返回context_changed，原代码提前return导致未锁券；已用运行红测复现，改为请求前预留锁。
- 导出保存前的检查不足以覆盖等待目录期间换账号。共享saveWineExport新增canSave，券/收银报告/存酒加载器传递实时守卫；原生在目录定位/创建/临时目录准备后、实际写入前后复查，失效尽力清理仅本次新文件；Web在触发下载前检查。已发出的浏览器下载不能撤回，文件系统拒绝删除时不能保证清理成功，不作绝对撤销承诺。

## 验证

历史/套餐初始两页运行红后转绿，相关71项报告测试通过。券初始缺文件为编译红（不伪称运行红），随后12项合同/页面/时序回归通过。父printer/Card接线有独立运行红；三端接线和生命周期定向64项通过。下载目录延迟测试运行红后转绿；额外真实IOOverrides延迟临时目录和写入边界，失效清理后无本次文件，保存器5项通过。

最终全工作区1483项通过（/tmp/shouyin-history-voucher-full.log），静态分析无error/warning、149条info（/tmp/shouyin-history-voucher-analyze.log）。全部打印、退券与文件测试使用替身/临时目录，未进行真实打印、退款、库存写入或业务数据导出。真实门店数据/实际Excel、Windows原生与硬件仍待验收，不自动标为已确认。

边界检查0违规、看板安全回归3项通过，Android debug APK构建成功（/tmp/shouyin-history-voucher-build.log），Web热重启完成。看板304项：未开始4、入口待接入3、已编码未确认294、已确认2、不移植1。
