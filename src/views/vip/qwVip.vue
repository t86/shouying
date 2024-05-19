<template>
  <div class="vip vip-type">
    <h3 class="title">企微会员</h3>
    <div
      class="top"
      style="padding: 10px;"
      v-if="$store.getters.vipAuth"
      layout="row"
      layout-align="start center"
    >
      <input v-model="keyword" style="height: 20px;line-height: 18px;align-items: center;padding: 3px;" placeholder="昵称/手机号" />
      <el-button
        class="m-l-2"
        type="primary"
        style="width:70px;height:30px;line-height:30px;padding:0"
        @click="getTableData"
      >查询</el-button>
      <el-button
        type="info"
        style="width:70px;height:30px;line-height:30px;padding:0"
        @click="resetHandle"
      >重置</el-button>
    </div>

    <!-- table -->
    <div class="table">
      <div class="thead">
        <div class="tr" layout="row" layout-align="start center">
          <div class="th">
            <span style="color: #1a1a21">序号</span>
          </div>
          <div class="th">昵称</div>
          <div class="th">手机号</div>
          <div class="th">添加时间</div>
        </div>
      </div>
      <div class="tbody">
        <div
          class="tr"
          :class="{ checked: item.checked }"
          v-for="(item, index) in tableData"
          :key="index"
          layout="row"
          layout-align="start center"
        >
          <div class="td">{{ index + 1 }}
          </div>
          <div class="td">{{ item.n }}</div>
          <div class="td">{{ item.p }}</div>
          <div class="td">{{ item.t }}</div>
        </div>
        <div class="no-data" v-if="tableData.length == 0">
          <img :src="require('@/assets/vip-imgs/empty.png')" alt />
          <p>暂无数据</p>
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
import IconButton from "@/components/IconButton.vue";
export default {
  data() {
    return {
      keyword: "",
      tableData: [],
      pageInfo: {
        page: 1,
        pageSize: 10,
        total: 0
      },
    };
  },
  methods: {
    async getTableData() {
      try {
        const params = {
        page_num: this.pageInfo.page, //   int    第几页
        page_size: this.pageInfo.pageSize, //  int    每页行数
        key: this.keyword, // string  关键字
      };
        const res = await api_vip.reqGetQwMbList(params);
        if (res.code == 1) {
          this.tableData = res.data.records || [];
          this.pageInfo.total = res.data.row_cnt
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("企微会员列表获取失败", error);
      }
    },
    resetHandle() {
      this.pageInfo.page = 1;
      this.pageInfo.pageSize = 10;
      this.keyword = "";
      this.getTableData();
    },
    changePageHandle(page) {
      this.pageInfo.page = page;
      this.getTableData();
    },
  },
  created() {
    this.getTableData();
  },
  components: {
    IconButton,
  },
  filters: {},
};
</script>

<style lang="less" scoped>
@import "../../style/vip/vip.less";
.table {
  max-height: calc(100vh - 250px);
  overflow-y: auto;
  .tr {
    .th,
    .td {
      width: 20%;
    }
    .th:nth-child(1),
    .td:nth-child(1),
    .th:nth-last-child(1),
    .td:nth-last-child(1) {
      width: 10%;
      span {
        color: #2362d5;
        cursor: pointer;
      }
    }
  }
}
</style>
