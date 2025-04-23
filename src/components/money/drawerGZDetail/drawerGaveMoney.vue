<template>
  <div>
    <!-- 挂账还款 -->
    <el-drawer
      title="挂账还款"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="70%"
    >
      <div class="account-gave-money">
        <div class="form">
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span>当前账户:</span>
            </div>
            <div class="value" layout="row" layout-align="start center">{{currentInfo.n}}</div>
          </div>
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span>剩余挂账金额:</span>
            </div>
            <div class="value" layout="row" layout-align="start center">{{currentInfo.a}}</div>
          </div>
          
          <!-- <div class="row">
            <div class="label"></div>
            <div class="value">
              <p class="red-tip">请勾选要还款的订单，系统会自动将渠道还款金额拆分到订单上</p>
            </div>
          </div> -->
          
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span>请勾选要还款的订单:</span>
            </div>
            <div class="value">
              <p class="red-tip">请勾选要还款的订单，系统会自动将渠道还款金额拆分到订单上</p>
            </div>
          </div>
          
          <div class="table-wrapper" layout="row">
            <div class="label-placeholder"></div>
            <div class="table">
              <div class="thead">
                <div class="tr" layout="row" layout-align="start center">
                  <div class="th" style="flex: 0.5; min-width: 40px;">
                    <el-checkbox
                      :indeterminate="indeterminate"
                      v-model="checkAll"
                      @change="handleCheckAllChange"
                    >全选</el-checkbox>
                  </div>
                  <div class="th" style="flex: 1; min-width: 80px;">挂账金额</div>
                  <div class="th" style="flex: 1; min-width: 100px;">还款金额</div>
                  <div class="th" style="flex: 1; min-width: 100px;">挂账时间</div>
                  <div class="th" style="flex: 1; min-width: 80px;">卡台名称</div>
                  <div class="th" style="flex: 1; min-width: 80px;">订位人</div>
                </div>
              </div>
              <div class="tbody">
                <div
                  class="tr"
                  layout="row"
                  layout-align="start center"
                  v-for="(item, index) in orderList"
                  :key="index"
                >
                  <div class="td" style="flex: 0.5; min-width: 40px;">
                    <el-checkbox
                      v-model="item.checked"
                      @change="handleItemChange"
                    ></el-checkbox>
                  </div>
                  <div class="td" style="flex: 1; min-width: 80px;">{{formatAmount(item.a)}}</div>
                  <div class="td" style="flex: 1; min-width: 100px;">
                    <div v-if="item.checked">
                      <div class="channel-amount-item" v-for="channelId in getActiveChannelIds(item)" :key="channelId">
                        {{getChannelName(channelId)}}：{{formatAmount(item.returnAmounts[channelId])}}
                      </div>
                      <div v-if="!hasChannelAmounts(item)" class="no-amount">未分配</div>
                    </div>
                    <div v-else>-</div>
                  </div>
                  <div class="td" style="flex: 1; min-width: 100px;">{{item.c}}</div>
                  <div class="td" style="flex: 1; min-width: 80px;">{{item.s}}</div>
                  <div class="td" style="flex: 1; min-width: 80px;">{{item.sn}}</div>
                </div>
                <p v-if="orderList.length == 0" class="m-t-10 fs14" style="text-align:center">暂无数据</p>
              </div>
            </div>
          </div>
          
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span class="red">*</span>
              <span>还款方式:</span>
            </div>
            <div class="value" layout="row" layout-align="start center">
              <div class="item">
                <div
                  class="item-info"
                  :class="{active: returnChannels[item.id]}"
                  v-for="item in returnList"
                  :key="item.id"
                  @click="toggleChannel(item.id)"
                >{{item.name}}</div>
              </div>
            </div>
          </div>
          
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span>总还款金额:</span>
            </div>
            <div class="value" layout="row" layout-align="start center">
              <input type="text" v-model="amtCount" disabled placeholder="各渠道还款金额总和" />
            </div>
          </div>
          
          <!-- 渠道金额输入区域 -->
          <div v-for="item in activeReturnChannels" :key="'input-'+item.id" class="row" layout="row" layout-align="start center">
            <div class="label">
              <span>{{item.name}}:</span>
            </div>
            <div class="value" layout="row" layout-align="start center">
              <input 
                type="number" 
                v-model="channelAmounts[item.id]" 
                placeholder="0.00" 
                @input="calculateTotalChannelAmount"
                style="width: 200px; height: 40px; font-size: 14px; text-align: center;" 
              />
              <!-- 只在第一个渠道输入框后显示"自动填入余额"按钮 -->
              <div 
                class="btn" 
                :class="{'disabled': !hasCheckedOrders || isAllOrdersFullyPaid}" 
                @click="handleAutoFillRemainingForChannel(item.id)"
              >自动填入余额</div>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_money from "@/api/money";
