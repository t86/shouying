<template>
  <div>
    <!-- 此文件为当用户输入的网址为项目根目录时，重新定位之前登录过得系统参数，并重定向 -->
  </div>
</template>
 
<script>
export default {
  mounted() {
    const client = this.$store.state.client;
    client
      ? this.$router.replace({ name: "Thelogin", query: { client } })
      : this.$router.replace({ name: "notFound" });
  }
};
</script>

<style scoped>
</style>