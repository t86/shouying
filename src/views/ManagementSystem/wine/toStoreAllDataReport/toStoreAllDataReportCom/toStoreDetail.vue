<template>
  <!-- 充公明细统计 -->
  <div class="to-store-detail">
    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="center center">
            <div class="th">充公类型</div>
            <div class="th">商品名称</div>
            <div class="th">规格</div>
            <div class="th">数量</div>
            <div class="th">卡台</div>
            <div class="th">订位人</div>
            <div class="th">充公日期</div>
            <div class="th">过期日期</div>
            <div class="th">客户名称</div>
            <div class="th">客户手机号</div>
            <div class="th">存酒流水号</div>
            <div class="th">充公人/操作人</div>
            <div class="th">备注</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" v-for="(item) in tableData" :key="item.id" layout="row" layout-align="space-between center">
            <div class="td">{{item.ct}}</div>
            <div class="td one-txt-cut">{{item.p}}</div>
            <div class="td">{{item.u}}</div>
            <div class="td">{{item.c}}</div>
            <div class="td">{{item.s}}</div>
            <div class="td">{{item.se}}</div>
            <div class="td">{{item.t}}</div>
            <div class="td">{{item.e}}</div>
            <div class="td">{{item.cn}}</div>
            <div class="td">{{item.cp}}</div>
            <div class="td" style="user-select: text;">{{item.i}}</div>
            <div class="td">{{item.oe}}</div>
            <div class="td">{{item.r}}</div>
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
.to-store-detail {
  .table-content {
    position: relative;
    width: 100%;
    height: calc(100vh - 220px);
    overflow: auto;
    .table {
      min-width: 1800px;
      .thead{
        position: sticky;
        z-index: 10;
        .th {
          font-size: 15px;
          background-color: #eee;
        }
      }
      .tbody {
        .tr {
          height: 40px;
          font-size: 15px;
          &:nth-child(2n) {
            .td:nth-child(1),
            .td:nth-child(2),
            .td:nth-child(3){
              background-color: #f5f5f5;
            }
          }
          &:nth-child(2n + 1) {
            .td:nth-child(1),
            .td:nth-child(2),
            .td:nth-child(3){
              background-color: #f9f9f9;
            }
          }
        }
      }
      .th,.td {
        padding: 0 10px;
        
        &:nth-child(1){
          position: sticky;
          left: 0;
          z-index: 1;
        }
        &:nth-child(2){
          position: sticky;
          left: 146px;
          z-index: 1;
        }
        &:nth-child(3){
          position: sticky;
          left: 292px;
          z-index: 1;
        }

        &:nth-child(3),
        &:nth-child(4),
        &:nth-child(6),
        &:nth-child(9){
          width: 40%;
        }
      }
    }
  }
}
</style>