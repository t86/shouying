<template>
  <div>
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div
        class="session p-5 fs14"
        layout="row"
        layout-align="space-around start"
      >
        <div class="item">
          <div>
            <div class="title bold">出品单格式:</div>
            <div class="content">
              <div class="bill_info">
                <div class="bill_info_l">[卡座区] K001</div>
              </div>
              <div class="guest_info">
                <div class="guest_info_l">人数：2</div>
                <div class="guest_info_r">服务员：000000 系统管理员</div>
              </div>
              <div class="pro border-b">
                <div class="pro_td_o_li fs17">百威啤酒</div>
                <div class="w200 pro_td_o_li">¥10.00</div>
                <div class="pro_td_o_li bold">1</div>
              </div>
              <div class="pro border-b">
                <div class="pro_td_o_li fs17">雪花啤酒</div>
                <div class="w200 pro_td_o_li">¥10.00</div>
                <div class="pro_td_o_li bold">1</div>
              </div>
              <div class="pro pro_tc m-t-2">
                <div class="pro_td_o_li fs17">小吃套餐</div>
                <div class="w200 pro_td_o_li">¥20.00</div>
                <div class="pro_td_o_li bold">1</div>
              </div>
              <div class="pro pro_tc">
                <div class="pro_td_o_li m-l-4 fs17">花生</div>
                <div class="pro_td_o_li bold">1</div>
              </div>
              <div class="pro pro_tc border-b" style="padding-bottom: 8px">
                <div class="pro_td_o_li m-l-4 fs17">可乐</div>
                <div class="pro_td_o_li bold">1</div>
              </div>
              <div class="totalmoney">
                <div class="totalmoney_l">总金额：40.00元</div>
                <div class="totalmoney_r">总数：4（3道）</div>
              </div>
              <div class="order_time">
                <div class="order_time_li">下单时间：2023-02-07 21:50:20</div>
                <div class="order_time_li">打印时间：2023-02-07 21:50:20</div>
                <div class="order_time_li">[大厅出品库]</div>
              </div>
            </div>
          </div>
          <div class="NoPaging">
            <div class="title bold">出品单（退单）格式:</div>
            <div class="content">
              <div class="bill_info">
                <div class="bill_info_l">[卡座区] K001</div>
              </div>
              <div class="guest_info">
                <div class="guest_info_l">人数：2</div>
                <div class="guest_info_r">服务员：000000 系统管理员</div>
              </div>
              <div class="pro border-b">
                <div class="pro_td_o_li fs17">雪花啤酒</div>
                <div class="w200 pro_td_o_li">¥10.00</div>
                <div class="pro_td_o_li bold">-1</div>
              </div>

              <div class="totalmoney">
                <div class="totalmoney_l">退单金额：10.00元</div>
                <div class="totalmoney_r">总数：1（1道）</div>
              </div>
              <div class="order_time">
                <div class="order_time_li">退单人：系统管理员</div>
                <div class="order_time_li">退单原因：点错了</div>
                <div class="order_time_li">下单时间：2023-02-07 21:50:20</div>
                <div class="order_time_li">打印时间：2023-02-07 21:50:20</div>
                <div class="order_time_li">[大厅出品库]</div>
              </div>
            </div>
          </div>
          <div class="NoPaging">
            <div class="title bold">消费单格式:</div>
            <div class="content">
              <div class="guest_info" style="border: none">
                <div class="guest_info_l">[卡座区] K001</div>
                <div class="guest_info_r">K001-001</div>
              </div>
              <div class="guest_info" style="margin-top: -4px">
                <div class="guest_info_l">人数：2</div>
                <div class="guest_info_r">订台人：营销</div>
              </div>
              <div class="pro_th pro_th_t" style="margin: 8px 0 4px">
                <div class="pro_th_t_li" style="width: 40%">商品名称</div>
                <div class="pro_th_t_li" style="">单价</div>
                x
                <div class="pro_th_t_li" style="width: 15%">数量</div>
                <div class="pro_th_t_li" style="width: 15%; text-align: right">
                  小计
                </div>
              </div>
              <div class="pro pro_td_t pro_tc pro_hint">
                <div class="pro_td_t_li" style="width: 40%">轩尼诗VSOP</div>
                <div
                  class="pro_td_t_li"
                  style="
                    width: 30%;
                    padding-left: 10px;
                    box-sizing: border-box;
                    white-space: nowrap;
                  "
                >
                  ¥1.00
                </div>
                <div class="pro_td_t_li" style="width: 15%">2</div>
                <div class="pro_td_t_li" style="width: 15%; text-align: right">
                  ¥2.00
                </div>
              </div>
              <div class="pro pro_td_t pro_tc pro_hint">
                <div class="pro_td_t_li" style="width: 40%">水果拼盘</div>
                <div
                  class="pro_td_t_li"
                  style="
                    width: 30%;
                    padding-left: 10px;
                    box-sizing: border-box;
                    white-space: nowrap;
                  "
                >
                  ¥1.00
                </div>
                <div class="pro_td_t_li" style="width: 15%">2</div>
                <div class="pro_td_t_li" style="width: 15%; text-align: right">
                  ¥2.00
                </div>
              </div>
              <div class="pro pro_td_t pro_tc pro_hint">
                <div class="pro_td_t_li" style="width: 40%">花生</div>
                <div
                  class="pro_td_t_li"
                  style="
                    width: 30%;
                    padding-left: 10px;
                    box-sizing: border-box;
                    white-space: nowrap;
                  "
                >
                  ¥1.00
                </div>
                <div class="pro_td_t_li" style="width: 15%">2</div>
                <div class="pro_td_t_li" style="width: 15%; text-align: right">
                  ¥2.00
                </div>
              </div>
              <div class="pro pro_td_t pro_tc pro_hint">
                <div class="pro_td_t_li" style="width: 40%">锅巴</div>
                <div
                  class="pro_td_t_li"
                  style="
                    width: 30%;
                    padding-left: 10px;
                    box-sizing: border-box;
                    white-space: nowrap;
                  "
                >
                  ¥2.00
                </div>
                <div class="pro_td_t_li" style="width: 15%">1</div>
                <div class="pro_td_t_li" style="width: 15%; text-align: right">
                  ¥2.00
                </div>
              </div>
              <div class="pro pro_td_t pro_tc pro_hint">
                <div class="pro_td_t_li" style="width: 40%">百威</div>
                <div
                  class="pro_td_t_li"
                  style="
                    width: 30%;
                    padding-left: 10px;
                    box-sizing: border-box;
                    white-space: nowrap;
                  "
                >
                  ¥5.00
                </div>
                <div class="pro_td_t_li" style="width: 15%">1</div>
                <div class="pro_td_t_li" style="width: 15%; text-align: right">
                  ¥5.00
                </div>
              </div>
              <div class="pro pro_td_t pro_tc pro_hint">
                <div class="pro_td_t_li" style="width: 40%">雪花</div>
                <div
                  class="pro_td_t_li"
                  style="
                    width: 30%;
                    padding-left: 10px;
                    box-sizing: border-box;
                    white-space: nowrap;
                  "
                >
                  ¥5.00
                </div>
                <div class="pro_td_t_li" style="width: 15%">1</div>
                <div class="pro_td_t_li" style="width: 15%; text-align: right">
                  ¥5.00
                </div>
              </div>
              <div class="pro pro_td_t pro_tc pro_hint">
                <div class="pro_td_t_li" style="width: 40%">绿茶</div>
                <div
                  class="pro_td_t_li"
                  style="
                    width: 30%;
                    padding-left: 10px;
                    box-sizing: border-box;
                    white-space: nowrap;
                  "
                >
                  ¥4.00
                </div>
                <div class="pro_td_t_li" style="width: 15%">2</div>
                <div class="pro_td_t_li" style="width: 15%; text-align: right">
                  ¥8.00
                </div>
              </div>
              <div class="pro pro_td_t pro_tc pro_hint">
                <div class="pro_td_t_li" style="width: 40%">小吃套餐</div>
                <div
                  class="pro_td_t_li"
                  style="
                    width: 30%;
                    padding-left: 10px;
                    box-sizing: border-box;
                    white-space: nowrap;
                  "
                >
                  ¥9.00
                </div>
                <div class="pro_td_t_li" style="width: 15%">1</div>
                <div class="pro_td_t_li" style="width: 15%; text-align: right">
                  ¥9.00
                </div>
              </div>
              <div class="pro pro_td_t pro_tc pro_hint">
                <div class="pro_td_t_li" style="width: 40%">
                  &nbsp;&nbsp;锅巴
                </div>
                <div
                  class="pro_td_t_li"
                  style="width: 30%; padding-left: 10px; box-sizing: border-box"
                ></div>
                <div class="pro_td_t_li" style="width: 15%">1</div>
                <div
                  class="pro_td_t_li"
                  style="width: 15%; text-align: right"
                ></div>
              </div>
              <div
                class="pro pro_td_t pro_tc pro_hint border-b"
                style="padding-bottom: 4px"
              >
                <div class="pro_td_t_li" style="width: 40%">
                  &nbsp;&nbsp;红茶
                </div>
                <div
                  class="pro_td_t_li"
                  style="width: 30%; padding-left: 10px; box-sizing: border-box"
                ></div>
                <div class="pro_td_t_li" style="width: 15%">1</div>
                <div
                  class="pro_td_t_li"
                  style="width: 15%; text-align: right"
                ></div>
              </div>
              <div class="totalmoney">
                <div class="totalmoney_l">优惠金额：¥10.00</div>
                <div class="totalmoney_r">应收金额：¥25.00</div>
              </div>
              <div class="totalmoney" style="margin-top: -14px">
                <div class="totalmoney_l">已收金额：¥0.00</div>
                <div class="totalmoney_r">未收金额：¥0.00</div>
              </div>
              <div class="order_time">
                <div class="order_time_li">下单时间：2023-02-07 21:50:20</div>
                <div class="order_time_li">打印时间：2023-02-07 21:50:20</div>
              </div>
            </div>
          </div>
          <div class="NoPaging p-t-1">
            <div class="title bold">套餐更换商品单格式:</div>
            <div class="content">
              <div class="bill_info">
                <div class="bill_info_l">[卡座区] K001</div>
              </div>
              <div class="guest_info">
                <div class="guest_info_l">人数：2</div>
                <div class="guest_info_r">服务员：000000 系统管理员</div>
              </div>
              <div class="pro pro_tc">
                <div class="pro_td_o_li fs17">小吃套餐</div>
                <div class="w200 pro_td_o_li">¥0.00</div>
                <div class="pro_td_o_li bold">1</div>
              </div>
              <div class="pro pro_tc">
                <div class="pro_td_o_li m-l-4 fs17">(退)花生</div>
                <div class="pro_td_o_li bold">-1</div>
              </div>
              <div class="pro pro_tc border-b" style="padding-bottom: 8px">
                <div class="pro_td_o_li m-l-4 fs17">(换)可乐</div>
                <div class="pro_td_o_li bold">1</div>
              </div>

              <div class="totalmoney">
                <div class="totalmoney_l"></div>
                <div class="totalmoney_r">总数：退1（1道）；换1（1道）</div>
              </div>
              <div class="order_time">
                <div class="order_time_li">更换人：系统管理员</div>
                <div class="order_time_li">下单时间：2023-02-07 21:50:20</div>
                <div class="order_time_li">打印时间：2023-02-07 21:50:20</div>
                <div class="order_time_li">[大厅出品库]</div>
              </div>
            </div>
          </div>
          <div class="NoPaging p-t-1">
            <div class="title bold">会员卡扣款格式:</div>
            <div class="content">
              <div class="guest_info" style="border: none">
                <div class="guest_info_l">操作人：收银员</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">流水号：129988877777</div>
              </div>
              <div class="guest_info" style="margin-top: -4px">
                <div class="guest_info_l">扣款时间：2023-09-09 12:33:32</div>
              </div>
              <div class="guest_info" style="border: none">
                <div class="guest_info_l">卡号：00000000000001</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">姓名：会员vip</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">储值金额扣款：￥1000.00</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">赠送金额扣款：￥1000.00</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">扣款类型：业务扣款</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">扣后储值余额: ￥2000.00</div>
              </div>
              <div class="guest_info" style="margin-top: -4px">
                <div class="guest_info_l">扣后赠送余额：￥0.00</div>
              </div>
              <div class="order_time">
                <div class="order_time_li">打印时间：2023-09-09 12:33:32</div>
              </div>
            </div>
          </div>

          <div class="NoPaging p-t-1">
            <div class="title bold">会员卡消费格式:</div>
            <div class="content">
              <div class="guest_info" style="border: none">
                <div class="guest_info_l">操作人：收银员</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">流水号：129988877777</div>
              </div>
              <div class="guest_info" style="margin-top: -4px">
                <div class="guest_info_l">扣款时间：2023-09-09 12:33:32</div>
              </div>
              <div class="guest_info" style="border: none">
                <div class="guest_info_l">卡号：00000000000001</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">姓名：会员vip</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">储值金额消费：￥1000.00</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">赠送金额消费：￥1000.00</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">消后储值余额: ￥2000.00</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">消后赠送余额：￥0.00</div>
              </div>
              <div class="guest_info" style="margin-top: -4px">
                <div class="guest_info_l">消后赠送积分：&nbsp;&nbsp;1000</div>
              </div>
              <div class="order_time">
                <div class="order_time_li">打印时间：2023-09-09 12:33:32</div>
              </div>
            </div>
          </div>
        </div>
        <div class="item">
          <div class="NoPaging">
            <div class="title bold">传菜单格式:</div>
            <div class="content">
              <div class="bill_info">
                <div class="bill_info_l">[卡座区] K001</div>
              </div>
              <div class="guest_info">
                <div class="guest_info_l">人数：2</div>
                <div class="guest_info_r">服务员：000000 系统管理员</div>
              </div>
              <div class="pro border-b">
                <div class="pro_td_o_li fs17">百威啤酒</div>
                <div class="w200 pro_td_o_li">¥10.00</div>
                <div class="pro_td_o_li bold">1</div>
              </div>
              <div class="pro border-b">
                <div class="pro_td_o_li fs17">雪花啤酒</div>
                <div class="w200 pro_td_o_li">¥10.00</div>
                <div class="pro_td_o_li bold">1</div>
              </div>
              <div class="pro pro_tc m-t-2">
                <div class="pro_td_o_li fs17">小吃套餐</div>
                <div class="w200 pro_td_o_li">¥20.00</div>
                <div class="pro_td_o_li bold">1</div>
              </div>
              <div class="pro pro_tc">
                <div class="pro_td_o_li m-l-4 fs17">花生</div>
                <div class="pro_td_o_li bold">1</div>
              </div>
              <div class="pro pro_tc border-b" style="padding-bottom: 8px">
                <div class="pro_td_o_li m-l-4 fs17">可乐</div>
                <div class="pro_td_o_li bold">1</div>
              </div>
              <div class="totalmoney">
                <div class="totalmoney_l"></div>
                <div class="totalmoney_r">总数：4（3道）</div>
              </div>
              <div class="order_time">
                <div class="order_time_li">下单时间：2023-02-07 21:50:20</div>
                <div class="order_time_li">打印时间：2023-02-07 21:50:20</div>
                <div class="order_time_li">[大厅出品库]</div>
              </div>
            </div>
          </div>
          <div class="NoPaging">
            <div class="title bold">出品单（退单|收银）格式:</div>
            <div class="content">
              <div class="bill_info">
                <div class="bill_info_l">[卡座区] K001</div>
              </div>
              <div class="guest_info">
                <div class="guest_info_l">人数：2</div>
                <div class="guest_info_r">服务员：000000 系统管理员</div>
              </div>
              <div class="pro border-b">
                <div class="pro_td_o_li fs17">雪花啤酒</div>
                <div class="w200 pro_td_o_li">¥10.00</div>
                <div class="pro_td_o_li bold">-1</div>
              </div>

              <div class="totalmoney">
                <div class="totalmoney_l">退单金额：10.00元</div>
                <div class="totalmoney_r">总数：1（1道）</div>
              </div>
              <div class="order_time">
                <div class="order_time_li">退单人：系统管理员</div>
                <div class="order_time_li">退单原因：点错了</div>
                <div class="order_time_li">下单时间：2023-02-07 21:50:20</div>
                <div class="order_time_li">打印时间：2023-02-07 21:50:20</div>
              </div>
            </div>
          </div>
          <div class="NoPaging p-t-5">
            <div class="title bold">结算单格式:</div>
            <div class="content">
              <div class="guest_info" style="border: none">
                <div class="guest_info_l">[卡座区] K001</div>
                <div class="guest_info_r">K001-001</div>
              </div>
              <div class="guest_info" style="margin-top: -4px; border: none">
                <div class="guest_info_l">人数：2</div>
                <div class="guest_info_r">订台人：营销</div>
              </div>
              <div class="guest_info" style="margin-top: -4px">
                <div class="guest_info_l">收银员：系统管理员</div>
              </div>
              <div class="pro_th pro_th_t" style="margin: 8px 0 4px">
                <div class="pro_th_t_li" style="width: 40%">商品名称</div>
                <div class="pro_th_t_li" style="">单价</div>
                x
                <div class="pro_th_t_li" style="width: 15%">数量</div>
                <div class="pro_th_t_li" style="width: 15%; text-align: right">
                  小计
                </div>
              </div>
              <div class="pro pro_td_t pro_tc pro_hint">
                <div class="pro_td_t_li" style="width: 40%">轩尼诗VSOP</div>
                <div
                  class="pro_td_t_li"
                  style="
                    width: 30%;
                    padding-left: 10px;
                    box-sizing: border-box;
                    white-space: nowrap;
                  "
                >
                  ¥1.00
                </div>
                <div class="pro_td_t_li" style="width: 15%">2</div>
                <div class="pro_td_t_li" style="width: 15%; text-align: right">
                  ¥2.00
                </div>
              </div>
              <div class="pro pro_td_t pro_tc pro_hint">
                <div class="pro_td_t_li" style="width: 40%">水果拼盘</div>
                <div
                  class="pro_td_t_li"
                  style="
                    width: 30%;
                    padding-left: 10px;
                    box-sizing: border-box;
                    white-space: nowrap;
                  "
                >
                  ¥1.00
                </div>
                <div class="pro_td_t_li" style="width: 15%">2</div>
                <div class="pro_td_t_li" style="width: 15%; text-align: right">
                  ¥2.00
                </div>
              </div>
              <div class="pro pro_td_t pro_tc pro_hint">
                <div class="pro_td_t_li" style="width: 40%">花生</div>
                <div
                  class="pro_td_t_li"
                  style="
                    width: 30%;
                    padding-left: 10px;
                    box-sizing: border-box;
                    white-space: nowrap;
                  "
                >
                  ¥1.00
                </div>
                <div class="pro_td_t_li" style="width: 15%">2</div>
                <div class="pro_td_t_li" style="width: 15%; text-align: right">
                  ¥2.00
                </div>
              </div>
              <div class="pro pro_td_t pro_tc pro_hint">
                <div class="pro_td_t_li" style="width: 40%">小吃套餐</div>
                <div
                  class="pro_td_t_li"
                  style="
                    width: 30%;
                    padding-left: 10px;
                    box-sizing: border-box;
                    white-space: nowrap;
                  "
                >
                  ¥9.00
                </div>
                <div class="pro_td_t_li" style="width: 15%">1</div>
                <div class="pro_td_t_li" style="width: 15%; text-align: right">
                  ¥9.00
                </div>
              </div>
              <div class="pro pro_td_t pro_tc pro_hint">
                <div class="pro_td_t_li" style="width: 40%">
                  &nbsp;&nbsp;锅巴
                </div>
                <div class="pro_td_t_li" style="width: 30%"></div>
                <div class="pro_td_t_li" style="width: 15%">1</div>
                <div
                  class="pro_td_t_li"
                  style="width: 15%; text-align: right"
                ></div>
              </div>
              <div
                class="pro pro_td_t pro_tc pro_hint border-b"
                style="padding-bottom: 4px"
              >
                <div class="pro_td_t_li" style="width: 40%">
                  &nbsp;&nbsp;红茶
                </div>
                <div class="pro_td_t_li" style="width: 30%"></div>
                <div class="pro_td_t_li" style="width: 15%">1</div>
                <div
                  class="pro_td_t_li"
                  style="width: 15%; text-align: right"
                ></div>
              </div>
              <div class="border-b m-t-2 p-b-2">
                <div class="totalmoney_l">
                  现金：<span style="margin-left: 190px">¥8.00</span>
                </div>
                <br />
                <div class="totalmoney_l" style="margin-top: -12px">
                  会员卡(a00001 张三)<span style="margin-left: 100px"
                    >¥7.00</span
                  >
                </div>
                <br />
                <div class="totalmoney_l" style="margin-top: -12px">
                  &nbsp;&nbsp;(储:¥2.00&nbsp;&nbsp;折:¥5.00)
                </div>
              </div>
              <div class="totalmoney">
                <div class="totalmoney_l">优惠金额：¥0.00</div>
                <div class="totalmoney_r">账单金额：¥15.00</div>
              </div>
              <div class="totalmoney" style="margin-top: -14px">
                <div class="totalmoney_l">折扣金额：¥5.00</div>
                <div class="totalmoney_r">实收金额：¥10.00</div>
              </div>
              <div class="order_time">
                <div class="order_time_li">下单时间：2023-02-07 21:50:20</div>
                <div class="order_time_li">打印时间：2023-02-07 21:50:20</div>
              </div>
            </div>
          </div>
          <div class="NoPaging">
            <div class="title bold">售出日报表格式:</div>
            <div class="content">
              <div class="guest_info" style="border: none">
                <div class="guest_info_l">营业日期：2023/02/07</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">收银员：系统管理员</div>
              </div>
              <div class="guest_info" style="margin-top: -4px">
                <div class="guest_info_l">
                  统计规则：全部分类；全部出品库；全部订单
                </div>
              </div>
              <div
                class="pro_th pro_th_t border-b p-t-1 p-b-3"
                style="margin: 6px 0"
              >
                <div class="pro_th_t_li">商品名称</div>
                <div class="pro_th_t_li" style="white-space: nowrap">
                  售出数量
                </div>
              </div>
              <div class="pro pro_td_t pro_tc pro_hint m-t-2">
                <div class="pro_td_t_li">轩尼诗VSOP</div>
                <div class="pro_td_t_li bold" style="text-align: right">10</div>
              </div>
              <div class="pro pro_td_t pro_tc pro_hint">
                <div class="pro_td_t_li">水果拼盘</div>
                <div class="pro_td_t_li bold" style="text-align: right">20</div>
              </div>
              <div class="pro pro_td_t pro_tc pro_hint">
                <div class="pro_td_t_li">花生</div>
                <div class="pro_td_t_li bold" style="text-align: right">50</div>
              </div>
              <div class="pro pro_td_t pro_tc pro_hint border-b">
                <div class="pro_td_t_li p-b-2">锅巴</div>
                <div class="pro_td_t_li p-b-2 bold" style="text-align: right">
                  12
                </div>
              </div>
              <div class="order_time m-t-3">
                <div class="order_time_li">打印时间：2023-02-07 21:50:20</div>
              </div>
            </div>
          </div>

          <div class="NoPaging p-t-1">
            <div class="title bold">会员卡充值格式:</div>
            <div class="content">
              <div class="guest_info" style="border: none">
                <div class="guest_info_l">操作人：收银员</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">推荐人：李四</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">流水号：129988877777</div>
              </div>
              <div class="guest_info" style="margin-top: -4px">
                <div class="guest_info_l">充值时间：2023-09-09 12:33:32</div>
              </div>
              <div class="guest_info" style="border: none">
                <div class="guest_info_l">卡号：00000000000001</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">姓名：会员vip</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">充值金额：￥1000.00</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">赠送金额：￥1000.00</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">赠送积分：&nbsp;&nbsp;1000</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">充值方式：现金</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">充后储值余额: ￥2000.00</div>
              </div>
              <div class="guest_info" style="margin-top: -4px">
                <div class="guest_info_l">充后赠送余额：￥2000.00</div>
              </div>

              <div class="order_time">
                <div class="order_time_li">打印时间：2023-09-09 12:33:32</div>
              </div>
            </div>
          </div>

          <div class="NoPaging p-t-1">
            <div class="title bold">会员卡扣除积分格式:</div>
            <div class="content">
              <div class="guest_info" style="border: none">
                <div class="guest_info_l">操作人：收银员</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">流水号：129988877777</div>
              </div>
              <div class="guest_info" style="margin-top: -4px">
                <div class="guest_info_l">扣除时间：2023-09-09 12:33:32</div>
              </div>
              <div class="guest_info" style="border: none">
                <div class="guest_info_l">卡号：00000000000001</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">姓名：会员vip</div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">
                  扣除积分：&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1000
                </div>
              </div>
              <div class="guest_info" style="border: none; margin-top: -4px">
                <div class="guest_info_l">扣除前积分余额：2000</div>
              </div>
              <div class="guest_info" style="margin-top: -4px">
                <div class="guest_info_l">扣除后积分余额：1000</div>
              </div>

              <div class="order_time">
                <div class="order_time_li">打印时间：2023-09-09 12:33:32</div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
