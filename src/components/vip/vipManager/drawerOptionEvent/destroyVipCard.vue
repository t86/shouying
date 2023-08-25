<template>
  <!-- 注销会员卡 -->
  <div class="destroy-card">
    <div class="content" layout="column" layout-align="center center">
      <img :src="require('../../../../assets/vip-imgs/warning.png')" alt />
      <p class="m-t-4">注销会员卡后，卡上金额会被清零，该操作不能撤销，</p>
      <p>是否确认注销该会员卡？</p>
      <h3 class="m-t-10">【卡号：{{vipInfo.card_no}}】</h3>
    </div>
  </div>
</template>
 
<script>
import api_vip from "@/api/vip";
export default {
  data() {
    return {
      vipInfo: {}
    };
  },
  methods: {
    async getVipInfo() {
      const params = {
        id: this.currentItemInfo.id * 1 //   int64   会员卡Id
      };
      try {
        const res = await api_vip.reqVipCardGetVNodeCard(params);
        if (res.code == 1) {
          this.vipInfo = res.data || {};
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取会员信息失败", error);
      }
    }
  },
  props: {
    currentItemInfo: {
      default: {}
    }
  },
  watch: {
    vipInfo: {
      handler(newVal) {
        this.$emit("updateInfoHandle", newVal);
      },
      immediate: true,
      deep: true
    }
  }
};
</script>

<style scoped lang="less">
.destroy-card{
  .content{
    margin-top: 10vh;
    img {
      width: 60px;
    }
    p {
      font-size: 18px;
      line-height: 26px;
    }

    h3{
      font-size: 24px;
    }
  }
}
</style>