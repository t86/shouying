<template>
  <div>
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="60%"
    >
      <el-form
        label-position="right"
        label-width="150px"
        :model="formData"
        ref="drawerRef"
        @submit.native.prevent
      >
        <el-form-item label="当前卡台:">
          <label style="width: 80%; color: white;">
            {{ $store.state.orderInfo.currentCardInfo.name }}
          </label>
        </el-form-item>

        <el-form-item label="多台预定">
          <div layout="row" layout-align="start center">
              <div
                v-for="item in orderedCardList"
                :key="item.id"
                class="label"
                @click="deleteCard(item)"
              >
                {{ item.name }}
              </div>
              <div
                style="color: cornflowerblue; cursor: pointer"
                @click="addCard"
              >
                添加卡台
              </div>
            </div>
        </el-form-item>

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
        <el-form-item label="是否发送短信">
          <el-radio v-model="formData.customInfo.auto_send_msg" label="2"
            >否</el-radio
          >
          <el-radio v-model="formData.customInfo.auto_send_msg" label="1"
            >是</el-radio
          >
        </el-form-item>

        <el-form-item label="卡台标记">
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

        <el-form-item label="预定到达时间">
          <dateTimePicker
            style="width: 80%"
            :value="formData.customArriveInfo.exp_arrive_time"
            :isShow="picker.show"
            :dateTabActiveIndex="dateTabActiveIndex"
            @showOrHidePicker="showOrHidePicker"
            @updateDatetime="updateDatetime"
          />
        </el-form-item>
        <el-form-item label="订位人">
          <input-select
           v-if="show"
            :autoFocus="this.bookId?false:true"
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
            style="width: 80%"
          ></el-input>
        </el-form-item>

        <el-form-item label="预定人数">
          <el-input
            v-model="formData.customPay.customer_exp_cnt"
            type="number"
            min="0"
            style="width: 80%"
            placeholder="请输入预期预定人数"
            @input="inputCardCountHandle"
          ></el-input>
        </el-form-item>

        <el-form-item label="预期最低消费">
          <el-input
            v-model="formData.customPay.exp_min_csm_amt"
            type="number"
            min="0"
            style="width: 80%"
            placeholder="请输入预期最低消费"
          ></el-input>
          <span class="m-l-1 white">元</span>
        </el-form-item>

        <el-form-item label="联合订位人">
          <input-select
            style="width: 80%"
            :value="formData.secondSales.second_sales_name"
            placeholder="请输入姓名或工号"
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
            style="width: 80%"
          ></el-input>
        </el-form-item>

        <!-- 备注 -->
        <el-form-item label="备注">
          <el-input
            type="textarea"
            :rows="2"
            placeholder="请输入备注"
            v-model="formData.remarkInfo.remark"
            style="width: 80%"
          ></el-input>
        </el-form-item>

        <!-- 提交按钮 -->
        <div class="form-btn">
          <el-button type="info" @click="onCancelDrawer">取消</el-button>
          <el-button type="primary" @click="onSubmit">确认</el-button>
        </div>
      </el-form>
    </el-drawer>
    <chooseCard ref="chooseCard" :showDrawer="showChooseCard" :cardList="allCardList" :dateVal="dateVal" 
    :tabList="tabList" :seatId="seatId"
     @changeShowDrawer="changeShowCardDrawer" @chooseCardHandle="chooseCardHandle" />
  </div>
</template>

<script>
import dateTimePicker from "@/components/book/reserved/dateTimePicker";
import inputSelect from "@/components/book/inputSelect";
import subSelect from "@/components/book/reserved/subSelect";
import formSelect from "@/components/book/select";
import { cardOptions, openTypeList } from "@/utils/config/card";
import api_book from "@/api/Book";
import common_book from "@/utils/common/book";
import chooseCard from "./chooseCard.vue";


