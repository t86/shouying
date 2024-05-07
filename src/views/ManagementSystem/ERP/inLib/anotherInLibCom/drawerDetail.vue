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
        <h3 class="show" style="text-align:center">其他入库单</h3>
        <!-- 头部信息 -->
        <div class="form">
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">单号：</div>
              <div class="value">{{info.code}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">入库仓库：</div>
              <div class="value">{{info.store_name}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">入库类型：</div>
              <div class="value">{{info.record_type}}</div>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">入库操作员名称：</div>
              <div class="value">{{info.oper_emp_name}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">入库单总金额：</div>
              <div class="value">{{info.total_amt}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">供应商：</div>
              <div class="value">{{info.supplier_name}}</div>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">入库时间：</div>
              <div class="value">{{info.store_time}}</div>
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
          <div class="table-title" style="font-weight: 600;">明细单列表：</div>
          <div class="table-content">
            <div class="table border">
              <div class="thead">
                <div class="tr" layout="row" >
                  <div class="th">序号</div>
                  <div class="th">物料名称</div>
                  <div class="th">一级分类</div>
                  <div class="th">二级分类</div>
                  <div class="th">入库单位</div>
                  <div class="th">入库数量</div>
                  <div class="th">入库单价</div>
                  <div class="th">入库小计</div>
                </div>
              </div>
              <div class="tbody">
                <div class="tr" layout="row"  v-for="(item, i) in tableData" :key="item.id">
                  <div class="td">{{i + 1}}</div>
                  <div class="td">{{item.n}}</div>
                  <div class="td">{{item.moc}}</div>
                  <div class="td">{{item.mtc}}</div>
                  <div class="td">{{item.un}}</div>
                  <div class="td">{{item.c}}</div>
                  <div class="td">{{(item.a/item.c).toFixed(2)}}</div>
                  <div class="td">{{(item.a - (item.a/item.c) * (item.hcCount || 0)).toFixed(2)}}</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 红冲操作单列表 -->
        <div v-if="hcTableData.length > 0">
          <h4 class="m-t-6 m-b-2">红冲操作单列表</h4>
          <div class="table-content">
            <div class="table border">
              <div class="thead">
                <div class="tr" layout="row">
                  <div class="th">序号</div>
                  <div class="th">物料名称</div>
                  <div class="th">物料操作员名称</div>
                  <div class="th">红冲数量</div>
                  <div class="th">红冲金额</div>
                  <div class="th">红冲单位</div>
                  <div class="th">红冲前数量</div>
                  <div class="th">红冲后数量</div>
                  <div class="th">红冲操作时间</div>
                </div>
              </div>
              <div class="tbody">
                <div class="tr" layout="row" v-for="(item, i) in hcTableData" :key="item.id">
                  <div class="td">{{i + 1}}</div>
                  <div class="td">{{item.n}}</div>
                  <div class="td">{{item.oen}}</div>
                  <div class="td">{{item.c}}</div>
                  <div class="td">{{item.a}}</div>
                  <div class="td">{{item.un}}</div>
                  <div class="td">{{item.bc}}</div>
                  <div class="td">{{item.ac}}</div>
                  <div class="td">{{item.ot}}</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="show">
          <div class="sign m-t-6">
            <div class="coll" layout="row" layout-align="start center">
              <div class="label">总金额：</div>
              <div class="value">{{allAmt.toFixed(2)}}元</div>
            </div>
          </div>
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
        <el-button type="primary" @click="emitHandle(1)">类似创建</el-button>
        <el-button type="primary" v-if="info.status == '已完成'" @click="emitHandle(2)">红冲</el-button>
        <el-button type="primary" v-if="info.status == '已完成'" @click="emitHandle(3)">红冲整单</el-button>
        <el-button type="primary" v-if="info.status == '已完成'" v-print="print">打印</el-button>
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
      print: {
        id: "print",
        popTitle: "其他入库单"
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
        const res = await this.$api.ERP.sin.requestsinget_f_view(params)
        if(res.code == 1) {
          this.info = res.data || {}
          this.tableData = res.data.dtls || []
          this.hcTableData = res.data.hc_dtls || []
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('初始化数据获取失败', error);
      }
    },

    emitHandle(type) {
      // type: 1:类似创建  2：红冲  3：红冲整单
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
        const amt = b.fapiao_type == '专票' ? b.a * 1 : b.sa * 1
        return a + amt
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

.table-title {
  margin-top: 24px;
  margin-bottom: 8px;
  font-weight: 600;
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

</style>


<style scoped lang="less" media="print">

@media print {
  
  .show {
    display: block;
  }

  .table-title {
    font-size: 10px;
    margin-top: 10px;
    margin-bottom: 4px;
  }
}
  </style>