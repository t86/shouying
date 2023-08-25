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
          <bj v-if="status == 1" v-model="dateVal" :dateOptions="dateOptions" :cardInfo="cardInfo" :orderInfo="orderInfo" @changeStatus="changeStatus" />
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
import { sessionStorage } from '@/utils/common/storage.js'
import api_order from "@/api/order";
import bj from './bj.vue'
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
        this.addShoppingCartHandle()
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

    async addShoppingCartHandle(){
      let res = {}
      let params = {}
      if(this.productInfo.prdType == 2) {
        params = {
          ...this.groupParams,
          relate_csm_id: this.orderInfo.id * 1, // int64  关联流水Id(用于补交),没有填0
        }
        try {
          const res = await api_order.reqAddGroupToShopping(params);
          if (res.code === 1) {
            this.$message.success("加入购物车成功");
            this.$store.dispatch("getShoppingCount", this);
            this.onCancelDrawer();
            this.$emit('onCancelDrawer')
          } else {
            this.$message.warning(res.msg);
          }
        } catch (error) {
          console.log("套餐加入购物车失败", error);
        }
        return console.log(params);
      } else {
        params = {
          seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //  int64  卡台Id
          prd_id: this.productInfo.id * 1, // int64   商品Id
          prd_cnt: this.count * 1, //  int    商品数量 小费类商品只能=1
          prd_amt: (this.productInfo.prdType == 13 || this.productInfo.prdType == 14) ? '' : this.amt.toString(), //  string  商品金额 普通商品,定价花篮(13),定价小费(14)不要传金额(空)(系统会自动计算), 时价花篮(3)/时价小费(4) 需传金额
          requirement: this.requestInfoArr.join(";"), // string   要求
          relate_csm_id: this.orderInfo.id * 1, // int64  关联流水Id(用于补交),没有填0
        };

        try {
          if(this.productInfo.prdType == 3 ||
            this.productInfo.prdType == 4 ||
            this.productInfo.prdType == 13 ||
            this.productInfo.prdType == 14 ||
            this.productInfo.prdType == 8) {
            res = await api_order.reqAddAmtToShopping(params);
          } else {
            params.prd_price = this.productInfo.price, //  string  商品单价,用于做二次验证
            res = await api_order.reqAddProductToShopping(params);
          }
          if (res.code == 1) {
            this.$message.success("加入购物车成功");
            this.$store.dispatch("getShoppingCount", this);
            this.onCancelDrawer();
            this.$emit('onCancelDrawer')
          } else {
            this.$message.warning(res.msg);
          }
        } catch (error) {
          console.log("加入购物车授权失败", error);
        }
      }

    },

    changeStatus(status = 1) {
      if(status == 1) {
        this.status = status
      } else if(status == 2) {
        if(!this.dateVal) return this.$message.warning('请选择补交日期')
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
    count: {
      default: ''
    },
    amt: {
      default: ''
    },
    requestInfoArr: {
      default: () => ([])
    },
    groupParams: {
      default: () => ({})
    }
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
          title = "补交"
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
    bj,
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
@import "../../../../style/common/elementDrawer.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/common/elementFormBtn.less";
@import "../../../../style/common/scrollBar.less";
</style>