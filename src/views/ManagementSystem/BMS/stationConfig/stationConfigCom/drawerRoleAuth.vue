<template>
  <div>
    <!-- 查单权限 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 erp-lib-detail fs14">
        <!-- 请选择角色 -->
        <div class="coll">
          <div class="label">请选择角色</div>
          <div class="value m-t-3 m-l-10">
            <el-checkbox
              v-for="item in erpList"
              :key="item.id"
              :indeterminate="item.st == 3"
              v-model="item.checked"
              @change="changeLoginConfigCheckboxHandle($event, item)"
              class="m-b-2"
              >{{ item.n }}</el-checkbox
            >
          </div>
        </div>
        <!-- 营销权限 -->
        <div class="coll p-t-3">
          <div class="label">营销权限</div>
          <div class="value m-t-3 m-l-10">
            <div class="m-t-2 m-b-2">
              <el-checkbox
                :indeterminate="originConfig.bookInfo[0].isIndeterminate"
                v-model="originConfig.bookInfo[0].checked"
                :disabled="originConfig.bookInfo[0].disabled"
                @change="changeCheckbox('bookInfo', originConfig.bookInfo[0])"
                >不允许查看下属订位消费</el-checkbox
              >
              <p class="red-color fs12 m-t-2">
                勾选后订位人只能查看自己订位卡台的消费，不能查看下属订位卡台的消费
              </p>
            </div>
            <div>
              <el-checkbox
                :indeterminate="originConfig.bookInfo[1].isIndeterminate"
                v-model="originConfig.bookInfo[1].checked"
                :disabled="originConfig.bookInfo[1].disabled"
                @change="changeCheckbox('bookInfo', originConfig.bookInfo[1])"
                >查看同组订位消费</el-checkbox
              >
              <p class="red-color fs12 m-t-2">
                勾选后订位人可查看同组人员订位卡台的消费
              </p>
            </div>
          </div>
        </div>
        <!-- 服务员权限 -->
        <div class="coll">
          <div class="label">服务员权限</div>
          <div class="value m-t-3 m-l-10">
            <el-checkbox
              v-for="item in erpList"
              :key="item.id"
              :indeterminate="item.st == 3"
              v-model="item.checked"
              @change="changeLoginConfigCheckboxHandle($event, item)"
              class="m-b-2"
              >{{ item.n }}</el-checkbox
            >
          </div>
          <div class="value m-t-3 m-l-10">
            <div class="m-t-2 m-b-2">
              <el-checkbox
                :indeterminate="originConfig.orderInfo[0].isIndeterminate"
                v-model="originConfig.orderInfo[0].checked"
                :disabled="originConfig.orderInfo[0].disabled"
                @change="changeCheckbox('orderInfo', originConfig.orderInfo[0])"
                >不允许查看下属点单消费</el-checkbox
              >
              <p class="red-color fs12 m-t-2">
                勾选后点单人只能查看自己点单的卡台消费，不能查看下属点单卡台的消费
              </p>
            </div>
            <div>
              <el-checkbox
                :indeterminate="originConfig.orderInfo[1].isIndeterminate"
                v-model="originConfig.orderInfo[1].checked"
                :disabled="originConfig.orderInfo[1].disabled"
                @change="changeCheckbox('orderInfo', originConfig.orderInfo[1])"
                >查看同组消费</el-checkbox
              >
              <p class="red-color fs12 m-t-2">
                勾选后点单人可查看同组人员点单卡台的消费
              </p>
            </div>
          </div>
        </div>
        <!-- 收银员权限 -->
        <div class="coll">
          <div class="label">收银员权限</div>
          <div class="value m-t-3 m-l-10">
            <el-checkbox
              v-for="item in erpList"
              :key="item.id"
              :indeterminate="item.st == 3"
              v-model="item.checked"
              @change="changeLoginConfigCheckboxHandle($event, item)"
              class="m-b-2"
              >{{ item.n }}</el-checkbox
            >
          </div>
        </div>
        <!-- 仓库管理员权限 -->
        <div class="coll">
          <div class="label">仓库管理员权限</div>
          <div class="value m-t-3 m-l-10">
            <el-checkbox
              v-for="item in erpList"
              :key="item.id"
              :indeterminate="item.st == 3"
              v-model="item.checked"
              @change="changeLoginConfigCheckboxHandle($event, item)"
              class="m-b-2"
              >{{ item.n }}</el-checkbox
            >
          </div>
        </div>
        <!-- 会员中心权限 -->
        <div class="coll">
          <div class="label">会员中心权限</div>
          <div class="value m-t-3 m-l-10">
            <el-checkbox
              v-for="item in erpList"
              :key="item.id"
              :indeterminate="item.st == 3"
              v-model="item.checked"
              @change="changeLoginConfigCheckboxHandle($event, item)"
              class="m-b-2"
              >{{ item.n }}</el-checkbox
            >
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
export default {
  data() {
    return {
      erpList: [
        {
          id: 231590937409810,
          n: "总仓",
          st: 1,
        },
        {
          id: 231590939409812,
          n: "大厅仓",
          st: 1,
        },
        {
          id: 231590939409814,
          n: "包厢仓",
          st: 1,
        },
        {
          id: 231731521431462,
          n: "zwj-test仓库",
          st: 2,
        },
      ],
      checkAll: false,
      indeterminate: false,
      originConfig: {
        bookInfo: [
          {
            checked: false,
            disabled: false,
            indeterminate: false,
          },
          {
            checked: false,
            disabled: false,
            indeterminate: false,
          },
        ],
        orderInfo: [
          {
            checked: false,
            disabled: false,
            indeterminate: false,
          },
          {
            checked: false,
            disabled: false,
            indeterminate: false,
          },
        ],
      },
    };
  },
  methods: {
    async getDetail() {
      const params = {
        station_ids: this.checkedList.map((item) => item.id),
      };
      try {
        const res = await this.$api.BMS.station.reqGetLookOrderConfig(params);
        if (res.code == 1) {
          this.checkAll = res.data.full_check_sel_type == 1;
          this.indeterminate = res.data.full_check_sel_type == 3;
          this.originConfig = {
            bookInfo: [
              {
                id: 1,
                checked: res.data.sales_self_sel_type == 1,
                disabled: this.checkAll,
                indeterminate: res.data.sales_self_sel_type == 3,
              },
              {
                id: 2,
                checked: res.data.sales_dept_sel_type == 1,
                disabled: this.checkAll,
                indeterminate: res.data.sales_dept_sel_type == 3,
              },
            ],
            orderInfo: [
              {
                id: 1,
                checked: res.data.order_self_sel_type == 1,
                disabled: this.checkAll,
                indeterminate: res.data.order_self_sel_type == 3,
              },
              {
                id: 2,
                checked: res.data.order_dept_sel_type == 1,
                disabled: this.checkAll,
                indeterminate: res.data.order_dept_sel_type == 3,
              },
            ],
          };
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("数据请求失败", error);
      }
    },

    lookOrderCheckBoxChange() {
      this.indeterminate = false;
      this.originConfig = {
        bookInfo: [
          {
            id: 1,
            checked: false,
            disabled: this.checkAll,
            indeterminate: false,
          },
          {
            id: 2,
            checked: false,
            disabled: this.checkAll,
            indeterminate: false,
          },
        ],
        orderInfo: [
          {
            id: 1,
            checked: false,
            disabled: this.checkAll,
            indeterminate: false,
          },
          {
            id: 2,
            checked: false,
            disabled: this.checkAll,
            indeterminate: false,
          },
        ],
      };
    },

    changeCheckbox(type, itemInfo) {
      this.originConfig[type].forEach((el) => {
        if (el.id == itemInfo.id) {
        } else {
          el.checked = false;
        }
        el.indeterminate = false;
      });
      console.log(this.originConfig);
      this.$forceUpdate();
    },

    async onSubmit() {
      const { bookInfo, orderInfo } = this.originConfig;

      const params = {
        station_id: this.checkedList.map((item) => item.id * 1), // []int64  岗位Id列表
        full_check_sel_type: this.checkAll ? 1 : this.indeterminate ? 3 : 2, // int   全场查单权限配置类型 1 全选 2 全不选 3 部分选中
        sales_self_sel_type: bookInfo[0].checked
          ? 1
          : bookInfo[0].indeterminate
          ? 3
          : 2, // int   订位人组织,仅查看自己订位消费配置类型 1 全选 2 全不选 3 部分选中
        sales_dept_sel_type: bookInfo[1].checked
          ? 1
          : bookInfo[1].indeterminate
          ? 3
          : 2, // int   订位人组织,查看同组订位消费 1 全选 2 全不选 3 部分选中
        order_self_sel_type: orderInfo[0].checked
          ? 1
          : orderInfo[0].indeterminate
          ? 3
          : 2, // int  点单人组织,仅查看自己点单消费配置类型 1 全选 2 全不选 3 部分选中
        order_dept_sel_type: orderInfo[1].checked
          ? 1
          : orderInfo[1].indeterminate
          ? 3
          : 2, // int   点单人组织,查看同组点单消费配置类型 1 全选 2 全不选 3 部分选中
      };

      try {
        const res = await this.$api.BMS.station.reqSetLookOrderConfig(params);
        if (res.code == 1) {
          this.$message.success("设置成功");
          this.onCancelDrawer();
          this.$emit("getTableData");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("查单权限设置失败", error);
      }
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
    checkedList: {
      default: () => [],
    },
  },
  computed: {
    title() {
      return "角色权限";
    },

    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      },
    },
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.getDetail();
        } else {
          this.areaList = [];
        }
      },
      immediate: true,
    },
  },
};
</script>

<style scoped lang="less">
@import "../../../../../style/common/elementDrawerWine.less";
@import "../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../style/erp/form.less";
@import "../../../../../style/erp/table.less";
</style>

<style lang="less" scoped>
.coll {
  .label {
    width: 100%;
    text-align: left;
  }
}
</style>
