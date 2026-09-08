<template>
  <div class="card-transfer-history" :title="history || ''" :aria-label="history ? '转台记录：' + history : ''">
    <span v-for="(seat, index) in recentSeats" :key="index">{{ seat }}{{ index ? '-' : '' }}</span>
  </div>
</template>

<script>
export default {
  props: {
    history: { type: String, default: '' },
  },
  computed: {
    recentSeats() {
      return (this.history || '').split('-').map(seat => seat.trim()).filter(Boolean).slice(-3).reverse();
    },
  },
};
</script>

<style scoped>
.card-transfer-history {
  display: flex;
  /* 从最新记录开始排布，旧记录整体换到不可见的下一行。 */
  flex-flow: row-reverse wrap;
  justify-content: flex-end;
  align-content: flex-start;
  height: 16px;
  margin-top: 4px;
  overflow: hidden;
  line-height: 16px;
}

.card-transfer-history > span {
  flex: 0 0 auto;
  max-width: 100%;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: clip;
}
</style>
