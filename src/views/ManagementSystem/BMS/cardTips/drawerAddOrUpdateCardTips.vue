<template>
  <div class="add-or-update-card-tips">
    <el-dialog :title="title" :visible.sync="showDrawer" :close-on-click-modal="false" :size="500">
      <el-form label-position="left">
        <div class="form-item m-b-6" layout="row" layout-align="center center">
          <div class="label">
            <span class="red">*</span>标签名称：
          </div>
          <el-input style="width:300px" v-model="cardName" :maxLength="10" placeholder="请输入一到十个文字" />
        </div>
        <div class="form-item" layout="row" layout-align="center center">
          <div class="label">
            <span class="red">*</span>显示标记：
          </div>
          <el-input style="width:300px" v-model="textTips" :maxLength="1" placeholder="请输入一个文字" />
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
      cardName: "",
      textTips: ""
    };
  },
  methods: {
    async submitHandle() {
      if (this.cardName.trim() === "" || this.textTips.trim() === "")
        return this.$message.warning("请输入必填项");
      const params = this.dataInfo.id
        ? {
            id: this.dataInfo.id * 1, //   int64   卡台标签Id
            n: this.textTips, //   string    卡台标签名称
            r: this.cardName  //    string   卡台标签描述
          }
        : {
            name: this.textTips, //       string    卡台标签名称
            remark: this.cardName //    string   卡台标签描述
          };

      try {
        const api = this.dataInfo.id ? "saveCardTips" : "addCardTips";
        const res = await this.$api.BMS.cardTips[api](params);
        if (res.code == 1) {
          this.$message.success("操作成功");
          this.$emit("showDrawerHandle");
          this.$emit("getTableData");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log(this.dataInfo.id ? "保存标签失败" : "新建标签失败", error);
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
    }
  },
  watch: {
    show(newVal) {
      this.showDrawer = newVal;
      if (newVal) {
        this.cardName = this.dataInfo.r || "";
        this.textTips = this.dataInfo.n || "";
      }
    },
    cardName(newVal) {
      if (newVal.length > 10) this.$message.warning("请输入一到十个字");
    },
    textTips(newVal) {
      if (newVal.length > 1) this.$message.warning("请输入一个字");
    }
  },
  computed: {
    title() {
      return (this.dataInfo.id ? "编辑" : "新建") + "标签";
    }
  }
};
</script>

<style scoped lang="less">
@import "./drawerAddOrUpdateCardTips.less";
</style>