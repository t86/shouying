<template>
  <div>
    <!-- 注册开卡弹窗 -->
  <el-dialog
    title="注册开卡"
    :visible.sync="show"
    :before-close="onCancelDialog"
    width="800px"
    custom-class="register-card-dialog"
    :close-on-click-modal="false"
    :append-to-body="true"
    :modal-append-to-body="true"
  >

      <!-- 手机号输入模式 -->
      <div v-if="currentMode === 'phone'" class="phone-input-mode">
        <div class="phone-input-section">
          <div class="input-label">手机号：</div>
          <div class="phone-input">
            <el-input
              v-model="phoneNumber"
              placeholder="请输入完整手机号"
              :maxlength="11"
              @input="handlePhoneInput"
              @keyup.enter="checkPhoneNumber"
            />
          </div>
        </div>

        <!-- 数字键盘 -->
        <div class="number-keyboard">
          <div class="keyboard-grid">
            <div class="key-row">
              <div class="key" @click="inputNumber('7')">7</div>
              <div class="key" @click="inputNumber('8')">8</div>
              <div class="key" @click="inputNumber('9')">9</div>
            </div>
            <div class="key-row">
              <div class="key" @click="inputNumber('4')">4</div>
              <div class="key" @click="inputNumber('5')">5</div>
              <div class="key" @click="inputNumber('6')">6</div>
            </div>
            <div class="key-row">
              <div class="key" @click="inputNumber('1')">1</div>
              <div class="key" @click="inputNumber('2')">2</div>
              <div class="key" @click="inputNumber('3')">3</div>
            </div>
            <div class="key-row">
              <div class="key clear" @click="clearPhone">清空</div>
              <div class="key" @click="inputNumber('0')">0</div>
              <div class="key backspace" @click="backspacePhone">回退</div>
            </div>
          </div>
        </div>

        <!-- 查询按钮 -->
        <div class="check-button-section">
          <el-button 
            type="primary" 
            size="large"
            @click="checkPhoneNumber"
            :loading="isCheckingPhone"
            :disabled="!isPhoneValid"
          >
            查询手机号
          </el-button>
        </div>

        <!-- 检测结果按钮（仅在手机号已存在时显示） -->
        <div v-if="showExistsButton" class="exists-button-section">
          <el-button 
            type="warning" 
            size="large"
            @click="handlePhoneExists"
          >
            该手机号已有会员卡，无需开卡
          </el-button>
        </div>
      </div>

      <!-- 注册表单模式 -->
      <div v-if="currentMode === 'form'" class="form-input-mode">
        <div class="form-section">
          <div class="form-row">
            <div class="form-label">手机号：</div>
            <div class="form-input">
              <el-input
                v-model="formData.phone"
                placeholder="请输入完整手机号"
                :maxlength="11"
                disabled
              />
            </div>
          </div>

          <div class="form-row">
            <div class="form-label">姓名：</div>
            <div class="form-input" :class="{ 'input-focused': currentFocusField === 'name' }">
              <el-input
                ref="nameInput"
                v-model="formData.name"
                placeholder="请输入姓名"
                @click.native="handleNameInputClick"
                @blur="handleNameInputBlur"
              />
            </div>
          </div>

          <div class="form-row">
            <div class="form-label">性别：</div>
            <div class="form-input">
              <el-radio-group v-model="formData.gender">
                <el-radio :label="1">男</el-radio>
                <el-radio :label="2">女</el-radio>
              </el-radio-group>
            </div>
          </div>

          <div class="form-row">
            <div class="form-label">生日：</div>
            <div class="form-input">
              <el-date-picker
                v-model="formData.birthday"
                type="date"
                placeholder="选择时间"
                style="width: 100%"
                format="yyyy-MM-dd"
                value-format="yyyy-MM-dd"
              />
            </div>
          </div>

          <div class="form-row">
            <div class="form-label">开卡推荐人：</div>
            <div class="form-input" :class="{ 'input-focused': currentFocusField === 'recommender' }">
              <el-select
                ref="recommenderSelect"
                v-model="formData.recommenderId"
                placeholder="输入员工姓名或工号"
                filterable
                remote
                reserve-keyword
                :remote-method="searchEmployees"
                :loading="loadingEmployees"
                style="width: 100%"
                @focus="handleRecommenderFocus"
                @blur="handleRecommenderBlur"
              >
                <el-option
                  v-for="emp in employeeOptions"
                  :key="emp.id"
                  :label="`${emp.name} (${emp.code})`"
                  :value="emp.id"
                />
              </el-select>
            </div>
          </div>
        </div>

        <!-- 右侧数字键盘（仅在表单模式下显示） -->
        <div class="form-keyboard">
          <div class="keyboard-grid">
            <div class="key-row">
              <div class="key" @click="inputToForm('7')">7</div>
              <div class="key" @click="inputToForm('8')">8</div>
              <div class="key" @click="inputToForm('9')">9</div>
            </div>
            <div class="key-row">
              <div class="key" @click="inputToForm('4')">4</div>
              <div class="key" @click="inputToForm('5')">5</div>
              <div class="key" @click="inputToForm('6')">6</div>
            </div>
            <div class="key-row">
              <div class="key" @click="inputToForm('1')">1</div>
              <div class="key" @click="inputToForm('2')">2</div>
              <div class="key" @click="inputToForm('3')">3</div>
            </div>
            <div class="key-row">
              <div class="key clear" @click="clearFormField">清空</div>
              <div class="key" @click="inputToForm('0')">0</div>
              <div class="key backspace" @click="backspaceFormField">回退</div>
            </div>
          </div>
        </div>
      </div>

      <!-- 底部按钮 -->
      <div slot="footer" class="dialog-footer">
        <el-button @click="onCancelDialog" size="large">取消</el-button>
        <el-button 
          v-if="currentMode === 'form'"
          type="primary" 
          @click="confirmRegister" 
          size="large"
          :disabled="!canConfirmRegister"
          :loading="isRegistering"
        >
          确认开卡
        </el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import api_vip from "@/api/vip";