export default {
  data() {
    return {
      show: false,
      returnChannels: {}, // 选中的渠道 { id: true/false }
      channelAmounts: {}, // 各渠道的金额 { id: amount }
      amtCount: '0.00',
      returnList: [
        {
          id: 1,
          name: '现金还款'
        },
        {
          id: 2,
          name: '微信还款'
        },
        {
          id: 3,
          name: '支付宝还款'
        },
        {
          id: 4,
          name: '刷卡还款'
        },
        {
          id: 5,
          name: '工资抵扣'
        },
        {
          id: 6,
          name: '会员卡扣款'
        }
      ],
      orderList: [],
      checkAll: false,
      indeterminate: false
    };
  },
  computed: {
    // 活跃的渠道列表（已选中的）
    activeReturnChannels() {
      return this.returnList.filter(item => this.returnChannels[item.id]);
    },
    
    // 是否有选中的订单
    hasCheckedOrders() {
      return this.orderList.some(item => item.checked);
    },
    
    // 选中订单的总金额
    totalOrderAmount() {
      return this.orderList
        .filter(item => item.checked)
        .reduce((sum, item) => sum + item.a, 0);
    },
    
    // 选中订单的总金额（元）
    totalOrderAmountInYuan() {
      return this.totalOrderAmount / 100;
    },
    
    // 总渠道金额
    totalChannelAmount() {
      return parseFloat(this.amtCount || 0);
    },
    
    // 是否所有选中的订单都已完全还款
    isAllOrdersFullyPaid() {
      return this.totalOrderAmountInYuan <= this.totalChannelAmount;
    },
    
    // 获取选中的渠道ID
    selectedChannelIds() {
      return Object.keys(this.returnChannels).filter(id => this.returnChannels[id]);
    }
  },
  methods: {
    // 获取挂账订单列表
    async getOrderList() {
      try {
        const params = {
          id: this.currentInfo.id * 1
        };
        const res = await api_money.reqGetGZOrders(params);
        if (res.code == 1) {
          this.orderList = (res.data.records || []).map(item => ({
            ...item,
            checked: false,
            returnAmount: '0.00', // 添加还款金额字段，默认为0
            returnAmounts: {} // 每个渠道的还款金额
          }));
          this.checkAll = false;
          this.indeterminate = false;
          this.amtCount = '0.00';
          
          // 重置选中渠道和金额
          this.returnChannels = {};
          this.channelAmounts = {};
          this.returnList.forEach(item => {
            this.channelAmounts[item.id] = '0.00';
          });
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取挂账订单列表失败", error);
      }
    },
    
    // 格式化金额显示
    formatAmount(amount) {
      return (amount / 100).toFixed(2);
    },
    
    // 切换渠道选择状态
    toggleChannel(id) {
      this.$set(this.returnChannels, id, !this.returnChannels[id]);
      if (!this.returnChannels[id]) {
        // 如果取消选中，重置金额
        this.channelAmounts[id] = '0.00';
      }
      this.calculateTotalChannelAmount();
    },
    
    // 计算所有渠道的总金额
    calculateTotalChannelAmount() {
      const total = Object.keys(this.channelAmounts)
        .filter(id => this.returnChannels[id])
        .reduce((sum, id) => {
          const amount = parseFloat(this.channelAmounts[id] || 0);
          return sum + amount;
        }, 0);
      
      this.amtCount = total.toFixed(2);
      
      // 如果有选中的订单，自动分配金额
      if (this.hasCheckedOrders) {
        this.distributeAmountToOrders();
      }
    },
    
    // 自动填入剩余金额
    handleAutoFillRemaining() {
      if (!this.hasCheckedOrders || this.isAllOrdersFullyPaid) return;
      
      // 计算已填入的渠道金额总和
      const existingTotal = Object.keys(this.channelAmounts)
        .filter(id => this.returnChannels[id])
        .reduce((sum, id) => sum + parseFloat(this.channelAmounts[id] || 0), 0);
      
      // 计算剩余需要填入的金额
      const remainingAmount = this.totalOrderAmountInYuan - existingTotal;
      
      if (remainingAmount <= 0) return;
      
      // 找到第一个选中的渠道
      const firstSelectedChannel = this.selectedChannelIds[0];
      if (firstSelectedChannel) {
        // 将剩余金额填入该渠道
        const currentAmount = parseFloat(this.channelAmounts[firstSelectedChannel] || 0);
        this.channelAmounts[firstSelectedChannel] = (currentAmount + remainingAmount).toFixed(2);
        this.calculateTotalChannelAmount();
      }
    },
    
    // 为特定渠道自动填入余额
    handleAutoFillRemainingForChannel(channelId) {
      if (!this.hasCheckedOrders || this.isAllOrdersFullyPaid) return;
      
      // 计算已填入的渠道金额总和
      const existingTotal = Object.keys(this.channelAmounts)
        .filter(id => this.returnChannels[id])
        .reduce((sum, id) => sum + parseFloat(this.channelAmounts[id] || 0), 0);
      
      // 计算剩余需要填入的金额
      const remainingAmount = this.totalOrderAmountInYuan - existingTotal;
      
      if (remainingAmount <= 0) return;
      
      // 将剩余金额填入指定渠道
      const currentAmount = parseFloat(this.channelAmounts[channelId] || 0);
      this.channelAmounts[channelId] = (currentAmount + remainingAmount).toFixed(2);
      this.calculateTotalChannelAmount();
    },
    
    // 分配金额到订单
    distributeAmountToOrders() {
      // 首先重置所有订单的还款金额
      this.orderList.forEach(order => {
        if (order.checked) {
          order.returnAmount = '0.00';
          order.returnAmounts = {};
        }
      });
      
      // 获取选中的渠道和对应金额
      const channels = Object.keys(this.returnChannels)
        .filter(id => this.returnChannels[id])
        .map(id => ({
          id,
          amount: parseFloat(this.channelAmounts[id] || 0) * 100 // 转为分
        }))
        .filter(channel => channel.amount > 0);
      
      // 按顺序分配每个渠道的金额到订单
      channels.forEach(channel => {
        let remainingAmount = channel.amount;
        
        // 按顺序遍历选中的订单
        for (const order of this.orderList.filter(o => o.checked)) {
          if (remainingAmount <= 0) break;
          
          // 计算该订单还可以分配的金额
          const orderMaxAmount = order.a - Object.values(order.returnAmounts).reduce((sum, amt) => sum + amt, 0);
          
          if (orderMaxAmount <= 0) continue;
          
          // 决定分配多少给这个订单
          const amountToAssign = Math.min(remainingAmount, orderMaxAmount);
          
          // 更新订单的渠道还款金额
          if (!order.returnAmounts[channel.id]) {
            this.$set(order.returnAmounts, channel.id, 0);
          }
          order.returnAmounts[channel.id] += amountToAssign;
          
          // 更新订单的总还款金额
          order.returnAmount = (Object.values(order.returnAmounts).reduce((sum, amt) => sum + amt, 0) / 100).toFixed(2);
          
          // 减少剩余可分配金额
          remainingAmount -= amountToAssign;
        }
      });
    },
    
    // 全选
    handleCheckAllChange(val) {
      this.orderList.forEach(item => {
        item.checked = val;
      });
      this.indeterminate = false;
      
      if (this.hasCheckedOrders) {
        this.distributeAmountToOrders();
      }
    },
    
    // 单选
    handleItemChange() {
      const checkedCount = this.orderList.filter(item => item.checked).length;
      this.checkAll = checkedCount === this.orderList.length;
      this.indeterminate = checkedCount > 0 && checkedCount < this.orderList.length;
      
      if (this.hasCheckedOrders) {
        this.distributeAmountToOrders();
      }
    },
    
    // 添加验证还款金额方法
    validateReturnAmount(item) {
      // 转为数字类型进行比较
      const returnAmount = parseFloat(item.returnAmount || 0);
      const maxAmount = item.a / 100;
      
      // 不能超过挂账金额
      if (returnAmount > maxAmount) {
        item.returnAmount = maxAmount.toFixed(2);
        this.$message.warning('还款金额不能超过挂账金额');
      }
      
      // 不能小于0
      if (returnAmount < 0) {
        item.returnAmount = '0.00';
      }
      
      // 更新总金额
      this.calculateTotalAmount();
    },
    
    // 提交
    async onSubmit() {
      // 验证是否选择了渠道
      if (this.selectedChannelIds.length === 0) {
        return this.$message.warning('请选择至少一种还款方式');
      }
      
      // 验证是否有渠道金额
      if (parseFloat(this.amtCount) <= 0) {
        return this.$message.warning('请输入还款金额');
      }
      
      // 验证是否勾选了订单
      if (!this.hasCheckedOrders) {
        return this.$message.warning('请勾选要还款的订单');
      }
      
      // 验证还款金额不能超过挂账总额
      if (parseFloat(this.amtCount) * 100 > this.totalOrderAmount) {
        return this.$message.warning('还款金额不能超过选中订单的挂账金额总和');
      }
      
      try {
        // 收集所有订单的渠道还款数据
        const ids = [];
        const amts = [];
        const cnl_names = [];
        
        // 获取选中的订单
        const checkedOrders = this.orderList.filter(item => item.checked);
        
        // 遍历每个订单
        checkedOrders.forEach(order => {
          // 遍历该订单的每个渠道还款
          Object.keys(order.returnAmounts || {}).forEach(channelId => {
            const amount = order.returnAmounts[channelId];
            // 只处理有金额的渠道
            if (amount > 0) {
              // 添加订单ID
              ids.push(order.id * 1);
              // 添加渠道还款金额（单位：分）
              amts.push(Math.round(amount));
              // 添加渠道名称
              const channel = this.returnList.find(item => item.id == channelId);
              cnl_names.push(channel.name);
            }
          });
        });
        
        // 如果没有有效的还款数据，给出提示
        if (ids.length === 0) {
          return this.$message.warning('没有有效的还款数据');
        }
        
        const params = {
          ids: ids,               // 挂账订单Id列表
          amts: amts,             // 对应上面挂账订单Id列表的还款金额, 单位分
          cnl_names: cnl_names    // 还款渠道名称列表
        };
        
        console.log('提交参数:', params);
        
        const res = await api_money.reqReturnMoney(params);
        if (res.code == 1) {
          this.$message.success("还款成功");
          this.$emit("getTableData");
          this.onCancelDrawer();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("还款失败", error);
        this.$message.error("还款失败：" + (error.message || '未知错误'));
      }
    },
    
    onCancelDrawer() {
      this.$emit("showOrHideGaveMoneyDrawer");
    },
    
    // 获取渠道名称
    getChannelName(channelId) {
      const channel = this.returnList.find(item => item.id == channelId);
      return channel ? channel.name : '';
    },
    
    // 获取订单中有金额的渠道ID
    getActiveChannelIds(order) {
      return Object.keys(order.returnAmounts || {}).filter(channelId => order.returnAmounts[channelId] > 0);
    },
    
    // 检查订单是否有渠道金额
    hasChannelAmounts(order) {
      return Object.values(order.returnAmounts || {}).some(amount => amount > 0);
    }
  },
  mounted() {},
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    },
    currentInfo: {
      default: () => ({})
    }
  },
  watch: {
    showDrawer: {
      handler(newVal) {
        this.show = newVal;
        if (newVal) {
          this.returnChannels = {};
          this.channelAmounts = {};
          this.amtCount = '0.00';
          this.getOrderList();
        } else {
          this.$emit('getTableData');
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/common/elementFormBtn.less";
@import "../../../style/common/scrollBar.less";
</style>
<style lang="less" scoped>
.account-gave-money {
  padding: 20px;
  color: rgba(255, 255, 255, .8);
  font-size: 14px;

  .red {
    color: #ff2f64;
  }

  .form {
    .row {
      padding: 10px 20px;
      .label {
        width: 150px;
        text-align: right;
      }
      .value {
        padding-left: 10px;
        width: 400px;
        input {
          padding: 0 10px;
          box-sizing: border-box;
          width: 300px;
          height: 40px;
          border-radius: 8px;
          box-sizing: border-box;
          border: 1px solid rgba(255, 255, 255, 0.15);
          background-color: rgba(255, 255, 255, 0.05);
          color: rgba(255, 255, 255, 0.8);
        }

        .return-amount-input {
          width: 100px !important;
          text-align: center;
          height: 40px !important;
          line-height: 40px;
          border-radius: 4px;
          padding: 0 8px;
          box-sizing: border-box;
          color: rgba(255, 255, 255, 0.8);
          font-size: 14px;
          margin: 5px 0;
        }

        .red-tip {
          color: #ff2f64;
          font-size: 12px;
          line-height: 1.5;
          margin-top: 0;
        }

        .btn {
          margin-left: 10px;
          background-color: #4b89ff;
          border-radius: 4px;
          width: 100px;
          height: 40px;
          line-height: 40px;
          text-align: center;
          cursor: pointer;

          &.disabled {
            background-color: #aaa;
            color: #eee;
            cursor: no-drop;
          }
        }
        .item {
          display: grid;
          width: 100%;
          grid-template-columns: repeat(auto-fill, 100px);
          grid-auto-rows: 40px;
          grid-gap: 10px;
          .item-info {
            border: 1px solid rgba(255, 255, 255, 0.15);
            border-radius: 8px;
            line-height: 40px;
            text-align: center;
            cursor: pointer;
            &.active {
              border-color: #4b89ff;
              color: #4b89ff;
            }
          }
        }
      }
    }
  }
  
  .table-wrapper {
    padding: 10px 20px;
    
    .label-placeholder {
      width: 10px;
    }
    
    .table {
      margin-left: 10px;
      border: 1px solid rgba(255, 255, 255, 0.15);
      border-radius: 4px;
      width: calc(100% - 160px);
      
      .thead {
        background-color: rgba(255, 255, 255, 0.05);
        .tr {
          border-bottom: 1px solid rgba(255, 255, 255, 0.15);
          .th {
            padding: 10px;
            text-align: center;
            flex: 1;
            &:first-child {
              flex: 0.5;
            }
          }
        }
      }
      
      .tbody {
        max-height: 300px;
        overflow-y: auto;
        .tr {
          border-bottom: 1px solid rgba(255, 255, 255, 0.1);
          &:last-child {
            border-bottom: none;
          }
          .td {
            padding: 10px;
            text-align: center;
            flex: 1;
            &:first-child {
              flex: 0.5;
            }
          }
        }
      }
    }
  }

  .channel-amount-item {
    font-size: 12px;
    line-height: 1.4;
    text-align: left;
    padding: 2px 0;
  }
  
  .no-amount {
    color: #999;
    font-size: 12px;
  }
}
</style>