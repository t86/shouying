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
        <h3 class="show" style="text-align:center">异议订单</h3>
        <!-- 头部信息 -->
        <h4 class="table-title">异议信息</h4>
        <div class="form">
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">单号：</div>
              <div class="value">{{info.cd}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">物料名称：</div>
              <div class="value">{{info.n}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">出库时间：</div>
              <div class="value">{{info.ost}}</div>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">一级分类：</div>
              <div class="value">{{info.moc}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">二级分类：</div>
              <div class="value">{{info.mtc}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">出库仓库：</div>
              <div class="value">{{info.osn}}</div>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">入库仓库：</div>
              <div class="value">{{info.isn}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">出库数量：</div>
              <div class="value">{{info.c}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">异议数量：</div>
              <div class="value">{{info.yc}}</div>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">异议锁定数量：</div>
              <div class="value">{{info.lyc}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">状态：</div>
              <div class="value">{{info.s}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">备注：</div>
              <div class="value">{{info.r}}</div>
            </div>
          </div>
        </div>

        <!-- 明细单列表 -->
        <div>
          <h4 class="table-title">异议记录</h4>
          <div class="table-content">
            <div class="table border">
              <div class="thead">
                <div class="tr" layout="row" >
                  <div class="th">子单号</div>
                  <div class="th">名称</div>
                  <div class="th">一级分类</div>
                  <div class="th">二级分类</div>
                  <div class="th">单位</div>
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
                <div class="tr" layout="row"  v-for="(item) in tableData" :key="item.id">
                  <div class="td">{{item.id}}</div>
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
                <div class="no-data" v-if="tableData.length==0">
                  <img :src="require('@/assets/img/wu.png')" alt />
                  <p>暂无数据</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="show">
          <div class="sign m-t-2" layout="row" layout-align="start center">
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

      <drawerBackOrder v-model="showDrawerBack" :currentInfo="currentInfo" @emitHandle="emitHandle" />

      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button type="primary" v-if="info.s == '已完成'" v-print="print">打印</el-button>
        <el-button type="primary" v-if="info.s == '已处理'" @click="goBackApplyForHandle">撤销异议</el-button>
        <el-button type="primary" v-if="info.lyc != '0' && info.s == '待处理'" @click="backOrderHandle">驳回</el-button>
        <el-button type="primary" v-if="info.s == '待处理'" @click="sureInOrderHandle">确定入库</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import drawerBackOrder from './drawerBackOrder.vue'
export default {
  data() {
    return {
      info: {},
      tableData: [],

      showDrawerBack: false, 

      print: {
        id: "print",
        popTitle: "异议订单"
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
        const res = await this.$api.ERP.soutdd_yy.req_in_yy_dtls(params)
        if(res.code == 1) {
          this.tableData = res.data.records || []
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('初始化数据获取失败', error);
      }
    },

    // 撤销异议
    async goBackApplyForHandle(){
      const params = {
        id: this.currentInfo.id * 1
      }
      try {
        const res = await this.$api.ERP.soutdd_yy.requestd_yyin_cancel(params)
        if(res.code == 1) {
          this.$message.success('操作成功')
          this.$emit('getTableData')
          this.onCancelDrawer()
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('撤销异议失败', error);
      }
    },

    // 驳回
    backOrderHandle(){
      this.showDrawerBack = true
    },

    // 确定入库
    async sureInOrderHandle(){
      const params = {
        id: this.currentInfo.id * 1
      }
      try {
        const res = await this.$api.ERP.soutdd_yy.requestd_yyin_confirm(params)
        if(res.code == 1) {
          this.$message.success('操作成功')
          this.$emit('getTableData')
          this.onCancelDrawer()
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('确定入库失败', error);
      }
    },

    emitHandle(){
      this.onCancelDrawer()
      this.$emit('getTableData')
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
  components: {
    drawerBackOrder
  },
  watch: {
    value: {
      handler(newVal) {
        if(newVal) {
          this.info = {...this.currentInfo}
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
      &:nth-child(1),
      &:nth-last-child(1){
        width: 70%;
      }
      &:nth-child(5),
      &:nth-child(6),
      &:nth-child(8) {
        width: 40%;
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