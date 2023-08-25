<template>
  <div>
    <!-- 红冲 -->
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
              <div class="label">出库单号：</div>
              <div class="value">{{info.code}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">仓库：</div>
              <div class="value">{{info.store_name}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">类型：</div>
              <div class="value">{{info.record_type}}</div>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">出库时间：</div>
              <div class="value">{{info.store_time}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">出库操作员名称：</div>
              <div class="value">{{info.oper_emp_name}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">出库单总成本：</div>
              <div class="value">{{info.total_amt}}</div>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="space-around center">
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">出库单出库金额：</div>
              <div class="value">{{info.sell_total_amt}}</div>
            </div>
            <div class="item fs14" layout="row" layout-align="start center">
              <div class="label">备注：</div>
              <div class="value">{{info.remark}}</div>
            </div>
            <div class="item fs14"></div>
          </div>
        </div>

        <!-- 红冲表格 -->
        <div class="table-content m-t-4">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">序号</div>
                <div class="th">物料名称</div>
                <div class="th">一级分类</div>
                <div class="th">二级分类</div>
                <div class="th">出库单位</div>
                <div class="th">红冲前数量</div>
                <div class="th">红冲数量</div>
                <div class="th">红冲后数量</div>
                <div class="th">红冲成本小计</div>
                <div class="th">红冲小计</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" layout="row" layout-align="space-between center" v-for="(item, i) in tableData" :key="item.id">
                <div class="td">{{i + 1}}</div>
                <div class="td">{{item.n}}</div>
                <div class="td">{{item.moc}}</div>
                <div class="td">{{item.mtc}}</div>
                <div class="td">{{item.un}}</div>
                <div class="td">{{item.c}}</div>
                <div class="td">
                  <el-input
                    v-model="item.hcCount"
                    @input="changeHcCount(item)"
                    placeholder="请输入数量"
                    size="mini"
                  />
                </div>
                <div class="td">{{item.c - item.hcCount}}</div>
                <div class="td">{{((item.a/item.c) * item.hcCount).toFixed(2)}}</div>
                <div class="td">{{((item.sa/item.c) * item.hcCount).toFixed(2)}}</div>
              </div>
              <div class="no-data m-b-10" v-if="tableData.length==0">
                <img :src="require('@/assets/img/wu.png')" alt />
                <p>暂无数据</p>
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
        const res = await  this.$api.ERP.sout.requestsoutget_f_hc(params)
        if(res.code == 1) {
          this.info = res.data || {}
          this.tableData = (res.data.dtls || []).map(item => ({
            ...item,
            hcCount: 0,
          }))

        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('初始化数据获取失败', error);
      }
    },

    // 改变红冲数量
    changeHcCount(itemInfo){
      if(isNaN(itemInfo.hcCount * 1)) {
        itemInfo.hcCount = 0
        return this.$message.warning('请输入数字')
      }
      if(itemInfo.hcCount * 1 > itemInfo.c * 1) {
        itemInfo.hcCount = itemInfo.c
        return this.$message.warning('最大可红冲数量不可超过入库数量')
      }

      if(itemInfo.hcCount * 1 < 0) {
        itemInfo.hcCount = 0
        return this.$message.warning('最小可红冲数量为0')
      }
    },
    
    // 确认红冲
    async onSubmit (){
      const resultTableData = this.tableData.filter(item => item.hcCount * 1 > 0)
      if(resultTableData.length <= 0) return this.$message.warning('请填写红冲实际入库数量')
      const params = {
        dtl_ids: resultTableData.map(item => item.id * 1),
        cnts: resultTableData.map(item => item.hcCount * 1)
      }
      try {
        const res = await this.$api.ERP.sout.requestsouthc(params)
        if (res.code == 1) {
          this.$message.success('红冲成功')
          this.onCancelDrawer()
          this.$emit('getTableData')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('红冲失败', error);
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
      return '红冲'
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