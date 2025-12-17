<template>
  <div class="pay-record">
    <el-drawer
      title="支付记录"
      :visible.sync="visible"
      direction="rtl"
      size="92%"
      :before-close="handleClose"
      append-to-body
      custom-class="pay-record-drawer-panel"
    >
      <div class="pay-record-body order-detail">
        <div class="pay-record-toolbar" layout="row" layout-align="start center">
          <el-input
            v-model.trim="query.key"
            placeholder="卡台名称"
            clearable
            maxlength="20"
          />
          <el-button type="primary" @click="handleSearch" :loading="loading">
            查询
          </el-button>
          <el-button @click="handleReset" :disabled="loading">
            重置
          </el-button>
        </div>

        <el-alert
          v-if="!isBusinessOpen"
          type="warning"
          class="pay-record-alert"
          :closable="false"
          title="营业日已结束，当前仅支持查看记录，无法变更订单绑定会员。"
        />

        <div class="pay-record-table" ref="tableContainer">
          <el-table
            class="dark-table"
            :data="payList"
            :height="tableHeight"
            stripe
            v-loading="loading"
            empty-text="暂无支付记录"
          >
            <el-table-column
              label="序号"
              type="index"
              width="70"
              :index="indexMethod"
            />
            <el-table-column prop="n" label="卡台" min-width="120" />
            <el-table-column
              prop="p"
              label="付款时间"
              min-width="150"
              :formatter="formatPayTime"
            />
            <el-table-column
              prop="pa"
              label="付款金额"
              min-width="120"
              align="right"
              :formatter="formatAmount"
            />
            <el-table-column prop="pi" label="支付方式" min-width="160" />
            <el-table-column
              label="订单绑定会员"
              min-width="180"
              :formatter="formatCustInfo"
            />
            <el-table-column label="操作" min-width="220" fixed="right">
              <template slot-scope="{ row }">
                <span
                  class="operation-btn"
                  :class="{ disabled: isCancelBindingDisabled(row) }"
                  @click="handleCancelBinding(row)"
                >
                  取消绑定
                </span>
                <span
                  class="operation-btn"
                  :class="{ disabled: isActionDisabled(row) }"
                  @click="openChangeDialog(row)"
                >
                  修改订单绑定会员
                </span>
              </template>
            </el-table-column>
          </el-table>
        </div>

      </div>

      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="handleClose">关闭</el-button>
      </div>
    </el-drawer>

    <el-dialog
      title="修改订单绑定会员"
      :visible.sync="editDialog.visible"
      append-to-body
      width="420px"
      :close-on-click-modal="false"
      custom-class="pay-record-edit-dialog"
      center
    >
      <div class="edit-form">
        <div class="edit-input">
          <el-input
            v-model.trim="editDialog.phone"
            placeholder="输入会员手机号"
            maxlength="11"
            @keyup.enter.native="searchMember"
          />
          <el-button
            type="primary"
            @click="searchMember"
            :loading="editDialog.searching"
          >
            搜索
          </el-button>
        </div>
        <p class="edit-error" v-if="editDialog.error">{{ editDialog.error }}</p>
        <div class="member-info" v-if="editDialog.member">
          <div class="info-row">
            <span>姓名：</span>{{ editDialog.member.name }}
          </div>
          <div class="info-row">
            <span>手机号：</span>{{ editDialog.member.phone }}
          </div>
          <div class="info-row">
            <span>总余额：</span>{{ formatCurrency(editDialog.member && editDialog.member.bal) }}
          </div>
          <div class="info-row">
            <span>积分：</span>{{ editDialog.member.pt }}
          </div>
        </div>
      </div>
      <span slot="footer" class="dialog-footer">
        <el-button @click="closeEditDialog">取消</el-button>
        <el-button
          type="primary"
          :disabled="!editDialog.phone || editDialog.phone.length !== 11"
          :loading="editDialog.confirming"
          @click="confirmChange"
        >
          确认更改
        </el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import api_money from "@/api/money";

