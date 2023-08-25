<template>
  <div>
    <!-- 查看详情 -->
    <el-drawer
      title="查看详情"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="900px"
    >
      <div class="session p-5 detail">
        <div class="top" layout="row" layout-align="start center">
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">出库单号：</div>
            <div class="value">{{orderId}}</div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">出库时间：</div>
            <div class="value">{{outTime}}</div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">操作人：</div>
            <div class="value">{{outEmp}}</div>
          </div>
        </div>
        <div class="table-content">
          <h3 class="m-b-2">明细单列表</h3>
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">商品名称</div>
                <div class="th">规格</div>
                <div class="th">入库仓库</div>
                <div class="th">充公出库数量</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" layout="row" layout-align="space-between center" v-for="item in tableData" :key="item.id">
                <div class="td">{{item.p}}</div>
                <div class="td">{{item.u}}</div>
                <div class="td">{{item.s}}</div>
                <div class="td">{{item.c}}</div>
              </div>
              <div class="no-data" v-if="tableData.length==0">
                <img :src="require('@/assets/img/wu.png')" alt />
                <p>暂无数据</p>
              </div>
            </div>
          </div>
          <h3 class="m-b-2 m-t-2">红冲记录</h3>
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">商品名称</div>
                <div class="th">规格</div>
                <div class="th">红冲前数量</div>
                <div class="th">红冲数量</div>
                <div class="th">红冲后数量</div>
                <div class="th">红冲操作人</div>
                <div class="th">红冲操作时间</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" layout="row" layout-align="space-between center" v-for="item in hcTableData" :key="item.id">
                <div class="td">{{item.p}}</div>
                <div class="td">{{item.u}}</div>
                <div class="td">{{item.bc}}</div>
                <div class="td">{{item.c}}</div>
                <div class="td">{{item.ac}}</div>
                <div class="td">{{item.n}}</div>
                <div class="td">{{item.t}}</div>
              </div>
              <div class="no-data" v-if="hcTableData.length==0">
                <img :src="require('@/assets/img/wu.png')" alt />
                <p>暂无数据</p>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_wine from '@/api/wine'
export default {
  data() {
    return {
      tableData: [],
      hcTableData: []
    };
  },
  methods: {
    async getTableData(){
      const params = {
        id: this.currentInfo.id * 1  //   int64   充公出库单订单Id
      }
      try {
        const res = await api_wine.reqGetToStoreOrderDetail(params)
        if(res.code == 1) {
          this.tableData = res.data.records || []
          this.hcTableData = res.data.hc_records || []

          this.orderId = res.data.id
          this.outTime = res.data.out_time || ''
          this.outEmp = res.data.oper_emp_name || ''
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('红冲详情列表获取失败', error)
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
    currentInfo: {
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
          this.getTableData()
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import '../../../../style/common/elementDrawerWine.less';
@import '../../../../style/common/elementDrawerHeaderAndSession.less';
@import '../../../../style/common/elementFormBtnWine.less';
@import "../../../../style/wine/table.less";
</style>

<style lang="less" scoped>
.detail {
  .top {
    margin-bottom: 20px;
    .coll {
      margin-right: 30px;
    }
  }

  .table {
    .th,.td{
      &:nth-child(2),
      &:nth-child(3),
      &:nth-child(4),
      &:nth-child(5),
      &:nth-child(6){
        width: 40%;
      }
    }
  }
}
</style>