export default {
  data() {
    return {};
  },
  methods: {
    async onSubmit() {},
    onCancelDrawer() {
      this.show = false;
    },
  },
  created() {},
  mounted() {},
  props: {
    value: {
      default: false,
    },
  },
  computed: {
    title() {
      return "小票预览";
    },
    show: {
      get() {
        return this.value;
      },
      set(val) {
        this.$emit("input", val);
      },
    },
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
        }
      },
      immediate: true,
    },
  },
};
</script>

<style scoped lang="less">
@import "../../../../style/common/elementDrawerWine.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/common/elementFormBtnWine.less";
@import "../../../../style/erp/form.less";
@import "../../../../style/erp/table.less";
</style>
<style scoped lang="less">
.item {
  width: 46%;
  color: #333;
  .title {
    font-size: 18px;
    padding: 16px 0;
  }
  .content {
    border: 1px solid #333;
    padding: 10px;

    .bill_info_l {
      font-weight: 600;
    }

    .guest_info {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin: 8px 0 4px;
      font-size: 12px;
      padding-bottom: 6px;
      border-bottom: 1px dashed #333;
    }

    .pro {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 10px 0 12px;
      .pro_td_o_li {
        line-height: 20px;
        max-width: 70%;
        word-wrap: break-word;
      }

      .pro_td_o_li.w200 {
        width: 150px;
        text-align: right;
        font-size: 13px;
      }

      .pro_td_o_li.bold {
        font-size: 18px;
      }

      &.pro_tc {
        padding: 2px 0;
      }
    }

    .pro_th,
    .totalmoney {
      display: flex;
      flex-direction: row;
      align-items: center;
      justify-content: space-between;
      margin: 8px 0 16px;
    }

    .sign {
      padding: 26px 0 26px;
      border-bottom: 1px dashed #333;
    }

    .order_time {
      .order_time_li {
        margin-top: 6px;
      }
    }

    .pro_hint {
      margin: 0;
      .pro_td_t_li {
        border-bottom: none;
        font-weight: 400;
        font-size: 12px;
        line-height: 20px;
      }
    }
  }

  .bold {
    font-weight: 600;
  }

  .border-b {
    border-bottom: 1px dashed #333;
  }

  .fs17 {
    font-size: 17px;
  }
}
</style>
