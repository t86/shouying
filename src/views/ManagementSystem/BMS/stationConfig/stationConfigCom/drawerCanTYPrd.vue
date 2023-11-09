<template>
  <div>
    <!-- 鸡尾酒关联商品 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 erp-lib-detail fs14">
        <div class="coll" layout="row" layout-align="start start">
          <div class="label">
            <span class="fs14">选择关联商品：</span>
          </div>
          <div class="value" layout="row" layout-align="start center">
            <classifyTreeThree
              :treeData="selCates"
              :resetStatus="resetStatus"
              @onChange="treeChange"
            />
          </div>
        </div>
        <p class="red-color fs14 m-t-3 m-l-3">说明：只允许关联花篮、小费类的商品</p>
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
      resetStatus: false,
      selCates: [],  // 树形结构
    };
  },
  methods: {
    async getDetail() {
      const params = {
        ids: this.checkedList.map(item => item.id * 1)
      };
      try {
        const res = await this.$api.BMS.station.reqGetGiveHlCate(params);
        if (res.code == 1) {
          this.selCates = (res.data.cates || []).map(item => ({
            ...item,
            subs: (item.subs || []).map(items =>({
              ...items,
              ost: items.st,
              c: items.st == 1
            }))
          }))
        } else {
          this.$message.warning(res.msg);
          this.onCancelDrawer()
        }
      } catch (error) {
        console.log("数据请求失败", error);
      }
    },

    // 点击可点商品全部checkbox
    checkAllHandle(val){
      if (val) {
        this.resetStatus = !this.resetStatus;
        this.selCates.map(item => {
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

    //监测鸡尾酒商品数据变化
    treeChange(data) {
      this.selCates = data;
    },

    async onSubmit() {
      const sel_prds = [];
      const unchange_prds = [];
      this.selCates.forEach(el => {
        el.subs && el.subs.forEach(ele => {
          ele.prds && ele.prds.forEach(element => {
              if (element.st == 1) sel_prds.push(element.id * 1);
              if (element.st == 3) unchange_prds.push(element.id * 1);
            });
          });
      });
      const params = {
        station_ids: this.checkedList.map(item => item.id * 1),
        sel_prds,
        unchange_prds
      }
      try {
        const res = await this.$api.BMS.station.reqSetGiveHlCate(params)
        if(res.code == 1) {
          this.$message.success('操作成功')
          this.onCancelDrawer()
          this.$emit('getTableData')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据提交失败', error);
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
      return "鸡尾酒关联商品";
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
    classifyTreeThree: () => import('./ClassifyTreeThree.vue')
  },

  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.getDetail();
        } else {
          this.selCates = []
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