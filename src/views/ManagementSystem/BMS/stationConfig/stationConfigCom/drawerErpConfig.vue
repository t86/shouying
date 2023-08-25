<template>
  <div>
    <!-- erp权限管理 -->
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
            <span class="red-color fs14">*</span>
            <span class="fs14">请勾选erp仓库：</span>
          </div>
          <div class="value m-t-3 m-l-10">
            <el-checkbox
              v-for="(item) in erpList"
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
            <span class="fs14">请勾选是否有查看空瓶仓权限：</span>
          </div>
          <div class="value m-t-3 m-l-10">
            <el-checkbox
              :indeterminate="emptyLibIndeterminate"
              v-model="emptyLibCheckAll"
              @change="emptyLibIndeterminate=false"
            >空瓶仓管理</el-checkbox>
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
      erpList: [], 

      emptyLibCheckAll: false, // 空瓶仓权限管理全选
      emptyLibIndeterminate: false,  // 空瓶仓权限管理半选
    };
  },
  methods: {

    async getDetail() {
      const params = {
        station_ids: this.checkedList.map(item => item.id * 1)
      };
      try {
        const res = await this.$api.BMS.station.requestStationStoreAdmins(params);
        if (res.code == 1) {
          this.erpList = (res.data.store_admins || []).map(item => ({
            ...item,
            checked: item.st == 1
          }))
          this.emptyLibCheckAll = res.data.rtn_bt_sel_type == 1  // 空瓶仓全部选中
          this.emptyLibIndeterminate = res.data.rtn_bt_sel_type == 3  // 空瓶仓半选
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("数据请求失败", error);
      }
    },

    changeLoginConfigCheckboxHandle(val, itemInfo){
      this.erpList = this.erpList.map(item => ({
        ...item,
        checked: item.id == itemInfo.id ? val : item.checked,
        st: item.id == itemInfo.id ? (val ? 1 : 2) : item.st
      }))
    },

    async onSubmit() {
      const params = {
        station_ids: this.checkedList.map(item => item.id * 1), // []int64   与上面部门Id对应的, 角色Id列表
        sel_stores: this.erpList.filter(item => item.st == 1).map(item => item.id * 1), //  []int64   选中的存货仓库Id列表
        unchange_stores: this.erpList.filter(item => item.st == 3).map(item => item.id * 1), // []int64    部分选中的存货仓库Id列表(就是没有修改的部分选中的列表)
        rtn_bt_sel_type: this.emptyLibCheckAll ? 1 : (this.emptyLibIndeterminate ? 3 : 2) //  int   空瓶仓管理权限 1 选中 2 不选 3 部分选中
      }
      try {
        const res = await this.$api.BMS.station.requestStationSaveStoreAdmins(params)
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
      return "管理仓库";
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
          this.erpList = []
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