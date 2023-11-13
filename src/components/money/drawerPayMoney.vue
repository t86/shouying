<template>
  <!-- 未支付订单付款页面drawer -->
  <div class="drawer-pay">
    <el-drawer
      title="收款"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="88%"
    >
      <div class="content" layout="row" layout-align="center center">
        <!-- 选择支付方式 -->
        <div class="left">
          <ul ref="scrollDom">
            <div ref="scrollDomItem">
              <li
                :class="{ active: payActiveInfo.id == item.id }"
                v-for="(item, i) in payList"
                :key="i"
                @click="payActiveInfo = item"
              >
                {{ item.name }}
              </li>
            </div>
          </ul>
          <div class="arrow" layout="row" layout-align="space-around center">
            <img
              class="arrow-top"
              @click.stop="scrollHandle('up')"
              :src="imgSrc.arrowBottom"
            />
            <img
              class="arrow-bottom"
              @click.stop="scrollHandle('down')"
              :src="imgSrc.arrowBottom"
            />
          </div>
        </div>
        <!-- 输入金额 -->
        <div class="center">
          <div class="center-top" layout="row" layout-align="center center">
            <div
              class="center-top-left"
              layout="row"
              layout-align="start center"
            >
              <p>未收:</p>
              <p class="red">￥{{ notPayAmt }}</p>
            </div>
          </div>

          <!-- 会员卡落单 -->
          <div class="vip-com" v-if="payActiveInfo.id == 5">
            <div class="form-item">
              <span>会员卡卡号:</span>
              <input
                ref="vipNumRef"
                :class="{ active: vipInfo.activeInput == 1 }"
                @focus="vipInfo.activeInput = 1"
                @input="inputHandle"
                v-model="vipInfo.vipNum"
                placeholder="请输入会员卡卡号"
              />
              <i
                class="el-icon-circle-close"
                :style="{ visibility: vipInfo.vipNum ? 'visible' : 'hidden' }"
                style="
                  color: rgba(255, 255, 255, 0.3);
                  transform: translateX(-30px);
                  cursor: pointer;
                "
                @click="vipInfo.vipNum = ''"
              ></i>
            </div>
            <div class="form-item">
              <span>卡储值金额:</span>
              <input
                :class="{ active: vipInfo.activeInput == 2 }"
                @focus="vipInfo.activeInput = 2"
                @input="inputHandle"
                v-model="vipInfo.payAmt"
                placeholder="请输入卡储值金额"
              />
              <i
                class="el-icon-circle-close"
                :style="{ visibility: vipInfo.payAmt ? 'visible' : 'hidden' }"
                style="
                  color: rgba(255, 255, 255, 0.3);
                  transform: translateX(-30px);
                  cursor: pointer;
                "
                @click="vipInfo.payAmt = ''"
              ></i>
            </div>
            <div class="form-item">
              <span>卡折扣金额:</span>
              <input
                :class="{ active: vipInfo.activeInput == 3 }"
                @focus="vipInfo.activeInput = 3"
                @input="inputHandle"
                v-model="vipInfo.paySubAmt"
                placeholder="请输入卡折扣金额"
              />
              <i
                class="el-icon-circle-close"
                :style="{
                  visibility: vipInfo.paySubAmt ? 'visible' : 'hidden',
                }"
                style="
                  color: rgba(255, 255, 255, 0.3);
                  transform: translateX(-30px);
                  cursor: pointer;
                "
                @click="vipInfo.paySubAmt = ''"
              ></i>
            </div>
          </div>

          <!-- 会员卡 -->
          <div class="vip-pay vip-com" v-else-if="payActiveInfo.id == 500">
            <div
              class="form-item"
              layout="row"
              layout-align="space-around center"
              style="padding: 0 15%"
            >
              <span style="color: #ff2f64">会员卡刷卡</span>
              <span
                style="width: 130px; color: #4b89ff; cursor: pointer"
                @click="showOrHideChooseVipCardDrawer(1)"
                >服务码选择会员卡</span
              >
              <span
                style="width: 130px; color: #4b89ff; cursor: pointer"
                @click="showOrHideChooseVipCardDrawer(2)"
                >手机号选择会员卡</span
              >
            </div>
            <div class="form-item" v-if="!vipPayInfo.show">
              <span>请刷会员卡</span>
            </div>
            <div class="form-item" v-if="vipPayInfo.show">
              <span>会员卡卡号:</span>
              <span class="value"
                >{{ vipPayInfo.cardNo
                }}{{ vipPayInfo.name ? "(" + vipPayInfo.name + ")" : "" }}</span
              >
            </div>
            <div class="form-item" v-if="vipPayInfo.show">
              <span>卡余额:</span>
              <span class="value"
                >￥{{
                  `${vipPayInfo.totalAmt} (储：￥${vipPayInfo.pb}; 赠：￥${vipPayInfo.fb})`
                }}</span
              >
            </div>
            <div class="form-item" v-if="vipPayInfo.show">
              <span
                >卡可用余额
                <el-tooltip
                  style="width: 12px; height: 12px"
                  content="卡可用金额：本次订单可使用当前会员卡的支付的金额；由于某些商品不允许使用会员卡储值金额、赠送金额或不能用会员卡支付，所以可能导致卡余额大于订单金额但卡可用余额小于订单金额"
                  effect="dark"
                  placement="top"
                  class="tooltip"
                >
                  <img src="@/assets/img/help.png" /> </el-tooltip
                >:</span
              >
              <span class="value"
                >￥{{
                  `${vipPayInfo.availableAmt} (储：￥${vipPayInfo.pv}; 赠：￥${vipPayInfo.fv})`
                }}</span
              >
            </div>

            <div class="form-item">
              <span>本次使用金额:</span>
              <span
                class="count value"
                layout="row"
                layout-align="start center"
                style="position: relative"
              >
                <input
                  class="count m-l-1"
                  ref="moneyCountRef"
                  v-model="count"
                  style="
                    width: calc(100% - 50px);
                    height: 100%;
                    border: none;
                    transform: translateY(-8px);
                  "
                  placeholder="请输入金额"
                />
                <i
                  class="el-icon-circle-close"
                  :style="{ visibility: count ? 'visible' : 'hidden' }"
                  style="
                    position: absolute;
                    right: -26px;
                    top: 10px;
                    color: rgba(255, 255, 255, 0.3);
                    transform: translateX(-30px);
                    cursor: pointer;
                  "
                  @click="count = ''"
                ></i>
              </span>
            </div>
          </div>

          <!-- 滞留金 -->
          <div v-else-if="payActiveInfo.id == 9999" class="center-center m-t-3">
            <div
              class="form-item"
              layout="row"
              layout-align="start center"
              style="padding: 0 15%; flex-wrap: wrap"
            >
              <div
                class="item m-t-2 m-l-2 fs14 p-2 cursor"
                style="width: 150px; border: 1px solid #999; border-radius: 8px"
                @click="addBookItemToShoppingCartHandle(item)"
                v-show="!hasChoosedListArr.find((items) => items.id == item.id)"
                v-for="item in bookAmtList"
                :key="item.id"
              >
                <div class="title" style="text-align: center">
                  {{ item.n.split("|")[0] }}
                </div>
                <div class="time m-t-1" style="text-align: center">
                  {{ item.n.split("|")[1] }}
                </div>
              </div>
            </div>
          </div>

          <!-- 挂账 -->
          <div v-else-if="payActiveInfo.id == 6" class="center-center m-t-3">
            <div v-if="isOrderGZ" style="margin: 5px 0px;" layout="row" layout-align="center center">
              <el-radio v-model="GZInfo.selectInfo.gzValue" label="1"
                >指定账号挂账</el-radio
              >
              <el-radio v-model="GZInfo.selectInfo.gzValue" label="2"
                >订位人挂账</el-radio
              >
            </div>
            <p layout="row" layout-align="start center">
              <span>挂账账户: </span>
              <span v-if="isOrderGZ && GZInfo.selectInfo.gzValue === '2'">{{ GZInfo.selectInfo.orderVal }}</span>
              <!-- <mySelect
                style="width: 210px"
                :value="GZInfo.selectInfo.selectVal"
                :optionsList="GZInfo.selectInfo.selectOption"
                @selectOptionItem="setSelectValHandle"
                @selectBlurHandle="selectBlurHandle"
                @getOption="getOptionHandle"
              /> -->
              <el-select v-else
              v-model="GZInfo.selectInfo.selectVal"
              placeholder="请选择或输入账号"
              style="width: 210px"
              filterable
              allow-create
              default-first-option
            >
              <el-option
                v-for="item in this.GZInfo.originOption"
                :key="item.id"
                :label="item.name"
                :value="item.id"
              >
              </el-option>
            </el-select>
            </p>
            <p class="m-t-3 fs14 color-red" layout="row" layout-align="center center">
              输入不存在的挂账账户系统将自动创建该挂账账户
            </p>
            <p class="m-t-3" layout="row" layout-align="start center">
              <span>{{ payActiveInfo.name }}金额:</span>
              <span class="count" layout="row" style="position: relative">
                ￥<input
                  class="count m-l-1"
                  ref="moneyCountRef"
                  v-model="count"
                  style="
                    width: 140px;
                    height: 100%;
                    border: none;
                    transform: translateY(-2px);
                  "
                  placeholder="请输入金额"
                />
                <i
                  class="el-icon-circle-close"
                  :style="{ visibility: count ? 'visible' : 'hidden' }"
                  style="
                    position: absolute;
                    right: -26px;
                    top: 10px;
                    color: rgba(255, 255, 255, 0.3);
                    transform: translateX(-30px);
                    cursor: pointer;
                  "
                  @click="count = ''"
                ></i>
              </span>
            </p>
          </div>

          <div v-else class="center-center m-t-8">
            <p layout="row" layout-align="start center">
              <span>{{ payActiveInfo.name }}金额:</span>
              <span class="count" layout="row" style="position: relative">
                ￥<input
                  class="count m-l-1"
                  ref="moneyCountRef"
                  v-model="count"
                  style="
                    width: calc(100% - 30px);
                    height: 100%;
                    border: none;
                    transform: translateY(-2px);
                  "
                  placeholder="请输入金额"
                />
                <i
                  class="el-icon-circle-close"
                  :style="{ visibility: count ? 'visible' : 'hidden' }"
                  style="
                    position: absolute;
                    right: -26px;
                    top: 10px;
                    color: rgba(255, 255, 255, 0.3);
                    transform: translateX(-30px);
                    cursor: pointer;
                  "
                  @click="count = ''"
                ></i>
              </span>
            </p>
            <p
              v-if="count - allAmt + chooseAmt * 1 > 0"
              class="m-t-2"
              layout="row"
              layout-align="start center"
            >
              <span>找零:</span>
              <span>￥{{ (count - allAmt + chooseAmt * 1).toFixed(2) }}</span>
            </p>
          </div>
          <div
            v-if="payActiveInfo.id != 9999"
            class="center-bottom"
            layout="row"
            layout-align="center center"
          >
            <ul>
              <li @click.stop="count = 100">￥100</li>
              <li @click.stop="count = 300">￥300</li>
              <li @click.stop="count = 500">￥500</li>
              <li @click.stop="count = 800">￥800</li>
            </ul>
            <keyBoard class="m-t-6" needPoint="true" @changeNum="changeNum" />
          </div>
        </div>
        <!-- 支付方式列表集合 -->
        <div class="right">
          <div class="right-top">
            <p>
              <span>本次应收:</span>
              <span class="amt all-amt">￥{{ allAmt }}</span>
            </p>
            <p>
              <span>已收:</span>
              <span class="amt">￥{{ chooseAmt }}</span>
            </p>
          </div>
          <div class="right-bottom">
            <ul>
              <li
                v-for="(item, i) in hasChoosedListArr"
                :key="i"
                layout="row"
                layout-align="space-between center"
              >
                <div class="pay-detail">
                  <!-- 会员卡 -->
                  <p v-if="item.pid == 500">
                    {{ "卡号：" + item.n + " " + item.c }}:
                  </p>
                  <!-- 非会员卡 -->
                  <p v-else>
                    {{ item.cn }}{{ item.l == 1 ? "(" + item.lt + ")" : "" }}:
                  </p>
                  <!-- 会员卡落单/会员卡 -->
                  <div v-if="item.pid == 5">
                    <p
                      class="amt"
                      layout="row"
                      layout-align="start center"
                      style="font-size: 13px"
                    >
                      <span style="width: 76px">卡金额:</span>￥{{
                        (item.pa * 1).toFixed(2)
                      }}
                    </p>
                    <p
                      class="amt"
                      layout="row"
                      layout-align="start center"
                      style="font-size: 13px"
                    >
                      <span style="width: 76px">卡储值金额:</span>￥{{
                        (item.pv * 1).toFixed(2)
                      }}
                    </p>
                    <p
                      class="amt"
                      layout="row"
                      layout-align="start center"
                      style="font-size: 13px"
                    >
                      <span style="width: 76px">卡折扣金额:</span>￥{{
                        (item.pf * 1).toFixed(2)
                      }}
                    </p>
                  </div>
                  <!-- 会员卡 -->
                  <div v-else-if="item.pid == 500">
                    <p
                      class="amt"
                      layout="row"
                      layout-align="start center"
                      style="font-size: 13px"
                    >
                      <span style="width: 76px">金额:</span>￥{{
                        (item.pa * 1).toFixed(2)
                      }}
                    </p>
                    <p
                      class="amt text-wrap"
                      layout-align="start center"
                      style="font-size: 13px"
                    >
                      <span>{{ `(储: ￥${(item.pv * 1).toFixed(2)}; ` }}</span>
                      <span>{{ `赠: ￥${(item.pf * 1).toFixed(2)})` }}</span>
                    </p>
                    <p
                      class="amt"
                      layout="row"
                      layout-align="start center"
                      style="font-size: 13px"
                    >
                      <span style="width: 76px">赠送积分:</span
                      >{{ !isNaN(item.p) ? `￥${item.p}` : item.p }}
                    </p>
                  </div>
                  <p v-else class="amt">￥{{ item.chooseAmt }}</p>
                </div>
                <div class="close">
                  <i
                    class="el-icon-error"
                    @click.stop="delPayList(item.id)"
                  ></i>
                </div>
              </li>
            </ul>
          </div>
        </div>
      </div>

      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="start center">
        <div class="btn-left" layout="row" layout-align="end center">
          <el-button
            class="m-r-6"
            type="info"
            @click="addChooseList"
            v-if="payActiveInfo.id != 9999"
            >{{ payActiveInfo.auth_type == 1 ? "授权" : "确认" }}</el-button
          >
        </div>
        <div class="btn-right" layout="row" layout-align="end center">
          <el-button class="m-r-6" type="danger" @click="onClose"
            >退出</el-button
          >
          <el-button class="m-r-6" type="primary" @click="onSubmit"
            >收款</el-button
          >
        </div>
      </div>

      <authComponent
        ref="authComponent"
        :amt="
          this.count - this.allAmt > 0
            ? this.allAmt.toString()
            : this.count.toString()
        "
        :showDrawer="showAuthDrawer"
        @getChoosePayList="getChoosePayList"
        @showOrHideDrawer="showOrHideAuthDrawer"
      />
      <drawerChooseVipCard
        :showDrawer="showChooseVipCardDrawer"
        :maxPayMoney="notPayAmt"
        :allAmt="allAmt"
        :type="chooseVipCardType"
        @nextHandle="getChoosePayList"
        @showOrHideDrawer="showOrHideChooseVipCardDrawer"
      />
    </el-drawer>
  </div>
