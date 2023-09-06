<template>
  <div class="shopping-cart">
    <div class="shopping-cart-content" :class="{rect: !isRect}">
      <div class="shopping-cart-content-top">
        <div class="thead">
          <div class="tr">
            <div class="th">状态</div>
            <div class="th">名称</div>
            <div class="th">数量</div>
            <div class="th">单价(元)</div>
            <div class="th">小计(元)</div>
            <div class="th">点单人</div>
            <div class="th">优惠人</div>
            <div class="th">操作</div>
          </div>
        </div>
        <div class="tbody">
          <div class="coll" v-for="item in shoppingCartList" :key="item.id">
            <div class="detail tr">
              <div class="td" layout="row" layout-align="start center">
                <span class="green" v-if="item.at==2">惠</span>
                <span class="green" v-if="item.at==3"><span style="display:block;transform:scale(0.7)">惠2</span></span>
                <!-- <span class="blue" v-if="item.at==6">自</span> -->
                <!-- <span class="purple">结</span>
                <span class="red">退</span>-->
              </div>
              <div class="td">
                <div class="p one-txt-cut">{{item.productInfo.name}}</div>
                <div class="p english-name one-txt-cut">{{item.productInfo.nameEng}}</div>
              </div>
              <div class="td">
                <!-- 赔偿类商品不可修改数量 -->
                <img
                  :src="item.pc==1||((item.at==2||item.at==3)&&authId!=item.ae)?imgSrc.subDisabled:imgSrc.sub"
                  @click="changeCount('sub',item)"
                  alt
                />
                <input
                  type="number"
                  min="1"
                  :disabled="(item.at==2||item.at==3)&&authId!=item.ae"
                  v-model="item.pc"
                  @input="changeCount('input',item)"
                />
                <img
                  :src="item.pc>=100||((item.at==2||item.at==3)&&authId!=item.ae)?imgSrc.addDisabled:imgSrc.add"
                  @click="changeCount('add',item)"
                  alt
                />
              </div>
              <div class="td">{{item.pp}}</div>
              <div class="td">{{item.pa}}</div>
              <div class="td">{{item.personInfo.name}}</div>
              <div class="td">{{item.authInfo? item.authInfo.name : '---'}}</div>
              <div class="td">
                <!-- <div class="bg" v-if="item.showList" @click="showOrHideList(item)"></div> -->
                <img :src="imgSrc.shoppingCarMore" @click.stop="showOrHideList(item)" alt />
                <img :src="imgSrc.sanJiao" v-if="item.showList" class="sanJiao" alt />
                <div class="do-list" v-if="item.showList">
                  <div class="li" @click.stop="delProduct(item)">删除</div>
                  <div class="li" @click.stop="showOrHideDrawer(3,item)">加要求</div>
                  <!-- 出现更改明细弹框 -->
                  <div class="li" @click.stop="showOrHideDrawer(4,item)" v-if="item.is==1">更改明细</div>
                  <!-- <div
                    class="li"
                    @click.stop="showOrHideDrawer(1,item)"
                    v-if="(item.productInfo.prdType == 1 || item.productInfo.prdType == 7 || item.productInfo.prdType == 6) && ((((($store.state.userInfo.authStatusArr.includes(1) || $store.state.userInfo.authStatusArr.includes(3)) && item.at == 0) || ($store.state.userInfo.authStatusArr.includes(2) && (item.at != 2 && item.at != 3))) && item.productInfo.canSeal) || ($store.state.userInfo.authStatus == 4))"
                  >优惠</div> -->
                </div>
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
            <!-- 补单信息 -->
            <div v-if="item.ra" class="requested">{{item.ra}}</div>
          </div>
        </div>
      </div>

      <div class="shopping-cart-content-bottom" layout="row" layout-align="space-between center">
        <div class="amt" layout="row">
          <div class="p m-r-10" layout="row" layout-align="start center">
            <span>购物车金额：</span>
            <span class="num">￥{{amt.allAmt}}</span>
          </div>
          <div class="p" layout="row" layout-align="start center">
            <span>优惠金额：</span>
            <span class="num">￥{{amt.giveAmt}}</span>
          </div>
        </div>
        <div class="btn" layout="row" layout-align="end center">
          <button style="width:100px" @click.stop="showOrHideDrawer(6)">
            批量优惠
          </button>
          <button style="width:100px" @click.stop="showOrHideDrawer(7)">
            批量优惠2
          </button>
          <button style="width:100px" v-if="$store.state.userInfo.authStatusArr.includes(1) && $store.state.userInfo.authStatus!=4" @click.stop="submitShoppingCartAndPayHandle">下单并买单</button>
          <button style="width:100px" @click.stop="submitShoppingCart('')">{{canOrder ? '立即下单' : '未点必须商品'}}</button>
        </div>
      </div>
    </div>

    <!-- 下单倒计时退出 -->
    <div class="num-sub-tips" v-show="showNumSubTips">
      <div class="contain">
        <i
          class="el-icon-close"
          style="position:absolute;top:10px;right:20px;color:#fff;cursor:pointer"
          @click="hideTimeSubHandle()"
        ></i>
        {{logoutCount}}秒后将退出登录！
      </div>
    </div>

    <!-- 单个优惠及其他操作 -->
    <drawerGiveHeMore
      ref="drawerGiveHeMore"
      :status="drawer.status"
      :showDrawer="drawer.showDrawer"
      :currentItemInfo="drawer.currentItemInfo"
      :shoppingCartList="shoppingCartList"
      @showOrHideDrawer="showOrHideDrawer"
    />

    <!-- 单品定制要求 -->
    <drawerChooseRequireInfo
      ref="drawerChooseRequireInfo"
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
import api_auth from "@/api/UtilAuth";
import api_order from "@/api/order";
import common_order from "@/utils/common/order";
import common_book from "@/utils/common/book";

