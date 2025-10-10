<template>
  <div>
    <!-- 会员充值 -->
    <el-drawer
      title="会员充值"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      :size="getDrawerSize()"
      class="vip-recharge-drawer"
      :class="getDrawerClass()"
    >
      <div class="drawer-content" :class="getContentClass()">
        <!-- 主要内容区域 -->
        <div class="main-content">
          <!-- 注册开卡按钮 -->
          <div class="top-actions">
            <button class="register-btn" @click="showRegisterCard">
              注册开卡
            </button>
            <div class="search-tip">
              <span>如搜索不到手机号，可进行新客户可直接注册开卡</span>
            </div>
          </div>

          <!-- 搜索选择充值账户 -->
          <div class="search-section">
          <div class="search-label">
            <span class="required">*</span>
            <span>选择充值账户:</span>
          </div>
          <div class="search-input">
            <el-select
              v-model="searchType"
              placeholder="请选择搜索方式"
              style="width: 200px; margin-right: 10px;"
              size="small"
            >
              <el-option label="输入手机号后四位或会员卡号搜索" value="phone" />
            </el-select>
            <el-input
              v-model="searchKeyword"
              :placeholder="searchType === 'phone' ? '输入手机号后四位或会员卡号' : '请选择搜索方式'"
              style="width: 300px; margin-right: 10px;"
              size="small"
              @input="handleSearch"
            />
          </div>
          
          <!-- 搜索结果列表 -->
          <div class="search-results" v-if="searchResults.length > 0">
            <div 
              v-for="(card, index) in searchResults" 
              :key="card.id"
              class="card-item"
              :class="{ active: selectedCardIndex === index }"
              @click="selectCard(index)"
            >
              {{ card.n }}
            </div>
          </div>
        </div>

        <!-- 充值内容区域 -->
        <div class="recharge-content" v-if="selectedMember">
          <!-- 会员信息展示 -->
          <div class="member-info">
            <div class="info-row">
              <div class="info-item">
                <span class="label">会员卡号:</span>
                <span class="value">{{ selectedMember.card_no }}</span>
              </div>
              <div class="info-item">
                <span class="label">会员姓名:</span>
                <span class="value">{{ selectedMember.name }}</span>
              </div>
              <div class="info-item">
                <span class="label">绑定手机:</span>
                <span class="value">{{ selectedMember.bind_phone }}</span>
              </div>
            </div>
            <div class="info-row">
              <div class="info-item">
                <span class="label">储值余额:</span>
                <span class="value">¥{{ selectedMember.val_bal || '0.00' }}</span>
              </div>
              <div class="info-item">
                <span class="label">赠送余额:</span>
                <span class="value">¥{{ selectedMember.free_bal || '0.00' }}</span>
              </div>
              <div class="info-item">
                <span class="label">总余额:</span>
                <span class="value">¥{{ selectedMember.bal || '0.00' }}</span>
              </div>
            </div>
          </div>

          <!-- 充值档位选择 -->
          <div class="recharge-options">
            <div class="section-title">
              <span class="required">*</span>
              <span>选择充值规则:</span>
            </div>
            <div class="options-grid">
              <div 
                v-for="(option, index) in rechargeOptions" 
                :key="index"
                class="option-card"
                :class="{ active: selectedOptionIndex === index }"
                @click="selectOption(index)"
              >
                <div class="option-price">
                  ¥{{ option.display_price }}
                </div>
                <div class="option-gift" v-if="option.gift_amount > 0 || option.gift_points > 0 || option.gift_coupon">
                  <div v-if="option.gift_amount > 0" class="gift-money">
                    赠：¥{{ option.gift_amount.toFixed(2) }}
                  </div>
                  <div v-if="option.gift_points > 0" class="gift-points">
                    赠：{{ option.gift_points }}积分
                  </div>
                  <div v-if="option.gift_coupon" class="gift-coupon">
                    赠：{{ option.gift_coupon }}
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- 自定义充值金额 -->
          <div class="custom-amount" v-if="isCustomAmount">
            <div class="input-group">
              <label>自定义充值金额:</label>
              <div class="amount-input-wrapper">
                <input
                  type="number"
                  v-model="customAmount"
                  placeholder="请输入金额"
                  class="amount-input"
                  step="0.01"
                  min="0"
                />
              </div>
            </div>
          </div>

          <!-- 推荐人选择 -->
          <div class="recommender-section">
            <div class="section-title">充值推荐人:</div>
            <el-select
              v-model="selectedRecommender"
              placeholder="输入员工姓名或工号进行查询"
              filterable
              remote
              :remote-method="searchEmployee"
              style="width: 300px;"
              size="small"
              clearable
            >
              <el-option
                v-for="emp in employeeOptions"
                :key="emp.id"
                :label="`${emp.name}${emp.code ? ' (' + emp.code + ')' : ''}`"
                :value="emp.id"
              />
            </el-select>
            <div class="recommender-tip" v-if="selectedRecommender">
              <span class="tip-text">已自动设置推荐人，允许修改</span>
            </div>
          </div>

          <!-- 备注信息 -->
          <div class="remark-section">
            <div class="section-title">备注:</div>
            <el-input
              type="textarea"
              :rows="3"
              placeholder="请输入备注信息"
              v-model="remarkText"
              style="width: 100%;"
            />
          </div>
        </div>
        </div>
      </div>

      <!-- 底部按钮 -->
      <div class="drawer-footer">
        <el-button @click="onCancelDrawer" size="large">取消</el-button>
        <el-button 
          type="primary" 
          @click="confirmRecharge" 
          size="large"
          :disabled="!canConfirmRecharge"
          :loading="isRecharging"
        >
          确认充值
        </el-button>
      </div>
    </el-drawer>

    <!-- 注册开卡弹窗 -->
    <DrawerRegisterCard
      v-model="showRegisterCardDialog"
      @registerSuccess="handleRegisterSuccess"
      @cancel="showRegisterCardDialog = false"
    />

    <!-- 支付方式选择弹窗 -->
    <PaymentMethodDialog 
      v-model="showPaymentMethodDialog"
      :recharge-info="rechargeFlowInfo"
      @paymentSuccess="handlePaymentSuccess"
      @cancel="showPaymentMethodDialog = false"
    />

    <!-- 支付成功弹窗 -->
    <PaymentSuccessDialog 
      v-model="showPaymentSuccessDialog"
      :payment-info="paymentSuccessInfo"
      @confirm="handlePaymentSuccessConfirm"
      @close="showPaymentSuccessDialog = false"
    />

    <!-- 充值流程弹窗 -->
    <DrawerRechargeFlow 
      v-model="showRechargeFlowDialog"
      :recharge-info="rechargeFlowInfo"
      @rechargeSuccess="handleRechargeFlowSuccess"
      @cancel="showRechargeFlowDialog = false"
    />
  </div>
