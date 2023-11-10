<template>
  <div class="empty-lib-order">
    <div class="top">
      <div class="status m-b-2" layout="row" layout-align="start center">
        <span class="label fs14">状态：</span>
        <div class="status-item fs14" @click="status = 0" :class="{ active: status == 0 }">全部</div>
        <div class="status-item fs14" @click="status = 1" :class="{ active: status == 1 }">待入库</div>
        <div class="status-item fs14" @click="status = 5" :class="{ active: status == 5 }">已出库</div>
      </div>
      <div layout="row" layout-align="start center">
        <span class="label fs14">日期：</span>
        <ul class="time-select fs14 m-r-1" layout="row" layout-align="start center">
          <li layout="row" layout-align="start center" @click="setDateVal(1)">
            <img
              :src="activeTime == 1 ? require('@/assets/img/date_label_selete.png') : require('@/assets/img/date_label_grey.png')"
              alt />
            <span :class="{ active: activeTime == 1 }">近7天</span>
          </li>
          <li layout="row" layout-align="start center" @click="setDateVal(2)">
            <img
              :src="activeTime == 2 ? require('@/assets/img/date_label_selete.png') : require('@/assets/img/date_label_grey.png')"
              alt />
            <span :class="{ active: activeTime == 2 }">近30天</span>
          </li>
          <li layout="row" layout-align="start center" @click="setDateVal(3)">
            <img
              :src="activeTime == 3 ? require('@/assets/img/date_label_selete.png') : require('@/assets/img/date_label_grey.png')"
              alt />
            <span :class="{ active: activeTime == 3 }">近90天</span>
          </li>
        </ul>
        <div class="value m-r-2">
          <el-date-picker style="width:140px" v-model="begin_day" type="date" :clearable="false" size="small"
            value-format="yyyy-MM-dd" placeholder="开始日期"></el-date-picker>
          <span>至</span>
          <el-date-picker style="width:140px" v-model="end_day" type="date" :clearable="false" size="small"
            value-format="yyyy-MM-dd" placeholder="结束日期"></el-date-picker>
        </div>
        <el-button type="primary" size="small" @click="getTableData">查询</el-button>
        <el-button size="small" @click="resetHandle">重置</el-button>
      </div>
    </div>
    <div class="btn-area m-t-4">
      <el-button type="primary" size="small" @click="showInLibHandle">确认入库</el-button>
      <el-button type="primary" size="small" @click="showHcDrawerHandle">红冲</el-button>
    </div>

    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">
              <el-checkbox v-model="checkAll" :indeterminate="isIndeterminate"
                @change="changeCheckboxHandle('all')">全选</el-checkbox>
            </div>
            <div class="th">单号</div>
            <div class="th">状态</div>
            <div class="th">入库时间</div>
            <div class="th">入库操作人</div>
            <div class="th">入库单生成时间</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" :class="{ 'selected': item.checked }" layout="row" layout-align="space-between center"
            v-for="(item, index) in tableData" :key="item.id">
            <div class="td" layout="row" layout-align="start center">
              <el-checkbox v-model="item.checked" @change="changeCheckboxHandle('item')">{{ index + 1 }}</el-checkbox>
            </div>
            <div class="td">
              <span class="link" @click="showOrderDetailHandle(item)">{{ item.id }}</span>
            </div>
            <div class="td">{{ item.s }}</div>
            <div class="td">{{ item.it }}</div>
            <div class="td">{{ item.o }}</div>
            <div class="td">{{ item.c }}</div>
          </div>
          <div class="no-data" v-if="tableData.length == 0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
        <drawerInListSure v-model="showOrderSureDrawer" :currentInfo="currentInfo" @getTableData="getTableData" />
        <drawerHC v-model="showOHcDrawer" :currentInfo="currentInfo" @getTableData="getTableData" />
        <drawerDetail v-model="showODetailDrawer" :currentInfo="currentInfo" />
      </div>
      <div class="pagination">
        <el-pagination background layout="prev, pager, next" :total="pageInfo.total" :page-size="pageInfo.pageSize"
          :current-page="pageInfo.page" @current-change="changePageHandle"></el-pagination>
      </div>
    </div>
  </div>
</template>
 
