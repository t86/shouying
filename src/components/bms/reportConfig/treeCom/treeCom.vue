<template>
  <div>
    <div class="m-l-3 m-t-2" v-for="item in arrayList" :key="item.key">
      <el-checkbox v-model="item.checked" :disabled="item.disabled" @change="changeCheckboxHandle($event, item)">{{item.n}}</el-checkbox>
      <treeCom :list="item.subs" />
    </div>
  </div>
</template>
 
<script>
import eventVue from '@/utils/eventVue';
export default {
  data() {
    return {};
  },
  methods: {
    changeCheckboxHandle(event, itemInfo){
      eventVue.$emit('changeTreeItem', {event, itemInfo})
    }
  },
  created() {},
  mounted() {},
  computed: {
    arrayList() {
      return this.list.filter(item => item.s == 1);
    }
  },
  props: {
    list: {
      default: []
    }
  },
  components: {},
  filters: {}
};
</script>

<style scoped lang='less'>
</style>