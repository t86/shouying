<template>
  <div>
    <div class="warning">
      说明：未在表单中配置规则的商品, 不能使用当前会员卡结账！
    </div>
  
  </div>
</template>


<script>
export default {
  components: {

  },
  props: {
    item: {},
  },
  watch: {
  },
  computed: {
    title() {
      return "积分规则";
    },
  },
  data() {
    return {
    };
  },
  methods: {
  },
  mounted() {},
};
</script>

<style lang="less" scoped>
</style>

<style lang="less" scoped>
</style>
