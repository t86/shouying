<template>
  <div>
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="40%"
    >
      <div class="session p-3 fs14">
        <!-- 头部筛选项 -->
        <div class="select-top" layout="col" style="width: 100%;">
          <div class="item" layout="row" layout-align="start center">
            <div class="reqfieldsd">*</div>
            <div class="label">类别名称:</div>
            <el-input
              v-model="name"
              style="width: 200px"
              placeholder="1-10个字符"
            ></el-input>
          </div>
          <div class="item m-t-4" layout="row" layout-align="start center">
            <div class="reqfieldsd">*</div>
            <p class="m-t-3">模式</p>
            <div class="m-t-3 m-l-3">
              <el-radio  v-model="mode" label="2"
                >分类模式<span style="color: red">(推荐)</span></el-radio
              >
            </div>
            <div  class="m-t-3 m-l-3">
              <el-radio v-model="mode" label="1"
                >优惠下单<span style="color: red">(特例)</span></el-radio
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
      name: "",
      channelInfo: [
      ],
      mode: "2", // 分类模式：2， 商品模式：1
    };
  },
  methods: {
    async submitHandle() {
      const params = {
        name: this.name,//   []int64   待添加分类名称
        type_id: this.mode * 1,
      };

      if (params.name.length <= 0)
        return this.$message.warning("请填写分类名称");
        if (params.mode * 1 <= 0)
        return this.$message.warning("请选择分类模式");

      try {
        const res = await this.$api.BMS.statiscalConfig.reqNewRptJkCate(params)
        if(res.code == 1) {
          this.closeDrawerHandle();
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("创建统计类别失败", error);
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
  },
  computed: {
    title() {
      return "新增类别" 
    },

  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.name = ""
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