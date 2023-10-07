<template>
  <div>
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="60%"
    >
      <div class="session p-3 fs14">
        <!-- 头部筛选项 -->
        <div class="select-top" layout="col" style="width: 100%;">
          <div class="item" layout="row" layout-align="start center">
            <div class="reqfieldsd">*</div>
            <div class="label m-r-4">类别名称:</div>
            <el-input
              v-model="name"
              style="width: 200px"
              placeholder="1-10个字符"
            ></el-input>
          </div>
        </div>
      </div>
      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button size="small" type="info" @click.stop="closeDrawerHandle">取消</el-button>
        <el-button type="primary" size="small" @click="submitHandle">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import { TimeSelect } from 'element-ui';

export default {
  data() {
    return {
      show: false,
      // 筛选条件
      name: "",
    };
  },
  methods: {
    async submitHandle() {
      const params = {
        name: this.name,//   []int64   待添加商品列表
        id: this.item.id * 1,
      };

      if (params.name.length <= 0)
        return this.$message.warning("请填写分类名称");
      try {
        const res = await this.$api.BMS.statiscalConfig.reqSaveRptJkCateName(params)
        if(res.code == 1) {
          this.$message.success("修改成功！")
          this.closeDrawerHandle();
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("修改分类名称失败", error);
      }
    },
    // 关闭drawer
    closeDrawerHandle() {
      this.$emit("showOrHideDrawerHandle");
    }
  },
  props: {
    showDrawer: {
      default: false
    },
    item: {}
  },
  computed: {
    title() {
      return "更改类别名称" 
    },

  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.name = this.item.n
        this.mode = "2"
      }
    }
  }
};
</script>

<style scoped lang="less">
@import '../../../../../style/common/elementDrawerWine.less';
@import '../../../../../style/common/elementDrawerHeaderAndSession.less';
@import '../../../../../style/common/elementFormBtnWine.less';
@import '../../../../../style/erp/form.less';
@import '../../../../../style/erp/table.less';
</style>
<style scoped lang="less">
@import "./drawerAddStatCom.less";
</style>

<style>
.reqfieldsd {
  font-size: 16px;
  padding-right: 4px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.el-icon-arrow-right:before {
  color: #606266;
}
</style>