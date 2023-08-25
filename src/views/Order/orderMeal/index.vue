<template>
  <!-- 点单 -->
  <div>
    <div class="contain">
      <router-view></router-view>
    </div>
    <footBar ref="footBarRef" />
  </div>
</template>

<script>
  import footBar from '@/components/order/footBar'
  export default {
    data() {
      return {
        
      }
    },
    methods: {

    },
    created() {

    },
    mounted() {
    },
    props: ['String'],
    components: {
      footBar
    },
    filters: {

    }
  }

</script>

<style scoped lang="less">
  @import '../../../style/common/scrollBar.less';
</style>

<style scoped lang="less">
  .contain{
    width: 100%;
    height: calc(100vh - 60px);
    overflow-x: hidden;
    overflow-y: auto;
  }
</style>