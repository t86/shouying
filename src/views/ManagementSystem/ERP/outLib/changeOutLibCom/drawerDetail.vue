<template>
  <div>
    <!-- 查看详情 -->
    <el-drawer
      title="查看详情"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="98%"
    >
      <div class="session p-5" id="print">
        <h3 class="show" style="text-align:center">调拨出库单</h3>
        <!-- 头部信息 -->
        <div class="form">
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">单号：</div>
              <div class="value">{{info.code}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">出库操作员名称：</div>
              <div class="value">{{info.out_emp_name}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">出库仓库名：</div>
              <div class="value">{{info.out_store_name}}</div>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">入库仓库名：</div>
              <div class="value">{{info.in_store_name}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">出库时间：</div>
              <div class="value">{{info.out_store_time}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">入库时间：</div>
              <div class="value">{{info.in_store_time}}</div>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">出库总成本：</div>
              <div class="value">{{info.in_store_name}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">状态：</div>
              <div class="value">{{info.status}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">备注：</div>
              <div class="value">{{info.remark}}</div>
            </div>
          </div>
        </div>

        <!-- 明细单列表 -->
        <div v-if="tableData.length > 0">
          <h4 class="m-t-6 m-b-2">已完成项</h4>
          <div class="table-content">
            <div class="table border">
              <div class="thead">
                <div class="tr" layout="row" >
                  <div class="th">序号</div>
                  <div class="th">物料名称</div>
                  <div class="th">一级分类</div>
                  <div class="th">二级分类</div>
                  <div class="th">单位</div>
                  <div class="th">成本单价</div>
                  <div class="th">数量</div>
                  <div class="th">成本小计</div>
                  <div class="th">状态</div>
                </div>
              </div>
              <div class="tbody">
                <div class="tr" layout="row"  v-for="(item, i) in tableData" :key="item.id">
                  <div class="td">{{i + 1}}</div>
                  <div class="td">{{item.n}}</div>
                  <div class="td">{{item.moc}}</div>
                  <div class="td">{{item.mtc}}</div>
                  <div class="td">{{item.un}}</div>
                  <div class="td">{{item.a/item.c}}</div>
                  <div class="td">{{item.c}}</div>
                  <div class="td">{{item.a}}</div>
                  <div class="td">{{item.s}}</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 红冲操作单列表 -->
        <div v-if="hcTableData.length > 0">
          <h4 class="m-t-6 m-b-2">红冲记录</h4>
          <div class="table-content">
            <div class="table border">
              <div class="thead">
                <div class="tr" layout="row">
                  <div class="th">序号</div>
                  <div class="th">物料名称</div>
                  <div class="th">一级分类</div>
                  <div class="th">二级分类</div>
                  <div class="th">单位</div>
                  <div class="th">红冲前数量</div>
                  <div class="th">红冲数量</div>
                  <div class="th">红冲后数量</div>
                  <div class="th">红冲成本小计</div>
                  <div class="th">红冲操作人</div>
                  <div class="th">日期</div>
                </div>
              </div>
              <div class="tbody">
                <div class="tr" layout="row" v-for="(item, i) in hcTableData" :key="item.id">
                  <div class="td">{{i + 1}}</div>
                  <div class="td">{{item.n}}</div>
                  <div class="td">{{item.moc}}</div>
                  <div class="td">{{item.mtc}}</div>
                  <div class="td">{{item.mun}}</div>
                  <div class="td">{{item.bc}}</div>
                  <div class="td">{{item.cnt}}</div>
                  <div class="td">{{item.ac}}</div>
                  <div class="td">{{item.amt}}</div>
                  <div class="td">{{item.oen}}</div>
                  <div class="td">{{item.ot}}</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 异议项列表 -->
        <div v-if="yyTableData.length > 0">
          <h4 class="table-title">异议项</h4>
          <div class="table-content">
            <div class="table border">
              <div class="thead">
                <div class="tr" layout="row">
                  <div class="th">序号</div>
                  <div class="th">物料名称</div>
                  <div class="th">一级分类</div>
                  <div class="th">二级分类</div>
                  <div class="th">单位</div>
                  <div class="th">确认数量</div>
                  <div class="th">确认小计</div>
                  <div class="th">异议数量</div>
                  <div class="th">异议小计</div>
                  <div class="th">操作方</div>
                  <div class="th">操作人</div>
                  <div class="th">操作时间</div>
                  <div class="th">异议备注</div>
                </div>
              </div>
              <div class="tbody">
                <div class="tr" layout="row" v-for="(item, i) in yyTableData" :key="item.id">
                  <div class="td">{{i + 1}}</div>
                  <div class="td">{{item.n}}</div>
                  <div class="td">{{item.moc}}</div>
                  <div class="td">{{item.mtc}}</div>
                  <div class="td">{{item.un}}</div>
                  <div class="td">{{item.dc}}</div>
                  <div class="td">{{item.da}}</div>
                  <div class="td">{{item.yc}}</div>
                  <div class="td">{{item.ya}}</div>
                  <div class="td">{{item.yo}}</div>
                  <div class="td">{{item.oen}}</div>
                  <div class="td">{{item.ot}}</div>
                  <div class="td">{{item.r}}</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="show">
          <div class="sign m-t-3" layout="row" layout-align="start center">
            <div class="coll" layout="row" layout-align="start center">
              <div class="label">签收人：</div>
              <div class="value line"></div>
            </div>
            <div class="coll" layout="row" layout-align="start center">
              <div class="label">送货人：</div>
              <div class="value line"></div>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" v-if="info.status == '已完成' || info.status == '待收货'" v-print="print">打印</el-button>
        <el-button type="primary" @click="emitHandle(1)">类似创建</el-button>
        <el-button type="primary" v-if="info.status == '待收货'" @click="emitHandle(2)">红冲</el-button>
        <el-button type="primary" v-if="info.status == '待收货'" @click="emitHandle(3)">整单红冲</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      info: {},
      tableData: [],
      hcTableData: [],     
      yyTableData: [],     
      print: {
        id: "print",
        popTitle: "调拨出库单"
      },
    };
  },
  methods: {
    // 获取基础信息
    async getAllData(){
      const params = {
        id: this.currentInfo.id * 1
      }
      try {
        const res = await this.$api.ERP.soutd.requestsoutdget_f_view(params)
        if(res.code == 1) {
          this.info = res.data || {}
          this.tableData = res.data.dtls || []
          this.hcTableData = res.data.hc_dtls || []
          this.yyTableData = res.data.yy_dtls || []
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('初始化数据获取失败', error);
      }
    },

    emitHandle(type) {
      // type: 1:类似创建  2：红冲  3：整单红冲
      this.onCancelDrawer()
      this.$emit('emitHandle', type)
    },

    onCancelDrawer(){
      this.show = false
    },

  },
  mounted() {},
  props: {
    value: {
      default: false // 是否显示drawer
    },
    currentInfo:{
      default: () => ({})
    }
  },
  computed: {
    show: {
      get(){
        return this.value
      },

      set(val) {
        this.$emit('input', val)
      }
    },
    allAmt(){
      return this.tableData.reduce((a, b) => {
        return a + b.sa * 1
      }, 0)
    }
  },
  watch: {
    value: {
      handler(newVal) {
        if(newVal) {
          this.getAllData()
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import '../../../../../style/common/elementDrawerWine.less';
@import '../../../../../style/common/elementDrawerHeaderAndSession.less';
@import '../../../../../style/common/elementFormBtnWine.less';
@import '../../../../../style/erp/form.less';
@import '../../../../../style/erp/table.less';
@import '../../../../../style/erp/tableBorder.less';
</style>

<style lang="less" scoped>
.form{
  padding: 20px;
  border-radius: 10px;
  background-color: #eee;
  .coll {
    box-sizing: border-box;
    .item {
      width: 50%;
      .label {
        width: 120px;
        text-align: right;
      }
    }
  }
}

.table-content {
  width: 100%;
  overflow: auto;
  .table {
    .tr {
      padding-right: 10px;
    }
    
    .th,.td {
      &:nth-child(1) {
        width: 20%;
      }
    }
  }
}

.line {
  width: 100px;
  transform: translateY(10px);
  border-bottom: 1px solid #666;
}

.show {
  display: none;
}
.table-title {
  margin-top: 24px;
  margin-bottom: 8px;
  font-weight: 600;
}
</style>


<style scoped media="print">

@media print {
  .show {
    display: block;
  }

  .table-title {
    font-size: 10px;
    margin-top: 0px;
    margin-bottom: 4px;
  }
  .form{
    padding: 10px;
  }
}
  </style>