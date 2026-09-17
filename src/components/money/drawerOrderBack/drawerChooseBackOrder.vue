<template>
  <!-- 选择要退单的商品信息 status=1 -->
  <div class="choose-back-order">
    <p class="red">请选择退单商品及数量</p>
    <div class="order-back-table">
      <div class="thead">
        <div class="tr">
          <div class="th">
            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll" @change="changeCheckBox('all')">全选</el-checkbox>
          </div>
          <div class="th">状态</div>
          <div class="th">名称</div>
          <div class="th">可退数量</div>
          <div class="th">退单数量</div>
          <div class="th">单价(元)</div>
          <div class="th">小计</div>
          <div class="th">退单小计(元)</div>
          <div class="th">服务员</div>
          <div class="th">点单时间</div>
        </div>
      </div>
      <div class="tbody">
        <div class="coll" v-for="(item,i) in tableData" :key="i">
          <div class="detail tr">
            <div class="td">
              <el-checkbox v-model="item.checked" @change="changeCheckBox('item')">{{i + 1}}</el-checkbox>
            </div>
            <div class="td">
              <span class="green" v-if="item.at==2">惠</span>
              <span class="green" v-if="item.at==3 && !(item.io==1 || item.oid)"><span style="display:block;transform:scale(0.7)">惠2</span></span>
            </div>
            <div class="td">{{item.productInfo.name}}</div>
            <div class="td">{{item.pc}}</div>
            <div class="td">
              <img
                :src="item.changeCount==1?imgSrc.subDisabled:imgSrc.sub"
                @click="changeCount('sub',item)"
                alt
              />
              <input
                type="number"
                min="1"
                :disabled="item.back"
                v-model="item.changeCount"
                @input="changeCount('input',item)"
              />
              <img
                :src="item.changeCount>=item.pc?imgSrc.addDisabled:imgSrc.add"
                @click="changeCount('add',item)"
                alt
              />
            </div>
            <div class="td">{{ formatUnitPrice(item) }}</div>
            <div class="td">{{(item.pa*1).toFixed(2)}}</div>
            <div v-if="['5','3','8'].indexOf(item.productInfo.prdType)>-1" class="td">
              <input
                v-if="item.changeCount < item.pc"
                type="number"
                @input="changeCount('amt', item)"
                v-model="item.allAmt"
                min="0"
                placeholder="请输入金额"
              />
              <span v-else>{{item.allAmt}}</span>
            </div>
            <div
              v-else
              class="td"
            >{{ formatRefundSubtotal(item) }}</div>
            <div class="td">{{item.personInfo?item.personInfo.name:'自助'}}</div>
            <div class="td">{{item.ot.slice(7)}}</div>
          </div>
          <div v-if="item.is==1&&(!item.back)">
            <div class="detail-list tr" v-for="(items,i) in item.si" :key="i">
              <div class="td"></div>
              <div class="td"></div>
              <div class="td">{{items.groupInfo ? items.groupInfo.name : ''}}</div>
              <div class="td">{{items.sc * items.dpc * item.pc}}</div>
              <div class="td"></div>
              <div class="td"></div>
              <div class="td"></div>
              <div class="td"></div>
              <div class="td"></div>
              <div class="td"></div>
            </div>
          </div>
          <div
            v-if="(item.r||item.is==1)&&!item.back"
            :class="{'pt':item.is==1}"
            class="requested"
          >{{item.r}}</div>
        </div>
      </div>
    </div>
    <p class="red m-t-4">请选择退单理由</p>
    <ul class="reason-list" layout="row" layout-align="start center">
      <li :class="{'active': backReason == item.name}" v-for="item in reasonList" :key="item.id" @click="backReason=item.name">{{item.name}}</li>
    </ul>
  </div>
</template>
 
