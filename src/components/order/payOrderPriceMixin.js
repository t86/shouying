import fcPriceMixin from "./fcPriceMixin";

// 买单列表保留接口返回的订单价格；方案元数据仅用于未下单商品。
export default {
  mixins: [fcPriceMixin],
  methods: {
    getDisplayPrice(item) {
      if (!item) return "0.00";
      if (Number(item.pp) === 0) return "时价";
      return Number(item.p2 !== undefined && item.p2 !== null && item.p2 !== "" ? item.p2 : item.pp || 0).toFixed(2);
    },
    getSubtotal(item) {
      if (!item || item.at == 2 || item.at == 3) return "0.00";
      // 沿用接口记录的实收金额，包含后端授权改价结果。
      if (Number(item.pc) === 0) return "0.00";
      if (item.pa !== undefined && item.pa !== null && item.pa !== "") {
        return Number(item.pa || 0).toFixed(2);
      }
      if (Number(item.pp) === 0) return "0.00";
      return (Number(this.getDisplayPrice(item)) * Number(item.pc || 0)).toFixed(2);
    },
  },
};
