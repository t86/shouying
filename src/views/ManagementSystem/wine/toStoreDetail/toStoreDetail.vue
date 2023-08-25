<template>
  <!-- 充公出库单 -->
  <div class="to-store-detail">
    <div class="top" layout="row" layout-align="start center">
      <span class="label fs14">出库日期：</span>
      <ul class="time-select fs14 m-r-1" layout="row" layout-align="start center">
        <li layout="row" layout-align="start center" @click="setDateVal(1)">
          <img :src="activeTime == 1 ? require('@/assets/img/日期标签-选中.png') : require('@/assets/img/日期标签-灰.png')" alt />
          <span :class="{active:activeTime == 1}"> 近7天 </span> 
        </li>
        <li layout="row" layout-align="start center" @click="setDateVal(2)">
          <img :src="activeTime == 2 ? require('@/assets/img/日期标签-选中.png') : require('@/assets/img/日期标签-灰.png')" alt />
          <span :class="{active:activeTime == 2}">近30天</span>
        </li>
        <li layout="row" layout-align="start center" @click="setDateVal(3)">
          <img :src="activeTime == 3 ? require('@/assets/img/日期标签-选中.png') : require('@/assets/img/日期标签-灰.png')" alt />
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
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button size="small" @click="resetHandle">重置</el-button>
    </div>

    <div class="btn-area m-t-4">
      <el-button type="primary" size="small" @click="showHcDrawerHandle">红冲</el-button>
    </div>

    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">序号</div>
            <div class="th">单号</div>
            <div class="th">充公出库操作人</div>
            <div class="th">充公出库时间</div>
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
            <div class="td" layout="row" layout-align="center center">
              <div style="width: 60px;text-align:left">
                <el-checkbox
                  v-model="item.checked"
                  @change="changeCheckboxHandle(item)"
                >{{index + 1}}</el-checkbox>
              </div>
            </div>
            <div class="td">
              <span class="primary" @click="showDetailDrawerHandle(item)">{{item.id}}</span>
            </div>
            <div class="td">{{item.n}}</div>
            <div class="td">{{item.t}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
      <div class="pagination">
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

    <drawerHc v-model="showHcDrawer" :currentInfo="currentInfo" @getTableData="getTableData" />

    <drawerDetail v-model="showDetailDrawer" :currentInfo="currentInfo" />
  </div>
</template>
 
<script>
import api_wine from "@/api/wine";
import drawerHc from './drawerHC.vue'
import drawerDetail from './drawerDetail.vue'
export default {
  data() {
    return {
      activeTime: 1,  // 1：近7天  2：近30天  3：近3个月
      dateVal: [],
      tableData: [],
      pageInfo: {
        page: 1,
        pageSize: 20,
        total: 0
      },

      currentInfo: {},
      showHcDrawer: false,  // 显示红冲的drawer
      showDetailDrawer: false,  // 查看详情的drawer
    };
  },
  methods: {
    async getTableData() {
      const params = {
        start_day: this.dateVal[0], //  string   查询开始日期
        end_day: this.dateVal[1], //    string   查询结束日期
        page_num: this.pageInfo.page * 1, //   int  指定第几页
        page_size: this.pageInfo.pageSize  //  int  每页行数
      };

      try {
        const res = await api_wine.reqGetToStoreDetailList(params);
        if (res.code == 1) {
          this.tableData = (res.data.records || []).map(item => ({
            ...item,
            checked: false
          }));
          this.pageInfo.total = res.data.row_cn || 0;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("充公出库单列表获取失败", error);
      }
    },

    // 红冲
    showHcDrawerHandle(){
      const checkedInfoList = this.tableData.filter(item => item.checked)
      if(checkedInfoList.length <= 0) return this.$message.warning('请选择需要红冲的订单')
      this.currentInfo = checkedInfoList[0]
      this.showHcDrawer = true
    },

    // 查看详情
    showDetailDrawerHandle(itemInfo){
      this.currentInfo = {...itemInfo}
      this.showDetailDrawer = true
    },

    changeCheckboxHandle(itemInfo) {
      // 目前需求为单选
      this.tableData = this.tableData.map(item => ({
        ...item,
        checked: item.id == itemInfo.id ? item.checked : false
      }))
    },
    
    changePageHandle(page = 1) {
      this.pageInfo.page = page;
      this.getTableData();
    },

    getDate(dateNum = +new Date()){
      const date = new Date(dateNum);
      const year = date.getFullYear();
      const month = (date.getMonth() + 1).toString().padStart(2, 0);
      const day = date.getDate().toString().padStart(2, 0);
      return year + "-" + month + "-" + day;
    },

    setDateVal(activeTime) {
      this.activeTime = activeTime
      const dayInfo = {
        '1': 7,
        '2': 30,
        '3': 90
      }
      const oneDay = +new Date('2023/05/24') - +new Date('2023/05/23')
      const begin = this.getDate(+new Date() - oneDay * dayInfo[activeTime])
      const end = this.getDate()
      this.dateVal = [begin, end];
      this.getTableData();
    },

    resetHandle() {
      this.setDateVal(1)
    }
  },
  created() {
    this.resetHandle();
  },
  components: {
    drawerHc,
    drawerDetail
  }
};
</script>

<style lang="less" scoped>
@import "../../../../style/wine/table.less";
</style>
<style scoped lang="less">
.to-store-detail {
  padding: 20px;
  .top {
    flex-wrap: wrap;
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
      height: calc(100vh - 280px);
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