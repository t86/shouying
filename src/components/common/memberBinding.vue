<template>
  <div class="member-binding" :class="`theme-${theme}`">
    <!-- 绑定会员享优惠和积分 -->
    <div class="member-binding-header">
      <div class="divider"></div>
      <div class="header-text">绑定会员享优惠和积分</div>
      <div class="divider"></div>
    </div>

    <!-- 选择会员 -->
    <div class="member-selection">
      <div class="section-title">选择会员:</div>
      <div class="member-list" v-if="memberList.length > 0">
        <div
          class="member-item"
          v-for="(item, index) in displayMemberList"
          :key="index"
          @click="selectMember(item)"
        >
          {{ item.n || item.name || '' }} {{ item.p || item.phone || '' }}
        </div>
        <div
          class="member-item view-more"
          v-if="memberList.length > 1"
          @click="showMoreMembers = !showMoreMembers"
        >
          {{ showMoreMembers ? '收起' : '查看更多' }}
        </div>
      </div>
    </div>

    <!-- 自定义输入 -->
    <div class="custom-input-section">
      <div class="section-title">自定义:</div>
      <div class="input-wrapper" layout="row" layout-align="start center">
        <input
          ref="phoneInput"
          v-model="customPhone"
          class="phone-input"
          placeholder="输入会员手机号"
          maxlength="11"
          @focus="handlePhoneFocus"
          @blur="handlePhoneBlur"
        />
        <el-button
          type="primary"
          size="small"
          class="search-btn"
          @click="searchMember"
          :loading="searching"
        >
          搜索
        </el-button>
        <el-button
          type="danger"
          size="small"
          class="cancel-bind-btn"
          @click="cancelBinding"
          :disabled="!selectedMemberInfo"
        >
          取消绑定
        </el-button>
      </div>
      <!-- 错误提示 -->
      <div class="error-message" v-if="errorMessage">
        {{ errorMessage }}
      </div>
      <!-- 会员信息显示 -->
      <div class="member-info" v-if="selectedMemberInfo">
        <div class="info-item">
          <span>姓名:</span>
          <span>{{ selectedMemberInfo.name || selectedMemberInfo.n || '' }}</span>
        </div>
        <div class="info-item">
          <span>手机号:</span>
          <span>{{ selectedMemberInfo.phone || selectedMemberInfo.p || '' }}</span>
          <el-button
            type="text"
            size="small"
            class="change-btn"
            @click="changeBinding"
          >
            更改绑定
          </el-button>
        </div>
      </div>
    </div>

    <!-- 数字键盘（点单机和平板） -->
    <div 
      class="keyboard-wrapper" 
      v-if="showKeyboard && (isOrderMachine || isTablet)"
      @mousedown.prevent.stop
      @touchstart.prevent.stop
      @click.stop
    >
      <keyBoard @changeNum="handleKeyboardInput" />
    </div>
  </div>
</template>

<script>
import api_order from "@/api/order";
import api_money from "@/api/money";
import keyBoard from "@/components/common/keyBoard";
import eventVue from "@/utils/eventVue";
import { setCsmCustWithPolling } from "@/utils/csmCustPolling";

