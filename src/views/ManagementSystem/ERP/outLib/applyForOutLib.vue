<template>
<!-- 异议订单 -->
  <div class="empty-lib-order">
    <div class="top">
      <div class="m-b-3" layout="row" layout-align="start center">
        <span class="label fs14">状态：</span>
        <ul class="fs14 order-status" layout="row" layout-align="start center">
          <li @click="orderStatus = 0;;getTableData()" :class="[orderStatus == 0 ? 'active cursor primary-link' : 'cursor']">全部</li>
          <li @click="orderStatus = 3;getTableData()" :class="[orderStatus == 3 ? 'active cursor primary-link' : 'cursor']">待处理</li>
          <li @click="orderStatus = 2;getTableData()" :class="[orderStatus == 2 ? 'active cursor primary-link' : 'cursor']">已处理</li>
          <li @click="orderStatus = 1;getTableData()" :class="[orderStatus == 1 ? 'active cursor primary-link' : 'cursor']">已完成</li>
        </ul>
      </div>
      <div layout="row" layout-align="start center">
        <span class="label fs14">操作时间：</span>
        <ul class="time-select fs14 m-r-1" layout="row" layout-align="start center">
          <li layout="row" layout-align="start center" @click="setDateVal(1)">
            <img
              :src="activeTime == 1 ? require('@/assets/img/date_label_selete.png') : require('@/assets/img/date_label_grey.png')"
              alt
            />
            <span :class="{active:activeTime == 1}">近7天</span>
          </li>
          <li layout="row" layout-align="start center" @click="setDateVal(2)">
            <img
              :src="activeTime == 2 ? require('@/assets/img/date_label_selete.png') : require('@/assets/img/date_label_grey.png')"
              alt
            />
            <span :class="{active:activeTime == 2}">近30天</span>
          </li>
          <li layout="row" layout-align="start center" @click="setDateVal(3)">
            <img
              :src="activeTime == 3 ? require('@/assets/img/date_label_selete.png') : require('@/assets/img/date_label_grey.png')"
              alt
            />
            <span :class="{active:activeTime == 3}">近90天</span>
          </li>
        </ul>
        <div class="value m-r-2">
          <el-date-picker
            style="width:260px"
            v-model="dateVal"
            type="daterange"
            :clearable="false"
            size="small"
            value-format="yyyy-MM-dd"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
          ></el-date-picker>
        </div>
        
        <el-button class="m-l-4" type="primary" size="small" @click="getTableData(2)">查询</el-button>
        <el-button size="small" @click="resetHandle">重置</el-button>
      </div>
    </div>

    <div class="table-content m-t-3">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">序号</div>
            <div class="th">单号</div>
            <div class="th">子单号</div>
            <div class="th">物料名称</div>
            <div class="th">一级分类</div>
            <div class="th">二级分类</div>
            <div class="th">出库单位</div>
            <div class="th">出库数量</div>
            <div class="th">异议数量</div>
            <div class="th">备注</div>
            <div class="th">状态</div>
            <div class="th">出库仓库</div>
            <div class="th">出库操作人</div>
            <div class="th">入库仓库</div>
            <div class="th">出库日期</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            layout="row"
            layout-align="space-between center"
            v-for="(item, index) in tableData"
            :key="item.id"
          >
            <div class="td">{{index + 1}}</div>
            <div class="td">{{item.cd}}</div>
            <div class="td">
              <span class="primary-link cursor" @click="showOrderDetailHandle(item)">{{item.id}}</span>
            </div>
            <div class="td">{{item.n}}</div>
            <div class="td">{{item.moc}}</div>
            <div class="td">{{item.mtc}}</div>
            <div class="td">{{item.un}}</div>
            <div class="td">{{item.c}}</div>
            <div class="td">{{item.yc}}</div>
            <div class="td">{{item.r}}</div>
            <div class="td">{{item.s}}</div>
            <div class="td">{{item.osn}}</div>
            <div class="td">{{item.oen}}</div>
            <div class="td">{{item.isn}}</div>
            <div class="td">{{item.ost}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
        <drawerDetail v-model="showDrawerDetail" :currentInfo="currentInfo" @getTableData="getTableData" />
      </div>
    </div>
    <div class="pagination m-t-2">
      <el-pagination
        background
        layout="prev, pager, next"
        :total="pageInfo.total"
        :page-size="pageInfo.pageSize"
        :current-page="pageInfo.page"
        @current-change="changePageHandle"
      ></el-pagination>
    </div>
  </div>
</template>
 
<script>
import drawerDetail from "./applyForOutLibCom/drawerDetail.vue";
import CharactersButton from "@/components/CharactersButton.vue";
export default {
  data() {
    return {
      orderStatus: 3,
      dateVal: [],
      tableData: [],
      pageInfo: {
        page: 1,
        pageSize: 20,
        total: 0
      },

      currentInfo: {},

      // 查看详情
      showDrawerDetail: false,
    };
  },
  methods: {
    async getTableData(isInit = 2) {
      const params = {
        page_num: this.pageInfo.page * 1,
        page_size: this.pageInfo.pageSize * 1, 
        status: this.orderStatus * 1, 
        begin_day: this.dateVal[0], 
        end_day: this.dateVal[1] 
      };

      try {
        const res = await this.$api.ERP.soutdd_yy.requestd_yyout_list(params);
        if (res.code == 1) {
          this.tableData = res.data.datas || [];
          this.pageInfo.total = res.data.row_cnt || 0;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("表格数据获取失败", error);
      }
    },
    
    showOrderDetailHandle(itemInfo) {
      this.currentInfo = {...itemInfo}
      this.showDrawerDetail = true
    },

    changePageHandle(page) {
      this.pageInfo.page = page
      this.getTableData()
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
      this.dateVal = [begin, end];
      this.getTableData(1);
    },

    resetHandle() {
      this.orderStatus = 3
      this.pageInfo.page = 1
      this.setDateVal(1);
    }
  },
  created() {
    this.resetHandle();
  },
  components: {
    drawerDetail,
    CharactersButton
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
    .order-status{
      li {
        padding: 6px 12px;
        border-radius: 6px;
        margin-right: 6px;
        border: 1px solid transparent;
        &.active {
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
  
  .btn-area {
    background-color: #eee;
  }

  .table-content {
    width: 100%;
    height: calc(100vh - 230px);
    overflow: auto;
    .table {
      width: 1800px;
      .thead {
        .th {
          background-color: #f5f5f5;
        }
      }
      .tbody {
        .tr{
          &:nth-child(2n) {
            .td {
              background-color: #f5f5f5;
            }
          }
          &:nth-child(2n + 1) {
            .td {
              background-color: #f9f9f9;
            }
          }
        }
      }
      .th,.td {
        &:nth-child(1) {
          position: sticky;
          left: 0;
          width: 500px;
        }
        &:nth-child(2) {
          position: sticky;
          left: 70px;
          width: 800px;
        }
        &:nth-child(3) {
          position: sticky;
          left: 178px;
          width: 1000px;
        }
        &:nth-child(4) {
          position: sticky;
          left: 310px;
          width: 1000px;
        }
        &:nth-child(15) {
          width: 70%;
        }
      }
    }
  }

  
  .pagination {
    float: right;
  }

  /deep/ .el-pagination.is-background .el-pager li:not(.disabled).active {
    background-color: #2170ff;
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