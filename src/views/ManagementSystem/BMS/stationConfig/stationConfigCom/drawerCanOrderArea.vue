<template>
  <div>
    <!-- 可点区域 -->
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
            <span class="fs14">选择可点区域：</span>
          </div>
          <div class="value m-t-3 m-l-10">
            <div class="m-l-10">
              <el-checkbox
                v-model="checkAll"
                @change="checkAllHandle($event)"
                :indeterminate="indeterminate"
                class="m-b-2"
              >全选</el-checkbox>
            </div>
            <div class="m-l-10" v-for="(item) in areaList" :key="item.id">
              <el-checkbox
                :indeterminate="item.st==3"
                v-model="item.checked"
                @change="changeLoginConfigCheckboxHandle($event, item)"
                class="m-b-2"
              >{{item.n}}</el-checkbox>
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
      checkAll: false,
      areaList: [],  // 可点区域列表
    };
  },
  methods: {
    async getDetail() {
      const params = {
        station_ids: this.checkedList.map(item => item.id * 1)
      };
      try {
        const res = await this.$api.BMS.station.requestStationWaiterRegions(params);
        if (res.code == 1) {
          this.areaList = (res.data || []).map(item => ({
            ...item,
            checked: item.st == 1
          }))
          this.checkAll = this.areaList.every(item => item.checked)

        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("数据请求失败", error);
      }
    },

    checkAllHandle() {
      this.areaList = this.areaList.map(item => ({
        ...item,
        checked: this.checkAll,
        st: this.checkAll ? 1 : 2
      }))
    },

    changeLoginConfigCheckboxHandle(val, itemInfo){
      this.areaList = this.areaList.map(item => ({
        ...item,
        checked: item.id == itemInfo.id ? val : item.checked,
        st: item.id == itemInfo.id ? (val ? 1 : 2) : item.st
      }))
      this.checkAll = this.areaList.every(item => item.checked)
    },

    async onSubmit() {
      const params = {
        station_ids: this.checkedList.map(item => item.id * 1),
        sel_regions: this.areaList.filter(item => item.st == 1).map(item => item.id * 1), //[]int64   选中的系统权限列表
        unchange_regions: this.areaList.filter(item => item.st == 3).map(item => item.id * 1),// []int64   部分选中的系统权限列表(就是没有修改的部分选中的列表)
      }
      try {
        const res = await this.$api.BMS.station.requestStationSaveWaiterRegions(params)
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
      return "可点区域";
    },

    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      }
    },

    indeterminate(){
      return this.areaList.some(item => item.checked) && !this.checkAll
    }
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.getDetail();
        } else {
          this.areaList = []
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