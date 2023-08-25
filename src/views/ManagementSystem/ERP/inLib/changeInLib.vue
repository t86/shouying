<template>
<!-- 调拨入库 -->
  <div class="empty-lib-order">
    <div class="top">
      <div class="m-b-3" layout="row" layout-align="start center">
        <span class="label fs14">状态：</span>
        <ul class="fs14 order-status" layout="row" layout-align="start center">
          <li @click="orderStatus = 0;getTableData()" :class="[orderStatus == 0 ? 'active cursor primary-link' : 'cursor']">全部</li>
          <li @click="orderStatus = 2;getTableData()" :class="[orderStatus == 2 ? 'active cursor primary-link' : 'cursor']">整单红冲</li>
          <li @click="orderStatus = 6;getTableData()" :class="[orderStatus == 6 ? 'active cursor primary-link' : 'cursor']">待入库</li>
          <li @click="orderStatus = 9;getTableData()" :class="[orderStatus == 9 ? 'active cursor primary-link' : 'cursor']">异议中</li>
          <li @click="orderStatus = 7;getTableData()" :class="[orderStatus == 7 ? 'active cursor primary-link' : 'cursor']">异议已处理</li>
          <li @click="orderStatus = 5;getTableData()" :class="[orderStatus == 5 ? 'active cursor primary-link' : 'cursor']">已完成</li>
        </ul>
      </div>
      <div layout="row" layout-align="start center">
        <span class="label fs14">入库日期：</span>
        <ul class="time-select fs14 m-r-1" layout="row" layout-align="start center">
          <li layout="row" layout-align="start center" @click="setDateVal(1)">
            <img
              :src="activeTime == 1 ? require('@/assets/img/日期标签-选中.png') : require('@/assets/img/日期标签-灰.png')"
              alt
            />
            <span :class="{active:activeTime == 1}">近7天</span>
          </li>
          <li layout="row" layout-align="start center" @click="setDateVal(2)">
            <img
              :src="activeTime == 2 ? require('@/assets/img/日期标签-选中.png') : require('@/assets/img/日期标签-灰.png')"
              alt
            />
            <span :class="{active:activeTime == 2}">近30天</span>
          </li>
          <li layout="row" layout-align="start center" @click="setDateVal(3)">
            <img
              :src="activeTime == 3 ? require('@/assets/img/日期标签-选中.png') : require('@/assets/img/日期标签-灰.png')"
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
        <span class="label fs14">出库仓库：</span>
        <el-select v-model="libType" size="small">
          <el-option label="全部" :value='0'></el-option>
          <el-option v-for="(item,i) in libOption" :key="i" :label="item.n" :value="item.id"></el-option>
        </el-select>

        <el-button class="m-l-4" type="primary" size="small" @click="getTableData(2)">查询</el-button>
        <el-button size="small" @click="resetHandle">重置</el-button>
      </div>
    </div>
    <div class="btn-area m-t-4" layout="row" layout-align="start center">
      <characters-button @click.native="applyForHandle" colors="#f5f5f5" wz="申请售后"></characters-button>
      <characters-button @click.native="allOrderInLibHandle" colors="#f5f5f5" wz="确认入库"></characters-button>
      <characters-button @click.native="someOrderInLibHandle" colors="#f5f5f5" wz="部分入库"></characters-button>
    </div>

    <div class="table-content">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">
              <el-checkbox
                v-model="checkAll"
                :indeterminate="isIndeterminate"
                @change="changeCheckboxHandle('all')"
              >全选</el-checkbox>
            </div>
            <div class="th">单号</div>
            <div class="th">入库仓库</div>
            <div class="th">出库仓库</div>
            <div class="th">入库成本</div>
            <div class="th">入库时间</div>
            <div class="th">入库操作人</div>
            <div class="th">出库时间</div>
            <div class="th">出库操作人</div>
            <div class="th">状态</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            :class="{'selected': item.checked}"
            layout="row"
            layout-align="space-between center"
            v-for="(item, index) in tableData"
            :key="item.id"
          >
            <div class="td" layout="row" layout-align="start center">
              <el-checkbox
                v-model="item.checked"
                @change="changeCheckboxHandle('item')"
              >{{index + 1}}</el-checkbox>
            </div>
            <div class="td">
              <span class="primary-link cursor" @click="showOrderDetailHandle(item)">{{item.cd}}</span>
            </div>
            <div class="td">{{item.isn}}</div>
            <div class="td">{{item.osn}}</div>
            <div class="td">{{item.ta}}</div>
            <div class="td">{{item.ist}}</div>
            <div class="td">{{item.ien}}</div>
            <div class="td">{{item.ost}}</div>
            <div class="td">{{item.oen}}</div>
            <div class="td">{{item.s}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
        <!-- 部分入库 -->
        <drawerSomeInLib v-model="showDrawerSomeOrderInLib" :currentInfo="currentInfo" @getTableData="getTableData" />
        <!-- 申请售后 -->
        <drawerApplyFor v-model="showDrawerApplyFor" :currentInfo="currentInfo" @getTableData="getTableData" />
        <drawerDetail v-model="showDrawerDetail" :currentInfo="currentInfo" @emitHandle="emitHandle" />
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
  </div>
</template>
 
<script>
import drawerSomeInLib from "./changeInLibCom/drawerSomeInLib.vue";
import drawerApplyFor from "./changeInLibCom/drawerApplyFor.vue";
import drawerDetail from "./changeInLibCom/drawerDetail.vue";
import CharactersButton from "@/components/CharactersButton.vue"; //根据路径导入组件
export default {
  data() {
    return {
      orderStatus: 0,
      activeTime: 1, // 1：近7天  2：近30天  3：近3个月
      dateVal: [],
      libType: 0,  // 出库仓库：
      libOption: [], // 出库仓库option
      checkAll: false,
      tableData: [],
      pageInfo: {
        page: 1,
        pageSize: 20,
        total: 0
      },

      currentInfo: {},

      // 部分入库
      showDrawerSomeOrderInLib: false,

      // 申请售后
      showDrawerApplyFor: false,

      // 查看详情
      showDrawerDetail: false,
    };
  },
  methods: {
    async getTableData(isInit = 2) {
      const params = {
        page_num: this.pageInfo.page * 1, //   int     第几页
        page_size: this.pageInfo.pageSize * 1, //  int    每页行数
        status: this.orderStatus * 1, //     int    状态 0 全部 5 已完成 2 红冲 6 待入库 7 异议已处理 9 异议待处理
        begin_day: this.dateVal[0], //  string  开始日期 格式  yyyy-mm-dd
        end_day: this.dateVal[1],  //    string  结束日期 格式 yyyy-mm-dd
        is_init: isInit, //     int   1 初始化,会返回仓库列表 2 非初始化
        out_store_id: this.libType * 1, // int   出库仓库id, 0 表示不限制
      };

      try {
        const res = await this.$api.ERP.sind.requestsindlist(params);
        if (res.code == 1) {
          this.tableData = (res.data.datas || []).map(item => ({
            ...item,
            checked: false
          }));
          this.checkAll = false;
          if(isInit == 1) this.libOption = res.data.stores || []
          this.pageInfo.total = res.data.row_cnt || 0;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("表格数据获取失败", error);
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
    // 申请售后
    applyForHandle(){
      const checkList = this.tableData.filter(item => item.checked)
      if(checkList.length != 1) return this.$message.warning('请选择一个订单')
      if(checkList[0].s != '已完成') return this.$message.warning('申请售后只可操作已完成订单')
      this.currentInfo = {...checkList[0]}
      this.showDrawerApplyFor = true
    },
    // 确认入库
    async allOrderInLibHandle(){
      const checkList = this.tableData.filter(item => item.checked)
      if(checkList.length <= 0) return this.$message.warning('请选择需要入库的订单')
      const params = {
        ids: checkList.map(item => item.id * 1)
      }
      try {
        const res = await this.$api.ERP.sind.requestsindbatch_in(params)
        if(res.code == 1){
          this.$message.success('操作成功')
          this.showDrawerDetail = false
          this.getTableData()
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('确认入库失败', error);
      }
    },
    // 部分入库
    someOrderInLibHandle(){
      const checkList = this.tableData.filter(item => item.checked)
      if(checkList.length != 1) return this.$message.warning('请选择一个需要入库的订单')
      this.currentInfo = {...checkList[0]}
      this.showDrawerSomeOrderInLib = true
    },

    emitHandle(type){
      switch (type) {
        case 1: 
          // 申请售后
          this.applyForHandle()
          break
        case 2: 
          // 2：确认入库
          this.allOrderInLibHandle()
          break
        case 3: 
          // 3：部分入库
          this.someOrderInLibHandle()
          break
      }
    },

    
    showOrderDetailHandle(itemInfo) {
      this.tableData = this.tableData.map(item => ({
        ...item,
        checked: item.id == itemInfo.id
      }))
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
      this.orderStatus = 0
      this.pageInfo.page = 1
      this.setDateVal(1);
      this.libType = 0
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
    drawerSomeInLib,
    drawerDetail,
    drawerApplyFor,
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
  .table {
    .tbody {
      height: calc(100vh - 330px);
      overflow: auto;
    }
    .th,.td {
      &:nth-child(1) {
        width: 30%;
      }
      &:nth-child(6),
      &:nth-child(8) {
        width: 70%;
      }
      &:nth-last-child(1) {
        width: 40%;
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