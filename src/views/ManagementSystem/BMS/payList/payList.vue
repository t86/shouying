<template>
  <div class="pay-list p-6">
    <p class="red-color fs14 m-b-3">提示：请勾选门店使用的支付渠道，去掉勾选则无法使用该渠道结账；“自适应”代表自适应门店业务</p>
    <div class="table-content">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">序号</div>
            <div class="th">支付渠道</div>
            <div class="th">启用</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            layout="row"
            layout-align="space-between center"
            v-for="(item, index) in tableData"
            :key="item.id"
          >
            <div class="td">{{index + 1}}</div>
            <div class="td">{{item.n}}</div>
            <div class="td">
              <el-checkbox v-if="item.id < 100 || item.id == 500" v-model="item.checked" @change="changeSelectHandle(item)"></el-checkbox>
              <span v-else>自适应</span>
            </div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>
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
    async getTableData() {
      try {
        const res = await this.$api.BMS.paycnl.requestpaycnllist()
        if (res.code == 1) {
          const isAllNotChoose = (res.data || []).filter(item => item.id < 100 || item.id == 500).some(item => item.iu == 1)
          const result = (res.data || []).map(item => ({
            ...item,
            checked: isAllNotChoose ? item.iu == 1 : true
          }))
          this.tableData = [...result.filter(item => item.id < 100), ...result.filter(item => item.id == 500), ...result.filter(item => item.id > 100 && item.id != 500)]
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("表格数据请求失败", error);
      }
    },

    async changeSelectHandle(itemInfo){
      const api = itemInfo.checked ? 'reqSelectItem' : 'reqNotSelectItem'
      const params = {
        id: itemInfo.id * 1 //  int64  支付渠道Id
      }

      try {
        const res = await this.$api.BMS.paycnl[api](params)
        if(res.code == 1) {
          this.$message.success('操作成功')
        }
      } catch (error) {
        console.log('操作支付渠道失败', error)
      }
    }
  },
  created(){
    this.getTableData()
  }
};
</script>

<style lang="less" scoped>
@import "../../../../style/erp/table.less";
</style>
<style scoped lang='less'>
.table-content {
  height: calc(100vh - 160px);
  overflow: auto;
  .table {
    .th,.td {
      &:nth-child(1),
      &:nth-child(3) {
        width: 30%;
      }
    }
  }
}
</style>