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
            <div class="label">选择该类别包含的二级分类:</div>
          </div>
          <el-tree 
              ref="treeRef"
              :data="data" 
              default-expand-all
              show-checkbox 
              node-key="id" 
              :default-checked-keys="selectedKeys"
              :props="defaultProps"
              multiple
            >
            </el-tree>
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
      data: [],
      defaultProps: {
        label: 'n',
        children: 'ss'
      },
      selectedKeys: []
    };
  },
  methods: {

    async getTableData(init = 1) {
      try {
        const res = await this.$api.BMS.statiscalConfig.reqGetRptJkCateCatesItems()
        if(res.code == 1) {
            this.data = res.data.cates.filter(item => item.ss).map(item =>  {
              item.ss.forEach(element => {
                element.disabled = element.ji != 0 && this.item.id != element.ji;
                element.checked = element.ji != 0;
                element.n = element.n + (element.jc ? "-" + element.jc : "")
                if(element.checked) {
                  this.selectedKeys.push(element.id)
                }
              });
              return {...item}
            })
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("读取统计分类列表失败", error);
      }
    },
    async submitHandle() {
      const keys = this.$refs.treeRef.getCheckedKeys().filter(item => this.$tool.flatten(this.data, 'ss').find(i => i.id == item && ((!i.checked && !i.disabled) || i.ji == this.item.id)));
      if(!keys || keys.length <= 0) {
        return this.$message.warning("请至少选择一个二级分类");
      }
      const params = {
        id: this.item.id,//   []int64  
        cate_ids: keys,
      };

      try {
        const res = await this.$api.BMS.statiscalConfig.reqSaveRptJkCateCates(params)
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
      this.selectedKeys = []
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
      return "配置" 
    },

  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.getTableData(1)
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