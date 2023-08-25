<template>
  <div>
    <!-- 会员充值 -->
    <el-drawer
      title="读卡"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="600px"
    >
      <div class="session p-5">
        <div class="content m-t-4">
          <readCard  />
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer()">取消</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import md5 from "js-md5";
import api_vip from "@/api/vip";
import readCard from "./readCard.vue";
export default {
  data() {
    return {
      show: false,
    };
  },
  methods: {
    
    onCancelDrawer() {
      this.$emit("showOrHideDrawer");
    },

    // 读卡
    readCard() {
      let cardNo = "";
      try {
        setTimeout(() => {
          cardNo = atool.getCardNo();
          if (!cardNo) {
            if (this.show) this.readCard();
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
          this.onCancelDrawer()
          this.$emit('updateVipDetailHandle', {
            id: res.data.id
          })
        } else {
          this.readCard();
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("刷卡获取vipId失败", error);
      }
    }
  },
  mounted() {},
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    }
  },
  components: {
    readCard,
  },
  watch: {
    showDrawer: {
      handler(newVal) {
        this.show = newVal;
        if(this.show) this.readCard()
      },
      immediate: true
    },
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