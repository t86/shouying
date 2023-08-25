<template>
  <div>
    <!-- 新增、修改会员卡类型 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5">
        <stepOne v-if="step == 1" :stepOneInfo="stepOneInfo" @updateStepOneInfo="updateStepOneInfo" />
        <stepTwo v-if="step == 2" :stepOneInfo="stepOneInfo" @updateStepTwoInfo="updateStepTwoInfo" @changeStep="changeStep" @updateIsJumpStepTwo="updateIsJumpStepTwo"/>
        <stepThree v-if="step == 3" :stepOneInfo="stepOneInfo" @updateStepThreeInfo="updateStepThreeInfo"/>
        <stepFour v-if="step == 4" :vipId="vNodeVipCardId" @updateStepFourInfo="updateStepFourInfo" />
        <div class="model" v-if="showCancelModel">
          <div class="content">
            <div class="title">新增会员卡成功，制卡流程尚未完成，是否放弃制卡？</div>
            <p>放弃后若要重新制卡，需要在会员管理列表中通过手机号检索到该会员卡，进行制卡</p>
            <div class="btn-area">
              <button class="btn primary" @click="onCancelDrawer($event, true)">放弃</button>
              <button class="btn info" @click="showCancelModel=false">取消</button>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="closeDrawerHandle">{{step==4?'关闭':'取消'}}</el-button>
        <el-button type="info" v-if="step==2 || step==3" @click="onCancelDrawer($event, false)">上一步</el-button>
        <el-button type="primary" v-if="step<4" @click="onSubmit">{{submitText}}</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_vip from '@/api/vip'
