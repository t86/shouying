<template>
  <el-dialog
    class="booking-detail-dialog"
    :title="dialogTitle"
    :visible="value"
    :close-on-click-modal="false"
    @close="closeDialog"
  >
    <div class="booking-detail-content">
      <div class="turnover-tabs">
        <button
          v-for="tab in turnoverTabs"
          :key="tab.turnoverCnt"
          type="button"
          class="turnover-tab"
          :class="{ active: selectedTurnoverCnt === tab.turnoverCnt }"
          @click="selectTurnover(tab.turnoverCnt)"
        >
          {{ tab.label }}
        </button>
      </div>
      <div class="detail-scroll" v-loading="loading">
        <readonly-consumption-table
          v-if="mode === 'consumption'"
          :rows="consumptionRows"
        />
        <readonly-wine-table v-else :rows="wineRows" />
      </div>
    </div>
    <span slot="footer" class="dialog-footer">
      <el-button @click="requestClose">关闭</el-button>
    </span>
  </el-dialog>
</template>

<script>
import apiOrder from '@/api/order';
import commonBook from '@/utils/common/book';
import commonOrder from '@/utils/common/order';
import bookingDetailAccess from '@/utils/bookingDetailAccess';
import orderDetailAdapter from '@/utils/orderDetailAdapter';
import readonlyConsumptionTable from '@/components/order/myOrder/readonlyConsumptionTable';
import readonlyWineTable from '@/components/order/myOrder/readonlyWineTable';

const { buildTurnoverTabs, getBookingDetailTurnoverCount } = bookingDetailAccess;
const {
  createDetailRequestState,
  getDetailCacheKey,
  normalizeOrderDetailResponse,
} = orderDetailAdapter;

const EMPTY_PAY_INFO = Object.freeze({
  allAmt: '0.00',
  giveAmt: '0.00',
  notPayAmt: '0.00',
});

export default {
  components: {
    readonlyConsumptionTable,
    readonlyWineTable,
  },
  props: {
    value: { type: Boolean, default: false },
    mode: {
      type: String,
      default: 'consumption',
      validator: value => ['consumption', 'wine'].includes(value),
    },
    cardInfo: { type: Object, default: () => ({}) },
  },
  data() {
    return {
      loading: false,
      closeRequested: false,
      turnoverTabs: [],
      selectedTurnoverCnt: 0,
      consumptionRows: [],
      wineRows: [],
      payInfo: { ...EMPTY_PAY_INFO },
      detailRequestState: createDetailRequestState(),
    };
  },
  computed: {
    dialogTitle() {
      return this.mode === 'wine' ? '查看存取酒明细' : '查看消费明细';
    },
    lookups() {
      return {
        getProductInfo: commonOrder.getProductInfo.bind(commonOrder),
        getProductInfoFromGroup: commonOrder.getProductInfoFromGroup.bind(commonOrder),
        getOrderPersonInfo: commonBook.getOrderPersonInfo.bind(commonBook),
      };
    },
  },
  watch: {
    value(visible) {
      if (visible) this.openDialog();
    },
  },
  methods: {
    openDialog() {
      this.detailRequestState.clear();
      this.loading = false;
      this.closeRequested = false;
      this.resetDetailData();
      const cardInfo = this.cardInfo || {};
      const turnoverCount = getBookingDetailTurnoverCount(cardInfo.bizStatus, cardInfo.turnoverCnt);
      this.turnoverTabs = buildTurnoverTabs(cardInfo.name || '', turnoverCount);
      this.selectedTurnoverCnt = this.turnoverTabs[0].turnoverCnt;
      return this.loadSelectedTurnover();
    },
    closeDialog() {
      this.detailRequestState.clear();
      this.loading = false;
      this.turnoverTabs = [];
      this.selectedTurnoverCnt = 0;
      this.resetDetailData();
      if (!this.closeRequested) this.$emit('input', false);
      this.closeRequested = false;
    },
    requestClose() {
      if (this.closeRequested) return;
      this.closeRequested = true;
      this.$emit('input', false);
    },
    selectTurnover(turnoverCnt) {
      this.selectedTurnoverCnt = turnoverCnt;
      return this.loadSelectedTurnover();
    },
    resetDetailData() {
      this.consumptionRows = [];
      this.wineRows = [];
      this.payInfo = { ...EMPTY_PAY_INFO };
    },
    applyDetailData(detailData) {
      this.consumptionRows = detailData.consumptionRows;
      this.wineRows = detailData.wineRows;
      this.payInfo = detailData.payInfo;
    },
    async loadSelectedTurnover() {
      const requestVersion = this.detailRequestState.startRequest();
      const cardInfo = this.cardInfo || {};
      const cacheKey = getDetailCacheKey(cardInfo.id, this.selectedTurnoverCnt);
      const cached = this.detailRequestState.get(cacheKey);

      if (cached) {
        this.applyDetailData(cached);
        this.loading = false;
        return;
      }

      this.loading = true;
      try {
        const res = await apiOrder.reqGetOrderList({
          seat_id: Number(cardInfo.id),
          turnover_cnt: Number(this.selectedTurnoverCnt),
        });
        if (!this.detailRequestState.isCurrent(requestVersion)) return;
        if (res.code !== 1) {
          this.resetDetailData();
          this.$message.warning(res.msg || '明细获取失败');
          return;
        }

        const detailData = normalizeOrderDetailResponse(res.data, this.lookups);
        this.detailRequestState.set(cacheKey, detailData);
        this.applyDetailData(detailData);
      } catch (error) {
        if (!this.detailRequestState.isCurrent(requestVersion)) return;
        this.resetDetailData();
        this.$message.warning('明细获取失败');
        console.error('预订系统读取卡台明细失败', error);
      } finally {
        if (this.detailRequestState.isCurrent(requestVersion)) this.loading = false;
      }
    },
  },
};
</script>

<style lang="less" src="../../../style/book/machine/bookingDetailDialog.less"></style>
