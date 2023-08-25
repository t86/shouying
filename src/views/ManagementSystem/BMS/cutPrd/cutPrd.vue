<template>
  <div class="table-count">
    <div class="content">
      <menuList  />
    </div>
  </div>
</template>
 
<script>
import menuList from "./cutPrdCom/menuList.vue";
export default {
  data() {
    return {
    };
  },
  components: {
    menuList,
  },
  filters: {},
  watch: {
    $route() {
      this.$nextTick(() => {
        this.$children && this.$children[0] && this.$children[0].init && this.$children[0].init();
      });
    },
  }
};
</script>

<style scoped lang="less">
@import "./cutPrd.less";
</style>