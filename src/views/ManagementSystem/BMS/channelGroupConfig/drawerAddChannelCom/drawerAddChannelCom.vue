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
          <div class="item" layout="row" layout-align="start center">
            <div class="reqfieldsd">*</div>
            <div class="label">选择该类别包含渠道:</div>
            <div layout="col" class="m-t-2 col">
              <div class="m-l-2" v-for="item in channelInfo" :key="item.id">
                <el-checkbox
                  v-model="item.checked"
                  :checked="item.isCheck"
                  :disabled="item.isDisabled"
                  @change="changeCheckBoxHandle('item')"
                >{{item.n + (item.ci > 0 ? "-" + item.cn : "")}}</el-checkbox>
              </div>
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
export default {
  data() {
    return {
      show: false,
      // 筛选条件
      name: "",
      channelInfo: [
      ]
    };
  },
  methods: {
    async getTableData(){
      this.name = this.item?this.item.n : ""
      try {
        const res = await this.$api.BMS.channelConfig.reqSavePrdConfig()
        if(res.code == 1) {
          this.channelInfo = res.data.records
          this.channelInfo.forEach(item => {
            if(item.ci > 0){
              item.isCheck = true
              item.isDisabled = this.item.id != item.ci
            }
          });
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("添加商品失败", error);
      }
    },
    // 改变多选框的值
    changeCheckboxHandle(itemInfo) {
      this.channelInfo = this.channelInfo.map((item) => ({
        ...item,
        checked: item.id == itemInfo.id,
        isCheck: item.id == itemInfo.id ? !itemInfo.isCheck : itemInfo.isCheck
      }));
      this.$forceUpdate();
    },
    async submitHandle() {
      const params = {
        id: this.item ? this.item.id : 0, //   新建
        name: this.item ? this.item.n : this.name,
        pay_cnl_ids: this.channelInfo.filter(item => item.isCheck && (!item.isDisabled || (this.item && this.item.id == item.ci))).map(item => item.id)
      };

      if (params.pay_cnl_ids.length <= 0)
        return this.$message.warning("请选择需要添加的渠道");

      try {
        const res = await this.$api.BMS.channelConfig.reqGetPrdConfig(params)
        if(res.code == 1) {
          this.closeDrawerHandle();
          this.$emit("getTableData");
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("添加商品失败", error);
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
    item: {
      default: {}
    }
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
        this.getTableData()
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
@import "./drawerAddChannelCom.less";
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