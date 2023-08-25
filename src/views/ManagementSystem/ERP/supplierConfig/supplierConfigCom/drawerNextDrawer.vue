<template>
  <div>
    <!-- 有效无效删除erp仓库冲突 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 erp-lib-detail fs14">
        <p>以下对象存在依赖，需人工处理依赖</p>
        <div class="table-content m-t-3">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">序号</div>
                <div class="th">说明</div>
              </div>
            </div>
            <div class="tbody">
              <div
                class="tr"
                v-for="(item,i) in nexDrawerInfo.ns || []"
                :key="i"
                layout="row"
                layout-align="space-between center"
              >
                <div class="td">{{i+1}}</div>
                <div class="td">{{item}}</div>
              </div>
              <div class="no-data" v-if="(nexDrawerInfo.ns || []).length==0">
                <img :src="require('@/assets/img/wu.png')" alt />
                <p>暂无数据</p>
              </div>
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
    return {
    };
  },
  methods: {
    onCancelDrawer() {
      this.show = false;
    }
  },
  mounted() {},
  props: {
    value: {
      default: false // 是否显示drawer
    },
    type: {
      default: 1
    },
    nexDrawerInfo: {
      default: () => ({})
    }
  },
  computed: {
    title() {
      return this.type == 1 ? "置为无效" : this.type == 2 ? "置为有效" : "批量删除";
    },

    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../../style/common/elementDrawerWine.less";
@import "../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../style/erp/form.less";
@import "../../../../../style/erp/table.less";
</style>

<style lang="less" scoped>
.table {
  .th,.td {
    &:nth-child(1) {
      width: 30%;
    }
    &:nth-child(2) {
      width: 70%;
    }
  }
}
</style>