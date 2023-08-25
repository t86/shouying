<template>
  <div class="search-list">
    <div class="table">
      <div class="thead">
        <div class="tr" layout="row" layout-align="space-between center">
          <div class="th">会员卡号</div>
          <div class="th">姓名</div>
          <div class="th">绑定手机</div>
          <div class="th">联系手机</div>
          <div class="th">卡类型</div>
          <div class="th">卡等级</div>
          <div class="th">操作</div>
        </div>
      </div>
      <div class="tbody">
        <div class="tr" v-for="item in tableData" :key="item.id" layout="row" layout-align="space-between center">
          <div class="td">{{item.c}}</div>
          <div class="td">{{item.n}}</div>
          <div class="td">{{item.p}}</div>
          <div class="td">{{item.cp}}</div>
          <div class="td">{{item.ct}}</div>
          <div class="td">{{item.cl}}</div>
          <div class="td">
            <span @click="emitData(item)">充值</span>
          </div>
        </div>
        <div class="no-data" v-if="tableData.length==0">
          <img :src="require('@/assets/vip-imgs/empty.png')" alt />
          <p>暂无数据</p>
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
  methods: {
    emitData(itemInfo){
      this.$emit('updateCurrentInfo', itemInfo)
      this.$emit('changeStep', 2)
    }
  },
  created() {},
  mounted() {},
  props: {
    tableData: {
      default: () => []
    }
  },
  components: {},
  filters: {}
};
</script>

<style scoped lang="less">
@import "../../../../style/vip/vip.less";
@import "../../../../style/vip/vipBtn.less";
</style>

<style lang="less" scoped>
.search-list {
  .table {
    .th:nth-child(1),
    .td:nth-child(1) {
      width: 120px;
    }
    .th:nth-child(2),
    .td:nth-child(2) {
      width: 100px;
    }
    .th:nth-child(3),
    .td:nth-child(3) {
      width: 120px;
    }
    .th:nth-child(4),
    .td:nth-child(4) {
      width: 120px;
    }
    .th:nth-child(5),
    .td:nth-child(5) {
      width: 150px;
    }
    .th:nth-child(6),
    .td:nth-child(6) {
      width: 120px;
    }
    .th:nth-child(7),
    .td:nth-child(7) {
      width: 60px;
      span{
        color: #2362D5;
        cursor: pointer;
      }
    }
  }
}
</style>