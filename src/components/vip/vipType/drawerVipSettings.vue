<template>
    <div>
      <el-drawer
        :title="title"
        :visible.sync="show"
        :before-close="onCancelDrawer"
        direction="rtl"
        size="90%"
        append-to-body
      >
        <div class="tab-container vip vip-bill-rules pl-2" >
          <el-tabs v-model="activeTab" >
            
            <el-tab-pane label="卡等级配置" name="cardLevel">
              <!-- 卡等级配置内容 -->
              <vipLevelConfig 
              :activeTab="activeTab"
              :editInfo="item"/>
            </el-tab-pane>
            <el-tab-pane label="充值配置" name="recharge">
              <!-- 充值配置内容 -->
              <vipRecharge :activeTab="activeTab" :item="item"/>
            </el-tab-pane>
            <el-tab-pane label="结账规则配置" name="billRules">
                <!-- 结账规则配置内容 -->
                <vipBillRules :activeTab="activeTab" :item="item"/>
            </el-tab-pane>
            <el-tab-pane label="积分配置" name="points">
              <!-- 积分配置内容 -->
                <vipPointConfig :activeTab="activeTab" :item="item"/>
            </el-tab-pane>
          </el-tabs>
        </div>
      </el-drawer>
    </div>
  </template>
  <script>
  import vipBillRules from "@/components/vip/vipType/vipBillRules.vue";
  import vipLevelConfig from "@/components/vip/vipType/vipLevel.vue";
  import vipRecharge from "@/components/vip/vipType/rechargeConfig.vue";
  import vipPointConfig from "@/components/vip/vipType/pointConfig.vue";
  export default {
    props: {
      item: {},
      showDrawer: {
        default: false, // 是否显示drawer
      },
    },
    watch: {
      showDrawer: {
        handler(newVal) {
          this.show = newVal;
        },
        immediate: true,
      },
    },
    computed: {
      title() {
        return "配置";
      },
    },
    data() {
      return {
        activeTab: "cardLevel",
        show: {
          default: false,
        },
      };
    },
    methods: {
      onCancelDrawer() {
        this.show = !this.show;
        this.$emit("showOrHideDrawerHandle");
      },
    },
    mounted() {},
    components: {
        vipBillRules,
        vipLevelConfig,
        vipRecharge,
        vipPointConfig,
    },
  };
  </script>
  
  <style lang="less" scoped>
  @import "../../../style/common/elementDrawerVip.less";
  @import "../../../style/vip/vipBtn.less";
  @import "../../../style/vip/vip.less";
  @import "../../../style/vip/vipPagination.less";
  </style>
  
  <style lang="less" scoped>
  .vip-bill-rules {
    padding-left: 20px;
    .warning {
      font-size: 28px;
      color: red;
      margin-bottom: 20px;
    }
  
    .search {
      display: grid;
      grid-template-columns: 300px 400px;
      grid-gap: 10px;
  
      .row {
        span {
          font-size: 13px;
        }
      }
    }
  }
  </style>
  