<template>
  <div>
    <!-- 查看详情 -->
    <el-drawer
      title="查看详情"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="1100px"
    >
      <div class="session p-5 detail">
        <div class="top" layout="row" layout-align="start center">
          <span>出库单号：</span>
          <span class="m-r-6">{{currentInfo.id}}</span>
          <span>出库时间：</span>
          <span class="m-r-6">{{currentInfo.it}}</span>
          <span>出库操作人：</span>
          <span>{{currentInfo.o}}</span>
        </div>

        <!-- 明细单列表表格 -->
        <h3 class="m-t-3">明细单列表</h3>
        <div class="table-content m-t-3">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">空瓶名称</div>
                <div class="th">出库数量</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" layout="row" layout-align="space-between center" v-for="item in tableData" :key="item.id">
                <div class="td">{{item.m}}</div>
                <div class="td">{{item.c}}</div>
              </div>
              <div class="no-data" v-if="tableData.length==0">
                <img :src="require('@/assets/img/wu.png')" alt />
                <p>暂无数据</p>
              </div>
            </div>
          </div>
        </div>

        <!-- 红冲记录表格 -->
        <h3 class="m-t-3">红冲记录</h3>
        <div class="table-content m-t-3">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">空瓶名称</div>
                <div class="th">红冲前数量</div>
                <div class="th">红冲数量</div>
                <div class="th">红冲后数量</div>
                <div class="th">红冲操作人</div>
                <div class="th">红冲操作时间</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" layout="row" layout-align="space-between center" v-for="item in tableDataHc" :key="item.id">
                <div class="td">{{item.m}}</div>
                <div class="td">{{item.bc}}</div>
                <div class="td">{{item.c}}</div>
                <div class="td">{{item.ac}}</div>
                <div class="td">{{item.e}}</div>
                <div class="td">{{item.t}}</div>
              </div>
              <div class="no-data" v-if="tableData.length==0">
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
export default {
  data() {
    return {
      tableData: [],  // 明细单列表
      tableDataHc: [], // 红冲单列表
    };
  },
  methods: {
    async getTableData(){
      const params = {
        id: this.currentInfo.id * 1 // int64  待入库订单Id
      }
      try {
        const res = await this.$api.ERP.emptyLib.getEmptyOutOrderDetail(params);
        if (res.code == 1) {
          this.tableData = res.data.records || []
          this.tableDataHc = res.data.hc_records || []
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('获取订单详情失败', error);
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
@import '../../../../../style/common/elementDrawerWine.less';
@import '../../../../../style/common/elementDrawerHeaderAndSession.less';
@import '../../../../../style/common/elementFormBtnWine.less';
@import '../../../../../style/erp/table.less';
</style>

<style lang="less" scoped>
.detail {
  .table {
    min-height: 260px;
  }
}
</style>