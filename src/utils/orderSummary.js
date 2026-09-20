// wo/list 的 pay_info 金额单位为分；未结金额为下单金额减去已付款金额。
export function calculateOrderSummary(info = {}) {
  const amount = key => Number(info[key]) || 0;
  return {
    allAmt: ((amount('discount_amt') + amount('order_amt')) / 100).toFixed(2),
    giveAmt: (amount('yh_amt') / 100).toFixed(2),
    discountAmt: ((amount('discount_amt') + amount('payed_free_amt')) / 100).toFixed(2),
    notPayAmt: ((amount('order_amt') - amount('payed_amt')) / 100).toFixed(2),
  };
}
