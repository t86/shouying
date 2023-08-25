<template>
  <div>
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      append-to-body
      size="720px"
    >
      <div class="session p-5 fs14" layout="row" layout-align="space-around start">
        <div class="item">
          <div class="title bold">不分页打印</div>
          <div class="content">
            <div class="border-bottom p-b-2">
              <div class="bold p-b-2 fs18">[卡座区] K001</div>
              <div class="fs12" layout="row" layout-align="space-between center">
                <span>人数：10</span>
                <span>服务员：000000 系统管理员</span>
              </div>
            </div>
            <div class="border-bottom p-t-2 p-b-2" layout="row" layout-align="space-between center">
              <div class="fs16">雪花啤酒</div>
              <div class="fs12" style="width:150px;text-align:right">¥10.00</div>
              <div class="bold fs20">1</div>
            </div>
            <div class="border-bottom p-t-2 p-b-2" layout="row" layout-align="space-between center">
              <div class="fs16">青岛啤酒</div>
              <div class="fs12" style="width:150px;text-align:right">¥10.00</div>
              <div class="bold fs20">1</div>
            </div>
            <div class="fs12">
              <div class="p-t-2 p-b-3" layout="row" layout-align="space-between center">
                <div>总金额：¥20.00元</div>
                <div>总数：2（2道）</div>
              </div>
              <div class="m-b-1">下单时间：2023-02-06 21:50:20</div>
              <div class="m-b-1">打印时间：2023-02-06 21:50:20</div>
              <div>[大厅出品库]</div>
            </div>
          </div>
        </div>
        <div class="item">
          <div class="title bold">分页打印</div>
          <div class="content">
            <div class="border-bottom p-b-2">
              <div class="bold p-b-2 fs18">[卡座区] K001</div>
              <div class="fs12" layout="row" layout-align="space-between center">
                <span>人数：10</span>
                <span>服务员：000000 系统管理员</span>
              </div>
            </div>
            <div class="border-bottom p-t-2 p-b-2" layout="row" layout-align="space-between center">
              <div class="fs16">雪花啤酒</div>
              <div style="width:150px;text-align:right">¥10.00</div>
              <div class="bold fs20">1</div>
            </div>
            <div class="fs12">
              <div class="p-t-2 p-b-3" layout="row" layout-align="space-between center">
                <div>总金额：¥10.00元</div>
                <div>总数：1（1道）</div>
              </div>
              <div class="m-b-1">下单时间：2023-02-06 21:50:20</div>
              <div class="m-b-1">打印时间：2023-02-06 21:50:20</div>
              <div>[大厅出品库]</div>
            </div>
          </div>
          <div class="content m-t-3">
            <div class="border-bottom p-b-2">
              <div class="bold p-b-2 fs18">[卡座区] K001</div>
              <div class="fs12" layout="row" layout-align="space-between center">
                <span>人数：10</span>
                <span>服务员：000000 系统管理员</span>
              </div>
            </div>
            <div class="border-bottom p-t-2 p-b-2" layout="row" layout-align="space-between center">
              <div class="fs16">青岛啤酒</div>
              <div style="width:150px;text-align:right">¥10.00</div>
              <div class="bold fs20">1</div>
            </div>
            <div class="fs12">
              <div class="p-t-2 p-b-3" layout="row" layout-align="space-between center">
                <div>总金额：¥10.00元</div>
                <div>总数：1（1道）</div>
              </div>
              <div class="m-b-1">下单时间：2023-02-06 21:50:20</div>
              <div class="m-b-1">打印时间：2023-02-06 21:50:20</div>
              <div>[大厅出品库]</div>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {};
  },
  methods: {
    async onSubmit() {},
    onCancelDrawer() {
      this.show = false;
    }
  },
  created() {},
  mounted() {},
  props: {
    value: {
      default: false
    }
  },
  computed: {
    title() {
      return "预览";
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
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang='less'>
@import "../../../../style/common/elementDrawerWine.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/common/elementFormBtnWine.less";
@import "../../../../style/erp/form.less";
@import "../../../../style/erp/table.less";
</style>
<style scoped lang='less'>
.item {
  width: 46%;
  .title {
    font-size: 14px;
    padding: 10px 0;
    text-align: center;
  }
  .content {
    border: 1px solid #333;
    padding: 10px;
  }

  .bold {
    font-weight: 600;
  }

  .border-bottom {
    border-bottom: 1px dashed #333;
  }
}
</style>