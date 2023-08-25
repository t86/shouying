<template>
  <div class="step-two">
   <div class="tips">
    检测到您当前的手机号有以下会员卡，您可直接制卡，也可继续添加新的会员卡
   </div>
   <div class="table">
    <div class="thead">
      <div class="tr" layout="row" layout-align="space-between center">
        <div class="th">序号</div>
        <div class="th">会员卡号</div>
        <div class="th">卡类型</div>
        <div class="th">卡等级</div>
        <div class="th">操作</div>
      </div>
    </div>
    <div class="tbody">
      <div class="tr" layout="row" layout-align="space-between center" v-for="(item,index) in tableData" :key="item.id">
        <div class="td">{{index+1}}</div>
        <div class="td">{{item.cn}}</div>
        <div class="td">{{item.ct}}</div>
        <div class="td">{{item.cl}}</div>
        <div class="td">
          <button class="button" :class="{disabled: item.h == 1}" @click="makeVipCardHandle(item)">制卡</button>
        </div>
      </div>
    </div>
   </div>
  </div>
</template>
 
<script>
  import api_vip from "@/api/vip";
  export default {
    data() {
      return {
        tableData: []
      }
    },
    methods: {
      async getVipCardOfBindPhoneNum() {
        const params = {
          bind_phone: this.stepOneInfo.phoneNum || ''  // string  认证手机号
        }
        try {
          const res = await api_vip.reqGetVipOfBindThisPhoneNum(params)
          if (res.code == 1) {
            this.tableData = res.data.records || []
            if (this.tableData.length == 0) {
              this.$emit('updateIsJumpStepTwo', true)
              this.$emit('changeStep', 3)
            }
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('获取新增会员手机号绑定的会员列表失败', error)
        }
      },

      makeVipCardHandle(itemInfo) {
        if(itemInfo.h == 1) return
        this.$emit('updateStepTwoInfo', {currentMakeCardItemInfo: itemInfo})
        this.$emit('changeStep', 4)
      }
    },
    created() {
      this.getVipCardOfBindPhoneNum()
    },
    mounted() {
 
    },
    props: {
      stepOneInfo: {
        default: ''
      }
    },
    components: {
 
    },
    filters: {
 
    }
  }
 
</script>

<style scoped lang="less">
@import '../../../../style/vip/vip.less';
@import '../../../../style/vip/drawerManager/stepTwo.less';
</style>