<template>
  <!-- 待充公 -->
  <div class="to-store">
    <div class="top" layout="row" layout-align="start center">
      <el-input
        v-model="keyword"
        style="width: 200px"
        class="m-r-2"
        size="small"
        placeholder="充公人/商品/卡台"
      ></el-input>
      <el-button type="primary" size="small" @click="getTableData"
        >查询</el-button
      >
      <el-button size="small" @click="resetHandle">重置</el-button>
    </div>
    <div class="btn-area m-t-4">
      <el-button type="primary" size="small" @click="toLibSureHandle"
        >确认入库</el-button
      >
      <el-button type="danger" size="small" @click="toLibBackHandle"
        >驳回</el-button
      >
    </div>

    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="start center">
            <div class="th">
              <el-checkbox
                :indeterminate="isIndeterminate"
                v-model="checkAll"
                @change="changeCheckboxHandle('all')"
                >全选</el-checkbox
              >
            </div>
            <div class="th">充公操作人</div>
            <div class="th">充公类型</div>
            <div class="th">卡台</div>
            <div class="th">订台人</div>
            <div class="th">待充公时间</div>
            <div class="th">操作</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            :class="{ selected: item.checked }"
            v-for="(item, index) in tableData"
            :key="item.id"
          >
            <div class="coll" layout="row" layout-align="space-between center">
              <div class="td" layout="row" layout-align="start center">
                <el-checkbox
                  v-model="item.checked"
                  @change="changeCheckboxHandle('item')"
                  >{{ index + 1 }}</el-checkbox
                >
                <i
                  class="m-l-2"
                  style="border: 1px solid #ccc; cursor: pointer"
                  @click="item.show = !item.show"
                  :class="[item.show ? 'el-icon-minus' : 'el-icon-plus']"
                ></i>
              </div>
              <div class="td">{{ item.w }}</div>
              <div class="td">{{ item.p }}</div>
              <div class="td">{{ item.s }}</div>
              <div class="td">{{ item.e }}</div>
              <div class="td">{{ item.t }}</div>
              <div class="td">
                <span v-if="item.ti == 1" @click="showEditDrawerHandle(item)">编辑</span>
              </div>
            </div>
            <div class="detail-list" v-if="item.show">
              <div
                class="tr-thead"
                layout="row"
                layout-align="space-between center"
              >
                <div class="tr-th">酒水名称</div>
                <div class="tr-th">规格</div>
                <div class="tr-th">每瓶克数</div>
                <div class="tr-th">数量</div>
              </div>
              <div class="tr-tbody">
                <div
                  class="tr-tr"
                  layout="row"
                  layout-align="space-between center"
                  v-for="(items, index) in item.ss || []"
                  :key="index"
                >
                  <div class="tr-td">{{ items.n }}</div>
                  <div class="tr-td">{{ items.u }}</div>
                  <div class="tr-td">{{ items.g || "-" }}</div>
                  <div class="tr-td">{{ items.c }}</div>
                </div>
              </div>
            </div>
          </div>
          <div class="no-data" v-if="tableData.length == 0">
            <img src="@/assets/img/wu.png" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>

    <!-- 编辑待充公 -->
    <drawerEditToStoreInfo
      v-model="showEditDrawer"
      :currentWineInfo="currentWineInfo"
      @getTableData="getTableData"
    />
  </div>
</template>

