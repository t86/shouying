<template>
  <div>
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      :size="size"
    >
      <el-form
        @submit.native.prevent
        v-if="showType == 'form'"
        label-position="right"
        label-width="150px"
        :model="formData"
        ref="drawerRef"
      >

      <el-form-item label="卡台名称">
        <span class="white">{{ cardInfo.name }}</span>
      </el-form-item>

        <!-- 订位人预约信息 -->
        <div v-if="formData.sales.sales_status_arr.indexOf(formStatus) > -1">
          <el-form-item label="订位人">
            <input-select
              v-if="show"
              :autoFocus="true"
              style="width: 80%"
              :value="formData.sales.sales_name"
              placeholder="请输入姓名或工号"
              :optionsList="formData.sales.sales_info_option"
              @selectInputHandle="inputSealName"
              @selectOptionItem="changeSealName"
              @selectBlurHandle="selectBlurHandle"
            ></input-select>
          </el-form-item>
          <el-form-item label="订位人电话">
            <el-input
              v-model="formData.sales.sales_phone"
              disabled
              style="width: 80%; background-color: rgba(0,0,0,0.2)"
            ></el-input>
          </el-form-item>
        </div>
        <!-- 卡台标记 -->
        <el-form-item
          v-if="formData.mark_status_arr.indexOf(formStatus) > -1"
          label="卡台标记"
        >
          <form-select
            :value="formData.markInfo.value"
            style="width: 80%"
            placeholder="请选择卡台标记"
            :optionsList="formData.markInfo.option"
            @selectOptionItem="changeTips"
            @selectBlurHandle="selectBlurHandle"
            @getOption="getMarkOption"
          />
          <i
            v-if="formData.markInfo.value"
            @click="formData.markInfo.value = ''"
            class="el-icon-circle-close"
            style="
              position: absolute;
              right: 23%;
              top: 14px;
              color: rgba(255, 255, 255, 0.15);
              cursor: pointer;
            "
          ></i>
        </el-form-item>

        <el-form-item
          v-if="
            formData.customArriveInfo.custom_arrive_status_arr.indexOf(
              formStatus
            ) > -1 &&
            ((formStatus == 2 && cardInfo.bizStatus == 3) ||
              formStatus == 1 ||
              formStatus == 8)
          "
          class="required required6"
          label="预定到达时间"
        >
          <form-select
            :value="formData.customArriveInfo.exp_arrive_time"
            style="width: 80%"
            placeholder="请选择预定到达时间"
            :optionsList="formData.customArriveInfo.exp_arrive_time_option"
            @selectOptionItem="changeTime"
            @selectBlurHandle="selectBlurHandle"
            @getOption="getArrivedTimeOption"
          />
        </el-form-item>

        <div
          v-if="formData.customPay.consumer_status_arr.indexOf(formStatus) > -1"
        >
          <div
            v-if="
              showMinAmtOpenTypeArr.indexOf(formData.openType.open_type) > -1
            "
          >
            <el-form-item label="预期最低消费">
              <el-input
                v-model="formData.customPay.exp_min_csm_amt"
                type="number"
                style="width: 80%"
                min="0"
                placeholder="请输入预期最低消费"
              >
              </el-input>
              <span class="m-l-1 white">元</span>
            </el-form-item>
            <!-- 预定开台时显示卡台最低消费 -->
            <el-form-item
              v-if="formStatus == 2 && cardInfo.bizStatus == 3"
              label="卡台最低消费"
            >
              <el-input
                v-model="formData.customPay.card_min_csm_amt"
                disabled
                type="number"
                style="width: 80%"
              >
              </el-input>
              <span class="m-l-1 white">元</span>
            </el-form-item>
          </div>
          <el-form-item label="预期预定人数">
            <el-input
              v-model="formData.customPay.customer_exp_cnt"
              type="number"
              min="0"
              maxlength="100"
              style="width: 80%"
              placeholder="请输入预期预定人数"
              @input="inputCardCountHandle"
            ></el-input>
          </el-form-item>
        </div>

        <!-- 开台类型 -->
        <div
          v-if="formData.openType.open_type_status_arr.indexOf(formStatus) > -1"
        >
          <div v-if="formStatus == 13">
            <el-form-item
              label="最低消费"
              v-if="
                showMinAmtOpenTypeArr.indexOf(formData.openType.open_type) > -1
              "
              class="required required4"
            >
              <el-input
                v-model="formData.lowConsume.min_csm_amt"
                type="number"
                min="0"
                style="width: 80%"
                placeholder="请输入最低消费"
              >
              </el-input>
              <span class="m-l-1 white">元</span>
            </el-form-item>
            <el-form-item label="修改理由" class="required required4">
              <el-input
                type="textarea"
                :rows="2"
                placeholder="请输入理由"
                v-model="formData.openType.reason"
                style="width: 80%"
              >
              </el-input>
            </el-form-item>
          </div>
        </div>

        <!-- 客人信息 -->
        <div
          v-if="
            formData.customInfo.consumer_info_status_arr.indexOf(formStatus) >
            -1
          "
        >
          <el-form-item label="客人电话">
            <input-select
              style="width: 80%"
              :value="formData.customInfo.customer_phone"
              placeholder="请输入客人电话"
              :optionsList="formData.customInfo.custom_info_option"
              @selectInputHandle="inputCustomPhone"
              @selectOptionItem="changeCustomPhone"
              @selectBlurHandle="selectBlurHandle"
            ></input-select>
          </el-form-item>
          <el-form-item label="客人姓名">
            <el-input
              v-model="formData.customInfo.customer_name"
              style="width: 80%"
              placeholder="请输入客人姓名"
            ></el-input>
          </el-form-item>
          <!-- 预定时需要发短信选择 -->
          <el-form-item label="是否发送短信" v-if="formStatus == 1">
            <el-radio v-model="formData.customInfo.auto_send_msg" label="2"
              >否</el-radio
            >
            <el-radio v-model="formData.customInfo.auto_send_msg" label="1"
              >是</el-radio
            >
          </el-form-item>
        </div>

        <!-- 联合订位人 -->
        <div
          v-if="
            formData.secondSales.second_sales_status_arr.indexOf(formStatus) >
            -1
          "
        >
          <el-form-item label="联合订位人">
            <input-select
              style="width: 80%"
              :value="formData.secondSales.second_sales_name"
              placeholder="请输入联合订位人姓名或工号"
              :optionsList="formData.secondSales.second_sales_info_option"
              @selectInputHandle="inputSecondSealName"
              @selectOptionItem="changeSecondSealName"
              @selectBlurHandle="selectBlurHandle"
            ></input-select>
          </el-form-item>
          <el-form-item label="联合订位人电话">
            <el-input
              v-model="formData.secondSales.second_sales_phone"
              disabled
              style="width: 80%; background-color: rgba(0,0,0,0.8)"
            ></el-input>
          </el-form-item>
        </div>

        <div v-if="formData.waiter.waiter_status_arr.indexOf(formStatus) >-1">
          <el-form-item label="服务员">
            <input-select
                :autoFocus="false"
                style="width: 80%"
                :value="formData.waiter.waiter_name"
                placeholder="请输入姓名或工号"
                :optionsList="formData.waiter.waiters"
                @selectInputHandle="inputWaiter"
                @selectOptionItem="changeWaiter"
                @selectBlurHandle="selectWaiterBlurHandle"
            ></input-select>
          </el-form-item>
        </div>

        <!-- 修改低消金额 -->
        <div
          v-if="
            formData.lowConsume.low_consume_status_arr.indexOf(formStatus) > -1
          "
        >
          <el-form-item label="最低消费" class="required required4">
            <el-input
              v-model="formData.lowConsume.min_csm_amt"
              placeholder="请输入最低消费"
              type="number"
              min="0"
              style="width: 80%"
            >
            </el-input>
            <span class="m-l-1 white">元</span>
          </el-form-item>
        </div>

        <!-- 备注 -->
        <el-form-item
          v-if="formData.remarkInfo.remark_status_arr.indexOf(formStatus) > -1"
          label="备注"
        >
          <el-input
            type="textarea"
            :rows="2"
            placeholder="请输入备注"
            v-model="formData.remarkInfo.remark"
            style="width: 80%"
          >
          </el-input>
        </el-form-item>

        <!-- 转台 -->
        <div
          class="change-card"
          v-if="
            formData.changeCard.change_card_status_arr.indexOf(formStatus) > -1
          "
        >
          <div class="change-card-info m-b-4">
            <span>{{ formData.changeCard.originCardName }}</span>
            <span>转</span>
            <span>{{ formData.changeCard.newCardName }}</span>
            <el-button type="primary" @click.stop="secondChangeCard"
              >更改台位</el-button
            >
          </div>
          <el-form-item label="老卡台低消" class="required required5">
            <el-input
              v-model="formData.changeCard.originAmt"
              disabled
              type="number"
              style="width: 80%"
            ></el-input>
            <span class="m-l-1 white">元</span>
          </el-form-item>
          <el-form-item label="新卡台低消" class="required required5">
            <el-input
              v-model="formData.changeCard.new_min_csm_amt"
              min="0"
              placeholder="请输入新卡台低消"
              type="number"
              style="width: 80%"
            ></el-input>
            <span class="m-l-1 white">元</span>
          </el-form-item>
        </div>

        <!-- 查看卡台详情 -->
        <div class="m-l-10 p-l-10" v-if="formStatus == 14">
          <el-form-item label="转台信息:">
            <span class="white">{{ cardDetailInfo.chgSeatInfo }}</span>
          </el-form-item>
          <el-form-item label="订位人:">
            <span class="white">{{ cardDetailInfo.saleName }}</span>
          </el-form-item>
          <el-form-item label="订位人联系方式:">
            <span class="white">{{ cardDetailInfo.salePhone }}</span>
          </el-form-item>
          <el-form-item label="预订到达时间:">
            <span class="white">{{ cardDetailInfo.arriveTime }}</span>
          </el-form-item>
          <el-form-item label="最低消费:">
            <span class="white">{{ cardDetailInfo.minAmt }}</span>
          </el-form-item>
          <el-form-item label="预订人数:">
            <span class="white">{{ cardDetailInfo.personNum }}</span>
          </el-form-item>
          <el-form-item label="客人姓名:">
            <span class="white">{{ cardDetailInfo.customName }}</span>
          </el-form-item>
          <el-form-item label="客人电话:">
            <span class="white">{{ cardDetailInfo.customPhone }}</span>
          </el-form-item>
          <el-form-item label="联合订位人:">
            <span class="white">{{ cardDetailInfo.secondSaleName }}</span>
          </el-form-item>
          <el-form-item label="联合订位人联系方式:">
            <span class="white">{{ cardDetailInfo.secondSalePhone }}</span>
          </el-form-item>
          <el-form-item label="备注：">
            <span class="white">{{ cardDetailInfo.remark }}</span>
          </el-form-item>
        </div>

        <!-- 提交按钮 -->
        <div class="form-btn">
          <el-button type="info" @click="onCancelDrawer">{{
            formStatus == 14 ? "关闭" : "取消"
          }}</el-button>
          <el-button type="primary" v-if="formStatus != 14" @click="onSubmit"
            >确认</el-button
          >
        </div>
      </el-form>
      <cardInfoTable
        v-if="showType == 'table'"
        :formStatus="formStatus"
        :cardInfo="cardInfo"
        :show="show"
        @closeDrawerHandle="closeDrawerHandle"
      ></cardInfoTable>
    </el-drawer>
  </div>
