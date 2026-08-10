<template>
  <div class="readonly-detail-table consumption-table">
    <div class="detail-head detail-row">
      <div>状态</div>
      <div>名称</div>
      <div>数量</div>
      <div>单价(元)</div>
      <div>小计(元)</div>
      <div>服务员</div>
      <div>点单时间</div>
    </div>
    <div v-if="rows.length === 0" class="detail-empty">暂无数据</div>
    <div v-for="item in rows" :key="item.id" class="detail-group">
      <div class="detail-row">
        <div class="status-cell">
          <span v-if="item.s == 5" class="badge settled">结</span>
          <span v-if="item.back" class="badge returned">退</span>
          <span v-if="item.at == 2" class="badge discount">惠</span>
          <span v-if="item.at == 3" class="badge discount">惠2</span>
        </div>
        <div>{{ item.productInfo && item.productInfo.name }}</div>
        <div>{{ item.pc }}</div>
        <div>{{ displayPrice(item) }}</div>
        <div>{{ subtotal(item) }}</div>
        <div>{{ item.personInfo && item.personInfo.name }}</div>
        <div>{{ orderTime(item.ot) }}</div>
      </div>
      <div
        v-for="(detail, index) in item.si"
        :key="`${item.id}-${index}`"
        class="detail-row set-detail"
      >
        <div></div>
        <div>
          {{ detail.groupInfo && detail.groupInfo.name }}{{ detail.r ? `（${detail.r}）` : '' }}
        </div>
        <div>{{ packageCount(detail, item.pc) }}</div>
        <div></div>
        <div></div>
        <div></div>
        <div></div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    rows: { type: Array, default: () => [] },
  },
  methods: {
    displayPrice(item) {
      if (Number(item.pp) === 0) return '时价';
      return Number(item.p2 || item.pp || 0).toFixed(2);
    },
    subtotal(item) {
      if (item.at == 2 || item.at == 3) return '0.00';
      const amount = item.pa === null || item.pa === undefined
        ? (item.pp || 0) * (item.pc || 0)
        : item.pa;
      return Number(amount).toFixed(2);
    },
    packageCount(detail, productCount) {
      return detail.s && detail.c
        ? detail.s * detail.c * productCount
        : detail.sc * detail.dpc * productCount;
    },
    orderTime(value) {
      return value ? String(value).slice(7) : '';
    },
  },
};
</script>
