<template>
  <div class="back-list">
    <div class="top" layout="row" layout-align="start center">
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
      <el-button type="primary" size="small" @click="toUserListHandle"
        >移出黑名单</el-button
      >
      <el-button type="primary" size="small" @click="toBalckListHandle"
        >添加黑名单</el-button
      >
      <el-button type="primary" size="small" @click="batchImport"
        >批量导入</el-button
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
            <div class="th">客户姓名</div>
            <div class="th">手机号码</div>
            <div class="th">更新时间</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            :class="{ selected: item.checked }"
            layout="row"
            layout-align="space-between center"
            v-for="(item, index) in tableData"
            :key="index"
          >
            <div class="td" layout="row" layout-align="center center">
              <div style="width: 60px; text-align: left">
                <el-checkbox
                  :value="item.checked"
                  @change="changeCheckboxHandle('item', item)"
                  >{{ index + 1 }}</el-checkbox
                >
              </div>
            </div>
            <div class="td">{{ item.n }}</div>
            <div class="td">{{ item.p }}</div>
            <div class="td">{{ item.u }}</div>
          </div>
          <div class="no-data" v-if="tableData.length == 0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>

    <drawerImportEmp v-model="showImportDrawer" @getTableData="getTableData" />

    <el-dialog
      title="移出黑名单"
      @close="removeBlackListDialog = false"
      :visible.sync="removeBlackListDialog"
      :close-on-click-modal="false"
    >
      <div style="height: 60px; padding-top: 30px; ">
        <span>确认将所选客户移出黑名单？</span>
      </div>
      <span slot="footer" class="dialog-footer">
        <el-button @click="removeBlackListDialog = false">取消</el-button>
        <el-button type="primary" @click="removeBlackListHandle">确认</el-button>
      </span>
    </el-dialog>

    <el-dialog
      title="添加黑名单"
      @close="blackListDialog = false"
      :visible.sync="blackListDialog"
      :close-on-click-modal="false"
    >
      <el-form label-position="left">
        <div class="compatibility" layout="row" layout-align="start center">
          <div class="mandatory">姓名：</div>
          <div class="value">
              <el-input
                v-model="userName"
                size="small"
                :maxLength="10"
                placeholder="1-10个字"
                style="width:200px"
              ></el-input>
            </div>
        </div>
      </el-form>
      <el-form label-position="left">
        <div class="compatibility" layout="row" layout-align="start center">
          <div class="mandatory"><span class="color-red">*</span>手机号码：</div>
          <div class="value">
              <el-input
                v-model="phoneNum"
                size="small"
                :maxLength="11"
                placeholder="输入正确的手机号码"
                style="width:200px"
              ></el-input>
            </div>
        </div>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="blackListDialog = false">取消</el-button>
        <el-button type="primary" @click="addBlackListHandle">确认</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import api_wine from "@/api/wine";

export default {
  components: {
    drawerImportEmp: () => import("./drawerCom/drawerImportBlackUserList.vue"),
  },
  
  data() {
    return {
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
      showImportDrawer: false,
      blackListDialog: false,
      removeBlackListDialog: false,
      tableData: [],
      userName: '',
      phoneNum: '',
    };
  },
  methods: {
    async getTableData() {
      const params = {
        key: this.keyword, //   string   搜索关键字
      };

      try {
        const res = await api_wine.reqGetBlackList(params);
        if (res.code == 1) {
          this.tableData = (res.data.records || []).map((item) => ({
            ...item,
            checked: false,
          }));

          this.checkAll = false;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("用户列表数据获取失败", error);
      }
    },

    async removeBlackListHandle(){
      const currentInfoList = this.tableData.filter((item) => item.checked);
      if (currentInfoList.length == 0){
        return this.$message.warning("请选择用户后进行操作");
      }
      const params = {
        phone_nums: currentInfoList.map((item) => item.p),
        cust_names: currentInfoList.map((item) => item.n),
      };
      const res = await api_wine.reqDeleteBlackList(params);
      if (res.code == 1) {
        this.$message.success("操作成功");
        this.removeBlackListDialog = false
        this.getTableData();
      } else {
        this.$message.warning(res.msg);
      }
    },
    // 移出黑名单
    async toUserListHandle() {
      const currentInfoList = this.tableData.filter((item) => item.checked);
      if (currentInfoList.length == 0){
        return this.$message.warning("请选择用户后进行操作");
      }
      this.removeBlackListDialog = true
    },

    toBalckListHandle(){
      this.blackListDialog = true
    },
    async addBlackListHandle(){
      if (!this.phoneNum || this.phoneNum.length != 11){
            return this.$message.warning("请输入11位手机号码");
      }
      const params = {
        phone_nums: [this.phoneNum],
        cust_names: [this.userName],
      };
      const res = await api_wine.reqAddBlackList(params);
      if (res.code == 1) {
        this.$message.success("操作成功");
        this.blackListDialog = false
        this.phoneNum = ""
        this.userName = ""
        this.getTableData();
      } else {
        this.$message.warning(res.msg);
      }
    },

    // 批量导入
    async batchImport() {
      this.showImportDrawer = true;
    },

    changeCheckboxHandle(type, item) {
      switch (type) {
        case "all":
          this.tableData.forEach((el) => {
            el.checked = this.checkAll;
          });
          break;
        case "item":
          this.tableData.forEach((el) => {
            if (el.p == item.p) {
              el.checked = !el.checked;
            }
          });
          this.checkAll = this.tableData.every((item) => item.checked);
          break;
      }
      this.ids = this.tableData
        .filter((item) => item.checked)
        .map((item) => item.id * 1);
    },

    changePageHandle(page = 1) {
      this.pageInfo.page = page;
      this.getTableData();
    },

    resetHandle() {
      this.keyword = "";
      this.getTableData();
    },
  },
  created() {
    this.resetHandle();
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
.back-list {
  .table {
    .tbody {
      height: calc(100vh - 330px);
      overflow: auto;
    }
  }

  .mandatory {
    width: 80px;
  }
}
</style>