<script>
import drawerInListSure from "./emptyInLibCom/drawerInLibSure.vue";
import drawerHC from "./emptyInLibCom/drawerHc.vue";
import drawerDetail from "./emptyInLibCom/drawerDetail.vue";
export default {
  data() {
    return {
      status: 0,
      activeTime: 1, // 1：近7天  2：近30天  3：近3个月
      begin_day: "",
      end_day: "",
      checkAll: false,
      tableData: [],

      showOrderSureDrawer: false, // 是否显示确认入库
      showOHcDrawer: false, // 是否显示红冲drawer
      showODetailDrawer: false, // 是否显示详情drawer
      currentInfo: {}, // 当前勾选空瓶订单
      pageInfo: {
        page: 1,
        pageSize: 20,
        total: 0
      }
    };
  },
  methods: {
    async getTableData() {
      const params = {
        begin_day: this.begin_day, //  string   查询开始日期
        end_day: this.end_day, //    string   查询结束日期
        page_num: this.pageInfo.page * 1, //   int  指定第几页
        page_size: this.pageInfo.pageSize, //  int  每页行数
        status: this.status * 1 //  int   状态 0 全部 1 待入 5 已入
      };

      try {
        const res = await this.$api.ERP.emptyLib.getEmptyInLibList(params);
        if (res.code == 1) {
          this.tableData = (res.data.records || []).map(item => ({
            ...item,
            checked: false
          }));
          this.checkAll = false;
          this.pageInfo.total = res.data.row_cnt || 0;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("充公出库单列表获取失败", error);
      }
    },

    changeCheckboxHandle(type) {
      switch (type) {
        case "all":
          this.tableData = this.tableData.map(item => ({
            ...item,
            checked: this.checkAll
          }));
          break;
        case "item":
          this.checkAll = this.tableData.every(item => item.checked);
          break;
      }
    },

    changePageHandle(page) {
      this.pageInfo.page = page;
      this.getTableData();
    },

    // 确认入库按钮
    showInLibHandle() {
      const checkedInfoList = this.tableData.filter(item => item.checked);
      if (checkedInfoList.length != 1)
        return this.$message.warning("请选择一个订单");
      this.currentInfo = checkedInfoList[0];
      this.showOrderSureDrawer = true;
    },
    // 红冲
    showHcDrawerHandle() {
      const checkedInfoList = this.tableData.filter(item => item.checked);
      if (checkedInfoList.length != 1)
        return this.$message.warning("请选择一个订单");
      this.currentInfo = checkedInfoList[0];
      this.showOHcDrawer = true;
    },

    // 查看详情
    showOrderDetailHandle(itemInfo) {
      this.currentInfo = { ...itemInfo }
      this.showODetailDrawer = true
    },

    getDate(dateNum = +new Date()) {
      const date = new Date(dateNum);
      const year = date.getFullYear();
      const month = (date.getMonth() + 1).toString().padStart(2, 0);
      const day = date
        .getDate()
        .toString()
        .padStart(2, 0);
      return year + "-" + month + "-" + day;
    },

    setDateVal(activeTime) {
      this.activeTime = activeTime;
      const dayInfo = {
        "1": 7,
        "2": 30,
        "3": 90
      };
      const oneDay = +new Date("2023/05/24") - +new Date("2023/05/23");
      const begin = this.getDate(+new Date() - oneDay * dayInfo[activeTime]);
      const end = this.getDate();
      this.begin_day = begin;
      this.end_day = end;
      this.getTableData();
    },

    resetHandle() {
      this.status = 0;
      this.pageInfo.page = 1;
      this.setDateVal(1);
    }
  },
  created() {
    this.resetHandle();
  },
  computed: {
    isIndeterminate() {
      return !this.checkAll && this.tableData.some(item => item.checked);
    }
  },
  components: {
    drawerInListSure,
    drawerHC,
    drawerDetail
  }
};
</script>

<style lang="less" scoped>
@import "../../../../style/erp/table.less";
</style>
<style scoped lang="less">
.empty-lib-order {
  padding: 20px;

  .top {
    .status {
      .status-item {
        width: 70px;
        height: 30px;
        line-height: 30px;
        text-align: center;
        border: 1px solid transparent;
        border-radius: 4px;
        margin-right: 10px;
        cursor: pointer;

        &.active {
          color: #2170ff;
          border: 1px solid #2170ff;
        }
      }
    }

    .time-select {
      li {
        cursor: pointer;
        margin-right: 16px;

        img {
          width: 12px;
          margin-right: 6px;
        }

        span {
          &.active {
            color: #2170ff;
          }
        }
      }
    }
  }

  .table {
    .tbody {
      height: calc(100vh - 310px);
      overflow: auto;

      .primary {
        color: #2170ff;
        cursor: pointer;
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