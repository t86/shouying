<template>
  <!-- 换卡 -->
  <div class="step-four">
    <div class="form-grid">
      <div class="row">
        <div class="label">会员卡号：</div>
        <div class="value">{{vipInfo.card_no}}</div>
      </div>
      <div class="row">
        <div class="label">姓名：</div>
        <div class="value">{{vipInfo.name || '---'}}</div>
      </div>
      <div class="row">
        <div class="label">绑定手机：</div>
        <div class="value">{{vipInfo.bind_phone || '---'}}</div>
      </div>
      <div class="row">
        <div class="label">联系手机：</div>
        <div class="value">{{vipInfo.contact_phone || '---'}}</div>
      </div>
      <div class="row">
        <div class="label">储蓄余额：</div>
        <div class="value">{{vipInfo.val_bal}}</div>
      </div>
      <div class="row">
        <div class="label">赠送余额：</div>
        <div class="value">{{vipInfo.free_bal}}</div>
      </div>
      <!-- <div class="row">
        <div class="label">剩余积分：</div>
        <div class="value">1000</div>
      </div> -->
    </div>
    <div class="content">
      <p>请将新的会员卡放到读卡器上！</p>
      <p>换卡后旧的会员卡不能使用！</p>
    </div>
  </div>
</template>
 
<script>
import api_vip from '@/api/vip'
export default {
  data() {
    return {
      vipInfo: {}
    };
  },
  methods: {
    async getVipInfo() {
      const params = {
        id: this.currentItemInfo.id * 1   //   int64   会员卡Id
      }
      try {
        const res = await api_vip.reqVipCardGetVNodeCard(params)
        if (res.code == 1) {
          this.vipInfo = res.data || {}
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取会员信息失败', error)
      }
    }
  },
  created() {
    this.getVipInfo()
  },
  props: {
    currentItemInfo: {
      default: {}
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../style/vip/drawerManager/stepFour.less";
</style>
<style lang="less" scoped>
.content{
  margin-top: 60px;
  text-align: center;
  font-size: 18px;
  line-height: 30px;
}
</style>