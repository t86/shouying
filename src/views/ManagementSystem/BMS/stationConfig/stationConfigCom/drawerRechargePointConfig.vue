<template>
  <div>
    <!-- 登录权限 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 erp-lib-detail fs14">
        <div class="coll">
          <div class="label">
            <span class="fs14">请勾选可登录的系统：</span>
          </div>
          <div class="value m-t-3 m-l-10">
            <el-checkbox
              v-for="(item) in sysList"
              :key="item.id"
              :indeterminate="item.st==3"
              v-model="item.checked"
              @change="changeLoginConfigCheckboxHandle($event, item)"
              class="m-b-2"
            >{{item.n}}</el-checkbox>
          </div>
        </div>
        <div class="coll">
          <div class="label">
            <span class="fs14">点单系统权限：</span>
          </div>
          <div class="value m-t-3 m-l-10">
            <el-checkbox
              v-for="(item) in sysModuleList"
              :key="item.id"
              :indeterminate="item.st==3"
              v-model="item.checked"
              @change="changeOrderConfigCheckboxHandle($event, item)"
              class="m-b-2"
            >{{item.n}}</el-checkbox>
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
      sysList: [],  // 登录权限里列表
      sysModuleList: [], // 点单系统权限
    };
  },
  methods: {
    async getDetail() {
      const params = {
        station_ids: this.checkedList.map(item => item.id * 1)
      };
      try {
        const res = await this.$api.BMS.station.requestStationSysPrivs(params);
        if (res.code == 1) {
          this.sysList = (res.data.sys_privs || []).map(item => ({
            ...item,
            checked: item.st == 1,
          }))

          this.sysModuleList = (res.data.sys_module_privs || []).map(item => ({
            ...item,
            checked: item.st == 1
          }))
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("数据请求失败", error);
      }
    },

    changeLoginConfigCheckboxHandle(val, itemInfo){
      this.sysList = this.sysList.map(item => ({
        ...item,
        checked: item.id == itemInfo.id ? val : item.checked,
        st: item.id == itemInfo.id ? (val ? 1 : 2) : item.st
      }))
    },

    changeOrderConfigCheckboxHandle(val, itemInfo){
      this.sysModuleList = this.sysModuleList.map(item => ({
        ...item,
        checked: item.id == itemInfo.id ? val : item.checked,
        st: item.id == itemInfo.id ? (val ? 1 : 2) : item.st
      }))
    },

    async onSubmit() {
      const params = {
        station_ids: this.checkedList.map(item => item.id * 1),
        sel_auth_modes: this.sysList.filter(item => item.st == 1).map(item => item.id * 1), //[]int64   选中的系统权限列表
        unchange_auth_modes: this.sysList.filter(item => item.st == 3).map(item => item.id * 1),// []int64   部分选中的系统权限列表(就是没有修改的部分选中的列表)
        sel_sys_modules: this.sysModuleList.filter(item => item.st == 1).map(item => item.id * 1), // []int64     选择的系统权限明细模块项
        unchange_sys_modules: this.sysModuleList.filter(item => item.st == 3).map(item => item.id * 1), // []int64    部分选中的系统权限明细模块项
      }
      try {
        const res = await this.$api.BMS.station.requestStationSaveSysPrivs(params)
        if(res.code == 1) {
          this.$message.success('操作成功')
          this.onCancelDrawer()
          this.$emit('getTableData')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },

    onCancelDrawer() {
      this.show = false;
    }
  },
  mounted() {},
  props: {
    value: {
      default: false // 是否显示drawer
    },
    checkedList: {
      default: () => []
    }
  },
  computed: {
    title() {
      return "登录权限";
    },

    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      }
    }
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.getDetail();
        } else {
          this.sysList = []
        }
      },
      immediate: true
    }
  }
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