</template>

<script>
import api_vip from "@/api/vip";
import DrawerRegisterCard from "./drawerRegisterCard.vue";
import DrawerRechargeFlow from "./drawerRechargeFlow.vue";
import PaymentMethodDialog from "./paymentMethodDialog.vue";
import PaymentSuccessDialog from "./paymentSuccessDialog.vue";

export default {
  name: "VipRechargeDrawer",
  components: {
    DrawerRegisterCard,
    DrawerRechargeFlow,
    PaymentMethodDialog,
    PaymentSuccessDialog,
  },
  props: {
    showDrawer: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      show: false,
      searchType: "phone",
      searchKeyword: "",
      searchResults: [],
      selectedCardIndex: -1,
      selectedMember: null,
      rechargeOptions: [],
      selectedOptionIndex: -1,
      customAmount: "",
      selectedRecommender: "",
      employeeOptions: [],
      remarkText: "",
      showKeyboard: false,
      isRecharging: false,
      showRegisterCardDialog: false,
      showPaymentMethodDialog: false,
      showPaymentSuccessDialog: false,
      showRechargeFlowDialog: false,
      rechargeFlowInfo: null,
      paymentSuccessInfo: null,
      newMemberInfo: {
        phone: "",
        name: ""
      }
    };
  },
  computed: {
    isCustomAmount() {
      return this.selectedOptionIndex === this.rechargeOptions.length - 1;
    },
    canConfirmRecharge() {
      return (
        this.selectedMember &&
        this.selectedOptionIndex >= 0 &&
        (!this.isCustomAmount || (this.customAmount && parseFloat(this.customAmount) > 0))
      );
    },
  },
  watch: {
    showDrawer: {
      handler(newVal) {
        this.show = newVal;
        if (newVal) {
          this.initData();
        }
      },
      immediate: true,
    },
  },
  methods: {
    initData() {
      this.searchKeyword = "";
      this.searchResults = [];
      this.selectedCardIndex = -1;
      this.selectedMember = null;
      this.rechargeOptions = [];
      this.selectedOptionIndex = -1;
      this.customAmount = "";
      this.selectedRecommender = "";
      this.employeeOptions = [];
      this.remarkText = "";
      this.isRecharging = false;
      
      // 重置员工选项为完整列表
      const orderPersonInfo = this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo || [];
      this.employeeOptions = [...orderPersonInfo];
    },

    async handleSearch() {
      if (this.searchKeyword.length < 4) {
        this.searchResults = [];
        this.selectedMember = null;
        this.rechargeOptions = [];
        return;
      }
      
      try {
        const res = await api_vip.reqGetCustCardListForDept({
          key: this.searchKeyword,
        });
        
        if (res.code === 1 && res.data && res.data.records) {
          this.searchResults = res.data.records;
          if (this.searchResults.length > 0) {
            // 默认选中第一个
            await this.selectCard(0);
          }
        } else {
          this.searchResults = [];
          this.selectedMember = null;
          this.rechargeOptions = [];
        }
      } catch (error) {
        console.error("搜索会员失败:", error);
        this.searchResults = [];
      }
    },

    async selectCard(index) {
      console.log("选择会员卡，索引:", index);
      this.selectedCardIndex = index;
      const selectedCard = this.searchResults[index];
      console.log("选中的会员卡:", selectedCard);
      if (selectedCard) {
        await this.loadRechargeOptions(selectedCard.id);
      }
    },

    async loadRechargeOptions(cardId) {
      try {
        console.log("开始加载充值选项，卡片ID:", cardId);
        
        // 并行获取会员卡详情、充值规则，然后加载默认推荐人
        const [cardRes, rulesRes] = await Promise.all([
          api_vip.reqGetVipCardDetailForMakeMoney({ id: cardId }),
          api_vip.reqGetDepositRulesForDept({ id: cardId })
        ]);
        
        console.log("Promise.all 完成，开始加载默认推荐人");
        
        if (cardRes.code === 1) {
          this.selectedMember = cardRes.data.mb_card;
          // 获取会员卡信息后，传递开卡推荐人信息
          await this.setRecommenderByRules(cardId, this.selectedMember.sales_emp_id);
        } else {
          // 如果获取会员卡信息失败，只根据上次充值推荐人设置
          await this.setRecommenderByRules(cardId, null);
        }
        
        if (rulesRes.code === 1 && rulesRes.data && rulesRes.data.records) {
          const rules = rulesRes.data.records;
          
          this.rechargeOptions = [
            ...rules.map(rule => ({
              display_price: (rule.d / 100).toFixed(2),
              gift_amount: rule.f / 100,
              gift_text: rule.f > 0 ? `充${(rule.d / 100).toFixed(0)}送${(rule.f / 100).toFixed(0)}元` : `充${(rule.d / 100).toFixed(0)}送${(rule.f / 100).toFixed(0)}元`,
              gift_points: rule.fp || 0,
              gift_coupon: rule.fkn || '',
              rule_data: rule,
            })),
            {
              display_price: "自定义",
              gift_amount: 0,
              gift_text: "会员充值",
              gift_points: 0,
              gift_coupon: '',
              rule_data: { d: "自定义", f: 0 },
            },
          ];
          
          // 默认选中第一个充值选项
          if (this.rechargeOptions.length > 0) {
            this.selectedOptionIndex = 0;
          }
        }
      } catch (error) {
        console.error("加载充值选项失败:", error);
      }
    },

    // 按照三层规则设置推荐人
    async setRecommenderByRules(cardId, openCardSalesEmpId) {
      try {
        console.log("开始按规则设置推荐人，卡ID:", cardId, "开卡推荐人ID:", openCardSalesEmpId);
        
        // 获取所有员工选项
        const orderPersonInfo = this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo || [];
        this.employeeOptions = orderPersonInfo;
        
        // 第一层：查询该卡上次充值时的充值推荐人
        const res = await api_vip.reqGetCustCardLastSales({
          card_id: cardId,
        });
        console.log("上次充值推荐人接口返回:", res);
        
        if (res.code === 1 && res.data && res.data.id) {
          const lastRechargeSalesEmpId = res.data.id;
          console.log("第一层：找到上次充值推荐人ID:", lastRechargeSalesEmpId, "姓名:", res.data.name);
          
          // 尝试在员工列表中找到匹配的推荐人
          const matchedEmployee = this.findEmployeeInOptions(lastRechargeSalesEmpId);
          if (matchedEmployee) {
            this.selectedRecommender = matchedEmployee.id;
            console.log("第一层：设置上次充值推荐人为默认值:", this.selectedRecommender);
            return;
          } else {
            console.log("第一层：上次充值推荐人不在当前员工列表中，添加到选项");
            // 将上次充值推荐人添加到员工选项中
            this.employeeOptions = [{
              id: lastRechargeSalesEmpId,
              name: res.data.name,
              code: ''
            }, ...orderPersonInfo];
            this.selectedRecommender = lastRechargeSalesEmpId;
            console.log("第一层：添加并设置上次充值推荐人为默认值:", this.selectedRecommender);
            return;
          }
        } else {
          console.log("第一层：没有找到上次充值推荐人");
        }
        
        // 第二层：如果没有上次充值推荐人，则使用开卡推荐人
        if (openCardSalesEmpId) {
          console.log("第二层：尝试使用开卡推荐人ID:", openCardSalesEmpId);
          const matchedEmployee = this.findEmployeeInOptions(openCardSalesEmpId);
          if (matchedEmployee) {
            this.selectedRecommender = matchedEmployee.id;
            console.log("第二层：设置开卡推荐人为默认值:", this.selectedRecommender);
            return;
          } else {
            console.log("第二层：开卡推荐人不在当前员工列表中");
          }
        } else {
          console.log("第二层：没有开卡推荐人信息");
        }
        
        // 第三层：如果前两层都没有，则推荐人为空白
        console.log("第三层：推荐人设置为空白，允许用户手动选择");
        this.selectedRecommender = "";
        
      } catch (error) {
        console.error("设置推荐人失败:", error);
        this.selectedRecommender = "";
      }
    },
    
    // 在员工选项中查找指定ID的员工
    findEmployeeInOptions(salesEmpId) {
      if (!salesEmpId) return null;
      
      const salesEmpIdStr = salesEmpId.toString();
      return this.employeeOptions.find(employee => 
        employee.id.toString() === salesEmpIdStr || 
        employee.id === salesEmpId
      );
    },

    selectOption(index) {
      this.selectedOptionIndex = index;
    },

    searchEmployee(query) {
      const orderPersonInfo = this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo || [];
      
      if (query) {
        // 过滤匹配查询条件的员工
        let filteredEmployees = orderPersonInfo.filter(
          emp => emp.name.includes(query) || (emp.code && emp.code.includes(query))
        );
        
        // 如果当前有选中的推荐人，且该推荐人不在过滤结果中，将其添加到结果顶部
        if (this.selectedRecommender) {
          const selectedEmp = this.employeeOptions.find(emp => emp.id === this.selectedRecommender);
          if (selectedEmp && !filteredEmployees.find(emp => emp.id === this.selectedRecommender)) {
            // 检查选中的推荐人是否匹配查询条件
            if (selectedEmp.name.includes(query) || (selectedEmp.code && selectedEmp.code.includes(query))) {
              filteredEmployees.unshift(selectedEmp);
            }
          }
        }
        
        this.employeeOptions = filteredEmployees;
      } else {
        // 没有查询条件时，显示所有员工，但确保自动设置的推荐人在列表中
        this.employeeOptions = [...orderPersonInfo];
        
        // 确保自动设置的推荐人在选项中
        if (this.selectedRecommender) {
          const selectedEmp = this.employeeOptions.find(emp => emp.id === this.selectedRecommender);
          if (!selectedEmp) {
            // 如果推荐人不在标准员工列表中，从之前保存的选项中寻找
            const autoSelectedEmp = this.employeeOptions.find(emp => emp.id === this.selectedRecommender) ||
                                   orderPersonInfo.find(emp => emp.id === this.selectedRecommender);
            if (autoSelectedEmp) {
              this.employeeOptions.unshift(autoSelectedEmp);
            }
          }
        }
      }
    },

    showRegisterCard() {
      this.showRegisterCardDialog = true;
    },

    // 注册成功后的处理
    handleRegisterSuccess(memberInfo) {
      this.$message.success(`会员 ${memberInfo.name} 注册成功！`);
      
      // 设置新会员信息，准备充值
      this.newMemberInfo = {
        phone: memberInfo.phone,
        name: memberInfo.name
      };
      
      // 显示充值流程弹窗
      this.showRechargeFlowDialog = true;
    },

    // 支付成功后的处理
    handlePaymentSuccess(paymentInfo) {
      // 保存支付成功信息
      this.paymentSuccessInfo = paymentInfo;
      
      // 显示支付成功弹窗
      this.showPaymentSuccessDialog = true;
    },

    // 支付成功确认后的处理
    handlePaymentSuccessConfirm() {
      // 关闭支付成功弹窗
      this.showPaymentSuccessDialog = false;
      
      // 刷新搜索结果，显示充值后的会员信息
      if (this.paymentSuccessInfo && this.paymentSuccessInfo.phone) {
        this.searchKeyword = this.paymentSuccessInfo.phone.slice(-4); // 使用手机号后四位搜索
        this.handleSearch();
      }
      
      // 清空支付成功信息
      this.paymentSuccessInfo = null;
    },

    // 充值流程成功后的处理
    handleRechargeFlowSuccess(rechargeInfo) {
      this.$message.success(`充值成功！金额：¥${rechargeInfo.amount}`);
      
      // 刷新搜索结果，显示新注册的会员
      if (rechargeInfo.phone) {
        this.searchKeyword = rechargeInfo.phone.slice(-4); // 使用手机号后四位搜索
        this.handleSearch();
      }
      
      // 关闭充值流程弹窗
      this.showRechargeFlowDialog = false;
    },

    async confirmRecharge() {
      if (!this.canConfirmRecharge) {
        return;
      }

      // 准备充值信息并跳转到支付方式选择
      const option = this.rechargeOptions[this.selectedOptionIndex];
      const isCustom = this.isCustomAmount;
      
      const rechargeInfo = {
        member: this.selectedMember,
        mode: isCustom ? 2 : 1, // 1: 标准充值, 2: 自定义充值
        depositAmount: isCustom ? this.customAmount : (option.rule_data.d / 100),
        freeAmount: isCustom ? 0 : (option.rule_data.f / 100),
        freePoints: isCustom ? 0 : (option.gift_points || 0),
        freeKqId: isCustom ? 0 : (option.rule_data.fk || 0), // 传递卡券ID
        salesEmpId: this.selectedRecommender || 0,
        remark: this.remarkText || "",
        option: option // 传递选择的充值档位信息
      };

      // 显示支付方式选择弹窗
      this.showPaymentMethodDialog = true;
      this.rechargeFlowInfo = rechargeInfo;
    },

    onCancelDrawer() {
      this.show = false;
      this.$emit("showOrHideDrawer");
    },

    handleRegisterSuccess(memberData) {
      // 注册成功后，将新会员信息填入充值表单
      if (memberData) {
        this.selectedMember = memberData;
        this.searchKeyword = memberData.bind_phone || memberData.card_no;
        this.$message.success("注册开卡成功，可以直接进行充值");
      }
    },

    // 获取弹窗尺寸
    getDrawerSize() {
      return "60%";
    },

    // 获取弹窗样式类
    getDrawerClass() {
      return '';
    },

    // 获取内容区域样式类
    getContentClass() {
      return '';
    },
  },
};
</script>

