<template>
<!-- 调拨入库 -->
  <div class="empty-lib-order">
    <div class="top">
      <div class="m-b-3" layout="row" layout-align="start center">
        <span class="label fs14">状态：</span>
        <ul class="fs14 order-status" layout="row" layout-align="start center">
          <li @click="orderStatus = 0;getTableData()" :class="[orderStatus == 0 ? 'active cursor primary-link' : 'cursor']">全部</li>
          <li @click="orderStatus = 2;getTableData()" :class="[orderStatus == 2 ? 'active cursor primary-link' : 'cursor']">整单红冲</li>
          <li @click="orderStatus = 6;getTableData()" :class="[orderStatus == 6 ? 'active cursor primary-link' : 'cursor']">待收获</li>
          <li @click="orderStatus = 7;getTableData()" :class="[orderStatus == 7 ? 'active cursor primary-link' : 'cursor']">异议中</li>
          <li @click="orderStatus = 9;getTableData()" :class="[orderStatus == 9 ? 'active cursor primary-link' : 'cursor']">异议已处理</li>
          <li @click="orderStatus = 5;getTableData()" :class="[orderStatus == 5 ? 'active cursor primary-link' : 'cursor']">已完成</li>
        </ul>
      </div>
      <div layout="row" layout-align="start center">
        <span class="label fs14">出库日期：</span>
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
          <el-date-picker style="width:140px" v-model="begin_day" type="date" :clearable="false" size="small"
            value-format="yyyy-MM-dd" placeholder="开始日期"></el-date-picker>
          <span>至</span>
          <el-date-picker style="width:140px" v-model="end_day" type="date" :clearable="false" size="small"
            value-format="yyyy-MM-dd" placeholder="结束日期"></el-date-picker>
        </div>
      </div>
      <div class="m-t-2" layout="row" layout-align="start center">
        <span class="label fs14">出库仓库：</span>
        <el-select v-model="libType" size="small">
          <el-option label="全部" :value='0'></el-option>
          <el-option v-for="(item,i) in libOption" :key="i" :label="item.n" :value="item.id"></el-option>
        </el-select>

        <span class="label fs14 m-l-3">备注：</span>
        <el-input v-model="remark" size="small" style="width:200px" placeholder="请输入备注模糊搜索"></el-input>

        <el-button class="m-l-4" type="primary" size="small" @click="getTableData(2)">查询</el-button>
        <el-button size="small" @click="resetHandle">重置</el-button>
      </div>
    </div>
    <div class="btn-area m-t-4" layout="row" layout-align="start center">
      <icon-button @click.native="addHandle(1)" text="新增" img="btn_add.png" colors="#f5f5f5"></icon-button>
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
            <div class="th">出库仓库</div>
            <div class="th">入库仓库</div>
            <div class="th">出库成本</div>
            <div class="th">状态</div>
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
            <div class="td">{{item.osn}}</div>
            <div class="td">{{item.isn}}</div>
            <div class="td">{{item.ta}}</div>
            <div class="td">{{item.s}}</div>
            <div class="td">{{item.r}}</div>
            <div class="td">{{item.ost}}</div>
            <div class="td">{{item.oen}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
        
        <drawerAdd v-model="showDrawerAdd" :isFirstLoad.sync="isFirstLoad" :type="addType" :paramsPrdList="paramsPrdList" :currentInfo="currentInfo" @getTableData="getTableData" /> 
        <drawerHC v-model="showDrawerHc" :currentInfo="currentInfo" @getTableData="getTableData" />
        <drawerDetail v-model="showDrawerDetail" :currentInfo="currentInfo" @getTableData="getTableData" @emitHandle="emitHandle" />
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
  </div>
</template>
 
<script>
import drawerAdd from "./changeOutLibCom/drawerAddOutLib.vue";
import drawerHC from "./changeOutLibCom/drawerHc.vue";
import drawerDetail from "./changeOutLibCom/drawerDetail.vue";
import IconButton from "@/components/IconButton.vue"; //根据路径导入组件
import CharactersButton from "@/components/CharactersButton.vue"; //根据路径导入组件
export default {
  data() {
    return {
      orderStatus: 0,
      activeTime: 1, // 1：近7天  2：近30天  3：近3个月
      begin_day: "",
      end_day: "",
      libType: 0,  // 出库仓库：
      libOption: [], // 出库仓库option
      remark: '',
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

      // 从首页跳转过来的参数
      paramsPrdList: [],
      isFirstLoad: true
    };
  },
  methods: {
    async getTableData(isInit = 2) {
      const params = {
        page_num: this.pageInfo.page * 1, //   int     第几页
        page_size: this.pageInfo.pageSize * 1, //  int    每页行数
        status: this.orderStatus * 1, //     int    状态 0 全部 5 已完成 2 红冲 6 待入库 7 异议已处理 9 异议待处理
        begin_day: this.begin_day, //  string   查询开始日期
        end_day: this.end_day, //    string  结束日期 格式 yyyy-mm-dd
        is_init: isInit, //     int   1 初始化,会返回仓库列表 2 非初始化
        in_store_id: this.libType * 1, // int   出库仓库id, 0 表示不限制
        remark: this.remark || ''
      };

      try {
        const res = await this.$api.ERP.soutd.requestsoutdlist(params);
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

    // 整单红冲
    async hcAllOrder(checkList){
      const params = {
        id: checkList[0].id * 1
      }
      try {
        const res = await this.$api.ERP.soutd.requestsoutdcs(params)
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

    emitHandle(type){
      switch (type) {
        case 1: 
        // 类似创建
        this.addHandle(2)
          break
        case 2: 
        // 2：红冲 
        this.hcHandle(2)
          break
        case 3: 
        // 3：整单红冲
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
      this.begin_day = begin;
      this.end_day = end;
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
    if(this.$route.query.itemObj){
      // 从首页跳转过来
      this.paramsPrdList = JSON.parse(this.$route.query.itemObj)
      this.addHandle(1)
    }
    this.resetHandle();
  },
  computed: {
    isIndeterminate() {
      return !this.checkAll && this.tableData.some(item => item.checked);
    }
  },
  components: {
    drawerAdd,
    drawerHC,
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
      height: calc(100vh - 380px);
      overflow: auto;
    }
    .th,.td {
      &:nth-child(1) {
        width: 30%;
      }
      &:nth-child(6){
        width: 40%;
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