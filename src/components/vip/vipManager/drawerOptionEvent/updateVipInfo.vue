<template>
  <div class="step-three">
    <div class="form">
      <div class="row" layout="row" layout-align="start center">
        <div class="label">
          <span class="red">*</span>
          <span>会员卡号:</span>
        </div>
        <div class="value">
          <el-input
            disabled
            v-model="form.vipNumVal"
            :maxlength="10"
            size="small"
            style="width: 284px"
            placeholder="请输入会员卡号"
          ></el-input>
        </div>
      </div>
      <div class="row" layout="row" layout-align="start center">
        <div class="label">
          <span class="red">*</span>
          <span>会员卡类别:</span>
        </div>
        <div class="value" layout="row" layout-align="start center">
          <el-input
            disabled
            v-model="form.vipTypeVal"
            :maxlength="10"
            size="small"
            style="width: 284px"
            placeholder="请输入会员卡类别"
          ></el-input>
        </div>
      </div>
      <div class="row" layout="row" layout-align="start center">
        <div class="label">
          <span class="red">*</span>
          <span>会员卡等级:</span>
        </div>
        <div class="value" layout="row" layout-align="start center">
          <el-input
            disabled
            v-model="form.vipDeepVal"
            :maxlength="10"
            size="small"
            style="width: 284px"
            placeholder="请输入会员等级"
          ></el-input>
        </div>
      </div>
      <div class="row" layout="row" layout-align="start center">
        <div class="label">
          <span>联系电话:</span>
        </div>
        <div class="value">
          <el-input
            v-model="form.connectPhoneNum"
            placeholder="请输入联系电话"
            style="width: 284px"
            size="small"
            :maxlength="11"
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
        <el-select
          style="width: 216px"
          v-model="form.personVal"
          filterable
          remote
          reserve-keyword
          placeholder="输入员工姓名或工号可查询"
          :remote-method="remoteMethod"
          :loading="remoteLoading"
          size="small"
        >
          <el-option
            v-for="item in personOptions"
            :key="item.id"
            :label="item.name + ' (' + item.code + ')'"
            :value="item.id"
          ></el-option>
        </el-select>
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
        vipDeepVal: "",
        connectPhoneNum: "",
        userName: "",
        sexVal: "1",
        birthdayVal: "",
        markVal: "会员",
        markList: [], // 会员卡标签
        timeLongVal: 99,
        timeLongList: [],
        messageList: [],
        personVal: "",
        originPersonVal: "",
      },
      personOptions:[],
      remoteLoading: false,
      pickerOptions: {
        disabledDate(time) {
          return time.getTime() > Date.now();
        },
      },
      originInfo: {},
    };
  },
  methods: {
    async initEditInfo() {
      const params = {
        id: this.currentItemInfo.id, // int 会员卡id
      };
      try {
        const res = await api_vip.reqGetVipInfoFormEditVipInfo(params);
        if (res.code == 1) {
          let { card_info, reg_sms_types } = res.data;
          this.form.vipNumVal = card_info.card_no;
          this.form.vipTypeVal = card_info.card_type_name;
          this.form.vipDeepVal = card_info.card_level_name;
          this.form.connectPhoneNum = card_info.contact_phone;
          this.form.userName = card_info.name;
          this.form.sexVal = card_info.sex.toString();
          this.form.birthdayVal = card_info.birthday;
          this.form.markVal = card_info.mark;
          this.form.timeLongVal = card_info.expired_type;
          this.form.personVal = card_info.sales_emp_name;
          this.form.originPersonVal = card_info.sales_emp_id;

          reg_sms_types = reg_sms_types || [];

          this.form.markList = res.data.marks || [];
          this.form.timeLongList = res.data.valid_years || [];
          this.form.messageList = (res.data.sms_types || []).map((item) => ({
            ...item,
            checked: reg_sms_types.includes(item.id),
          }));
          this.originInfo = {
            userName: card_info.name,
            sexVal: card_info.sex.toString(),
            birthdayVal: card_info.birthday,
          };
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取修改前会员卡数据失败", error);
      }
    },
    remoteMethod(query) {
      if (query !== "") {
        this.remoteLoading = true;
        const result =
          this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo || [];
        this.personOptions = result.filter(
          (item) => item.code.includes(query) || item.name.includes(query) || item.namePy.includes(query)
        );
        this.remoteLoading = false;
      } else {
        this.options = [];
      }
    },
  },
  props: {
    currentItemInfo: {
      default: {},
    },
  },
  watch: {
    form: {
      handler(newVal) {
        if (
          newVal.userName !== this.originInfo.userName ||
          newVal.sexVal !== this.originInfo.sexVal ||
          newVal.birthdayVal !== this.originInfo.birthdayVal
        ) {
          newVal.show = true;
        } else {
          newVal.show = false;
        }
        this.$emit("updateInfoHandle", newVal);
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
