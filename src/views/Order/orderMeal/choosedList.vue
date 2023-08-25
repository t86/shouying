<template>
  <div class="shopping-cart">
    <div class="shopping-cart-content">
      <div class="shopping-cart-content-top">
        <div class="thead">
          <div class="tr">
            <div class="th">名称</div>
            <div class="th">数量</div>
            <div class="th">单价(元)</div>
            <div class="th">小计(元)</div>
            <div class="th">点单人</div>
            <div class="th">操作</div>
          </div>
        </div>
        <div class="tbody">
          <div class="coll" v-for="item in shoppingCartList" :key="item.id">
            <div class="detail tr">
              <div class="td">{{item.productInfo.name}}</div>
              <div class="td">
                <!-- 赔偿类商品不可修改数量 -->
                <img
                  :src="item.pc==1||((item.at==2||item.at==3||item.at==5)&&authId!=item.ae)?imgSrc.subDisabled:imgSrc.sub"
                  @click="changeCount('sub',item)"
                  alt
                />
                <input
                  type="number"
                  min="1"
                  :disabled="(item.at==2||item.at==3||item.at==5)&&authId!=item.ae"
                  v-model="item.pc"
                  @input="changeCount('input',item)"
                />
                <img
                  :src="item.pc>=100||((item.at==2||item.at==3||item.at==5)&&authId!=item.ae)?imgSrc.addDisabled:imgSrc.add"
                  @click="changeCount('add',item)"
                  alt
                />
              </div>
              <div class="td">{{item.pp}}</div>
              <div class="td">{{item.pa}}</div>
              <div class="td">{{item.personInfo.name}}</div>
              <div class="td">
                <!-- <div class="bg" v-if="item.showList" @click="showOrHideList(item)"></div> -->
                <img :src="imgSrc.shoppingCarMore" @click.stop="showOrHideList(item)" alt />
                <img :src="imgSrc.sanJiao" v-if="item.showList" class="sanJiao" alt />
                <ul class="do-list" v-if="item.showList">
                  <li @click.stop="delProduct(item)">删除</li>
                  <li @click.stop="showOrHideDrawer(3,item)">加要求</li>
                  <!-- 出现更改明细弹框 -->
                  <li @click.stop="showOrHideDrawer(4,item)" v-if="item.is==1">更改明细</li>
                </ul>
              </div>
            </div>
            <div v-if="item.is==1">
              <div class="detail-list tr" v-for="(items,i) in item.si" :key="i">
                <div class="td"></div>
                <div class="td one-txt-cut">{{items.groupInfo.name}}{{items.r ? '（'+items.r+'）':''}}</div>
                <div class="td">{{items.s * items.c * item.pc}}</div>
                <div class="td"></div>
                <div class="td"></div>
                <div class="td"></div>
                <div class="td"></div>
                <div class="td"></div>
              </div>
            </div>
            <div v-if="item.r||item.is==1" class="requested">{{item.r}}</div>
          </div>
        </div>
      </div>

      <div class="shopping-cart-content-bottom" layout="row" layout-align="space-between center">
        <div class="amt" layout="row">
          <p layout="row" layout-align="start center">
            <span>优惠金额：</span>
            <span class="num">￥{{amt.giveAmt}}</span>
          </p>
        </div>
        <div class="btn" layout="row" layout-align="end center">
          <!-- <button @click.stop="showOrHideDrawer(1)">批量赠送</button>
          <button @click.stop="showOrHideDrawer(2)">批量自用</button>-->
          <button @click.stop="submitShoppingCart">立即优惠</button>
        </div>
      </div>
    </div>

    <!-- 批量赠送 -->
    <drawerGiveHeMore
      :status="drawer.status"
      :showDrawer="drawer.showDrawer"
      :currentItemInfo="drawer.currentItemInfo"
      :shoppingCartList="shoppingCartList"
      @showOrHideDrawer="showOrHideDrawer"
    />

    <!-- 单品定制要求 -->
    <drawerChooseRequireInfo
      :showDrawer="requireDrawerInfo.showDrawer"
      :productInfo="requireDrawerInfo.productInfo"
      :requestInfoArr="requireDrawerInfo.requestInfoArr"
      notCloseDrawer="true"
      @updateRequireInfoArr="updateRequireInfoArr"
      @showOrHideDrawer="showOrHideRequireDrawer"
    />
  </div>
