<template>
<!-- 收银系统增加滞留金 -->
  <div>
    <el-drawer
      title="新增滞留金"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      append-to-body
      size="600px"
    >
      <div class="session p-5 fs14">
          <div class="coll" layout="row" layout-align="start start">
            <div class="label m-t-2">
              <span class="red-color">*</span>
              <span>渠道：</span>
            </div>
            <div class="value" layout="row" layout-align="start center">
              <div
                class="choose"
                :class="{'active': payType == item.id}"
                v-for="item in payTypeListArr"
                :key="item.id"
                @click="payType = item.id"
              >{{item.n}}</div>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span class="red-color">*</span>
              <span>金额：</span>
            </div>
            <div class="value" layout="row" layout-align="start center">
              <el-input style="width: 380px" v-model="amt" size="small" placeholder="请输入金额"></el-input>&nbsp;&nbsp;
              <span>元</span>
            </div>
          </div>

          <div class="m-t-6">
            <keyBoard needPoint="true" @changeNum="changeNum" />
          </div>
        </div>

      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_money from "@/api/money";
export default {
  data() {
    return {
      payTypeListArr: [],
      payType: "",
      amt: "",
    };
  },
  methods: {
    init(){
      this.payType = ''
      this.amt = ''
      this.payTypeListArr = JSON.parse(JSON.stringify(this.payTypeList))
    },

    changeNum(value) {
      switch (value) {
        case 10: // 小数点
          if (this.amt.toString().indexOf(".") > -1) return;
          this.amt = this.amt.toString() + ".";
          break;
        case 12: // 回退
          this.amt =
            this.amt.toString().slice(0, this.amt.toString().length - 1) * 1;
          break;
        default:
          this.amt = this.amt.toString() + value;
          break;
      }
    },

    async onSubmit() {
      if(this.payType == '') return this.$message.warning('请选择渠道')
      if(!this.amt) return this.$message.warning('请输入金额')
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64 卡台Id
        pay_cnl_id: this.payType * 1, // int   滞留金渠道Id
        pay_amt: this.amt.toString(), //  string   滞留金金额
      }
      try {
        const res = await api_money.reqAddMerchantMoney(params)
        if(res.code == 1) {
          this.$message.success('新增成功')
          this.onCancelDrawer()
          this.$emit('getTableData')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
     
    },
    onCancelDrawer() {
      this.show = false;
    }
  },
  created() {},
  mounted() {},
  props: {
    value: {
      default: false
    },
    payTypeList:{
      default: () => ([])
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
    }
  },
  components: {
    keyBoard: () => import("@/components/common/keyBoard")
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.init();
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang='less'>
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>
<style scoped lang='less'>
.session {
  color: rgba(255, 255, 255, 0.8);
}

.coll {
  margin-top: 20px;
  .label {
    width: 80px;
    text-align: right;
  }

  .value {
    width: calc(100% - 100px);
    margin-left: 10px;
    flex-wrap: wrap;
    .choose {
      cursor: pointer;
      padding: 6px 16px;
      margin-right: 10px;
      margin-bottom: 10px;
      border: 1px solid #999;
      color: #999;
      border-radius: 6px;

      &.active {
        border-color: #4b89ff;
        color: #4b89ff;
      }
    }
  }
}

.content {
  padding: 10px;
  text-align: center;
  box-sizing: border-box;

  .label {
    margin: 4.5vh 0 5.5vh;
    font-size: 16px;
    line-height: 16px;

    .amt {
      color: #1edaad;
      font-size: 30px;
    }
  }

  .qr {
    margin: 0 auto;
    width: 240px;
    height: 240px;
    background-color: rgba(255, 255, 255, 0.2);

    img.loading {
      width: 70px;
      animation: rotateAnimation 0.7s linear infinite;
    }

    @keyframes rotateAnimation {
      from {
        transform: rotate(0deg);
      }
      to {
        transform: rotate(360deg);
      }
    }
  }

  .tips {
    font-size: 15px;
    color: #ff2f4b;
    margin-top: 4.5vh;
    margin-bottom: 5vh;
  }
}
</style>