<template>
  <!-- 出库网格统计 -->
  <div class="grid-detail">
    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">商品名称</div>
            <div class="th">整瓶</div>
            <div class="th">0.1</div>
            <div class="th">0.2</div>
            <div class="th">0.3</div>
            <div class="th">0.4</div>
            <div class="th">0.5</div>
            <div class="th">0.6</div>
            <div class="th">0.7</div>
            <div class="th">0.8</div>
            <div class="th">0.9</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" layout="row" layout-align="space-between center" v-for="item in tableData" :key="item.id">
            <div class="td one-txt-cut">{{item.p}}</div>
            <div class="td">{{item.p10 || ''}}</div>
            <div class="td">{{item.p1 || ''}}</div>
            <div class="td">{{item.p2 || ''}}</div>
            <div class="td">{{item.p3 || ''}}</div>
            <div class="td">{{item.p4 || ''}}</div>
            <div class="td">{{item.p5 || ''}}</div>
            <div class="td">{{item.p6 || ''}}</div>
            <div class="td">{{item.p7 || ''}}</div>
            <div class="td">{{item.p8 || ''}}</div>
            <div class="td">{{item.p9 || ''}}</div>
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
@import "../../../../../style/wine/table2.less";
</style>
<style scoped lang="less">
.grid-detail {
  .table-content {
    position: relative;
    width: 100%;
    height: calc(100vh - 220px);
    overflow: auto;
    .table {
      display: table;
      width: 100%;
      border-collapse: collapse; /* 确保没有空白间隙 */

      .thead, .tbody {
        display: table-row-group;
      }

      .tr {
        display: table-row;
        border-bottom: 1px solid #ddd;
      }

      .th, .td {
        display: table-cell;
        padding: 8px;
        border-right: 1px solid #ddd; /* 添加竖线 */
        box-sizing: border-box; /* 包含边框的宽度 */
      }

      .th:last-child, .td:last-child {
        border-right: none; /* 最后一列无竖线 */
      }
    }
  }
}
</style>