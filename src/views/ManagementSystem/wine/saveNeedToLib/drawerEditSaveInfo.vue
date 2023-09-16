<template>
  <div>
    <!-- 修改存酒入库单 -->
    <el-drawer
      title="编辑"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="800px"
    >
      <div class="session edit-save-info p-5">
        <div class="top" layout="row" layout-align="start center">
          <div class="title">存酒详情</div>
          <div class="name">{{ currentSaveInfo.c }}</div>
          <div class="phone">{{ currentSaveInfo.p }}</div>
        </div>
        <div class="red fs14 m-t-3 m-b-3">点击散瓶规格可更改</div>
        <!-- 表格 -->
        <div class="table-content">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">名称</div>
                <div class="th">规格</div>
                <div class="th">每瓶克数</div>
                <div class="th">数量</div>
                <div class="th">授权人</div>
                <div class="th" style="width: 120px">操作</div>
              </div>
            </div>
            <div class="tbody">
              <div
                class="tr"
                layout="row"
                layout-align="space-between center"
                v-for="item in tableData"
                :key="item.id"
              >
                <div class="td">{{ item.n }}</div>
                <div class="td">
                  <div v-if="item.u == '整瓶'">{{ item.u }}</div>
                  <div v-else>
                    <el-select
                      v-model="item.u"
                      size="mini"
                      style="width: 100px"
                      placeholder="请选择"
                    >
                      <el-option
                        v-for="item in options"
                        :key="item.value"
                        :label="item.label"
                        :value="item.label"
                      ></el-option>
                    </el-select>
                  </div>
                </div>
                <div class="td">
                  <div v-if="item.u == '整瓶'">{{ item.g || "-" }}</div>
                  <div v-else>
                    <el-input
                      v-model="item.g"
                      size="mini"
                      style="width: 100px"
                    ></el-input>
                  </div>
                </div>
                <div class="td" layout="row" layout-align="center center">
                  <el-button
                    type
                    size="small"
                    style="
                      width: 26px;
                      padding: 0;
                      height: 26px;
                      border-radius: 50%;
                    "
                    icon="el-icon-minus"
                    :disabled="item.c <= 1"
                    @click="item.c = Math.max(1, item.c - 1)"
                  ></el-button>
                  <el-input
                    v-model="item.c"
                    size="mini"
                    style="width: 60px; margin: 0 10px"
                  ></el-input>
                  <el-button
                    type
                    size="mini"
                    :disabled="item.a != '-' && item.c >= item.ac"
                    style="
                      width: 26px;
                      padding: 0;
                      height: 26px;
                      border-radius: 50%;
                    "
                    icon="el-icon-plus"
                    @click="item.c++"
                  ></el-button>
                </div>
                <div class="td">{{ item.a }}</div>
                <div class="td" style="width: 120px">
                  <span
                    style="color: #2170ff; cursor: pointer"
                    @click="deleteHandle(item)"
                    >删除</span
                  >
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- 授权 -->
      <authCom
        ref="authRef"
        v-model="showAuthDrawer"
        :tableData="tableData"
        @emitHandle="submitSureHandle"
      />

      <el-dialog
        title="提示"
        :visible.sync="dialogVisible"
        append-to-body
        width="30%"
      >
        <p>确认入库吗？</p>
        <span slot="footer" class="dialog-footer">
          <el-button @click="dialogVisible = false">取 消</el-button>
          <el-button type="primary" @click="onSubmit">确 定</el-button>
        </span>
      </el-dialog>

      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="showAuthHandle">{{
          needWaiterAuth ? "服务员授权" : "确认入库"
        }}</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_wine from "@/api/wine";
