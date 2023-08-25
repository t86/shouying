<template>
  <div class="bgc" layout="row" layout-align="center center">
    <div class="contain">
      <img :src="imgSrc.img404" alt />
      <p>没有找到您要访问的页面！</p>
    </div>
  </div>
</template>
 
<script>
import img404 from "@/assets/img/404.png";
export default {
  data() {
    return {
      imgSrc: {
        img404
      }
    };
  }
};
</script>

<style scoped lang="less">
.bgc {
  width: 100vw;
  height: 100vh;
  background: #202C4A;
  // background: linear-gradient(180deg, #202C4A 0%, #2A3959 100%);
  .contain {
    transform: translateY(-20%);
    text-align: center;
    p {
      font-size: 18px;
      color: #ffffff;
      line-height: 18px;
    }
  }
}
</style>