export default {
  name: "MemberBinding",
  components: {
    keyBoard,
  },
  props: {
    seatId: {
      type: Number,
      required: true,
    },
    // 主题：浅色/深色，默认浅色以适配白底页面
    theme: {
      type: String,
      default: "light",
      validator: (value) => ["dark", "light"].includes(value),
    },
  },
  data() {
    return {
      memberList: [], // 当前卡台的会员列表
      showMoreMembers: false, // 是否显示更多会员
      customPhone: "", // 自定义输入的手机号
      searching: false, // 搜索中状态
      errorMessage: "", // 错误提示信息
      selectedMemberInfo: null, // 选中的会员信息
      showKeyboard: false, // 是否显示键盘
      isOrderMachine: false, // 是否是点单机
      isTablet: false, // 是否是平板
      allowBlur: false, // 是否允许失去焦点
    };
  },
  computed: {
    // 显示的会员列表（默认显示第一个，查看更多时显示全部）
    displayMemberList() {
      if (this.showMoreMembers || this.memberList.length <= 1) {
        return this.memberList;
      }
      return [this.memberList[0]];
    },
  },
  mounted() {
    this.init();
    this.detectDeviceType();
    // 如果是点单机或平板，默认显示键盘
    this.$nextTick(() => {
      if (this.isOrderMachine || this.isTablet) {
        this.showKeyboard = true;
      }
    });
  },
  methods: {
    init() {
      // 加载当前卡台的会员信息
      this.loadCurrentCardMember();
    },

    // 检测设备类型
    detectDeviceType() {
      const client = sessionStorage.getItem('client') || '';
      const userAgent = navigator.userAgent.toLowerCase();
      
      // 判断是否是点单机或平板
      this.isOrderMachine = client === 'order' || userAgent.includes('pad') || userAgent.includes('tablet');
      this.isTablet = userAgent.includes('pad') || userAgent.includes('tablet') || window.innerWidth <= 1024;
    },

    // 加载当前卡台的会员信息
    async loadCurrentCardMember() {
      try {
        const businessData = this.$store.state.cardPageInfo.resResultDataObj.businessData || [];
        const currentBusiness = businessData.find(
          (ite) => ite.seatId * 1 == this.seatId * 1
        );

        if (currentBusiness && currentBusiness.csm_cust_phone) {
          // 如果当前卡台已绑定会员，添加到会员列表
          this.memberList = [
            {
              p: currentBusiness.csm_cust_phone,
              n: currentBusiness.csm_cust_name || this.maskPhone(currentBusiness.csm_cust_phone),
            },
          ];
          this.selectedMemberInfo = {
            phone: currentBusiness.csm_cust_phone,
            name: currentBusiness.csm_cust_name || this.maskPhone(currentBusiness.csm_cust_phone),
          };
        }

        // 加载历史手机号
        try {
          const res = await api_order.get_csm_phone_nums({
            id: this.seatId * 1,
          });

          if (res.code === 1 && res.data && res.data.records) {
            const historyPhones = res.data.records || [];
            // 合并历史手机号到会员列表（去重）
            historyPhones.forEach((phone) => {
              if (!this.memberList.find((item) => item.p === phone)) {
                this.memberList.push({
                  p: phone,
                  n: this.maskPhone(phone),
                });
              }
            });
          }
        } catch (error) {
          console.error("加载历史手机号失败:", error);
        }
      } catch (error) {
        console.error("加载当前卡台会员信息失败:", error);
      }
    },

    // 手机号脱敏
    maskPhone(phone) {
      if (!phone || phone.length !== 11) return phone;
      return phone.substring(0, 3) + "****" + phone.substring(7);
    },

    // 选择会员
    async selectMember(member) {
      if (!member || !member.p) return;

      this.customPhone = member.p;
      this.errorMessage = "";
      this.selectedMemberInfo = null;

      // 查询会员详细信息
      await this.searchMemberByPhone(member.p);
    },

    // 搜索会员
    async searchMember() {
      // 允许失去焦点，因为要执行搜索操作
      this.allowBlur = true;
      
      if (!this.customPhone || this.customPhone.length !== 11) {
        this.$message.warning("请输入正确的11位手机号");
        this.allowBlur = false;
        this.$nextTick(() => {
          if (this.$refs.phoneInput) {
            this.$refs.phoneInput.focus();
          }
        });
        return;
      }

      this.errorMessage = "";
      this.selectedMemberInfo = null;
      await this.searchMemberByPhone(this.customPhone);
      
      // 搜索完成后，如果失败则重新允许焦点
      if (!this.selectedMemberInfo) {
        this.allowBlur = false;
        this.$nextTick(() => {
          if (this.$refs.phoneInput) {
            this.$refs.phoneInput.focus();
          }
        });
      }
    },

    // 根据手机号搜索会员
    async searchMemberByPhone(phone) {
      this.searching = true;
      try {
        // 先查询是否是会员
        const res = await api_order.get_cust_items_for_csm({
          cust_phone: phone,
        });

        if (res.code === 1 && res.data && res.data.records && res.data.records.length > 0) {
          // 是会员，显示会员信息并绑定
          const memberData = res.data.records[0];
          this.selectedMemberInfo = {
            phone: phone,
            name: memberData.n || memberData.name || this.maskPhone(phone),
          };

          // 自动绑定会员
          await this.bindMember(phone);

          // 搜索有结果时隐藏键盘
          if (this.isOrderMachine || this.isTablet) {
            this.showKeyboard = false;
            // 通知父组件，memberBinding的键盘已隐藏
            this.$emit('keyboard-active', false);
          }

          // 通知父组件价格需要重新计算
          this.$emit("member-bound", {
            phone: phone,
            name: this.selectedMemberInfo.name,
          });
        } else {
          // 不是会员
          this.errorMessage = "当前手机号未注册会员,不能享受会员价格!";
          this.selectedMemberInfo = null;
          // 搜索无结果时保持键盘显示
        }
      } catch (error) {
        console.error("搜索会员失败:", error);
        this.$message.error("搜索会员失败");
        // 搜索失败时保持键盘显示
      } finally {
        this.searching = false;
      }
    },

    // 绑定会员
    async bindMember(phone) {
      // 创建loading实例
      const loading = this.$loading({
        lock: true,
        text: '正在设置结账客人...',
        spinner: 'el-icon-loading',
        background: 'rgba(0, 0, 0, 0.7)'
      });

      try {
        // 使用轮询工具函数
        const result = await setCsmCustWithPolling(
          phone,
          this.seatId * 1,
          loading,
          () => {
            // 用户取消操作的回调
            this.$message.info('已取消设置');
          }
        );

        if (result.success) {
          this.$message.success(result.message || '绑定成功');
          // 更新会员列表
          if (!this.memberList.find((item) => item.p === phone)) {
            this.memberList.unshift({
              p: phone,
              n: this.selectedMemberInfo.name,
            });
          }
          // 触发元数据刷新（通过事件总线）
          if (this.$store && this.$store.dispatch) {
            // 等待一下让后端更新完成
            setTimeout(() => {
              // 触发重新加载业务数据
              eventVue.$emit("reloadBusinessData");
            }, 500);
          }
        } else {
          // 如果是用户取消，不显示错误消息
          if (!result.canceled) {
            this.$message.warning(result.message || '绑定失败');
          }
        }
      } catch (error) {
        console.error("绑定会员失败:", error);
        this.$message.error("绑定会员失败");
      } finally {
        // 确保loading被关闭
        if (loading) {
          loading.close();
        }
      }
    },

    // 更改绑定
    changeBinding() {
      this.selectedMemberInfo = null;
      this.customPhone = "";
      this.errorMessage = "";
      this.allowBlur = false;
      // 更改绑定时重新显示键盘
      if (this.isOrderMachine || this.isTablet) {
        this.$nextTick(() => {
          this.showKeyboard = true;
          if (this.$refs.phoneInput) {
            this.$refs.phoneInput.focus();
          }
        });
      }
    },

    // 取消绑定
    async cancelBinding() {
      if (!this.selectedMemberInfo) {
        return;
      }

      // 创建loading实例
      const loading = this.$loading({
        lock: true,
        text: '正在取消绑定...',
        spinner: 'el-icon-loading',
        background: 'rgba(0, 0, 0, 0.7)'
      });

      try {
        // 使用轮询工具函数取消绑定（传空字符串）
        const result = await setCsmCustWithPolling(
          "",
          this.seatId * 1,
          loading,
          () => {
            // 用户取消操作的回调
            this.$message.info('已取消操作');
          }
        );

        if (result.success) {
          this.$message.success(result.message || '取消绑定成功');
          // 清空选中会员信息
          this.selectedMemberInfo = null;
          this.customPhone = "";
          this.errorMessage = "";
          this.allowBlur = false;

          // 触发元数据刷新（通过事件总线）
          if (this.$store && this.$store.dispatch) {
            setTimeout(() => {
              eventVue.$emit("reloadBusinessData");
            }, 500);
          }

          // 通知父组件价格需要重新计算
          this.$emit("member-bound", {
            phone: "",
            name: "",
          });

          // 取消绑定时重新显示键盘
          if (this.isOrderMachine || this.isTablet) {
            this.$nextTick(() => {
              this.showKeyboard = true;
              if (this.$refs.phoneInput) {
                this.$refs.phoneInput.focus();
              }
            });
          }
        } else {
          // 如果是用户取消，不显示错误消息
          if (!result.canceled) {
            this.$message.warning(result.message || '取消绑定失败');
          }
        }
      } catch (error) {
        console.error("取消绑定失败:", error);
        this.$message.error("取消绑定失败");
      } finally {
        // 确保loading被关闭
        if (loading) {
          loading.close();
        }
      }
    },

    // 手机号输入框获得焦点
    handlePhoneFocus() {
      this.allowBlur = false;
      if (this.isOrderMachine || this.isTablet) {
        this.showKeyboard = true;
        // 通知父组件，memberBinding的键盘正在使用
        this.$emit('keyboard-active', true);
      }
      // 确保输入框保持焦点
      this.$nextTick(() => {
        if (this.$refs.phoneInput) {
          this.$refs.phoneInput.focus();
        }
      });
    },

    // 手机号输入框失去焦点
    handlePhoneBlur() {
      // 如果允许失去焦点（比如点击搜索按钮），则隐藏键盘并通知父组件
      if (this.allowBlur) {
        if (this.isOrderMachine || this.isTablet) {
          this.showKeyboard = false;
          // 通知父组件，memberBinding的键盘已隐藏
          this.$emit('keyboard-active', false);
        }
        return;
      }
      // 否则，延迟重新获得焦点，确保虚拟键盘输入时不会失去焦点
      // 使用较短的延迟，确保用户体验流畅
      setTimeout(() => {
        if (this.$refs.phoneInput && (this.isOrderMachine || this.isTablet) && !this.allowBlur) {
          this.$refs.phoneInput.focus();
        }
      }, 50);
    },

    // 键盘输入处理
    handleKeyboardInput(value) {
      // 确保输入框保持焦点，并且当前焦点在手机号输入框
      if (!this.$refs.phoneInput || document.activeElement !== this.$refs.phoneInput) {
        // 如果焦点不在手机号输入框，重新获得焦点
        this.$nextTick(() => {
          if (this.$refs.phoneInput) {
            this.$refs.phoneInput.focus();
          }
        });
      }

      // 处理键盘输入
      if (value === 11) {
        // 删除
        this.customPhone = this.customPhone.slice(0, -1);
      } else if (value === 12) {
        // 清空
        this.customPhone = "";
      } else {
        // 数字输入
        if (this.customPhone.length < 11) {
          this.customPhone += value;
        }
      }
      
      // 通知父组件，memberBinding的键盘正在使用，避免全局键盘干扰
      this.$emit('keyboard-active', true);
    },
  },
};
</script>

