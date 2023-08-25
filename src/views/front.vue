<template>
  <div>
    <router-view />
  </div>
</template>
<script>
import { cardInfoMixins } from "@/mixin/cardInfo";
import swipingCard from "@/mixin/swipingCard";
import authStatus from "@/mixin/authStatus";
export default {
  created () {
    this.getAuthStatus()
  },
  mixins: [cardInfoMixins, swipingCard, authStatus]
};
</script>
<style lang="less">
</style>