# 2026-09-20 已结支付渠道修改：实际为重新结算

## 原流程与副作用

源components/money/payedOrder.vue:509：先强确认“本订单已支付渠道将进入滞留金列表，本订单需重新支付”，再POST /sel/pay_order_back：

```json
{"seat_id":100,"pay_id":900,"remark":"","wk_order_ids":[],"prd_back_cnts":[],"prd_back_amts":[]}
```

以上数字仅为示例，不是真实请求。三空数组表示重新打开结算，不能与正常多项商品退款混用。

code1后重新读取/sel/csm_orders {seat_id,turnover_cnt}，用新unpay_order.os匹配原付款单商品；调用/sel/cart_begin_process {seat_id,wk_order_ids,prd_cnts,total_amt}，金额是元字符串。成功才进入普通购物车收款，最后/sel/pay_order并刷新未结页。源部分父订单更新允许数量0，不能误用正常退款必须正数的校验。

第一步成功即已改变后台。后续刷新、购物车初始化失败或者关闭抽屉，不等于恢复原付款单；恢复/重试不可再次自动“撤销结算”。

## 门禁与禁止猜测

- 历史翻台和线上付款单禁止更改；全部页仅恰好一张付款单才允许，否则必须选具体付款单。
- get_chg_pay_cnls在当前Vue只有API定义，没有页面调用，现Flutter猜测的返回字段不能据此上线。
- 普通渠道要来自有效支付配置和门店启用配置，不开放任意手输ID。
- 5会员卡落单、6挂账、10授权抹零、500实体会员卡、202预订金、9999合成滞留金入口、1000合成线上收款入口各有专属协议，不能作为普通渠道绕过。
- 500原请求使用seat_id/auth_type=1/auth_code/mb_card_id/amt（分）；202使用seat_id/auth_code/prepay_id/amt并需相应验证；9999实际调用cart_add_late_cnl {id,late_id}，不能传9999冒充真实渠道。

## 当前实施状态

- 已新增独立reopenPaidPayment API/loader，精确三空数组和空remark；cashier限定，未放宽普通refundPayed的非空选择约束。
- 已新增beginPaymentProcess API/loader，数组对齐/唯一、合法ID、非负数量及元金额；均沿用会话/在线/generation守卫。
- API底座已用本地适配器测试；尚未接渠道修改UI状态流程或真实交易，不宣称S3.P2.T03整项闭环。
- 先补有效渠道配置及分阶段失败恢复，再接强提示UI。绝不以占位“操作成功”取代后端结果。