import stepOne from './stepOne.vue'
import stepTwo from './stepTwo.vue'
import stepThree from './stepThree.vue'
import stepFour from './stepFour.vue'
export default {
  data() {
    return {
      show: false,
      showCancelModel: false,
      step: 1,
      isJumpStepTwo: false,  // 是否跳过step2(用于首次新建记名卡)
      phoneValidateStr: '',  // 手机验证码验证字符串
      vNodeVipCardId: '',  // 制卡所对应的vip卡
      stepOneInfo: {},
      stepTwoInfo: {},
      stepThreeInfo: {},
      stepFourInfo: {},
    };
  },
  methods: {
    updateIsJumpStepTwo(flag = false){
      this.isJumpStepTwo = flag
    },
    updateStepOneInfo(info) {
      this.stepOneInfo = info
    },
    updateStepTwoInfo(info) {
      this.stepTwoInfo = info.currentMakeCardItemInfo
      this.vNodeVipCardId = this.stepTwoInfo.id   // 当前制卡的vip id
      this.$emit('updateVipIdHandle', this.vNodeVipCardId)
    },
    updateStepThreeInfo(info) {
      this.stepThreeInfo = info
    },
    updateStepFourInfo(info) {
      this.stepFourInfo = info
    },

    async validatePhoneInfo(){
      const params = {
        m: this.stepOneInfo.phoneNum , //   string    手机号
        c: this.stepOneInfo.validateVal, //    string   验证码
      }

      if(params.c.length != 5){
        this.$message.warning('请输入正确的五位验证码')
        return false
      }
      try {
        const res = await api_vip.reqValidatePhoneMsg(params)
        if(res.code == 1) {
          this.phoneValidateStr = res.data.c
          return res.data.c
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('验证手机验证码失败', error)
      }
    },

    // 新增会员
    async addVipHandle() {
      const {stepThreeInfo} = this
      const params = {
        card_no: stepThreeInfo.vipNumVal, //    string   卡号
        card_type_id: stepThreeInfo.vipTypeVal * 1, // int64   卡类型Id
        card_level_id: stepThreeInfo.vipDeepVal * 1, // int64    卡等级Id
        contact_phone: stepThreeInfo.connectPhoneNum,  // string  联系手机号
        name : stepThreeInfo.userName, //      string   姓名
        bind_phone_auth_code: this.stepOneInfo.radioVal == 1 ? this.phoneValidateStr : '', // string  认证手机授权码
        bind_phone: this.stepOneInfo.radioVal == 1 ? this.stepOneInfo.phoneNum : '', // string   认证手机
        sex : stepThreeInfo.sexVal * 1, //  int      性别 男1, 女2
        birthday: stepThreeInfo.birthdayVal, //   string   生日 yyyy-mm-dd
        mark: stepThreeInfo.markVal.toString(), //       string   标签
        expired_type: stepThreeInfo.timeLongVal * 1, // int    过期类型
        sales_emp_id: stepThreeInfo.openCardPersonVal * 1, // int64   推荐人
        sms_type_ids: stepThreeInfo.messageList.filter(item => item.checked).map(item => item.id * 1), // []int    订阅消息列表
      }

      if(!params.card_no) {
        this.$message.warning('请输入会员卡号')
        return false
      }

      try {
        const res = await api_vip.reqAddVipCard(params)
        if (res.code == 1) { 
          this.vNodeVipCardId = res.data.id
          this.$emit('updateVipIdHandle', this.vNodeVipCardId)
          return true
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('新建会员失败', error)
      }
    },
    // 提交
    async onSubmit(){
      switch (this.step){
        case 1:
          if(this.stepOneInfo.radioVal == 1) {  // 记名卡
            if(!this.stepOneInfo.phoneNum || this.stepOneInfo.phoneNum.length != 11) return this.$message.warning('请输入11位手机号码')
            const result = await this.validatePhoneInfo()
            if(result) this.changeStep(2)
          } else {
            this.changeStep(3)
          }
          break
        case 2:
          this.changeStep(3)
          break
        case 3:  // 创建会员
          const result = await this.addVipHandle()
          if (result) {
            if (this.stepOneInfo.radioVal == 2) {
              // 不记名卡
              this.changeStep(4)
            } else {
              this.onCancelDrawer('', true)
              this.$emit('getTableData', true)
              this.$emit('showOrHideModalHandle', {
                modalText: '新增成功',
                btnArr: ['关闭', '充值', '制卡']
                })
            }
          } 
          break
        case 4:

          break
      }
    },

    changeStep(step=1){
      this.step = step
      this.$emit('changeInitStep', step)
    },
    onCancelDrawer(e, type) {
      if(!type && this.step > 1) {  // 上一步
        if(this.stepOneInfo.radioVal == 1 && this.step == 3 && this.isJumpStepTwo) return this.changeStep(1)
        if(this.stepOneInfo.radioVal != 1) {
          if(this.step == 3) {
            this.changeStep(1)
          } else {
            this.changeStep(this.step - 1)
          }
        } else {
          this.changeStep(this.step - 1)
        }
      } else {  // 关闭
        this.step = 1
        this.$emit("showOrHideDrawer");
        this.$emit('getTableData', true)
        this.showCancelModel = false
      }
    },

    closeDrawerHandle(e){
      if(typeof e == 'object' && this.step == 4) {
        this.showCancelModel = true
      } else {
        this.onCancelDrawer('', true)
      }
    },

    // 读取卡号
    readCard() {
      let cardNo = ''
      try {
        setTimeout(() => {
          cardNo = atool.getCardNo();
          if(!cardNo) {
            if(this.show && this.step == 4) this.readCard()
          } else {
            this.getBeginCardInfo(cardNo)
          }
        }, 1000);
      } catch (error) {
        console.log('cardNo信息获取失败：', error)
      }
    },
    // 开始制卡
    async getBeginCardInfo(cardNo){
      const params = {
        card_no: cardNo,  //  string  卡号,这里是物理卡的卡号
        mb_card_id: this.vNodeVipCardId * 1 //  int64    虚拟卡Id
      }
      try {
        const res = await api_vip.reqMakeVipCardBegin(params)
        if(res.code == 1) {
          try {
            const result = atool.doRegCard(res.data.card_pass, res.data.card_verify_data)
            if(result === '0') {
              this.makeCardEnd(cardNo)
            } else {
              this.readCard()
              this.$message.warning('制卡失败，即将重新制卡')
            }
          } catch (e) {
            console.log('制卡失败', e)
          }
        } else {
          this.readCard()
          this.$message.warning(res.msg + '，即将重新制卡')
        }
      } catch (error) {
        console.log('制卡begin失败', error)
      }
    },

    // 结束制卡
    async makeCardEnd(cardNo) {
      const params = {
        card_no: cardNo, //    string  卡号
        mb_card_id: this.vNodeVipCardId * 1 //  int64    虚拟卡Id
      }
      try {
        const res = await api_vip.reqMakeVipCardEnd(params)
        if(res.code == 1) {
          this.$message.success('制卡成功')
          this.onCancelDrawer('', true)
          this.$emit('showOrHideModalHandle', {
            modalText: '制卡成功',
            btnArr: ['关闭', '充值']
            })
        } else {
          this.readCard()
          this.$message.warning(res.msg + '，即将重新制卡')
        }
      } catch (error) {
        console.log('制卡结束失败', error)
      }
    },
  },
  mounted() {},
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    },
    initStep: {
      default: 1
    },
    initVipId: {
      default: ''
    }
  },
  computed: {
    title() {
      let title = ''
      if(this.step < 4) {
        title = '新增会员'
      } else {
        title = '制卡'
      }
      return title;
    },
    submitText(){
      let submitText = ''
      switch (this.step) {
        case 1:
          submitText = '下一步'
          break
        case 2:
          submitText = '继续添加'
          break
        case 3:
        case 4:
          submitText = '确定'
          break
      }
      return submitText
    }
  },
  components: {
    stepOne,
    stepTwo,
    stepThree,
    stepFour
  },
  watch: {
    showDrawer: {
      handler(newVal) {
        this.show = newVal;
        if(newVal) {
          this.step = this.initStep || 1
          this.vNodeVipCardId = this.initVipId || ''
        } else {
          this.stepOneInfo = {}
          this.stepTwoInfo = {}
          this.stepThreeInfo = {}
          this.stepFourInfo = {}
          this.updateIsJumpStepTwo(false)
        }
      },
      immediate: true
    },

    step(newVal) {
      if(newVal == 4) {
        // 制卡
        this.readCard()
      }
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
@import "../../../../style/vip/drawerAddOrUpdateVipType.less";
</style>

<style lang="less" scoped>
.model {
  position: fixed;
  width: 100vw;
  height: 100vh;
  left: 0;
  top: 0;
  z-index: 2;
  background-color: rgba(0, 0, 0, .5);
  .content {
    background-color: #fff;
    position: absolute;
    left: 50%;
    top: 45%;
    transform: translate(-50%, -50%);
    padding: 40px;
    width: 450px;
    border-radius: 10px;
    .title {
      font-size: 18px;
      font-weight: 600;
    }
    p {
      margin: 20px 0 ;
      line-height: 30px;
    }
    .btn-area{
      text-align: center
    }
  }
}
</style>