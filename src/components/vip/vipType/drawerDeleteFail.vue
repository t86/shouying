<template>
  <div>
    <!-- 新增、修改会员卡类型 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="500px"
    >
      <div class="session delete-fail">
        <div class="tips" layout="row" layout-align="start center">
          <img :src="require('@/assets/vip-imgs/delete-warning.png')" alt />
          <span>检测到以下会员卡正在使用当前所选卡类型，暂不能批量删除</span>
        </div>
        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="space-between center">
              <div class="th">序号</div>
              <div class="th">会员卡号</div>
              <div class="th">手机号</div>
            </div>
          </div>
          <div class="tbody">
            <div
              class="tr"
              layout="row"
              layout-align="space-between center"
              v-for="(item,index) in deleteFailList"
              :key="index"
            >
              <div class="td">{{index + 1}}</div>
              <div class="td">{{item.c}}</div>
              <div class="td">{{item.p}}</div>
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
import api_vip from "@/api/vip";
export default {
  data() {
    return {
      show: false
    };
  },
  methods: {
    onCancelDrawer() {
      this.$emit("showOrHideHandle");
    }
  },
  mounted() {},
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    },
    deleteFailList: {
      default: []
    }
  },
  computed: {
    title() {
      let title = "删除";
      return title;
    }
  },
  watch: {
    showDrawer: {
      handler(newVal) {
        this.show = newVal;
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawerVip.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/vip/vipBtn.less";
@import "../../../style/common/elementFormBtnVip.less";
@import "../../../style/common/scrollBarVip.less";
@import "../../../style/vip/vipBtn.less";
@import "../../../style/vip/vip.less";
</style>
<style lang="less" scoped>
.delete-fail {
  padding: 20px;
  .tips {
    font-size: 14px;
    color: #e0304f;
    margin-bottom: 20px;
    img {
      width: 20px;
      margin-right: 8px;
    }
  }

  .table {
    .thead .tr {
      background-color: #b3bbcd !important;
    }

    .th:nth-child(1),
    .td:nth-child(1) {
      width: 20%;
    }
    .th:nth-child(2),
    .td:nth-child(2),
    .th:nth-child(3),
    .td:nth-child(3) {
      width: 40%;
    }
  }
}
</style>