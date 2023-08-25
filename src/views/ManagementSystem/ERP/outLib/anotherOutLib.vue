<template>
<!-- 其他入库 -->
  <div class="empty-lib-order">
    <div class="top">
      <div layout="row" layout-align="start center">
        <span class="label fs14">出库日期：</span>
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
      </div>
      <div class="m-t-2" layout="row" layout-align="start center">
        <span class="label fs14">出库类型：</span>
        <el-select v-model="outLibType" size="small">
          <el-option label="全部" :value='0'></el-option>
          <el-option label="销售出库" :value="11"></el-option>
          <el-option label="其他出库" :value="17"></el-option>
          <el-option label="盘亏出库" :value="52"></el-option>
          <el-option label="报损出库" :value="62"></el-option>
        </el-select>
        <span class="label fs14 m-l-4">备注：</span>
        <el-input v-model="keyword" size="small" style="width:200px" placeholder="请输入备注模糊搜索"></el-input>

        <el-button class="m-l-4" type="primary" size="small" @click="getTableData">查询</el-button>
        <el-button size="small" @click="resetHandle">重置</el-button>
      </div>
    </div>
    <div class="btn-area m-t-4" layout="row" layout-align="start center">
      <icon-button @click.native="addHandle(1)" text="新增" img="添加.png" colors="#f5f5f5"></icon-button>
      <characters-button @click.native="hcHandle(1)" colors="#f5f5f5" wz="红冲"></characters-button>
      <characters-button @click.native="hcHandle(2)" colors="#f5f5f5" wz="红冲整单"></characters-button>
      <characters-button @click.native="addHandle(2)" colors="#f5f5f5" wz="类似创建"></characters-button>
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
            <div class="th">出库类型</div>
            <div class="th">出库仓库</div>
            <div class="th">出库成本</div>
            <div class="th">出库总额</div>
            <div class="th">备注</div>
            <div class="th">出库时间</div>
            <div class="th">出库操作人</div>
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
            <div class="td">{{item.rt}}</div>
            <div class="td">{{item.sn}}</div>
            <div class="td">{{item.ta}}</div>
            <div class="td">{{item.sa}}</div>
            <div class="td">{{item.r}}</div>
            <div class="td">{{item.st}}</div>
            <div class="td">{{item.en}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
        <drawerAdd v-model="showDrawerAdd" :type="addType" :currentInfo="currentInfo" @getTableData="getTableData" /> 
        <drawerHC v-model="showDrawerHc" :currentInfo="currentInfo" @getTableData="getTableData" />
        <drawerDetail v-model="showDrawerDetail" :currentInfo="currentInfo" @getTableData="getTableData" @emitHandle="emitHandle" />
      </div>
      <div class="pagination m-t-6">
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
import drawerAdd from "./anotherInOutCom/drawerAddOutLib.vue";
import drawerHC from "./anotherInOutCom/drawerHc.vue";
import drawerDetail from "./anotherInOutCom/drawerDetail.vue";
import IconButton from "@/components/IconButton.vue"; //根据路径导入组件
import CharactersButton from "@/components/CharactersButton.vue"; //根据路径导入组件
export default {
  data() {
    return {
      activeTime: 1, // 1：近7天  2：近30天  3：近3个月
      dateVal: [],
      outLibType: 0,  // 入库类型
      keyword: '', // 备注模糊查询
      checkAll: false,
      tableData: [],
      pageInfo: {
        page: 1,
        pageSize: 20,
        total: 0
      },

      // 新增
      showDrawerAdd: false,
      addType: 1,  // 1:新增  2：类似创建

      currentInfo: {}, // 勾选上的的表格基础数据(用于类似创建、查看详情和红冲)

      // 红冲
      showDrawerHc: false,

      // 查看详情
      showDrawerDetail: false,
    };
  },
  methods: {
    async getTableData() {
      const params = {
        begin_day: this.dateVal[0], //  string   查询开始日期
        end_day: this.dateVal[1], //    string   查询结束日期
        remark: this.keyword || '',
        record_type: this.outLibType * 1,
        page_num: this.pageInfo.page * 1, //   int  指定第几页
        page_size: this.pageInfo.pageSize, //  int  每页行数
      };

      try {
        const res = await this.$api.ERP.sout.requestsoutlist(params);
        if (res.code == 1) {
          this.tableData = (res.data.datas || []).map(item => ({
            ...item,
            checked: false
          }));
          this.checkAll = false;
          this.pageInfo.total = res.data.row_cnt || 0;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("其他入库表格数据获取失败", error);
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

    // 创建/类似创建
    addHandle(type) {
      // type: 1:新增  2：类似创建
      if(type == 2) {
        const checkedList = this.tableData.filter(item => item.checked)
        if(checkedList.length != 1) return this.$message.warning('请选择一个进行操作')
        this.currentInfo = {...checkedList[0]}
      }
      this.showDrawerAdd = true
      this.addType = type
    },

    hcHandle(type) {
      // type:1:红冲  2：整单红冲
      const checkList = this.tableData.filter(item => item.checked)
      if(checkList.length != 1) return this.$message.warning("请选择一个进行操作");
      if(type == 2) {
        return this.hcAllOrder(checkList)
      }
      this.currentInfo = {...checkList[0]}
      this.showDrawerHc = true
    },

    // 用于详情中类似创建/红冲/红冲整单
    emitHandle(type) {
      switch (type) {
        case 1: 
          // 类似创建
          this.addHandle(2)
          break
        case 2: 
          // 红冲
          this.hcHandle(1)
          break
        case 3: 
          // 红冲整单
          this.hcHandle(2)
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

    async hcAllOrder(checkList) {
      const params = {
        id: checkList[0].id * 1
      }
      try {
        const res = await this.$api.ERP.sout.requestsoutcs(params)
        if(res.code == 1) {
          this.$message.success('红冲整单成功')
          this.getTableData()
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('红冲整单失败', error);
      }
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
      this.getTableData();
    },

    resetHandle() {
      this.pageInfo.page = 1
      this.setDateVal(1);
      this.outLibType = 0
      this.keyword = ''
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
    drawerHC,
    drawerAdd,
    drawerDetail,
    IconButton,
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
      height: calc(100vh - 350px);
      overflow: auto;
    }
    .th,.td {
      &:nth-child(1) {
        width: 30%;
      }
      &:nth-child(8) {
        width: 70%;
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