<template>
    <div>
      <el-drawer
        :title="title"
        :visible.sync="show"
        :before-close="closeDrawerHandle"
        direction="rtl"
        size="720px"
        append-to-body
      >
      <el-form
        @submit.native.prevent
        label-position="right"
        label-width="150px"
        :model="formData"
        ref="drawerRef"
      >
        <el-form-item label="最低消费" class="required required4">
          <el-input
            v-model="formData.name"
            placeholder="请输入最低消费"
            type="number"
            min="0"
            style="width: 80%"
          >
          </el-input>
          <span class="m-l-1 white">元</span>
        </el-form-item>

        <div class="form-btn">
          <el-button type="info" @click="closeDrawerHandle">取消</el-button>
          <el-button type="primary" @click="onSubmit">保存</el-button
          >
        </div>
      </el-form>
      </el-drawer>
    </div>
  </template>
  
  <script>
  import api_vip from "@/api/vip";
  
  export default {
    props: {
      item: {},
      showDrawer: {
        default: false,
      },
      isDefault: {
        default: true,
      },

    },
    data() {
      return {
        formData: {
          name: "",
          pic: "",
          experienceThreshold: "",
        },
        show: false,
      };
    },
    methods: {
      // 关闭抽屉
      closeDrawerHandle() {
        this.resetFormHandle();
        this.$emit("showOrHideDrawerHandle");
      },
      // 重置form表单
      resetFormHandle() {
      },
      async onSubmit() {
        
      },
      
    },
    computed: {
      title() {
        return this.isDefault ? "新增等级" : "选择商品";
      },
    },
    watch: {
      showDrawer(newVal) {
        this.show = newVal;
        if (newVal) {
        }
      },
    },
  };
  </script>
  
  <style scoped lang="less">
  @import "../../../style/common/elementDrawerWine.less";
  @import "../../../style/common/elementDrawerHeaderAndSession.less";
  @import "../../../style/common/elementFormBtnWine.less";
  @import "../../../style/erp/form.less";
  @import "../../../style/erp/table.less";
  </style>
  <style scoped lang="less">
  </style>
  
  <style scoped lang="less">

  </style>
  