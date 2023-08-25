<template>
  <div>
    <!-- 新增或修改erp仓库信息 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 erp-lib-detail fs14">
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red">*</span>
            <span>erp仓库名称：</span>
          </div>
          <div class="value">
            <el-input
              v-model="erpName"
              size="mini"
              @input="inputHandle"
              placeholder="请输入十个字以内的erp仓库名称"
            ></el-input>
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span>erp仓库描述：</span>
          </div>
          <div class="value">
            <el-input
              v-model="erpDes"
              type="textarea"
              :rows="2"
              size="mini"
              placeholder="请输入erp仓库描述"
            ></el-input>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      erpName: "",
      erpDes: ""
    };
  },
  methods: {
    async onSubmit() {
      if (this.erpName.length <= 0)
        return this.$message.warning("请输入erp仓库名称");
      const params = {
        name: this.erpName, //       string  仓库名称
        remark: this.erpDes, //     string   描述信息
        ...this.type == 2 && {id : this.currentInfo.id}
      };
      try {
        const api = this.type == 1 ? 'requeststorenew' : 'requeststoresave'
        const res = await  this.$api.ERP.store[api](params)
        if(res.code == 1) {
          this.onCancelDrawer()
          this.$emit('getTableData')
          this.$message.success('操作成功')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('新增失败', error);
      }
    },
    inputHandle() {
      this.$overall.character(this.erpName) > 20
        ? this.$message.warning("最大长度为10")
        : "";
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
    type: {
      default: 1
    },
    currentInfo: {
      default: () => ({})
    }
  },
  computed: {
    title() {
      return this.type == 1 ? "新增erp仓库" : "编辑erp仓库";
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
          if (this.type == 1) {
            this.erpName = "";
            this.erpDes = "";
          } else {
            this.erpName = this.currentInfo.n || "";
            this.erpDes = this.currentInfo.r || "";
          }
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
</style>