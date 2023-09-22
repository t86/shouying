<template>
<!-- 收银系统滞留金管理 -->
  <div>
    <el-drawer
      title="滞留金管理"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      append-to-body
      size="720px"
    >
      <div class="session p-5 fs14">
        <div class="top">
          <el-button type="primary" style="width: 80px;height:36px" @click.native="showAddMerchant = true">新增</el-button>
        </div>
        <div class="tips">
          <p class="fs12">1、微信、会员卡、支付宝渠道支付的滞留金，不允许删除；如在清台时未使用完，将会在清台后退回到客人账户</p>
          <p class="fs12">2、除微信、会员卡、支付宝渠道外，其他渠道如在清台时未使用或未删除，将不允许继续进行清台操作</p>
        </div>

        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="start center">
              <div class="th">序号</div>
              <div class="th">支付渠道</div>
              <div class="th">支付金额</div>
              <div class="th">支付时间</div>
              <div class="th">备注</div>
              <div class="th">操作</div>
            </div>
          </div>
          <div class="tbody">
            <div
              class="tr"
              layout="row"
              layout-align="start center"
              v-for="(item, index) in tableData"
              :key="item.id"
            >
              <div class="td one-txt-cut">{{index + 1}}</div>
              <div class="td">{{item.n}}</div>
              <div class="td">{{item.a}}</div>
              <div class="td">{{item.t}}</div>
              <div class="td">{{item.r}}</div>
              <div class="td">
                <span class="primary-link cursor" @click="changeMerchant(item)">转滞留金</span>
                <span class="primary-link cursor" v-if="item.b == 1" @click="backHandle(item)">退款</span>
                <span class="primary-link cursor" v-else @click="deleteHandle(item)">删除</span>
              </div>
            </div>
            <p v-if="tableData.length == 0" class="m-t-10 fs14" style="text-align:center">暂无数据</p>
          </div>
        </div>
      </div>
      
      <!-- 新增滞留金 -->
      <drawerAddMerchantConfig v-model="showAddMerchant" :payTypeList="payTypeList" @getTableData="getTableData" />

      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
      </div>

        <!-- 转滞留金 -->
        <fullPageTable
          titleText="选择卡台"
          @showOrHideFullPageHandle="showOrHideChooseCardHandle"
          @setChoosedCardInfo="setChooseCardInfo"    
          v-if="isShowChooseCard"
        />
    </el-drawer>

    
  
  </div>
</template>
 
<script>
import api_money from "@/api/money";
import fullPageTable from '@/components/book/machine/fullPageTable'
export default {
  data() {
    return {
      payTypeList: [],  // 支付渠道（用于新建滞留金）
      tableData: [],
      showAddMerchant: false, // 新增滞留金

      isShowChooseCard: false, // 是否显示选择卡台组件
    };
  },
  methods: {
    // 获取滞留金表格列表
    async getTableData(force = 2){
      const params = {
        id: this.$store.state.orderInfo.currentCardInfo.seatId * 1,  // int64  卡台Id
        w: force, //  int  是否返回新增滞留金的渠道列表, 第一次拉取的时候获取一下(1), 以后刷新管理列表的时候, 不需要重复拉取(2)
      }
      try {
        const res = await api_money.reqGetMerchantListData(params)
        if(res.code == 1) {
          if(force == 1) {
            this.payTypeList = res.data.new_cnls || []
          }
          this.tableData = res.data.late_cnls || []
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },

    // 删除
    deleteHandle(itemInfo){
      this.$confirm('确认删除', '提示', {
        distinguishCancelAndClose: true,
        confirmButtonText: "确定",
        cancelButtonText: "取消"
      })
        .then(async res => {
          const params = {
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64   卡台Id
            late_id: itemInfo.id * 1, //    int64    滞留金订单Id
          }
          try {
            const res = await api_money.reqDelMerchantMoney(params)
            if(res.code == 1) {
              this.$message.success('删除成功')
              this.getTableData()
            } else {
              this.$message.warning(res.msg)
            }
          } catch (error) {
            console.log('删除滞留金失败', error);
          }
        })
        .catch(e => "");
    },

    // 退款
    backHandle(itemInfo){
      this.$confirm('确认退款', '提示', {
        distinguishCancelAndClose: true,
        confirmButtonText: "确定",
        cancelButtonText: "取消"
      })
        .then(async res => {
          const params = {
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64   卡台Id
            late_id: itemInfo.id * 1, //    int64    滞留金订单Id
          }
          try {
            const res = await api_money.reqBackMerchantMoney(params)
            if(res.code == 1) {
              this.$message.success('退款请求发起成功，具体退款处理结果，请在异议单管理中查看')
              this.getTableData()
            } else {
              this.$message.warning(res.msg)
            }
          } catch (error) {
            console.log('删除滞留金失败', error);
          }
        })
        .catch(e => "");
    },
   
    
    onCancelDrawer() {
      this.show = false;
    },
    // 显示或隐藏选择卡台组件
    showOrHideChooseCardHandle() {
      this.isShowChooseCard = !this.isShowChooseCard;
    },
    changeMerchant(itemInfo){
      console.log('选择的滞留金项',itemInfo)
      this.showOrHideChooseCardHandle();
    },
    setChooseCardInfo(cardInfo) {
      console.log("选择的卡台信息", cardInfo);
    },
    
  },
  props: {
    value: {
      default: false
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
    drawerAddMerchantConfig: () => import("./drawerAddMerchantConfig.vue"),
    fullPageTable
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.getTableData(1);
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
  .tips {
    margin: 20px 0;
    p {
      color: #999;
      line-height: 20px;
    }
  }

  .table {
    margin-top: 20px;
    border: 1px solid #999;
    border-radius: 10px;
    height: calc(100vh - 300px);
    width: 100%;
    overflow: auto;

    .tr {
      box-sizing: border-box;
      min-height: 36px;
      font-size: 14px;
    }

    .thead {
      width: 100%;
      color: rgba(255, 255, 255, .5);
      position: sticky;
      top: 0;
      z-index: 1;
      background:  #182037;
      // background: linear-gradient(180deg, #182037 0%, #11182D 100%);
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
      }

      .td {
        font-size: 13px;
      }
    }

    .th,
    .td {
      width: 50%;
      padding: 0 10px;
      box-sizing: border-box;

      &:nth-child(1){
        width: 20%;
      }

      &:nth-child(5) {
        width: 60%;
      }
      &:nth-child(6){
        width: 50%;
      }
    }

  }
}
</style>