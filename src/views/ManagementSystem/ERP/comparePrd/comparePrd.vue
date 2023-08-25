<template>
  <div class="compare-prd">
    <!-- tab栏 -->
    <ul class="tab" layout="row" layout-align="start center">
      <li :class="{'active': tabIndex == 1}" @click="changeTabIndexHandle(1)">未对照</li>
      <li :class="{'active': tabIndex == 2}" @click="changeTabIndexHandle(2)">已对照</li>
      <li :class="{'active': tabIndex == 3}" @click="changeTabIndexHandle(3)">不用对照</li>
    </ul>
    <div v-if="tabIndex!=3" class="not-compare-tips">
      <h5 class="m-b-3" v-if="tabIndex == 1">系统已自动为商品匹配erp商品，如匹配无误可直接完成对照；如有错误可手动调整，若商品不需要对照，则点击不用对照</h5>
      <!-- <el-button type="primary" @click.native="compareSuccessHandle">完成对照</el-button> -->
      <el-button type="primary" @click.native="notCompareHandle">不用对照</el-button>
    </div>
    <div class="contain">
      <div class="table-content">
        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="space-between center">
              <div class="th">
                <el-checkbox v-model="checkAll" :indeterminate="isIndeterminate" @change="changeCheckBoxHandle('all')">序号</el-checkbox>
              </div>
              <div class="th">商品名称</div>
              <div class="th">一级分类</div>
              <div class="th">二级分类</div>
              <div class="th">拼音简写</div>
              <div class="th">商品价格</div>
              <div class="th">erp商品名称</div>
            </div>
          </div>

          <div class="tbody" :class="{'first-tab': tabIndex == 1, 'second-tab': tabIndex == 2}">
            <div
              class="tr"
              :class="{'selected': item.checked,'gray': item.s == '无效'}"
              layout="row"
              layout-align="space-between center"
              v-for="(item,index) in tableData"
              :key="index"
            >
              <div class="td">
                <el-checkbox v-model="item.checked" @change="changeCheckBoxHandle('item')">{{index+1}}</el-checkbox>
              </div>
              <div class="td">{{item.n}}</div>
              <div class="td">{{item.ocn}}</div>
              <div class="td">{{item.tcn}}</div>
              <div class="td">{{item.np}}</div>
              <div class="td">{{item.p}}</div>
              <div class="td" layout="row" layout-align="start center">
                <ul
                  v-if="item.mn"
                  class="list"
                  layout="row"
                  layout-align="start center"
                  style="flex-wrap:wrap;margin-bottom:4px"
                >
                  <li
                    class="m-l-1 m-t-1"
                    style="background:#eee;padding:5px;border-radius:2px;white-space: nowrap;"
                  >
                    <span style="background:rgba(0,0,0,0)">{{item.mn}}</span>
                  </li>
                </ul>
                <span
                  style="display:inline-block;margin-left:4px;color:#fff"
                  @click="showOrHideDrawerHandle(item)"
                >{{item.mn?'去修改':'去绑定'}}</span>
              </div>
            </div>
            <div class="tr" v-if="tableData.length<1">
              <div class="nodata">
                <img src="../../../../assets/img/wu.png" alt />
                <div class="hint">暂无数据</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="fr">
      <el-pagination
        background
        layout="prev, pager, next"
        @current-change="changePageHandle"
        :page-size="pageSize"
        :total="allTotal"
      ></el-pagination>
    </div>

    <drawerBindPrd
      :showDrawer="showDrawer"
      :currentItem="currentItem"
      @showOrHideDrawer="showOrHideDrawerHandle"
      @getBindList="getBindList"
    />
  </div>
</template>
 
