<template>
  <div class="bill form">
    <el-form label-position="left">
      <div class="compatibil">
        <div class="compatibility">
          <div class="mandatory">
            <span class="reqfieldsd"></span>下单消费单（点单机）打印份数：
          </div>
          <el-form-item class="controlling">
            <el-input-number v-model="orderCount" :min="0" :max="9" />
          </el-form-item>
        </div>
      </div>
      <div class="compatibil">
        <div class="compatibility">
          <div class="mandatory">
            <span class="reqfieldsd"></span>结账结算单（收银台）打印份数：
          </div>
          <el-form-item class="controlling">
            <el-input-number v-model="orderPayedCount" :min="0" :max="9"/>
          </el-form-item>
        </div>
      </div>
      <div class="compatibil">
        <div class="compatibility">
          <div class="mandatory">
            <span class="reqfieldsd"></span>清台结算单打印份数：
          </div>
          <el-form-item class="controlling">
            <el-input-number v-model="clearCardCount" :min="0" :max="9"/>
          </el-form-item>
        </div>
      </div>
      <div class="compatibil">
        <div class="compatibility">
          <div class="mandatory">
            <span class="reqfieldsd"></span>退单小票（出品库）打印份数：
          </div>
          <el-form-item class="controlling">
            <el-input-number v-model="backOrderCount" :min="0" :max="9" />
          </el-form-item>
        </div>
      </div>
      <div class="compatibil">
        <div class="compatibility">
          <div class="mandatory">
            <span class="reqfieldsd"></span>退单小票（收银台）打印份数：
          </div>
          <el-form-item class="controlling">
            <el-input-number v-model="backOrderMoneyCount" :min="0" :max="9"/>
          </el-form-item>
        </div>
      </div>
    </el-form>
    <span slot="footer" class="dialog-footer">
      <el-button class="save" type="primary" @click="saveConfig">保存</el-button>
      <span class="preview" @click="PagingPreview = true">查看小票预览</span>
    </span>

    <!-- 小票预览 -->
    <div class="Pagingss" v-show="PagingPreview">
      <el-dialog title="小票预览" :visible.sync="PagingPreview" :close-on-click-modal="false">
        <div class="Pagingll">
          <div class="Pagingll_left">
            <div class="NoPaging">
              <div class="headline">出品单格式:</div>
              <div class="content">
                <div class="bill_info">
                  <div class="bill_info_l">[卡座区] K001</div>
                </div>
                <div class="guest_info">
                  <div class="guest_info_l">人数：2</div>
                  <div class="guest_info_r">服务员：000000 系统管理员</div>
                </div>
                <!-- <div class="pro_th">
                                    <div class="pro_th_o_li">商品名称</div>
                                    <div class="pro_th_o_li">单价x数量</div>
                </div>-->
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
                <div class="pro pro_tc border-b" style="padding-bottom:8px">
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
              <div class="headline">出品单（退单）格式:</div>
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
              <div class="headline">消费单格式:</div>
              <div class="content">
                <div class="guest_info" style="border:none">
                  <div class="guest_info_l">[卡座区] K001</div>
                  <div class="guest_info_r">K001-001</div>
                </div>
                <div class="guest_info" style="margin-top:-10px">
                  <div class="guest_info_l">人数：2</div>
                  <div class="guest_info_r">订台人：营销</div>
                </div>
                <div class="pro_th pro_th_t">
                  <div class="pro_th_t_li">商品名称</div>
                  <div class="pro_th_t_li">单价</div>x
                  <div class="pro_th_t_li">数量</div>
                  <div class="pro_th_t_li">小计</div>
                </div>
                <div class="pro pro_td_t pro_tc pro_hint">
                  <div class="pro_td_t_li">轩尼诗VSOP</div>
                  <div class="pro_td_t_li">¥1.00</div>
                  <div class="pro_td_t_li">2</div>
                  <div class="pro_td_t_li">¥2.00</div>
                </div>
                <div class="pro pro_td_t pro_tc pro_hint">
                  <div class="pro_td_t_li">水果拼盘</div>
                  <div class="pro_td_t_li">¥1.00</div>
                  <div class="pro_td_t_li">2</div>
                  <div class="pro_td_t_li">¥2.00</div>
                </div>
                <div class="pro pro_td_t pro_tc pro_hint">
                  <div class="pro_td_t_li">花生</div>
                  <div class="pro_td_t_li">¥1.00</div>
                  <div class="pro_td_t_li">2</div>
                  <div class="pro_td_t_li">¥2.00</div>
                </div>
                <div class="pro pro_td_t pro_tc pro_hint">
                  <div class="pro_td_t_li">锅巴</div>
                  <div class="pro_td_t_li">¥2.00</div>
                  <div class="pro_td_t_li">1</div>
                  <div class="pro_td_t_li">¥2.00</div>
                </div>
                <div class="pro pro_td_t pro_tc pro_hint">
                  <div class="pro_td_t_li">百威</div>
                  <div class="pro_td_t_li">¥5.00</div>
                  <div class="pro_td_t_li">1</div>
                  <div class="pro_td_t_li">¥5.00</div>
                </div>
                <div class="pro pro_td_t pro_tc pro_hint">
                  <div class="pro_td_t_li">雪花</div>
                  <div class="pro_td_t_li">¥5.00</div>
                  <div class="pro_td_t_li">1</div>
                  <div class="pro_td_t_li">¥5.00</div>
                </div>
                <div class="pro pro_td_t pro_tc pro_hint">
                  <div class="pro_td_t_li">绿茶</div>
                  <div class="pro_td_t_li">¥4.00</div>
                  <div class="pro_td_t_li">2</div>
                  <div class="pro_td_t_li">¥8.00</div>
                </div>
                <div class="pro pro_td_t pro_tc pro_hint">
                  <div class="pro_td_t_li">小吃套餐</div>
                  <div class="pro_td_t_li">¥9.00</div>
                  <div class="pro_td_t_li">1</div>
                  <div class="pro_td_t_li">¥9.00</div>
                </div>
                <div class="pro pro_td_t pro_tc pro_hint">
                  <div class="pro_td_t_li">&nbsp;&nbsp;锅巴</div>
                  <div class="pro_td_t_li"></div>
                  <div class="pro_td_t_li">1</div>
                  <div class="pro_td_t_li"></div>
                </div>
                <div class="pro pro_td_t pro_tc pro_hint border-b" style="padding-bottom: 4px">
                  <div class="pro_td_t_li">&nbsp;&nbsp;红茶</div>
                  <div class="pro_td_t_li"></div>
                  <div class="pro_td_t_li">1</div>
                  <div class="pro_td_t_li"></div>
                </div>
                <div class="totalmoney">
                  <div class="totalmoney_l">优惠金额：¥10.00</div>
                  <div class="totalmoney_r">应收金额：¥25.00</div>
                </div>
                <div class="totalmoney" style="margin-top:-20px">
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
              <div class="headline">套餐更换商品单格式:</div>
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
                <div class="pro pro_tc border-b" style="padding-bottom:8px">
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
          </div>
          <div class="Pagingll_right">
            <div class="NoPaging">
              <div class="headline">传菜单格式:</div>
              <div class="content">
                <div class="bill_info">
                  <div class="bill_info_l">[卡座区] K001</div>
                </div>
                <div class="guest_info">
                  <div class="guest_info_l">人数：2</div>
                  <div class="guest_info_r">服务员：000000 系统管理员</div>
                </div>
                <!-- <div class="pro_th">
                                    <div class="pro_th_o_li">商品名称</div>
                                    <div class="pro_th_o_li">单价x数量</div>
                </div>-->
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
                <div class="pro pro_tc border-b" style="padding-bottom:8px">
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
              <div class="headline">出品单（退单|收银）格式:</div>
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
              <div class="headline">结算单格式:</div>
              <div class="content">
                <div class="guest_info" style="border:none">
                  <div class="guest_info_l">[卡座区] K001</div>
                  <div class="guest_info_r">K001-001</div>
                </div>
                <div class="guest_info" style="margin-top:-10px;border:none">
                  <div class="guest_info_l">人数：2</div>
                  <div class="guest_info_r">订台人：营销</div>
                </div>
                <div class="guest_info" style="margin-top:-10px">
                  <div class="guest_info_l">收银员：系统管理员</div>
                </div>
                <div class="pro_th pro_th_t">
                  <div class="pro_th_t_li">商品名称</div>
                  <div class="pro_th_t_li">单价</div>x
                  <div class="pro_th_t_li">数量</div>
                  <div class="pro_th_t_li">小计</div>
                </div>
                <div class="pro pro_td_t pro_tc pro_hint">
                  <div class="pro_td_t_li">轩尼诗VSOP</div>
                  <div class="pro_td_t_li">¥1.00</div>
                  <div class="pro_td_t_li">2</div>
                  <div class="pro_td_t_li">¥2.00</div>
                </div>
                <div class="pro pro_td_t pro_tc pro_hint">
                  <div class="pro_td_t_li">水果拼盘</div>
                  <div class="pro_td_t_li">¥1.00</div>
                  <div class="pro_td_t_li">2</div>
                  <div class="pro_td_t_li">¥2.00</div>
                </div>
                <div class="pro pro_td_t pro_tc pro_hint">
                  <div class="pro_td_t_li">花生</div>
                  <div class="pro_td_t_li">¥1.00</div>
                  <div class="pro_td_t_li">2</div>
                  <div class="pro_td_t_li">¥2.00</div>
                </div>
                <div class="pro pro_td_t pro_tc pro_hint">
                  <div class="pro_td_t_li">小吃套餐</div>
                  <div class="pro_td_t_li">¥9.00</div>
                  <div class="pro_td_t_li">1</div>
                  <div class="pro_td_t_li">¥9.00</div>
                </div>
                <div class="pro pro_td_t pro_tc pro_hint">
                  <div class="pro_td_t_li">&nbsp;&nbsp;锅巴</div>
                  <div class="pro_td_t_li"></div>
                  <div class="pro_td_t_li">1</div>
                  <div class="pro_td_t_li"></div>
                </div>
                <div class="pro pro_td_t pro_tc pro_hint border-b" style="padding-bottom: 4px">
                  <div class="pro_td_t_li">&nbsp;&nbsp;红茶</div>
                  <div class="pro_td_t_li"></div>
                  <div class="pro_td_t_li">1</div>
                  <div class="pro_td_t_li"></div>
                </div>
                <div class="border-b">
                  <div class="totalmoney_l">现金：<span style="margin-left: 190px">¥8.00</span></div><br/>
                  <div class="totalmoney_l" style="margin-top:-32px">会员卡(a00001 张三)<span style="margin-left: 100px">¥7.00</span></div><br/>
                  <div class="totalmoney_l" style="margin-top:-32px">&nbsp;&nbsp;(储:¥2.00&nbsp;&nbsp;折:¥5.00)</div>
                </div>
                <div class="totalmoney">
                  <div class="totalmoney_l">优惠金额：¥0.00</div>
                  <div class="totalmoney_r">账单金额：¥15.00</div>
                </div>
                <div class="totalmoney" style="margin-top:-20px">
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
              <div class="headline">售出日报表格式:</div>
              <div class="content">
                <div class="guest_info" style="border:none;">
                  <div class="guest_info_l">营业日期：2023/02/07</div>
                </div>
                <div class="guest_info" style="border:none;margin-top:-10px">
                  <div class="guest_info_l">收银员：系统管理员</div>
                </div>
                <div class="guest_info" style="margin-top:-10px">
                  <div class="guest_info_l">统计规则：全部分类；全部出品库；全部订单</div>
                </div>
                <div class="pro_th pro_th_t border-b p-t-1 p-b-1">
                  <div class="pro_th_t_li">商品名称</div>
                  <div class="pro_th_t_li"></div>
                  <div class="pro_th_t_li"></div>
                  <div class="pro_th_t_li">售出数量</div>
                </div>
                <div class="pro pro_td_t pro_tc pro_hint m-t-2">
                  <div class="pro_td_t_li">轩尼诗VSOP</div>
                  <div class="pro_td_t_li"></div>
                  <div class="pro_td_t_li"></div>
                  <div class="pro_td_t_li bold">10</div>
                </div>
                <div class="pro pro_td_t pro_tc pro_hint">
                  <div class="pro_td_t_li">水果拼盘</div>
                  <div class="pro_td_t_li"></div>
                  <div class="pro_td_t_li"></div>
                  <div class="pro_td_t_li bold">20</div>
                </div>
                <div class="pro pro_td_t pro_tc pro_hint">
                  <div class="pro_td_t_li">花生</div>
                  <div class="pro_td_t_li"></div>
                  <div class="pro_td_t_li"></div>
                  <div class="pro_td_t_li bold">50</div>
                </div>
                <div class="pro pro_td_t pro_tc pro_hint border-b">
                  <div class="pro_td_t_li p-b-2">锅巴</div>
                  <div class="pro_td_t_li"></div>
                  <div class="pro_td_t_li"></div>
                  <div class="pro_td_t_li p-b-2 bold">12</div>
                </div>
                <div class="order_time m-t-3">
                  <div class="order_time_li">打印时间：2023-02-07 21:50:20</div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <span slot="footer" class="dialog-footer">
          <el-button @click="PagingPreview = false">关闭</el-button>
        </span>
      </el-dialog>
    </div>
  </div>