export default {
  data() {
    return {
      title: "新建预留",
      bookId: "", // 当前操作修改的预定id
      seatId: "", // 当前所选择预定的卡台id
      orderedCardList: [], // 预定卡台id列表，当前卡台默认添加
      allCardList: [], // 所有卡台列表,对是否选中，是否disabled进行处理
      showChooseCard: false, // 是否显示选择卡台
      show: this.showDrawer, // 是否显示drawer
      formData: {
        //  客人信息
        customInfo: {
          customer_name: "", // 客人名称
          customer_phone: "", // 客人电话
          auto_send_msg: "2", // 是否发送短信
          custom_info_option: [],
        },

        //  客人预定时间
        customArriveInfo: {
          exp_arrive_time: "", // 预定到达时间
        },

        /*
          卡台标记
          */
        markInfo: {
          value: "", // 卡台标记所选值
          option: [],
        },

        //  订位人信息
        sales: {
          sales_name: "", // 订位人名称
          sales_emp_id: "", // 订位人id
          sales_phone: "", // 订位人电话
          sales_info_option: [], // 订位人下拉框选项
        },

        //  联合订位人信息
        secondSales: {
          second_sales_name: "", // 联合订位人名称
          second_sales_emp_id: "", // 联合订位人id
          second_sales_phone: "", // 联合订位人电话
          second_sales_info_option: [], // 联合订位人下拉框选项
        },

        //  客人消费情况
        customPay: {
          exp_min_csm_amt: "", // 预期最低消费
          card_min_csm_amt: "", // 预定开台时卡台固定的最低消费(不可修改状态)

          customer_exp_cnt: "", // 预定人数
        },

        remarkInfo: {
          remark: "", // 备注
        },
      },

      picker: {
        // 时间日期选择器
        show: false,
      },
    };
  },
  methods: {
    deleteCard(itemInfo){
      console.log('item delete', itemInfo)
      this.orderedCardList = this.orderedCardList.filter(item => item.id !== itemInfo.id)
      this.allCardList = this.allCardList.map(item => {
        if(item.id == itemInfo.id) {
          item.selected = false
        }
        return item
      })
    },
    addCard(){
      console.log('addCard')
      
      this.showChooseCard = true
    },
    
    chooseCardHandle(cardInfoLst){
      this.orderedCardList = [...cardInfoLst.filter(item =>item.id *1 != this.seatId * 1)]
      console.log('cardInfoLst', cardInfoLst)
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
        this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo || [];
      const results = query
        ? sealInfoArr.filter(
            (el) =>
              el.code.toString().includes(query) ||
              el.name.toString().includes(query) ||
              el.namePy.toString().includes(query.toLowerCase())
          )
        : sealInfoArr;
      this.formData.sales.sales_info_option = results;
    },
    // 选择订位人的信息
    changeSealName(info) {
      this.formData.sales.sales_name = info.name;
      this.formData.sales.sales_phone = info.phoneNum;
      this.formData.sales.sales_emp_id = info.id;
      this.formData.sales.sales_info_option = [];
    },
    /*
     * 联合订位人
     */
    // 获取模糊查询联合订位人的相关信息
    inputSecondSealName(query) {
      this.formData.secondSales.second_sales_name = query;
      this.formData.secondSales.second_sales_phone = "";
      this.formData.secondSales.second_sales_emp_id = "";
      const sealInfoArr =
        this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo || [];
      const results = query
        ? sealInfoArr.filter(
            (el) =>
              el.code.toString().includes(query) ||
              el.name.toString().includes(query) ||
              el.namePy.toString().includes(query.toLowerCase())
          )
        : sealInfoArr;
      this.formData.secondSales.second_sales_info_option = results;
    },
    // 选择联合订位人的信息
    changeSecondSealName(info) {
      this.formData.secondSales.second_sales_name = info.name;
      this.formData.secondSales.second_sales_phone = info.phoneNum;
      this.formData.secondSales.second_sales_emp_id = info.id;
      this.formData.secondSales.second_sales_info_option = [];
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
        const res = await api_book.reqGetCustomPhone(params);
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

    selectBlurHandle() {
      this.formData.sales.sales_info_option = [];
      this.formData.customInfo.custom_info_option = [];
      this.formData.markInfo.option = [];
    },

    // 更新选择时间
    updateDatetime(dateVal) {
      this.formData.customArriveInfo.exp_arrive_time = dateVal;
      this.showOrHidePicker();
    },

    /**
     * 卡台标记
     */
    changeTips(info) {
      this.formData.markInfo.value = info.id == 0 ? "" : info.name;
      this.formData.markInfo.option = [];
    },
    // 获取卡台标记下拉框
    getMarkOption() {
      const markList =
        this.$store.state.cardPageInfo.resResultDataObj.tipsList || [];
      this.formData.markInfo.option = [{ name: "请选择", id: 0 }, ...markList];
    },

    /*
     * 提交
     */
    async onSubmit() {
      const dateStr =
        this.$store.state.cardPageInfo.resResultDataObj.canDoList[
          this.dateTabActiveIndex
        ].name;
      if (this.isValidParams("addOrUpdateReservedParams") !== "ok") return;
      try {
        const res = this.bookId
          ? await api_book.reqUpdateReservedInfo(this.addOrUpdateReservedParams)
          : await api_book.reqAddBatchReservedInfo(this.addOrUpdateReservedParams);
        this.formSubmitHandle(
          res,
          this.bookId ? "修改成功" : "新增成功",
          this.$parent.getTableData
        );
      } catch (error) {
        console.log("提交失败", error);
      }
    },

    changeShowCardDrawer(val){
      this.showChooseCard = val
    },
    onCancelDrawer() {
      this.$emit("changeShowDrawer", false);
    },

    closeDrawerHandle() {
      this.$emit("changeShowDrawer", false);
    },

    // 初始化表单数据
    async setFomData(info) {
      console.log('info', info)
      this.bookId = info.id || "";
      this.seatId = info.seatId || "";
      this.title = this.bookId ? "修改预留" : "新建预留";
      if (!this.bookId) return this.resetForm();
      const res = await api_book.reqGetBookDetail({ id: this.bookId * 1 });
      if (res.code == 1) {
        const orderPersonInfo =
          common_book.getOrderPersonInfo(res.data.sales_emp_id) || {};
        const orderSecondPersonInfo = res.data.second_sales_emp_id
          ? common_book.getOrderPersonInfo(res.data.second_sales_emp_id) || {}
          : {};
        this.formData = {
          //  客人信息
          customInfo: {
            customer_name: res.data.customer_name || "", // 客人名称
            customer_phone: res.data.customer_phone || "", // 客人电话
            auto_send_msg: res.data.auto_send_msg.toString(), // 是否发送短信
          },

          //  客人预定时间
          customArriveInfo: {
            exp_arrive_time: res.data.exp_arrive_time || "", // 预定到达时间
          },

          //  订位人信息
          sales: {
            sales_name: orderPersonInfo.name || "", // 订位人名称
            sales_emp_id: orderPersonInfo.id, // 订位人id
            sales_phone:
              this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo.find(
                (el) => el.id == orderPersonInfo.id
              ) &&
              this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo.find(
                (el) => el.id == orderPersonInfo.id
              ).phoneNum, // 订位人电话
          },
          //  联合订位人信息
          secondSales: orderSecondPersonInfo.id
            ? {
                second_sales_name: orderSecondPersonInfo.name || "", // 订位人名称
                second_sales_emp_id: orderSecondPersonInfo.id || 0, // 订位人id
                second_sales_phone:
                  this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo.find(
                    (el) => el.id == orderSecondPersonInfo.id
                  ) &&
                  this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo.find(
                    (el) => el.id == orderSecondPersonInfo.id
                  ).phoneNum, // 订位人电话
              }
            : this.formData.secondSales,

          //  客人消费情况
          customPay: {
            exp_min_csm_amt: res.data.exp_min_csm_amt || "", // 预期最低消费

            customer_exp_cnt: res.data.customer_exp_cnt || "", // 预定人数
          },

          remarkInfo: {
            remark: res.data.remark, // 备注
          },

          markInfo: {
            value: res.data.mark, // 卡台标注
            option: [],
          },
        };
      } else {
        this.$message.warning(res.msg);
      }
    },

    // 提交数据
    formSubmitHandle(res, msg, successCallback) {
      if (res.code === 1) {
        this.$message.success(msg);
        this.resetForm();
        this.closeDrawerHandle();
        successCallback && successCallback();
      } else {
        this.$message.warning(res.msg);
      }
    },

    // 重置表单
    resetForm() {
      this.formData.customInfo.customer_name = ""; // 客人名称
      this.formData.customInfo.customer_phone = ""; // 客人电话
      this.formData.customInfo.auto_send_msg = "2"; // 是否发送短信

      this.formData.customArriveInfo.exp_arrive_time = ""; // 预定到达时间

      this.formData.sales.sales_emp_id = ""; // 订位人id
      this.formData.sales.sales_name = ""; // 订位人名称
      this.formData.sales.sales_phone = ""; // 订位人电话

      this.formData.secondSales.second_sales_emp_id = ""; // 联合订位人id
      this.formData.secondSales.second_sales_name = ""; // 联合订位人名称
      this.formData.secondSales.second_sales_phone = ""; // 联合订位人电话

      // 预定人数：如果 capacity 为 0 或未定义，默认设置为 1
      const capacity = this.$store.state.orderInfo.currentCardInfo.capacity;
      this.formData.customPay.customer_exp_cnt = capacity && capacity > 0 ? capacity : 1; // 预定人数
      this.formData.customPay.exp_min_csm_amt =
        this.$store.state.orderInfo.currentCardInfo.grpMinCsmAmt || ""; // 预期最低消费
      this.formData.customPay.card_min_csm_amt = ""; // 预定开台时卡台固定的最低消费(不可修改状态)

      this.formData.remarkInfo.remark = ""; // 备注

      this.formData.markInfo.value = ""; // 卡台标签
    },

    showOrHidePicker() {
      this.picker.show = !this.picker.show;
    },

    isValidParams(key) {
      if (
        this[key].customer_phone.length !== 0 &&
        this[key].customer_phone.length != 11
      )
        return this.$message.warning("请输入正确的手机号");
      // if (!this[key].customer_name)
      //   return this.$message.warning("请输入客人姓名");
      // if (!this[key].exp_arrive_time)
      //   return this.$message.warning("请输入预定到达时间");

      // if (this[key].customer_exp_cnt === '')
      //   return this.$message.warning("请输入预期到店人数");
      // this[key].customer_exp_cnt = Number(this[key].customer_exp_cnt);

      // if (this[key].exp_min_csm_amt.length === 0)
      //   return this.$message.warning("请输入预期最低消费金额");
      // this[key].exp_min_csm_amt = Number(this[key].exp_min_csm_amt);

      return "ok";
    },
  },
  mounted() {
    // this.formData.customArriveInfo.exp_arrive_time = '202210030330'
  },
  props: {
    showDrawer: {
      default: false, // 是否显示drawer
    },
    dateTabActiveIndex: {
      // 当前操作的时期tabIndex
      default: "",
    },
    dateVal: {
      // 当前操作的日期
      default: "",
    },
    cardList: {
      // 卡台列表
      default: [],
    },
    tabList: {
      // 卡座tab列表
      default: [],
    },
  },
  computed: {
    addOrUpdateReservedParams() {
      
      const { formData } = this;
      return {
        is_this_wkday: this.dateTabActiveIndex == 0 ? 1 : 2, // int 是否为当前营业日 1 是 2 否
        id: this.bookId ? this.bookId * 1 : "",
        customer_phone: formData.customInfo.customer_phone, // string 客户电话
        customer_name: formData.customInfo.customer_name, // string  客户名称
        auto_send_msg: Number(formData.customInfo.auto_send_msg), // int  发送短信 1 发送 2 不发送
        book_day: this.$store.state.cardPageInfo.resResultDataObj.canDoList[
          this.dateTabActiveIndex
        ].name
          .split("(")[1]
          .split(")")[0], //   string     //BookDay 预定日期,格式 yyyy-mm-dd
        exp_arrive_time: formData.customArriveInfo.exp_arrive_time, // string 期望到达时间 格式 yyyymmddhh24mi
        sales_emp_id: Number(formData.sales.sales_emp_id), // int64  订位人Id
        second_sales_emp_id: Number(formData.secondSales.second_sales_emp_id), //int64      //SecondSalesEmpId 联合订位人Id
        customer_exp_cnt: formData.customPay.customer_exp_cnt * 1, // int  预期到店人数  // 暂用string 用于校验是否为空
        exp_min_csm_amt: formData.customPay.exp_min_csm_amt * 1, // int   预期最低消费  // 暂时用string 用于校验是否为空
        exp_region_id: 0, // int64 期望区域Id 没指定,或者指定了意向卡台Id,则传0
        exp_seat_id: this.seatId * 1, // int64  期望卡台Id 没指定传0
        exp_seat_ids: [...this.orderedCardList.map(item => item.id * 1), this.seatId * 1], // int64[]  期望卡台Id列表
        remark: formData.remarkInfo.remark, // string   备注信息
        mark: formData.markInfo.value, //  string   卡台标签
      };
    },
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal)
        this.orderedCardList = []
        this.allCardList = this.cardList.map(item => {
          return {
            ...item,
            selected: item.id == this.$store.state.orderInfo.currentCardInfo.id,
            disabled: !item.options.find(item => item.id == 1)
          }
        })
        this.$nextTick(() => {
          const sessionDom = document.querySelector(".el-drawer__body");
          sessionDom.scrollTo(0, 0);
        });
    },
  },
  components: {
    dateTimePicker,
    inputSelect,
    subSelect,
    formSelect,
    chooseCard,
  },
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawer.less";
</style>

<style scoped lang="less">
/deep/ .el-input.is-disabled .el-input__inner {
  background: rgba(0, 0, 0, 0.2) !important;
  border: 1px solid rgba(255, 255, 255, 0.15) !important;
  cursor: not-allowed !important;
}
.label {
  position: relative;
  margin-right: 20px;
  padding: 0px 10px;
  color: white;
  text-align: center;
  border-radius: 10px;
  border: 1px solid #356c6c;
}
.label::after {
  content: "x";
  position: absolute;
  top: -10px;
  right: -10px;
  width: 20px;
  height: 20px;
  line-height: 20px;
  text-align: center;
  background-color: #f56c6c;
  color: #fff;
  border-radius: 50%;
  cursor: pointer;
}
</style>
