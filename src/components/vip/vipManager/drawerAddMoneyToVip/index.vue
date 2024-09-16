<template>
  <div>
    <!-- 会员充值 -->
    <el-drawer
      title="充值"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="1000"
    >
      <div class="session p-5">
        <div class="search">
          <el-input
            size="small"
            v-model="keyword"
            placeholder="输入手机号后四位后，方可搜索"
            style="width:284px"
            @input="searchHandle"
          ></el-input>
          <button class="btn primary" @click="searchHandle">搜索</button>
          <span v-if="step==1" class="red m-l-6">可刷卡获取会员卡号</span>
        </div>
        <div class="content m-t-4">
          <searchList
            v-if="step == 1"
            :tableData="tableData"
            @changeStep="changeStep"
            @updateCurrentInfo="updateCurrentInfo"
          />
          <searchDetail
            ref="vipDetailRef"
            v-if="step == 2"
            :currentInfo="currentInfo"
            :vipIdOfSwiper="vipIdOfSwiper"
            @updateFormInfo="updateFormInfo"
          />
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer()">取消</el-button>
        <el-button type="primary" v-if="step==2" @click="onSubmit" :disabled="charging" >确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import md5 from "js-md5";
import api_vip from "@/api/vip";
import searchList from "./searchList.vue";
import searchDetail from "./searchDetail.vue";
export default {
  data() {
    return {
      show: false,
      keyword: "",
      step: 0,
      tableData: [],
      currentInfo: {}, // 当前手动选择充值的会员卡相关信息
      vipIdOfSwiper: "",
      stepTwoInfo: {},
      charging: false, //充值处理中
    };
  },
  methods: {
    async searchHandle(e) {
      if (typeof e === "object" && this.keyword.length != 4)
        return this.$message.warning("输入手机号后四位，方可搜索");
      if (this.keyword.length != 4) return this.tableData = [];
      const params = {
        phone: this.keyword //    string   手机号后4位
      };
      try {
        const res = await api_vip.reqGetMakeMoneyListOfPhoneNum(params);
        if (res.code == 1) {
          this.tableData = res.data.records || [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("模糊查询待充值会员列表失败", error);
      }
    },
    updateFormInfo(formInfo) {
      this.stepTwoInfo = { ...formInfo };
    },
    // 提交
    async onSubmit() {
      this.charging = true
      const isCustom = this.stepTwoInfo.makeAmtInfo.d == '自定义'
      const makeAmt = isCustom ? (this.stepTwoInfo.makeAmt * 1).toFixed(2) : (this.stepTwoInfo.makeAmtInfo.d / 100).toFixed(2)
      const freeAmt = isCustom ? (this.stepTwoInfo.freeAmt * 1).toFixed(2) : (this.stepTwoInfo.makeAmtInfo.f / 100).toFixed(2)
      const params = {
        id: (this.currentInfo.id || this.vipIdOfSwiper) * 1 , //    int64    会员卡Id
        val_amt: makeAmt ? makeAmt : "0", //    string   有价金额(最多支持两位小数)
        free_amt: freeAmt ? freeAmt : "0", //   string  赠送金额(最多支持两位小数)
        pt_amt: this.stepTwoInfo.sendPoint ? this.stepTwoInfo.sendPoint * 1 : 0, //   string  赠送积分
        m: isCustom ? 2 : 1,//  int   充值模式 1 规则模式, 2 自定义模式
        oper_emp_id: this.$store.state.userInfo.emp_id * 1, // int64    操作员工
        deposit_cnl: this.stepTwoInfo.typeVal * 1, // int     充值渠道Id
        sales_emp_id: this.stepTwoInfo.personVal * 1, // int64    推荐人(员工)
        remark: this.stepTwoInfo.remark //     string    充值备注
      };
      if (!params.deposit_cnl)  {
        this.charging = false
        return this.$message.warning("请选择充值方式");
      } 
      try {
        const res = await api_vip.reqMakeMoneyToCard(params);
        if (res.code == 1) {
          this.$message.success("充值成功");
          this.onCancelDrawer();
          this.$emit('getTableData')
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("充值失败", error);
      }
      this.charging = false
    },

    changeStep(step = 1) {
      this.step = step;
    },

    updateCurrentInfo(currentInfo) {
      this.currentInfo = { ...currentInfo };
    },
    onCancelDrawer() {
      this.changeStep(0);
      this.$emit("showOrHideDrawer");
    },

    // 读卡
    readCard() {
      let cardNo = "";
      try {
        setTimeout(() => {
          cardNo = atool.getCardNo();
          if (!cardNo) {
            if (this.show && this.step == 1) this.readCard();
          } else {
            this.getCardPwd(cardNo);
          }
        }, 1000);
      } catch (error) {
        console.log("cardNo信息获取失败：", error);
      }
    },

    async getCardPwd(cardNo) {
      const params = {
        card_no: cardNo //  string  卡号,这里是指实体卡卡号
      };
      try {
        const res = await api_vip.reqGetVipCardPwdMsg(params);
        if (res.code == 1) {
          this.getCardData(cardNo, res.data.p);
        } else {
          this.readCard();
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取卡密失败", error);
      }
    },
    
    // 通过查询返回的卡密码,读取卡内容数据
    getCardData(cardNo = '', password = '') {
      let cardInfoText = ''
      try {
        cardInfoText = atool.getCardData(password);  // 参数为密码
        if (cardInfoText.length == 0){
          this.readCard();
          return this.$message.warning('卡验证失败,请确认卡未离开读卡位置或是有效卡')
        }
        this.getVipId(cardNo, cardInfoText)
      } catch (error) {
        console.log('读取卡内容数据失败：', error)
        this.$message.warning('读取卡内容数据失败：' + error)
      }
    },

    // 获取vipId
    async getVipId(cardNo, cardInfoText) {
      const params = {
        card_no: cardNo, //    string   卡号,这里是指实体卡卡号
        dt: md5(cardInfoText)
          .toString()
          .toUpperCase() //     string    卡验证数据
      };

      try {
        const res = await api_vip.reqGetVipCardId(params);
        if (res.code == 1) {
          this.vipIdOfSwiper = res.data.id;
          this.changeStep(2);
        } else {
          this.readCard();
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("刷卡获取vipId失败", error);
      }
    },

    restHandle() {
      this.keyword = "";
      this.tableData = [];
      if(this.currentVipId) {
        // 通过新建会员后模态框中去充值点击进入(此处借用刷卡方式进入到充值详情)
        this.vipIdOfSwiper = this.currentVipId
        this.changeStep(2)
      } else {
        // 通过普通充值按钮点击进入
        this.changeStep(1);
        setTimeout(() => {
          this.$message.info("输入手机后四位后，方可自动搜索");
        }, 200);
      }
    }
  },
  mounted() {},
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    },
    currentVipId: {
      default: ''
    }
  },
  components: {
    searchList,
    searchDetail
  },
  watch: {
    showDrawer: {
      handler(newVal) {
        this.show = newVal;
        if (newVal) {
          this.restHandle();
        }
      },
      immediate: true
    },
    keyword() {
      this.changeStep(1);
    },
    step: {
      handler(newVal) {
        if (newVal == 1) {
          this.currentInfo = {};
          this.vipIdOfSwiper = "";
          this.readCard();
        } else if (newVal == 2) {
          this.$nextTick(() => {
            this.$refs.vipDetailRef &&
              this.$refs.vipDetailRef.init &&
              this.$refs.vipDetailRef.init();
          });
        }
      },
      immediate: true
    }
  }
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
.red {
  font-size: 14px;
  color: #e0304f;
}
</style>