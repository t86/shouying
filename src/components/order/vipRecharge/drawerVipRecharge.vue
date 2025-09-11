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
                  v-if="!showVirtualKeyboard"
                  type="number"
                  v-model="customAmount"
                  placeholder="请输入金额"
                  class="amount-input"
                  step="0.01"
                  min="0"
                />
                <div 
                  v-else
                  class="amount-input virtual-input"
                  @click="focusAmountInput"
                >
                  <span class="input-display">{{ customAmount || '请输入金额' }}</span>
                  <span class="cursor-blink" v-if="isAmountInputFocused"></span>
                </div>
              </div>
            </div>
          </div>

          <!-- 推荐人选择 -->
          <div class="recommender-section">
            <div class="section-title">推荐人:</div>
            <el-select
              v-model="selectedRecommender"
              placeholder="输入员工姓名或工号"
              filterable
              remote
              :remote-method="searchEmployee"
              style="width: 300px;"
              size="small"
            >
              <el-option
                v-for="emp in employeeOptions"
                :key="emp.id"
                :label="`${emp.name} (${emp.code})`"
                :value="emp.id"
              />
            </el-select>
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

        <!-- 虚拟键盘区域 -->
        <div class="keyboard-section" v-if="showVirtualKeyboard">
          <vip-keyboard
            :landscape="isLandscape"
            :itemWidth="keyboardItemWidth"
            :itemHeight="keyboardItemHeight"
            :width="keyboardWidth"
            @changeNum="handleKeyboardInput"
          />
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
import vipKeyboard from "@/components/common/vipKeyBoard.vue";
import DrawerRegisterCard from "./drawerRegisterCard.vue";
import DrawerRechargeFlow from "./drawerRechargeFlow.vue";
import PaymentMethodDialog from "./paymentMethodDialog.vue";
import PaymentSuccessDialog from "./paymentSuccessDialog.vue";

