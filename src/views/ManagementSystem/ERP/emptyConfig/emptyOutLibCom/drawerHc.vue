<template>
  <div>
    <!-- 红冲 -->
    <el-drawer
      title="红冲"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="1100px"
    >
      <div class="session p-5 hc">
        <div class="top" layout="row" layout-align="start center">
          <span>出库单号：</span>
          <span class="m-r-6">{{currentInfo.id}}</span>
          <span>出库时间：</span>
          <span class="m-r-6">{{currentInfo.it}}</span>
          <span>出库操作人：</span>
          <span>{{currentInfo.o}}</span>
        </div>

        <!-- 表格 -->
        <div class="table-content m-t-3">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">空瓶名称</div>
                <div class="th">红冲前数量</div>
                <div class="th">红冲给数量</div>
                <div class="th">红冲后数量</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" layout="row" layout-align="space-between center" v-for="item in tableData" :key="item.id">
                <div class="td">{{item.m}}</div>
                <div class="td">{{item.c}}</div>
                <div class="td">
                  <el-input size="small" style="width:130px" v-model="item.count" :maxLength="30" placeholder="请输入红冲数量" @input="inputCountHandle(item)"></el-input>
                </div>
                <div class="td">{{item.resultCount}}</div>
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
        <el-button type="primary" @click="onSubmit">确认红冲</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      tableData: []
    };
  },
  methods: {
    async getTableData(){
      const params = {
        id: this.currentInfo.id * 1 // int64  待入库订单Id
      }
      try {
        const res = await this.$api.ERP.emptyLib.getHCOrderOutLib(params);
        if (res.code == 1) {
          this.tableData = (res.data.records || []).map(item => ({
            ...item,
            count: 0,  // 红冲数量
            resultCount: item.c  // 红冲后数量
          }));
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('获取订单详情失败', error);
      }
    },

    inputCountHandle(itemInfo){
      if(isNaN(itemInfo.count * 1)) {
        this.$message.warning('请输入数字')
        itemInfo.count = itemInfo.c
      }
      if(itemInfo.count > itemInfo.c) {
        itemInfo.count = itemInfo.c
      }

      if(itemInfo.count < 0) {
        itemInfo.count = 0
      }

      itemInfo.resultCount = itemInfo.c - itemInfo.count
    },

    // 确认红冲
    async onSubmit (){
      const isNaNOrder = this.tableData.some(item => isNaN(item.count * 1))
      if(isNaNOrder) return this.$message.warning('红冲数量存在非数字')
      const params = {
        ids: this.tableData.filter(item => item.count * 1 > 0).map(item => item.id * 1), //   []int64   入库订单列表
        cnt: this.tableData.filter(item => item.count * 1 > 0).map(item => item.count * 1), //    []int   红冲数量,>0
      }
      try {
        const res = await this.$api.ERP.emptyLib.submitHCOutLib(params);
        if (res.code == 1) {
          this.$message.success('红冲成功')
          this.onCancelDrawer()
          this.$emit('getTableData')
        } else {
          this.$message.warning(res.msg);
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
.hc {
  .table {
    .tbody {
      height: calc(100vh - 230px);
      overflow: auto;
    }
  }
}
</style>