<script>
import api_wine from "@/api/wine";
import drawerEditToStoreInfo from "./drawerEditToStoreInfo.vue";
export default {
  data() {
    return {
      ids: [], // 选中的id列表
      keyword: "",
      start_cg_day: "", // 充公开始日期
      end_cg_day: "", // 充公结束日期
      checkAll: false,
      tableData: [],
      showEditDrawer: false,
      currentWineInfo: {},
    };
  },
  methods: {
    async getTableData() {
      const params = {
        start_cg_day: this.start_cg_day, //  string  开始日期,格式 yyyy-mm-dd
        end_cg_day: this.end_cg_day, // string  结束日期,格式 yyyy-mm-dd
        key: this.keyword || "", //  string  搜索关键字
      };

      try {
        const res = await api_wine.reqGetNeedToStoreList(params);
        if (res.code == 1) {
          res.data.records = res.data.records || [];
          res.data.records.forEach((el) => {
            el.ss = el.ss || [];
            el.show = true;
            el.checked = false;
          });

          this.checkAll = false;
          this.tableData = res.data.records;
          this.ids = [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("待入库存酒数据获取失败", error);
      }
    },

    // 确认入库
    async toLibSureHandle() {
      const params = {
        ids: this.ids, //    []int64  存酒待入库订单列表
      };
      if (params.ids.length == 0)
        return this.$message.warning("请选择需要确认的数据");
      try {
        const res = await api_wine.reqPassToStoreListOfNotAuth(params);
        if (res.code == 1) {
          this.$message.success("入库成功");
          this.getTableData();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("确认入库操作失败", error);
      }
    },

    // 驳回
    async toLibBackHandle() {
      const params = {
        ids: this.ids, //    []int64  存酒待入库订单列表
      };
      if (params.ids.length == 0)
        return this.$message.warning("请选择需要驳回的数据");
      try {
        const res = await api_wine.reqBackToStoreList(params);
        if (res.code == 1) {
          this.$message.success("驳回成功");
          this.getTableData();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("驳回操作失败", error);
      }
    },

    changeCheckboxHandle(type) {
      switch (type) {
        case "all":
          this.tableData = this.tableData.map((item) => ({
            ...item,
            checked: this.checkAll,
          }));
          break;
        case "item":
          this.checkAll = this.tableData.every((item) => item.checked);
          this.indeterminate =
            !this.checkAll && this.tableData.some((item) => item.checked);
          break;
      }
      this.ids = this.tableData
        .filter((item) => item.checked)
        .map((item) => item.o);
    },

    resetHandle() {
      const oneHour =
        +new Date("2023/07/22 12:00:00") - +new Date("2023/07/22 11:00:00");
      const date = new Date(+new Date() - 8 * oneHour);
      const year = date.getFullYear();
      const month = (date.getMonth() + 1).toString().padStart(2, 0);
      const day = date.getDate().toString().padStart(2, 0);
      const now = year + "-" + month + "-" + day;
      this.start_cg_day = now;
      this.end_cg_day = now;
      this.keyword = "";
      this.checkAll = false;
      this.getTableData();
    },

    showEditDrawerHandle(itemInfo) {
      this.currentWineInfo = { ...itemInfo };
      this.showEditDrawer = true;
    },
  },
  created() {
    this.resetHandle();
  },
  components: {
    drawerEditToStoreInfo,
  },
  computed: {
    isIndeterminate() {
      return !this.checkAll && this.tableData.some((item) => item.checked);
    },
  },
};
</script>

<style lang="less" scoped>
@import "../../../../style/wine/table.less";
</style>
<style scoped lang="less">
.to-store {
  padding: 20px;
  .table-content {
    .table {
      .thead .th {
        font-size: 15px;
      }
      .tbody {
        height: calc(100vh - 260px);
        overflow: auto;
        .tr {
          background-color: #ddd !important;
          margin-top: 2px;
          .td {
            background-color: #ddd !important;
          }
          &:hover {
            .td {
              background-color: #ddd !important;
            }
          }
        }
        .coll {
          height: 40px;
          font-size: 15px;
          .td {
            font-weight: 600;
            /deep/.el-checkbox__label {
              font-weight: 600;
            }
            &:nth-last-child(1) {
              span {
                color: #2170ff;
                cursor: pointer;
              }
            }
          }
        }
        .detail-list {
          font-size: 13px;
          .tr-thead {
            height: 30px;
            width: 100%;
            background-color: #eee;
            .tr-th {
              width: 50%;
              color: #6a6a74;
              font-weight: 600;
              &:nth-child(1) {
                padding-left: 20px;
              }
            }
          }
          .tr-tbody {
            // max-height: 200px;
            // overflow: auto;
            .tr-tr {
              min-height: 30px;
              &:hover {
                background-color: #d7e9ff !important;
              }
              &:nth-child(2n) {
                background-color: #eee;
              }
              &:nth-child(2n + 1) {
                background-color: #f9f9f9;
              }
              .tr-td {
                width: 50%;
                &:nth-child(1) {
                  padding-left: 20px;
                }
              }
            }
          }
        }
      }
    }
  }
}
</style>

<style>
/* 日期选择器 */
.el-date-picker__header-label {
  color: #1a1a21;
}
.el-date-table th,
.el-picker-panel__content {
  color: #1a1a21;
}
.el-range-editor--small .el-range-input {
  background-color: transparent;
}
</style>
