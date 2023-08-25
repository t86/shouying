<template>
  <div>
    <!-- 新增或修改erp二级分类 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 fs14">
        <div class="coll m-b-2" layout="row" layout-align="start center">
          <div class="label">
            <span>一级分类名称:</span>
          </div>
          <div class="value">{{oneCateInfo.n}}</div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red">*</span>
            <span>二级分类名称:</span>
          </div>
          <div class="value">
            <el-input
              v-model="twoCateName"
              size="mini"
              placeholder="请输入二级分类名称"
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
      oneCateInfo: {},
      twoCateName: "",
    };
  },
  methods: {
    async onSubmit() {
      if (this.twoCateName.length <= 0)
        return this.$message.warning("请输入二级分类名称");
      const params = {
        name: this.twoCateName || '',
        mat_one_cate_id: this.oneCateInfo.id,
        ...this.type == 2 && {id : this.currentInfo.id}
      };
      try {
        const api = this.type == 1 ? 'requestmtcatenew' : 'requestmtcatesave'
        const res = await this.$api.ERP.mtcate[api](params)
        if(res.code == 1) {
          this.onCancelDrawer()
          this.$emit('getTableData')
          this.$emit('getMenuList')
          this.$message.success('操作成功')
        } else if (res.code == 6) {
          this.onCancelDrawer()
          this.$emit('getTableData')
          this.$emit('getMenuList')
          this.$message.warning("创建成功，状态无效，" + res.msg)
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('新增失败', error);
      }
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
    menuList: {
      default: () => ([])
    },
    currentInfo: {
      default: () => ({})
    }
  },
  computed: {
    title() {
      return this.type == 1 ? "新增二级分类" : "编辑二级分类";
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
            this.twoCateName = "";
            const oneCateInfo = this.menuList.find(item => item.id == this.$route.query.menuId)
            this.oneCateInfo = oneCateInfo || {}
          } else {
            this.twoCateName = this.currentInfo.n || "";
          }
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../../../style/common/elementDrawerWine.less";
@import "../../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../../style/erp/form.less";
</style>