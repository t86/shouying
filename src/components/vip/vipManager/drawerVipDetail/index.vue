<template>
  <div>
    <!-- 会员详情 -->
    <el-drawer
      title="会员详情"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="80%"
    >
      <div class="content m-t-4">
        <component is="vipInfo" :info="stepOneInfo" ref="_detailRef" @phoneChanged="phoneChanged" />
      </div>
      <div class="session p-5">
        <ul class="tab" layout="row" layout-align="start center">
<!--          <li @click="step=1" :class="{'active': step==1}">基本信息</li>-->
          <li @click="step=2" :class="{'active': step==2}">会员卡详情</li>
          <li @click="step=3" :class="{'active': step==3}">交易明细</li>
          <li @click="step=4" :class="{'active': step==4}">优惠券</li>
          <li @click="step=5" :class="{'active': step==5}">剩余存酒</li>
          <li @click="step=6" :class="{'active': step==6}">消费喜好</li>
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
import vipRemainWine from "./vipRemainWine.vue";
import vipFav from "./vipFav.vue";
export default {
  data() {
    return {
      show: false,
      step: 2,
      stepOneInfo: {},
      stepTwoInfo: [],
      stepThreeInfo: {},
      stepCoupon: {},
      stepRemainWain: {},
      stepFav: {},
      originPhone: true
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
          if(res.data.bind_phone){
            this.stepOneInfo = { ...res.data };
            if(!this.preVipInfo.bp){
              this.preVipInfo.bp = res.data.bind_phone
            }
          }else if(res.data.contact_phone){
            if(!this.preVipInfo.bp){
              this.preVipInfo.bp = res.data.contact_phone
            }
          } else {
            this.$message.warning("会员卡未登记客人手机");
            return
          }
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("vip详情获取失败", error);
      }
    },
    async getVipCardList(init = false) {
      this.stepTwoInfo = []
      const params = !this.originPhone ? {
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
    },
    phoneChanged(value){
      console.log("phoneChanged from sub:", value)
      this.preVipInfo.bp = value
      this.originPhone = false
      this.getVipDetail();
      this.getVipCardList()
      this.step = 2
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
    vipCoupons,
    vipRemainWine,
    vipFav,
  },
  computed: {
    stepName() {
      const componentNameInfo = {
        "1": "vipInfo",
        "2": "vipCardInfo",
        "3": "vipPayInfo",
        "4": "vipCoupons",
        "5": "vipRemainWine",
        "6": "vipFav",
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
        case 5:
          return this.stepRemainWain;
        case 6:
            return this.stepFav;
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
      console.log("step:", newVal)
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
            this.$refs.detailRef && this.$refs.detailRef.getTableData && this.$refs.detailRef.getTableData(true, this.originPhone)
          } )
          break;
        case 4:
          this.stepCoupon = JSON.parse(JSON.stringify(this.preVipInfo))
          this.$nextTick(() => {
            this.$refs.detailRef && this.$refs.detailRef.getTableData && this.$refs.detailRef.getTableData(true)
          } )
        case 5:
          this.stepRemainWain = JSON.parse(JSON.stringify(this.preVipInfo))
          this.$nextTick(() => {
            this.$refs.detailRef && this.$refs.detailRef.getTableData && this.$refs.detailRef.getTableData(true)
          } )
          break;
        case 6:
          this.stepFav = JSON.parse(JSON.stringify(this.preVipInfo))
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