<template>
  <div>
    <!-- 挂账还款 -->
    <el-drawer
      title="挂账还款"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="600px"
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
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span class="red">*</span>
              <span>还款方式:</span>
            </div>
            <div class="value" layout="row" layout-align="start center">
              <div class="item">
                <div
                  class="item-info"
                  :class="{active: activeId == item.id}"
                  v-for="item in returnList"
                  :key="item.id"
                  @click="activeId=item.id"
                >{{item.name}}</div>
              </div>
            </div>
          </div>
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span class="red">*</span>
              <span>还款金额:</span>
            </div>
            <div class="value" layout="row" layout-align="start center">
              <input type="text" v-model="amtCount" placeholder="还款金额=勾选的挂账订单中还款金额总和" disabled />
            </div>
          </div>
          
          <div class="row">
            <div class="label"></div>
            <div class="value">
              <p class="red-tip">请勾选要还款的订单，勾选后自动填入还款金额，如需部分还款，可修改订单的还款金额</p>
            </div>
          </div>
          
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span>请勾选要还款的订单:</span>
            </div>
          </div>
          
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="start center">
                <div class="th" style="flex: 0.5; min-width: 60px;">
                  <el-checkbox
                    :indeterminate="indeterminate"
                    v-model="checkAll"
                    @change="handleCheckAllChange"
                  >全选</el-checkbox>
                </div>
                <div class="th" style="flex: 1; min-width: 120px;">挂账时间</div>
                <div class="th" style="flex: 1; min-width: 100px;">卡台名称</div>
                <div class="th" style="flex: 1; min-width: 100px;">订位人</div>
                <div class="th" style="flex: 1; min-width: 100px;">挂账金额</div>
                <div class="th" style="flex: 1; min-width: 120px;">还款金额</div>
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
                <div class="td" style="flex: 0.5; min-width: 60px;">
                  <el-checkbox
                    v-model="item.checked"
                    @change="handleItemChange"
                  ></el-checkbox>
                </div>
                <div class="td" style="flex: 1; min-width: 120px;">{{item.c}}</div>
                <div class="td" style="flex: 1; min-width: 100px;">{{item.s}}</div>
                <div class="td" style="flex: 1; min-width: 100px;">{{item.sn}}</div>
                <div class="td" style="flex: 1; min-width: 100px;">{{formatAmount(item.a)}}</div>
                <div class="td" style="flex: 1; min-width: 120px;">
                  <input 
                    type="number" 
                    v-model="item.returnAmount" 
                    :disabled="!item.checked"
                    @input="validateReturnAmount(item)"
                    style="width: 100px; height: 40px; font-size: 14px; text-align: center; margin: 5px 0;"
                    class="return-amount-input"
                  />
                </div>
              </div>
              <p v-if="orderList.length == 0" class="m-t-10 fs14" style="text-align:center">暂无数据</p>
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
      activeId: "",
      amtCount: '',
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
            returnAmount: (item.a / 100).toFixed(2) // 添加还款金额字段，默认等于挂账金额
          }));
          this.checkAll = false;
          this.indeterminate = false;
          this.amtCount = '';
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
    
    // 全选
    handleCheckAllChange(val) {
      this.orderList.forEach(item => {
        item.checked = val;
        // 更新默认还款金额
        if (val) {
          item.returnAmount = (item.a / 100).toFixed(2);
        }
      });
      this.indeterminate = false;
      this.calculateTotalAmount();
    },
    
    // 单选
    handleItemChange() {
      const checkedCount = this.orderList.filter(item => item.checked).length;
      this.checkAll = checkedCount === this.orderList.length;
      this.indeterminate = checkedCount > 0 && checkedCount < this.orderList.length;
      
      // 设置被选中项的默认还款金额
      this.orderList.forEach(item => {
        if (item.checked && !item.returnAmount) {
          item.returnAmount = (item.a / 100).toFixed(2);
        }
      });
      
      this.calculateTotalAmount();
    },
    
    // 计算总金额
    calculateTotalAmount() {
      const totalAmount = this.orderList
        .filter(item => item.checked)
        .reduce((sum, item) => sum + parseFloat(item.returnAmount || 0) * 100, 0);
      this.amtCount = (totalAmount / 100).toFixed(2);
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
      if(this.activeId == '') return this.$message.warning('请选择还款方式');
      if(this.amtCount * 1 == 0) return this.$message.warning('请勾选要还款的订单');
      
      // 获取选中的订单ID和金额
      const checkedOrders = this.orderList.filter(item => item.checked);
      const ids = checkedOrders.map(item => item.id * 1);
      const amts = checkedOrders.map(item => Math.round(parseFloat(item.returnAmount || 0) * 100)); // 转换为分
      
      // 查找对应的还款方式名称
      let cnl_name = '';
      const foundItem = this.returnList.find(item => item.id == this.activeId);
      if (foundItem) {
        cnl_name = foundItem.name;
      }
      
      const params = {
        ids: ids,                                      // 挂账订单Id列表
        amts: amts,                                    // 对应上面挂账订单Id列表的还款金额, 单位分
        cnl_name: cnl_name                             // 还款渠道名称
      };
      
      try {
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
      }
    },
    
    onCancelDrawer() {
      this.$emit("showOrHideGaveMoneyDrawer");
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
          this.activeId = '';
          this.amtCount = '';
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
          height: 30px;
          border-radius: 8px;
          box-sizing: border-box;
          border: 1px solid rgba(255, 255, 255, 0.15);
          background-color: rgba(255, 255, 255, 0.05);
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
          width: 90px;
          height: 30px;
          line-height: 30px;
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
  
  .table {
    margin: 0 20px;
    border: 1px solid rgba(255, 255, 255, 0.15);
    border-radius: 4px;
    
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
</style>