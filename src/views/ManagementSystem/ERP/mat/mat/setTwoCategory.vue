<template>
  <div class="set-second-category">
    <el-dialog title="批量设置二级分类" :visible.sync="show" :close-on-click-modal="false">
      <section>
        <div class="item m-t-4">
          <span>二级分类：</span>
          <el-cascader placeholder="请选择二级分类" clearable :options="options" v-model="value"></el-cascader>
        </div>
      </section>
      <span slot="footer" class="dialog-footer">
        <el-button type="info" @click.native="closeDrawerHandle">取消</el-button>
        <el-button type="primary" @click.native="submitHandle">确定</el-button>
      </span>
    </el-dialog>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      value: [0, 0],
      show: false,
      options: []
    };
  },
  methods: {
    async getOptions() {
      try {
        const res = await this.$api.ERP.mcate.requestmcatetree()
        if (res.code == 1) {
          res.data = res.data || []
          this.options = res.data.map(item => ({
            ...item,
            label: item.n,
            value: item.id,
            children: (item.subs || []).map(items => ({
              ...items,
              label: items.n,
              value: items.id,
            }))
          }))
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('分类列表获取失败', error)
      }
    },
    submitHandle() {
      this.$emit("submitSecondCategoryHandle", this.value[1]);
    },
    closeDrawerHandle() {
      this.$emit("showOrHideSetSecondCategoryHandle");
    }
  },
  mounted() {},
  props: {
    showDrawer: {
      type: Boolean,
      default: false
    }
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.value = [0, 0]
        this.getOptions();
      } 
    }
  }
};
</script>

<style scoped lang="less">
.set-second-category{
    /deep/.el-dialog {
    width: 50vw;
    }
}
.button {
  display: inline-block;
  cursor: pointer;
  background-color: #2170ff;
  padding: 0px 10px;
  color: #fff;
  height: 26px;
  line-height: 26px;
  border-radius: 4px;
}

.bold {
  font-weight: 600;
}
</style>
<style>
.el-loading-mask.is-fullscreen {
  z-index: 9999 !important;
}
</style>