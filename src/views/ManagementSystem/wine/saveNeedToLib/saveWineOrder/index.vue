<template>
  <div>
    <el-drawer
      :title="title"
      :visible.sync="show"
      direction="rtl"
      :size="size"
      append-to-body
      :before-close="onCancelDrawer"
    >
      <div class="content">
        <div class="session m-b-10 p-l-3 p-r-3">
          <cardOrder v-if="status == 1" v-model="dateVal" :dateOptions="dateOptions" :cardInfo="cardInfo" :orderInfo="orderInfo" @changeStatus="changeStatus" />
          <chooseCard ref="chooseCard" v-show="status == 2" :dateVal="dateVal" @chooseCardHandle="chooseCardHandle" />
          <chooseOrder ref="chooseOrder" v-show="status == 3" :dateVal="dateVal" :cardId="cardInfo.id" @chooseOrderHandle="chooseOrderHandle" />
        </div>
        <!-- 提交按钮 -->
        <div class="form-btn" layout="row" layout-align="center center">
          <el-button type="info" @click.stop="onCancelDrawer">取消</el-button>
          <el-button type="primary" @click.stop="onSubmit">{{submitTxt}}</el-button>
        </div>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import cardOrder from './cardOrder.vue'
import chooseCard from './chooseCard.vue'
import chooseOrder from './chooseOrder.vue'
export default {
  data() {
    return {
      status: 1, // 1:补交  2：选择卡台  3：选择流水
      dateVal: '',
      dateOptions: [],
      cardTempInfo: {}, // 点击确定之前的temp卡台信息
      cardInfo: {}, // 卡台信息
      tempOrderInfo: {}, // 点击确定之前的temp流水信息
      orderInfo: {} // 流水信息
    };
  },
  methods: {
    init() {
      console.log("productinfo", this.productInfo);
      this.getDate()
      this.status = 1
      this.cardTempInfo = {}
      this.cardInfo = {}
      this.tempOrderInfo = {}
      this.orderInfo = {}
    },
    async onSubmit() {
      if(this.status == 1) {
        if(this.dateVal == '') return this.$message.warning('请选择日期')
        if(!this.cardInfo.id || !this.orderInfo.id) return this.$message.warning('请选择卡台及流水')
        this.$emit("onSubmit", {
          cardInfo: this.cardInfo,
          orderInfo: this.orderInfo
        });
      } else if(this.status == 2) {
        if(!this.cardTempInfo.id) return this.$message.warning("请选择卡台")
        this.cardInfo = {...this.cardTempInfo}
        this.tempOrderInfo = {}
        this.orderInfo = {}
        this.changeStatus(3)
      } else if (this.status == 3) {
        if(!this.tempOrderInfo.id) return this.$message.warning("请选择流水")
        this.orderInfo = {...this.tempOrderInfo}
        this.changeStatus(1)
      }
    },

    changeStatus(status = 1) {
      if(status == 1) {
        this.status = status
      } else if(status == 2) {
        if(!this.dateVal) return this.$message.warning('请选择营业日期')
        this.status = status;
        this.$refs.chooseCard.init()
      } else if (status == 3) {
        this.status = status;
        this.$nextTick(() => {
          this.$refs.chooseOrder.init()
        });
      }
    },

    chooseCardHandle(cardInfo){
      this.cardTempInfo = {...cardInfo}
    },

    chooseOrderHandle(orderInfo){
      this.tempOrderInfo = {...orderInfo}
    },

    getDate() {
      const canDoList = this.$store.state.cardPageInfo.resResultDataObj.canDoList || []
      const yingYeRiInfo = canDoList[0]
      let year = ''
      let month = ''
      let day = ''
      if(yingYeRiInfo) {
        year = yingYeRiInfo.id.slice(0, 4)
        month = yingYeRiInfo.id.slice(4, 6)
        day = yingYeRiInfo.id.slice(6, 8)
      } else {
        const date = new Date()
        year = date.getFullYear().toString()
        month = (date.getMonth() + 1).toString().padStart(2, 0)
        day = date.getDate().toString().padStart(2, 0)
      }
      this.dateVal = year + '-' + month + '-' + day
      this.initOption()
    },    
    
    initOption(){
      const oneDay = +new Date('2023/06/23') - +new Date('2023/06/22')
      const dateOptions = []
      for (let i = 0; i < 7; i++) {
         dateOptions.push(this.getDateOption(+new Date(this.dateVal) - oneDay * i))
      }
      this.dateOptions = [...dateOptions]
    },

    getDateOption(timeNum) {
      const date = new Date(timeNum)
      const year = date.getFullYear()
      const month = (date.getMonth() + 1).toString().padStart(2, 0)
      const day = date.getDate().toString().padStart(2, 0)
      return {
        label: year + '-' + month + '-' + day
      }
    },

    onCancelDrawer() {
      if(this.status > 1) {
        return this.status -= 1
      }
     this.show = false;
    }
  },
  props: {
    value: false,

    // productInfo.prdType 1存货(关联erp) 7普通(不关联erp) 2套餐 3 时价特饮(关联erp) 4 小费 5 赔偿 6 联营,13 定价特饮 14 定价小费
    productInfo: {
      default: () => {}
    },
  },
  computed: {
    show: {
      get() {
        return this.value;
      },
      set(val) {
        this.$emit("input", val);
      }
    },
    title() {
      let title = "";
      switch (this.status) {
        case 1:
          title = "更改卡台流水"
          break
        case 2:
          title = "选择卡台";
          break;
        case 3:
          title = "选择流水";
          break;
      }
      return title;
    },
    size() {
      let size = "60%";
      switch (this.status) {
        case 1:
          break;
        case 2:
        case 3:
          size = "90%";
          break;
      }
      return size;
    },
    submitTxt() {
      let txt = "确认";
      if(this.status == 2) {
        txt = '下一步'
      }
      return txt;
    }
  },
  components: {
    cardOrder,
    chooseCard,
    chooseOrder
  },
  watch: {
    value(newVal) {
      this.show = newVal;
      if (newVal) {
        this.init()
      }
    },
  }
};
</script>
<style scoped lang="less">
@import '../../../../../style/common/elementDrawerWine.less';
@import '../../../../../style/common/elementDrawerHeaderAndSession.less';
@import '../../../../../style/common/elementFormBtnWine.less';
@import '../../../../../style/erp/form.less';
@import '../../../../../style/erp/table.less';
</style>
<style scoped lang="less">
@import "./../drawerchg.less";
</style>
