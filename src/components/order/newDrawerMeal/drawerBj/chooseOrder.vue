<template>
  <div>
    <div class="table-content m-t-3">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">序号</div>
            <div class="th">流水</div>
            <div class="th">开台时间</div>
            <div class="th">订位人</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" layout="row" layout-align="space-between center" v-for="(item, index) in tableData"
            :key="item.id">
            <div class="td" style="font-size: 22px;font-family: PingFangSC, PingFang SC;font-weight: 400;color: #08080A;">
              <el-checkbox v-model="item.checked" @change="changeCheckBox(item)">{{ index + 1 }}</el-checkbox>
            </div>
            <div class="td" style="font-size: 22px;font-family: PingFangSC, PingFang SC;font-weight: 400;color: #08080A;">{{ item.n }}</div>
            <div class="td" style="font-size: 22px;font-family: PingFangSC, PingFang SC;font-weight: 400;color: #08080A;">{{ item.o }}</div>
            <div class="td" style="font-size: 22px;font-family: PingFangSC, PingFang SC;font-weight: 400;color: #08080A;">{{ item.s }}</div>
          </div>
          <div class="no-data p-10 fs14" v-if="tableData.length <= 0">暂无数据</div>
        </div>
      </div>
    </div>
  </div>
</template>
 
<script>
import api_order from "@/api/order";
export default {
  data() {
    return {
      tableData: []
    };
  },
  methods: {
    init() {
      this.getOrderList();
    },
    async getOrderList() {
      const params = {
        biz_day: this.dateVal, //    string  营业日期,格式: yyyy-mm-dd
        seat_id: this.cardId * 1 // int64  卡台Id
      };
      try {
        const res = await api_order.reqGetCanBJSeatOrderList(params);
        if (res.code == 1) {
          this.tableData = (res.data.records || []).map(item => ({
            ...item,
            checked: (res.data.records || []).length == 1
          }));
          if (this.tableData.length == 1) {
            this.$emit('chooseOrderHandle', this.tableData[0]);
          }
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("卡台信息获取失败", error);
      }
    },

    changeCheckBox(itemInfo) {
      this.tableData = this.tableData.map(item => ({
        ...item,
        checked: item.id == itemInfo.id
      }));
      this.$emit('chooseOrderHandle', itemInfo);
    }
  },
  created() { },
  mounted() { },
  props: {
    cardId: "",
    dateVal: ""
  },
  components: {},
  filters: {}
};
</script>
<style lang="less" scoped>
@import "../../../../style/saveWine/newTable.less";
</style>

<style scoped lang='less'>
.table {
  .tbody {
    height: calc(100vh - 220px);
    overflow: auto;
  }
}
</style>