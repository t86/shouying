<template>
  <div class="day-report">
    <div class="header white p-l-4 p-r-4" layout="row" layout-align="space-between center">
      <span>{{ showDetail ? '客人预订金余额表' : '预订金流水详情' }}</span>
      <i class="el-icon-close" @click="onClose"></i>
    </div>
    <div>
      <div v-if="showDetail">
        <div class="top m-l-4 m-b-4" layout="row" layout-align="start center">
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
              <div class="th">卡台名称</div>
              <div class="th">客人姓名</div>
              <div class="th">联系方式</div>
              <div class="th">类型名称</div>
              <div class="th">预订日期</div>
              <div class="th">操作时间</div>
              <div class="th">操作金额</div>
              <div class="th">操作前余额</div>
              <div class="th">操作后余额</div>
            </div>
          </div>
          <div class="tbody">
            <div
              class="tr"
              layout="row"
              layout-align="start center"
              v-for="(item, index) in detailTableData"
              :key="index"
            >
              <div class="td one-txt-cut">{{ index + 1 }}</div>
              <div class="td one-txt-cut">{{item.s}}</div>
              <div class="td one-txt-cut">{{item.n}}</div>
              <div class="td one-txt-cut">{{item.p}}</div>
              <div class="td one-txt-cut">{{item.t}}</div>
              <div class="td one-txt-cut">{{item.b}}</div>
              <div class="td one-txt-cut">{{item.o}}</div>
              <div class="td one-txt-cut">{{(item.a/100).toFixed(2)}}</div>
              <div class="td one-txt-cut">{{(item.bb/100).toFixed(2)}}</div>
              <div class="td one-txt-cut">{{(item.ab/100).toFixed(2)}}</div>
              <p v-if="tableData.length == 0" class="m-t-10 fs14" style="text-align:center">暂无数据</p>
            </div>
          </div>
        </div>
      </div>
      <div v-else>
        <div class="top m-l-4 m-b-4" layout="row" layout-align="start center">
          <input style="margin: 0px 10px;height: 30px;line-height: 30px; padding-left: 10px; border-radius: 5px" v-model="key" placeholder="客户姓名/电话" />
          <el-button type="primary" size="small" @click="getTableData">查询</el-button>
          <el-button size="small" @click="resetHandle">重置</el-button>
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
              <div class="th">客人姓名</div>
              <div class="th">联系方式</div>
              <div class="th">可用金额</div>
              <div class="th">锁定金额</div>
              <div class="th">消费金额</div>
              <div class="th">退款金额</div>
              <div class="th">操作</div>
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
            <div class="td one-txt-cut">{{ index + 1 }}</div>
            <div class="td one-txt-cut">{{item.n}}</div>
            <div class="td one-txt-cut">{{item.p}}</div>
            <div class="td one-txt-cut">{{(item.ub/100).toFixed(2)}}</div>
            <div class="td one-txt-cut">{{(item.la/100).toFixed(2)}}</div>
            <div class="td one-txt-cut">{{(item.ca/100).toFixed(2)}}</div>
            <div class="td one-txt-cut">{{(item.ba/100).toFixed(2)}}</div>
            <div class="td one-txt-cut">
              <span class="primary-link cursor"
                @click="intoDetail(item)">查看详情</span>
              </div>

            </div>
            <p v-if="tableData.length == 0" class="m-t-10 fs14" style="text-align:center">暂无数据</p>
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
      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onClose">关闭</el-button>
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
      key: "",
      tableData: [],
      detailTableData: [],
      pageInfo: {
        page: 1,
        pageSize: 10,
        total: 0
      },
      showDetail: false,
      selectedItem: {}
    };
  },
  methods: {
    intoDetail(item) {
      this.selectedItem = item;
      this.showDetail = true;
      this.getTableData();
    },
    resetHandle(){
      this.pageInfo.page = 1;
      this.pageInfo.pageSize = 10;
      this.getTableData();
    },
    onClose(){
      console.log('close', this.showDetail)
      if(this.showDetail){
        this.showDetail = false;
      }else{
        this.$emit('showOrHideSetYDJYEDrawerHandle')
      }
    },
    changePageHandle(page) {
      this.pageInfo.page = page;
      this.getTableData();
    },

    //  读取客人预订金流水记录
    async getTableData() {
      if(this.showDetail) {
        const params = {
          cust_id: this.selectedItem.id
        };

        const res = await api_money.reqGetOneCustPrePayLog(params);
        if (res.code == 1) {
          this.detailTableData = res.data.records || []
        } else {
          this.$message.warning(res.msg);
        }
      } else {
        const params = {
          page_num: this.pageInfo.page, //   int    第几页
          page_size: this.pageInfo.pageSize, //  int    每页行数
          key: this.key, // string  关键字
        };

        const res = await api_money.reqGetCustPrePayBal(params);
        if (res.code == 1) {
          this.tableData = res.data.records || []
          this.pageInfo.total = res.data.row_cnt
        } else {
          this.$message.warning(res.msg);
        }
      }

    },

    // 导出excel
    async exportExcel() {
      try {
        let params = {
            cust_id: this.selectedItem.id
          };
        if(!this.showDetail) {
          params = {
            page_num: this.pageInfo.page, //   int    第几页
            page_size: this.pageInfo.pageSize, //  int    每页行数
            key: this.key, // string  关键字
          };
        }
        const res = this.showDetail ? await api_money.reqExpOneCustPrePayLog(params) : await api_money.reqExpCustPrePayBal(params);
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
  created() {
    this.resetHandle();
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
@import "../../style/common/elementFormBtn.less";
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
    height: calc(100vh - 270px);
    overflow-y: auto;
    margin-bottom: 10px;
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
    .th:nth-child(5), .td:nth-child(5),
    .th:nth-child(6), .td:nth-child(6),
    .th:nth-child(7), .td:nth-child(7),
    .th:nth-child(8), .td:nth-child(8),
    .th:nth-child(9), .td:nth-child(9),
    .th:nth-child(10), .td:nth-child(10)
    {
      width: calc((100% - 60px) / 9);
    }

  }

  .pagination{
    margin-top: 20px;
    float: right;
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


/deep/ .el-select {
  input {
    background: #FAFAFC;
    border-radius: 8px;
    border: 1px solid #C4CBD7;
    color: #08080A;
    font-size: 20px;
    font-family: PingFangSC, PingFang SC;
    font-weight: 400;

    &::placeholder {
      color: #7A7A7A;
    }
  }
}


.el-select-dropdown__item.hover,
.el-select-dropdown__item:hover {
  color: #1A1A21 !important;
  background: rgba(16, 16, 32, 0.4);
}

.el-select-dropdown__item.selected {
  color: #1A1A21 !important;
  background: rgba(16, 16, 32, 0.4);
}
</style>