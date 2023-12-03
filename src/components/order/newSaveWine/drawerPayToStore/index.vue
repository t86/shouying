<template>
  <div>
    <el-drawer
      title="消费充公"
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
            :stepOneInfo="stepOneInfo"
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
      status: 1, // 1 选择充公日期和订位人  2 选择充公商品
      stepOneInfo: {
        empName: '',
        empId: '',
        dateVal: ''
      }
    };
  },
  methods: {
    init(){
      const date = new Date()
      const year = date.getFullYear()
      const month = (date.getMonth() + 1).toString().padStart(2, 0)
      const day = date.getDate().toString().padStart(2, 0)
      this.stepOneInfo = {
        dateVal: year + '-' + month + '-' + day,
        empName: '',
        empId: '',
      }
    },

    async onSubmit() {
      switch (this.status) {
        case 1:
          if (!this.stepOneInfo.dateVal) return this.$message.warning('请输入充公日期')
          // if (!this.stepOneInfo.empName || !this.stepOneInfo.empId) return this.$message.warning("请输入订位人");
          this.changeStatus(2)
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
      let size = "60%";
      switch (this.status) {
        case 1:
          size = "60%";
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
        this.init()
        this.status = 1;
      }
    },
    status(newVal) {
      if(newVal == 2) {
        this.$nextTick(() => {
          this.$refs.stepTwo.getCenterType()
        })
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../style/common/newElementDrawer.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/common/newElementFormBtn.less";
</style>