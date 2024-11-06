<template>
  <div>
    <!-- 挂账还款 -->
    <el-drawer
      title="挂账还款"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="600px"
    >
      <div class="account-gave-money">
        <div class="form">
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span>当前账户:</span>
            </div>
            <div class="value" layout="row" layout-align="start center">{{currentInfo.n}}</div>
          </div>
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span>剩余挂账金额:</span>
            </div>
            <div class="value" layout="row" layout-align="start center">{{currentInfo.a}}</div>
          </div>
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span class="red">*</span>
              <span>还款方式:</span>
            </div>
            <div class="value" layout="row" layout-align="start center">
              <div class="item">
                <div
                  class="item-info"
                  :class="{active: activeId == item.id}"
                  v-for="item in returnList"
                  :key="item.id"
                  @click="activeId=item.id"
                >{{item.name}}</div>
              </div>
            </div>
          </div>
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span class="red">*</span>
              <span>还款金额:</span>
            </div>
            <div class="value" layout="row" layout-align="start center">
              <input type="text" v-model="amtCount" placeholder="请输入金额" />
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
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
      show: false,
      activeId: "",
      amtCount: '',
      returnList: [
        {
          id: 1,
          name: '现金还款'
        },
        {
          id: 2,
          name: '微信还款'
        },
        {
          id: 3,
          name: '支付宝还款'
        },
        {
          id: 4,
          name: '刷卡还款'
        },
        {
          id: 5,
          name: '工资抵扣'
        },
        {
          id: 6,
          name: '会员卡扣款'
        }
      ]
    };
  },
  methods: {
    // 提交
    async onSubmit() {
      if(this.activeId == '') return this.$message.warning('请选择还款方式')
      if(this.amtCount * 1 == 0) return this.$message.warning('请输入还款金额')
      const params = {
        id: this.currentInfo.id * 1, //   int64  挂账账户Id
        cnl_name: this.returnList[this.activeId - 1].name,   //   string   还款渠道名称
        amt: this.amtCount   //   string  还款金额
      };
      try {
        const res = await api_money.reqReturnMoney(params);
        if (res.code == 1) {
          this.$message.success("还款成功");
          this.$emit("getTableData");
          this.onCancelDrawer();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("还款失败", error);
      }
    },
    onCancelDrawer() {
      this.$emit("showOrHideGaveMoneyDrawer");
    }
  },
  mounted() {},
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    },
    currentInfo: {
      default: () => ({})
    }
  },
  watch: {
    showDrawer: {
      handler(newVal) {
        this.show = newVal;
        if (!newVal) {
          this.$emit('getTableData')
        } else {
          this.amtCount = ''
        }
      },
      immediate: true
    },
    amtCount(newVal){
      if(isNaN(newVal * 1)) return this.$message.warning('请输入数字')
      if(newVal * 1 > this.currentInfo.a * 1) {
        this.amtCount = this.currentInfo.a
        this.$message.warning('当前可还款最大金额为' + this.currentInfo.a)
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/common/elementFormBtn.less";
@import "../../../style/common/scrollBar.less";
</style>
<style lang="less" scoped>
.account-gave-money {
  padding: 20px;
  color: rgba(255, 255, 255, .8);
  font-size: 14px;

  .red {
    color: #ff2f64;
  }

  .form {
    .row {
      padding: 10px 20px;
      .label {
        width: 100px;
        text-align: right;
      }
      .value {
        padding-left: 10px;
        width: 400px;
        input {
          padding: 0 10px;
          box-sizing: border-box;
          width: 200px;
          height: 30px;
          border-radius: 8px;
          box-sizing: border-box;
          border: 1px solid rgba(255, 255, 255, 0.15);
        }

        .btn {
          margin-left: 10px;
          background-color: #4b89ff;
          border-radius: 4px;
          width: 90px;
          height: 30px;
          line-height: 30px;
          text-align: center;
          cursor: pointer;

          &.disabled {
            background-color: #aaa;
            color: #eee;
            cursor: no-drop;
          }
        }
        .item {
          display: grid;
          width: 100%;
          grid-template-columns: repeat(auto-fill, 100px);
          grid-auto-rows: 40px;
          grid-gap: 10px;
          .item-info {
            border: 1px solid rgba(255, 255, 255, 0.15);
            border-radius: 8px;
            line-height: 40px;
            text-align: center;
            cursor: pointer;
            &.active {
              border-color: #4b89ff;
              color: #4b89ff;
            }
          }
        }
      }
    }
  }
}
</style>