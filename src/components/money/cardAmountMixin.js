import api_money from "@/api/money";
import cardAmountLoaderMixin from "@/components/common/cardAmountLoaderMixin";
import { buildPriceContextFromStore, calcItemAmount, calcUnpaidOrderAmount } from "@/utils/orderItemPrice";

const needsDetails = (card) => card && [5, 6].includes(Number(card.bizStatus));
const amountCents = (value) => Math.round((Number(value) || 0) * 100);

function unpaidRows(data) {
  const unpaid = data.unpay_order || {};
  let rows = [];
  if (Array.isArray(unpaid.os)) rows = rows.concat(unpaid.os);
  if (Array.isArray(unpaid.oos)) {
    unpaid.oos.forEach((group) => {
      if (group && !group.back && Array.isArray(group.os)) rows = rows.concat(group.os);
    });
  }
  // pc 已是剩余数量；bs 是退单记录，si 是套餐明细，均不再重复累加。
  return rows.filter((row) => row && !row.back && Number(row.pc) > 0);
}

export default {
  mixins: [cardAmountLoaderMixin],
  methods: {
    async fetchCardAmountDetails(card) {
      const res = await api_money.reqGetCardPayInfo({
        seat_id: Number(card.seatId || card.id),
        turnover_cnt: Number(card.turnoverCnt || 0),
      });
      if (res.code === 1 && res.data) return unpaidRows(res.data);
      return null;
    },
    getCardAmounts(card) {
      if (!needsDetails(card)) {
        return { order: Number(card.orderAmt || 0).toFixed(2), unpaid: "0.00" };
      }
      const rows = this.cardAmountDetails[this.cardAmountKey(card)];
      // 尚未读到明细时不把摘要中的旧价格当作正确未付金额显示。
      if (!rows) return { order: "--", unpaid: "--" };
      const context = { ...buildPriceContextFromStore(this.$store), cardInfo: card };
      const products = this.$store.state.cardPageInfo.resResultDataObj.goodsAroundInfo || [];
      const pricedRows = rows.map((row) => ({
        ...row,
        productInfo: products.find((product) => product.id == row.pid) || row.productInfo,
      }));
      const unpaidCents = amountCents(calcUnpaidOrderAmount(pricedRows, context));
      let recordedCents = 0;
      pricedRows.forEach((row) => {
        if (row.at == 2 || row.at == 3) return;
        if (row.pa !== undefined && row.pa !== null && row.pa !== "") {
          recordedCents += amountCents(row.pa);
        } else {
          recordedCents += amountCents(calcItemAmount({ ...row, changeCount: row.pc }, { ...context, fcProductPrices: [] }));
        }
      });
      // 仅修正未结商品的价差，保留已结商品、实收及结账优惠的历史金额。
      return {
        order: ((amountCents(card.orderAmt) + unpaidCents - recordedCents) / 100).toFixed(2),
        unpaid: (unpaidCents / 100).toFixed(2),
      };
    },
    getCardUnpaidAmount(card) {
      return this.getCardAmounts(card).unpaid;
    },
    getCardOrderAmount(card) {
      return this.getCardAmounts(card).order;
    },
  },
};
