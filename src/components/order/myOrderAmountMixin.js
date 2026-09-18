// 折前金额减实收及未付得到总折扣，避免重复叠加已结方案价差。
export default {
  data() {
    return {
      amountOrderList: [],
      orderPayInfo: {},
    };
  },
  computed: {
    amt() {
      let originalCents = 0;
      let unpaidCents = 0;
      let unpaidDiscountCents = 0;
      this.amountOrderList.forEach((item) => {
        if (!item || item.back || Number(item.pc) <= 0) return;
        const amount = Number(this.getSubtotal(item));
        if (!Number.isFinite(amount)) return;
        const cents = Math.round(amount * 100);
        if (item.at != 2 && item.at != 3) {
          const original = Number(item.pp) > 0 ? Math.round(Number(item.pp) * Number(item.pc) * 100) : cents;
          originalCents += original;
          if (Number(item.s) !== 5) unpaidDiscountCents += Math.max(0, original - cents);
        }
        if (Number(item.s) !== 5) unpaidCents += cents;
      });
      const info = this.orderPayInfo;
      const hasAmount = value => value !== undefined && value !== null && value !== '' && Number.isFinite(Number(value));
      const hasOrderAmount = hasAmount(info.order_amt);
      const discountCents = hasOrderAmount && hasAmount(info.payed_val_amt)
        ? Math.max(0, Number(info.order_amt) - Number(info.payed_val_amt) - unpaidCents)
        : (hasAmount(info.payed_free_amt) ? Number(info.payed_free_amt) : 0) + unpaidDiscountCents;
      return {
        allAmt: ((hasOrderAmount ? Number(info.order_amt) : originalCents) / 100).toFixed(2),
        giveAmt: (Number(info.yh_amt || 0) / 100).toFixed(2),
        discountAmt: (discountCents / 100).toFixed(2),
        notPayAmt: (unpaidCents / 100).toFixed(2),
      };
    },
  },
};
