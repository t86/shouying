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
        <h3 class="show" style="text-align:center">调拨入库单</h3>
        <!-- 头部信息 -->
        <div class="form">
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">单号：</div>
              <div class="value">{{info.code}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">入库仓库：</div>
              <div class="value">{{info.in_store_name}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">出库仓库：</div>
              <div class="value">{{info.out_store_name}}</div>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">入库时间：</div>
              <div class="value">{{info.in_store_time}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">出库时间：</div>
              <div class="value">{{info.out_store_time}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">入库操作员：</div>
              <div class="value">{{info.in_emp_name}}</div>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">出库操作员：</div>
              <div class="value">{{info.out_emp_name}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">出库总成本：</div>
              <div class="value">{{info.total_amt}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">备注：</div>
              <div class="value">{{info.remark}}</div>
            </div>
          </div>
        </div>

        <!-- 明细单列表 -->
        <div v-if="tableData.length > 0">
          <h4 class="m-t-6 m-b-2">正常订单</h4>
          <div class="table-content">
            <div class="table border">
              <div class="thead">
                <div class="tr" layout="row" >
                  <div class="th">序号</div>
                  <div class="th">物料名称</div>
                  <div class="th">物料分类</div>
                  <div class="th">一级单位</div>
                  <div class="th">二级单位</div>
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
                  <div class="td">{{(item.a * 1 == 0 || item.c * 1 == 0) ? '0.00' : (item.a/item.c).toFixed(2)}}</div>
                  <div class="td">{{item.c}}</div>
                  <div class="td">{{item.a}}</div>
                  <div class="td">{{item.s}}</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 异议记录 -->
        <div v-if="applyForTableData.length > 0">
          <h4 class="m-t-6 m-b-2">异议记录</h4>
          <div class="table-content">
            <div class="table border">
              <div class="thead">
                <div class="tr" layout="row">
                  <div class="th">序号</div>
                  <div class="th">物料名称</div>
                  <div class="th">物料分类</div>
                  <div class="th">一级单位</div>
                  <div class="th">二级单位</div>
                  <div class="th">确认数量</div>
                  <div class="th">确认小计</div>
                  <div class="th">异议数量</div>
                  <div class="th">异议小计</div>
                  <div class="th">异议备注</div>
                  <div class="th">操作人</div>
                  <div class="th">操作方</div>
                  <div class="th">操作时间</div>
                </div>
              </div>
              <div class="tbody">
                <div class="tr" layout="row" v-for="(item, i) in applyForTableData" :key="item.id">
                  <div class="td">{{i + 1}}</div>
                  <div class="td">{{item.n}}</div>
                  <div class="td">{{item.moc}}</div>
                  <div class="td">{{item.mtc}}</div>
                  <div class="td">{{item.un}}</div>
                  <div class="td">{{item.dc}}</div>
                  <div class="td">{{item.da}}</div>
                  <div class="td">{{item.yc}}</div>
                  <div class="td">{{item.ya}}</div>
                  <div class="td">{{item.r}}</div>
                  <div class="td">{{item.oen}}</div>
                  <div class="td">{{item.yo}}</div>
                  <div class="td">{{item.ot}}</div>
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
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button type="primary" v-if="info.status == '已完成' || info.status == '待入库'" v-print="print">打印</el-button>
        <el-button type="primary" v-if="info.status == '已完成'" @click="emitHandle(1)">申请售后</el-button>
        <el-button type="primary" v-if="info.status == '待入库'" @click="emitHandle(2)">确认入库</el-button>
        <el-button type="primary" v-if="info.status == '待入库'" @click="emitHandle(3)">部分入库</el-button>
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
      applyForTableData: [],     
      print: {
        id: "print",
        popTitle: "调拨入库单"
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
        const res = await this.$api.ERP.sind.requestsindget_f_view(params)
        if(res.code == 1) {
          this.info = res.data || {}
          this.tableData = res.data.dtls || []
          this.applyForTableData = res.data.yy_dtls || []
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('初始化数据获取失败', error);
      }
    },

    emitHandle(type) {
      // type:1:申请售后  2：确认入库  3：部分入库
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
      &:nth-child(13) {
        width: 70%;
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


<style scoped media="print">

@media print {
  #print .show {
    display: block;
  }
}
  </style>