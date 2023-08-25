<template>
  <!-- 存酒查询 -->
  <div class="save-search">
    <div class="top" layout="row" layout-align="start center">
      <div class="item m-r-2" layout="row" layout-align="start center">
        <div class="label fs14 m-l-6">查询类型：</div>
        <div class="value">
          <el-select style="width:120px" size="small" v-model="selectVal" placeholder="请选择">
            <el-option
              v-for="item in options"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            ></el-option>
          </el-select>
        </div>
      </div>

      <el-select
        v-if="selectVal == 2"
        style="width:200px"
        class="m-r-2"
        size="small"
        v-model="selectEmpVal"
        placeholder="请输入员工工号/姓名"
        filterable
        remote
        reserve-keyword
        :loading="loading"
        :remote-method="remoteMethodHandle"
      >
        <el-option
          v-for="item in empOption"
          :key="item.id"
          :label="item.n"
          :value="item.id"
        ></el-option>
      </el-select>

      <el-input
        v-else
        v-model="keyword"
        style="width:200px"
        class="m-r-2"
        size="small"
        :placeholder="selectVal == 1 ? '请输入完整存酒流水号' : '请输入客人手机号'"
      ></el-input>
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button size="small" @click="resetHandle">重置</el-button>
      <el-button type="primary" size="small" @click="exportExcelHandle">导出</el-button>
    </div>

    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">操作类型</div>
            <div class="th">酒水名称</div>
            <div class="th">规格</div>
            <div class="th">每瓶克数</div>
            <div class="th">操作前数量</div>
            <div class="th">操作数量</div>
            <div class="th">操作后库存数量</div>
            <div class="th">存酒流水号</div>
            <div class="th">操作时间</div>
            <div class="th">操作人</div>
            <div class="th">客户姓名</div>
            <div class="th">手机号</div>
            <div class="th">订位人</div>
            <div class="th">卡台</div>
            <div class="th">服务员</div>
            <div class="th">备注姓名</div>
            <div class="th">备注手机号</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            layout="row"
            layout-align="space-between center"
            v-for="(item, index) in tableData"
            :key="index"
          >
            <div class="td">{{item.t}}</div>
            <div class="td">{{item.p}}</div>
            <div class="td">{{item.u}}</div>
            <div class="td">{{item.g}}</div>
            <div class="td">{{item.bc}}</div>
            <div class="td">{{item.c}}</div>
            <div class="td">{{item.ac}}</div>
            <div class="td" style="user-select: text;">{{item.i}}</div>
            <div class="td">{{item.o}}</div>
            <div class="td">{{item.oe}}</div>
            <div class="td">{{item.cn}}</div>
            <div class="td">{{item.cp}}</div>
            <div class="td">{{item.se}}</div>
            <div class="td">{{item.s}}</div>
            <div class="td">{{item.w}}</div>
            <div class="td">{{item.rn}}</div>
            <div class="td">{{item.rp}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
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
</template>
 
<script>
import api_wine from "@/api/wine";
export default {
  data() {
    return {
      selectVal: 1,
      options: [
        {
          value: 1,
          label: "存酒流水号"
        },
        {
          value: 2,
          label: "订位人"
        },
        {
          value: 3,
          label: "客人手机号"
        }
      ],
      loading: false,
      selectEmpVal: "",
      empOption: [],
      keyword: "",
      tableData: [],

      pageInfo: {
        page: 1,
        pageSize: 20,
        total: 0
      }
    };
  },
  methods: {
    async getTableData() {

      if(this.selectVal == 1) {
        if(isNaN(this.keyword * 1)) {
          return this.$message.warning('流水号存在非数字')
        }
        if(this.keyword.toString().length == 0) {
          return this.$message.warning('请输入流水号')
        }
      } 

      if(this.selectVal == 2 && this.selectEmpVal == 0) return this.$message.warning('请输入订位人')
      if(this.selectVal == 3 && (isNaN(this.keyword * 1) || this.keyword.toString().length != 11)) return this.$message.warning('请输入正确手机号')

      const params = {
        page_num: this.pageInfo.page * 1, //   int   第几页
        page_size: this.pageInfo.pageSize, //  int    每页行数
        type_id: this.selectVal * 1, //  int   查询模式 1 存酒流水号 2 订位人 3 客人手机号
        invt_id: this.selectVal == 1 ? this.keyword * 1 : 0, //    int64   存酒流水号,模式为2,3时填0
        sales_emp_id: this.selectVal == 2 ? this.selectEmpVal * 1 : 0, // int64   订位人,模式为1,3时,填0
        cust_phone_num: this.selectVal == 3 ? this.keyword : "" // string  客人手机号,模式为1,2时,填空
      };

      try {
        const res = await api_wine.reqSaveSearchReportList(params);
        if (res.code == 1) {
          this.tableData = res.data.records || []
          this.pageInfo.total = res.data.row_cn || 0;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("存酒查询列表数据获取失败", error);
      }
    },

    
    async exportExcelHandle(){

      if(this.selectVal == 1) {
        if(isNaN(this.keyword * 1)) {
          return this.$message.warning('流水号存在非数字')
        }
        if(this.keyword.toString().length == 0) {
          return this.$message.warning('请输入流水号')
        }
      } 

      if(this.selectVal == 2 && this.selectEmpVal == 0) return this.$message.warning('请输入订位人')
      if(this.selectVal == 3 && (isNaN(this.keyword * 1) || this.keyword.toString().length != 11)) return this.$message.warning('请输入正确手机号')

      const params = {
        page_num: this.pageInfo.page * 1, //   int   第几页
        page_size: this.pageInfo.pageSize, //  int    每页行数
        type_id: this.selectVal * 1, //  int   查询模式 1 存酒流水号 2 订位人 3 客人手机号
        invt_id: this.selectVal == 1 ? this.keyword * 1 : 0, //    int64   存酒流水号,模式为2,3时填0
        sales_emp_id: this.selectVal == 2 ? this.selectEmpVal * 1 : 0, // int64   订位人,模式为1,3时,填0
        cust_phone_num: this.selectVal == 3 ? this.keyword : "" // string  客人手机号,模式为1,2时,填空
      };

      try {
        const res = await api_wine.reqExportExcelOfSaveSearchReport(params);
        if (!res.msg) {
          const url = window.URL.createObjectURL(
            new Blob([res], {
              type:
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            })
          );
          const a = document.createElement("a"); //添加a标签
          document.body.appendChild(a);
          a.href = url;
          a.setAttribute("download", res.fileName); // 下载文件的名称及文件类型后缀
          a.click(); //点击标签
          document.body.removeChild(a); // 下载完成移除元素
          window.URL.revokeObjectURL(url); // 释放掉blob对象
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("导出excel失败", error);
      }
    },

    async getEmpList(query=""){
      const params = {
        page_num: 1, //   int    第几页
        page_size: 9999999, //  int   每页行数
        name: query  //  string   模糊查询关键字
      }
      try {
        const res = await api_wine.reqGetEmpList(params)
        if(res.code == 1) {
          this.empOption = res.data.records || []
        } else {
          this.$message.warning(res.msg)
        }
        this.loading = false
      } catch (error) {
        console.log('模糊查询订位人失败', error)
      }
    },

    remoteMethodHandle(query) {
      if (query !== "") {
        this.loading = true
        this.getEmpList(query)
      } else {
        this.empOption = [];
      }
    },

    changePageHandle(page = 1) {
      this.pageInfo.page = page;
      this.getTableData();
    },

    resetHandle() {
      this.selectVal = 1;
      this.keyword = "";
      this.selectEmpVal = ''
      this.tableData = []
    }
  },
  watch: {
    selectVal(){
      this.keyword = ''
      this.selectEmpVal = ''
    }
  }
};
</script>

<style lang="less" scoped>
@import "../../../../style/wine/table.less";
</style>
<style scoped lang="less">
.save-search {
  padding: 20px;

  .table-content {
    position: relative;
    width: 100%;
    height: calc(100vh - 200px);
    overflow: auto;
    .table {
      min-width: 2350px;
      .thead{
        position: sticky;
        z-index: 10;
        .th {
          font-size: 15px;
          background-color: #eee;
        }
      }
      .tbody {
        .tr {
          height: 40px;
          font-size: 15px;
          &:nth-child(2n) {
            .td:nth-child(1),
            .td:nth-child(2){
              background-color: #f5f5f5;
            }
          }
          &:nth-child(2n + 1) {
            .td:nth-child(1),
            .td:nth-child(2){
              background-color: #f9f9f9;
            }
          }
        }
      }
      .th,.td {
        padding: 0 10px;
        
        &:nth-child(1){
          position: sticky;
          left: 0;
          z-index: 1;
        }
        &:nth-child(2){
          position: sticky;
          left: 151px;
          z-index: 1;
        }

        &:nth-child(3),
        &:nth-child(4),
        &:nth-child(5),
        &:nth-child(6),
        &:nth-child(10),
        &:nth-child(11),
        &:nth-child(13),
        &:nth-child(15){
          width: 40%;
        }
      }
    }
  }

  .pagination{
    margin-top: 10px;
    float: right;
  }
}
</style>


<style>
.el-select-dropdown__empty{
  background-color: #f5f5f5!important;
}
</style>