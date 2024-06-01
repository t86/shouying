<template>
  <div class="vip-pay-info">
    <div class="table">
      <div class="thead">
        <div class="tr" layout="row" layout-align="space-between center">
          <div class="th">序号</div>
          <div class="th">酒水名称</div>
          <div class="th">规格</div>
          <div class="th">每瓶重量</div>
          <div class="th">数量</div>
          <div class="th">入库时间</div>
          <div class="th">到期时间</div>
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
          <div class="td">{{item.u}}</div>
          <div class="td">{{item.g}}</div>
          <div class="td">{{item.c}}</div>
          <div class="td">{{item.i}}</div>
          <div class="th">{{item.e}}</div>
        </div>
      </div>
    </div>

  </div>
</template>

<script>
import api_vip from "@/api/vip";
export default {
  data() {
    return {
      options: [
        {
          value: 0,
          label: '全部'
        },
        {
          value: 1,
          label: '有效'
        },
        {
          value: 5,
          label: '已使用'
        },
        {
          value: 2,
          label: '已失效'
        },
        {
          value: 4,
          label: '已作废'
        }
      ],
      selectedStatus: 0,
      tableData: [],
    };
  },
  methods: {
    async getTableData(reset) {
      const params = {
        ...(this.info.bp && { bind_phone: this.info.bp }), // string  绑定手机号(用于查询有绑定手机的会员信息,里面可能包含多张卡)
      };

      try {
        const res = await api_vip.reqMyWineList(params);
        console.log(res)
        if (res.code == 1) {
          this.tableData = res.data.records || [];
          // this.pageInfo.total = res.data.row_cnt || 0;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("优惠剩余存酒失败", error);
      }
    },
  },
  props: {
    info: {
      default: {}
    }
  }
};
</script>

<style lang="less" scoped>
@import "../../../../style/vip/vip.less";
</style>
<style scoped lang="less">
.vip-pay-info {
  font-size: 14px;
  .table {
    height: calc(100vh - 280px);
    overflow-y: auto;
    .th:nth-child(1),
    .td:nth-child(1) {
      width: 60px;
    }
    .th:nth-child(2),
    .td:nth-child(2) {
      width: 180px;
    }
    .th:nth-child(3),
    .td:nth-child(3) {
      width: 80px;
    }
    .th:nth-child(4),
    .td:nth-child(4) {
      width: 80px;
    }
    .th:nth-child(5),
    .td:nth-child(5) {
      width: 80px;
      // span {
      //   color: #2362d5;
      //   cursor: pointer;
      // }
    }
    .th:nth-child(6),
    .td:nth-child(6) {
      width: 180px;
    }
    .th:nth-child(7),
    .td:nth-child(7) {
      width: 180px;
    }
  }

  .pagination{
    margin-top: 20px;
    float: right;
  }
}
</style>