import add from "@/assets/order-img/order_add.png";
import sub from "@/assets/order-img/sub.png";
import addDisabled from "@/assets/order-img/add-disabled.png";
import subDisabled from "@/assets/order-img/sub-disabled.png";
import shoppingCarMore from "@/assets/order-img/shoppingCarMore.png";
import sanJiao from "@/assets/card-imgs/cardOptions/sanjiao.png";

import drawerGiveHeMore from "@/components/order/shoppingCart/drawerGiveHeMore";
import drawerChooseRequireInfo from "@/components/order/drawerMeal/drawerChooseRequireInfo";

// 键盘码 keycode
let downKeyCode = [0, 0]
const ctrlAndShiftCode = [17, 16]

export default {
  data() {
    return {
      isRect: true, // 是否为横屏
      timer: '', // 下单后倒计时退出登录
      showNumSubTips: false, // 倒计时退出模态框
      logoutCount: 3, // 倒计时秒数

      authId: "", // 用户id
      mustOrderPrdId: "", // 必点商品id
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
        status: 1, // 1:优惠  2：自用  3：加要求  4：更改明细  5：批量优惠  6：批量优惠2
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

      // 是否为估清商品及数量限制
      const outOfSomethingPrdList = this.$store.state.cardPageInfo
        .resResultDataObj.prdOutOfSomething;
      const isOutOfSomethingPrd = outOfSomethingPrdList.find(
        item => item.id == info.pid
      );
      if (isOutOfSomethingPrd && isOutOfSomethingPrd.cnt < count) {
        return this.$message.warning(
          "点单数量已超过当前可点估清数量" + isOutOfSomethingPrd.cnt
        );
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
          this.$store.dispatch("getShoppingCount", this);
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

    // 下单 callback 为下单并买单的标识
    async submitShoppingCart(callback) {
      if (!this.canOrder) {
        const prdInfo = this.$store.state.cardPageInfo.resResultDataObj.goodsAroundInfo.find(
          item => item.id == this.mustOrderPrdId
        );
        if(!prdInfo) return this.$message.warning('未找到必点商品')
        this.$parent.$children[0] &&
          this.$parent.$children[0].footNavBarClick &&
          this.$parent.$children[0].footNavBarClick({
            id: 2,
            name: "商品菜单",
            routeName: "orderMealList",
            mustOrderPrdId: this.mustOrderPrdId,
            mustPrdName: prdInfo.name
          });
        return this.$message.warning(`需要点“${prdInfo.name}”才可下单`);
      }
      this.showTips = true
      // this.$confirm("确认下单吗？", "下单", {
      //   distinguishCancelAndClose: true,
      //   confirmButtonText: "确定",
      //   cancelButtonText: "取消"
      // })
      //   .then(async () => {
          const params = {
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64    卡台Id
            shopping_cart_ids: this.shoppingCartList.map(el => el.id) // []int64   要下单的购物车项Id
          };
          if(params.shopping_cart_ids.length == 0) return this.$message.warning('购物车商品为空，请添加商品至购物车再下单！')
          try {
            const res = await api_order.reqPlaceAnOrder(params);
            this.$message.success("下单成功");

            if (res.code === 1) {

              if (callback) {
                this.$parent.$children[0] &&
                this.$parent.$children[0].footNavBarClick &&
                this.$parent.$children[0].footNavBarClick({
                  id: 4,
                  name: "我的点单",
                  routeName: "myOrder"
                });
                return callback()  // 是否为下单并买单
              }

              // this.getShoppingCartData();
              if(this.$store.state.userInfo.authStatus == 4){
                // 收银系统跳转来的点单
                this.$router.replace({name: 'payOrder'})
              } else {
                // 点单系统点单
                this.subSecondLogoutHandle()
              }
            } else {
              this.$message.warning(res.msg);
            }
          } catch (error) {
            console.log("购物车下单失败", error);
          }
          this.showTips = false
        // })
        // .catch(() => {
        //   this.showTips = false
        // });
    },

    // 下单并结账
    submitShoppingCartAndPayHandle(){
      this.submitShoppingCart(() => {
        this.getShoppingCartData()
        for (var i = 0; i < this.$parent.$children.length; i++) {
           if(this.$parent.$children[i].$el.className == 'footBar') {
              this.$parent.$children[i].showOrderListDrawerHandle()
           }
        };
      })
    },

    // 倒计时退出登录
    subSecondLogoutHandle(){
      this.showNumSubTips = true
      this.getShoppingCartData()
      if(this.timer) clearInterval(this.timer)
      this.timer = setInterval(() => {
        this.logoutCount--
        if(this.logoutCount == 0) {
          this.hideTimeSubHandle()
          this.logOutHandle()
          clearInterval(this.timer)
        }
      }, 1000);
    },

    hideTimeSubHandle(){
      this.showNumSubTips = false
      this.logoutCount = 4
      if(this.timer) clearInterval(this.timer)
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
    },

    async logOutHandle() {
      try {
        const res = await api_auth.auth.requestauthlogout();
        if (res.code === 1) {
          // this.$store.commit("updateResResultDataObj", "");
          this.$store.commit("updateUserInfo", "");
          this.$router.replace({
            name: "Thelogin",
            replace: true,
            query: {
              client: "order"
            }
          });
          this.$message.success("退出成功！");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("logout失败", error);
      }
    },

    // -------------单品定制要求end----------------

    // 收银快捷键
    keyHandle(e){
      // alt 或 windows键(防止利用alt切屏)
      if (e.keyCode == 18 || e.keyCode == 91) return e.preventDefault()
      switch (e.type){
        case 'keydown':

        if(downKeyCode.findIndex(item => item == 0) < 0) return

        if (ctrlAndShiftCode.includes(e.keyCode)) {
          downKeyCode[0] = e.keyCode
        } else if (downKeyCode[0] == 0 && downKeyCode[1] == 0) {
          downKeyCode[1] = e.keyCode
        } else if (downKeyCode[0] == e.keyCode && downKeyCode[1] == 0 ){
          // 重复按同一个件
        } else if (downKeyCode[0] != 0 && downKeyCode[1] == 0) {
          downKeyCode[1] = e.keyCode
        }

        this.$nextTick(() => {
          if(downKeyCode[0] == 17 && downKeyCode[1] == 81) {
            //  ctrl + q  // 返回收银首页
            e.preventDefault()
            this.$router.replace({name: 'moneyCard'})
          } else if (downKeyCode[0] == 16 && downKeyCode[1] == 65) {
            // shift + a // 商品菜单
            e.preventDefault()
            this.$parent.$refs.footBarRef &&
            this.$parent.$refs.footBarRef.footNavBarClick &&
            this.$parent.$refs.footBarRef.footNavBarClick({
              id: 2,
              name: "商品菜单",
              routeName: "orderMealList"
            });
          } else if (downKeyCode[0] == 16 && downKeyCode[1] == 68) {
            // shift + d  // 我的点单
            e.preventDefault()
            this.$parent.$refs.footBarRef &&
            this.$parent.$refs.footBarRef.footNavBarClick &&
            this.$parent.$refs.footBarRef.footNavBarClick({
              id: 4,
              name: "商品菜单",
              routeName: "myOrder"
            });
          } else if (downKeyCode[0] == 0 && downKeyCode[1] == 13) {
            // enter  // 立即下单
            if(!this.showTips) {
              e.preventDefault()
              this.submitShoppingCart('')
            }
          } 
        })
          break;

        case 'keyup':
          const index = downKeyCode.findIndex(item => item == e.keyCode)

          if (index > -1) downKeyCode[1] = 0

          if(ctrlAndShiftCode.includes(e.keyCode)) downKeyCode = [0, 0]
          
          break
      }
    },

    // 检测是否为横屏
    getRectVal(){
      const width = screen.availWidth
      const height = screen.availHeight
      this.isRect = width >= height
    },

    // 点单快捷键
    keydownHandle(e) {
      if(e.keyCode == 13) {
        this.$nextTick(() => {
          if (this.drawer.showDrawer) {
            // 批量赠送
            this.$refs.drawerGiveHeMore.onSubmit()
          } else if (this.requireDrawerInfo.showDrawer) {
            // 单品定制要求
            this.$refs.drawerChooseRequireInfo.onSubmit()
          }
        })
      }
    }
  },

  created () {
    setTimeout(() => {
      if (this.$store.state.userInfo.authStatus == 4) {
        document.onkeydown = this.keyHandle
        document.onkeyup = this.keyHandle
      } else {
        document.onkeydown = this.keydownHandle
      }
    }, 200);
  },
  mounted() {
    this.authId = this.$store.state.userInfo.emp_id;
    this.getRectVal()
    this.getShoppingCartData();
    document.body.addEventListener("click", this.showOrHideList);
  },
  components: {
    drawerGiveHeMore,
    drawerChooseRequireInfo
  },
  computed: {
    amt() {
      let allAmt = 0;
      let giveAmt = 0;
      this.shoppingCartList.forEach(el => {
        if (el.at == 2 || el.at == 3 || el.at == 5) {
          // 赠送
          giveAmt += el.pa * 1;
        } else if (el.at == 6) {
          // 自用
        } else {
          allAmt += el.pa * 1;
        }
      });
      return {
        allAmt: allAmt.toFixed(2),
        giveAmt: giveAmt.toFixed(2)
      };
    },

    // 是否点了必点商品
    canOrder() {
      // 卡台状态：4 开台 5 点单未结账 6 部分结账 7 已结账（通过卡台状态判断是否下过单）
      const currentCardAreaId = this.$store.state.orderInfo.currentCardInfo
        .regionId;
      this.mustOrderPrdId = this.$store.state.cardPageInfo.resResultDataObj.areaInfo.find(
        item => item.id == currentCardAreaId
      ).mustOrderPrdId;
      if (this.$store.state.orderInfo.currentCardInfo.bizStatus == 4 && this.$store.state.orderInfo.currentCardInfo.bizType != 3 && this.mustOrderPrdId != 0) {
        // 第一次下单，判断是否点了必点商品
        return this.shoppingCartList.find(
          item => item.pid == this.mustOrderPrdId
        );
      } else {
        return true;
      }
    }
  },
  beforeDestroy() {
    document.onkeydown = null
    document.onkeyup = null
    downKeyCode = [0, 0]
    document.body.removeEventListener("click", this.showOrHideList);
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDialog.less";
@import "../../../style/order/orderMeal/shoppingCart/shoppingCart.less";
</style>

<style scoped>
@import "../../../style/common/elementConfirm.less";
</style>