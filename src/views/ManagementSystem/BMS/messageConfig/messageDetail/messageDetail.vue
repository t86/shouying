<template>
  <div class="message-detail">
    <div class="top" layout="row" layout-align="start center">
      <div class="label fs14">日期：</div>
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
      <div class="label fs14">类型：</div>
      <el-select v-model="selectVal" size="small" style="width:100px" placeholder="请选择">
        <el-option
          v-for="item in options"
          :key="item.value"
          :label="item.label"
          :value="item.value"
        ></el-option>
      </el-select>
      <el-button class="m-l-3" type="primary" size="small" @click="getTableData(1)">查询</el-button>
      <el-button size="small" @click="resetHandle">重置</el-button>
    </div>

    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">日期</div>
            <div class="th">类型</div>
            <div class="th">金额</div>
            <div class="th">短信数量(条)</div>
            <div class="th">剩余金额</div>
            <div class="th">剩余短信数量(条)</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" v-for="(item) in tableData" :key="item.id" layout="row" layout-align="space-between center">
            <div class="td">
              <span v-if="item.t=='消费'" class="primary-link cursor" @click="showDetailInfoHandle(item)">{{item.d}}</span>
              <span v-else class="primary-link cursor" @click="showDetailInfoHandle(item)">{{item.d}}</span>
            </div>
            <div class="th">{{item.t}}</div>
            <div class="td">{{item.a}}</div>
            <div class="td">{{item.sc}}</div>
            <div class="td">{{item.b}}</div>
            <div class="td">{{item.bc}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img src="@/assets/img/wu.png" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>
    <div class="fr m-t-4">
      <el-pagination
        background
        layout="prev, pager, next"
        @current-change="changePageHandle"
        :page-size="pageInfo.pageSize"
        :total="pageInfo.total">
      </el-pagination>
    </div>

    <drawerDetailInfo v-model="showDetailInfoDrawer" :currentInfo="currentInfo" />
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      dateVal: [],
      selectVal: 0,
      options:[{
        label: '全部',
        value: 0
      },{
        label: '充值',
        value: 1
      },{
        label: '消费',
        value: 2
      }],
      tableData: [],
      pageInfo: {
        page: 1,
        pageSize: 20,
        total: 0
      },
      showDetailInfoDrawer: false,
      currentInfo: {}
    };
  },
  methods: {
    async getTableData(init) {
      if(init == 1) {
        this.pageInfo.page = 1
      }
      const params = {
        page_num: this.pageInfo.page * 1, //   int    指定第几页
        page_size: this.pageInfo.pageSize, //  int     每页行数
        start_biz_day: this.dateVal[0], // string    开始日期
        end_biz_day: this.dateVal[1], // string   结束日期
        type_id: this.selectVal * 1, //    int     0全部 1 充值 2 消费
      };

      try {
        const res = await this.$api.BMS.messageConfig.reqGetMsgDayData(params)
        if (res.code == 1) {
          this.pageInfo.total = res.data.row_cnt || 0
          this.tableData = res.data.records || []
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("列表数据获取失败", error);
      }
    },

    
    changePageHandle(page) {
      this.pageInfo.page = page
      this.getTableData()
    },

    showDetailInfoHandle(itemInfo){
      this.currentInfo = {...itemInfo}
      this.showDetailInfoDrawer = true
    },

    resetHandle() {
      const date = new Date()
      const year = date.getFullYear();
      const month = (date.getMonth() + 1).toString().padStart(2, 0);
      const day = date
        .getDate()
        .toString()
        .padStart(2, 0);
      const begin = year + '-' + month + '-01'
      const now = year + "-" + month + "-" + day;
      this.dateVal = [begin, now];
      this.selectVal = 0
      this.pageInfo.page = 1
      this.getTableData(1)
    }
  },
  created() {
    this.resetHandle();
  },
  components: {
    drawerDetailInfo: () => import('./drawerDetailInfo.vue')
  }
};
</script>

<style lang="less" scoped>
@import "../../../../../style/wine/table.less";
</style>
<style scoped lang="less">
.message-detail {
  padding: 20px;
  .table-content {
    width: 100%;
    .table {
      min-width: 100%;
      height: calc(100vh - 220px);
      overflow: auto;
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