// 金额按权限过滤前的当台明细汇总，单价方案和行小计共用同一计算入口。
export default {
  data() {
    return {
      amountOrderList: [],
      orderGiftAmount: "0.00",
    };
  },
  computed: {
    amt() {
      let allCents = 0;
      let unpaidCents = 0;
      this.amountOrderList.forEach((item) => {
        if (!item || item.back || Number(item.pc) <= 0) return;
        const amount = Number(this.getSubtotal(item));
        if (!Number.isFinite(amount)) return;
        const cents = Math.round(amount * 100);
        allCents += cents;
        // 已结明细已计入点单金额，不能再计入未结金额或再次扣除已收款。
        if (Number(item.s) !== 5) unpaidCents += cents;
      });
      return {
        allAmt: (allCents / 100).toFixed(2),
        giveAmt: this.orderGiftAmount,
        notPayAmt: (unpaidCents / 100).toFixed(2),
      };
    },
  },
};