import api_order from "@/api/order";

export default {
  name: "DrawerRegisterCard",
  props: {
    value: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      show: false,
      currentMode: "phone", // 'phone' | 'form'
      phoneNumber: "",
      showExistsButton: false,
      isCheckingPhone: false,
      formData: {
        phone: "",
        name: "",
        gender: 1,
        birthday: "",
        recommenderId: ""
      },
      employeeOptions: [],
      loadingEmployees: false,
      isRegistering: false,
      currentFocusField: "name" // 当前焦点字段，用于键盘输入
    };
  },
  computed: {
    isPhoneValid() {
      return /^1[3-9]\d{9}$/.test(this.phoneNumber);
    },
    canConfirmRegister() {
      return this.formData.phone && this.formData.name && /^1[3-9]\d{9}$/.test(this.formData.phone);
    }
  },
  watch: {
    value: {
      immediate: true,
      handler(val) {
        this.show = val;
        if (val) {
          this.resetForm();
        }
      }
    },
    show(val) {
      this.$emit("input", val);
    },
    phoneNumber: {
      handler(val) {
        // 重置状态
        this.showExistsButton = false;
        this.currentMode = "phone";
      },
      immediate: false
    }
  },
  methods: {
    handlePhoneInput(val) {
      // 只允许数字
      this.phoneNumber = val.replace(/\D/g, "");
    },

    inputNumber(num) {
      if (this.phoneNumber.length < 11) {
        this.phoneNumber += num;
      }
    },

    inputToForm(num) {
      if (this.currentFocusField === "name") {
        this.formData.name += num;
      }
    },

    clearPhone() {
      this.phoneNumber = "";
      this.showExistsButton = false;
    },

    clearFormField() {
      if (this.currentFocusField === "name") {
        this.formData.name = "";
      }
    },

    backspacePhone() {
      this.phoneNumber = this.phoneNumber.slice(0, -1);
      if (!this.isPhoneValid) {
        this.showExistsButton = false;
      }
    },

    backspaceFormField() {
      if (this.currentFocusField === "name") {
        this.formData.name = this.formData.name.slice(0, -1);
      }
    },

    async checkPhoneNumber() {
      if (!this.isPhoneValid) {
        this.$message.warning("请输入正确的手机号格式");
        return;
      }

      this.isCheckingPhone = true;
      try {
        // 使用新的API接口查询客人信息
        const res = await api_order.get_cust_items_for_csm({ 
          cust_phone: this.phoneNumber
        });
        
        if (res.code === 1 && res.data && res.data.records && res.data.records.length > 0) {
          // 手机号已存在会员信息
          this.showExistsButton = true;
          this.$message.info("检测到该手机号已有客人信息，可能已有会员卡");
        } else {
          // 手机号未注册，切换到表单模式
          this.showExistsButton = false;
          this.switchToFormMode();
        }
      } catch (error) {
        console.error("检查手机号失败:", error);
        // 出错时也切换到表单模式
        this.switchToFormMode();
      } finally {
        this.isCheckingPhone = false;
      }
    },

    switchToFormMode() {
      this.currentMode = "form";
      this.formData.phone = this.phoneNumber;
    },

    handlePhoneExists() {
      this.$message.info("该手机号已有会员卡，无需开卡");
      this.onCancelDialog();
    },

    async confirmRegister() {
      if (!this.canConfirmRegister) {
        return;
      }

      this.isRegistering = true;
      try {
        // 使用新的API接口创建记名会员卡
        const params = {
          bind_phone: this.formData.phone,
          name: this.formData.name,
          sex: this.formData.gender, // 1 男, 2 女, 0 空
          birth_day: this.formData.birthday || "", // yyyy-mm-dd格式
          sales_emp_id: this.formData.recommenderId * 1 || 0 // 开卡推荐人Id
        };

        const res = await api_vip.reqNewCustCardForDept(params);
        
        if (res.code === 1) {
          this.$message.success("注册开卡成功!");
          // 发送成功事件，包含注册信息用于后续充值
          this.$emit("registerSuccess", {
            phone: this.formData.phone,
            name: this.formData.name,
            success: true
          });
          this.onCancelDialog();
        } else {
          this.$message.error(res.msg || "注册开卡失败");
        }
      } catch (error) {
        console.error("注册开卡失败:", error);
        this.$message.error("注册开卡失败，请重试");
      } finally {
        this.isRegistering = false;
      }
    },

    resetForm() {
      this.currentMode = "phone";
      this.phoneNumber = "";
      this.showExistsButton = false;
      this.formData = {
        phone: "",
        name: "",
        gender: 1,
        birthday: "",
        recommenderId: ""
      };
      this.employeeOptions = [];
      this.currentFocusField = "name";
    },

    onCancelDialog() {
      this.show = false;
      this.$emit("cancel");
    },

    // 加载初始员工列表
    async loadInitialEmployees() {
      if (this.employeeOptions.length === 0) {
        await this.searchEmployees("");
      }
    },

    // 搜索员工
    async searchEmployees(query) {
      this.loadingEmployees = true;
      try {
        // 从store中获取员工信息
        const cardPageInfo = this.$store.state.cardPageInfo;
        const resResultDataObj = cardPageInfo && cardPageInfo.resResultDataObj;
        const orderPersonInfo = (resResultDataObj && resResultDataObj.orderPersonInfo) || [];
        
        if (orderPersonInfo.length > 0) {
          // 根据查询条件过滤员工
          const filteredEmployees = query 
            ? orderPersonInfo.filter(emp => 
                emp.name.includes(query) || 
                emp.code.toString().includes(query) ||
                (emp.namePy && emp.namePy.toLowerCase().includes(query.toLowerCase()))
              )
            : orderPersonInfo;
          
          this.employeeOptions = filteredEmployees.map(emp => ({
            id: emp.id,
            name: emp.name,
            code: emp.code
          }));
        } else {
          this.employeeOptions = [];
        }
      } catch (error) {
        console.error("搜索员工失败:", error);
        this.employeeOptions = [];
      } finally {
        this.loadingEmployees = false;
      }
    },

    // 处理姓名输入框点击 - 显示系统键盘
    handleNameInputClick(event) {
      console.log('姓名输入框被点击');
      this.currentFocusField = 'name';
      this.keyboardShow('nameInput');
    },

    // 处理姓名输入框失去焦点 - 隐藏系统键盘
    handleNameInputBlur() {
      console.log('姓名输入框失去焦点');
      this.currentFocusField = '';
      this.keyboardLeave();
    },

    // 处理推荐人选择框聚焦
    handleRecommenderFocus() {
      console.log('推荐人选择框获得焦点');
      this.currentFocusField = 'recommender';
      this.loadInitialEmployees();
      this.keyboardShow('recommenderSelect');
    },

    // 处理推荐人选择框失焦
    handleRecommenderBlur() {
      console.log('推荐人选择框失去焦点');
      this.currentFocusField = '';
      this.keyboardLeave();
    },

    // 显示系统键盘
    keyboardShow(refString) {
      console.log('尝试显示系统键盘，ref:', refString);
      if (
        window.atool &&
        window.atool.getTermType() == "android" &&
        "showSoftInput" in window.atool
      ) {
        console.log('调用 atool.showSoftInput()');
        atool.showSoftInput();
        // 对于 el-input 组件，需要获取其内部的 input 元素
        // 对于 el-select 组件，需要特殊处理
        this.$nextTick(() => {
          const refElement = this.$refs[refString];
          console.log('获取到的 ref 元素:', refElement);
          if (refElement) {
            // 如果是 el-input 组件，需要调用其 focus 方法
            if (refElement.focus && typeof refElement.focus === 'function') {
              console.log('调用 focus 方法');
              refElement.focus();
            }
            // 如果是原生 input 元素，直接 focus
            else if (refElement.tagName === 'INPUT') {
              console.log('原生 input 元素 focus');
              refElement.focus();
            }
          }
        });
      } else {
        console.log('atool 不可用或非 android 环境');
      }
    },

    // 隐藏系统键盘
    keyboardLeave() {
      console.log('隐藏系统键盘');
      setTimeout(() => {
        if (
          window.atool &&
          window.atool.getTermType() == "android" &&
          "hideSoftInput" in window.atool
        ) {
          console.log('调用 atool.hideSoftInput()');
          atool.hideSoftInput();
          atool.restart();
        }
      }, 10);
    }
  }
};
</script>

