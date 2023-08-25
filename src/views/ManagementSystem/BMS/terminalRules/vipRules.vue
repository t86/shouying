<template>
  <div class="vip-rules">
    <h4 class="m-b-2">会员卡规则</h4>
    <div class="m-l-4">
      <div>
        <el-checkbox v-model="notPayGroup">线上结账不允许结账套餐</el-checkbox>
        <p class="red-color red">勾选后，在线上支付的时候，套餐不能使用会员卡支付</p>
      </div>
    </div>
    <div class="m-l-4">
      <div>
        <el-checkbox v-model="notPayNotPrd">线上结账不允许结账非主营商品</el-checkbox>
        <p class="red-color red">勾选后，在线上支付的时候，非主营商品不能使用会员卡结账</p>
      </div>
    </div>
    <div class="tips">
      <h4 class="m-t-2 m-b-2">规则解释：</h4>
      <p>1、总剩余：当前会员卡剩余总额</p>
      <p>2、本次可用：本次订单可使用当前会员卡支付的金额</p>
      <p>3、总储值：当前会员卡剩余的储值金额</p>
      <p>4、总赠送：当前会员卡剩余的赠送金额</p>
      <h5 class="m-t-2 m-b-1">问题一：为什么会员卡剩余金额大于订单金额，但是本次可用金额却小于订单金额？</h5>
      <p>答：可能门店不允许使用会员卡结账套餐类或一些特殊商品，但你本次的订单含有这种商品。</p>
    </div>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      isFirstLoad: true,
      notPayGroup: false,
      notPayNotPrd: false
    };
  },
  methods: {
    async init(){
      try {
        const res = await this.$api.BMS.terminalRules.reqGetVipRules();
        if (res.code == 1) {
          res.data.ids = res.data.ids || []
          this.notPayGroup = res.data.ids.includes(1)
          this.notPayNotPrd = res.data.ids.includes(2)
          setTimeout(() => {
            this.isFirstLoad = false
          }, 1000);
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取线上结账不允许结账套餐状态失败', error)
      }
    },

    async changeHandle(){
      let ids = []
      if(this.notPayGroup) ids.push(1)
      if(this.notPayNotPrd) ids.push(2)
      const params = {
        ids   //   []int64    选中规则Id列表
      }
      try {
        const res = await this.$api.BMS.terminalRules.reqSubmitVipRules(params);
        res.code == 1
          ? this.$message.success("保存成功")
          : this.$message.warning(res.msg);
      } catch (error) {
        console.log('更改线上结账不允许结账套餐失败', error)
      }
    }
  },
  mounted () {
    this.init()
  },
  watch: {
    notPayGroup() {
      if(!this.isFirstLoad) this.changeHandle()
    },
    notPayNotPrd() {
      if(!this.isFirstLoad) this.changeHandle()
    }
  }
};
</script>

<style scoped lang="less">
.vip-rules {
  padding: 20px;
  padding-left: 30px;
  .red {
    font-size: 14px;
    line-height: 30px;
  }

  .tips {
    p {
      font-size: 14px;
      line-height: 26px;
      color: #333;
    }
  }
}
</style>