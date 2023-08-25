<template>
  <div>
    <!-- 盘盈盘亏 -->
    <el-drawer
      title="盘盈盘亏"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="95%"
    >
      <div class="profit">
        <el-button type="primary" @click="showOrHideAddProfitPrdDrawerHandle" style="height:30px;line-height:30px;padding:0;margin-bottom:10px" >添加盘盈盘亏单</el-button>
        <div class="contain">
          <div class="scroll-area">
            <div class="table" v-for="(item, index) in tableList" :key="index">
              <div class="thead">
                <div class="title tr" layout="row" layout-align="space-between center">
                  <div class="title-item">出品库：{{item.m}}</div>
                  <div class="title-item">操作人：{{item.o}}</div>
                  <div class="title-item">操作时间：{{item.t}}</div>
                </div>
                <div class="tr" layout="row" layout-align="space-between center">
                  <div class="th">序号</div>
                  <div class="th">商品名称</div>
                  <div class="th">一级分类</div>
                  <div class="th">二级分类</div>
                  <div class="th">盘盈数量</div>
                  <div class="th">盘亏数量</div>
                </div>
              </div>
              <div class="tbody">
                <div class="tr" layout="row" layout-align="space-between center" v-for="(items,i) in item.rs" :key="i">
                  <div class="td">{{i + 1}}</div>
                  <div class="td">{{items.n}}</div>
                  <div class="td">{{items.on}}</div>
                  <div class="td">{{items.tn}}</div>
                  <div class="td">{{items.pc}}</div>
                  <div class="td">{{items.lc}}</div>
                </div>
              </div>
            </div>
          </div>

        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
      </div>
    </el-drawer>

    <!-- 添加盘盈盘亏商品 -->
    <drawerAddProfitPrd ref="drawerAddProfitPrd" :showDrawer="showOrHideAddProfitPrdDrawer" @getTableData="getTableData" @showOrHideAddProfitPrdDrawerHandle="showOrHideAddProfitPrdDrawerHandle" />
  </div>
</template>
 
<script>
import api_money from "@/api/money";
import drawerAddProfitPrd from './drawerAddProfitPrd.vue'
export default {
  data() {
    return {
      show: false,
      showOrHideAddProfitPrdDrawer: false,
      tableList: []
    };
  },
  methods: {
    async getTableData(){
      try {
        const res = await api_money.reqGetProfitData();
        if(res.code == 1) {
          this.tableList = res.data.records || []
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('盘盈盘亏数据获取失败', error);
      }
    },

    showOrHideAddProfitPrdDrawerHandle(){
      this.showOrHideAddProfitPrdDrawer = !this.showOrHideAddProfitPrdDrawer
    },
    
    onCancelDrawer() {
      this.$emit("showOrHideProfitHandle");
    },

  },
  mounted() {
    
  },
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    }
  },
  components: {
    drawerAddProfitPrd
  },
  watch: {
    showDrawer: {
      handler(newVal) {
        this.show = newVal;
        if(newVal) this.getTableData()
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/money/drawerProfit.less";
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/common/elementFormBtn.less";
@import "../../../style/common/scrollBar.less";
</style>