<style scoped lang="less">
.register-card-dialog {
  .tips-header {
    background: #fff3cd;
    padding: 12px;
    border-radius: 6px;
    border: 1px solid #ffeaa7;
    margin-bottom: 20px;
    
    p {
      margin: 6px 0;
      font-size: 12px;
      color: #856404;
      line-height: 1.4;
      
      &:first-child {
        font-weight: 500;
        color: #8b4513;
      }
    }
  }

  .phone-input-mode {
    min-height: 400px;
    padding: 15px;
    
    .phone-input-section {
      margin-bottom: 20px;
      text-align: center;

      .input-label {
        font-size: 16px;
        font-weight: 600;
        margin-bottom: 12px;
        color: #303133;
      }

      .phone-input {
        max-width: 300px;
        margin: 0 auto;

        /deep/ .el-input__inner {
          height: 44px;
          font-size: 18px;
          text-align: center;
          border: 2px solid #dcdfe6;
          border-radius: 6px;
          
          &:focus {
            border-color: #409eff;
            box-shadow: 0 0 0 2px rgba(64, 158, 255, 0.2);
          }
        }
      }
    }

    .number-keyboard {
      margin: 20px auto;
      max-width: 280px;

      .keyboard-grid {
        .key-row {
          display: flex;
          gap: 8px;
          margin-bottom: 8px;

          .key {
            flex: 1;
            height: 44px;
            background: linear-gradient(145deg, #ffffff, #f0f2f5);
            border: 1px solid #e4e7ed;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s ease;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);

            &:hover {
              background: linear-gradient(145deg, #e6f7ff, #d9ecff);
              border-color: #409eff;
              transform: translateY(-1px);
              box-shadow: 0 2px 6px rgba(64, 158, 255, 0.2);
            }

            &:active {
              transform: translateY(0);
              box-shadow: 0 1px 3px rgba(64, 158, 255, 0.3);
            }

            &.clear, &.backspace {
              background: linear-gradient(145deg, #fef0f0, #fde2e2);
              border-color: #fbc4c4;
              color: #f56c6c;
              font-size: 14px;
              font-weight: 500;

              &:hover {
                background: linear-gradient(145deg, #fde2e2, #fbc4c4);
                transform: translateY(-1px);
                box-shadow: 0 2px 6px rgba(245, 108, 108, 0.2);
              }
            }
          }
        }
      }
    }

    .check-button-section {
      text-align: center;
      margin: 20px 0 15px;

      .el-button {
        width: 220px;
        height: 42px;
        font-size: 16px;
        font-weight: 500;
        border-radius: 21px;
      }
    }

    .exists-button-section {
      text-align: center;
      margin-top: 15px;

      .el-button {
        width: 260px;
        height: 42px;
        font-size: 14px;
        font-weight: 500;
        border-radius: 21px;
      }
    }
  }

  .form-input-mode {
    display: flex;
    gap: 20px;
    min-height: 350px;
    padding: 15px;

    .form-section {
      flex: 2;
      padding: 15px;
      background: #fafafa;
      border-radius: 8px;
      border: 1px solid #e4e7ed;

      .form-row {
        display: flex;
        align-items: center;
        margin-bottom: 18px;

        .form-label {
          width: 100px;
          font-size: 14px;
          font-weight: 600;
          color: #303133;
        }

        .form-input {
          flex: 1;
          transition: all 0.3s ease;

          // 焦点高亮效果
          &.input-focused {
            /deep/ .el-input__inner,
            /deep/ .el-select .el-input__inner {
              border-color: #409eff !important;
              box-shadow: 0 0 0 2px rgba(64, 158, 255, 0.2) !important;
              background-color: #f0f9ff !important;
            }
          }

          /deep/ .el-input__inner {
            height: 38px;
            font-size: 14px;
            border: 1px solid #dcdfe6;
            border-radius: 6px;
            transition: all 0.3s ease;
            
            &:focus {
              border-color: #409eff;
              box-shadow: 0 0 0 2px rgba(64, 158, 255, 0.2);
            }
          }

          /deep/ .el-radio {
            margin-right: 20px;
            font-size: 14px;
            
            .el-radio__label {
              font-size: 14px;
              color: #303133;
            }
          }

          /deep/ .el-date-editor {
            width: 100%;
            
            .el-input__inner {
              height: 38px;
              font-size: 14px;
              background-color: #ffffff !important;
              color: #303133 !important;
              border: 1px solid #dcdfe6;
              
              &::placeholder {
                color: #c0c4cc !important;
              }
              
              &:focus {
                border-color: #409eff;
                background-color: #ffffff !important;
                color: #303133 !important;
              }
            }
            
            .el-input__prefix {
              color: #909399;
            }
            
            .el-input__suffix {
              color: #909399;
            }
          }

          /deep/ .el-select {
            width: 100%;
            
            .el-input__inner {
              height: 38px;
              font-size: 14px;
            }
          }
        }
      }
    }

    .form-keyboard {
      flex: 1;
      padding: 15px;

      .keyboard-grid {
        .key-row {
          display: flex;
          gap: 6px;
          margin-bottom: 6px;

          .key {
            width: 50px;
            height: 42px;
            background: linear-gradient(145deg, #ffffff, #f0f2f5);
            border: 1px solid #e4e7ed;
            border-radius: 6px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s ease;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);

            &:hover {
              background: linear-gradient(145deg, #e6f7ff, #d9ecff);
              border-color: #409eff;
              transform: translateY(-1px);
              box-shadow: 0 2px 4px rgba(64, 158, 255, 0.2);
            }

            &:active {
              transform: translateY(0);
            }

            &.clear, &.backspace {
              background: linear-gradient(145deg, #fef0f0, #fde2e2);
              border-color: #fbc4c4;
              color: #f56c6c;
              font-size: 12px;
              font-weight: 500;

              &:hover {
                background: linear-gradient(145deg, #fde2e2, #fbc4c4);
                box-shadow: 0 2px 4px rgba(245, 108, 108, 0.2);
              }
            }
          }
        }
      }
    }
  }

  .dialog-footer {
    text-align: center;
    padding: 15px 0;
    border-top: 1px solid #e4e7ed;
    background: #fafafa;

    .el-button {
      width: 120px;
      height: 38px;
      font-size: 14px;
      font-weight: 500;
      margin: 0 10px;
      border-radius: 19px;
      
      &.el-button--primary {
        background: linear-gradient(135deg, #409eff, #337ecc);
        border: none;
        
        &:hover {
          background: linear-gradient(135deg, #337ecc, #2d6bb3);
        }
      }
    }
  }
}

/deep/ .register-card-dialog {
  z-index: 3100 !important;
}

/deep/ .register-card-dialog .el-dialog {
  margin-top: 2vh !important;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15);
  max-height: 90vh;
  overflow-y: auto;
}

/deep/ .register-card-dialog .el-dialog__header {
  background: linear-gradient(135deg, #409eff, #337ecc);
  padding: 15px 20px;
  border-bottom: none;

  .el-dialog__title {
    font-size: 16px;
    font-weight: 600;
    color: #ffffff;
  }

  .el-dialog__close {
    color: #ffffff;
    font-size: 18px;
    
    &:hover {
      color: #ffffff;
      background: rgba(255, 255, 255, 0.2);
      border-radius: 50%;
    }
  }
}

/deep/ .register-card-dialog .el-dialog__body {
  padding: 15px;
  background: #ffffff;
}

/deep/ .register-card-dialog .el-dialog__footer {
  padding: 0;
  border-top: none;
}

// 响应式设计 - 适配竖屏（严格遵循收银系统开发规则）
@media (orientation: portrait) {
  /deep/ .register-card-dialog .el-dialog {
    width: 95% !important;
    max-width: 95% !important;
    margin-top: 1vh !important;
    max-height: 92vh !important;
  }
  
  .form-input-mode {
    flex-direction: column;
    gap: 15px;
    
    .form-section {
      flex: none;
    }
    
    .form-keyboard {
      flex: none;
      
      .keyboard-grid .key-row .key {
        width: 42px;
        height: 36px;
        font-size: 14px;
      }
    }
  }
  
  .phone-input-mode .number-keyboard {
    max-width: 280px;
    
    .keyboard-grid .key-row .key {
      height: 40px;
      font-size: 16px;
    }
  }
}

// 响应式设计 - 适配小屏幕
@media (max-width: 900px) {
  /deep/ .register-card-dialog .el-dialog {
    width: 95% !important;
    max-width: 95% !important;
  }
  
  .number-keyboard {
    max-width: 260px !important;
    
    .keyboard-grid .key-row .key {
      height: 38px;
      font-size: 15px;
    }
  }
}

// 全局日期选择器弹出面板样式优化
/deep/ .el-picker-panel {
  background: #ffffff !important;
  border: 1px solid #e4e7ed !important;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1) !important;
}

/deep/ .el-date-picker {
  .el-picker-panel__body {
    .el-date-table {
      td {
        &.available {
          .cell {
            color: #606266 !important;
            background: transparent !important;
            
            &:hover {
              color: #409eff !important;
              background: #e6f7ff !important;
            }
          }
        }
        
        &.today {
          .cell {
            color: #409eff !important;
            font-weight: 600 !important;
          }
        }
        
        &.current {
          .cell {
            background: #409eff !important;
            color: #ffffff !important;
            
            &:hover {
              background: #337ecc !important;
              color: #ffffff !important;
            }
          }
        }
      }
    }
  }
  
  .el-picker-panel__header {
    background: #fafafa !important;
    border-bottom: 1px solid #e4e7ed !important;
    
    .el-picker-panel__icon-btn {
      color: #303133 !important;
      
      &:hover {
        color: #409eff !important;
      }
    }
    
    .el-date-picker__header-label {
      color: #303133 !important;
      
      &:hover {
        color: #409eff !important;
      }
    }
  }
}
</style> 