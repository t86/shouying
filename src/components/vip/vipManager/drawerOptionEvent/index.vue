<template>
  <div>
    <!-- 表格中option 相关 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5">
        <!-- 编辑会员卡信息 -->
        <updateVipInfo
          v-if="optionObj.optionInfo.id == 1"
          ref="updateVipInfoRef"
          :currentItemInfo="currentItemInfo"
          @updateInfoHandle="updateInfoHandle"
        />
        <!-- 制卡 -->
        <makeCard
          v-if="optionObj.optionInfo.id == 2"
          ref="makeCardRef"
          :currentItemInfo="currentItemInfo"
        />
        <!-- 更改会员卡等级 -->
        <updateVipDeep
          v-if="optionObj.optionInfo.id == 3"
          ref="updateVipDeepRef"
          :currentItemInfo="currentItemInfo"
          @updateInfoHandle="updateInfoHandle"
        />
        <!-- 更改/绑定会员手机号 -->
        <updateVipPhoneNum
          v-if="optionObj.optionInfo.id == 4"
          ref="updateVipPhoneNumRef"
          :currentItemInfo="currentItemInfo"
          @updateInfoHandle="updateInfoHandle"
        />
        <!-- 挂失/解除挂失 -->
        <enableVip
          v-if="optionObj.optionInfo.id == 5"
          ref="enAbledRef"
          :currentItemInfo="currentItemInfo"
          @updateInfoHandle="updateInfoHandle"
        />
        <!-- 换卡 -->
        <changeCard
          v-if="optionObj.optionInfo.id == 6"
          ref="changeCardRef"
          :currentItemInfo="currentItemInfo"
          @updateInfoHandle="updateInfoHandle"
        />
        <!-- 退卡 -->
        <backVipCard
          v-if="optionObj.optionInfo.id == 7"
          ref="backCardRef"
          :currentItemInfo="currentItemInfo"
          @updateInfoHandle="updateInfoHandle"
        />
        <!-- 扣款 -->
        <subMoneyFromVipCard
          v-if="optionObj.optionInfo.id == 8"
          ref="subMoneyRef"
          :currentItemInfo="currentItemInfo"
          @updateInfoHandle="updateInfoHandle"
        />
    
        <!-- 注销 -->
        <destroyVipCard
          v-if="optionObj.optionInfo.id == 9"
          ref="destroyRef"
          :currentItemInfo="currentItemInfo"
          @updateInfoHandle="updateInfoHandle"
        />
        <!-- 扣除积分 -->
        <deductionPoint
          v-if="optionObj.optionInfo.id == 10"
          ref="deductionPointRef"
          :currentItemInfo="currentItemInfo"
          @updateInfoHandle="updateInfoHandle"
        />
        <!-- 修改会员卡信息提示框 -->
        <div class="modal" v-if="confirmEditVipInfo">
          <div class="modal-content">
            <h3 class="m-b-6">提示</h3>
            <p class="m-b-6">
              同一个手机号绑定的其他会员卡，这些信息也会同步更改<br />是否确认修改？
            </p>
            <div class="btn-area">
              <el-button size="mini" type="" @click="confirmEditVipInfo = false"
                >取消</el-button
              >
              <el-button
                size="mini"
                type="primary"
                @click="submitEditVipInfoHandle"
                >确认</el-button
              >
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer($event, false)"
          >关闭</el-button
        >
        <el-button
          type="primary"
          v-if="
            this.optionObj.optionInfo.id != 2 &&
            this.optionObj.optionInfo.id != 6
          "
          @click="onSubmit"
          >确定</el-button
        >
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_vip from "@/api/vip";
import updateVipInfo from "./updateVipInfo.vue";
import makeCard from "./makeCard.vue";
import updateVipDeep from "./updateVipDeep.vue";
import updateVipPhoneNum from "./updateVipPhoneNum.vue";
import enableVip from "./enableVip.vue";
import changeCard from "./changeCard.vue";
import backVipCard from "./backVipCard.vue";

