<template>
  <div class="user-list">
    <div class="top" layout="row" layout-align="start center">
      <div class="item m-r-2" layout="row" layout-align="start center">
        <div class="label fs14">短信状态：</div>
        <div class="value">
          <el-select
            style="width: 100px"
            size="small"
            v-model="selectVal"
            placeholder="请选择"
          >
            <el-option
              v-for="item in options"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            ></el-option>
          </el-select>
        </div>
      </div>
      <el-input
        v-model="keyword"
        style="width: 200px"
        class="m-r-2"
        size="small"
        placeholder="输入手机号码/客户姓名"
      ></el-input>
      <el-button type="primary" size="small" @click="getTableData"
        >查询</el-button
      >
      <el-button size="small" @click="resetHandle">重置</el-button>
    </div>
    <div class="btn-area m-t-4">
      <el-button type="primary" size="small" @click="openOrCloseMsgHandle(1)"
        >开启短信</el-button
      >
      <el-button type="primary" size="small" @click="openOrCloseMsgHandle(2)"
        >关闭短信</el-button
      >
      <el-button type="primary" size="small" @click="updateUserInfo(1)"
        >编辑姓名</el-button
      >
      <el-button type="primary" size="small" @click="updateUserInfo(2)"
        >更改手机号</el-button
      >
      <el-button type="primary" size="small" @click="addBlackList"
        >加入黑名单</el-button
      >
    </div>

    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th" layout="row" layout-align="center center">
              <div style="width: 60px; text-align: left">
                <el-checkbox
                  :indeterminate="isIndeterminate"
                  v-model="checkAll"
                  @change="changeCheckboxHandle('all')"
                  >全选</el-checkbox
                >
              </div>
            </div>
            <div class="th" layout="row" layout-align="center center">
              客户姓名
            </div>
            <div class="th" layout="row" layout-align="center center">
              手机号码
            </div>
            <div class="th" layout="row" layout-align="center center">
              短信状态
            </div>
            <div
              class="th"
              layout="row"
              layout-align="center center"
              style="width: 200px"
            >
              黑名单
            </div>
            <div class="th" layout="row" layout-align="center center">
              更新时间
            </div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            :class="{ selected: item.checked }"
            layout="row"
            layout-align="space-between center"
            v-for="(item, index) in tableData"
            :key="item.id"
          >
            <div class="td" layout="row" layout-align="center center">
              <div style="width: 60px; text-align: left">
                <el-checkbox
                  v-model="item.checked"
                  @change="changeCheckboxHandle('item')"
                  >{{ index + 1 }}</el-checkbox
                >
              </div>
            </div>
            <div class="td" layout="row" layout-align="center center">
              {{ item.n }}
            </div>
            <div class="td" layout="row" layout-align="center center">
              {{ item.p }}
            </div>
            <div class="td" layout="row" layout-align="center center">
              {{ item.s }}
            </div>
            <div
              class="td"
              layout="row"
              layout-align="center center"
              style="width: 200px"
            >
              {{ item.b }}
            </div>
            <div class="td" layout="row" layout-align="center center">
              {{ item.u }}
            </div>
          </div>
          <div class="no-data" v-if="tableData.length == 0">
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

    <!-- 修改姓名/手机号 -->
    <drawerUpdateAuthInfo
      v-model="showDrawer"
      :status="status"
      :userInfo="currentUserInfo"
      @getTableData="getTableData"
    />
  </div>
</template>

<script>
import { keyHandle } from "../../../../../mixin/keyhandle";
import api_wine from "@/api/wine";
import drawerUpdateAuthInfo from "../drawerUpdateAuthInfo.vue";
export default {
  data() {
    return {
      selectVal: 0,
      options: [
        {
          value: 0,
          label: "全部",
        },
        {
          value: 1,
          label: "开启",
        },
        {
          value: 2,
          label: "关闭",
        },
      ],
      keyword: "",
      checkAll: false,
      tableData: [],

      pageInfo: {
        page: 1,
        pageSize: 20,
        total: 0,
      },

      showDrawer: false,
      status: 1, // 1:修改姓名  2：修改手机号
      currentUserInfo: {}, // 当前修改的用户数据
    };
  },
  methods: {
    async getTableData() {
      const params = {
        page_num: this.pageInfo.page * 1, //   int    指定第几页
        page_size: this.pageInfo.pageSize, //  int     每页行数
        sms_flag: this.selectVal * 1, //   int  短信开关 0 不限 1 短信开启 2 短信关闭
        key: this.keyword, //   string   搜索关键字
      };

      try {
        const res = await api_wine.reqGetCustomList(params);
        if (res.code == 1) {
          this.tableData = (res.data.records || []).map((item) => ({
            ...item,
            checked: false,
          }));

          this.checkAll = false;

          this.pageInfo.total = res.data.row_cnt || 0;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("用户列表数据获取失败", error);
      }
    },
    // 开启或关闭短信
    async openOrCloseMsgHandle(type) {
      // type 1: 开启  2：关闭
      const params = {
        phone_nums: this.tableData
          .filter((item) => item.checked)
          .map((item) => item.p), //  []string   要修改的客户手机号列表
        enable_sms: type * 1, // int     短信状态 1 开启 2 关闭
      };

      if (params.phone_nums.length == 0)
        return this.$message.warning("请选择用户");
      try {
        const res = await api_wine.reqOpenOrCloseMsg(params);
        if (res.code == 1) {
          this.$message.success("操作成功");
          this.getTableData();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("开启或关闭短信操作失败", error);
      }
    },

    // 加入黑名单
    async addBlackList() {
      const currentInfoList = this.tableData.filter((item) => item.checked);
      if (currentInfoList.length == 0)
        return this.$message.warning("请选择用户后进行操作");
      const params = {
        phone_nums: currentInfoList.map((item) => item.p),
        cust_names: currentInfoList.map((item) => item.n),
      };
      const res = await api_wine.reqAddBlackList(params);
      if (res.code == 1) {
        this.$message.success("操作成功");
        this.getTableData();
      } else {
        this.$message.warning(res.msg);
      }
    },

    changeCheckboxHandle(type) {
      switch (type) {
        case "all":
          this.tableData.forEach((el) => {
            el.checked = this.checkAll;
          });
          break;
        case "item":
          this.checkAll = this.tableData.every((item) => item.checked);
          break;
      }
      this.ids = this.tableData
        .filter((item) => item.checked)
        .map((item) => item.id * 1);
    },

    updateUserInfo(status = 1) {
      const currentInfoList = this.tableData.filter((item) => item.checked);
      if (currentInfoList.length != 1)
        return this.$message.warning("请选择一个进行操作");
      this.status = status;
      this.showDrawer = true;
      this.currentUserInfo = currentInfoList[0];
    },

    changePageHandle(page = 1) {
      this.pageInfo.page = page;
      this.getTableData();
    },

    resetHandle() {
      this.keyword = "";
      this.selectVal = 0;
      this.getTableData();
    },
  },
  created() {
    this.getTableData();
  },
  mixins: [keyHandle],
  components: {
    drawerUpdateAuthInfo,
  },
  computed: {
    isIndeterminate() {
      return !this.checkAll && this.tableData.some((item) => item.checked);
    },
  },
};
</script>

<style lang="less" scoped>
@import "../../../../../style/wine/table.less";
</style>
<style scoped lang="less">
.user-list {
  .table {
    .tbody {
      height: calc(100vh - 330px);
      overflow: auto;
    }
  }
}
</style>
