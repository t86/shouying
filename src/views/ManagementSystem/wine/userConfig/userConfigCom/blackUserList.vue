<template>
  <div class="back-list">
    <div class="top" layout="row" layout-align="start center">
      <el-input
        v-model="keyword"
        style="width:200px"
        class="m-r-2"
        size="small"
        placeholder="输入手机号码/客户姓名"
      ></el-input>
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button size="small" @click="resetHandle">重置</el-button>
    </div>
    <div class="btn-area m-t-4">
      <el-button type="primary" size="small" @click="toUserListHandle">移出黑名单</el-button>
    </div>

    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th" layout="row" layout-align="center center">
              <div style="width: 60px;text-align:left">
                <el-checkbox
                  :indeterminate="isIndeterminate"
                  v-model="checkAll"
                  @change="changeCheckboxHandle('all')"
                >全选</el-checkbox>
              </div>
            </div>
            <div class="th">客户姓名</div>
            <div class="th">手机号码</div>
            <div class="th">短信状态</div>
            <div class="th">更新时间</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            :class="{'selected': item.checked}"
            layout="row"
            layout-align="space-between center"
            v-for="(item, index) in tableData"
            :key="item.id"
          >
            <div class="td" layout="row" layout-align="center center">
              <div style="width: 60px;text-align:left">
                <el-checkbox
                  v-model="item.checked"
                  @change="changeCheckboxHandle('item')"
                >{{index + 1}}</el-checkbox>
              </div>
            </div>
            <div class="td">{{item.n}}</div>
            <div class="td">{{item.p}}</div>
            <div class="td">{{item.s}}</div>
            <div class="td">{{item.u}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img :src="require('@/assets/img/wu.png')" alt />
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

  </div>
</template>
 
<script>
import api_wine from "@/api/wine";
export default {
  data() {
    return {
      options: [
        {
          value: 0,
          label: "全部"
        },
        {
          value: 1,
          label: "开启"
        },
        {
          value: 2,
          label: "关闭"
        }
      ],
      keyword: "",
      checkAll: false,
      tableData: [],

      pageInfo: {
        page: 1,
        pageSize: 20,
        total: 0
      }
    };
  },
  methods: {
    async getTableData() {
      return this.$message.warning('开发中，敬请期待...')
      const params = {
        page_num: this.pageInfo.page * 1, //   int    指定第几页
        page_size: this.pageInfo.pageSize, //  int     每页行数
        key: this.keyword //   string   搜索关键字
      };

      try {
        const res = await api_wine.reqGetCustomList(params);
        if (res.code == 1) {
          this.tableData = (res.data.records || []).map(item => ({
            ...item,
            checked: false
          }));

          this.checkAll = false;

          this.pageInfo.total = res.data.row_cn || 0;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("用户列表数据获取失败", error);
      }
    },

    // 移出黑名单
    async toUserListHandle(){
      this.$message.warning('开发中，敬请期待...')
    },

    changeCheckboxHandle(type) {
      switch (type) {
        case "all":
          this.tableData.forEach(el => {
            el.checked = this.checkAll;
          });
          break;
        case "item":
          this.checkAll = this.tableData.every(item => item.checked);
          break;
      }
      this.ids = this.tableData
        .filter(item => item.checked)
        .map(item => item.id * 1);
    },

    changePageHandle(page = 1) {
      this.pageInfo.page = page;
      this.getTableData();
    },

    resetHandle() {
      this.keyword = "";
      this.getTableData();
    }
  },
  created() {
    this.resetHandle();
  },
  computed: {
    isIndeterminate() {
      return !this.checkAll && this.tableData.some(item => item.checked);
    }
  }
};
</script>

<style lang="less" scoped>
@import "../../../../../style/wine/table.less";
</style>
<style scoped lang="less">
.back-list {
  .table {
    .tbody {
      height: calc(100vh - 330px);
      overflow: auto;
    }
  }
}
</style>