import api_order from "@/api/order";
import payOrderPriceMixin from "./payOrderPriceMixin";

// 支付渠道选择页只预览本次勾选商品；实际付款金额仍由支付接口返回。
export default {
  mixins: [payOrderPriceMixin],
  data() {
    return {
      selectedOrderIdList: [],
      payOrderItems: [],
      payOrderSeatId: null,
      payAmountRequestId: 0,
    };
  },
  computed: {
    payAmount() {
      if (this.payOrderSeatId !== this.currentSeatId) return 0;
      const selectedIds = new Set(this.selectedOrderIdList.map(String));
      const cents = this.payOrderItems.reduce((total, item) => {
        if (!item || item.back || item.oid || Number(item.pc) === 0 || !selectedIds.has(String(item.id))) return total;
        return total + Math.round(Number(this.getSubtotal(item)) * 100);
      }, 0);
      return cents / 100;
    },
  },
  methods: {
    async loadPayAmount() {
      const requestId = ++this.payAmountRequestId;
      const seatId = this.currentSeatId;
      this.payOrderItems = [];
      this.payOrderSeatId = null;
      if (!this.selectedOrderIdList.length || !(seatId > 0)) return;
      const isCurrentRequest = () => requestId === this.payAmountRequestId && seatId === this.currentSeatId;

      try {
        const res = await api_order.reqGetPayOrderList({ seat_id: Number(seatId) });
        if (!isCurrentRequest()) return;
        if (res.code === 1) {
          if (res.data && Array.isArray(res.data.os)) {
            this.payOrderItems = res.data.os;
          }
          this.payOrderSeatId = seatId;
        } else {
          this.$message.warning(res.msg || "加载待支付金额失败");
        }
      } catch (error) {
        if (!isCurrentRequest()) return;
        console.error("加载待支付金额失败:", error);
        this.$message.warning("加载待支付金额失败，请重试");
      }
    },
  },
  watch: {
    currentSeatId() {
      this.payAmountRequestId++;
      this.payOrderItems = [];
      this.payOrderSeatId = null;
      this.selectedOrderIdList = [];
    },
  },
  beforeDestroy() {
    this.payAmountRequestId++;
  },
};
