import { getFcPrice } from '@/utils/fcPrice';

export default {
  methods: {
    fcOrderPrice(item) {
      if (!item) return null;
      return getFcPrice(item.pid, item.ae, item.wei, this.$store.state.cardPageInfo.resResultDataObj);
    },
    fcProductPrice(product) {
      if (!product) return null;
      return getFcPrice(product.id, 0, this.$store.state.userInfo.emp_id, this.$store.state.cardPageInfo.resResultDataObj);
    },
    fcApplyPrice(params, product) {
      const price = this.fcProductPrice(product);
      if (price === null) return params;
      params.prd_price = price.toFixed(2);
      return params;
    },
    // add_hl 使用总金额；定价商品留空，由后端按方案计算。
    fcApplyAmount(params, product) {
      const result = { ...params };
      delete result.prd_price;
      if ([3, 4, 8].includes(Number(product.prdType))) {
        const price = this.fcProductPrice(product);
        if (price !== null) result.prd_amt = (price * Number(params.prd_cnt)).toFixed(2);
      } else {
        result.prd_amt = '';
      }
      return result;
    },
    fcOrderOriginal(item, actual) {
      return Boolean(item) && Number.isFinite(Number(actual)) && Number(item.pp) > 0 && Number(item.pp) !== Number(actual);
    },
    fcOriginalSubtotal(item) {
      return Number(item.pp) > 0 ? Number(item.pp) * Number(item.pc || 0) : Number(item.pa || 0);
    },
    fcSubtotalOriginal(item, actual) {
      return Boolean(item) && Number.isFinite(Number(actual)) && this.fcOriginalSubtotal(item) > 0 && this.fcOriginalSubtotal(item) !== Number(actual);
    },
    fcProductOriginalPrice(product) { return Number(product.vipPrice || product.price || 0); },
    fcOriginalText(item) { return Number(item.pp).toFixed(2); },
  },
};
