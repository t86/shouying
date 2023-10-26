<template>
  <div>
    <el-drawer
      :title="title"
      :visible.sync="show"
      direction="rtl"
      :size="size"
      :before-close="onCancelDrawer"
    >
      <div class="content">
        <div class="session m-b-10">
          <stepOne
            v-if="status == 1"
            :stepOneInfo="stepOneInfo"
            @updateStepInfo="updateStepInfo"
          />
          <stepTwo
            ref="stepTwo"
            v-if="status == 2"
            :tabIndex="stepOneInfo.tabIndex"
            :customPhoneNum="stepOneInfo.customPhoneNum"
            :stepTwoInfo="stepTwoInfo"
            :phoneValidateStr="stepOneInfo.phoneValidateStr"
            :phoneNum="stepOneInfo.phoneNum"
            :customName="stepOneInfo.customName"
            :customPhoneName="stepOneInfo.customPhoneName"
            :superValidate="stepOneInfo.superValidate"
            :checkedOrderInfo="checkedOrderInfo"
            @updateStepInfo="updateStepInfo"
            @changeStatus="changeStatus"
            @onCancelDrawer="onCancelDrawer"
          />
        </div>
        <!-- 提交按钮 -->
        <div
          class="form-btn"
          v-if="status != 2"
          layout="row"
          layout-align="center center"
        >
          <el-button type="info" @click.stop="onCancelDrawer">取消</el-button>
          <el-button type="primary" @click.stop="onSubmit">{{
            submitTxt
          }}</el-button>
        </div>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_vip from "@/api/vip";
import api_money from "@/api/money";
import api_saveWine from "@/api/saveWine";
import api_wine from "@/api/wine";