import authCom from "../commonCom/auth.vue";
export default {
  data() {
    return {
      dialogVisible: false,
      tableData: [],
      showAuthDrawer: false,
      options: [
        { id: 1, label: "0.1" },
        { id: 2, label: "0.2" },
        { id: 3, label: "0.3" },
        { id: 4, label: "0.4" },
        { id: 5, label: "0.5" },
        { id: 6, label: "0.6" },
        { id: 7, label: "0.7" },
        { id: 8, label: "0.8" },
        { id: 9, label: "0.9" },
      ],
      authInfo: {},
    };
  },
  methods: {
    async onSubmit() {
      const { userName, passWord, type } = this.authInfo;
      const params = {
        auth_emp_code: userName, // string   授权人工号
        auth_emp_passwd: passWord, //  string   授权人密码
        pass_type: type, //  int   1 验证 员工号/密码  2 验证卡号/卡数据 为兼容之前的账号密码认证, 当=2的时候验证卡号和卡密, 共用emp_code,password
        bef_in_id: this.currentSaveInfo.o * 1, //  int64      //BefInId 待入库订单Id
        bef_in_dtl_ids: this.tableData.map((item) => item.id * 1), //  []int64   待入库子订单Id
        unit_types: this.tableData.map((item) =>
          item.u == "整瓶" ? "1" : item.u
        ), //  []string   对应子定单修改后的规格
        prd_cnts: this.tableData.map((item) => item.c * 1), //   []int   对应子订单修改后的商品数量
        g_cnts: this.tableData.map((item) => item.g * 1), //     []int        //GCnts 对应子订单修改后的克数
        remark_cust_phone: "", // string   客户中心存酒,备注客人手机号
        remark_cust_name: "", // string   客户中心存酒,备注客人姓名
      };
      try {
        const res = await api_wine.reqAuthSureToLib(params);
        if (res.code == 1) {
          this.$message.success("入库成功");
          this.showAuthDrawer = false;
          this.onCancelDrawer();
          this.$emit("getTableData");
        } else {
          if (type == 2) window.loopReadCard();
          this.$message.warning(res.msg);
        }
        this.dialogVisible = false;
      } catch (error) {
        if (type == 2) window.loopReadCard();
        console.log("授权修改存酒详情失败", error);
      }
    },

    deleteHandle(itemInfo) {
      const index = this.tableData.findIndex((item) => item.id == itemInfo.id);
      if (index > -1) {
        this.tableData.splice(index, 1);
      }
    },

    showAuthHandle() {
      if (this.needWaiterAuth) {
        if (this.tableData.length <= 0)
          return this.$message.warning("当前暂无商品可授权");
        this.showAuthDrawer = true;
      } else {
        // 仓库人员编辑完存酒单，不需要服务员授权，直接提交
        this.authInfo = { userName: "", passWord: "", type: 1 };
        this.dialogVisible = true;
      }
    },

    submitSureHandle({ userName, passWord, type }) {
      this.authInfo = { userName, passWord, type };
      this.dialogVisible = true;
    },

    onCancelDrawer() {
      this.show = false;
    },
  },
  mounted() {},
  props: {
    value: {
      default: false, // 是否显示drawer
    },
    currentSaveInfo: {
      default: () => ({}),
    },
    needWaiterAuth: {
      default: true,
    },
  },
  computed: {
    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      },
    },
  },
  components: {
    authCom,
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.tableData = JSON.parse(
            JSON.stringify(this.currentSaveInfo.ss || [])
          );
        } else {
        }
      },
      immediate: true,
    },
  },
};
</script>

<style scoped lang="less">
@import "../../../../style/common/elementDrawerWine.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/common/elementFormBtnWine.less";
@import "../../../../style/wine/table.less";
</style>

<style lang="less" scoped>
.edit-save-info {
  .top {
    .title {
      font-size: 20px;
      font-weight: 600;
    }
    .name {
      margin: 0 20px;
    }
  }
  .red {
    color: #f56c6c;
  }

  .table {
    .tbody {
      height: calc(100vh - 250px);
      overflow: auto;
    }
  }
}

/deep/.el-button--default {
  background-color: #fff;
}
</style>