<style lang="less" scoped>
.member-binding {
  padding: 10px 15px 18px;
  background: transparent;
  border-radius: 6px;
  margin-bottom: 8px;

  // 深色主题（收银端）
  &.theme-dark {
    .member-binding-header {
      .divider { background: rgba(255, 255, 255, 0.2); }
      .header-text { color: rgba(255, 255, 255, 0.8); }
    }
    .member-selection {
      .section-title { color: rgba(255, 255, 255, 0.8); }
      .member-item {
        background: rgba(255, 255, 255, 0.1);
        color: rgba(255, 255, 255, 0.9);
        border: 1px solid rgba(255, 255, 255, 0.15);
        &:hover {
          background: rgba(255, 255, 255, 0.2);
          border-color: rgba(255, 255, 255, 0.3);
        }
      }
    }
    .custom-input-section {
      .section-title { color: rgba(255, 255, 255, 0.8); }
      .phone-input {
        border: 1px solid rgba(255, 255, 255, 0.4);
        background: rgba(255, 255, 255, 0.2);
        color: #ffffff;
        &::placeholder { color: rgba(255, 255, 255, 0.6); }
        &:focus { background: rgba(255, 255, 255, 0.25); }
      }
      .member-info {
        background: rgba(255, 255, 255, 0.08);
        border: 1px solid rgba(255, 255, 255, 0.1);
        .info-item {
          span:first-child { color: rgba(255, 255, 255, 0.7); }
          span:nth-child(2) { color: rgba(255, 255, 255, 0.9); }
        }
      }
    }
  }

  // 浅色主题（点单端默认）
  &.theme-light {
    .member-binding-header {
      .divider { background: rgba(0, 0, 0, 0.12); }
      .header-text { color: rgba(0, 0, 0, 0.85); }
    }
    .member-selection {
      .section-title { color: rgba(0, 0, 0, 0.85); }
      .member-item {
        background: rgba(0, 0, 0, 0.05);
        color: rgba(0, 0, 0, 0.85);
        border: 1px solid rgba(0, 0, 0, 0.15);
        &:hover {
          background: rgba(0, 0, 0, 0.1);
          border-color: rgba(0, 0, 0, 0.25);
        }
      }
    }
    .custom-input-section {
      .section-title { color: rgba(0, 0, 0, 0.85); }
      .phone-input {
        border: 1px solid rgba(0, 0, 0, 0.2);
        background: #fff;
        color: #1a1a1a;
        &::placeholder { color: rgba(0, 0, 0, 0.5); }
        &:focus { background: #fff; border-color: #409eff; }
      }
      .member-info {
        background: rgba(0, 0, 0, 0.03);
        border: 1px solid rgba(0, 0, 0, 0.1);
        .info-item {
          span:first-child { color: rgba(0, 0, 0, 0.65); }
          span:nth-child(2) { color: rgba(0, 0, 0, 0.85); }
        }
      }
    }
  }

  .member-binding-header {
    display: flex;
    align-items: center;
    margin-bottom: 10px;
    .divider { flex: 1; height: 1px; }
    .header-text { padding: 0 12px; font-size: 13px; }
  }

  .member-selection {
    margin-bottom: 10px;
    .section-title { font-size: 13px; margin-bottom: 8px; }
    .member-list {
      display: flex; flex-wrap: wrap; gap: 8px;
      .member-item {
        padding: 6px 12px;
        border-radius: 6px;
        font-size: 13px;
        cursor: pointer;
        transition: all 0.2s;
        &.view-more {
          color: #409eff;
          background: transparent;
          border: 1px solid #409eff;
        }
      }
    }
  }

  .custom-input-section {
    .section-title { font-size: 13px; margin-bottom: 8px; }
    .input-wrapper {
      margin-bottom: 8px;
      .phone-input {
        flex: 1;
        height: 40px;
        padding: 0 12px;
        border-radius: 6px;
        font-size: 14px;
        margin-right: 10px;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        &:focus { outline: none; box-shadow: 0 0 0 2px rgba(64, 158, 255, 0.2); }
      }
      .search-btn { height: 40px; padding: 0 18px; font-size: 14px; margin-right: 10px; }
      .cancel-bind-btn { height: 40px; padding: 0 18px; font-size: 14px; }
    }
    .error-message { color: #f56c6c; font-size: 12px; margin-top: 4px; padding: 4px 0; }
    .member-info {
      margin-top: 10px;
      padding: 12px;
      border-radius: 6px;
      .info-item {
        display: flex;
        align-items: center;
        margin-bottom: 8px;
        font-size: 13px;
        span:first-child { width: 80px; }
        span:nth-child(2) { flex: 1; }
        .change-btn { margin-left: 10px; color: #409eff; }
        &:last-child { margin-bottom: 0; }
      }
    }
  }

  .keyboard-wrapper {
    margin-top: 10px;
    position: relative;
    z-index: 10;
    ::v-deep .keyboard { position: relative; z-index: 10; }
    ::v-deep .item { position: relative; z-index: 10; }
  }
}

@media (orientation: portrait) {
  .member-binding {
    padding: 8px 12px 14px;
    margin-bottom: 6px;
    .member-binding-header {
      margin-bottom: 8px;
      .header-text { padding: 0 10px; font-size: 12px; }
    }
    .member-selection {
      margin-bottom: 8px;
      .section-title { margin-bottom: 6px; font-size: 12px; }
      .member-list {
        gap: 6px;
        .member-item { padding: 5px 10px; font-size: 12px; }
      }
    }
    .custom-input-section {
      .section-title { margin-bottom: 6px; font-size: 12px; }
      .input-wrapper {
        margin-bottom: 6px;
        .phone-input { height: 38px; font-size: 13px; padding: 0 10px; }
        .search-btn { height: 38px; padding: 0 15px; font-size: 13px; margin-right: 8px; }
        .cancel-bind-btn { height: 38px; padding: 0 15px; font-size: 13px; }
      }
      .member-info {
        margin-top: 8px;
        padding: 10px;
        .info-item { margin-bottom: 6px; font-size: 12px; }
      }
    }
    .keyboard-wrapper { margin-top: 8px; }
  }
}
</style>

