<template>
  <div class="vip-pay-info">
    状态:
    <el-select v-model="selectedStatus" placeholder="请选择"  @change="statusChanged(true)">
      <el-option
          v-for="item in options"
          :key="item.value"
          :label="item.label"
          :value="item.value">
      </el-option>
    </el-select>

    <div class="table">
      <div class="thead">
        <div class="tr" layout="row" layout-align="space-between center">
          <div class="th">序号</div>
          <div class="th">卡券名称</div>
          <div class="th">卡券来源</div>
          <div class="th">操作人</div>
          <div class="th">领取时间</div>
          <div class="th">使用时间</div>
          <div class="th">使用卡台</div>
          <div class="th">到期时间</div>
          <div class="th">卡券状态</div>
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
          <div class="td">{{item.c}}</div>
          <div class="td">{{item.u}}</div>
          <div class="td">{{item.g}}</div>
          <div class="td">{{item.ct}}</div>
          <div class="td">{{item.sn}}</div>
          <div class="td">{{item.e}}</div>
          <div class="th">{{item.s}}</div>
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
      pageInfo: {
        page: 1,
        pageSize: 20,
        total: 0
      }
    };
  },
  methods: {
    async statusChanged(){
      console.log('----------------------')
      await this.getTableData(true)
    },
    async getTableData(reset) {
      if (reset) this.pageInfo.page = 1;
      const params = {
        page_num: this.pageInfo.page, //   int    第几页
        page_size: this.pageInfo.pageSize, //  int    每页行数
        status: this.selectedStatus, // 状态
        ...(this.info.bp && { bind_phone: this.info.bp }), // string  绑定手机号(用于查询有绑定手机的会员信息,里面可能包含多张卡)
      };

      try {
        const res = await api_vip.reqMyKQList(params);
        if (res.code == 1) {
          this.tableData = res.data.datas || [];
          this.pageInfo.total = res.data.row_cnt || 0;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("优惠券获取失败", error);
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
      width: 120px;
    }
    .th:nth-child(7),
    .td:nth-child(7) {
      width: 120px;
    }
    .th:nth-child(8),
    .td:nth-child(8) {
      width: 100px;
    }
  }

  .pagination{
    margin-top: 20px;
    float: right;
  }
}
</style>