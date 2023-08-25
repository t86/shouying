<template>
  <div class="choose-prd">
    <el-dialog
      :title="activeIndex == 1 ? '添加商品' : '添加套餐'"
      :visible.sync="show"
      :close-on-click-modal="false"
    >
      <section>
        <div class="top m-t-2">
          <el-input
            v-model="keyword"
            :placeholder="activeIndex == 1 ? '请输入商品名称' : '请输入套餐名称'"
            style="width:150px"
          ></el-input>
          <el-button type="primary" @click.native="getTableData">搜索</el-button>
          <el-button @click.native="resetHandle">重置</el-button>
        </div>
        <div class="table m-t-4">
          <div class="thead">
            <div class="tr" layout="row" layout-align="start center">
              <div class="th">序号</div>
              <div class="th">{{activeIndex == 1 ? '单品名称' : '套餐名称'}}</div>
            </div>
          </div>
          <div class="tbody">
            <div
              class="tr"
              layout="row"
              layout-align="start center"
              v-for="(item,index) in tableData"
              :key="item.id"
            >
              <div class="td">
                <el-checkbox v-model="item.checked">{{index + 1}}</el-checkbox>
              </div>
              <div class="td">{{item.n}}</div>
            </div>
          </div>
        </div>
      </section>
      <span slot="footer" class="dialog-footer">
        <el-button @click.native="closeDrawerHandle">取消</el-button>
        <el-button type="primary" @click.native="submitHandle">添加</el-button>
      </span>
    </el-dialog>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      show: false,
      tableData: [],
      keyword: ""
    };
  },
  methods: {
    getTableData() {
      this.tableData = JSON.parse(JSON.stringify(this.prdList))
        .filter(item => item.n.startsWith(this.keyword))
        .map(item => ({
          ...item,
          checked: false
        }));
    },
    resetHandle() {
      this.keyword = "";
      this.getTableData();
    },
    submitHandle() {
      const selectedList = this.tableData.filter(item => item.checked);
      if (selectedList.length == 0)
        return this.$message.warning(
          "请选择需要添加的" + this.activeIndex == 1 ? "商品" : "套餐"
        );

      const emitFnName =
        this.activeIndex == 1 ? "addSingleListHandle" : "addGroupListHandle";
      this.$emit(emitFnName, selectedList);
    },
    closeDrawerHandle() {
      this.$emit("showOrHideChoosePrdDrawerHandle");
    }
  },
  created() {},
  mounted() {},
  props: {
    activeIndex: {
      type: Number,
      default: 1
    },
    showDrawer: {
      type: Boolean,
      default: false
    },
    prdList: {
      type: Array,
      default: []
    }
  },
  components: {},
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.keyword = "";
        this.getTableData();
      }
    },
    prdList: {
      deep: true,
      handler(newVal) {
        this.getTableData();
      }
    }
  }
};
</script>

<style scoped lang="less">
.choose-prd {
  /deep/.el-dialog {
    width: 60vw !important;

    .table {
      .th:nth-child(1),
      .td:nth-child(1) {
        width: 30%;
      }
      .th:nth-child(2),
      .td:nth-child(2) {
        width: 70%;
      }
      .thead {
        .tr {
          background-color: #f5f5f5;
          font-weight: 600;
          line-height: 30px;
        }
      }
      .tbody {
        .tr {
          line-height: 30px;
          &:nth-child(2n) {
            background-color: #f5f5f5;
          }
        }
      }
    }
  }
}
</style>