</template>
<script>
export default {
  name: "",
  props: {},
  data() {
    return {
      orderCount: 1, // 下单消费单打印份数
      orderPayedCount: 1, // 结账结算单打印份数
      clearCardCount: 1, // 清台结算打印份数
      backOrderCount: 1, // 退单小票(出品库)打印份数
      backOrderMoneyCount: 1, // 退单小票(收银)打印份数
      PagingPreview: false //小票预览
    };
  },
  mounted() {
    this.getConfig();
  },
  methods: {
    // 获取小票配置
    async getConfig() {
      try {
        const res = await this.$api.BMS.bill.requestBillGet();
        if (res.code == 1) {
          this.orderCount = res.data.ord_csm_ddj_cnt;
          this.orderPayedCount = res.data.sel_sel_syt_cnt;
          this.backOrderCount = res.data.back_mklib_cnt;
          this.backOrderMoneyCount = res.data.back_syt_cnt;
          this.clearCardCount = res.data.clean_stl_cnt;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("小票配置获取失败", error);
      }
    },
    // 保存编辑内容
    async saveConfig() {
      const params = {
        ord_csm_ddj_cnt: this.orderCount * 1, // int    下单消费单,点单机,打印份数, 0表示不自动打印
        sel_sel_syt_cnt: this.orderPayedCount * 1, // int    结账结算单,收银台,打印份数, 0表示不自动打印
        back_mklib_cnt: this.backOrderCount * 1, // int    退单,出品库,打印份数(如果是已出品的), 0 表示不自动打印
        back_syt_cnt: this.backOrderMoneyCount * 1, // int    退单,收银台,打印份数(如果是已出品的), 0 表示不自动打印
        clean_stl_cnt: this.clearCardCount * 1  // int 清台,咨客台(会配置到收银打印机),收银台,打印结算单份数
      };
      try {
        const res = await this.$api.BMS.bill.requestBillSave(params);
        res.code == 1
          ? this.$message.success("保存成功")
          : this.$message.warning(res.msg);
      } catch (error) {
        console.log("保存小票配置失败", error);
      }
    }
  },
  watch: {},
  components: {}
};
</script>
<style>
/* 靠右 */
.bill .el-dialog {
  margin: 0px 0px 0px auto !important;
  background-color: #f9f9f9;
  height: 100%;
  position: relative;
}

.bill .el-dialog__footer {
  position: absolute;
  width: 100%;
  bottom: 0;
  right: 0;
  display: flex;
  justify-content: center;
}

.bill .el-dialog__body {
  padding: 0px 0px 30px 20px;
  overflow-y: scroll !important;
  /* width: 100%; */
  width: calc(100% - 40px);
  height: calc(100% - 160px);
  max-height: calc(100% - 160px);
  margin: 0;
}

.bill .el-dialog {
  border-left: 1px solid #f9f9f9;
  box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1);
}

