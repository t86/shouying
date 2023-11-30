<template>
  <div>
    <!-- 我的下级 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      append-to-body
      :size="size"
    >
    <div class="table-content table2">
        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="start center">
              <div class="th">序号</div>
              <div class="th">员工</div>
              <div class="th">部门</div>
              <div class="th">工号</div>
            </div>
          </div>
          <div class="tbody">
            <div
              class="tr"
              v-for="(item, index) in tableData"
              :key="index"
              layout="row"
              layout-align="start center"
            >
              <div class="td">{{ index + 1 }}</div>
              <div class="td">{{ item.n }}</div>
              <div class="td">{{ item.sn }}</div>
              <div class="td">{{ item.cd }}</div>
              <div class="td">{{ item.u}}</div>
            </div>
            <div class="no-data" v-if="tableData.length == 0">
              <img src="@/assets/img/wu.png" alt />
              <p>暂无数据</p>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="primary" @click.native="onCancelDrawer">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      tableData: []
    };
  },
  methods: {
    // 获取绑定员工二维码
    async getTableData(){
      try {
        const res = await this.$api.BMS.emp.reqGetMySubList({})
        if (!res.msg){
          const blob = new Blob([res]);
          const url = URL.createObjectURL(blob)
          this.QRBindImgSrc = url;
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取我的下级失败', error)
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
      return '我的下级'
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
</style>