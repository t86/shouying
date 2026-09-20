// 当前流水金额跟随服务端业务摘要；查看历史流水时保留历史接口的金额。
export default {
  data() {
    return { footerHistoricalAmounts: false };
  },
  computed: {
    footerOriginalAmount() {
      const orderCents = Math.round((Number(this.cardInfo.orderAmt) || 0) * 100);
      // 历史流水沿用历史接口摘要，不叠加当前卡台的折扣。
      const discountCents = this.footerHistoricalAmounts ? 0 : Math.round((Number(this.cardInfo.discount_amt) || 0) * 100);
      return ((orderCents + discountCents) / 100).toFixed(2);
    },
  },
  methods: {
    refreshFooterCardAmounts() {
      if (this.footerHistoricalAmounts) return;
      const current = this.$store.state.orderInfo.currentCardInfo || {};
      const metadata = this.$store.state.cardPageInfo.resResultDataObj || {};
      const seatId = current.seatId || current.id;
      const business = (metadata.businessData || []).find((row) =>
        String(row.seatId) === String(seatId) &&
        (current.turnoverCnt === undefined || Number(row.turnoverCnt) === Number(current.turnoverCnt))
      );
      const amounts = {};
      if (business) {
        ["discount_amt", "orderAmt", "payed_val_amt", "order_zy_amt", "payedAmt", "payed_zy_val_amt"].forEach((key) => {
          if (business[key] !== undefined && business[key] !== null && business[key] !== "" && Number.isFinite(Number(business[key]))) {
            amounts[key] = business[key];
          }
        });
      }
      this.cardInfo = { ...current, ...amounts };
    },
  },
  watch: {
    "$store.state.cardPageInfo.resResultDataObj.businessData": {
      deep: true,
      handler() { this.refreshFooterCardAmounts(); },
    },
    "$store.state.orderInfo.currentCardInfo": {
      deep: true,
      handler() { this.refreshFooterCardAmounts(); },
    },
  },
};
