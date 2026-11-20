# 收银首页报表与估清对照（2026-09-22）

原Web真值：主仓4b5379e8，moneyCard实际导入的组件，不按看板早期描述猜接口。Flutter沿用feature-flutter-foundation工作树，保留其他agent与用户修改。

## 本轮范围

- S3.P1.R17：翻台记录。drawerTurnOver.vue，查询get_turnover_csm_list、导出exp_turnover_cms_list，无body，全部9列。
- S3.P1.R18：点单记录。drawerOrder.vue，get/exp_order_prd_list，21列、关键词及4筛选。商品/营业类型取服务端，不写死。原重置form={}产生is_cust:null，其余undefined字段省略；导出同语义。
- S3.P1.R20：非鸡尾酒补交。drawerNotTYOrXF.vue，get/exp_relate_prd_list，orders与pays双表独立。渠道汇总不能因明细为空而消失。
- S3.P1.R21：修改订位人记录。drawerUpdateBookEmp.vue，get/exp_csm_sales_chg_list，10列；原日期筛选为注释，无活动分页。
- S3.P1.R22：收银估清，复用与原Web相同的共享估清业务；收银无module5要求，点单有。list无body、set为prd_id/cnt、delete为prd_id，收银tt8/点单tt4，未增加部门筛选。

## 实际缺口及修复

收银原先被导向未接入通用报告，loader仅允许读取、set/delete硬编码order。现在按会话捕获client，传递页面/会话/连接代际检查到协议发送边界。权限脉冲后旧数量弹窗不能恢复有效；返回动画开始即关闭操作scope。

目录原先全平台硬编码PAD。LegacyCardTableStore现注入设备类型，两条目录路径均使用；Card根据运行平台传入。与源一致：分类及空搜索按limit_pc/limit_pad字符串1过滤；非空全局搜索仍取原allProductsList，未擅自改变原搜索行为。

复核中实际确认连接流onDone、数据流错误/结束未关闭估清访问，已统一置blocked。连接流onError原来已通过_reportCanRead监听间接关闭估清，不把它误记为新增修复。

## 验证证据与边界

四报表先观察4项unavailable红测，再完成11新测试与既有回归共39项绿；独立源合同审查未发现阻断。估清接线、cashier维护以及旧数量确认复活三项红测均已观察，随后定向29项通过；追加平台、权限、返回动画、流错误/结束与真实延迟凭据、同账号重登零发送测试24项通过。

首轮全工作区1378通过、1项原凭据跨isolate OS锁测试30秒超时。独立检查确定性复现了可导致同类等待超时的既有竞态：独占创建遇EEXIST之后持有者恰好删除锁，原exists复查误判失败。现在只对平台对应的文件已存在错误重试，EACCES等仍拒绝操作；测试worker回传错误，避免无声等待。不能断言历史那一次超时已被证明唯一由此引起。原3项及新增竞态/权限错误/worker回传3项，与session测试共50项通过。

最终全工作区1382项通过（/tmp/shouyin-cashier-final-tests.log），静态分析无error/warning、149条info（/tmp/shouyin-cashier-final-analyze.log）；边界检查0违规，看板安全回归3项通过。看板现未开始4、待接入16、已编码未确认281、已确认2、不移植1。

全部写路径使用测试替身；没有真实设置估清、解除估清、付款或库存操作。旧Web浏览器已进入收银登录页，但没有可用员工会话，已请用户手工登录，不读取或猜测密码。真实报表返回及导出文件待验收；Windows仅共享接线/模拟平台测试，不是Windows原生运行验收。

Android debug APK构建成功（/tmp/shouyin-cashier-final-build.log），已安装并启动模拟器；本地Web重新编译，已通过UI看到选择收银后进入收银登录页。只验证启动，不冒充真实业务验收。

待确认：旧Web允许负数估清数量（没有明确拒绝），Flutter现有非负校验暂保留。已询问实际业务含义，未把差异隐藏为“完全一致”。任务状态为已编码未确认，用户已确认项保留。
