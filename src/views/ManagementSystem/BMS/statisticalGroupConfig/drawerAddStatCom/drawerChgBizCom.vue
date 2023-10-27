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
            <div class="label m-r-4">营业类型:</div>
            <div class="m-t-3 m-l-3">
              <el-radio  v-model="bizType" label="3"
                >全部</el-radio
              >
            </div>
            <div  class="m-t-3 m-l-3">
              <el-radio v-model="bizType" label="1"
                >主营</el-radio
              >
            </div>
            <div  class="m-t-3 m-l-3">
              <el-radio v-model="bizType" label="2"
                >非主营</el-radio
              >
            </div>
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
      bizType: "",
    };
  },
  methods: {
    validator() {
      if (this.bizType == "") {
        this.$message.warning("请选择营业类型")
        return false
      }
      return true
    },
    async submitHandle() {
      if(!this.validator()) return
      const params = {
        biz_type: this.bizType * 1,//BizType 营业类型 1 主营 2 非主营 3 全部
        id: this.item.id * 1,  //Id 缴款单分类Id
      };

      if (params.biz_type <= 0)
        return this.$message.warning("请选择营业类型");
      try {
        const res = await this.$api.BMS.statiscalConfig.reqSaveRptJkCateBizType(params)
        if(res.code == 1) {
          this.$message.success("修改成功！")
          this.closeDrawerHandle();
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("修改营业类型失败", error);
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
      return "更改营业类型" 
    },

  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        console.log("type:", this.item.b)
        this.bizType = this.item.b + ""
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