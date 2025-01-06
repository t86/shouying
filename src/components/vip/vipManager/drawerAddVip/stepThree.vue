<template>
  <div class="step-three">
    <div class="form">
      <div class="row" layout="row" layout-align="start center">
        <div class="label">
          <span class="red">*</span>
          <span>会员卡号:</span>
        </div>
        <div class="value" layout="row" layout-align="start center">
          <el-input
            v-model="form.vipNumVal"
            :maxlength="10"
            size="small"
            style="width: 284px"
            placeholder="请输入会员卡号"
          ></el-input>
          <div
            v-if="loading"
            class="loading"
            layout="row"
            layout-align="start center"
          >
            <img :src="require('@/assets/order-img/loading.png')" alt="" />
            <span>自动生成卡号中...</span>
          </div>
        </div>
      </div>
      <div class="row" layout="row" layout-align="start center">
        <div class="label">
          <span class="red">*</span>
          <span>会员卡类别:</span>
        </div>
        <div class="value" layout="row" layout-align="start center">
          <el-select
            v-model="form.vipTypeVal"
            size="small"
            style="width: 284px"
            placeholder="请选择会员卡类别"
          >
            <el-option
              v-for="item in form.vipTypeOption"
              :key="item.id"
              :label="item.n"
              :value="item.id"
            ></el-option>
          </el-select>
        </div>
      </div>
      <div class="row" layout="row" layout-align="start center">
        <div class="label">
          <span class="red">*</span>
          <span>会员卡等级:</span>
        </div>
        <div class="value" layout="row" layout-align="start center">
          <el-select
            v-model="form.vipDeepVal"
            size="small"
            style="width: 284px"
            placeholder="请选择会员卡等级"
          >
            <el-option
              v-for="item in form.vipDeepValOption"
              :key="item.id"
              :label="item.n"
              :value="item.id"
            ></el-option>
          </el-select>
        </div>
      </div>
      <div class="row" layout="row" layout-align="start center">
        <div class="label">
          <span>联系电话:</span>
        </div>
        <div class="value">
          <el-input
            type="text"
            v-model="form.connectPhoneNum"
            placeholder="请输入联系电话"
            :maxlength="11"
            style="width: 284px"
            size="small"
          ></el-input>
        </div>
      </div>
      <div class="row" layout="row" layout-align="start center">
        <div class="label">
          <span>姓名:</span>
        </div>
        <div class="value">
          <el-input
            v-model="form.userName"
            size="small"
            style="width: 284px"
            placeholder="请输入姓名"
          ></el-input>
        </div>
      </div>
      <div class="row" layout="row" layout-align="start center">
        <div class="label">
          <span>性别:</span>
        </div>
        <div class="value">
          <el-radio v-model="form.sexVal" label="1">男</el-radio>
          <el-radio v-model="form.sexVal" label="2">女</el-radio>
        </div>
      </div>
      <div class="row" layout="row" layout-align="start center">
        <div class="label">
          <span>生日:</span>
        </div>
        <div class="value">
          <el-date-picker
            v-model="form.birthdayVal"
            type="date"
            size="small"
            value-format="yyyy-MM-dd"
            placeholder="选择日期"
            :picker-options="pickerOptions"
            style="width: 284px"
          ></el-date-picker>
        </div>
      </div>
      <div class="row" layout="row" layout-align="start center">
        <div class="label">
          <span>会员卡标签:</span>
        </div>
        <div class="value">
          <el-radio
            v-for="item in form.markList"
            :key="item"
            v-model="form.markVal"
            :label="item"
            >{{ item }}</el-radio
          >
        </div>
      </div>
      <div class="row" layout="row" layout-align="start center">
        <div class="label">
          <span>有效期:</span>
        </div>
        <div class="value">
          <el-radio
            v-for="item in form.timeLongList"
            :key="item.id"
            v-model="form.timeLongVal"
            :label="item.id"
            >{{ item.n }}</el-radio
          >
        </div>
      </div>
      <div
        class="row"
        layout="row"
        layout-align="start center"
      >
        <div class="label">
          <span>订阅短信类型:</span>
        </div>
        <div class="value">
          <el-checkbox
            v-model="item.checked"
            v-for="item in form.messageList"
            :key="item.id"
            >{{ item.n }}</el-checkbox
          >
        </div>
      </div>
      <div class="row" layout="row" layout-align="start center">
        <div class="label">
          <span>开卡推荐人:</span>
        </div>
        <div class="value">
          <el-select
            style="width: 284px"
            v-model="form.openCardPersonVal"
            filterable
            remote
            reserve-keyword
            placeholder="输入员工姓名或工号可查询"
            :remote-method="remoteMethod"
            :loading="remoteLoading"
            size="small"
          >
            <el-option
              v-for="item in form.openCardPersonOptions"
              :key="item.id"
              :label="item.name + ' (' + item.code + ')'"
              :value="item.id"
            ></el-option>
          </el-select>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import api_vip from "@/api/vip";
