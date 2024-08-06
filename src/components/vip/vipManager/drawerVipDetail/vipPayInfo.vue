<template>
  <div class="vip-pay-info">
    <div class="table">
      <div class="thead">
        <div class="tr" layout="row" layout-align="space-between center">
          <div class="th">序号</div>
          <div class="th">交易日期</div>
          <div class="th">会员卡号</div>
          <div class="th">类型</div>
          <div class="th">商品<br/><span class="fs12">(鼠标悬停可全部显示)</span></div>
          <div class="th">卡台</div>
          <div class="th">储值金额</div>
          <div class="th">赠送金额</div>
          <div class="th">操作人</div>
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
          <div class="td">{{item.o}}</div>
          <div class="td">{{item.c}}</div>
          <div class="td">{{item.t}}</div>
          <div class="td one-txt-cut">
            <span :title="item.od">{{item.od}}</span>
          </div>
          <div class="td fs16-bold">{{item.s}}</div>
          <div class="td fs16-bold">{{item.va}}</div>
          <div class="td fs16-bold">{{item.fa}}</div>
          <div class="td">{{item.e}}</div>
        </div>
      </div>
    </div>

    <div class="pagination">
      <el-pagination
        background
        layout="prev, pager, next"
        :total="pageInfo.total"
        :page-size="pageInfo.pageSize"
        :current-page="pageInfo.page"
        @current-change="changePageHandle"
      ></el-pagination>
    </div>
  </div>
</template>
 
<script>
import api_vip from "@/api/vip";
export default {
  data() {
    return {
      tableData: [],
      pageInfo: {
        page: 1,
        pageSize: 20,
        total: 0
      }
    };
  },
  methods: {
    async getTableData(reset) {
      if (reset) this.pageInfo.page = 1;
      const params = {
        page_num: this.pageInfo.page, //   int    第几页
        page_size: this.pageInfo.pageSize, //  int    每页行数
        ...(this.info.bp && { bind_phone: this.info.bp }), // string  绑定手机号(用于查询有绑定手机的会员信息,里面可能包含多张卡)
        ...(!this.info.bp && { id: this.info.id * 1 }) //  int64   会员卡Id(用于查询没有绑定手机的会员卡信息,单卡) 与bind_phone互斥
      };

      try {
        const res = await api_vip.reqGetVipCarPayMoneyListDetail(params);
        if (res.code == 1) {
          this.tableData = res.data.datas || [];
          this.pageInfo.total = res.data.row_cnt || 0;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("交易明细获取失败", error);
      }
    },

    changePageHandle(page) {
      this.pageInfo.page = page;
      this.getTableData();
    }
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
      width: 120px;
    }
    .th:nth-child(3),
    .td:nth-child(3) {
      width: 120px;
    }
    .th:nth-child(4),
    .td:nth-child(4) {
      width: 100px;
    }
    .th:nth-child(5),
    .td:nth-child(5) {
      width: 200px;
      // span {
      //   color: #2362d5;
      //   cursor: pointer;
      // }
    }
    .th:nth-child(6),
    .td:nth-child(6) {
      width: 100px;
    }
    .th:nth-child(7),
    .td:nth-child(7) {
      width: 120px;
    }
    .th:nth-child(8),
    .td:nth-child(8) {
      width: 120px;
    }
    .th:nth-child(9),
    .td:nth-child(9) {
      width: 100px;
    }
  }

  .pagination{
    margin-top: 20px;
    float: right;
  }
}
</style>