</template>

<script>
import md5 from "js-md5";
import api_money from "@/api/money";

import common_money from "@/utils/common/money";

import drawerChooseVipCard from "./drawerChooseVipCard.vue";
import keyBoard from "@/components/common/keyBoard";
import authComponent from "@/components/money/drawerPayMoneyAuth";
import mySelect from "@/components/book/select";

import arrowBottom from "@/assets/card-imgs/arrow-bottom.png";
export default {
  data() {
    return {
      isOrderGZ: false, // 是否订位人挂账
      flag: false, // 点击付款按钮的节流阀
      show: false,
      showAuthDrawer: false, // 显示授权
      chooseVipCardType: 1, // 1：二维码  2：手机号
      showChooseVipCardDrawer: false, // 显示选择会员卡
      payList: [],
      payActiveInfo: {},
      count: "", // 金额
      bookAmtList: [], // 滞留金列表
      vipInfo: {
        activeInput: 1, // 1: 会员卡号  2：卡金额  3：折扣卡金额
        vipNum: "",
        payAmt: "",
        paySubAmt: "",
      },
      // 会员卡刷卡
      vipPayInfo: {
        id: "", // 会员卡id
        cardNo: "", // 会员卡号
        totalAmt: "0", // 卡余额
        availableAmt: "0", // 卡可用余额
        pb: "0", // 有价余额
        fb: "0", // 无价余额
        pv: "0", // 有价可用余额
        fv: "0", // 无价可用余额
        authCode: "", // 认证扣款字符串
        name: "", // 会员卡名称
        show: false, //
      },
      // 挂账
      GZInfo: {
        originOption: [],
        selectInfo: {
          gzValue: "1",
          selectVal: "",
          selectOption: [],
          orderVal: ""
        },
      },
      hasChoosedListArr: [], // 选择好支付方式的列表（购物车）
      imgSrc: {
        arrowBottom,
      },
    };
  },
  methods: {
    // 会员卡支付粘贴
    inputHandle() {
      const splitStr = "tab";
      const numList = [
        this.vipInfo.vipNum,
        this.vipInfo.payAmt,
        this.vipInfo.paySubAmt,
      ];
      const isCopy = numList.find((item) => item.toString().includes(splitStr));
      if (isCopy) {
        const resultArr = isCopy.split(splitStr);
        this.vipInfo.vipNum = resultArr[0] || 0;
        this.vipInfo.payAmt = resultArr[1] || 0;
        this.vipInfo.paySubAmt = resultArr[2] || 0;
      }
    },
    async init() {
      this.show = this.showDrawer;

      // 判断是否有滞留金
      const bookAmtList = (await this.getBookAmtList()) || [];
      // 注：id<200为线下支付方式  >=200为线上支付方式
      let allPayList = this.$store.state.cardPageInfo.resResultDataObj[
        "payList"
      ].filter((item) => item.status == 1 && (item.id < 200 || item.id == 500));
      // 滞留金信息
      let bookPayInfo = {};
      if (bookAmtList.length > 0) {
        // 有滞留金
        bookPayInfo = {
          id: 9999, // 渠道id
          name: "滞留金", //  渠道名称
          pay_type: 2, // 支付类型: 1 联动渠道 2 不联动渠道(只落单)
          auth_type: 2, // 授权类型: 1 需要授权 2 不需要授权
          value_type: 2, // 价值类型: 1 全有价 2 全免费 3 混合
          status: 1, // 状态: 1有效 3 删除
          dsp: -1, // 显示顺序（排在第一个）
        };
      }

      // 门店设置的渠道
      const effectPayList = this.$store.state.cardPageInfo.resResultDataObj[
        "payListFilter"
      ].filter((item) => item.status == 1);

      const canConfigPayList = allPayList.filter((item) => item.id < 100);
      const canNotConfigPayList = allPayList.filter((item) => item.id >= 100); // 自适应（暂时不需要配置到支付渠道中）
      const vipPayList = allPayList.filter((item) => item.id == 500); // 会员卡

      let payList = [];
      if (effectPayList.length > 0) {
        // 门店有配置
        payList = canConfigPayList.filter((item) =>
          effectPayList.map((items) => items.id).includes(item.id)
        );
      } else {
        payList = [...canConfigPayList];
      }
      // 线下支付订单
      this.payList = bookPayInfo.id
        ? [{ ...bookPayInfo }, ...payList, ...vipPayList].sort(
            (a, b) => a.dsp - b.dsp
          )
        : [...payList, ...vipPayList].sort((a, b) => a.dsp - b.dsp);
      this.payActiveInfo = this.payList.length > 0 ? this.payList[0] : {};
    },
    // 获取已选择好的支付渠道（购物车）
    async getChoosePayList() {
      try {
        const res = await api_money.reqGetCardPayList({
          id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, // int64   卡台Id
        });
        if (res.code === 1) {
          const hasChoosedListArr = res.data || [];
          hasChoosedListArr.forEach((el) => {
            el.chooseAmt = (el.pa * 1).toFixed(2);
            el.choosedPayInfo = common_money.getPayInfo(el.pid);
          });
          this.hasChoosedListArr = hasChoosedListArr;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("支付渠道获取失败", error);
      }
    },

    // 添加滞留金到购物车渠道列表
    async addBookItemToShoppingCartHandle(itemInfo) {
      if (this.notPayAmt * 1 < itemInfo.a * 1)
        return this.$message.warning(
          "未支付金额" +
            this.notPayAmt +
            "元，不能使用大于该金额的滞留金，可添加其他待结商品或扣减其他结账渠道"
        );
      const params = {
        id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //  int64   卡台Id
        late_id: itemInfo.id * 1, // int64    滞留金渠道订单Id
      };
      try {
        const res = await api_money.reqAddBookAmtToShopping(params);
        if (res.code == 1) {
          this.$message.success("加入成功");
          this.getChoosePayList();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("数据请求失败", error);
      }
    },

    async selfAuth() {
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64   卡台Id
        pay_cnl_id: 10, // int     支付渠道Id, 目前只支持抹零, =10
        pay_amt:
          this.count - this.allAmt + this.chooseAmt * 1 > 0
            ? ((this.allAmt * 100 - this.chooseAmt * 100) / 100).toString()
            : this.count.toString(), //    string   支付金额
        auth_emp_code: "", // string   授权人工号
        auth_emp_passwd: "", // string   授权人密码
        pass_type: 1, // 1:账号密码， 2：刷卡
      };

      try {
        const res = await api_money.reqAddShoppingFromZero(params);
        if (res.code === 1) {
          this.$message.success("加入成功");
          this.getChoosePayList();
        } else if (res.code == 2) {
          this.$refs.moneyCountRef.blur();
          window.loopReadCard();
          this.showOrHideAuthDrawer();
          return;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        window.loopReadCard();
        console.log("人工授权加入购物车失败", error);
      }
    },

    // 加入已选择好的支付渠道列表
    async addChooseList() {
      if (!this.count && this.payActiveInfo.id != 5)
        return this.$message.warning("请输入金额");
      if (this.payActiveInfo.auth_type == 1) {
        // 抹零授权（先自己授权）
        return this.selfAuth();
      }
      if (this.payActiveInfo.id == 500) {
        // 添加会员卡渠道
        return this.addVipInfo();
      }
      try {
        let params = {
          id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //         int64   卡台Id
          pay_cnl_id: this.payActiveInfo.id * 1, // int   支付渠道Id
          pay_amt:
            this.count - this.allAmt + this.chooseAmt * 1 > 0
              ? ((this.allAmt * 100 - this.chooseAmt * 100) / 100).toString()
              : this.count.toString(), //    string   支付金额
          biz_id: 0, //  int64   当渠道为 预付金抵扣(202) 的时候,传预付金账户Id; 当渠道为 挂账账户 的时候,传挂账账户Id, 其他情况下传0
        };
        // 会员卡落单
        if (this.payActiveInfo.id == 5) {
          params = {
            ...params,
            pay_amt: (
              this.vipInfo.payAmt * 1 +
              this.vipInfo.paySubAmt * 1
            ).toFixed(2),
            card_no: this.vipInfo.vipNum.trim(), //    string     //CardNo 会员卡落单,卡号
            card_value_amt: this.vipInfo.payAmt.trim(), // string     //CardValueAmt 会员卡储值金额
            card_free_amt: this.vipInfo.paySubAmt.trim() || "0", // string     //CardFreeAmt 会员卡折扣金额
          };

          if (params.card_no === "")
            return this.$message.warning("请输入会员卡号");
          if (params.card_value_amt === "")
            return this.$message.warning("请输入卡金额");
        }

        // 挂账
        if (this.payActiveInfo.id == 6) {
          if (!this.GZInfo.selectInfo.selectVal && !this.GZInfo.selectInfo.orderVal)
            return this.$message.warning("请选择挂账账户");
            
          let bizItem = this.GZInfo.originOption.find((item) => item.name == this.GZInfo.selectInfo.selectVal)
          params = {
            ...params,
            biz_id: this.isOrderGZ ? 0 : bizItem ? bizItem.id * 1 : 0,
            card_no: this.isOrderGZ ?  this.GZInfo.selectInfo.orderVal : bizItem ? '' : this.GZInfo.selectInfo.selectVal
          };
        }

        const res = await api_money.reqAddPayListToShopping(params);
        if (res.code === 1) {
          this.$message.success("加入成功");
          this.vipPayInfo = {
            id: "", // 会员卡id
            cardNo: "", // 会员卡号
            totalAmt: "0", // 卡余额
            pv: "0", // 有价余额
            fv: "0", // 无价余额
            authCode: "", // 认证扣款字符串
            name: "",
            show: false,
          };
          this.getChoosePayList();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("加入选择好的支付渠道失败", error);
      }
    },

    // 删除已选择好的支付渠道
    async delPayList(id) {
      try {
        const res = await api_money.reqDelPayListFromShopping({
          seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, // int64   卡台Id
          id: id * 1, //         int64      //Id 支付Id
        });
        if (res.code === 1) {
          this.$message.success("删除成功");
          this.getChoosePayList();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("删除已选择好的支付渠道失败", error);
      }
    },

    changeNum(value) {
      let count = 0;
      // 会员卡落单
      if (this.payActiveInfo.id == 5) {
        if (this.vipInfo.activeInput == 1) {
          count = this.vipInfo.vipNum;
        }
        switch (this.vipInfo.activeInput) {
          case 1:
            count = this.vipInfo.vipNum;
            break;
          case 2:
            count = this.vipInfo.payAmt;
            break;
          case 3:
            count = this.vipInfo.paySubAmt;
            break;
        }
      } else {
        count = this.count;
      }
      switch (value) {
        case 10: // 小数点
          if (this.count.toString().indexOf(".") > -1) return;
          count = count.toString() + ".";
          break;
        case 12: // 回退
          count = count.toString().slice(0, count.toString().length - 1);
          break;
        default:
          const pointIndex = count.toString().indexOf(".");
          if (pointIndex > -1 && count.toString().length > pointIndex + 2)
            return;
          count = count.toString() + value;
          break;
      }
      if (this.payActiveInfo.id == 5) {
        switch (this.vipInfo.activeInput) {
          case 1:
            this.vipInfo.vipNum = count;
            break;
          case 2:
            this.vipInfo.payAmt = count;
            break;
          case 3:
            this.vipInfo.paySubAmt = count;
            break;
        }
      } else {
        this.count = count == "00" ? 0 : count;
      }
    },
    // 关闭
    onClose() {
      this.closeDrawerHandle();
    },
    // 结账
    async onSubmit() {
      // 处理待结账订单中退单（如果当前订单全部已经退单，传入退单订单的parentOrderId并去重，并且退单数量为0；如果没有退完，则只需要传入主订单id(待结账id)，数量为待结账数量）
      // 此处需要兼容线上已全部退款订单，如果线上支付订单已全部退款，则可结算，如果未全部退款
      const wk_order_ids = [];
      const prd_cnts = [];
      this.choosePayOrderList.forEach((el) => {
        if (el.oid) {
          // 线上支付商品，但是已经全部对款
          el.resultNotPayData &&
            el.resultNotPayData.forEach((ele) => {
              if (wk_order_ids.indexOf(ele.parentOrderId * 1) == -1) {
                // 过滤掉重复的主订单id（一个主订单id对应的商品可以退款不同数量多次）
                wk_order_ids.push(ele.parentOrderId * 1);
                prd_cnts.push(0);
              }
            });
        } else {
          // 线下支付商品
          if (el.back) {
            if (wk_order_ids.indexOf(el.parentOrderId * 1) == -1) {
              wk_order_ids.push(el.parentOrderId * 1);
              prd_cnts.push(0);
            }
          } else {
            wk_order_ids.push(el.id * 1);
            prd_cnts.push(el.changeCount * 1);
          }
        }
      });
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64     卡台Id
        wk_order_ids, // []int64    待结账订单Id组
        prd_cnts, // []int  对应待结算订单的商品数量
        total_amt: this.allAmt.toString(), //  string   总待结算金额(当前勾选的商品总金额),做二次验证用
      };
      if (this.flag) return this.$message.warning("付款中，请稍后...");
      this.flag = true;
      try {
        const res = await api_money.reqPayOrder(params);
        if (res.code === 1) {
          this.$message.success("支付成功");
          this.closeDrawerHandle();
          this.$parent.getOrderInfo(this.$parent.getPayTabList, true);
          // this.$router.replace('/moneyCard');
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("支付失败", error);
      }
      setTimeout(() => {
        this.flag = false;
      }, 1000);
    },

    // 箭头滚动
    scrollHandle(type) {
      const scrollDom = this.$refs.scrollDom;
      const scrollDomItem = this.$refs.scrollDomItem;
      if (!scrollDom || !scrollDomItem) return;
      const clientHeight = scrollDom.getBoundingClientRect().height;
      const maxHeight = scrollDomItem.getBoundingClientRect().height;
      if (clientHeight >= maxHeight) return; // 未能撑满可视区域，无需滚动
      let scrollTop = scrollDom.scrollTop;
      switch (type) {
        case "up":
          scrollTop = Math.min(maxHeight, scrollTop - 200);
          scrollDom.scrollTo(0, scrollTop);
          break;
        case "down":
          scrollTop = Math.max(0, scrollTop + 200);
          scrollDom.scrollTo(0, scrollTop);
          break;
      }
    },

    closeDrawerHandle() {
      this.$emit("showOrHideDrawer", false);
    },

    onCancelDrawer() {
      this.closeDrawerHandle();
    },
    // 显示或隐藏authDrawer
    showOrHideAuthDrawer() {
      this.showAuthDrawer = !this.showAuthDrawer;
    },

    showOrHideChooseVipCardDrawer(type) {
      this.showChooseVipCardDrawer = !this.showChooseVipCardDrawer;

      if (type && typeof type === "number" && this.showChooseVipCardDrawer) {
        this.chooseVipCardType = type;
      }

      if (!this.showChooseVipCardDrawer) {
        this.chooseVipCardType = "";
        this.getChoosePayList();
      }
    },

    /**
     * 读卡相关
     */
    // 读卡
    readCard() {
      let cardNo = "";
      try {
        setTimeout(() => {
          cardNo = atool.getCardNo();
          if (!cardNo) {
            if (
              this.show &&
              this.payActiveInfo.id == 500 &&
              !this.showChooseVipCardDrawer
            )
              this.readCard();
          } else {
            this.getCardPwd(cardNo);
          }
        }, 1000);
      } catch (error) {
        console.log("cardNo信息获取失败：", error);
      }
    },

    async getCardPwd(cardNo) {
      const params = {
        card_no: cardNo, //  string  卡号,这里是指实体卡卡号
      };
      try {
        const res = await api_money.reqGetVipCardPwd(params);
        if (res.code == 1) {
          this.getCardData(cardNo, res.data.p);
        } else {
          this.readCard();
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取卡密失败", error);
      }
    },

    // 通过查询返回的卡密码,读取卡内容数据
    getCardData(cardNo = "", password = "") {
      let cardInfoText = "";
      try {
        cardInfoText = atool.getCardData(password); // 参数为密码
        if (cardInfoText.length == 0) {
          this.readCard();
          return this.$message.warning(
            "卡验证失败,请确认卡未离开读卡位置或是有效卡"
          );
        }
        this.getVipInfo(cardNo, cardInfoText);
      } catch (error) {
        console.log("读取卡内容数据失败：", error);
        this.$message.warning("读取卡内容数据失败：" + error);
      }
    },

    // 获取会员卡信息
    async getVipInfo(cardNo, cardInfoText) {
      const params = {
        card_no: cardNo, //    string   卡号,这里是指实体卡卡号
        dt: md5(cardInfoText).toString().toUpperCase(), //     string    卡验证数据
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, // 卡台
      };

      try {
        const res = await api_money.reqGetVipCardInfo(params);
        if (res.code == 1) {
          this.vipPayInfo = {
            id: res.data.id, // 会员卡id
            cardNo: res.data.card_no, // 会员卡号
            fv: res.data.usable_free_amt, //
            pv: res.data.usable_val_amt,
            fb: res.data.free_balance,
            pb: res.data.val_balance,
            totalAmt: res.data.val_balance * 1 + res.data.free_balance * 1, // 卡余额
            availableAmt:
              res.data.usable_free_amt * 1 + res.data.usable_val_amt * 1, // 卡可用余额
            authCode: res.data.auth_code || "", // 认证扣款字符串
            authCodeStr: res.data.auth_code || "", // 认证扣款字符串
            name: res.data.name,
            show: true, //
          };
        } else {
          this.readCard();
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("刷卡获取卡信息失败", error);
      }
    },

    // 添加会员卡渠道
    async addVipInfo() {
      const param = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1,
        auth_type: 1,
        auth_code: this.vipPayInfo.authCodeStr,
        mb_card_id: this.vipPayInfo.id,
        amt: this.count.toString(),
      };
      const res = await api_money.reqUpdateVipCardIntoBillChannel(param);
      if (res.code == 1) {
        this.$message.success("加入成功");
        this.getChoosePayList();
      } else {
        this.$message.warning(res.msg);
      }
    },

    // 获取滞留金列表
    async getBookAmtList() {
      // 判断是否为空台（翻台后可以查看消费记录）
      if (this.$store.state.orderInfo.currentCardInfo.bizStatus == 1) return;
      const params = {
        id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //  int64  卡台Id
      };
      try {
        const res = await api_money.reqGetBookAmtList(params);
        if (res.code == 1) {
          this.bookAmtList = res.data.records || [];
          return this.bookAmtList;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取滞留金列表失败", error);
      }
    },

    /*
    筛选下拉框相关 start
    */
    setSelectValHandle(info) {
      this.GZInfo.selectInfo.selectVal = info.name;
    },
    selectBlurHandle() {
      this.GZInfo.selectInfo.selectOption = [];
    },
    getOptionHandle() {
      this.GZInfo.selectInfo.selectOption = JSON.parse(
        JSON.stringify(this.GZInfo.originOption)
      );
    },
  },
  mounted() {
    this.init();
  },
  props: {
    showDrawer: {
      default: false, // 是否显示drawer
    },
    choosePayOrderList: {
      // 选择好的即将要支付的订单
      default: () => [],
    },
  },
  computed: {
    // 未收金额 / 分成金额
    allAmt() {
      let allAmt = 0;
      this.choosePayOrderList.forEach((el) => {
        if (
          !el.oid &&
          el.at != 2 &&
          el.at != 3 &&
          el.at != 5 &&
          el.at != 6 &&
          !el.back
        ) {
          allAmt += el.pp == 0 ? el.pa * 1 : el.changeCount * el.pp;
        }
      });
      return allAmt.toFixed(2);
    },
    // 已收金额
    chooseAmt() {
      let chooseAmt = 0;
      this.hasChoosedListArr.forEach((el) => {
        chooseAmt += el.chooseAmt * 1;
      });
      return chooseAmt.toFixed(2);
    },
    notPayAmt() {
      return (this.allAmt - this.chooseAmt).toFixed(2);
    },
  },
  components: {
    keyBoard,
    authComponent,
    drawerChooseVipCard,
    mySelect,
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      this.showAuth = false;

      if (newVal){
          this.isOrderGZ = this.$store.state.orderInfo.currentCardInfo.salesEmpId != '0'
          if(this.isOrderGZ) {
            let employee = this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo.find(item => item.id == this.$store.state.orderInfo.currentCardInfo.salesEmpId)
            this.GZInfo.selectInfo.orderVal = '订位-' + (employee ? employee.name : this.$store.state.orderInfo.currentCardInfo.salesEmpId)
          }
          setTimeout(() => {
            this.count = (this.allAmt - this.chooseAmt).toFixed(2) * 1;
            this.$refs.moneyCountRef && this.$refs.moneyCountRef.focus();
            this.init();
          }, 200);

        this.getChoosePayList();
      }
    },
    notPayAmt() {
      this.count = (this.allAmt - this.chooseAmt).toFixed(2) * 1;
    },
    showChooseVipCardDrawer(newVal) {
      if (!newVal && this.payActiveInfo.id == 500) {
        this.readCard();
      }
    },
    payActiveInfo: {
      handler(newVal) {
        if (this.show)
          this.$nextTick(() => {
            this.$refs.moneyCountRef && this.$refs.moneyCountRef.focus();
            this.$refs.vipNumRef && this.$refs.vipNumRef.focus();
          });

        if (newVal.id == 500) {
          // 会员卡刷卡
          this.readCard();
        } else {
          this.vipPayInfo = {
            id: "", // 会员卡id
            cardNo: "", // 会员卡号
            totalAmt: "0", // 卡余额
            pv: "0", // 有价余额
            fv: "0", // 无价余额
            authCode: "", // 认证扣款字符串
            name: "",
            show: false,
          };
        }

        if (newVal.id == 9999) {
          // 滞留金
          this.getBookAmtList();
        }

        if (newVal.id == 6) {
          // 挂账
          this.GZInfo.selectInfo.selectVal = "";
          this.GZInfo.originOption =
            this.$store.state.cardPageInfo.resResultDataObj.accountOfGZ.filter(
              (item) => item.status == 1
            );
        }
      },
      deep: true,
    },
  },
};
</script>

<style scoped lang="less">
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/money/drawerPayMoney.less";
@import "../../style/common/scrollBar.less";
</style>
