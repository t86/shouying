<template>
  <div class="one-table">
    <div class="table-content">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">序号</div>
            <div class="th">明细名称</div>
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
        const params = {
          id: this.$route.query.menuId * 1
        }
        if(!params.id) return
        const res = await this.$api.BMS.require.requestRqmlist(params);
        if (res.code == 1) {
          this.tableData = res.data || []
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("表格数据请求失败", error);
      }
    },

  },
  created () {
    this.getTableData()
  },
  watch: {
    '$route': {
      handler() {
        this.getTableData()
      }
    }
  }
};
</script>

<style lang="less" scoped>
@import "../../../../../style/erp/table.less";
</style>
<style scoped lang='less'>
.one-table {
  padding: 20px;
  .top {
    background-color: #eee;
  }
  .table-content {
    .table {
      max-height: calc(100vh - 160px);
      overflow: auto;
      .th,.td{
        &:nth-child(2){
          width: 90%;
        }
      }
    }
  }
}
</style>