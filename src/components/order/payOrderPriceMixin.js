import fcPriceMixin from "./fcPriceMixin";

// 服务员买单列表与点单明细使用相同的员工方案，保留接口返回的订单价格。
export default {
  mixins: [fcPriceMixin],
  methods: {
    getDisplayPrice(item) {
      if (!item) return "0.00";
      if (!item.back) {
        const schemePrice = this.fcOrderPrice(item);
        if (schemePrice !== null) return schemePrice.toFixed(2);
      }
      if (Number(item.pp) === 0) return "时价";
      return Number(item.p2 || item.pp || 0).toFixed(2);
    },
    getSubtotal(item) {
      if (!item || item.at == 2 || item.at == 3) return "0.00";
      if (!item.back) {
        const schemePrice = this.fcOrderPrice(item);
        if (schemePrice !== null) {
          return (schemePrice * Number(item.pc || 0)).toFixed(2);
        }
      }
      // 未匹配方案时沿用下单时的实际金额，不按当前会员/包厢状态重算。
      if (item.pa !== undefined && item.pa !== null) {
        return Number(item.pa || 0).toFixed(2);
      }
      if (Number(item.pp) === 0) return "0.00";
      return (Number(this.getDisplayPrice(item)) * Number(item.pc || 0)).toFixed(2);
    },
  },
};