</template>

<script>
import cardInfoTable from "@/components/book/machine/cardInfoTable";
import inputSelect from "@/components/book/inputSelect";
import formSelect from "@/components/book/select";
import { cardOptions, openTypeList } from "@/utils/config/card";
import common_book from "@/utils/common/book";
import personSearch from "@/utils/personSearch";
import api_card from "@/api/Book";
import api_order from "@/api/order";

const drawerWidth = "60%";
const drawerBigWidth = "80%";

export default {
  data() {
    return {
      oldSalesEmpId: '',
      show: false, // 是否显示drawer
      showMinAmtOpenTypeArr: [1, 5, 6], // 显示最低消费输入框的openType列表

      // 查看卡台详情
      cardDetailInfo: {
        saleName: "",
        salePhone: "",
        arriveTime: "",
        minAmt: "",
        personNum: "",
        customName: "",
        customPhone: "",
        secondSaleName: "",
        secondSalePhone: "",
        remark: "",
      },

      formData: {
        /*
            订位人信息
          */
        sales: {
          sales_name: "", // 订位人名称
          sales_emp_id: "", // 订位人id
          sales_phone: "", // 订位人电话
          sales_info_option: [], // 订位人下拉框选项
          sales_status_arr: [1, 2, 8, 11], // 订位人在form表单中出现的formStatus集合
        },

        /*
            客人预定时间
          */
        customArriveInfo: {
          exp_arrive_time: "", // 预定到达时间
          exp_arrive_time_id: "", // 预定到达id
          exp_arrive_time_option: [], // 预定到达时间下拉选项
          custom_arrive_status_arr: [1, 2, 8],
        },

        /*
            卡台标记
           */
        markInfo: {
          value: "", // 卡台标记所选值
          option: [],
        },
        mark_status_arr: [1, 2, 8, 20],

        /*
            开台类型
          */
        openType: {
          open_type: 1, // 开台类型
          open_type_list: openTypeList, // 开台类型列表
          reason: "", // 修改开台类型的理由
          open_type_status_arr: [2, 13],
        },

        /*
            客人消费情况
          */
        customPay: {
          exp_min_csm_amt: "", // 预期最低消费
          card_min_csm_amt: "", // 预定开台时卡台固定的最低消费(不可修改状态)

          customer_exp_cnt: "", // 预定人数
          consumer_status_arr: [1, 2, 8], // 消费情况状态在formStatus中的集合
        },

        /*
            客人信息
          */
        customInfo: {
          customer_name: "", // 客人名称
          customer_phone: "", // 客人电话
          auto_send_msg: "2", // 是否发送短信
          custom_info_option: [],
          consumer_info_status_arr: [1, 2, 8],
        },

        /*
            联合订位人信息
          */
        secondSales: {
          second_sales_phone: "", // 联合订位人电话
          second_sales_name: "", // 联合订位人名称
          second_sales_emp_id: "", // 联合订位人id
          second_sales_info_option: [], // 联合订位人下拉选项
          second_sales_status_arr: [1, 2, 8, 11],
        },
        waiter : {
          waiter_name: "",
          waiter_emp_id: "",
          waiters : [],
          waiter_status_arr: [2, 23],
        },

        /*
            卡台低消数据
          */
        lowConsume: {
          min_csm_amt: 0, // 卡台抵消金额
          low_consume_status_arr: [10],
        },

        /**
         * 转台信息
         */
        changeCard: {
          originAmt: "", // 原卡台低消
          originCardName: "", // 原卡台名称
          new_min_csm_amt: "", // 新卡台低消
          newCardName: "", // 新卡台名称
          change_card_status_arr: [7],
        },

        remarkInfo: {
          remark: "", // 备注
          remark_status_arr: [1, 2, 8, 21],
        },
      },
    };
  },
  methods: {
    // 计算一天1200到次日1130的所有时间段（30分钟间隔）
    getOneDayTimeOption() {
      let H = 12;
      let M = 0;
      const resultOption = [];
      let dayName = "";
      for (let i = 0; i < 48; i++) {
        resultOption.push({
          id: H.toString().padStart(2, 0) + M.toString().padStart(2, 0),
          name:
            dayName +
            H.toString().padStart(2, 0) +
            ":" +
            M.toString().padStart(2, 0),
        });
        M += 30;
        if (M >= 60) {
          H++;
          M = 0;
        }
        if (H === 24) {
          dayName = "次日";
          H = 0;
        }
      }
      return resultOption;
    },
    // 计算未来一天的时间段（30分钟间隔）
    getArrivedTimeOption() {
      const date = new Date();
      let H = date.getHours();
      let M = date.getMinutes();
      if (H < 12) {
        H = 12;
        M = 0;
      }
      let dayName = "";
      const resultOption = [];
      M = M === 0 ? 0 : Math.max(M, 30);
      if (M > 30 && M <= 59) {
        H += 1;
        M = 0;
      }
      for (let i = 0; i < 48; i++) {
        if (M >= 60) {
          M = 0;
          H += 1;
          if (H >= 24) {
            dayName = "次日";
            H = 0;
          }
        }
        if (!(dayName === "次日" && H >= 12))
          resultOption.push({
            id: H.toString().padStart(2, 0) + M.toString().padStart(2, 0),
            name:
              dayName +
              H.toString().padStart(2, 0) +
              ":" +
              M.toString().padStart(2, 0),
          });
        M += 30;
      }
      this.formData.sales.sales_info_option = [];
      this.formData.customInfo.custom_info_option = [];
      this.formData.secondSales.second_sales_info_option = [];
      this.formData.customArriveInfo.exp_arrive_time_option = resultOption;
    },

    getMarkOption() {
      const markList =
        this.$store.state.cardPageInfo.resResultDataObj.tipsList || [];
      this.formData.markInfo.option = [{ name: "请选择", id: 0 }, ...markList];
    },

    /*
     *订位人
     */
    // 获取模糊查询订位人的相关信息
    inputSealName(query) {
      this.formData.sales.sales_name = query;
      this.formData.sales.sales_phone = "";
      this.formData.sales.sales_emp_id = "";
      const sealInfoArr =
        this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo;
      this.formData.sales.sales_info_option =
        personSearch.getActivePersonOptions(sealInfoArr, query);
    },
    // 选择订位人的信息
    changeSealName(info) {
      this.formData.sales.sales_name = info.name;
      this.formData.sales.sales_phone = info.phoneNum;
      this.formData.sales.sales_emp_id = info.id;
      this.formData.sales.sales_info_option = [];
    },

    /**
     * 预计到达时间
     */
    changeTime(info) {
      this.formData.customArriveInfo.exp_arrive_time = info.name;
      this.formData.customArriveInfo.exp_arrive_time_id = info.id;
      this.formData.customArriveInfo.exp_arrive_time_option = [];
    },

    /**
     * 卡台标记
     */
    changeTips(info) {
      this.formData.markInfo.value = info.id == 0 ? "" : info.name;
      this.formData.markInfo.option = [];
    },

    /*
     * 预定人数
     */
    inputCardCountHandle(e) {
      if (e > 100) this.$message.warning("卡台最大可容纳人数为100");
      this.formData.customPay.customer_exp_cnt =
        e > 100 ? (e.startsWith("100") ? e.slice(0, 3) : e.slice(0, 2)) : e;
    },

    /**
     * 客人
     */
    // 模糊查询常客电话
    async inputCustomPhone(query) {
      this.formData.customInfo.customer_phone = query;
      if (query.length < 5) return;
      try {
        const params = {
          page_num: 1, //  int 第几页
          page_size: 1000, // int  每页行数
          phone: query, // string  常客手机关键字, 输入至少5位后再模糊
        };
        const res = await api_card.reqGetCustomPhone(params);
        const options = res.code === 1 && res.data ? res.data : [];
        options.forEach((el) => {
          el.name = el.p;
          el.code = el.n;
        });
        this.formData.customInfo.custom_info_option = options;
        this.$forceUpdate();
      } catch (error) {
        console.log("常客信息获取失败", error);
      }
    },

    // 选择客人的信息
    changeCustomPhone(info) {
      this.formData.customInfo.customer_phone = info.p;
      this.formData.customInfo.customer_name = info.n;
      this.formData.customInfo.custom_info_option = [];
    },

    /*
     * 联合订位人
     */
    // 获取模糊查询订位人的相关信息
    inputSecondSealName(query) {
      this.formData.secondSales.second_sales_name = query;
      this.formData.secondSales.second_sales_phone = "";
      this.formData.secondSales.second_sales_emp_id = "";
      const secondSealInfoArr =
        this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo;
      this.formData.secondSales.second_sales_info_option =
        personSearch.getActivePersonOptions(secondSealInfoArr, query, {
          excludeIds: [this.formData.sales.sales_emp_id],
        });
    },
    // 选择订位人的信息
    changeSecondSealName(info) {
      this.formData.secondSales.second_sales_name = info.name;
      this.formData.secondSales.second_sales_phone = info.phoneNum;
      this.formData.secondSales.second_sales_emp_id = info.id;
      this.formData.secondSales.second_sales_info_option = [];
    },

    selectBlurHandle() {
      this.formData.sales.sales_info_option = [];
      this.formData.customInfo.custom_info_option = [];
      this.formData.secondSales.second_sales_info_option = [];
      this.formData.customArriveInfo.exp_arrive_time_option = [];
      this.formData.markInfo.option = [];
    },
    inputWaiter(query) {
      this.formData.waiter.waiter_name = query;
      this.formData.waiter.waiter_emp_id = "";
      this.formData.secondSales.second_sales_emp_id = "";
      const all = this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo
      this.formData.waiter.waiters = personSearch.getActivePersonOptions(all, query);
    },
    changeWaiter(info) {
      this.formData.waiter.waiter_name = info.name;
      this.formData.waiter.waiter_emp_id = info.id;
      this.formData.waiter.waiters = [];
    },

    selectWaiterBlurHandle() {
      this.formData.sales.sales_info_option = [];
      this.formData.customInfo.custom_info_option = [];
      this.formData.secondSales.second_sales_info_option = [];
      this.formData.customArriveInfo.exp_arrive_time_option = [];
      this.formData.markInfo.option = [];
    },

    /**
     * 转台更改台位信息
     */
    // 转台获取新卡台的相关信息
    getNewCardInfo() {
      this.formData.changeCard.new_min_csm_amt =
        this.$store.state.cardPageInfo.newCardInfo.grpMinCsmAmt; // 新卡台最基础低消
      this.formData.changeCard.newCardName =
        this.$store.state.cardPageInfo.newCardInfo.name; // 新卡台最基础低消
    },
    // 更改台位信息
    secondChangeCard() {
      this.$emit("showOrHideFullPageHandle", {
        showFullPage: true,
        showDrawer: false,
      });
    },

    /*
     * 提交
     */
    onSubmit() {
      switch (Number(this.formStatus)) {
        // case 1:  // 空台预定操作
        //   this.nullToReserve()
        //   break
        case 2: // 空台、预定开台操作
          if (this.cardInfo.bizStatus.toString() === "1") {
            this.nullToOpen();
          } else if (this.cardInfo.bizStatus.toString() === "8") {
            if (this.cardInfo.showOnlineText) {
              // 线上卡台开台
              this.showConfirmHandle(
                "确定开台",
                "线上订台" +
                  this.cardInfo.name +
                  "，开台后不能撤台，是否确认开台？",
                () => {
                  this.reserveToOpen();
                }
              );
            } else {
              // 线下卡台预定开台
              this.reserveToOpen();
            }
          } else {
            this.$message.warning(
              "当前卡台状态为非空台和非预定状态，不需要卡台"
            );
          }
          break;
        case 7: // 空台、预定转台操作
          this.reserveOrOpenToChange();
          break;
        // case 8:  // 修改预定操作
        //   this.updateReserve()
        //   break
        case 10: // 开台修改低消
          this.updateConsume();
          break;
        case 11: // 开台修改订位人和联合订位人
          this.updateOpenSales();
          break;
        case 13: // 开台修改开台类型
          this.updateOpenType();
          break;
        case 20: // 修改卡台标签
          this.updateCardTips();
          break;
        case 21:
          this.updateRemark();
          break;
        case 23:
          try {
            if (!this.formData.waiter.waiter_emp_id) {
              this.$message.warning("请选择服务员");
              return;
            }
            let params ={
              seat_id: this.cardId * 1,
              waiter_emp_id: this.formData.waiter.waiter_emp_id * 1,
              turnover_cnt: this.cardInfo.turnoverCnt * 1
            }
            console.log(params)
            api_order.reqChgCsmWaiter(params).then(res => {
              if(res.code === 1) {
                this.formResponseHandle(res, "修改服务员成功！", false);

              } else {
                this.$message.warning("修改服务员失败:" + res.msg);
              }
            })
          } catch(error) {
            this.$message.warning("修改服务员失败" + error);
          }
          break
      }
    },

    onCancelDrawer() {
      this.$emit("changeShowDrawer", false);
    },

    closeDrawerHandle() {
      this.$emit("changeShowDrawer", false);
    },

    // 获取被预定过的卡台信息
    async getReservedCardInfo() {
      const sealInfoArr =
        this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo;
      const secondSealInfoArr =
        this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo;
      try {
        if (Number(this.bookId) == 0) return;
        const res = await api_card.reqGetBookDetail({
          id: Number(this.bookId),
        });
        if (res.code === 1) {
          this.formData.sales.sales_name =
            sealInfoArr.find((el) => el.id == res.data.sales_emp_id) &&
            sealInfoArr.find((el) => el.id == res.data.sales_emp_id).name; // 订位人名称
          this.formData.sales.sales_emp_id = res.data.sales_emp_id
            ? res.data.sales_emp_id.toString()
            : ""; // 订位人id
          this.oldSalesEmpId = res.data.sales_emp_id ? res.data.sales_emp_id.toString() : ""; // 订位人id

          this.formData.sales.sales_phone =
            sealInfoArr.find((el) => el.id == res.data.sales_emp_id) &&
            sealInfoArr.find((el) => el.id == res.data.sales_emp_id).phoneNum; // 订位人电话
          this.formData.customArriveInfo.exp_arrive_time =
            this.getOneDayTimeOption().find(
              (el) => el.id == res.data.exp_arrive_time
            ) &&
            this.getOneDayTimeOption().find(
              (el) => el.id == res.data.exp_arrive_time
            ).name; // 预定到达时间
          this.formData.customArriveInfo.exp_arrive_time_id =
            res.data.exp_arrive_time || ""; // 预定到达时间id

          this.formData.customPay.exp_min_csm_amt =
            res.data.exp_min_csm_amt || ""; // 预期最低消费
          this.formData.customPay.card_min_csm_amt =
            this.cardInfo.grpMinCsmAmt || ""; // 卡台固定的最低消费(用于预约之后开台展示)
          this.formData.customPay.customer_exp_cnt =
            res.data.customer_exp_cnt || ""; // 预定人数

          this.formData.customInfo.customer_name = res.data.customer_name || ""; // 客人名称
          this.formData.customInfo.customer_phone =
            res.data.customer_phone || ""; // 客人电话
          this.formData.customInfo.auto_send_msg = "2"; // 是否发送短信

          this.formData.secondSales.second_sales_name =
            secondSealInfoArr.find(
              (el) => el.id == res.data.second_sales_emp_id
            ) &&
            secondSealInfoArr.find(
              (el) => el.id == res.data.second_sales_emp_id
            ).name; // 联合订位人名称
          this.formData.secondSales.second_sales_emp_id =
            res.data.second_sales_emp_id.toString(); // 联合订位人id
          this.formData.secondSales.second_sales_phone =
            secondSealInfoArr.find(
              (el) => el.id == res.data.second_sales_emp_id
            ) &&
            secondSealInfoArr.find(
              (el) => el.id == res.data.second_sales_emp_id
            ).phoneNum; // 联合订位人电话

          this.formData.remarkInfo.remark = res.data.remark || ""; // 备注

          this.formData.markInfo.value = res.data.mark || ""; // 卡台标签
          this.$forceUpdate();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (e) {
        console.log("被预定卡台信息获取失败", e);
      }
    },

    // 空台开台提交
    async nullToOpen() {
      if (this.isValidParams("nullOrReserveToOpenParams") !== "ok")
        return false;
      try {
        const res = await api_card.reqNullToOpenCard(
          this.nullOrReserveToOpenParams
        );
        this.formResponseHandle(res, "开台成功！", false);
      } catch {
        console.log("预定操作出错");
      }
    },

    // 预定开台提交
    async reserveToOpen() {
      if (this.isValidParams("nullOrReserveToOpenParams") !== "ok")
        return false;
      try {
        const res = await api_card.reqReserveToOpenCard(
          this.nullOrReserveToOpenParams
        );
        this.formResponseHandle(res, "开台成功！", false);
      } catch {
        console.log("预定操作出错");
      }
    },

    // 预定或开台转台
    async reserveOrOpenToChange() {
      const { new_min_csm_amt } = this.reserveOrOpenToChangeParams;
      // if (new_min_csm_amt.length <= 0) return this.$message.warning('请输入新卡台低消')
      this.reserveOrOpenToChangeParams.new_min_csm_amt = Number(
        this.reserveOrOpenToChangeParams.new_min_csm_amt
      );
      try {
        // cardInfo.bizStatus: 8:预定转台  4：开台转台
        const res =
          this.cardInfo.bizStatus == 8
            ? await api_card.reqReserveToChangeCard(
                this.reserveOrOpenToChangeParams
              )
            : await api_card.reqOpenToChange(this.reserveOrOpenToChangeParams);
        this.formResponseHandle(res, "转台成功", false);
        if (res.code === 1) {
          this.$store.commit("updateNewCardInfo", {});
          this.$sessionStorage.removeItem("newCardInfo");
        }
      } catch (error) {
        console.log("转台失败", error);
      }
    },

    // 开台后修改低消金额提交
    async updateConsume() {
      const { min_csm_amt } = this.updateConsumeParams;
      // if (min_csm_amt === '') return this.$message.warning('请输入最低消费')
      this.updateConsumeParams.min_csm_amt = Number(
        this.updateConsumeParams.min_csm_amt
      );
      try {
        const res = await api_card.reqUpdateLowConsume(
          this.updateConsumeParams
        );
        this.formResponseHandle(res, "修改低消金额操作成功！", false);
      } catch (error) {
        console.log("修改低消操作失败", error);
      }
    },

    // 开台修改开台订位人、联合订位人
    async updateOpenSales() {
      try {
        const res = await api_card.reqUpdateOpenSales(
          this.updateOpenSalesParams
        );
        this.formResponseHandle(res, "修改订位人成功！", false);
      } catch (error) {
        console.log("修改开台订位人失败", error);
      }
    },

    // 开台状态修改开台类型
    async updateOpenType() {
      if (this.updateOpenTypeParams.new_min_csm_amt.length === 0)
        return this.$message.warning("请填写最低消费");
      if (this.updateOpenTypeParams.reason.length === 0)
        return this.$message.warning("请填写修改原因");
      try {
        this.updateOpenTypeParams.new_min_csm_amt = Number(
          this.updateOpenTypeParams.new_min_csm_amt
        );
        const res = await api_card.reqUpdateOpenType(this.updateOpenTypeParams);
        this.formResponseHandle(res, "修改开台类型成功！", false);
      } catch (error) {
        console.log("修改开台类型失败！", error);
      }
    },

    async updateCardTips() {
      const params = {
        id: this.cardInfo.seatId * 1, //     int64     待操作卡台Id
        mark: this.formData.markInfo.value, //   string    卡台标记
      };
      try {
        const res = await api_card.reqUpdateCardTips(params);
        this.formResponseHandle(res, "修改卡台标签成功！", false);
      } catch (error) {
        console.log("修改卡台标记失败", error);
      }
    },

    
    async updateRemark() {
      const params = {
        id: this.cardInfo.seatId * 1, //     int64     待操作卡台Id
        remark: this.formData.remarkInfo.remark, //   string    卡台标记
      };
      try {
        const res = await api_card.reqUpdateCardRemark(params);
        this.formResponseHandle(res, "修改卡台备注成功！", false);
      } catch (error) {
        console.log("修改卡台备注失败", error);
      }
    },

    // 验证提交参数是否合法
    isValidParams(key) {
      if (this.formStatus === 1 || this.formStatus === 8) {
        // 空台预定1或修改预定信息8
        if (this[key].sales_name && !this[key].sales_emp_id)
          return this.$message.warning("请输入有效订位人");
        // if (!this[key].exp_arrive_time) return this.$message.warning('请输入预定到达时间')

        // if (this[key].exp_min_csm_amt.length === 0) return this.$message.warning('请输入预期最低消费金额')
        // this[key].exp_min_csm_amt = Number(this[key].exp_min_csm_amt)

        // if (this[key].customer_exp_cnt === '') return this.$message.warning('请输入预期到店人数')
        // if (!this[key].customer_name) return this.$message.warning('请输入客人姓名')
        if (
          this[key].customer_phone.length !== 0 &&
          this[key].customer_phone.length != 11
        )
          return this.$message.warning("请输入正确的手机号");

        if (this[key].second_sales_name && !this[key].second_sales_emp_id)
          return this.$message.warning("请输入有效联合订位人");
      } else if (this.formStatus === 2) {
        // 空台或预定开台2
        if (this[key].sales_name && !this[key].sales_emp_id)
          return this.$message.warning("请输入有效订位人");

        // if (this[key].min_csm_amt.length === 0) return this.$message.warning('请输入预期最低消费金额')
        // this[key].min_csm_amt = Number(this[key].min_csm_amt)

        // if (this[key].customer_cnt === '') return this.$message.warning('请输入预期到店人数')
        if (
          this[key].customer_phone.length !== 0 &&
          this[key].customer_phone.length != 11
        )
          return this.$message.warning("请输入正确的手机号");

        if (this[key].second_sales_name && !this[key].second_sales_emp_id)
          return this.$message.warning("请输入有效联合订位人");
      }
      return "ok";
    },

    // 重置表单
    resetForm() {
      this.formData.sales.sales_emp_id = ""; // 订位人id
      this.formData.sales.sales_name = ""; // 订位人名称
      this.formData.sales.sales_phone = ""; // 订位人电话

      this.formData.customArriveInfo.exp_arrive_time = ""; // 预定到达时间
      this.formData.customArriveInfo.exp_arrive_time_id = ""; // 预定到达时间option id

      this.formData.openType.open_type = 1; // 开台类型
      this.formData.openType.reason = ""; // 开台类型

      this.formData.customPay.exp_min_csm_amt =
        this.cardInfo.grpMinCsmAmt || ""; // 预期最低消费
      this.formData.customPay.card_min_csm_amt = ""; // 预定开台时卡台固定的最低消费(不可修改状态)
      // 预定人数：如果 capacity 为 0 或未定义，默认设置为 1
      const capacity = this.$store.state.orderInfo.currentCardInfo.capacity;
      this.formData.customPay.customer_exp_cnt = capacity && capacity > 0 ? capacity : 1; // 预定人数

      this.formData.customInfo.customer_name = ""; // 客人名称
      this.formData.customInfo.customer_phone = ""; // 客人电话
      this.formData.customInfo.auto_send_msg = "2"; // 是否发送短信

      this.formData.secondSales.second_sales_phone = ""; // 联合订位人电话
      this.formData.secondSales.second_sales_name = ""; // 联合订位人名称
      this.formData.secondSales.second_sales_emp_id = ""; // 联合订位人id

      this.formData.lowConsume.min_csm_amt = 0; // 卡台抵消金额

      this.formData.changeCard.originAmt = 0; // 转台原卡台低消
      this.formData.changeCard.new_min_csm_amt = 0; // 转台新卡台低消

      this.formData.remarkInfo.remark = ""; // 备注

      this.formData.markInfo.value = ""; // 卡台标签
      this.oldSalesEmpId = '';
    },

    formResponseHandle(res, successTips = "操作成功！", isResetForm = true) {
      if (res.code === 1) {
        this.show = false;
        this.$message.success(successTips);
        if (isResetForm) this.resetForm();
      } else {
        this.$message.warning(res.msg);
      }
    },

    // 点击操作选项后进来之后赋值
    cardInfoChange(value) {
      console.log('-----------------------------', this.formStatus)
      const newVal = value || this.cardInfo;
      switch (this.formStatus) {
        case 2: // 空台开台或预定开台   newVal.bizStatus:1 空台开台  2：预定开台
          if (newVal.bizStatus == 1) {
            // 空台开台
            this.resetForm();
            this.formData.customPay.exp_min_csm_amt = newVal.grpMinCsmAmt;
          } else {
            // 预定开台
            this.getReservedCardInfo();
          }
          this.formData.waiter = {
            waiter_name: "",
            waiter_emp_id: "",
            waiters: [],
            waiter_status_arr: [2, 23],
          }
          let waiterConfigs = this.$store.state.cardPageInfo.resResultDataObj["waiterConfig"]
          if(waiterConfigs && waiterConfigs.length > 0) {
            let currentWaiter = waiterConfigs.find(item=> item.seat_id*1 === this.cardId*1)
            if (currentWaiter) {
              let emp_id = currentWaiter.waiter_emp_id;
              this.formData.waiter.waiter_emp_id = emp_id
              const all_emps = this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo
              let finder = all_emps.find(item=>item.id * 1 === emp_id * 1)
              if(finder) {
                this.formData.waiter.waiter_name = finder.name
              }
            }
          }
          break;
        case 7: // 转台   newVal.bizStatus:  3：预定转台   4：开台转台
          this.formData.changeCard.originAmt = newVal.assignMinCsmAmt; // 老卡台被修改过的低消
          this.formData.changeCard.originCardName = newVal.name; // 老卡台名称
          break;
        case 10: // 修改低消
          this.formData.lowConsume.min_csm_amt = newVal.assignMinCsmAmt;
          break;
        case 11: // 修改订位人、联合订位人
          const { salesEmpId, secondSalesEmpId } = newVal;
          const sealInfoArr =
            this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo;
          const secondSealInfoArr =
            this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo;
          this.formData.sales.sales_name =
            sealInfoArr.find((el) => el.id == salesEmpId) &&
            sealInfoArr.find((el) => el.id == salesEmpId).name; // 订位人名称
          this.formData.sales.sales_emp_id = salesEmpId.toString(); // 订位人id
          this.formData.sales.sales_phone =
            sealInfoArr.find((el) => el.id == salesEmpId) &&
            sealInfoArr.find((el) => el.id == salesEmpId).phoneNum; // 订位人电话
          this.formData.secondSales.second_sales_name =
            secondSealInfoArr.find((el) => el.id == secondSalesEmpId) &&
            secondSealInfoArr.find((el) => el.id == secondSalesEmpId).name; // 联合订位人名称
          this.formData.secondSales.second_sales_emp_id =
            secondSalesEmpId.toString(); // 联合订位人id
          this.formData.secondSales.second_sales_phone =
            secondSealInfoArr.find((el) => el.id == secondSalesEmpId) &&
            secondSealInfoArr.find((el) => el.id == secondSalesEmpId).phoneNum; // 联合订位人电话
          break;
        case 13: // 修改开台类型
          this.formData.lowConsume.min_csm_amt = newVal.assignMinCsmAmt;
          this.formData.openType.open_type = Number(newVal.openType);
          this.formData.openType.reason = "";
          break;
        case 21:
          this.formData.remarkInfo.remark = this.cardInfo.remark;
          break
        case 23:
          this.formData.waiter.waiter_emp_id = this.cardInfo.waiter_emp_id
            console.log(this.cardInfo.waiter_emp_id)
          let p = this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo.find(item=>item.id === this.cardInfo.waiter_emp_id)
            if (p) {
              this.formData.waiter.waiter_name = p.name
            } else {
              this.formData.waiter.waiter_name = ""
            }

          break
      }
      this.$forceUpdate();
    },

    // 操作确认框
    showConfirmHandle(title = "", content = "", callback) {
      this.$confirm(content, title, {
        distinguishCancelAndClose: true,
        confirmButtonText: "确定",
        cancelButtonText: "取消",
      })
        .then(() => {
          callback && callback();
        })
        .catch((e) => "");
    },
  },
  created() {},
  mounted() {},
  props: {
    showDrawer: {
      default: false, // 是否显示drawer
    },
    formStatus: {
      required: true,
      default: 1, // 所选选项的表单状态
      // 1:预定  2：开台 3：查看卡台消费 4：修改翻台订位人 5：锁定 6：取消锁定 7：转台 8：修改预定
      // 10：修改低消  11:修改订位人  12：撤台  13：修改开台类型  14：查看卡台详情  15：取消预定
    },
    cardId: {
      default: "", // 操作卡台id
    },
    bookId: {
      default: "", // 操作卡台预定id
    },
    cardInfoIndex: {
      default: 0, // 操作卡台index索引值
    },
    cardInfo: {
      // 当前卡台所有业务信息
      default: {},
    },
  },
  computed: {
    // 是否展示form
    showType() {
      const formType = [1, 2, 7, 8, 10, 11, 13, 14, 20, 21, 23]; // 展示form表单的formStatus
      const tableType = [3, 4]; // 展示table表格的formStatus  3：查看卡台消费  4：修改翻台订位人
      if (formType.indexOf(this.formStatus) > -1) {
        this.$nextTick(() => {
         this.$refs.sealNameRef && this.$refs.sealNameRef.focus();
        })
        return "form";
      } else if (tableType.indexOf(this.formStatus) > -1) {
        return "table";
      }
    },
    size() {
      return this.showType === "form" ? drawerWidth : drawerBigWidth;
    },
    title() {
      return (
        cardOptions.find((el) => el.id === this.formStatus) &&
        cardOptions.find((el) => el.id === this.formStatus).name
      );
    },

    /*
     * 空台预定或预定修改卡台信息接口参数
     */
    nullOrUpdateToReserveParams() {
      const { formData } = this;
      return {
        seat_id: Number(this.cardId), // int64   待操作卡台Id
        customer_phone: formData.customInfo.customer_phone.toString(), // string   客户电话
        customer_name: formData.customInfo.customer_name, // string   客户名称
        auto_send_msg: Number(formData.customInfo.auto_send_msg), //  int   发送短信 1 发送 2 不发送
        exp_arrive_time: formData.customArriveInfo.exp_arrive_time_id, // string  期望到达时间 格式 hh24mi  1200至次日1130  参数对应 1200,1230,....,0000,0030,0100,....1130
        sales_emp_id: Number(formData.sales.sales_emp_id), // int64  订位人Id
        sales_name: formData.sales.sales_name, // string  订位人名称
        second_sales_emp_id: Number(formData.secondSales.second_sales_emp_id), // int64  联合订位人Id
        second_sales_name: Number(formData.secondSales.second_sales_name), // string  联合订位人名称
        customer_exp_cnt: Number(formData.customPay.customer_exp_cnt), // int64  预期到店人数
        exp_min_csm_amt:
          formData.customPay.exp_min_csm_amt === 0
            ? 0
            : formData.customPay.exp_min_csm_amt * 1, // int64  预期最低消费
        remark: formData.remarkInfo.remark, // string  备注信息
      };
    },


    /*
     * 空台或预定开台
     */
    nullOrReserveToOpenParams() {
      const { formData } = this;
      return {
        seat_id: Number(this.cardId), // int64 待操作卡台Id   用于空台开台提交
        id: Number(this.bookId), // int64 待操作卡台预定id  用于预定开台提交
        // open_type: formData.openType.open_type,  //int   开台类型 1 正常消费,2 内招, 3 外招, 4 气氛, 5 全转, 6 半转
        customer_phone: formData.customInfo.customer_phone.toString(), // string   客户电话
        customer_name: formData.customInfo.customer_name, // string  客户名称
        sales_emp_id: Number(formData.sales.sales_emp_id), // int64 订位人Id
        sales_name: formData.sales.sales_name, // string  订位人名称
        second_sales_emp_id: Number(formData.secondSales.second_sales_emp_id), // int64  联合订位人Id
        second_sales_name: Number(formData.secondSales.second_sales_name), // string  联合订位人名称
        customer_cnt: Number(formData.customPay.customer_exp_cnt), // int  到店人数
        min_csm_amt:
          this.showMinAmtOpenTypeArr.indexOf(formData.openType.open_type) > -1
            ? formData.customPay.exp_min_csm_amt === 0
              ? 0
              : formData.customPay.exp_min_csm_amt * 1
            : 0, // int 最低消费
        remark: formData.remarkInfo.remark, // string  备注信息
        mark: formData.markInfo.value, //  string   卡台标签
        old_sales_emp_id: Number(this.oldSalesEmpId), // int64 元订位人Id
        waiter_emp_id: Number(formData.waiter.waiter_emp_id),
      };
    },

    /**
     * 预定/开台转台
     */
    reserveOrOpenToChangeParams() {
      return {
        // cardInfo.bizStatus: 8:预定转台  4：开台转台
        id:
          this.cardInfo.bizStatus == 8
            ? Number(this.bookId)
            : Number(this.cardId), // int 待操作卡台Id
        dest_seat_id: Number(this.$store.state.cardPageInfo.newCardInfo.seatId), // int64  目标卡台Id
        new_min_csm_amt: this.formData.changeCard.new_min_csm_amt, // int  抵消金额(元)
      };
    },

    /*
     * 开台修改低消金额参数
     */
    updateConsumeParams() {
      const { formData } = this;
      return {
        id: Number(this.cardId), // int64 待操作卡台Id
        min_csm_amt:
          this.formData.lowConsume.min_csm_amt === 0
            ? "0"
            : this.formData.lowConsume.min_csm_amt.toString(), // int  抵消金额(元) 此处暂用string，用于判断是否为空
      };
    },

    /**
     * 开台修改订位人和联合订位人参数
     */
    updateOpenSalesParams() {
      const { formData } = this;
      return {
        id: Number(this.cardId), //    int64  待操作卡台Id
        sales_emp_id: Number(formData.sales.sales_emp_id), // int64  订位人Id
        sales_name: formData.sales.sales_name, // string  订位人名称
        second_sales_emp_id: Number(formData.secondSales.second_sales_emp_id), // int64  联合订位人Id
        second_sales_name: Number(formData.secondSales.second_sales_name), // string  联合订位人名称
      };
    },

    /**
     * 开台修改开台类型
     */
    updateOpenTypeParams() {
      const { formData } = this;
      return {
        id: Number(this.cardId), //    int64  待操作卡台Id
        open_type: formData.openType.open_type, //int   开台类型 1 正常消费,2 内招, 3 外招, 4 气氛, 5 全转, 6 半转
        new_min_csm_amt:
          this.showMinAmtOpenTypeArr.indexOf(formData.openType.open_type) > -1
            ? formData.lowConsume.min_csm_amt === 0
              ? "0"
              : formData.lowConsume.min_csm_amt.toString()
            : "0", // int  抵消金额(元)  此处暂用string，用于判断是否为空
        reason: formData.openType.reason, //     string   理由
      };
    },
  },
  watch: {
    showDrawer(newVal) {
      console.log('showDrawer', newVal, this.formStatus)
      this.show = newVal;
      if (newVal && this.formStatus == 14) {
        const saleInfo =
          common_book.getOrderPersonInfo(this.cardInfo.salesEmpId) || {};
        const secondSaleInfo =
          common_book.getOrderPersonInfo(this.cardInfo.secondSalesEmpId) || {};
        this.cardDetailInfo.saleName = saleInfo.name || "---";
        this.cardDetailInfo.salePhone = saleInfo.phoneNum || "---";
        this.cardDetailInfo.arriveTime = this.cardInfo.expArriveTime || "---";
        this.cardDetailInfo.minAmt = this.cardInfo.assignMinCsmAmt || "---";
        this.cardDetailInfo.personNum = this.cardInfo.customerCnt || "---";
        this.cardDetailInfo.customName = this.cardInfo.customerName || "---";
        this.cardDetailInfo.customPhone = this.cardInfo.customerPhone || "---";
        this.cardDetailInfo.secondSaleName = secondSaleInfo.name || "---";
        this.cardDetailInfo.secondSalePhone = secondSaleInfo.phoneNum || "---";
        this.cardDetailInfo.remark = this.cardInfo.remark || "---";
        this.cardDetailInfo.chgSeatInfo = this.cardInfo.chgSeatInfo || "---";
      } else if (newVal && this.formStatus == 20) {
        // 修改卡台标签
        this.formData.markInfo.value = this.cardInfo.mark;
      }
    },
    show(newVal) {
      this.$emit("changeShowDrawer", newVal);
    },
    // 卡台信息
    cardInfo: {
      handler(newVal) {
        this.cardInfoChange(newVal);
      },
      immediate: true,
    },
  },
  components: {
    cardInfoTable,
    inputSelect,
    formSelect,
  },
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawer.less";
@import "../../../style/book/machine/cardDrawer.less";

</style>
