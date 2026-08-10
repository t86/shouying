<template>
  <div class="readonly-detail-table wine-table">
    <div class="detail-head detail-row">
      <div>类型</div>
      <div>名称</div>
      <div>规格</div>
      <div>数量</div>
      <div>存/取酒操作人</div>
      <div>存/取酒操作时间</div>
    </div>
    <div v-if="rows.length === 0" class="detail-empty">暂无数据</div>
    <div v-for="(item, index) in rows" :key="`${item.t}-${index}`" class="detail-row">
      <div>
        <span class="badge" :class="item.t == 1 ? 'save' : 'take'">
          {{ item.t == 1 ? '存' : '取' }}
        </span>
      </div>
      <div>{{ item.p }}</div>
      <div>{{ item.u }}</div>
      <div>{{ item.c }}</div>
      <div>{{ item.n }}</div>
      <div>{{ item.o }}</div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    rows: { type: Array, default: () => [] },
  },
};
</script>
