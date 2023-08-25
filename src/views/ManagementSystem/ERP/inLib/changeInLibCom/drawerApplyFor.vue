<template>
  <div>
    <!-- 部分入库 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="98%"
    >
      <div class="session p-5">
        <!-- 头部信息 -->
        <div class="form">
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">调拨单单号：</div>
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
              <div class="label">出库总售出金额：</div>
              <div class="value">{{info.sell_total_amt}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">备注：</div>
              <div class="value">{{info.remark}}</div>
            </div>
          </div>
        </div>
        <!-- 部分入库表格 -->
        <div v-if="tableData.length > 0">
          <h4 class="m-b-3 m-t-3">正常订单</h4>
          <div class="table-content m-t-4">
            <div class="table">
              <div class="thead">
                <div class="tr" layout="row" layout-align="space-between center">
                  <div class="th">序号</div>
                  <div class="th">物料名称</div>
                  <div class="th">一级分类</div>
                  <div class="th">二级分类</div>
                  <div class="th">单位</div>
                  <div class="th">成本单价</div>
                  <div class="th">入库数量</div>
                  <div class="th">成本小计</div>
                  <div class="th">状态</div>
                  <div class="th">操作</div>
                </div>
              </div>
              <div class="tbody">
                <div class="tr" layout="row" layout-align="space-between center" v-for="(item, i) in tableData" :key="item.id">
                  <div class="td">{{i + 1}}</div>
                  <div class="td">{{item.n}}</div>
                  <div class="td">{{item.moc}}</div>
                  <div class="td">{{item.mtc}}</div>
                  <div class="td">{{item.un}}</div>
                  <div class="td">{{(item.a/item.c).toFixed(2)}}</div>
                  <div class="td">{{item.c}}</div>
                  <div class="td">{{item.a}}</div>
                  <div class="td">{{item.s}}</div>
                  <div class="td">
                    <span class="primary-link cursor" @click="applyForHandle(item)">申请</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <!-- 异议项 -->
        <div v-if="applyForTableData.length > 0">
          <h4 class="m-b-3 m-t-3">异议项</h4>
          <div class="table-content m-t-4">
            <div class="table">
              <div class="thead">
                <div class="tr" layout="row" layout-align="space-between center">
                  <div class="th">序号</div>
                  <div class="th">物料名称</div>
                  <div class="th">一级分类</div>
                  <div class="th">二级分类</div>
                  <div class="th">物料单位</div>
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
                <div class="tr" layout="row" layout-align="space-between center" v-for="(item, i) in applyForTableData" :key="item.id">
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
        <drawerApplyForNext v-model="showDrawerApplyForNext" :currentInfo="currentNextInfo" @getAllData='getAllData' />
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import drawerApplyForNext from './drawerApplyForNext.vue'
export default {
  data() {
    return {
      info: {},
      tableData: [], // 正常订单列表
      applyForTableData: [], // 异议订单列表
      showDrawerApplyForNext: false,
      currentNextInfo: {}, // 申请异议订单的订单信息
    };
  },
  methods: {
    // 获取基础信息
    async getAllData(){
      const params = {
        id: this.currentInfo.id * 1
      }
      try {
        const res = await this.$api.ERP.sind.requestsindget_f_sh(params)
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

    // 正常订单申请异议
    applyForHandle(itemInfo) {
      if(itemInfo.s != '已完成') return this.$message.warning("只有已完成状态,才能申请");
      this.currentNextInfo = {...itemInfo}
      this.showDrawerApplyForNext = true

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
    title(){
      return '申请售后'
    },
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
    drawerApplyForNext
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
    min-width: 1200px;
    max-height: 50vh;
    overflow: auto;
    .tr {
      padding-right: 10px;
    }
    
    .th,.td {
      &:nth-child(1) {
        width: 30%;
      }
      &:nth-child(13) {
        width: 70%;
      }
    }
  }
}
</style>