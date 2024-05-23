<template>
  <div>
    <!-- 会员详情 -->
    <el-drawer
      title="会员详情"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="800px"
    >
      <div class="content m-t-4">
        <component is="vipInfo" :info="stepOneInfo" ref="_detailRef" />
      </div>
      <div class="session p-5">
        <ul class="tab" layout="row" layout-align="start center">
<!--          <li @click="step=1" :class="{'active': step==1}">基本信息</li>-->
          <li @click="step=2" :class="{'active': step==2}">会员卡详情</li>
          <li @click="step=3" :class="{'active': step==3}">交易明细</li>
          <li @click="step=4" :class="{'active': step==4}">优惠券</li>
        </ul>
        <div class="content m-t-4">
          <component :is="stepName" :info="stepInfo" ref="detailRef" />
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_vip from "@/api/vip";
import vipInfo from "./vipInfo.vue";
import vipCardInfo from "./vipCardInfo.vue";
import vipPayInfo from "./vipPayInfo.vue";
import vipCoupons from "./vipCoupons.vue";
export default {
  data() {
    return {
      show: false,
      step: 2,
      stepOneInfo: {},
      stepTwoInfo: [],
      stepThreeInfo: {},
      stepCoupon: {},
    };
  },
  methods: {
    async getVipDetail() {
      this.stepOneInfo = {}
      const params = this.preVipInfo.bp ? {
        bind_phone: this.preVipInfo.bp // string   绑定手机号
      } : {
        id: this.preVipInfo.id * 1  //   int64   会员卡Id(用于查询没有绑定手机的会员卡信息,单卡) 与bind_phone互斥
      }
      try {
        const res = await api_vip.reqGetVipCardDetail(params);
        if (res.code == 1) {
          this.stepOneInfo = { ...res.data };
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("vip详情获取失败", error);
      }
    },
    async getVipCardList() {
      this.stepTwoInfo = []
      const params = this.preVipInfo.bp ? {
        bind_phone: this.preVipInfo.bp // string   绑定手机号
      } : {
        id: this.preVipInfo.id * 1  //   int64   会员卡Id(用于查询没有绑定手机的会员卡信息,单卡) 与bind_phone互斥
      }
      try {
        const res = await api_vip.reqGetVipCardListOfOnePhoneNum(params);
        if (res.code == 1) {
          this.stepTwoInfo = res.data.records || []
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("vip卡片列表获取失败", error);
      }
    },
    async getMyCoupons(){},
    changeStep(step = 2) {
      this.step = step;
    },
    onCancelDrawer() {
      this.$emit("showOrHideDrawer");
    }
  },
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    },
    preVipInfo: {
      default: {} // 当前查看详情的vip数据
    }
  },
  components: {
    vipInfo,
    vipCardInfo,
    vipPayInfo,
    vipCoupons
  },
  computed: {
    stepName() {
      const componentNameInfo = {
        "1": "vipInfo",
        "2": "vipCardInfo",
        "3": "vipPayInfo",
        "4": "vipCoupons"
      };
      return componentNameInfo[this.step];
    },
    stepInfo() {
      switch (this.step * 1) {
        // case 1:
        //   return this.stepOneInfo;
        case 2:
          return this.stepTwoInfo;
        case 3:
          return this.stepThreeInfo;
        case 4:
          return this.stepCoupon;
      }
    }
  },
  watch: {
    showDrawer: {
      handler(newVal) {
        this.show = newVal;
        if (newVal) {
          this.step = 2;
          this.getVipDetail()
          this.getVipCardList()
        }
      },
      immediate: true
    },
    step(newVal) {
      switch (newVal * 1) {
        case 1:
          this.getVipDetail();
          this.getVipCardList()
          this.step = 2
          break;
        case 2:
          this.getVipCardList()
          break;
        case 3:
          this.stepThreeInfo = JSON.parse(JSON.stringify(this.preVipInfo))
          this.$nextTick(() => {
            this.$refs.detailRef && this.$refs.detailRef.getTableData && this.$refs.detailRef.getTableData(true)
          } )
          break;
        case 4:
          this.stepCoupon = JSON.parse(JSON.stringify(this.preVipInfo))
          this.$nextTick(() => {
            this.$refs.detailRef && this.$refs.detailRef.getTableData && this.$refs.detailRef.getTableData(true)
          } )
          break;
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../style/common/elementDrawerVip.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/vip/vipBtn.less";
@import "../../../../style/common/elementFormBtnVip.less";
@import "../../../../style/common/scrollBarVip.less";
@import "../../../../style/vip/vipBtn.less";
@import "../../../../style/vip/drawerAddOrUpdateVipType.less";
</style>
<style lang="less" scoped>
ul.tab {
  height: 40px;
  background: rgba(204, 209, 220, 0);
  // background: linear-gradient(270deg, rgba(204, 209, 220, 0) 0%, #ccd1dc 100%);
  border-radius: 20px;
  font-size: 16px;
  padding-left: 10px;
  li {
    padding: 0 16px;
    cursor: pointer;
    &.active {
      color: #2362d5;
      position: relative;
      &:after {
        content: "";
        width: 40px;
        height: 3px;
        background-color: #2362d5;
        border-radius: 2px;
        position: absolute;
        bottom: -12px;
        left: 50%;
        transform: translateX(-50%);
      }
    }
  }
}
</style>