export default {
  name: "VipRechargeDrawer",
  components: {
    vipKeyboard,
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
      },
      
      // 键盘相关
      isLandscape: window.innerWidth > window.innerHeight,
      keyboardItemWidth: 88,
      keyboardItemHeight: 88,
      keyboardWidth: 500,
      showVirtualKeyboard: false,
      isMobile: false,
      isTablet: false,
      windowWidth: window.innerWidth,
      windowHeight: window.innerHeight,
      isAmountInputFocused: false
    };
  },
  computed: {
    isPortrait() {
      return !this.isLandscape;
    },
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
          this.updateKeyboardLayout();
        }
      },
      immediate: true,
    },
    isCustomAmount(newVal) {
      if (newVal) {
        this.customAmount = "";
        if (this.showVirtualKeyboard) {
          this.isAmountInputFocused = true;
        }
      } else {
        this.isAmountInputFocused = false;
      }
    },
  },
  mounted() {
    this.detectDevice();
    window.addEventListener("resize", this.updateKeyboardLayout);
    window.addEventListener("resize", this.handleResize);
  },
  beforeDestroy() {
    window.removeEventListener("resize", this.updateKeyboardLayout);
    window.removeEventListener("resize", this.handleResize);
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
    },

    // 检测设备类型
    detectDevice() {
      const userAgent = navigator.userAgent;
      const platform = navigator.platform;
      
      // 检测是否是移动设备
      this.isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(userAgent);
      
      // 检测是否是平板
      this.isTablet = /iPad|Android.*(?=.*\btablet\b)/i.test(userAgent) || 
                     (platform === 'MacIntel' && navigator.maxTouchPoints > 1);
      
      // 检测是否是桌面浏览器
      const isDesktop = !this.isMobile && !this.isTablet;
      
      // 只有在移动设备或平板上才显示虚拟键盘
      this.showVirtualKeyboard = (this.isMobile || this.isTablet) && !isDesktop;
      
      this.updateScreenSize();
    },

    // 处理屏幕尺寸变化
    handleResize() {
      this.updateScreenSize();
      this.updateKeyboardLayout();
    },

    // 更新屏幕尺寸
    updateScreenSize() {
      this.windowWidth = window.innerWidth;
      this.windowHeight = window.innerHeight;
      this.isLandscape = this.windowWidth > this.windowHeight;
    },

    updateKeyboardLayout() {
      this.isLandscape = window.innerWidth > window.innerHeight;
      
      if (this.isLandscape) {
        // 横屏模式
        if (this.windowWidth >= 1200) {
          // 大屏幕：键盘可以横向布局，放在右侧
          this.keyboardItemWidth = 70;
          this.keyboardItemHeight = 60;
          this.keyboardWidth = 300;
        } else {
          // 小屏幕：键盘竖向布局，两列
          this.keyboardItemWidth = 65;
          this.keyboardItemHeight = 55;
          this.keyboardWidth = 200;
        }
      } else {
        // 竖屏模式：键盘横向布局，放在底部
        this.keyboardItemWidth = 70;
        this.keyboardItemHeight = 50;
        this.keyboardWidth = Math.min(400, this.windowWidth - 40);
      }
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
      this.selectedCardIndex = index;
      const selectedCard = this.searchResults[index];
      if (selectedCard) {
        await this.loadRechargeOptions(selectedCard.id);
      }
    },

    async loadRechargeOptions(cardId) {
      try {
        // 首先获取会员卡详情
        const cardRes = await api_vip.reqGetVipCardDetailForMakeMoney({
          id: cardId,
        });
        
        if (cardRes.code === 1) {
          this.selectedMember = cardRes.data.mb_card;
        }
        
        // 然后获取充值规则
        const rulesRes = await api_vip.reqGetDepositRulesForDept({
          id: cardId,
        });
        
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

    selectOption(index) {
      this.selectedOptionIndex = index;
    },

    handleKeyboardInput(keyId) {
      if (keyId === 10) {
        // 清空
        this.customAmount = "";
      } else if (keyId === 11) {
        // 删除
        if (this.customAmount.length > 0) {
          this.customAmount = this.customAmount.slice(0, -1);
        }
      } else if (keyId >= 0 && keyId <= 9) {
        // 数字输入
        if (this.customAmount.includes('.') && this.customAmount.split('.')[1].length >= 2) {
          return; // 限制小数点后两位
        }
        this.customAmount += keyId.toString();
      }
    },

    searchEmployee(query) {
      if (query) {
        const orderPersonInfo = this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo || [];
        this.employeeOptions = orderPersonInfo.filter(
          emp => emp.name.includes(query) || emp.code.includes(query)
        );
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

    // 焦点控制
    focusAmountInput() {
      this.isAmountInputFocused = true;
    },

    blurAmountInput() {
      this.isAmountInputFocused = false;
    },


    // 获取弹窗尺寸
    getDrawerSize() {
      if (!this.showVirtualKeyboard) {
        return "60%";
      }
      
      // 有虚拟键盘时，根据屏幕方向调整
      if (this.isLandscape) {
        // 横屏：如果是大屏幕，增加宽度以容纳键盘
        return this.windowWidth >= 1200 ? "80%" : "95%";
      } else {
        // 竖屏：需要更大的宽度来容纳内容和键盘
        return "90%";
      }
    },

    // 获取弹窗样式类
    getDrawerClass() {
      const classes = [];
      if (this.showVirtualKeyboard) {
        classes.push('with-keyboard');
        if (this.isLandscape) {
          classes.push('landscape-keyboard');
        } else {
          classes.push('portrait-keyboard');
        }
      }
      return classes;
    },

    // 获取内容区域样式类
    getContentClass() {
      const classes = [];
      if (this.showVirtualKeyboard) {
        if (this.isLandscape && this.windowWidth >= 1200) {
          classes.push('side-keyboard-layout');
        } else if (this.isLandscape) {
          classes.push('compact-layout');
        } else {
          classes.push('bottom-keyboard-layout');
        }
      }
      return classes;
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
            
            .virtual-input {
              height: 40px;
              border: 1px solid #ddd;
              border-radius: 4px;
              background: #f8f9fa;
              padding: 0 10px;
              display: flex;
              align-items: center;
              cursor: pointer;
              position: relative;
              width: 200px;
              
              &:hover {
                border-color: #409eff;
              }
              
              .input-display {
                color: #333;
                font-size: 16px;
                flex: 1;
              }
              
              .cursor-blink {
                width: 1px;
                height: 20px;
                background: #333;
                animation: blink 1s infinite;
                margin-left: 2px;
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
      }
    }

    .keyboard-section {
      margin-top: 20px;
      display: flex;
      justify-content: center;
      padding: 20px;
      background: #f8f9fa;
      border-radius: 8px;
    }
  }

  // 有虚拟键盘时的布局
  &.with-keyboard {
    .drawer-content {
      height: 100%;
      
      // 大屏幕横屏：左右布局
      &.side-keyboard-layout {
        display: flex;
        gap: 20px;
        
        .main-content {
          flex: 1;
          max-width: calc(100% - 350px);
        }
        
        .keyboard-section {
          width: 320px;
          margin-top: 0;
          height: fit-content;
          position: sticky;
          top: 20px;
        }
      }
      
      // 小屏幕横屏：紧凑布局
      &.compact-layout {
        .main-content {
          margin-bottom: 20px;
        }
        
        .keyboard-section {
          position: sticky;
          bottom: 20px;
          margin-top: 10px;
          z-index: 10;
        }
      }
      
      // 竖屏：键盘在底部
      &.bottom-keyboard-layout {
        display: flex;
        flex-direction: column;
        height: 100%;
        
        .main-content {
          flex: 1;
          overflow-y: auto;
          margin-bottom: 10px;
        }
        
        .keyboard-section {
          position: sticky;
          bottom: 0;
          margin-top: auto;
          z-index: 10;
          background: white;
          border-top: 2px solid #e0e0e0;
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