<style scoped lang="less">
.vip-recharge-drawer {
  .drawer-content {
    padding: 20px;
    height: calc(100vh - 120px);
    overflow-y: auto;

    .top-actions {
      display: flex;
      align-items: center;
      margin-bottom: 20px;
      
      .register-btn {
        background: #007bff;
        color: white;
        border: none;
        padding: 8px 20px;
        border-radius: 4px;
        cursor: pointer;
        margin-right: 15px;
        
        &:hover {
          background: #0056b3;
        }
      }
      
      .search-tip {
        color: #ffa500;
        font-size: 12px;
      }
    }

    .search-section {
      margin-bottom: 20px;
      
      .search-label {
        margin-bottom: 10px;
        font-size: 14px;
        
        .required {
          color: #ff4757;
          margin-right: 4px;
        }
      }
      
      .search-input {
        display: flex;
        align-items: center;
        margin-bottom: 10px;
      }
      
      .search-results {
        margin-top: 15px;
        max-height: 200px;
        overflow-y: auto;
        border: 1px solid #ddd;
        border-radius: 6px;
        
        .card-item {
          padding: 12px 15px;
          border-bottom: 1px solid #f0f0f0;
          cursor: pointer;
          transition: all 0.2s;
          
          &:last-child {
            border-bottom: none;
          }
          
          &:hover {
            background: #f8f9fa;
          }
          
          &.active {
            background: #409eff;
            color: white;
          }
        }
      }
      
    }

    .recharge-content {
      .member-info {
        background: #f8f9fa;
        padding: 15px;
        border-radius: 8px;
        margin-bottom: 20px;
        
        .info-row {
          display: flex;
          justify-content: space-between;
          margin-bottom: 10px;
          
          &:last-child {
            margin-bottom: 0;
          }
          
          .info-item {
            flex: 1;
            display: flex;
            align-items: center;
            
            .label {
              font-weight: 500;
              margin-right: 8px;
              min-width: 80px;
            }
            
            .value {
              color: #333;
            }
          }
        }
      }

      .recharge-options {
        margin-bottom: 20px;
        
        .section-title {
          margin-bottom: 15px;
          font-size: 14px;
          
          .required {
            color: #ff4757;
            margin-right: 4px;
          }
        }
        
        .options-grid {
          display: flex;
          flex-wrap: wrap;
          gap: 10px;
          
          .option-card {
            width: 180px;
            min-height: 100px;
            border: 1px solid #ddd;
            border-radius: 8px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            cursor: pointer;
            background: #f8f9fa;
            transition: all 0.3s;
            padding: 10px;
            
            &:hover {
              border-color: #409eff;
              background: #e3f2fd;
            }
            
            &.active {
              border-color: #409eff;
              background: #409eff;
              color: white;
            }
            
            .option-price {
              font-size: 18px;
              font-weight: bold;
              margin-bottom: 8px;
            }
            
            .option-gift {
              text-align: center;
              font-size: 12px;
              line-height: 1.4;
              
              .gift-money {
                color: #67c23a;
                margin-bottom: 2px;
              }
              
              .gift-points {
                color: #e6a23c;
                margin-bottom: 2px;
              }
              
              .gift-coupon {
                color: #f56c6c;
                margin-bottom: 2px;
              }
            }
            
            &.active .option-gift .gift-money,
            &.active .option-gift .gift-points,
            &.active .option-gift .gift-coupon {
              color: white;
            }
          }
        }
      }

      .custom-amount {
        margin-bottom: 20px;
        
        .input-group {
          display: flex;
          align-items: center;
          
          label {
            margin-right: 10px;
            min-width: 120px;
          }
          
          .amount-input-wrapper {
            .amount-input {
              height: 40px;
              border: 1px solid #ddd;
              border-radius: 4px;
              padding: 0 10px;
              font-size: 16px;
              width: 200px;
              
              &:focus {
                border-color: #409eff;
                outline: none;
              }
            }
          }
        }
      }

      .recommender-section,
      .remark-section {
        margin-bottom: 20px;
        
        .section-title {
          margin-bottom: 10px;
          font-size: 14px;
        }
        
        .recommender-tip {
          margin-top: 8px;
          
          .tip-text {
            color: #67c23a;
            font-size: 12px;
            background: #f0f9ff;
            padding: 4px 8px;
            border-radius: 4px;
            border: 1px solid #b3e5fc;
          }
        }
      }
    }

  }
}

  .drawer-footer {
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    padding: 20px;
    background: white;
    border-top: 1px solid #eee;
    display: flex;
    justify-content: center;
    gap: 20px;
  }

/deep/ .el-drawer__header {
  background: #007bff;
  color: white;
  margin-bottom: 0;
  padding: 20px;
}

/deep/ .el-drawer__title {
  color: white;
  font-size: 18px;
}

/deep/ .el-drawer__close-btn {
  color: white;
  font-size: 20px;
}

/deep/ .el-drawer__body {
  padding: 0;
  position: relative;
}

// 竖屏模式下确保弹窗宽度
@media (orientation: portrait) {
  /deep/ .el-drawer.rtl {
    width: 90% !important;
  }
}

// 小屏幕横屏模式
@media (orientation: landscape) and (max-width: 1200px) {
  /deep/ .el-drawer.rtl {
    width: 95% !important;
  }
}

// 动画
@keyframes blink {
  0%, 50% {
    opacity: 1;
  }
  51%, 100% {
    opacity: 0;
  }
}
</style>