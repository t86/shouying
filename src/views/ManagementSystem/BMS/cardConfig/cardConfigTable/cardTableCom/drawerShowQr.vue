<template>
  <div>
    <!-- 预览二维码 -->
    <el-drawer
      title="预览二维码"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 fs14" style="height:calc(100vh - 130px)" layout="row" layout-align="center center">
        <img style="height: auto;width: 500px;" :src="`${imgSrc}`" alt="">
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="closeDrawerHandle">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      imgSrc: ''
    };
  },
  methods: {
    async getImgData() {
      const params = {
        seat_id: this.currentInfo.id * 1
      }
      try {
        const res = await this.$api.BMS.seat.requestSeatPreviewQr(params)
          const blob = new Blob([res])
          const objectURL = URL.createObjectURL(blob)
          this.imgSrc = objectURL
      } catch (error) {
        console.log('分类列表获取失败', error)
      }
    },
    closeDrawerHandle() {
      this.show = false
    }
  },
  mounted() {},
  props: {
    value: {
      default: false // 是否显示drawer
    },
    currentInfo: {
      default: () => ({})
    }
  },
  computed: {
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
    show(newVal) {
      this.show = newVal;
      if (newVal) {
        this.getImgData();
      } 
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../../../style/common/elementDrawerWine.less";
@import "../../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../../style/erp/form.less";
@import "../../../../../../style/erp/table.less";
</style>

<style lang="less" scoped>
.table {
  .th,.td {
    &:nth-child(1) {
      width: 20%;
    }
  }
}
</style>