import stepOne from "./stepOne.vue";
import stepTwo from "./stepTwo.vue";
export default {
  data() {
    return {
      status: 1, // 1:选择流水  2：选择可存酒水  3：授权存酒
      stepOneInfo: {
        tabIndex: 1,
        authValidateVal: "", // 服务码
        phoneNum: "", // 手机号
        validateVal: "", // 验证码
        customPhoneNum: "", // 客户手机号
        customName: "", // 客户手机号存酒姓名
        customPhoneName: "", // 客户中心存酒客户姓名
        superValidate: "", // 超级授权码
        needAuthPhoneVal: true, // 是否需要手机号验证码
        orderList: [],
        phoneValidateStr: "", // 手机号授权认证
      },

      stepTwoInfo: {},
    };
  },
  methods: {
    init() {
      this.getStepOneData();
      this.stepOneInfo = {
        tabIndex: 1,
        authValidateVal: "", // 服务码
        superValidate: "", // 超级授权码
        phoneNum: "", // 手机号
        customName: "", // 手机号
        validateVal: "", // 验证码
        customPhoneName: "", // 客户中心存酒客户姓名
        needAuthPhoneVal: true, // 是否需要手机号验证码
        orderList: [],
        phoneValidateStr: "", // 手机号授权认证
      };
    },
    async getStepOneData() {
      const params = {
        seat_id: this.$store.state.orderInfo.saveWineCardInfo.id * 1, //    int64   待操作卡台Id
      };
      try {
        const res = await api_saveWine.reqGetCustomOrderList(params);
        if (res.code == 1) {
          this.stepOneInfo.orderList = (res.data.records || []).map(
            (item, index) => ({
              ...item,
              checked: index == 0,
            })
          );
          this.stepOneInfo.needAuthPhoneVal = res.data.cust_in_need_sms == 1;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("流水信息获取失败", error);
      }
    },

    // 手机号验证
    async validatePhoneInfo() {
      const params = {
        m: this.stepOneInfo.phoneNum, //   string    手机号
        c: this.stepOneInfo.validateVal, //    string   验证码
      };

      if (params.c.length != 5) {
        this.$message.warning("请输入正确的五位验证码");
        return false;
      }
      try {
        const res = await api_vip.reqValidatePhoneMsg(params);
        if (res.code == 1) {
          this.stepOneInfo.phoneValidateStr = res.data.c;
          return res.data.c;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("验证手机验证码失败", error);
      }
    },

    // 手机号验证
    async validateBlackList(phoneNumber) {
      const params = {
        key: phoneNumber, //   string   搜索关键字
      };

      try {
        const res = await api_wine.reqGetBlackList(params);
        if (res.code == 1 && res.data.records && res.data.records.length > 0) {
          this.$message.warning("该手机号是黑名单用户，不支持存酒服务");
          return false;
        }
      } catch (error) {
        this.$message.warning("黑名单服务验证异常，稍后重试");
        return false;
      }
      return true;
    },

    // 服务码验证
    async validateValidateInfo() {
      const params = {
        pay_code: this.stepOneInfo.authValidateVal, //    string   付款码
      };
      if (params.pay_code.length != 6) {
        this.$message.warning("请输入正确的六位服务码序列号");
        return false;
      }
      try {
        const res = await api_money.reqGetVipCardFormValidate(params);
        if (res.code == 1) {
          this.stepOneInfo.phoneNum = res.data.p;
          this.stepOneInfo.phoneValidateStr = res.data.c;
          this.stepOneInfo.customPhoneNum = res.data.p;
          if (await this.validateBlackList(res.data.p)) {
            return res.data.c;
          }
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("验证手机验证码失败", error);
      }
    },

    async onSubmit() {
      switch (this.status) {
        case 1:
          let result = "";
          if (this.stepOneInfo.tabIndex == 2) {
            // 手机验证码
            if (
              !this.stepOneInfo.phoneNum ||
              this.stepOneInfo.phoneNum.length != 11
            )
              return this.$message.warning("请输入正确的11位手机号码");
            if (await this.validateBlackList(this.stepOneInfo.phoneNum)) {
              result = this.stepOneInfo.needAuthPhoneVal
                ? await this.validatePhoneInfo()
                : true;
            }
          } else if (this.stepOneInfo.tabIndex == 3) {
            // 客户中心手机号
            // if(this.stepOneInfo.customPhoneNum.length != 11) return this.$message.warning("请输入正确的11位手机号码");
            result = await this.validateBlackList(this.stepOneInfo.customPhoneNum);
          } else if (this.stepOneInfo.tabIndex == 4) {
            // 手机验证码
            if (
              !this.stepOneInfo.phoneNum ||
              this.stepOneInfo.phoneNum.length != 11
            )
              return this.$message.warning("请输入正确的11位手机号码");
            // 超级授权码
            if (this.stepOneInfo.superValidate.length != 7)
              return this.$message.warning("请输入正确的7位超级授权码");
            result = true;
          } else {
            // 服务码
            result = await this.validateValidateInfo();
          }
          if (result) {
            // 隐藏键盘
            if (
            window.atool.getTermType() == "android" &&
            ("hideSoftInput" in window.atool)) {
              atool.hideSoftInput();
              setTimeout(()=>{
                atool.restart();
              },10);
            }
            this.changeStatus(2);
          }
          break;
      }
    },

    changeStatus(status = 1) {
      this.status = status;
    },

    updateStepInfo(info) {
      if (this.status == 1) {
        this.stepOneInfo = { ...info };
      } else if (this.status == 2) {
        this.stepTwoInfo = { ...info };
      }
    },

    onCancelDrawer(isClose) {
      // 隐藏键盘
      if (
        window.atool.getTermType() == "android" &&
        ("hideSoftInput" in window.atool)) {
          atool.hideSoftInput();
          setTimeout(()=>{
            atool.restart();
          },10);
      }
      if (isClose || this.status == 1) this.show = false;
      else this.status -= 1;
    },
  },
  props: {
    value: false,
  },
  computed: {
    show: {
      get() {
        return this.value;
      },
      set(val) {
        this.$emit("input", val);
      },
    },
    checkedOrderInfo() {
      const find = this.stepOneInfo.orderList.find((item) => item.checked);
      return find || {};
    },
    title() {
      let title = "";
      switch (this.status) {
        case 1:
        case 2:
          title = "存酒";
          break;
      }
      return title;
    },
    size() {
      let size = "60%";
      switch (this.status) {
        case 1:
          size = "80%";
          break;
        case 2:
          size = "90%";
          break;
      }
      return size;
    },
    submitTxt() {
      let txt = "确认";
      switch (this.status) {
        case 1:
          txt = "下一步";
          break;
      }
      return txt;
    },
  },
  components: {
    stepOne,
    stepTwo,
  },
  watch: {
    value(newVal) {
      this.show = newVal;
      if (newVal) {
        this.status = 1;
        this.init();
      }
    },
    status(newVal) {
      if (newVal == 2) {
        this.$nextTick(() => {
          this.$refs.stepTwo.init();
        });
      }
    },
  },
};
</script>

<style scoped lang="less">
@import "../../../../style/common/elementDrawer.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/common/elementFormBtn.less";
</style>