import subMoneyFromVipCard from "./subMoneyFromVipCard.vue";
import deductionPoint from "./deductionPoint.vue";
import destroyVipCard from "./destroyVipCard.vue";

export default {
  data() {
    return {
      show: false,
      confirmEditVipInfo: false, // 是否修改会员卡信息确认框的显示或隐藏
      currentItemInfo: {},
      updateVipInfoObj: {}, // 编辑会员卡信息
      makeCardInfoObj: {}, // 制卡
      updateVipDeepInfoObj: {}, // 更改会员卡等级
      updateVipPhoneNumObj: {}, // 更改、绑定手机号
      enableVipInfoObj: {}, // 挂失、解除挂失
      changeVipCardInfoObj: {}, // 换卡
      backVipCardInfoObj: {}, // 退卡
      subMoneyVipCardInfoObj: {}, // 扣款
      deleteVipCardInfoObj: {}, // 注销
      deductionPointInfoObj:{}, // 扣除积分
    };
  },
  methods: {
    resetHandle() {
      this.updateVipInfoObj = {};
      this.makeCardInfoObj = {};
      this.updateVipDeepInfoObj = {};
      this.updateVipPhoneNumObj = {};
      this.enableVipInfoObj = {};
      this.changeVipCardInfoObj = {};
      this.backVipCardInfoObj = {};
      this.subMoneyVipCardInfoObj = {};
      this.deleteVipCardInfoOb = {};
      this.deductionPointInfoObj = {};
    },

    updateInfoHandle(info) {
      this[this.optionObj.optionInfo.objName] = JSON.parse(
        JSON.stringify(info)
      );
    },

    /*
      制卡、换卡
    */
    // 读取卡号
    readCard() {
      let cardNo = "";
      try {
        setTimeout(() => {
          cardNo = atool.getCardNo();
          if (!cardNo) {
            if (
              this.show &&
              (this.optionObj.optionInfo.id == 2 ||
                this.optionObj.optionInfo.id == 6)
            )
              this.readCard();
          } else {
            // 制卡、换卡
            this.getBeginCardInfo(cardNo);
          }
        }, 1000);
      } catch (error) {
        console.log("cardNo信息获取失败：", error);
      }
    },
    // 开始制卡、换卡
    async getBeginCardInfo(cardNo) {
      const params = {
        card_no: cardNo, //  string  卡号,这里是物理卡的卡号
        mb_card_id: this.currentItemInfo.id * 1, //  int64    虚拟卡Id
      };
      try {
        const res =
          this.optionObj.optionInfo.id == 2
            ? await api_vip.reqMakeVipCardBegin(params)
            : await api_vip.reqChangeVipCardBegin(params);
        if (res.code == 1) {
          try {
            const result = atool.doRegCard(
              res.data.card_pass,
              res.data.card_verify_data
            );
            if (result === "0") {
              this.makeCardEnd(cardNo);
            } else {
              this.readCard();
              this.$message.warning(
                this.optionObj.optionInfo.id == 2
                  ? "制卡失败，即将重新制卡"
                  : "换卡失败，即将重新换卡"
              );
            }
          } catch (e) {
            console.log(
              this.optionObj.optionInfo.id == 2 ? "制卡失败" : "换卡失败",
              e
            );
          }
        } else {
          this.readCard();
          this.$message.warning(res.msg + "，即将重新制卡");
        }
      } catch (error) {
        console.log("制卡begin失败", error);
      }
    },

    // 结束制卡、换卡
    async makeCardEnd(cardNo) {
      const params = {
        card_no: cardNo, //    string  卡号
        mb_card_id: this.currentItemInfo.id * 1, //  int64    虚拟卡Id
      };
      try {
        const res =
          this.optionObj.optionInfo.id == 2
            ? await api_vip.reqMakeVipCardEnd(params)
            : await api_vip.reqChangeVipCardEnd(params);
        if (res.code == 1) {
          this.$message.success(
            this.optionObj.optionInfo.id == 2 ? "制卡成功" : "换卡成功"
          );
          this.onCancelDrawer("", true);
        } else {
          this.readCard();
          this.$message.warning(res.msg + "，即将重新制卡");
        }
      } catch (error) {
        console.log("制卡结束失败", error);
      }
    },

    async submitEditVipInfoHandle() {
      const params = {
        id: this.currentItemInfo.id * 1, //   int64   会员卡Id
        contact_phone: this.updateVipInfoObj.connectPhoneNum, // string  联系手机号
        name: this.updateVipInfoObj.userName, //       string     //Name 姓名
        sex: this.updateVipInfoObj.sexVal * 1, //        int        //Sex 性别 1, 2
        birthday: this.updateVipInfoObj.birthdayVal, //   string     //BirthDay 生日 yyyy-mm-dd
        mark: this.updateVipInfoObj.markVal, //       string     //Mark 标签
        expired_type: this.updateVipInfoObj.timeLongVal * 1, // int        //ExpiredType 过期类型
        sms_type_ids: this.updateVipInfoObj.messageList
          .filter((item) => item.checked)
          .map((item) => item.id * 1), // []int        //SmsTypeIds 订阅消息列表
        sales_emp_id: this.updateVipInfoObj.personVal * 1, //
      };
      try {
        const res = await api_vip.reqUpdateVipCard(params);
        if (res.code == 1) {
          this.confirmEditVipInfo = false;
          this.$message.success("编辑成功");
          this.onCancelDrawer();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("编辑会员信息失败", error);
      }
    },

    /**
     * 其它
     */
    // 提交
    async onSubmit() {
      let params = {};
      switch (this.optionObj.optionInfo.id * 1) {
        case 1:
          // 编辑会员信息
          this.confirmEditVipInfo =
            this[this.optionObj.optionInfo.objName].show;
          if (!this.confirmEditVipInfo) {
            this.submitEditVipInfoHandle();
          }
          break;
        case 3:
          // 更改会员等级
          params = {
            id: this.currentItemInfo.id * 1, //   int64   会员卡Id
            card_level_id: this.updateVipDeepInfoObj.vipDeepVal * 1, // int64  卡等级
          };
          try {
            const res = await api_vip.reqUpdateVipCardDeep(params);
            if (res.code == 1) {
              this.$message.success("更改成功");
              this.onCancelDrawer();
            } else {
              this.$message.warning(res.msg);
            }
          } catch (error) {
            console.log("更改会员等级失败", error);
          }
          break;
        case 4:
          // 更改/绑定手机号
          params = {
            m: this.updateVipPhoneNumObj.phoneNum, //   string    手机号
            c: this.updateVipPhoneNumObj.validateVal, //    string   验证码
          };

          if (params.c.length != 5) {
            this.$message.warning("请输入正确的五位验证码");
            return false;
          }
          try {
            const res = await api_vip.reqValidatePhoneMsg(params);
            if (res.code == 1) {
              this.submitUpdatePhoneNumHandle(res.data.c);
            } else {
              this.$message.warning(res.msg);
            }
          } catch (error) {
            console.log("验证手机验证码失败", error);
          }

          break;
        case 5:
          // 挂失/解除挂失
          params = {
            id: this.currentItemInfo.id * 1, //   int64   会员卡Id
          };
          try {
            const res =
              this.currentItemInfo.rs == 1
                ? await api_vip.reqAbleVipCard(params)
                : await api_vip.reqEnableVipCard(params);
            if (res.code == 1) {
              this.$message.success(
                `${this.currentItemInfo.rs == 1 ? "挂失" : "解除挂失"}成功`
              );
              this.onCancelDrawer();
            } else {
              this.$message.warning(res.msg);
            }
          } catch (error) {
            console.log(
              `${this.currentItemInfo.rs == 1 ? "挂失" : "解除挂失"}会员卡失败`,
              error
            );
          }

          break;
        case 7:
          // 退卡
          params = {
            mb_card_id: this.currentItemInfo.id * 1, //   int64   会员卡Id
            remark: this.backVipCardInfoObj.reason, //   string     //Remark 退卡原因
          };

          if (!params.remark) return this.$message.warning("请输入退卡理由");
          try {
            const res = await api_vip.reqBackVipCard(params);
            if (res.code == 1) {
              this.$message.success("退卡成功");
              this.onCancelDrawer();
            } else {
              this.$message.warning(res.msg);
            }
          } catch (error) {
            console.log("退卡失败", error);
          }

          break;

        case 8:
          // 扣款
          params = {
            id: this.currentItemInfo.id * 1, //   int64   会员卡Id
            val_amt: this.subMoneyVipCardInfoObj.addAmt, //    string  有价金额(最多支持两位小数)
            free_amt: this.subMoneyVipCardInfoObj.zSAmt || "0", //   string   赠送金额(最多支持两位小数)
            pt_amt: this.subMoneyVipCardInfoObj.point * 1, //    int 赠送/扣除积分
            pt_bal: this.$store.state.userInfo.emp_id * 1, // int64    操作员工
            type_id: this.subMoneyVipCardInfoObj.subType * 1, //    int   操作类型, 1业务扣款 2充错扣款
          };

          if (params.val_amt.length <= 0)
            return this.$message.warning("请输入储值金额");
          try {
            const res = await api_vip.reqSubMoneyFromCard(params);
            if (res.code == 1) {
              this.$message.success("扣款成功");
              this.onCancelDrawer();
            } else {
              this.$message.warning(res.msg);
            }
          } catch (error) {
            console.log("扣款失败", error);
          }

          break;
        case 9:
          // 注销
          params = {
            mb_card_id: this.currentItemInfo.id * 1, // int64   虚拟卡Id
            val_balance: this.deleteVipCardInfoObj.val_bal, // string  储值余额, 做二次认证用
            free_balance: this.deleteVipCardInfoObj.free_bal, // string   赠送余额, 做二次认证用
          };

          try {
            const res = await api_vip.reqDestroyVipCard(params);
            if (res.code == 1) {
              this.$message.success("注销成功");
              this.onCancelDrawer();
            } else {
              this.$message.warning(res.msg);
            }
          } catch (error) {
            console.log("注销失败", error);
          }

          break;

        case 10:
          // 扣除积分
          
          params = {
            id: this.currentItemInfo.id * 1, // int64   虚拟卡Id
            oper_emp_id: this.$store.state.userInfo.emp_id * 1, // int64    操作员工
            pt_amt:this.deductionPointInfoObj.point * 1, // 积分
            remark:this.deductionPointInfoObj.remark  //Remark 扣款备注
          };
          try {
            const res = await api_vip.reqSubPointFromCard(params);
            if (res.code == 1) {
              this.$message.success("扣除成功");
              this.onCancelDrawer();
            } else {
              this.$message.warning(res.msg);
            }
          } catch (error) {
            console.log("扣除失败", error);
          }

          break;
      }
    },
    // 提交更改/绑定手机号
    async submitUpdatePhoneNumHandle(phoneValidateStr) {
      if (this.currentItemInfo.bp) {
        // 更改手机号
        const params = {
          id: this.currentItemInfo.id * 1, //   int64   会员卡Id
          bind_phone_auth_code: phoneValidateStr, // string  认证手机授权码
          bind_phone: this.updateVipPhoneNumObj.phoneNum, // string   认证手机
        };
        try {
          const res = await api_vip.reqUpdateVipCardBindPhoneNum(params);
          if (res.code == 1) {
            this.$message.success("更改成功");
            this.onCancelDrawer();
          } else {
            this.$message.warning(res.msg);
          }
        } catch (error) {
          console.log("更改手机号失败", error);
        }
      } else {
        // 绑定手机号
        const params = {
          id: this.currentItemInfo.id * 1, //   int64   会员卡Id
          bind_phone_auth_code: phoneValidateStr, // string  认证手机授权码
          bind_phone: this.updateVipPhoneNumObj.phoneNum, // string     //BindPhone 认证手机
          sms_type_ids: this.updateVipPhoneNumObj.messageList
            .filter((item) => item.checked)
            .map((item) => item.id * 1), //  []int   订阅消息列表
        };
        try {
          const res = await api_vip.reqBindVipCardPhoneNum(params);
          if (res.code == 1) {
            this.$message.success("绑定成功");
            this.onCancelDrawer();
          } else {
            this.$message.warning(res.msg);
          }
        } catch (error) {
          console.log("绑定手机号失败", error);
        }
      }
    },
    onCancelDrawer() {
      this.$emit("showOrHideDrawer");
    },
  },
  mounted() {},
  props: {
    showDrawer: {
      default: false, // 是否显示drawer
    },
    optionObj: {
      default: {
        optionInfo: {},
        currentInfo: {},
      },
    },
  },
  computed: {
    title() {
      return this.optionObj.optionInfo ? this.optionObj.optionInfo.name : "";
    },
  },
  components: {
    updateVipInfo,
    makeCard,
    updateVipDeep,
    updateVipPhoneNum,
    enableVip,
    changeCard,
    backVipCard,
    subMoneyFromVipCard,
    deductionPoint,
    destroyVipCard,
  },
  watch: {
    showDrawer: {
      handler(newVal) {
        this.show = newVal;
        if (newVal) {
          this.resetHandle();
          this.$nextTick(() => {
            switch (this.optionObj.optionInfo.id * 1) {
              case 1:
                // 修改会员信息
                this.$refs.updateVipInfoRef &&
                  this.$refs.updateVipInfoRef.initEditInfo();
                break;
              case 2:
                // 制卡
                this.$refs.makeCardRef && this.$refs.makeCardRef.getVipInfo();
                this.readCard();
                break;
              case 3:
                // 更改会员卡等级
                this.$refs.updateVipDeepRef &&
                  this.$refs.updateVipDeepRef.getVipInfo();
                break;
              case 4:
                // 更改/绑定手机号
                this.$refs.updateVipPhoneNumRef &&
                  this.$refs.updateVipPhoneNumRef.getVipInfo();
                break;
              case 5:
                // 挂失/解除挂失
                this.$refs.enAbledRef && this.$refs.enAbledRef.getVipInfo();
                break;
              case 6:
                // 换卡
                this.$refs.changeCardRef &&
                  this.$refs.changeCardRef.getVipInfo();
                this.readCard();
                break;
              case 7:
                // 退卡
                this.$refs.backCardRef && this.$refs.backCardRef.getVipInfo();
                break;
              case 8:
                // 扣款
                this.$refs.subMoneyRef && this.$refs.subMoneyRef.getVipInfo();
                break;
              case 9:
                // 扣款
                this.$refs.destroyRef && this.$refs.destroyRef.getVipInfo();
                break;
              
              case 10:
                // 扣除积分
                this.$refs.deductionPointRef && this.$refs.deductionPointRef.getVipInfo();
                break;
            }
          });
        } else {
          this.$emit("getTableData", true);
        }
      },
      immediate: true,
    },
    optionObj: {
      handler(newVal) {
        this.currentItemInfo = JSON.parse(JSON.stringify(newVal.currentInfo));
      },
      immediate: true,
      deep: true,
    },
  },
};
</script>

<style scoped lang="less">
@import "../../../../style/common/elementDrawerVip.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/vip/vipBtn.less";
@import "../../../../style/common/elementFormBtnVip.less";
@import "../../../../style/common/scrollBarVip.less";
@import "../../../../style/vip/vipBtn.less";
</style>

<style lang="less" scoped>
.modal {
  position: fixed;
  z-index: 99999;
  left: 0;
  top: 0;
  background-color: rgba(0, 0, 0, 0.5);
  width: 100vw;
  height: 100vh;
  .modal-content {
    width: 500px;
    border-radius: 10px;
    overflow: hidden;
    box-sizing: border-box;
    background-color: #f5f5f5;
    position: absolute;
    left: 50%;
    top: 45%;
    transform: translate(-50%, -50%);
    h3 {
      padding: 30px 30px 0;
    }
    p {
      padding: 10px 30px;
      line-height: 30px;
    }

    .btn-area {
      text-align: center;
      background-color: #eee;
      padding: 20px;
    }
  }
}
</style>