export default {
  name: "drawerPayRecord",
  props: {
    showDrawer: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      visible: false,
      loading: false,
      payList: [],
      query: {
        key: "",
      },
      tableHeight: 400,
      editDialog: {
        visible: false,
        phone: "",
        member: null,
        searching: false,
        confirming: false,
        error: "",
        currentPay: null,
      },
    };
  },
  computed: {
    isBusinessOpen() {
      const status = Number(
        this.$store.state.cardPageInfo.storeStatusId || 0
      );
      return status > 0;
    },
  },
  watch: {
    showDrawer(val) {
      this.visible = val;
      if (val) {
        this.handleReset();
        this.$nextTick(() => {
          this.setTableHeight();
        });
      }
    },
  },
  created() {
    window.addEventListener("resize", this.setTableHeight);
  },
  beforeDestroy() {
    window.removeEventListener("resize", this.setTableHeight);
  },
  methods: {
    setTableHeight() {
      this.$nextTick(() => {
        setTimeout(() => {
          if (!this.visible || !this.$refs.tableContainer) {
            this.tableHeight = 400;
            return;
          }
          
          const tableContainer = this.$refs.tableContainer;
          const containerHeight = tableContainer.clientHeight;
          
          // 如果容器高度有效，使用容器高度；否则使用默认值
          if (containerHeight > 0) {
            this.tableHeight = containerHeight;
          } else {
            // 降级方案：使用视口高度计算
            const viewport = window.innerHeight || document.documentElement.clientHeight || 768;
            const drawerBody = document.querySelector('.pay-record-drawer-panel .el-drawer__body');
            if (drawerBody) {
              const drawerBodyHeight = drawerBody.clientHeight;
              const toolbar = document.querySelector('.pay-record-toolbar');
              const alert = document.querySelector('.pay-record-alert');
              
              let usedHeight = 0;
              if (toolbar) usedHeight += toolbar.offsetHeight;
              if (alert && alert.offsetParent !== null) {
                usedHeight += alert.offsetHeight + 4;
              }
              usedHeight += 16 + 15 + 24 + 64; // padding + margin + form-btn
              
              this.tableHeight = Math.max(300, drawerBodyHeight - usedHeight - 10);
            } else {
              this.tableHeight = Math.max(300, Math.round(viewport * 0.6));
            }
          }
        }, 150);
      });
    },
    indexMethod(index) {
      return index + 1;
    },
    formatPayTime(row, column, cellValue) {
      return cellValue || "--";
    },
    formatAmount(row, column, cellValue) {
      const field =
        (column && column.property) ||
        (typeof column === "string" ? column : "");
      let value =
        typeof cellValue !== "undefined" ? cellValue : field ? row[field] : row;
      return this.formatCurrency(value);
    },
    formatCurrency(value) {
      if (value === undefined || value === null || value === "") return "--";
      const num = Number(value);
      if (Number.isNaN(num)) return value;
      return num.toFixed(2);
    },
    formatCustInfo(row) {
      if (!row || !row.c || row.c === "-") return "";
      return row.c;
    },
    parseTime(value) {
      if (!value) return 0;
      const date = new Date(value.replace(/-/g, "/"));
      return date.getTime() || 0;
    },
    async fetchPayList() {
      this.loading = true;
      try {
        const params = {
          key: this.query.key || "",
        };
        const res = await api_money.reqGetPayRecordList(params);
        if (res.code === 1) {
          const records = (res.data.records || []).sort(
            (a, b) => this.parseTime(b.p) - this.parseTime(a.p)
          );
          this.payList = records;
        } else {
          this.payList = [];
          this.$message.warning(res.msg || "获取支付记录失败");
        }
      } catch (error) {
        console.error("获取支付记录失败", error);
        this.payList = [];
        this.$message.error("获取支付记录失败");
      } finally {
        this.loading = false;
      }
    },
    handleSearch() {
      this.fetchPayList();
    },
    handleReset() {
      this.query.key = "";
      this.fetchPayList();
    },
    handleClose(done) {
      this.visible = false;
      this.$emit("showOrHidePayRecordDrawer");
      if (typeof done === "function") {
        done();
      }
    },
    isSelfService(row) {
      return (row.pi || "").indexOf("自助") > -1;
    },
    isActionDisabled(row) {
      return this.isSelfService(row) || !this.isBusinessOpen;
    },
    isCancelBindingDisabled(row) {
      // 如果没有绑定会员，取消绑定按钮应该置灰
      const hasBinding = row.c && row.c !== "-" && row.c.trim() !== "";
      return this.isActionDisabled(row) || !hasBinding;
    },
    handleCancelBinding(row) {
      if (this.isCancelBindingDisabled(row)) return;
      this.$confirm(
        "确认取消绑定？取消绑定后该支付记录的会员信息将置空。",
        "取消绑定",
        {
          confirmButtonText: "确定",
          cancelButtonText: "取消",
          type: "warning",
        }
      )
        .then(() => this.updatePayCustomer(row.id, ""))
        .catch(() => {});
    },
    openChangeDialog(row) {
      if (this.isActionDisabled(row)) return;
      this.editDialog.visible = true;
      this.editDialog.phone = "";
      this.editDialog.member = null;
      this.editDialog.error = "";
      this.editDialog.currentPay = row;
    },
    closeEditDialog() {
      this.editDialog.visible = false;
      this.editDialog.phone = "";
      this.editDialog.member = null;
      this.editDialog.error = "";
    },
    async searchMember() {
      if (!this.editDialog.phone) {
        this.editDialog.error = "请输入会员手机号";
        this.editDialog.member = null;
        return;
      }
      // 检查手机号是否为11位
      if (this.editDialog.phone.length !== 11) {
        this.editDialog.error = "手机号必须为11位";
        this.editDialog.member = null;
        return;
      }
      // 检查是否为纯数字
      if (!/^\d+$/.test(this.editDialog.phone)) {
        this.editDialog.error = "手机号必须为数字";
        this.editDialog.member = null;
        return;
      }
      this.editDialog.error = "";
      this.editDialog.searching = true;
      try {
        const params = {
          phone_num: this.editDialog.phone,
        };
        const res = await api_money.reqGetCustInfoByPhone(params);
        if (res.code === 1) {
          this.editDialog.member = res.data || null;
          if (!this.editDialog.member) {
            this.editDialog.error = "当前手机号未注册会员";
          }
        } else {
          this.editDialog.member = null;
          this.editDialog.error = res.msg || "当前手机号未注册会员";
        }
      } catch (error) {
        console.error("搜索会员失败", error);
        this.editDialog.error = "搜索失败，请稍后重试";
        this.editDialog.member = null;
      } finally {
        this.editDialog.searching = false;
      }
    },
    async confirmChange() {
      if (!this.editDialog.phone || !this.editDialog.currentPay) return;
      // 检查手机号是否为11位
      if (this.editDialog.phone.length !== 11) {
        this.$message.warning("手机号必须为11位");
        return;
      }
      // 检查是否为纯数字
      if (!/^\d+$/.test(this.editDialog.phone)) {
        this.$message.warning("手机号必须为数字");
        return;
      }
      this.editDialog.confirming = true;
      try {
        // 如果找到了会员，使用会员的手机号；如果没找到，使用输入的手机号（未注册会员也可以绑定）
        const phoneToUse = this.editDialog.member 
          ? this.editDialog.member.phone 
          : this.editDialog.phone;
        const isMemberFound = !!this.editDialog.member;
        await this.updatePayCustomer(
          this.editDialog.currentPay.id,
          phoneToUse,
          isMemberFound
        );
        this.editDialog.visible = false;
      } finally {
        this.editDialog.confirming = false;
      }
    },
    async updatePayCustomer(id, phone, isMemberFound = true) {
      try {
        const params = {
          id,
          phone: phone || "", // 客人手机号，如果要解绑传空字符串
        };
        const res = await api_money.reqChangePayCustomer(params);
        if (res.code === 1) {
          if (!phone || phone === "") {
            this.$message.success("解绑成功");
          } else if (isMemberFound) {
            this.$message.success("绑定会员成功");
          } else {
            this.$message.success("更改成功");
          }
          this.fetchPayList();
        } else {
          this.$message.warning(res.msg || "操作失败");
        }
      } catch (error) {
        console.error("更新支付客人信息失败", error);
        this.$message.error("操作失败，请稍后重试");
      }
    },
  },
};
</script>

<style scoped lang="less">
@import "../../style/money/drawerOrder.less";
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
@import "../../style/money/payRecord.less";
</style>

