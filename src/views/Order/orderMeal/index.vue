<template>
  <!-- 点单 -->
  <div>
    <div class="contain">
      <router-view></router-view>
    </div>

    <footBar ref="footBarRef" v-if="!isOrderMeal" />
    <newFootBar ref="footBarRef" v-else />
  </div>
</template>

<script>
import footBar from '@/components/order/footBar';
import newFootBar from '@/components/order/newFootBar'
export default {
  data() {
    return {
      isOrderMeal: false
    }
  },
  methods: {

  },
  created() {

  },
  mounted() {
    this.isOrderMeal = this.$route.path.startsWith("/orderMeal");
  },
  props: ['String'],
  components: {
    footBar,
    newFootBar
  },
  filters: {

  }
}

</script>

<style scoped lang="less">
@import '../../../style/common/scrollBar.less';
</style>

<style scoped lang="less">
.contain {
  width: 100%;
  height: calc(100vh - 60px);
  overflow-x: hidden;
  overflow-y: auto;
}
</style>