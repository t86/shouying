<template>
  <div>
    <!-- 查看我的替身 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      append-to-body
      :size="size"
    >
    <!--         
        e          string     //EmpName 员工姓名,前面会有空格表示层次, 需要对空格进行处理, 让页面能展示
        d          string     //DeptName 部门姓名
        c          string     //EmpCode 员工工号
      -->
    <div class="table-content table2">
        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="start center">
              <div class="th">序号</div>
              <div class="th">员工姓名</div>
              <div class="th">部门名称</div>
              <div class="th">员工工号</div>
            </div>
          </div>
          <div class="tbody">
            <div
              class="tr"
              v-for="(item, index) in tableData"
              :key="index"
              layout="row"
              layout-align="start center"
            >
              <div class="td">{{ index + 1 }}</div>
              <div class="td">{{ item.e }}</div>
              <div class="td">{{ item.d }}</div>
              <div class="td">{{ item.c }}</div>
            </div>
            <div class="no-data" v-if="tableData.length == 0">
              <img src="@/assets/img/wu.png" alt />
              <p>暂无数据</p>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="primary" @click.native="onCancelDrawer">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      tableData: [],
    };
  },
  methods: {
    // 获取获取指定员工的下级(
    async getTableData(){
      try {
        const res = await this.$api.BMS.emp.reqGetMyCloneList({
          id: this.id * 1 // int64  员工Id
        })
        if (res.code == 1){
          this.tableData = res.data.records || []
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取我的下级失败', error)
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
    id:{
      default: '' // 员工id
    }
  },
  computed: {
    title() {
      return '我的替身'
    },

    size() {
      return '720px'
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
          this.show = newVal;
          this.getTableData();
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../../../../style/common/elementDrawerWine.less";
@import "../../../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../../../style/erp/form.less";
@import "../../../../../../../style/erp/table.less";
</style>

<style lang="less" scoped>
.coll {
  margin-top: 16px;
  .label {
    width: 120px;
  }
}
</style>