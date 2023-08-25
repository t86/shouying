<template>
  <div>
    <!-- 配置权限 -->
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
            <span class="fs14">请勾选权限：</span>
          </div>
          <div class="value m-t-3 m-l-10">
            <div v-for="item in configList" :key="item.id">
              <el-checkbox
                v-model="item.checked"
                :indeterminate="item.indeterminate"
                @change="item.indeterminate = false"
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
      configList: [],
    };
  },
  methods: {

    async getDetail() {
      const params = {
        station_ids: this.checkedList.map(item => item.id * 1)
      };
      try {
        const res = await this.$api.BMS.station.reqGetAuthLimitConfig(params);
        if (res.code == 1) {
          this.configList = (res.data || []).map(item => ({
            ...item,
            checked: item.st == 1,
            indeterminate: item.st == 3
          }))
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("数据请求失败", error);
      }
    },

    async onSubmit() {
      const params = {
        station_ids: this.checkedList.map(item => item.id * 1),
        sel_privs: this.configList.filter(item => item.checked).map(item => item.id * 1),
        unchange_privs: this.configList.filter(item => item.indeterminate).map(item => item.id * 1),
      }
      try {
        const res = await this.$api.BMS.station.reqSetAuthLimitConfig(params)
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
      return "配置权限";
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
          this.configList = []
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