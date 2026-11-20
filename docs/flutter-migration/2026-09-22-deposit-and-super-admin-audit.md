# 预订金报表及超级账号审计（2026-09-22）

基线：原Web主仓4b5379e8；Flutter保持feature-flutter-foundation当前工作树及用户/其他agent改动。复用现有报告组件与导出服务，不改变后端。

## 三张收银报表

- R33：drawerSetGZHK.vue，get/exp_cnl_account_rtn_list，无body；m分转元。
- R34：drawerSetYDJHistory.vue，now减8小时的日期、10条分页。查询不擅自归第一页；重置恢复日期/页码、保留关键词。a/bb/ab分转元。源binaryFilePost确用get_cust_prepay_log，未猜exp路径。
- R35：drawerSetYDJYE.vue，get/exp_cust_prepay_bal；真实cust_id进入get/exp_one_cust_prepay_log明细。返回保留列表页码和关键词；旧详情响应不能覆盖列表。ub/la/ca/ba分转元，详情不带虚假分页。

三页原版没有打印。已观察3项unavailable红测，再新增9项与既有报告共48项通过；独立合同审查通过。真实数据及Excel待登录后验收。

## S9尚未闭环

原任务拆分文档第888–894行将S9列为可选、非门店日常，Android不在范围；已询问是否纳入本次验收，未自行扩大或取消范围。看板误继承前一节的“不移植”页面标题改为“超级账号（可选，待确认）”，状态保留未开始。

已有API和页面，但没有独立stk会话保存/隔离，登录后仍受普通machine/user路由拦截；loader没有独立超管权限守卫。不能以存在文件或测试绿推断S9可用。

本轮闭环的合同及入口缺陷：

- 所有S9 API检查业务code，HTTP成功的code2不再假成功；有限整数形式1.0及字符串1兼容。
- 改密字段为old_password/new_password，API边界单次大写MD5；页面不trim密码，不额外强加原页面没有的6位长度规则。
- station_id非空选中值发整数，无效操作ID/畸形列表拒绝，不再默认生成可操作id0。
- 超管登录只接受真实token字符串；重复提交、提交后输入清空、异常恢复、返回动画迟到回调有回归。
- S9.P3实际是设备注册/register/machine。移除共享假机器码；无真实机器码时零发送。auth_mode严格解析，旧机器请求返回不驱动新绑定页面。

仍缺：独立超管凭据与会话生命周期、路由、子部门选择；真实机器码获取、auth_mode保存和重新授权。原生设备注册是否仍使用及S9范围待确认，不能把“禁止假机码”视为已实现真正注册。

## 验证

S9先观察17项API合同、4项入口红测，后补原密码页面传递、旧长度限制、code1.0与注册重绑定回归。最终全工作区1415项通过（/tmp/shouyin-deposit-s9-full.log）。全部写路径使用测试替身，未修改真实密码、员工权限或注册终端。真实验收不由合成测试替代。

最后清理仅本轮新增lint后S9定向33项再次通过；静态分析无error/warning，149条info（/tmp/shouyin-deposit-s9-final-analyze.log）。边界检查0违规，看板安全回归3项通过。Android debug APK构建成功（/tmp/shouyin-deposit-s9-build.log），Web热重启成功。看板304项：未开始4、待接入13、已编码未确认284、已确认2、不移植1。