<script>
import drawerBindPrd from "./drawerBindPrd.vue";
export default {
  data() {
    return {
      tabIndex: 1, // tab当前高亮值
      page: 1, // 当前页码
      allTotal: 0, // 数据总条数
      pageSize: 20, // 每页展示数据
      showDrawer: false, // 是否显示绑定抽屉
      checkAll: false, // 全选
      tableData: [], //表格数据
      currentItem: {} // 当前绑定的商品信息
    };
  },
  methods: {
    changeTabIndexHandle(index) {
      this.tabIndex = index;
      this.page = 1;
      this.allTotal = 0;
      this.getTableData();
    },
    async getTableData() {
      try {
        this.loading = this.$loading({
          lock: true,
          text: "Loading",
          spinner: "el-icon-loading",
          background: "rgba(0, 0, 0, 0.5)"
        });

        setTimeout(() => {
          this.loading.close();
        }, 5000);

        const params = {
          page_num: this.page * 1, //   int        //PageNum 第几页
          page_size: this.pageSize * 1 //  int        //PageSize 每页行数
        };
        let res = {};
        if (this.tabIndex == 1) {
          // 未对照
          res = await this.$api.ERP.comparePrd.reqGetNotBindPrdList(params);
        } else if (this.tabIndex == 2) {
          // 已对照
          res = await this.$api.ERP.comparePrd.reqGetBindedPrdList(params);
        } else {
          // 不用对照
          res = await this.$api.ERP.comparePrd.reqGetCantBindPrdList(params);
        }
        if (res.code == 1) {
          this.tableData =
            res.data && res.data.datas
              ? res.data.datas.map(item => ({ ...item, checked: false }))
              : [];
              this.allTotal = res.data.row_cnt
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取未绑定存货列表失败", error);
      }
      this.loading.close();
    },

    // 选择
    changeCheckBoxHandle(type) {
      switch (type) {
        case "all":
          const tableData = [...this.tableData];
          tableData.forEach(el => {
            el.checked = this.checkAll;
          });
          this.tableData = [...tableData];
          break;
        case "item":
          this.checkAll = this.tableData.every(item => item.checked);
          break;
      }
    },

    getBindList({ inventory, currentItem }) {
     this.compareSuccessHandle(currentItem.id, inventory[0].id)
    },

    showOrHideDrawerHandle(item) {
      if (item && item.n) {
        this.currentItem = { ...item };
      }
      this.showDrawer = !this.showDrawer;
    },
    // 完成对照
    async compareSuccessHandle(id, mid) {
      const params = {
        id: id * 1, // int64  待操作商品Id
        mid: mid * 1 // int64  绑定的物料Id
      };
      try {
        const res = await this.$api.ERP.comparePrd.reqBindPrdList(params);
        if (res.code == 1) {
          this.getTableData();
          this.$message.success("对照成功");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("完成对照失败", error);
      }
    },
    // 不用对照
    async notCompareHandle() {
      const params = {
        ids: this.tableData.filter(item => item.checked).map(item => item.id) //  []int64    待操作商品Id列表
      };
      if (params.ids.length <= 0)
        return this.$message.warning("请选择操作的商品");
      try {
        const res = await this.$api.ERP.comparePrd.reqCloseBindPrdList(params);
        if (res.code == 1) {
          this.getTableData();
          this.$message.success("操作成功");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("不用对照失败", error);
      }
    },

    changePageHandle(page) {
      this.page = page;
      this.checkAll = false;
      this.getTableData()
    }
  },
  mounted() {
    this.getTableData();
  },

  computed: {
    isIndeterminate() {
      return !this.checkAll && this.tableData.some(item => item.checked);
    }
  },
  
  components: {
    drawerBindPrd
  }
};
</script>

<style lang="less" scoped>
@import '../../../../style/erp/table.less';
</style>

<style scoped lang="less">
.compare-prd {
  padding: 20px;
  color: #40404e;

  .tab {
    padding-bottom: 10px;
    li {
      padding: 10px;
      margin-right: 4px;
      font-size: 17px;
      border-bottom: 2px solid transparent;
      cursor: pointer;
      &.active {
        color: #2170ff;
        border-bottom: 2px solid #2170ff;
      }
    }
  }

  h5 {
    font-weight: 400;
    color: #f56c6c;
    font-size: 16px;
    line-height: 26px;
  }

  .contain {
    width: 100%;
    overflow-x: auto;
    .table {
      padding: 10px;
      width: calc(100% - 60px);
      min-width: 600px;
      font-size: 14px;
      .tr {
        min-height: 30px;
        padding: 5px 0;
        .th:nth-child(1),
        .td:nth-child(1) {
          width: 8%;
        }
        .th:nth-child(2),
        .td:nth-child(2) {
          width: 15%;
        }
        .th:nth-child(3),
        .td:nth-child(3) {
          width: 15%;
        }
        .th:nth-child(4),
        .td:nth-child(4) {
          width: 15%;
        }
        .th:nth-child(5),
        .td:nth-child(5) {
          width: 6%;
        }
        .th:nth-child(6),
        .td:nth-child(6) {
          width: 6%;
        }
        .th:nth-child(7),
        .td:nth-child(7) {
          width: 20%;
          text-align: left;
          span {
            font-size: 12px;
            padding: 4px;
            background-color: #2170ff;
            border-radius: 4px;
            cursor: pointer;
          }
        }
      }

      .thead .tr {
        background-color: #f5f5f5;
        /deep/.el-checkbox__label,
        .th {
          font-size: 14px;
          color: #1a1a21;
          font-weight: 600;
        }
      }

      .tbody {
        height: calc(100vh - 300px);
        overflow-y: auto;
        &.first-tab {
          height: calc(100vh - 372px);
        }
        &.second-tab {
          height: calc(100vh - 334px);
        }
        .tr:nth-child(2n) {
          background-color: #f5f5f5;
        }
      }
    }
  }

  /deep/.el-pagination.is-background .el-pager li:not(.disabled).active{
    background-color: #2170ff;
  }
}
</style>