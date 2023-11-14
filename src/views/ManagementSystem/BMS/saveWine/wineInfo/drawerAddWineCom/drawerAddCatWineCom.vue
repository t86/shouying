<template>
  <div>
    <el-dialog :title="title" :visible.sync="showDrawer" :close-on-click-modal="false" :size="500">
      <div class="session">
        <!-- 头部筛选项 -->
        <div class="select-top" layout="Column" layout-align="start center">
          <div class="item" layout="row" layout-align="start center">
            <div class="label">
              <span class="red">*</span>
              <span>存酒分类名称：</span>
            </div>
            <el-input v-model="name" style="width: 250px" size="small" placeholder="请输入存酒分类名称(1-10个字)"></el-input>
          </div>
          <div class="item" layout="row" layout-align="start center">
            <div class="label">
              <span class="red">*</span>
              <span>整瓶有效期：</span>
            </div>
            <el-input v-model="full_expired_day" style="width: 250px" size="small" placeholder="请输入数字"></el-input>
            <span>天</span>
          </div>
          <div class="item" layout="row" layout-align="start center">
            <div class="label">
              <span class="red">*</span>
              <span>散瓶有效期：</span>
            </div>
            <el-input v-model="loose_expired_day" style="width: 250px" size="small" placeholder="请输入数字"></el-input>
            <span>天</span>
          </div>
        </div>
      </div>
      <!-- 提交按钮 -->
      <span slot="footer" class="dialog-footer">
        <el-button @click.stop="closeDrawerHandle">取消</el-button>
        <el-button type="primary" @click="submitHandle">确定</el-button>
      </span>
    </el-dialog>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      show: false,
      // 筛选条件
      name: "",
      full_expired_day: "",
      loose_expired_day: "",
    };
  },
  methods: {
    validator() {
      if (this.name == "") {
        this.$message.warning("请输入存酒分类名称")
        return false
      } else if (this.$overall.character(this.name) > 10) {
        this.$message.warning("存酒分类长度超过10")
        return false
      } else if (this.full_expired_day == "" || this.loose_expired_day == "") {
        this.$message.warning("请输入有效期")
        return false
      } else if (isNaN(this.full_expired_day) || isNaN(this.loose_expired_day)) {
        this.$message.warning("有效期为数字")
        return false
      }
      return true
    },

    // 重置
    restSearchData() {
      this.name = this.status == 2 ? this.currentInfo.n : "";
      this.full_expired_day = this.status == 2 ? this.currentInfo.f : "";
      this.loose_expired_day = this.status == 2 ? this.currentInfo.l : "";
    },
    async submitHandle() {
      if (!this.validator()) return
      const params = {
        id: this.status == 2 ? this.currentInfo.id : undefined,
        name: this.name,
        full_expired_day: Number(this.full_expired_day),
        loose_expired_day: Number(this.loose_expired_day),
      };
      try {
        const res = this.status == 2 ? await this.$api.BMS.saveWine.reqUpdateWineCate(params) : await this.$api.BMS.saveWine.reqNewWineCate(params);
        if (res.code == 1) {
          this.$message.success(this.status == 2 ? '编辑成功' : '添加成功')
          this.closeDrawerHandle();
          this.$emit("getTableData");
          this.$emit('getMenuList');
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log(this.status == 2 ? "编辑失败" : "添加失败", error);
      }
    },
    // 关闭drawer
    closeDrawerHandle() {
      this.$emit("showDrawerHandle");
    }
  },
  props: {
    showDrawer: {
      default: false
    },
    status: {
      default: 1 // 新增存酒分类   编辑存酒分类
    },
    currentInfo: {
      default: {}
    }
  },
  computed: {
    title() {
      return this.status == 1 ? "新增存酒分类" : "编辑存酒分类";
    },

    isIndeterminate() {
      if (
        this.tableData
          .filter(item => !item.disabled)
          .every(item => item.checked)
      ) {
        return false;
      } else {
        return this.tableData.some(item => item.checked);
      }
    }
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.restSearchData()
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "./drawerAddWineCom.less";
</style>

<style lang='less' scoped>
.red {
  color: #D9001B;
}

.label {
  width: 120px;
}

.el-icon-arrow-right:before {
  color: #606266;
}

/deep/.el-dialog {
  float: right;
  margin: 0 !important;
  height: 100vh;
  width: 700px;
}

/deep/.el-dialog__body {
  height: calc(100vh - 130px);
  padding: 0 20px;
  box-sizing: border-box;
  overflow: auto;
}

/deep/.el-dialog__footer {
  text-align: center;
}
</style>