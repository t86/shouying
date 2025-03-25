<template>
  <div>
    <!-- 商户号信息 -->
    <el-drawer
      title="商户号信息"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="merchant fs14">
        <div v-show="status == 1">
          <p class="m-t-3 fs14">{{$overall.toFixed(((merchantAmtInfo.amt - merchantAmtInfo.g_amt) / 10000), 2)}}</p>
          <p class="m-t-3 fs14">G {{$overall.toFixed((merchantAmtInfo.g_amt / 10000), 2)}}</p>
          <div class="content-table" layout="row" layout-align="center center">
            <div class="table-content">
              <div class="table">
                <div class="tbody">
                  <div class="tr" v-for="(item, index) in leftTableData" :key="index" layout="row" layout-align="space-between center">
                    <div class="td">{{item.h}}</div>
                    <div class="td">{{item.c}}</div>
                    <div class="td">{{item.g}}</div>
                    <div class="td">{{item.t}}</div>
                  </div>
                </div>
              </div>
            </div>
            <div class="table-content">
              <div class="table">
                <div class="tbody">
                  <div class="tr" v-for="(item, index) in rightTableData" :key="index" layout="row" layout-align="space-between center">
                    <div class="td">{{item.h}}</div>
                    <div class="td">{{item.c}}</div>
                    <div class="td">{{item.g}}</div>
                    <div class="td">{{item.t}}</div>
                  </div>
                </div>
              </div>
            </div>

          </div>
          <el-button type="primary" style="width:200px;margin-top: 20px" @click="getMerchantList">商户号一键切换</el-button>
        </div>
        <div v-show="status == 2">
          <div class="status2" layout="row" layout-align="start center">
            <div class="merchant-item" :class="{'active': currentMerchantInfo.id == item.id}" v-for="item in merchantList" :key="item.id" @click="currentMerchantInfo = item">{{item.n}}</div>
          </div>
        </div>
        <div v-show="status == 3">
          <p class="m-t-3 fs14">{{$overall.toFixed(((merchantAmtInfo.amt - merchantAmtInfo.g_amt) / 10000), 2)}}</p>
          <p class="m-t-3 fs14">G {{$overall.toFixed((merchantAmtInfo.g_amt / 10000), 2)}}</p>
          <p class="m-t-3 fs14">【{{currentMerchantInfo.n}}】</p>
          <el-button type="primary" style="width:200px;margin-top: 20px" @click="cancelChangeHandle">取消切换</el-button>
        </div>
      </div>
      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer(status == 3)">{{status == 1 ? '关闭' : status == 2 ? '上一步' : '关闭窗口' }}</el-button>
        <el-button type="primary" v-if="status == 2" @click="onSubmit">确定</el-button>
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
      status: 1,  // 1 商户号信息展示  2 商户号选择  3 选择后的商户号信息
      leftTableData: [],
      rightTableData: [],
      currentMerchantInfo: {},
      merchantList: [],
      merchantAmtInfo: {}
    };
  },
  methods: {
    async getMerchantList(){
      try {
        const res = await api_money.reqGetMerchantList()
        if(res.code == 1) {
          this.status = 2
          this.merchantList = res.data.cnl_cfgs || []
          if(res.data.enabled == 1) {
            // 配置过
            this.currentMerchantInfo = this.merchantList.find(item => item.id == res.data.id) || {}
          } else {
            this.currentMerchantInfo = {}
          }
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },

    async getMerchantTimeAmtList(){
      try {
        let params = {
          cnl_cfg_id: this.merchantId * 1
        }
        const res = await api_money.reqGetMerchantTimeAmtList(params)
        if(res.code == 1) {
          const result = res.data.records || []
          result.sort((a,b) => a.h - b.h)
          this.rightTableData = result.slice(0, 12)
          this.leftTableData = result.slice(12, 24)
          
          // 合并传入的金额信息
          if (!this.merchantAmtInfo.amt && !this.merchantAmtInfo.g_amt && result.length > 0) {
            // 如果没有传入金额信息，则使用接口返回的数据计算总额
            this.merchantAmtInfo = {
              amt: result.reduce((sum, item) => sum + (Number(item.c) || 0), 0),
              g_amt: result.reduce((sum, item) => sum + (Number(item.g) || 0), 0)
            };
          }
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },

    async onSubmit() {
      if(this.currentMerchantInfo.id) {
        const params = {
          cnl_cfg_id: this.currentMerchantInfo.id * 1, // int64   切换的目标商户号Id
        }
        try {
          const res = await api_money.reqOpenMerchantConfig(params)
          if(res.code == 1) {
            this.status = 3
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('数据请求失败', error);
        }
      } else {
        this.$message.warning('请选择')
      }
    },

    async cancelChangeHandle(){
      try {
        const res = await api_money.reqCancelMerchantConfig()
        if(res.code == 1) {
          this.$message.success('操作成功')
          this.onCancelDrawer(true)
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },

    onCancelDrawer(isClose = false) {
      if(this.status > 1 && !isClose) {
        this.status -= 1
      }  else {
        this.$emit("showOrHideDrawer");
      }
    }
  },
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    },
    merchantId: {
      type: [Number, String],
      default: null
    },
    amt: {
      type: [Number, String],
      default: 0
    },
    g_amt: {
      type: [Number, String],
      default: 0
    }
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.status = 1;
        // 初始化商户金额信息
        this.merchantAmtInfo = {
          amt: this.amt || 0,
          g_amt: this.g_amt || 0
        };
        console.log("this.merchantAmtInfo:", this.merchantAmtInfo)
        this.getMerchantTimeAmtList();
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>
<style lang="less" scoped>
.merchant {
  padding: 10px 20px 60px;
  box-sizing: border-box;
  color: rgba(255, 255, 255, 0.8);
  text-align: center;

  .status2 {
    flex-wrap: wrap;
    .merchant-item {
      min-width: 106px;
      position: relative;
      padding: 6px 10px;
      border: 1px solid #999;
      border-radius: 8px;
      cursor: pointer;
      margin: 4px 8px;

      &.merchant-common {
        &:after {
          position: absolute;
          content: "公";
          padding: 3px;
          border: 1px solid rgba(255, 255, 255, 0.8);
          background-color: #222f4d;
          border-radius: 50%;
          color: rgba(255, 255, 255, 0.8);
          font-size: 12px;
          right: 0;
          top: 0;
          transform: translate(50%, -50%);
        }
      }

      &.active {
        border-color: #409eff;
        color: #409eff;

        &.merchant-common {
          &:after {
            border-color: #409eff;
            color: #409eff;
          }
        }
      }
    }
  }
}
</style>

<style lang="less" scoped>
.table {
  margin: 20px 10px 0;
  border: 1px solid #999;
  border-radius: 10px;
  width: 300px;
  overflow: hidden;

  .tr {
    box-sizing: border-box;
    min-height: 36px;
    // line-height: 36px;
    padding: 4px 0;
    font-size: 14px;
  }

  .tbody {
    width: 100%;
    .tr:nth-child(2n) {
      background-color: #2f3342;
      .td{
        background-color: #2f3342;
      }
    }
    .tr:nth-child(2n + 1) {
      background-color: #2A3959;
      .td{
        background-color: #2A3959;
      }
    }
  }

  .th,
  .td {
    width: 50%;
    padding: 0 10px;
    box-sizing: border-box;
  }
}
</style>