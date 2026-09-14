<template>
  <div class="order-lookup">
    <el-drawer
      title="订单查询"
      :visible.sync="visible"
      :before-close="handleClose"
      direction="rtl"
      size="98%"
    >
      <div class="lookup-body">
        <div class="lookup-toolbar">
          <label for="lookup-order-no">订单号：</label>
          <el-input
            id="lookup-order-no"
            v-model="orderNo"
            placeholder="输入完整订单号查询"
            clearable
            :disabled="loading"
            @keyup.enter.native="queryOrder"
          />
          <el-button type="primary" :loading="loading" @click="queryOrder">查询</el-button>
          <el-button @click="reset">重置</el-button>
        </div>
        <el-table
          :data="records"
          v-loading="loading"
          :empty-text="emptyText"
          height="100%"
          stripe
        >
          <el-table-column prop="b" label="营业日" min-width="110" />
          <el-table-column prop="id" label="订单号" min-width="210" />
          <el-table-column prop="r" label="区域" min-width="90" />
          <el-table-column prop="s" label="卡台" min-width="90" />
          <el-table-column prop="o" label="开台时间" min-width="160" />
          <el-table-column prop="pa" label="支付金额" min-width="110" align="right" />
          <el-table-column prop="sn" label="订位人" min-width="100" />
          <el-table-column prop="sd" label="订位部门" min-width="120" />
          <el-table-column prop="et" label="支付完成时间" min-width="160" />
          <el-table-column prop="ps" label="支付状态" min-width="110" />
          <el-table-column prop="pds" label="商品信息" min-width="240" />
          <el-table-column prop="ws" label="服务员信息" min-width="160" />
        </el-table>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="handleClose">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_money from "@/api/money";

export default {
  name: "drawerOrderLookup",
  props: {
    showDrawer: { type: Boolean, default: false },
  },
  data() {
    return {
      visible: false,
      orderNo: "",
      records: [],
      loading: false,
      searched: false,
      error: "",
      requestId: 0,
    };
  },
  computed: {
    emptyText() {
      return this.error || (this.searched
        ? "未查询到该订单，请核对完整订单号"
        : "请输入完整订单号查询订单！");
    },
  },
  watch: {
    showDrawer(value) {
      this.visible = value;
      this.reset();
    },
  },
  beforeDestroy() {
    this.requestId++;
  },
  methods: {
    reset() {
      // 关闭或重置后，忽略尚未返回的查询结果。
      this.requestId++;
      this.orderNo = "";
      this.records = [];
      this.loading = false;
      this.searched = false;
      this.error = "";
    },
    async queryOrder() {
      if (this.loading) return;
      const orderNo = this.orderNo.trim();
      if (!orderNo) {
        this.reset();
        this.$message.warning("请输入完整订单号查询订单");
        return;
      }
      const requestId = ++this.requestId;
      this.orderNo = orderNo;
      this.loading = true;
      this.searched = true;
      this.records = [];
      this.error = "";
      try {
        const res = await api_money.reqGetOnlinePayOrderInfo({ order_no: orderNo });
        if (requestId !== this.requestId) return;
        if (res.code === 1) {
          this.records = (res.data && res.data.records) || [];
        } else {
          this.error = res.msg || "订单查询失败，请重试";
          this.$message.warning(this.error);
        }
      } catch (error) {
        if (requestId !== this.requestId) return;
        this.error = "订单查询失败，请检查网络后重试";
        this.$message.error(this.error);
      } finally {
        if (requestId === this.requestId) this.loading = false;
      }
    },
    handleClose() {
      this.visible = false;
      this.reset();
      this.$emit("close");
    },
  },
};
</script>

<style scoped lang="less">
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";

.lookup-body {
  height: 100%;
  box-sizing: border-box;
  padding: 16px 20px 64px;
  display: flex;
  flex-direction: column;
  min-height: 0;
  color: #fff;
}

.lookup-toolbar {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 16px;
  flex-shrink: 0;

  .el-input { width: 300px; max-width: 100%; }
  .el-button { margin-left: 0; }
}

.lookup-body /deep/ .el-table {
  flex: 1;
  min-height: 0;
  background: #171d2d;
  color: #fff;

  &::before { display: none; }
  th, td { border: none; }
  th { background: #222d47; color: #fff; }
  tr { background: #171d2d; }
  .el-table__row--striped td { background: #202c42; }
  .el-table__body tr:hover > td { background: #2b3955; }
  .cell { white-space: pre-line; overflow-wrap: anywhere; }
  .el-table__empty-text { color: #c5cede; }
}
</style>
