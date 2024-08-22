<template>
  <div id="app">
    <router-view />
    <Loading />
  </div>
</template>
<script>
import Loading from '@/components/Loading.vue';
export default {
  components: {
    Loading,
  },
};
</script>
<style lang="less">
/* .el-popup-parent--hidden{
  padding-right: 0px !important;
} */
#app {
  font-family: "黑体";
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  color: #2c3e50;
  width: 100%;
  height: 100%;
  overflow: hidden;
  user-select: none;
  outline: none;
  -webkit-tap-highlight-color: transparent;
}

html {
  min-height: max-content;
  /* min-height: -webkit-max-content; */
  width: 100%;
  /* height:100%; */
}

body {
  margin: 0;
  padding: 0;
  width: 100%;
  height: 100%;

  /* 解决elementui出现弹框纵向滚动条被隐藏页面向右闪动的问题 */
  &.el-popup-parent--hidden {
    overflow-x: hidden !important;
    overflow-y: visible !important;
  }
}

a {
  text-decoration: none;
}

.one-txt-cut {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.el-checkbox .el-checkbox__inner {
  border: 1px solid #8c8c8c;
}

.el-scrollbar__view.el-select-dropdown__list {
  background-color: #f5f5f5 !important;
}

.el-select-dropdown__item.hover,
.el-select-dropdown__item:hover {
  background-color: #e5e5e5 !important;
}

.el-switch {
  display: inline-flex;
  align-items: center;
  font-size: 14px;
  line-height: 20px;
  height: 20px;
  margin-left: -20px;
}
.el-switch__label--left {
  position: relative;
  left: 45px;
  color: #fff;
  z-index: -1111;
}
.el-switch__core{
  width: 50px!important;
}
.el-switch__label--right {
  position: relative;
  right: 46px;
  color: #fff;
  z-index: -1111;
}
.el-switch__label--right.is-active {
  z-index: 1111;
  color: #fff!important;
}
.el-switch__label--left.is-active {
  z-index: 1111;
  color: #9c9c9c!important;
}

</style>