<script>
import add from "@/assets/order-img/order_add.png";
import sub from "@/assets/order-img/sub.png";
import addDisabled from "@/assets/order-img/add-disabled.png";
import subDisabled from "@/assets/order-img/sub-disabled.png";
import { resolveUnitPrice, buildPriceContextFromStore, calcItemAmount } from "@/utils/orderItemPrice";
export default {
  data() {
    return {
      // 表格数据
      checkAll: false,
      tableData: [],
      backReason: '',
      imgSrc: {
        add,
        sub,
        addDisabled,
        subDisabled
      }
    };
  },
  methods: {
    formatUnitPrice(item) {
      // 时价商品按现有逻辑直接显示时价
      if (['3','4','5'].indexOf(item.productInfo && item.productInfo.prdType) > -1) {
        return '时价';
      }
      try {
        const ctx = buildPriceContextFromStore(this.$store);
        ctx.fcProductPrices = []; // 退单沿用原订单价格
        const unit = resolveUnitPrice(item, ctx);
        if (unit === null || unit === undefined || Number.isNaN(Number(unit))) {
          return '时价';
        }
        return (Number(unit) || 0).toFixed(2);
      } catch (e) {
        // fallback to original pp if something goes wrong
        return (item.pp * 1).toFixed(2);
      }
    },
    formatRefundSubtotal(item) {
      try {
        const ctx = buildPriceContextFromStore(this.$store);
        ctx.fcProductPrices = []; // 退单沿用原订单价格
        const amt = calcItemAmount(item, ctx);
        return (amt || 0).toFixed(2);
      } catch (e) {
        // fallback to previous inline logic
        return item.pp == 0 ? (item.pa * 1).toFixed(2) : ((item.pp * 1) * (item.changeCount * 1)).toFixed(2);
      }
    },
    // 初始化退单列表信息
    init(originOrderList){
      originOrderList = originOrderList || JSON.parse(JSON.stringify(this.originOrderList))
      this.checkAll = true
      if(originOrderList.some(item => item.oid)){
        // 线上订单

        const onlineOrderList = originOrderList.filter(item => item.oid)
        const localOrderList = originOrderList.filter(item => !item.oid)

        const onlineTableData = onlineOrderList.map(item => item.os).flat()

        this.tableData = [...onlineTableData, ...localOrderList].filter(item => item.pc > 0 && !item.back).map(item => ({
          ...item,
          changeCount: item.pc * 1,
          checked: true,
          allAmt: item.pa
        }))
      }else{
        // 全部为线下订单
        this.tableData = JSON.parse(JSON.stringify(originOrderList)).filter(
          item => !item.back && item.payed
        ).map(item => ({
          ...item,
          changeCount: item.pc * 1,
          checked: true,
          allAmt: item.pa
        }))
      }
      
      this.$emit(
        "getBackOrderList",
        this.tableData.filter(item => item.changeCount > 0)
      );
    },
    // 更改结账商品数量
    changeCount(type, info) {
      if (type !== "amt") {
        let count = info.changeCount;
        switch (type) {
          case "add":
            count = Math.min(count + 1, info.pc);
            break;
          case "sub":
            count = Math.max(count - 1, 1);
            break;
          case "input":
            count = Math.min(count, info.pc);
            count = Math.max(count, 1);
            break;
        }
        info.changeCount = count;
        if(['5','3','8'].indexOf(info.productInfo.prdType)>-1) {
          if(info.changeCount == info.pc) {
            info.allAmt = info.pa
          }
        }
        this.$forceUpdate();
      }
      this.$emit(
        "getBackOrderList",
        this.tableData.filter(item => item.changeCount > 0 && item.checked)
      );
    },
    // 选择需要退单的商品
    changeCheckBox(type){
      switch(type){
        case 'all':
          this.tableData = this.tableData.map(item => ({
            ...item,
            checked: this.checkAll
          }))
          break
        case 'item':
          this.checkAll = this.tableData.every(item => item.checked)
          break
      }
      this.$emit(
        "getBackOrderList",
        this.tableData.filter(item => item.changeCount > 0 && item.checked)
      );
    },
  },
  props: {
    originOrderList: {
      default: () => ({}) // 已支付订单信息
    },
    show: {
      default: false
    }
  },
  computed: {
    reasonList(){ // 退单理由
      return this.$store.state.cardPageInfo.resResultDataObj.reasonList.filter(item => item.status == 1 && item.type_id == 2)
    },
    isIndeterminate(){
      return !this.checkAll && this.tableData.some(item => item.checked)
    }
  },
  watch: {
    show:{
      handler(newVal) {
        if(newVal) this.init()
      },
      immediate: true
    },
    backReason(newVal) {
      this.$emit('updateBackReason', newVal)
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/scrollBar.less";
@import "../../../style/money/drawerChooseBackOrder.less";
</style>