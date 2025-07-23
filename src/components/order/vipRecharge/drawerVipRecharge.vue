<template>
  <div>
    <!-- 会员充值 -->
    <el-drawer
      title="会员充值"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="60%"
      class="vip-recharge-drawer"
    >
      <div class="drawer-content">
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
          
          <!-- 提示信息 -->
          <div class="tips-section">
            <div class="tip-item">
              1. 下拉框中显示查询的内容，点击可直接选择进入
            </div>
            <div class="tip-item">
              2. 下拉框提示：手机号-会员卡号-记名/不记名
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
                <div class="option-gift" v-if="option.gift_amount > 0">
                  {{ option.gift_text }}
                </div>
                <div class="option-points" v-if="option.gift_points > 0">
                  赠{{ option.gift_points }}积分
                </div>
              </div>
            </div>
          </div>

          <!-- 自定义充值金额 -->
          <div class="custom-amount" v-if="isCustomAmount">
            <div class="input-group">
              <label>自定义充值金额:</label>
              <div class="amount-input">
                <span class="input-display">{{ customAmount || '请输入金额' }}</span>
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

        <!-- 键盘输入区域 -->
        <div class="keyboard-section" v-if="showKeyboard">
          <keyboard
            :landscape="isLandscape"
            :oneLine="!isPortrait"
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
  </div>
</template>

<script>
import api_vip from "@/api/vip";
import keyboard from "@/components/common/keyBoard.vue";
import DrawerRegisterCard from "./drawerRegisterCard.vue";

export default {
  name: "VipRechargeDrawer",
  components: {
    keyboard,
    DrawerRegisterCard,
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
      
      // 键盘相关
      isLandscape: window.innerWidth > window.innerHeight,
      keyboardItemWidth: 88,
      keyboardItemHeight: 88,
      keyboardWidth: 500,
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
      this.showKeyboard = newVal;
      if (newVal) {
        this.customAmount = "";
      }
    },
  },
  mounted() {
    window.addEventListener("resize", this.updateKeyboardLayout);
  },
  beforeDestroy() {
    window.removeEventListener("resize", this.updateKeyboardLayout);
  },
  methods: {
    initData() {
      this.searchKeyword = "";
      this.selectedMember = null;
      this.rechargeOptions = [];
      this.selectedOptionIndex = -1;
      this.customAmount = "";
      this.selectedRecommender = "";
      this.employeeOptions = [];
      this.remarkText = "";
      this.showKeyboard = false;
      this.isRecharging = false;
    },

    updateKeyboardLayout() {
      this.isLandscape = window.innerWidth > window.innerHeight;
      if (this.isLandscape) {
        this.keyboardItemWidth = 88;
        this.keyboardItemHeight = 68;
        this.keyboardWidth = 600;
      } else {
        this.keyboardItemWidth = 88;
        this.keyboardItemHeight = 88;
        this.keyboardWidth = 280;
      }
    },

    async handleSearch() {
      if (this.searchKeyword.length < 4) {
        return;
      }
      
      try {
        const res = await api_vip.reqGetMakeMoneyListOfPhoneNum({
          phone: this.searchKeyword,
        });
        
        if (res.code === 1 && res.data.records.length > 0) {
          // 这里可以显示搜索结果供用户选择
          // 暂时直接选择第一个结果
          await this.selectMember(res.data.records[0]);
        }
      } catch (error) {
        console.error("搜索会员失败:", error);
      }
    },

    async selectMember(member) {
      this.selectedMember = member;
      await this.loadRechargeOptions(member.id);
    },

    async loadRechargeOptions(memberId) {
      try {
        const res = await api_vip.reqGetVipCardDetailForMakeMoney({
          id: memberId,
        });
        
        if (res.code === 1) {
          this.selectedMember = res.data.mb_card;
          const rules = res.data.deposit_rules || [];
          
          this.rechargeOptions = [
            ...rules.map(rule => ({
              display_price: (rule.d / 100).toFixed(2),
              gift_amount: rule.f / 100,
              gift_text: rule.f > 0 ? `赠${(rule.f / 100).toFixed(2)}元` : '',
              gift_points: rule.pt || 0,
              rule_data: rule,
            })),
            {
              display_price: "自定义",
              gift_amount: 0,
              gift_text: "会员充值",
              gift_points: 0,
              rule_data: { d: "自定义", f: 0 },
            },
          ];
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

    async confirmRecharge() {
      if (!this.canConfirmRecharge) {
        return;
      }

      this.isRecharging = true;
      
      try {
        const option = this.rechargeOptions[this.selectedOptionIndex];
        const isCustom = this.isCustomAmount;
        
        const params = {
          id: this.selectedMember.id,
          val_amt: isCustom ? this.customAmount : option.rule_data.d / 100,
          free_amt: isCustom ? "0" : option.rule_data.f / 100,
          pt_amt: isCustom ? 0 : option.gift_points,
          m: isCustom ? 2 : 1,
          oper_emp_id: this.$store.state.userInfo.emp_id,
          deposit_cnl: 1, // 默认充值渠道
          sales_emp_id: this.selectedRecommender || 0,
          remark: this.remarkText,
        };

        const res = await api_vip.reqMakeMoneyToCard(params);
        
        if (res.code === 1) {
          this.$message.success("充值成功!");
          this.onCancelDrawer();
          this.$emit("rechargeSuccess");
        } else {
          this.$message.error(res.msg || "充值失败");
        }
      } catch (error) {
        console.error("充值失败:", error);
        this.$message.error("充值失败，请重试");
      } finally {
        this.isRecharging = false;
      }
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
      
      .tips-section {
        background: #fff3cd;
        padding: 10px;
        border-radius: 4px;
        border: 1px solid #ffeaa7;
        
        .tip-item {
          font-size: 12px;
          color: #856404;
          margin-bottom: 5px;
          
          &:last-child {
            margin-bottom: 0;
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
            width: 120px;
            height: 80px;
            border: 1px solid #ddd;
            border-radius: 8px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            cursor: pointer;
            background: #f8f9fa;
            transition: all 0.3s;
            
            &:hover {
              border-color: #007bff;
              background: #e3f2fd;
            }
            
            &.active {
              border-color: #007bff;
              background: #007bff;
              color: white;
            }
            
            .option-price {
              font-size: 18px;
              font-weight: bold;
              margin-bottom: 4px;
            }
            
            .option-gift {
              font-size: 12px;
              color: #28a745;
            }
            
            .option-points {
              font-size: 11px;
              color: #ffc107;
            }
            
            &.active .option-gift,
            &.active .option-points {
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
          
          .amount-input {
            .input-display {
              display: inline-block;
              padding: 8px 12px;
              border: 1px solid #ddd;
              border-radius: 4px;
              background: #f8f9fa;
              min-width: 200px;
              font-size: 16px;
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
</style>