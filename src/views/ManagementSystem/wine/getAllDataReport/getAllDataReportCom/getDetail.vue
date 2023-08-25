<template>
  <!-- 出库明细统计 -->
  <div class="get-detail">
    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="center center">
            <div class="th">商品名称</div>
            <div class="th">规格</div>
            <div class="th">数量</div>
            <div class="th">存酒流水号</div>
            <div class="th">出库时间</div>
            <div class="th">取酒时间</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" v-for="(item) in tableData" :key="item.id" layout="row" layout-align="space-between center">
            <div class="td one-txt-cut">{{item.pn}}</div>
            <div class="td">{{item.u}}</div>
            <div class="td">{{item.c}}</div>
            <div class="td" style="user-select: text;">{{item.i}}</div>
            <div class="td">{{item.t}}</div>
            <div class="td">{{item.it}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img src="@/assets/img/wu.png" alt />
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
    };
  },
  props:{
    tableData:{
      default: () => ([])
    }
  }
};
</script>

<style lang="less" scoped>
@import "../../../../../style/wine/table.less";
</style>
<style scoped lang="less">
.get-detail {
  .table-content {
    position: relative;
    width: 100%;
    height: calc(100vh - 220px);
    overflow: auto;
    .table {
      .thead{
        position: sticky;
        z-index: 10;
        .th {
          font-size: 15px;
        }
      }
      .tbody {
        .tr {
          height: 40px;
          font-size: 15px;
        }

        
      }
      .th,.td {
        padding: 0 10px;
        
        &:nth-child(2),
        &:nth-child(3){
          width: 40%;
        }
      }
    }
  }
}
</style>