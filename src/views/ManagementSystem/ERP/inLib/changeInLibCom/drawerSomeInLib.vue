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
              <div class="label">出库仓库：</div>
              <div class="value">{{info.out_store_name}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">入库仓库：</div>
              <div class="value">{{info.in_store_name}}</div>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">出库操作员名称：</div>
              <div class="value">{{info.out_emp_name}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">出库时间：</div>
              <div class="value">{{info.out_store_time}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">出库总成本：</div>
              <div class="value">{{info.total_amt}}</div>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">备注：</div>
              <div class="value">{{info.remark}}</div>
            </div>
            <div class="item fs14"></div>
            <div class="item fs14"></div>
          </div>
        </div>
        <p class="fs12 red-color m-t-4">说明：请核实入库数量是否正确，数量有误的处理成异议单，确认数量默认为零，异议备注是必填写的，除待确认数量和确认数量一致以外。</p>
        <!-- 部分入库表格 -->
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
                <div class="th">待确认数量</div>
                <div class="th">确认数量</div>
                <div class="th">成本小计</div>
                <div class="th">异议原因</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" layout="row" layout-align="space-between center" v-for="(item, i) in tableData" :key="item.id">
                <div class="td">{{i + 1}}</div>
                <div class="td">{{item.n}}</div>
                <div class="td">{{item.moc}}</div>
                <div class="td">{{item.mtc}}</div>
                <div class="td">{{item.un}}</div>
                <div class="td">{{(item.a / item.c).toFixed(2)}}</div>
                <div class="td">{{item.c}}</div>
                <div class="td">
                  <el-input
                    v-model="item.sureCount"
                    @input="changeCount(item)"
                    placeholder="请输入数量"
                    size="mini"
                  />
                </div>
                <div class="td">{{((item.a/item.c)*(item.sureCount||0)).toFixed(2)}}</div>
                <div class="td">
                  <el-input
                    :disabled="item.sureCount == item.c"
                    v-model="item.remark"
                    :placeholder="item.c == item.sureCount ? '---':'请输入异议备注'"
                    size="mini"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      info: {},
      tableData: []
    };
  },
  methods: {
    // 获取基础信息
    async getAllData(){
      const params = {
        id: this.currentInfo.id * 1
      }
      try {
        const res = await this.$api.ERP.sind.requestsindget_f_pt(params)
        if(res.code == 1) {
          this.info = res.data || {}
          this.tableData = (res.data.dtls || []).map(item => ({
            ...item,
            sureCount: 0,
            remark: ''
          }))

        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('初始化数据获取失败', error);
      }
    },

    // 改变入库数量
    changeCount(itemInfo){
      if(isNaN(itemInfo.sureCount * 1)) {
        itemInfo.sureCount = 0
        return this.$message.warning('请输入数字')
      }
      if(itemInfo.sureCount * 1 > itemInfo.c * 1) {
        itemInfo.sureCount = itemInfo.c
        return this.$message.warning('最大可数量不可总数量')
      }

      if(itemInfo.sureCount * 1 < 0) {
        itemInfo.sureCount = 0
        return this.$message.warning('最小数量为0')
      }

      if(itemInfo.sureCount == itemInfo.c) {
        itemInfo.remark = ''
      }
    },
    
    // 确认入库
    async onSubmit (){
      // 异议订单列表
      const notAllOrderList = this.tableData.filter(item => item.sureCount * 1 < item.c)
      // 异议订单必填备注
      if(notAllOrderList.some(item => !item.remark)) return this.$message.warning('请填写确认入库数量小于总数量的异议原因')
      const params = {
        id: this.currentInfo.id * 1, //  int64  调拨入库单id
        dtl_ids: this.tableData.filter(item => item.c == item.sureCount).map(item => item.id * 1),  //  []int64  确认入库的子订单id列表
        yy_dtl_ids: notAllOrderList.map(item => item.id * 1), //  []int64   发起异议子订单id列表
        in_cnts: notAllOrderList.map(item => item.sureCount * 1), //  []int   对应异议订单的实际入库数量(注意不是异议数量)
        yy_remarks: notAllOrderList.map(item => item.remark)  //  []string   异议备注
      }
      try {
        const res = await this.$api.ERP.sind.requestsindone_part_in(params)
        if (res.code == 1) {
          this.$message.success('操作成功')
          this.onCancelDrawer()
          this.$emit('getTableData')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('部分调拨入库失败', error);
      }
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
      return '部分入库'
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
    min-width: 1300px;
    max-height: calc(100vh - 300px);
    overflow: auto;
    .tr {
      padding-right: 10px;
    }
    
    .th,.td {
      &:nth-child(1) {
        width: 30%;
      }
    }
  }
}
</style>