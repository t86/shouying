<template>
  <div>
    <!-- 新增、修改会员卡类型 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session">
        
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer($event, false)">关闭</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_vip from '@/api/vip'
export default {
  data() {
    return {
      show: false,
      
    };
  },
  methods: {
    // 提交
    async onSubmit(){
      
    },
    onCancelDrawer(e, type) {
      this.$emit("showOrHideHandle");
    },
  },
  mounted() {},
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    }
  },
  computed: {
    title() {
      let title = ''
      return title;
    }
  },
  watch: {
    showDrawer: {
      handler(newVal) {
        this.show = newVal;
        if(newVal) {
          // this.resetData()
          // if(this.editInfo.id) {
          //   // 编辑
          //   this.getEditInfoHandle()
          // }
        } else {
          this.$emit('getTableData')
        }
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
@import "../../../style/vip/drawerAddOrUpdateVipType.less";
</style>