export default {
  data() {
    return {
      form: {
        vipNumVal: "",
        vipTypeVal: "",
        vipTypeOption: [],
        vipDeepVal: "",
        vipDeepValOption: [],
        connectPhoneNum: "", // 联系电话
        userName: "",
        sexVal: "1",
        birthdayVal: "",
        markVal: "会员",
        markList: [], // 会员卡标签
        timeLongVal: 99,
        timeLongList: [],
        messageList: [],
        openCardPersonVal: "", // 开卡推荐人
        openCardPersonOptions: [],
      },
      pickerOptions: {
        disabledDate(time) {
          return time.getTime() > Date.now();
        },
      },
      remoteLoading: false,
      loading: false,
    };
  },
  methods: {
    // 获取添加会员卡相关option
    async init() {
      this.getParams();
      this.getCardNo();
    },
    async getCardNo() {
      this.loading = true;
      try {
        const res = await api_vip.reqCreateVipCardNo();
        if (res.code == 1) {
          if (!this.form.vipNumVal) {
            this.form.vipNumVal = res.data.card_no || "";
          }
        } else {
          this.$message.warning(res.msg);
        }
        this.loading = false;
      } catch (error) {
        console.log("获取可用卡号失败", error);
      }
    },
    async getParams() {
      try {
        // 并行请求获取添加会员卡参数和会员卡规则
        const [paramsRes, rulesRes] = await Promise.all([
          api_vip.reqGetAddVipCardParams(),
          this.$api.BMS.terminalRules.reqGetVipRules()
        ]);

        if (paramsRes.code == 1) {
          this.form.vipTypeOption = paramsRes.data.card_types || [];
          const defaultVipTypeInfo = this.form.vipTypeOption.sort(
            (a, b) => a - b
          )[0];
          this.form.vipTypeVal = defaultVipTypeInfo.id;
          this.form.vipDeepValOption = defaultVipTypeInfo.ls || [];
          const defaultVipDeepInfo = this.form.vipDeepValOption.sort(
            (a, b) => a - b
          )[0];
          this.form.vipDeepVal = defaultVipDeepInfo.id;

          this.form.markList = paramsRes.data.marks || [];
          this.form.timeLongList = paramsRes.data.valid_years || [];

          // 获取短信类型列表和默认选中状态
          const smsTypes = paramsRes.data.sms_types || [];
          const defaultCheckedTypes = rulesRes.code === 1 ? (rulesRes.data.sms_types || []) : [];

          // 设置短信类型列表，并根据会员卡规则设置默认选中状态
          this.form.messageList = smsTypes.map(item => ({
            ...item,
            checked: defaultCheckedTypes.includes(item.id)
          }));
        } else {
          this.$message.warning(paramsRes.msg);
        }
      } catch (error) {
        console.log("会员卡参数获取失败", error);
      }
    },
    remoteMethod(query) {
      if (query !== "") {
        this.remoteLoading = true;
        this.form.openCardPersonOptions = JSON.parse(
          JSON.stringify(this.openCardPersonOptions)
        ).filter(
          (item) => item.code.includes(query) || item.name.includes(query) || item.namePy.includes(query)
        );
        this.remoteLoading = false;
      } else {
        this.options = [...this.openCardPersonOptions];
      }
    },
  },
  created() {
    this.init();
  },
  mounted() {},
  props: {
    stepOneInfo: {
      default: {},
    },
  },
  computed: {
    openCardPersonOptions() {
      const result =
        this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo || [];
      this.form.openCardPersonOptions = [...result];
      return result;
    },
  },
  watch: {
    "form.vipTypeVal"(newVal) {
      const defaultVipTypeInfo =
        this.form.vipTypeOption.find((item) => item.id == newVal) || {};
      this.form.vipDeepValOption = defaultVipTypeInfo.ls || [];
      const defaultVipDeepInfo = this.form.vipDeepValOption.sort(
        (a, b) => a - b
      )[0];
      this.form.vipDeepVal = defaultVipDeepInfo.id;
    },
    form: {
      handler(newVal) {
        this.$emit("updateStepThreeInfo", newVal);
      },
      deep: true,
      immediate: true,
    },
  },
};
</script>

<style scoped lang="less">
@import "../../../../style/vip/drawerManager/stepThree.less";
@import "../../../../style/vip/vip.less";
</style>

<style>
.el-date-table td.disabled div {
  background-color: transparent;
  color: #999;
}
</style>
