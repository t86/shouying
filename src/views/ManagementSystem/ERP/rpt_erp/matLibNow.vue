<template>
  <div class="erp-lib">
    <div class="top m-b-3" layout="row" layout-align="start center">
      <div class="coll" layout="row" layout-align="start center">
        <div class="label fs14">仓库名称：</div>
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
            <div class="th">库存数量</div>
            <div class="th">实时加权单价</div>
            <div class="th">成本金额小计</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" layout="row" layout-align="space-between center" v-for="(item, index) in tableData" :key="item.id">
            <div class="th">{{index + 1}}</div>
            <div class="th">{{item.sn}}</div>
            <div class="th">{{item.n}}</div>
            <div class="th">{{item.un}}</div>
            <div class="th">{{item.moc}}</div>
            <div class="th">{{item.mtc}}</div>
            <div class="th">{{item.c}}</div>
            <div class="th">{{item.p}}</div>
            <div class="th">{{item.a}}</div>
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
      libVal: 0,
      libOption: [],
      keyword: '',
      tableData: []
    };
  },
  methods: {
    async getTableData() {
      const params = {
        store_id: this.libVal * 1, //   int64    仓库id , 0 表示全部
        name: this.keyword || "" //  string   模糊查询关键字, 物料名称或简称 , 空, 表示不限制
      };
      try {
        const res = await this.$api.ERP.erpLib.getLibList(params)
        if(res.code == 1) {
          this.libOption = [{
            id: 0,
            n: '全部'
          }, ...(res.data.stores || [])]
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
        store_id: this.libVal * 1, //   int64    仓库id , 0 表示全部
        name: this.keyword || "" //  string   模糊查询关键字, 物料名称或简称 , 空, 表示不限制
      };
      try {
        const res = await this.$api.ERP.erpLib.exportExcelLibList(params)
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

    resetHandle() {
      this.libVal = 0
      this.keyword = ''
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
  .table{
    .th,.td {
      &:nth-child(1),
      &:nth-child(4){
        width: 30%;
      }
    }
    .tbody {
      height: calc(100vh - 200px);
      overflow: auto;
    }
  }
}
</style>