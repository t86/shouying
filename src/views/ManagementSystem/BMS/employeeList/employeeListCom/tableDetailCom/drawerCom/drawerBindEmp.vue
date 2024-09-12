<template>
  <div>
    <!-- 绑定员工 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      append-to-body
      :size="size"
    >
      <div class="session p-5 erp-lib-detail fs14" style="width:100%;height:80%">
        <div v-if="currentBindPersonInfo.bs=='未绑定'" style="width:100%;height:100%" layout="column" layout-align="center center" >
          <img width="300" :src="QRBindImgSrc" />
          <h3 style="line-height:60px;text-align:center">请‘{{currentBindPersonInfo.n}}’用微信扫描二维码进行绑定</h3>
          <p class="red-color">备注：二维码在15分钟内有效</p>
        </div>
        <h3 v-else style="line-height:60px">是否确认解除绑定？</h3>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="" @click.stop="onCancelDrawer">{{currentBindPersonInfo.bs=='未绑定'?'关闭':'取消'}}</el-button>
        <el-button v-if="currentBindPersonInfo.bs!='未绑定'" type="primary" @click.native="unBindEmpHandle">确认</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      QRBindImgSrc: ''
    };
  },
  methods: {
    // 获取绑定员工二维码
    async getBindQRcode(){
      const params = {
        emp_id: this.currentBindPersonInfo.id * 1 //  int64   员工Id
      }

      try {
        const res = await this.$api.BMS.emp.reqGetEmpQrCode(params)
        if (!res.msg){
          const blob = new Blob([res]);
          const url = URL.createObjectURL(blob)
          this.QRBindImgSrc = url;
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('绑定员工二维码获取失败', error)
      }
    },

    // 解绑
    async unBindEmpHandle(){
      const params = {
        emp_id: this.currentBindPersonInfo.id * 1 //  int64   员工Id
      }
      try {
         const res = await this.$api.BMS.emp.reqUnbindEmp(params)
        if (res.code == 1){
          this.$message.success('解绑成功')
          this.onCancelDrawer()
          this.$emit('getEmpTableList')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
          console.log('解绑员工失败', error)
      }
    },

    onCancelDrawer() {
      this.show = false;
    }
  },
  mounted() {},
  props: {
    value: {
      default: false // 是否显示drawer
    },
    currentBindPersonInfo:{
      default: () => ({})
    }
  },
  computed: {
    title() {
      return '绑定员工'
    },

    size() {
      return '720px'
    },

    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      }
    }
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.getBindQRcode()
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../../../../style/common/elementDrawerWine.less";
@import "../../../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../../../style/erp/form.less";
@import "../../../../../../../style/erp/table.less";
</style>

<style lang="less" scoped>
.coll {
  margin-top: 16px;
  .label {
    width: 120px;
  }
}
/deep/ .el-drawer__body {
  flex: 1;
}

</style>