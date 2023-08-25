<template>
  <div class="add-or-update-reason">
    <el-dialog :title="title" :visible.sync="showDrawer" :close-on-click-modal="false" :size="500">
      <el-form label-position="left">
        <div class="form-item" layout="row" layout-align="center center">
          <div class="label">
            <span class="red">*</span> {{typeInfo[type].name}}理由名称：
          </div>
          <el-input style="width:300px" v-model="reasonText" :maxLength="10" placeholder="请输入十个文字" />
        </div>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="$emit('showDrawerHandle')">取消</el-button>
        <el-button type="primary" @click="submitHandle">{{this.dataInfo.id ? '保存' : '新建'}}</el-button>
      </span>
    </el-dialog>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      showDrawer: false,
      reasonText: ""
    };
  },
  methods: {
    async submitHandle() {
      if (this.reasonText.trim() === "")
        return this.$message.warning("请输入" + this.typeInfo[this.type].name + "理由");
      const params = this.dataInfo.id
        ? {
            id: this.dataInfo.id * 1, //   int64   卡台标签Id
            n: this.reasonText,   //  string  理由
          }
        : {
            name: this.reasonText,   //  string  理由
            type_id: this.typeInfo[this.type].id //     int  类型, 1 优惠理由  2 退单理由
          };

      try {
        const api = this.dataInfo.id ? "reqSaveReason" : "reqAddReason";
        const res = await this.$api.BMS.reason[api](params);
        if (res.code == 1) {
          this.$message.success("操作成功");
          this.$emit("showDrawerHandle");
          this.$emit("getTableData");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log(this.dataInfo.id ? "保存理由失败" : "新建理由失败", error);
      }
    }
  },
  props: {
    show: {
      default: false,
      type: Boolean
    },
    dataInfo: {
      default: {},
      type: Object
    },
    type: {
      default: ''
    },
    typeInfo: {
      default: {}
    }
  },
  watch: {
    show(newVal) {
      this.showDrawer = newVal;
      if (newVal) {
        this.reasonText = this.dataInfo.n || "";
      }
    },
    reasonText(newVal) {
      if (newVal.length > 10) this.$message.warning("理由最多可输入十个字");
    }
  },
  computed: {
    title() {
      return (this.dataInfo.id ? "编辑" : "新建") + this.typeInfo[this.type].name + "理由";
    }
  }
};
</script>

<style scoped lang="less">
@import "./drawerAddOrUpdateReason.less";
</style>