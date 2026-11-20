# 2026-09-20 点单优惠授权与套餐缺口

本次只读追踪当前路由newShoppingCart/newMyOrder/newDrawerMeal，不把旧drawer方法或Flutter已有按钮当作功能完成；未访问真实接口。

## 当前仍未闭环的授权

- 购物车优惠/wsc/to_yh、已下单优惠/wo/yh_prd：原版选择数量、原因后进入本人/他人授权，Flutter目前主要为整行本人请求，缺数量与他人/卡授权。
- 购物车/已下单优惠2：/wsc/to_yh2、/wo/yh2_prd还需所选行、数量、订位人与目标卡台及授权；当前手输目标ID不是完整选择流程。
- 菜单新增优惠：最新newDrawerMeal/singleProduct.vue营销分支已经改用/wsc/add_prd，附auth_type=2及prd_price；旧reqAddYhToShopping已注释，不能仅给旧/add_yh增加授权就宣称同源。
- 菜单新增优惠2/wsc/add_yh2源非1只提示，不自动把code2当授权。
- 非收银已下单换套餐/wo/set_chg明确code2转授权；收银走/sel/chg_prd_set_dtl不传授权字段。自动下单的code2另表示必点商品，code5表示零金额自动买单成功，不可统一解释。

授权字段：本人code/password为空；他人auth_emp_code与MD5大写密码，pass_type=1；员工卡使用卡号和卡内密码MD5大写，pass_type=2。真实读卡能力仍属于M0.P3.T04。

## 套餐可信字段

| 含义 | 购物车/点单响应 | 收银兼容响应 |
| --- | --- | --- |
| 父购物车/订单ID | 父行id | 父行id |
| 套餐商品及数量 | pid / pc | pid / pc |
| 套餐明细 | is=1, si数组 | 同左 |
| 组ID | si[].gid | 同左 |
| 明细商品ID | si[].i | si[].dpi |
| 单次商品数量 | si[].c | si[].dpc |
| 选中次数 | si[].s | si[].sc |
| 要求 | si[].r | 同左 |
| 实际已下单子订单ID | si[].id | 同左 |

get_items的data支持数组或records数组；wo/list使用records。orderDetailAdapter复制保留si，不生成子订单ID；退单展开行复制的si不能冒充可编辑订单。

### 换品请求

先选择gid!=1的一项原明细，保存其原商品、要求及s/sc次数，再选同组合法目标。

- /wsc/chg_set_dtl：父id、标量grp_ids、标量dtl_prd_ids（原商品）、requirement（原要求），以及目标dest_dtl_prd_ids/dest_sel_cnts/dest_requirements三数组。
- /wo/set_chg：order_id为父订单，order_dtl_id必须是选中si[].id，绝不是父id；dest_dtl_prd_ids/dest_dtl_prd_sel_cnts/dest_requirements，另含授权字段。收银改用/sel/chg_prd_set_dtl。

当前Flutter购物车把原商品ID误用为目标商品ID，已下单又把子订单ID误用为父订单ID。这两项已改标待接入，不允许用当前测试里的错误映射当源合同。

### 新增套餐

元数据9：[prdId,status,grpId,seqId,dtlPrdId,prdCnt,grpSelCnt,typeId]。

- 组1固定项sel_cnts=1；其他组要求所选次数总和等于grpSelCnt，不是只检查候选商品数。
- 同商品不同要求可分别选，不能仅按商品ID去重。
- 明细数量=prdCnt×选中次数×套餐数量；add_set五数组逐项对齐，prd_price为分。
- typeId=2需展开套餐模板，不能当普通商品ID。

关键源码：newShoppingCart/drawerGiveHeMoreForOrder.vue:794/968；myOrder/newDrawerMyOrder.vue:918/939/1595；newDrawerMeal/groupProduct.vue:423；utils/orderDetailAdapter.js；utils/transformCardData.js:134。

下一批实施顺序：真实si模型与解析 → 原项/合法目标选择 → 正确请求与授权分支 → 批量数量/要求/模板验证。以上未完成范围没有被本轮操作上下文安全修复替代。
