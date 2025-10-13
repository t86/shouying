<template>
  <div class="front-container">
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
<style lang="less" scoped>
.front-container {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  width: 100%;
  height: 100%;
  margin: 0;
  padding: 0;
  overflow: hidden;
}
</style>