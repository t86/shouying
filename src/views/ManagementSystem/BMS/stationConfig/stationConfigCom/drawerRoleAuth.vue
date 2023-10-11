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
          <div class="label text-blue-500 p-4">请选择角色</div>
          <div class="value m-t-3 m-l-10">
            <el-checkbox
              v-for="item in erpList"
              :key="item.id"
              :indeterminate="item.st == 3"
              v-model="item.checked"
              class="m-b-2"
              @change="checkboxHandle(item)"
              >{{ item.n }}</el-checkbox
            >
          </div>
        </div>

        <div class="coll p-t-3" v-for="items in subList" :key="items.id">
          <div class="label">{{ items.t }}</div>
          <div
            layout="row"
            class="row value m-t-3 m-l-10"
            v-if="items.val.findIndex((i) => !i.row) >= 0"
          >
            <div class="m-t-2 m-b-2 m-l-2" v-for="item in items.val">
              <el-checkbox
                v-if="!item.row"
                v-model="item.checked"
                :disabled="item.disabled"
                :indeterminate="item.st == 3"
                @change="subCheckboxHandle(item)"
                >{{ item.n }}</el-checkbox
              >
              <p class="red-color fs12 m-t-2" v-if="item.m && !item.row">
                {{ item.m }}
              </p>
            </div>
          </div>
          <div
            layout="row"
            class="row value m-t-3 m-l-10"
            v-for="item in items.val.filter((i) => i.row)"
          >
            <div class="m-t-2 m-b-2 m-l-2">
              <el-checkbox
                v-if="item.row"
                v-model="item.checked"
                :indeterminate="item.st == 3"
                :disabled="item.disabled"
                @change="subCheckboxHandle(item)"
                >{{ item.n }}</el-checkbox
              >
              <p class="red-color fs12 m-t-2" v-if="item.m && item.row">
                {{ item.m }}
              </p>
            </div>
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
      subList: [],
      erpList: [
        {
          id: 231590937409810,
          n: "咨客",
          st: 1,
        },
        {
          id: 231590939409812,
          n: "服务员",
          st: 2,
          subList: {
            t: "服务员权限",
            val: [
              {
                id: 23159093740981201,
                n: "存取酒操作权限",
                st: 201,
              },
              {
                id: 23159093740981202,
                n: "存酒超额权限",
                st: 202,
              },
              {
                id: 23159093740981203,
                n: "服务员退单",
                st: 203,
              },
              {
                id: 23159093740981211,
                n: "不允许查看下属点单消费",
                st: 211,
                row: true,
                w: "勾选后点单人只能查看自己点单的卡台消费，不能查看下属点单卡台的消费",
              },
            ],
          },
        },
        {
          id: 231590939409814,
          n: "营销",
          st: 3,
          subList: {
            t: "营销权限",
            val: [
              {
                id: 23159093940981401,
                n: "不允许查看下属点单消费",
                st: 301,
                row: true,
              },
              {
                id: 23159093940981402,
                n: "查看同组点单消费",
                st: 302,
                row: true,
                w: "勾选后点单人可查看同组人员点单卡台的消费",
              },
            ],
          },
        },
        {
          id: 231731521431462,
          n: "特饮",
          st: 4,
        },
      ],
    };
  },
  methods: {
    async getDetail() {
      const params = {
        station_ids: this.checkedList.map((item) => item.id),
      };
      try {
        const res = await this.$api.BMS.station.reGetSysRolesAndAuthModule(
          params
        );
        if (res.code == 1) {
          const role_module = res.data.sys_role_modules;
          const roles = res.data.sys_roles.map((d) => {
            const sub_module = role_module.filter((e) => e.r == d.n);
            if (sub_module.length > 0) {
              d.subList = {
                id: d.id,
                t: d.n + "权限",
                val: sub_module.map((m) => {
                  return {
                    ...m,
                    rId: d.id,
                    row: m.m && m.m.length > 0,
                    checked: m.st == 1,
                  };
                }),
              };
            }
            d.checked = d.st == 1;
            return d;
          });

          this.erpList = roles;

          const haveSub = this.erpList.filter((e) => e.subList);
          this.subList = haveSub.map((e) => e.subList);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("数据请求失败", error);
      }
    },

    async onSubmit() {
      const sel_roles = this.erpList.filter((e) => e.st == 1);
      const unchange_roles = this.erpList.filter((e) => e.st == 3);

      let modules = [];
      this.subList.forEach((e) => {
        modules = [...modules, ...e.val];
      });

      const sel_modules = modules.filter((e) => e.st == 1);
      const unchange_modules = modules.filter((e) => e.st == 3);

      const params = {
        station_ids: this.checkedList.map((item) => item.id * 1), // []int64  角色Id列表
        sel_sys_roles: sel_roles.map((e) => e.id * 1), // 全选中的系统角色列表
        unchange_sys_roles: unchange_roles.map((e) => e.id * 1), // 部分选中的系统角色列表(就是没有修改的部分选中的列表)
        sel_sys_modules: sel_modules.map((e) => e.id * 1), // 全选中的系统角色模块明细模块项
        unchange_sys_modules: unchange_modules.map((e) => e.id * 1), // 部分选中的系统角色模块项
      };

      try {
        const res = await this.$api.BMS.station.reSetSysRolesAuthModule(params);
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
    checkboxHandle(item) {
      if (item.st == 3) {
        this.erpList = this.erpList.map((e) => {
          if (e.id == item.id) {
            e.checked = true;
            e.st = 1;
          }
          return e;
        });
      } else {
        this.erpList = this.erpList.map((e) => {
          if (e.id == item.id) {
            e.st = e.checked ? 1 : 2;
          }
          return e;
        });
      }
    },
    subCheckboxHandle(item) {
      // rId
      const erpItem = this.erpList.find((e) => e.id == item.rId);

      if (erpItem.st == 3) {
        // 角色 st == 3 只能取消
        if (item.st != 3) {
          this.$message.warning("该角色权限未全部包含,只能取消权限");
        }
        this.subList = this.subList.map((e) => {
          if (e.id == item.rId) {
            e.val = e.val.map((m) => {
              if (m.id == item.id) {
                m.checked = false;
                m.st = 2;
              }
              return m;
            });
          }
          return e;
        });
      } else if (erpItem.st == 1) {
        this.subList = this.subList.map((e) => {
          if (e.id == item.rId) {
            e.val = e.val.map((m) => {
              if (m.id == item.id) {
                m.st = m.checked ? 1 : 2;
              }
              return m;
            });
          }
          return e;
        });
      } else if (erpItem.st == 2) {
        if (item.checked && item.st == 2) {
          this.$message.warning("该角色权限未选,不能选中");
        }
        // 未选角色不能编辑 取消选中
        this.subList = this.subList.map((e) => {
          if (e.id == item.rId) {
            e.val = e.val.map((m) => {
              if (m.id == item.id) {
                m.checked = false;
                m.st = 2;
              }
              return m;
            });
          }
          return e;
        });
      }
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

// @tailwind base;
// @tailwind components;
// @tailwind utilities;
</style>

<style lang="less" scoped>
.coll {
  .label {
    width: 100%;
    text-align: left;
  }
  .value {
    flex-wrap: wrap;
  }
}
</style>
