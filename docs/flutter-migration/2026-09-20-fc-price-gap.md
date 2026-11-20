# 2026-09-20 价格方案与金额链路缺口

## 证据与优先级

Chrome已有登录的原版后台 /shouyin/BMS/fcPriceConfig，实际页面包含“商品列表”“价格方案管理”，商品管理菜单中有“小费特饮价格方案配置”。仅只读观察，未编辑方案、价格或员工。

主仓当前HEAD为2fd74959，较最初d8a12c97增加方案员工展示/立即移除，以及未结汇总减已结金额。以下对照以当前源码为准；这些更新未修改本轮ERP或5个报表源接口。

当前Flutter缺少完整价格方案链路，因此不能把现有收款测试通过等同于金额逻辑全部一致。当前选中整行累计历史pa这一点是正确的，不能误报为所有金额都错。

## 原接口（均POST /prd/）

| 接口 | 参数/响应要点 |
| --- | --- |
| get_fc_prd_cfg_list | key；plans/prds/prices；商品id/n/on/tn/p，方案id/n，价格id/p/a（分） |
| get_fc_prd_cfg_items | one_cate_id/two_cate_id/key；records/cates；c=1已配置 |
| batch_add_fc_prd / batch_del_fc_prd | ids |
| get_fc_price_plan_list | 空对象；records含id/n/e/c/u |
| get_fc_plan_emp_items | plan_id/dept_id/key；records含id/n/d/c/s/p/r；s=1当前方案、s=2其它方案 |
| remove_emp_from_plan | plan_id/emp_id；立即生效，取消编辑不会回滚 |
| new_fc_price_plan / save_fc_price_plan | name/emp_ids；保存另含id |
| batch_del_fc_price_plan | ids |
| save_fc_prd_plan_price | prd_id/plan_id/pay_amt整数分 |

依据src/api/BMS/fcPrice.js与对应fcPriceConfig/model.js、页面调用者。金额非负且最多两位小数；显式0有效，缺少价格才回退。

## 必须还原的业务规则

- 同步58=[prd_id,plan_id,pay_amt,status]，59=[plan_id,emp_id,status]，仅status=1有效，按复合键更新并隔离会话。
- 新点单授权人优先，否则点单人；授权人无方案时不再回退点单人的方案。分转元，0价不是缺失。
- add_prd用方案prd_price；add_hl不发送prd_price，类型3/4/8可发方案单价×数量的prd_amt；普通定价留空交后端。
- 历史订单保留pp/p2/pa/pc/at：整行用pa，拆分才用p2回退pp；pp=0仍是时价不能拆分；at=2/3小计0；不能按现行方案改写已下单/退款金额。
- /wo/list pay_info为整数分：折前=discount_amt+order_amt；赠送=yh_amt；优惠=discount_amt+payed_free_amt；未结=order_amt-payed_amt。

依据src/utils/fcPrice.js、components/order/fcPriceMixin.js、utils/orderItemPrice.js、utils/orderSummary.js和transformCardData.js/websocket.js。

## 当前缺口与任务

已新增而非删除范围：
- M0.P5.T01 历史成交价与赠送快照（P1）
- M0.P5.T02 58/59同步与失效（P1）
- M0.P5.T03 新点单选价与请求（P1）
- M0.P5.T04 pay_info四项汇总（P1）
- S7.P2.T07 价格矩阵配置（P2）
- S7.P2.T08 方案与员工归属（P2）

初次检查时Flutter无对应API/菜单/58/59处理，pay_order_api及order_meal模型缺p2，discountType曾恒0，新点单直接product.price。下列进展不等于全链路已验收，不可用于正式收银验收结论。

### 实施进展

- M0.P5.T02已编码未确认：FcPriceCatalog及卡台存储支持58/59复合键全量/增量、有效状态、零价、未知与空方案区分、旧快照回放及坏包失效。父代理重跑8项专项测试通过。
- M0.P5.T04已编码未确认：新增SessionBoundOrderMealLoader.listOrdersWithSummary，沿用在线、会话身份和连接代次守卫；Web/Android主程序及点单页摘要已接线。缺pay_info显示--；界面“优惠金额”对应yh_amt，“折扣金额”对应discount_amt+payed_free_amt，与Vue标签保持一致。
- S7.P2.T07/T08已编码未确认：11个原接口、零价、金额分单位校验、双Tab编辑器及立即移除/取消语义共12项契约和界面测试通过。未操作真实配置。
- M0.P5.T01已编码未确认：历史p2、整行pa、赠送与时价、缺pc与显式0/null区分已对齐；退款模型不代表实际退款接口闭环。
- M0.P5.T03已编码未确认：卡台推送页实时方案通知、弹窗后重查、身份/连接失效、0价以及已存订单不重价已接线。独立复核额外发现type5赔偿金额遗漏，已补add_prd的可选amount全链路；3/4/8继续按add_hl原规则，套餐不猜套用方案。
- 父代理重跑价格/历史/接口/界面相关82项通过；后续全量验证及APK证据记录在本轮最终检查段。仍未进行真实收款、退款、方案配置提交。

### 金额显示权限与后续缺口

新摘要和旧底部金额已支持PC营销角色3且模块12/99组合隐藏；未知权限隐藏，权限变更及身份变化实时撤销旧推送页可见性。源newMyOrder.vue:611与newFootBar.vue:1736。

初次价格轮仍缺旧底部四金额的canLookOrderAmt和督查区域判断。后续退单轮已按真实/wo/chk_order_can_see及metadata56补独立底栏通知与两端接线，未用本地模块猜服务器许可；保留原宽窄安全模式差异。当前证据和未完成的员工卡硬件/已结退款范围见2026-09-20-refund-gap.md。

父代理独立运行当前Vue四个相关测试文件：fcPriceConfig、fcOrderPrice、orderPayPrice、cashierWoSummary，共40/40通过，可作为后续Dart移植对照依据；不是Flutter已经通过这些规则。

## 本轮最终检查

### 用户复核发现：商品卡片缺原价（后续修正）

用户截图指出原Web GOGO小费同时展示划线原价800.00和方案价777.00，而Flutter仅777.00。此前价格选取/提交测试通过不代表展示一致，此项确属漏验。

已按主仓productList.vue与fcPriceMixin还原商品卡片：有效方案且原价>0且不同价时，灰色划线原价＋红色“方案价”；相同价或无方案不重复展示，普通价格使用原绿色。方案0保留，实时变价重绘。新增390px移动视口回归校验800→777、划线/颜色、0价、同价、无方案，点单页35项测试通过。此记录是代码测试证据，安装更新与用户实页确认仍需单独完成，不能追溯为此前已确认。

- Flutter完整测试：879/879通过，日志/tmp/shouyin-price-verify.aQKYyZ/tests-verified.log。
- 全工作区静态分析：0错误、0警告、135项info；边界检查0违反，git diff --check通过。
- Android调试APK重新构建成功，安装emulator-5554成功，MainActivity启动Status ok且处于Resumed；此次安装未清应用数据。
- Web开发服务热重启完成，实际页面读到9个系统选择按钮。尚未用真实账号实测本轮所有业务页，测试通过不等于人工验收。
- 未进行真实收款/退单/库存或价格方案变更。退款链路和旧底栏额外权限仍按上文保留待办，整体移植目标未完成。