</template>
 
<script>
import api_order from "@/api/order";
import common_order from "@/utils/common/order";
import common_book from "@/utils/common/book";

import add from "@/assets/order-img/add.png";
import sub from "@/assets/order-img/sub.png";
import addDisabled from "@/assets/order-img/add-disabled.png";
import subDisabled from "@/assets/order-img/sub-disabled.png";
import shoppingCarMore from "@/assets/order-img/shoppingCarMore.png";
import sanJiao from "@/assets/card-imgs/cardOptions/sanjiao.png";

import drawerGiveHeMore from "@/components/order/shoppingCart/drawerGiveHeMore";
import drawerChooseRequireInfo from "@/components/order/drawerMeal/drawerChooseRequireInfo";
export default {
  data() {
    return {
      authId: "", // 用户id
      shoppingCartList: [], // 购物车列表数据
      updateDetail: {
        // 修改套餐明细
        productItemInfo: {}, // 当前被修改的套餐总信息
        groupList: [], // 修改套餐明细列表
        showDialog: false,
        detailIndex: 0 // 选择修改套餐明细的索引值
      },
      drawer: {
        showDrawer: false,
        status: 1, // 1:批量赠送  2：批量自用  3：加要求  4：更改明细
        currentItemInfo: {} // 当前加要求/更改明细的商品信息
      },
      imgSrc: {
        add,
        sub,
        addDisabled,
        subDisabled,
        shoppingCarMore,
        sanJiao
      },
      requireDrawerInfo: {
        shoppingCartId: "", // 当前单品的购物车id
        showDrawer: false,
        productInfo: {}, //  当前单品的单品信息
        requestInfoArr: [] // 当前单品修改前的定制要求
      }
    };
  },
  methods: {
    // 删除购物车商品
    delProduct(info) {
      this.$confirm("确认删除此商品吗？", "删除？", {
        distinguishCancelAndClose: true,
        confirmButtonText: "确定",
        cancelButtonText: "取消"
      })
        .then(async () => {
          try {
            const params = {
              seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64  卡台Id
              id: info.id * 1, // int64 购物车项Id
              cnt: 0 //  int  修改后数量 =0表示删除
            };
            const res = await api_order.reqUpdateShoppingCount(params);
            if (res.code === 1) {
              this.getShoppingCartData();
            } else {
              this.$message.warning(res.msg);
            }
          } catch (error) {
            console.log("删除商品失败", error);
          }
        })
        .catch(() => {
          this.shoppingCartList.forEach((el, i) => {
            el.showList = false;
          });
        });
    },

    // 是否显示操作下拉框选项
    showOrHideList(info) {
      const index = this.shoppingCartList.findIndex(el => el.id == info.id);
      this.shoppingCartList.forEach((el, i) => {
        el.showList = index == i ? !el.showList : false;
      });
    },

    // 获取购物车列表数据
    async getShoppingCartData() {
      this.$store.dispatch("getShoppingCount", this);
      try {
        const params = {
          id: this.$store.state.orderInfo.currentCardInfo.seatId * 1 // int64  卡台Id
        };
        const res = await api_order.reqGetShoppingList(params);
        console.log(res);
        if (res.code === 1) {
          const data = res.data || [];
          data.forEach(el => {
            el.productInfo = common_order.getProductInfo(el.pid);
            el.personInfo = common_book.getOrderPersonInfo(el.wei);
            el.authInfo = common_book.getOrderPersonInfo(el.ae);
            el.showList = false;
            if (el.is == 1)
              el.si.forEach(ele => {
                ele.groupInfo = common_order.getProductInfoFromGroup(ele.i);
              });
          });
          this.shoppingCartList = data;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("购物车列表获取失败", error);
      }
    },

    // 更改购物车商品数量
    async changeCount(type, info) {
      if (
        this.authId != info.ae &&
        (info.at == 2 || info.at == 3 || info.at == 5)
      )
        return this.$message.warning("此优惠商品非当前用户授权，不可修改数量");
      let count = info.pc;
      switch (type) {
        case "add":
          count = Math.min(count + 1, 1000);
          break;
        case "sub":
          count = Math.max(count - 1, 1);
          break;
        case "input":
          count = Math.min(count, 1000);
          count = Math.max(count, 1);
          break;
      }
      try {
        const params = {
          seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64  卡台Id
          id: info.id * 1, // int64 购物车项Id
          cnt: count //  int  修改后数量 =0表示删除
        };
        const res = await api_order.reqUpdateShoppingCount(params);
        if (res.code === 1) {
          info.pc = count;
          info.pa = res.data.prd_amt;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("更改购物车商品数量失败", error);
      }
    },

    // 修改套餐明细选择框
    showOrHideDialog() {
      this.updateDetail.showDialog = !this.updateDetail.showDialog;
      if (!this.updateDetail.showDialog) {
        this.shoppingCartList.forEach(el => {
          el.showList = false;
        });
      }
    },

    // 立即优惠
    submitShoppingCart() {
      this.$confirm("确认优惠吗？", "优惠", {
        distinguishCancelAndClose: true,
        confirmButtonText: "确定",
        cancelButtonText: "取消"
      })
        .then(async () => {

          return this.$message.warning('开发中，敬请期待......')
          const params = {
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64    卡台Id
            shopping_cart_ids: this.shoppingCartList.map(el => el.id) // []int64   要下单的购物车项Id
          };
          try {
            const res = await api_order.reqPlaceAnOrder(params);
            if (res.code === 1) {
              this.$message.success("下单成功");
              // this.getShoppingCartData();
              this.$store.dispatch("getShoppingCount", this);
              // 跳转到点单页面
              this.$parent.$children[0]&& this.$parent.$children[0].footNavBarClick && this.$parent.$children[0].footNavBarClick({
                id: 2,
                name: "商品菜单",
                routeName: "orderMealList"
              });
            } else {
              this.$message.warning(res.msg);
            }
          } catch (error) {
            console.log("购物车下单失败", error);
          }
        })
        .catch(() => {});
    },

    // 显示隐藏赠送或自用信息
    showOrHideDrawer(status, objInfo) {
      // 单品定制要求
      if (objInfo) {
        objInfo.productInfo.requireInfo = common_order.getRequireInfo(
          objInfo.productInfo.twoCateId
        );
      }

      if (status == 3 && objInfo && objInfo.is == 2) {
        this.requireDrawerInfo.shoppingCartId = objInfo.id;
        this.requireDrawerInfo.productInfo = objInfo.productInfo;
        this.requireDrawerInfo.requestInfoArr = objInfo.r.split(";");
        this.showOrHideRequireDrawer();
        return;
      }

      this.drawer.showDrawer = !this.drawer.showDrawer;
      if (this.drawer.showDrawer) {
        this.drawer.status = status;
        this.drawer.currentItemInfo = objInfo;
      } else {
        this.shoppingCartList.forEach(el => {
          el.showList = false;
        });
      }
    },

    // -------------单品定制要求start----------------

    // 接收单品定制要求的值
    updateRequireInfoArr(requireList) {
      this.requireDrawerInfo.requestInfoArr = requireList;
      this.submitSingleProductRequire();
    },

    // 单品定制要求提交
    async submitSingleProductRequire() {
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64  卡台Id
        id: this.requireDrawerInfo.shoppingCartId * 1, //         int64   购物车项Id
        requirement: this.requireDrawerInfo.requestInfoArr.join(";") // string   要求
      };
      try {
        const res = await api_order.reqUpdateSingleProductRequire(params);
        if (res.code == 1) {
          this.showOrHideRequireDrawer();
          this.getShoppingCartData();
          this.$message.success("修改成功");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("单品修改要求失败", error);
      }
    },

    showOrHideRequireDrawer() {
      this.requireDrawerInfo.showDrawer = !this.requireDrawerInfo.showDrawer;
    }

    // -------------单品定制要求end----------------
  },
  mounted() {
    this.authId = this.$store.state.userInfo.emp_id;
    this.getShoppingCartData();
    document.body.addEventListener("click", this.showOrHideList);
  },
  components: {
    drawerGiveHeMore,
    drawerChooseRequireInfo
  },
  computed: {
    amt() {
      let giveAmt = 0;
      this.shoppingCartList.forEach(el => {
          giveAmt += el.pa * 1;
      });
      return {
        giveAmt: giveAmt.toFixed(2)
      };
    }
  },
  beforeDestroy() {
    document.body.removeEventListener("click", this.showOrHideList);
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDialog.less";
@import "../../../style/order/orderMeal/choosedList/choosedList.less";
</style>

<style scoped>
@import "../../../style/common/elementConfirm.less";
</style>