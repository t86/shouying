<template>
  <div class="user-config">
    <div class="tab m-b-3" layout="row" layout-align="start center">
      <div class="tab-item" :class="{active: tabIndex == 1}" @click="tabIndex = 1">用户管理</div>
      <div class="tab-item" :class="{active: tabIndex == 2}" @click="tabIndex = 2">黑名单</div>
    </div>

    <userList v-if="tabIndex == 1" />
    <blackUserList v-if="tabIndex == 2" />
  </div>
</template>
 
<script>
import userList from './userConfigCom/userList.vue'
import blackUserList from './userConfigCom/blackUserList.vue'
export default {
  data() {
    return {
      tabIndex: 1
    };
  },
  methods: {},
  created() {},
  mounted() {},
  props: ["String"],
  components: {
    userList,
    blackUserList
  },
  filters: {}
};
</script>

<style scoped lang="less">
.user-config{
  padding: 20px;
  .tab {
    .tab-item {
      padding: 10px;
      border-bottom: 2px solid transparent;
      margin-right: 10px;
      cursor: pointer;
      &.active {
        color: #2170ff;
        border-bottom: 2px solid #2170ff;
      }
    }
  }
}
</style>