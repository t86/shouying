import api_order from "@/api/order";
import cardAmountLoaderMixin from "@/components/common/cardAmountLoaderMixin";
import fcPriceMixin from "./fcPriceMixin";

function needsDetails(card) {
  // 关联功能台展示 get_sp_seat_list 的合并金额，不用单个流水的明细覆盖。
  if (Number(card.bizType) === 3) return false;
  const status = Number(card.bizStatus);
  return [5, 6].includes(status) || ([3, 4].includes(status) && Number(card.orderAmt) > 0);
}

export default {
  mixins: [cardAmountLoaderMixin, fcPriceMixin],
  methods: {
    canReadCardAmount(card) {
      return Boolean(card && card.canLookOrder && Number(this.typeModule) === 1 && !this.safeModeEnabled);
    },
    cardAmountTargets() {
      return (this.card.cardList || []).filter((card) => this.canReadCardAmount(card) && needsDetails(card));
    },
    cardAmountKey(card) {
      return JSON.stringify([
        cardAmountLoaderMixin.methods.cardAmountKey.call(this, card),
        this.$store.state.userInfo.emp_id, card.canLookOrder, card.bizType, this.typeModule,
      ]);
    },
    async fetchCardAmountDetails(card) {
      // 点单账号使用自己的订单查询权限，不调用收银端接口。
      const res = await api_order.reqGetOrderList({
        seat_id: Number(card.seatId || card.id),
        turnover_cnt: Number(card.turnoverCnt || 0),
      });
      if (res.code !== 1 || !res.data) return null;
      const payInfo = res.data.pay_info || {};
      let orderCents = null;
      if (payInfo.order_amt !== undefined && payInfo.order_amt !== null && payInfo.order_amt !== "") {
        const value = Number(payInfo.order_amt);
        if (Number.isFinite(value)) orderCents = Math.round(value);
      }
      let rows = [];
      if (Array.isArray(res.data.records)) rows = res.data.records;
      return { rows, orderCents };
    },
    getCardOrderAmount(card) {
      if (!this.canReadCardAmount(card)) return "--";
      if (!needsDetails(card)) return Number(card.orderAmt || 0).toFixed(2);
      const detail = this.cardAmountDetails[this.cardAmountKey(card)];
      if (!detail) return "--";
      let orderCents = detail.orderCents;
      if (orderCents === null) orderCents = Math.round(Number(card.orderAmt || 0) * 100);
      detail.rows.forEach((row) => {
        // pc 已扣除退单数量，bs/si 不再重复计费；已结记录保持原结算价格。
        if (!row || row.back || Number(row.s) === 5 || row.at == 2 || row.at == 3) return;
        const count = Number(row.pc);
        if (!Number.isFinite(count) || count <= 0) return;
        const schemePrice = this.fcOrderPrice(row);
        if (schemePrice === null) return;
        let recordedAmount = Number(row.p2 || row.pp || 0) * count;
        if (row.pa !== undefined && row.pa !== null && row.pa !== "") recordedAmount = Number(row.pa);
        if (!Number.isFinite(recordedAmount)) return;
        orderCents += Math.round(schemePrice * count * 100) - Math.round(recordedAmount * 100);
      });
      // 只调整未结商品的方案价差，保留接口的全台范围和已结账优惠。
      return (orderCents / 100).toFixed(2);
    },
  },
  watch: {
    typeModule() { this.refreshCardAmounts(); },
  },
};
