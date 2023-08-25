<template>
  <div class="upload-pro-img">
    <ul class="tab" layout="row" layout-align="start center">
      <li
        :class="{'active':active == index}"
        v-for="(item,index) in tabList"
        :key="index"
        @click="active=index"
      >{{item}}</li>
    </ul>
    <div class="content">
      <uploadImg v-if="active==0" />
      <proList v-else />
    </div>
  </div>
</template>
 
<script>
import uploadImg from "./uploadProImgCom/uploadImg.vue";
import proList from "./uploadProImgCom/proList.vue";
export default {
  data() {
    return {
      tabList: ["批量上传图片", "图片检测"],
      active: 0
    };
  },
  components: {
    uploadImg,
    proList
  }
};
</script>

<style scoped lang="less">
.upload-pro-img {
  padding: 20px 30px;
  color: #d9d9d9;
  .tab {
    padding-bottom: 20px;
    li {
      margin-right: 30px;
      padding: 0 10px 10px;
      border-bottom: 3px solid transparent;
      cursor: pointer;
      color: #1a1a21;
      &.active {
        border-bottom-color: #2170ff;
      }
    }
  }
}
</style>