.bill {
  width: calc(100% - 40px);
  height: calc(100% - 40px);
  padding: 20px 30px;
}

.bill .compatibil {
  margin-bottom: 20px;
}

.bill .compatibility {
  display: flex;
  align-items: center;
  margin-bottom: 10px;
  height: 34px;
}

.bill .required {
  width: 60px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.bill .el-dialog .el-button--default {
  background-color: #ccc;
  border: 1px solid #ccc;
  color: #40404e;
}

.bill .el-dialog {
  background-color: #f9f9f9;
}

.bill .el-input__inner {
  background-color: rgba(0, 0, 0, 0);
  color: #40404e;
}

.bill .el-dialog__header,
.bill .el-dialog__footer {
  background-color: #22232b;
}

.bill .el-dialog__title,
.bill .el-dialog__headerbtn .el-dialog__close,
.bill .el-form-item__label {
  color: #1a1a21;
}

.bill .el-form-item {
  display: flex;
  margin: 0;
}

.bill .dialogPrinter .el-form-item__content {
  display: flex;
  margin: 0;
}

.bill table thead tr th,
.bill table tbody tr td {
  height: 40px;
  font-size: 14px;
}

.bill .el-checkbox__input {
  background-color: rgba(0, 0, 0, 0);
}

.bill .printer .el-dialog {
  width: 30vw;
}

.bill .has-gutter {
  border: 1px solid #f5f5f5;
}

.bill .el-input-number__decrease,
.bill .el-input-number__increase {
  background-color: rgba(0, 0, 0, 0);
}

.bill .el-radio__label {
  color: #40404e;
}

/* 必填 */
.bill .mandatory {
  color: #40404e;
  width: 250px;
  text-align: right;
}

.bill .reqfieldsd {
  font-size: 14px;
  padding-right: 4px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.bill .controlling {
  color: #40404e;
  width: 350px !important;
  display: flex;
  align-items: center;
}

/* 输入框禁用颜色 */
.el-input.is-disabled .el-input__inner {
  background-color: rgba(255, 255, 255, 0.075);
}

/* 单选框框文字颜色 */
.el-radio {
  color: #40404e;
}

.bill .layouts {
  margin-left: 100px;
  font-size: 12px;
  /* margin-bottom: 5px; */
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.save {
  width: 150px;
  margin-left: 100px;
  margin-top: 25px;
}

.bill .preview {
  display: flex;
  color: #ce4153;
  cursor: pointer;
}

.bill .Taketogenerate {
  margin-top: 2px;
}

.bill .Taketogenerate span {
  display: block;
  padding: 0;
  line-height: 20px;
}

/* 单选框改变颜色 */
.bill .el-radio__inner {
  background-color: transparent !important;
}

.bill .el-radio__input.is-checked .el-radio__inner {
  background-color: #2a5de9 !important;
}

.bill .el-radio__inner::after {
  background-color: #e5e5e5 !important;
}

/* 下拉框 */
.bill .el-select-dropdown__wrap {
  background-color: #f5f5f5;
}

.bill .el-select-dropdown__empty {
  background-color: #f5f5f5;
  color: #40404e;
}

.bill .el-select-dropdown__item.selected {
  background-color: #e5e5e5;
}

.bill .el-select__popper.el-popper[role="tooltip"] {
  border: 1px solid #f5f5f5;
}

.bill
  .el-select__popper.el-popper[role="tooltip"][data-popper-placement^="bottom"]
  .el-popper__arrow::before {
  border: 1px solid #f5f5f5;
  background-color: #f5f5f5;
}

.bill .el-select-dropdown__item.hover,
.el-select-dropdown__item:hover {
  background-color: #e5e5e5;
}

.bill .el-select-dropdown__item.selected {
  color: #40404e;
}

.bill .el-select-dropdown__item {
  color: #40404e;
}

.bill .el-select-dropdown {
  border: 1px solid #f5f5f5;
}

.bill .preview {
  color: #409eff;
  font-size: 14px;
  margin-left: 45px;
  display: inline-block;
}

.bill .Pagingss .el-dialog {
  margin-top: 6vh;
  margin-bottom: 0;
  width: 50vw !important;
  min-width: 800px !important;
  max-width: 800px !important;
}

.bill .Pagingss .el-dialog__body {
  padding: 10px 20px;
}

.bill .Pagingss .el-dialog__footer {
  padding-bottom: 10px;
}

.bill .Pagingss .el-dialog__header {
  padding-top: 10px;
}

.bill .Pagingll {
  display: flex;
}

.bill .Pagingll_left,
.bill .Pagingll_right {
  /* color: #40404e; */
  color: #000;
  display: flex;
  width: 50%;
  flex-direction: column;
  align-items: center;
}

.bill .NoPaging {
  font-size: 14px;
  margin: 10px;
  width: 100%;
  display: block;
}

.bill .headline {
  color: #40404e;
  text-align: left;
  margin-bottom: 10px;
  font-size: 22px;
  font-weight: bold;
}

.bill .content {
  width: 350px;
  border: 1px solid #40404e;
  padding: 20px;
  margin-bottom: 20px;
  background-color: #fff;
  box-sizing: border-box;
}

.bill .bill_info,
.bill .guest_info,
.bill .pro_th,
.bill .pro,
.bill .totalmoney,
.bill .reason {
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
}

.bill .bill_info_l {
  font-size: 16px;
  line-height: 20px;
  font-weight: 700;
}

.bill .bill_info_r {
  font-size: 14px;
  line-height: 20px;
  font-weight: 700;
}

.bill .guest_info {
  margin-top: 10px;
  border-bottom: 1px dashed #000;
}

.bill .guest_info_l,
.bill .guest_info_r {
  font-size: 14px;
  line-height: 30px;
  font-weight: 400;
}

.bill .pro_th_o_li,
.bill .pro_td_o_li {
  font-size: 14px;
  line-height: 25px;
  font-weight: 400;
}

.bill .pro_th_t_li,
.bill .pro_td_t_li {
  font-size: 14px;
  line-height: 25px;
  font-weight: 400;
  /*text-align: center;*/
}

.bill .pro {
  padding: 10px 0;
}

.bill .pro .fs17 {
  font-size: 17px;
}

.bill .pro_tc {
  border-bottom: none;
  padding: 2px 0;
}

.bill .border-b {
  border-bottom: 1px dashed #000;
}

.bill .pro_td_o_li {
  line-height: 20px;
  max-width: 70%;
  word-wrap: break-word;
}

.bill .pro_td_o_li.w200 {
  width: 150px;
  text-align: right;
}

.bill .pro_td_o_li.bold {
  font-weight: 600;
  font-size: 20px;
}

.bill .totalmoney_l,
.bill .totalmoney_r {
  font-size: 14px;
  line-height: 40px;
  font-weight: 400;
}

.bill .totalmoney_tui_l {
  font-size: 14px;
  line-height: 30px;
  font-weight: 400;
  margin-top: 5px;
}

.bill .reason_l,
.bill .reason_r {
  font-size: 14px;
  line-height: 30px;
  font-weight: 400;
}

.bill .order_time {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}

.bill .order_time_li {
  font-size: 14px;
  line-height: 20px;
  font-weight: 400;
}

.bill .bold {
  font-weight: bold;
}

.bill .pro_h {
  border-bottom: none;
  padding-bottom: 0;
}

.bill .bot_no {
  border-bottom: none;
}

.bill .pro_th_t,
.bill .pro_td_t {
  width: 100%;
}

.pro_th_t_li:nth-child(1),
.pro_td_t_li:nth-child(1) {
  width: 60%;
  max-width: 60%;
}

.pro_th_t_li:nth-child(2),
.pro_td_t_li:nth-child(2) {
  width: 12%;
  max-width: 12%;
}

.pro_th_t_li:nth-child(3),
.pro_td_t_li:nth-child(3) {
  width: 12%;
  max-width: 12%;
  text-align: right;
}
.pro_th_t_li:nth-child(4),
.pro_td_t_li:nth-child(4) {
  width: 20%;
  max-width: 20%;
  text-align: right;
}

.bill .pro_hint {
  padding: 0px;
}

.bill .pro_hint .pro_td_t_li {
  border-bottom: none;
  font-weight: 400;
  font-size: 12px;
  line-height: 20px;
}

.bill .pro_hint .pro_td_t_li.bold{
  font-weight: bold;
  font-size: 20px;
}

.bill .shop_info {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.bill .shop_info_name {
  font-size: 18px;
  font-weight: bold;
  line-height: 25px;
}

.bill .guest_info_x {
  margin-top: 0;
}
</style>

<style>
.el-select-dropdown__list {
  background: #f5f5f5;
}
</style>