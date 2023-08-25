<template>
  <div class="employ">
    <div class="content">
      <menuList />
    </div>
  </div>
</template>
 
<script>
import menuList from "./employeeListCom/menuList.vue";
export default {
  data() {
    return {
      tableIndex: 1,
      orgId: ''
    };
  },
  methods: {
    changeTabHandle(index) {
      this.tableIndex = index;
    },
  },
  created() {},
  mounted() {},
  props: ["String"],
  components: {
    menuList
  },
  filters: {},
  watch: {
    $route() {
      this.orgId = this.$route.query.orgId;
      this.$nextTick(() => {
        this.$children && this.$children[0] && this.$children[0].init && this.$children[0].init();
      });
    },
  }
};
</script>

<style scoped lang="less">
@import "./employeeList.less";
</style>