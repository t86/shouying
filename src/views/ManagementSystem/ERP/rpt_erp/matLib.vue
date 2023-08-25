<template>
  <div class="erp-lib">
    <div class="top m-b-3" layout="row" layout-align="start center">
      <div class="coll" layout="row" layout-align="start center">
        <span class="label fs14">日期：</span>
        <el-date-picker
          v-model="dateVal"
          style="width:220px"
          type="daterange"
          size="small"
          value-format="yyyy-MM-dd"
          range-separator="至"
          start-placeholder="开始日期"
          end-placeholder="结束日期"
          >
        </el-date-picker>
        <div class="label fs14 m-l-3">仓库名称：</div>
        <div class="value">
          <el-select style="width:160px" v-model="libVal" size="small" placeholder="请选择">
            <el-option
              v-for="item in libOption"
              :key="item.id"
              :label="item.n"
              :value="item.id"
            ></el-option>
          </el-select>
        </div>
      </div>
      <el-input v-model="keyword" size="small" style="width:200px;margin: 0 10px" placeholder="物料名称或简写"></el-input>
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button type="primary" size="small" @click="resetHandle">重置</el-button>
      <el-button type="primary" size="small" @click="exportExcelHandle">导出Excel</el-button>
    </div>

    <div class="table-content">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">序号</div>
            <div class="th">仓库</div>
            <div class="th">物料名称</div>
            <div class="th">单位</div>
            <div class="th">一级分类</div>
            <div class="th">二级分类</div>
            <div class="th">上期结存数量</div>
            <div class="th">上期结存金额</div>
            <div class="th">入库数量</div>
            <div class="th">入库金额</div>
            <div class="th">出库数量</div>
            <div class="th">出库成本金额</div>
            <div class="th">出库销售金额</div>
            <div class="th">本期结存数量</div>
            <div class="th">本期加权单价</div>
            <div class="th">本期结存金额</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" layout="row" layout-align="space-between center" v-for="(item, index) in tableData" :key="item.id">
            <div class="td">{{index + 1}}</div>
            <div class="td">{{item.sn}}</div>
            <div class="td">{{item.n}}</div>
            <div class="td">{{item.un}}</div>
            <div class="td">{{item.moc}}</div>
            <div class="td">{{item.mtc}}</div>
            <div class="td">{{item.pc}}</div>
            <div class="td">{{item.pa}}</div>
            <div class="td">{{item.ic}}</div>
            <div class="td">{{item.ia}}</div>
            <div class="td">{{item.oc}}</div>
            <div class="td">{{item.oa}}</div>
            <div class="td">{{item.os}}</div>
            <div class="td">{{item.c}}</div>
            <div class="td">{{item.p}}</div>
            <div class="td">{{item.a}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img src="@/assets/img/wu.png" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      dateVal: ['', ''],
      libVal: 0,
      libOption: [],
      keyword: '',
      tableData: []
    };
  },
  methods: {
    async getOption() {
      try {
        const res = await this.$api.ERP.rpt_erp.requestrpt_erpparam_items()
        if(res.code == 1) {
          this.libOption = [{
            id: 0,
            n: '全部'
          }, ...(res.data.stores || [])]
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取仓库列表option失败');
      }
    },

    async getTableData() {
      const params = {
        start_day: this.dateVal[0],
        end_day: this.dateVal[1],
        store_id: this.libVal * 1, //   int64    仓库id , 0 表示全部
        name: this.keyword || "" //  string   模糊查询关键字, 物料名称或简称 , 空, 表示不限制
      };
      try {
        const res = await this.$api.ERP.rpt_erp.requestrpt_erpmonth_invs(params)
        if(res.code == 1) {
          this.tableData = res.data.records || []
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("获取表格数据失败", error);
      }
    },

    async exportExcelHandle(){
      const params = {
        start_day: this.dateVal[0],
        end_day: this.dateVal[1],
        store_id: this.libVal * 1, //   int64    仓库id , 0 表示全部
        name: this.keyword || "" //  string   模糊查询关键字, 物料名称或简称 , 空, 表示不限制
      };
      try {
        const res = await this.$api.ERP.rpt_erp.reqExportOutMatLib(params)
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

    resetHandle() {
      this.libVal = 0
      this.keyword = ''
      this.dateVal = [this.getDate(), this.getDate()]
      this.getOption()
      this.getTableData()
    }
  },
  created() {
    this.resetHandle()
  },
  components: {},
  filters: {}
};
</script>

<style lang="less" scoped>
@import '../../../../style/erp/table.less';
</style>
<style scoped lang="less">
.erp-lib{
  padding: 20px;
  .table-content {
    width: 100%;
    height: calc(100vh - 160px);
    overflow: auto;
    .table{
      width: 1700px;
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
          width: 300px;
          position: sticky;
          left: 0;
        }
        &:nth-child(2) {
          width: 800px;
          position: sticky;
          left: 45px;
        }
        &:nth-child(3) {
          width: 1200px;
          position: sticky;
          left: 152px;
        }
        &:nth-child(4){
          width: 300px;
          position: sticky;
          left: 307px;
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