<template>
  <div class="day-report">
    <div class="header white p-l-4 p-r-4" layout="row" layout-align="space-between center">
      <span>挂账还款记录表</span>
      <i class="el-icon-close" @click="onClose"></i>
    </div>
    <div>
      <div class="top m-l-4 m-b-4" layout="row" layout-align="space-between center">
          <el-button
            type="primary"
            @click="exportExcel"
            style="width:90px;height:30px;line-height:30px;padding:0"
          >导出Excel</el-button>
      </div>
      <div class="table">
        <div class="thead">
          <!--
        o          string     //OperTime 操作时间
        a          string     //CnlAcctName 挂账账号
        e          string     //OperEmpName 操作人
        r          string     //RtnCnlName 还款渠道
        m          int64      //Amt 还款金额, 单位分, 需要前端做格式化
          -->
          <div class="tr" layout="row" layout-align="start center">
            <div class="th">序号</div>
            <div class="th">操作时间</div>
            <div class="th">挂账账号</div>
            <div class="th">操作人</div>
            <div class="th">还款渠道</div>
            <div class="th">还款金额</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            layout="row"
            layout-align="start center"
            v-for="(item, index) in tableData"
            :key="index"
          >
          <div class="td one-txt-cut">{{item.o}}</div>
          <div class="td one-txt-cut">{{item.a}}</div>
          <div class="td one-txt-cut">{{item.e}}</div>
          <div class="td one-txt-cut">{{item.r}}</div>
          <div class="td one-txt-cut">{{(item.m / 100).toFixed(2)}}</div>
          </div>
          <p v-if="tableData.length == 0" class="m-t-10 fs14" style="text-align:center">暂无数据</p>
        </div>
      </div>
    </div>
  </div>
</template>
 
<script>
import api_money from "@/api/money";
import mySelect from "@/components/book/select";
export default {
  data() {
    return {
      defaultProps: {
        label: 'n',
        children: 'ss'
      },
      tableData: [],
    };
  },
  methods: {

    onClose(){
      this.$emit('showOrHideSetGZHKDrawerHandle')
    },

    //  读取挂账还款记录
    async getTableData() {
      const res = await api_money.reqGetCnlAccountRtnList();
      if (res.code == 1) {
        this.tableData = res.data.records || []
      } else {
        this.$message.warning(res.msg);
      }
    },

    // 导出excel
    async exportExcel() {
      try {
        const res = await api_money.reqExpCnlAccountRtnList();
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
          a.setAttribute("download", decodeURIComponent(res.fileName)); // 下载文件的名称及文件类型后缀
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
  },
  async mounted() {
    await this.getTableData();
  },
  components: {
    mySelect
  },
};
</script>

<style scoped lang="less">
.day-report {
  background: #202C4A;
  // background: linear-gradient(180deg, #202C4A 0%, #2A3959 100%);

  .header {
    height: 48px;
    background:#222D47;
    // background: linear-gradient(180deg, #222D47 0%, #11182D 100%);
  }

  .table{
    border: 1px solid #999;
    border-radius: 10px;
    height: calc(100vh - 90px);
    overflow-y: auto;
    .tr{
      padding: 0 20px;
      box-sizing: border-box;
      height: 36px;
      line-height: 36px;
      font-size: 14px;
    }
    .thead{
      position: sticky;
      top: 0;
      background: #182037;
      // background: linear-gradient(180deg, #182037 0%, #11182D 100%);
      color: rgba(255, 255, 255, .5);
    }
    .tbody{
      color: rgba(255, 255, 255, .8);
      .tr:nth-child(2n){
        background-color: rgba(255, 255, 255, 0.04);
      }
    }

    .th:nth-child(1), .td:nth-child(1){
      width: 60px;
    }
    // 剩余几个th td平分宽度
    .th:nth-child(2), .td:nth-child(2),
    .th:nth-child(3), .td:nth-child(3),
    .th:nth-child(4), .td:nth-child(4),
    .th:nth-child(5), .td:nth-child(5){
      width: calc((100% - 60px) / 5);
    }

  }
}

/deep/.el-checkbox__label {
  color: #fff;
}

/deep/.select-com,
/deep/.options{
  border-color: #999!important;
}

/deep/.select-com,
/deep/.options li {
  font-size: 14px;
  height: 28px;
  line-height: 28px;
}

/deep/.el-tree__empty-block {
  background-color: #202C4A;
}

/deep/.el-tree__empty-text {
  color: rgba(255, 255, 255, 0.8);
}
/deep/.el-tree {
  background-color: #202C4A;
  color: rgba(255, 255, 255, 0.8);
}

/deep/.el-tree-node__content:hover, .el-upload-list__item:hover {
  background-color: rgba(30, 30, 30, 0.8);
}
</style>