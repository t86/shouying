<template>
  <div>
    <el-drawer
      title="取酒"
      :visible.sync="show"
      direction="rtl"
      :size="size"
      :before-close="onCancelDrawer"
    >
      <div class="content">
        <div class="session m-b-10">
          <stepOne v-if="status==1" :stepOneInfo="stepOneInfo" @updateStepInfo="updateStepInfo" />
          <stepTwo
            ref="stepTwo"
            v-if="status==2"
            :stepTwoInfo="stepTwoInfo"
            :tabIndex="stepOneInfo.tabIndex"
            :phoneValidateStr="stepOneInfo.phoneValidateStr"
            :phoneNum="stepOneInfo.phoneNum"
            :superValidate="stepOneInfo.superValidate"
            @updateStepInfo="updateStepInfo"
            @changeStatus="changeStatus"
            @onCancelDrawer="onCancelDrawer"
          />
        </div>
        <!-- 提交按钮 -->
        <div class="form-btn" v-if="status!=2" layout="row" layout-align="center center">
          <el-button type="info" @click.stop="onCancelDrawer">取消</el-button>
          <el-button type="primary" @click.stop="onSubmit">{{submitTxt}}</el-button>
        </div>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_vip from "@/api/vip";
import api_money from "@/api/money";

import stepOne from "./stepOne.vue";
import stepTwo from "./stepTwo.vue";
export default {
  data() {
    return {
      status: 1, // 1:选择取酒人  2：选择取酒对应商品
      stepOneInfo: {
        tabIndex: 1,
        authValidateVal: "", // 服务码
        superValidate: "", // 超级授权码
        phoneNum: "", // 手机号
        validateVal: "", // 验证码
        phoneValidateStr: "" // 手机号授权认证
      },

      stepTwoInfo: {}
    };
  },
  methods: {
    init(){
      this.stepOneInfo = {
        tabIndex: 2,
        authValidateVal: "", // 服务码
        superValidate: "", // 超级授权码
        phoneNum: "", // 手机号
        validateVal: "", // 验证码
        phoneValidateStr: "" // 手机号授权认证
      }
    },

    // 服务码验证
    async validateValidateInfo() {
      const params = {
        srv_code: this.stepOneInfo.authValidateVal //    string   付款码
      };
      if (params.srv_code.length != 6) {
        this.$message.warning("请输入正确的六位服务码序列号");
        return false;
      }
      try {
        const res = await api_money.reqGetVipCardFormValidate(params);
        if (res.code == 1) {
          this.stepOneInfo.phoneNum = res.data.p;
          this.stepOneInfo.phoneValidateStr = res.data.c;
          return res.data.c;
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
            ){
              return this.$message.warning("请输入11位手机号码");
            }
            result = true;
          } else if (this.stepOneInfo.tabIndex == 3) {
            // 手机验证码
            if (!this.stepOneInfo.phoneNum || this.stepOneInfo.phoneNum.length != 11) return this.$message.warning("请输入11位手机号码");
            // 超级授权码
            if(this.stepOneInfo.superValidate.length != 7) return this.$message.warning("请输入正确的7位超级授权码");
            result = true
          } else {
            // 服务码
            result = await this.validateValidateInfo();
          }
          if (result) {
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
      if (isClose || this.status == 1) this.show = false;
      else this.status -= 1;
    }
  },
  props: {
    value: false
  },
  computed: {
    show: {
      get() {
        return this.value;
      },
      set(val) {
        this.$emit("input", val);
      }
    },
    size() {
      let size = "90%";
      switch (this.status) {
        case 1:
          size = "90%";
          break;
        case 2:
          size = "95%";
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
    }
  },
  components: {
    stepOne,
    stepTwo
  },
  watch: {
    value(newVal) {
      this.show = newVal;
      if (newVal) {
        this.status = 1;
        this.init()
      }
    },
    status(newVal) {
      if(newVal == 2) {
        this.$nextTick(() => {
          this.$refs.stepTwo.init()
        })
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../style/common/elementDrawer.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/common/elementFormBtn.less";
</style>