import { calculateOrderSummary } from "@/utils/orderSummary";

export default {
  data() {
    return {
      amountOrderList: [],
      orderPayInfo: {},
    };
  },
  computed: {
    amt() {
      return calculateOrderSummary(this.orderPayInfo);
    },
  },
};
