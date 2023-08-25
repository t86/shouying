<template>
  <div>
    <!-- 可点商品 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 erp-lib-detail fs14">
        <p class="red-color">说明：勾选“全部”后，如果有新增分类，该新增的分类默认选中</p>
        <p class="red-color m-l-10 p-l-2 m-t-3 m-b-3">勾选“以下全部勾选”，如果有新增分类，该新增的分类默认不选中</p>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="fs14">可点商品：</span>
          </div>
          <div class="value">
            <el-checkbox
              v-model="checkAll"
              :indeterminate="indeterminate"
              @change="checkAllHandle($event)"
            >全部</el-checkbox>
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start start">
          <div class="label">
            <span class="fs14">选择可点商品：</span>
          </div>
          <div class="value" layout="row" layout-align="start center">
            <classifyTree
              :treeData="waiterCates"
              :resetStatus="resetStatus"
              @onChange="waiterCatesChange"
            />
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      checkAll: false,
      indeterminate: false,
      resetStatus: false,
      waiterCates: [],  // 树形结构
    };
  },
  methods: {
    async getDetail() {
      const params = {
        station_ids: this.checkedList.map(item => item.id * 1)
      };
      try {
        const res = await this.$api.BMS.station.requestStationWaiterCates(params);
        if (res.code == 1) {
          this.waiterCates = (res.data.cates || []).map(item => ({
            ...item,
            subs: (item.subs || []).map(items =>({
              ...items,
              ost: items.st,
              c: items.st == 1
            }))
          }))
          setTimeout(() => {
            this.indeterminate = res.data.all_sel_type == 3
            this.checkAll = res.data.all_sel_type == 1;
          })
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("数据请求失败", error);
      }
    },

    // 点击可点商品全部checkbox
    checkAllHandle(val){
      setTimeout(() => {
        this.checkAll = val;
        this.indeterminate = false;
      });
      if (val) {
        this.resetStatus = !this.resetStatus;
        this.waiterCates.map(item => {
          item.st = 2;
          item.c = false;
          if (item.subs) {
            item.subs.map(v => {
              v.st = 2;
              v.c = false;
            });
          }
        });
      }
    },

    //监测可点商品数据变化
    waiterCatesChange(data) {
      this.waiterCates = data;
      this.indeterminate = false;
      this.checkAll = false;
    },

    async onSubmit() {
      let selCates = []
      let unChangeCates = []
      let selected = []
      let allPrdMode = 2
      this.waiterCates.forEach(el => {
        (el.subs || []).forEach(ele => {
          if (ele.ost == ele.st && ele.st != 2) {
            unChangeCates.push(ele.id);
          }
          if (ele.ost != ele.st && ele.st == 1) {
            selCates.push(ele.id);
          }
          if (ele.st != 2) {
            selected.push(ele.id);
          }
        });
      });
      
      if(this.checkAll) {
        allPrdMode = 1
      } else if (!this.indeterminate && !this.checkAll) {
        allPrdMode = 2
      } else {
        allPrdMode = 3
      }

      if (allPrdMode == 2 && selected.length < 1) {
        return this.$message.warning("请选择商品分类");
      }

      const params = {
        station_ids: this.checkedList.map(item => item.id * 1),
        all_prd_mode: allPrdMode,
        sel_cates: selCates,
        unchange_cates: unChangeCates
      }
      try {
        const res = await this.$api.BMS.station.requestStationSaveWaitCates(params)
        if(res.code == 1) {
          this.$message.success('操作成功')
          this.onCancelDrawer()
          this.$emit('getTableData')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
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
    checkedList: {
      default: () => []
    }
  },
  computed: {
    title() {
      return "可点商品";
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

  components:{
    classifyTree: () => import('./ClassifyTree.vue')
  },

  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.getDetail();
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
@import "../../../../../style/erp/table.less";
</style>

<style lang="less" scoped>
.coll {
  .label {
    width: 120px;
  }
}
</style>