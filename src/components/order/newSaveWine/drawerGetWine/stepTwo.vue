<template>
  <div class="step-two">
    <div class="top" layout="row" layout-align="space-between center">
      <div class="left">
        <span :class="{ 'is-black': isBlack }">{{ phoneNum }}</span>
        <span :class="{ 'is-black': isBlack }">{{ customName }}</span>
      </div>
      <div class="right" layout="row" layout-align="start center">
        <div class="card-name">
          {{ $store.state.orderInfo.saveWineCardInfo.name }}
        </div>
        <div class="info">
          <span class="date">{{
            filterTime($store.state.orderInfo.saveWineCardInfo.openTime)
          }}</span>
          <span>订位人：{{
            getOrderPersonName(
              $store.state.orderInfo.saveWineCardInfo.salesEmpId
            )
          }}</span>
        </div>
      </div>
    </div>

    <!-- 剩余取酒详情  -->
    <div v-if="!showCheckCode || codeCheckDone" :class="{
      'get-list': true,
      'get-list-cloumn': !isRect
    }">
      <div class="left">
        <div layout="row" layout-align="start center" class="title fs16 m-t-3 m-b-3">
          <span class="row-title">剩余取酒详情</span>
          <div class="arrow">
            <div class="bg" layout="row" layout-align="center center">
              <div class="bg-left" @click="scrollHandle('first', 'up')">
                <img :src="require('@/assets/card-imgs/new-arrow-bottom.png')" alt />
              </div>
              <div class="bg-right" @click="scrollHandle('first', 'down')">
                <img :src="require('@/assets/card-imgs/new-arrow-bottom.png')" alt />
              </div>
            </div>
          </div>

        </div>
        <div class="table-content" layout="column">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">名称</div>
                <div class="th">规格</div>
                <div class="th">每瓶克数</div>
                <!-- <div class="th">存酒时间</div>
                <div class="th">过期时间</div> -->
                <div class="th">剩余可取数量</div>
              </div>
            </div>
            <div class="tbody" ref="firstTableRef">
              <div class="tr" layout="row" layout-align="space-between center" v-for="item in WineList" :key="item.id">
                <div class="td" :class="{ 'is-black': isBlack }">

                  <p style="font-size: 22px;font-weight: 400;color: #08080A;"> {{ item.n }}</p>
                  <p style="font-size: 16px;font-weight: 400;color: #40404E;">过期时间：{{ item.e }}</p>
                </div>
                <div class="td" style="display: flex; flex-direction: column;">
                  <p style="font-size: 20px;font-weight: 400;color: #08080A;"> {{ item.u }}</p>
                  <p style="font-size: 16px;font-weight: 400;color: #40404E;">存酒时间：{{ item.i }}</p>
                </div>
                <div class="td" style="font-size: 20px;font-weight: 400;color: #08080A;">{{ item.g || "-" }}</div>
                <div class="td" layout="row" layout-align="space-between center">
                  <div class="count" style="font-size: 24px;font-weight: 400;color: #08080A;">{{ item.c }}</div>
                  <div class="get-icon" :class="{ opacity: !item.canGet }" @click="addWineToShoppingCart(item)">
                    取
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="right">
        <div layout="row" layout-align="start center" class="title fs16 m-t-3 m-b-3"><span class="row-title">取酒详情 </span>
          <div class="arrow">
            <div class="bg" layout="row" layout-align="center center">
              <div class="bg-left" @click="scrollHandle('second', 'up')">
                <img :src="require('@/assets/card-imgs/new-arrow-bottom.png')" alt />
              </div>
              <div class="bg-right" @click="scrollHandle('second', 'down')">
                <img :src="require('@/assets/card-imgs/new-arrow-bottom.png')" alt />
              </div>
            </div>
          </div>
        </div>
        <div class="table-content" layout="column">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">名称</div>
                <div class="th">规格</div>
                <div class="th">每瓶克数</div>
                <div class="th">数量</div>
                <div class="th">操作</div>
              </div>
            </div>
            <div class="tbody" ref="secondTableRef">
              <div class="tr" layout="row" layout-align="space-between center"
                v-for="(item, index) in shoppingCartWineList" :key="item.id">
                <div class="td" :class="{ 'is-black': isBlack }"
                  style="font-size: 20px;font-family: PingFangSC, PingFang SC;font-weight: 400;color: #08080A;">
                  {{ item.n }}
                </div>
                <div class="td"
                  style="font-size: 20px;font-family: PingFangSC, PingFang SC;font-weight: 400;color: #08080A;">{{ item.u
                  }}</div>
                <div class="td"
                  style="font-size: 20px;font-family: PingFangSC, PingFang SC;font-weight: 400;color: #08080A;">{{ item.g
                    || "-" }}</div>
                <div class="td" layout="row" layout-align="start center">
                  <img :src="
                    item.c > 1
                      ? require('@/assets/order-img/new_sub.png')
                      : require('@/assets/order-img/new-sub-disabled.png')
                  " @click="
  changeShoppingCartCount(item, Math.max(item.c * 1 - 1, 1))
" />
                  <input type="number" :class="{ onFocus: focus == index }" @click="focus = index" :min="1"
                    v-model="item.c" @input="changeShoppingCartCount(item, Math.max(item.c, 1))" />
                  <img :src="
                    item.c < item.maxCount
                      ? require('@/assets/order-img/new_order_add.png')
                      : require('@/assets/order-img/new-add-disabled.png')
                  " @click="changeShoppingCartCount(item, item.c * 1 + 1)" />
                </div>
                <div class="td" layout="row" layout-align="space-between center">
                  <img :src="require('@/assets/order-img/new-delete.png')" @click="changeShoppingCartCount(item, 0)" />
                </div>
              </div>
            </div>
          </div>
          <div
          v-if="!isNarrow"
            style="display: flex; flex-direction: column; align-items: center; justify-content: center; margin-top: 30px;padding-bottom:80px" >
            <div v-if="tabIndex == 2" class="cap-content">
              <div class="label">验证码</div>
              <div class="value-content">
                <div class="value">
                  <input v-model="validateVal" :class="{ focus: focus == 'validateVal' }" @click="focus = 'validateVal'"
                    placeholder="请输入验证码" />
                </div>
                <el-button style="margin-left: 10px;
                                  width: 120px;
                                  height: 44px;
                                  background: #374368;
                                  box-shadow: inset 0px 1px 1px 0px rgba(255,255,255,0.3);
                                  border-radius: 8px;font-size: 20px;
                                  font-family: PingFangSC, PingFang SC;
                                  font-weight: 500;
                                  padding: 0;
                                  color: #FFFFFF;" :type="count == 60 ? 'primary' : 'info'" :disabled="count != 60"
                  @click="sendPhoneMessage">{{ btnText }}</el-button>
              </div>

            </div>
            <keyBoard @changeNum="changeNumHandle" :width="389" :itemHeight="64" :itemWidth="64" :landscape="true" />
          </div>
        </div>
      </div>
    </div>
    <div v-else
            style="display: flex; flex-direction: column; align-items: center; justify-content: center; margin-top: 30px;padding-bottom:80px" >
            <div v-if="tabIndex == 2" class="cap-content">
              <div class="label">验证码</div>
              <div class="value-content">
                <div class="value">
                  <input v-model="validateVal" :class="{ focus: focus == 'validateVal' }" @click="focus = 'validateVal'"
                    placeholder="请输入验证码" />
                </div>
                <el-button style="margin-left: 10px;
                                  width: 120px;
                                  height: 44px;
                                  background: #374368;
                                  box-shadow: inset 0px 1px 1px 0px rgba(255,255,255,0.3);
                                  border-radius: 8px;font-size: 20px;
                                  font-family: PingFangSC, PingFang SC;
                                  font-weight: 500;
                                  padding: 0;
                                  color: #FFFFFF;" :type="count == 60 ? 'primary' : 'info'" :disabled="count != 60"
                  @click="sendPhoneMessage">{{ btnText }}</el-button>
              </div>

            </div>
            <keyBoard @changeNum="changeNumHandle" :width="389" :itemHeight="64" :itemWidth="64" :landscape="true" />
          </div>
    <!-- 底部按钮 -->
    <div class="form-btn" layout="row" layout-align="space-between center">
      <div class="left" layout="row" layout-align="end center">
        <!-- <el-button type="primary" @click="showChooseWineParamsOfAuthDrawer=true">授权存酒</el-button> -->
      </div>
      <div class="right" layout="row" layout-align="end center">
        <el-button v-if="!showCheckCode || codeCheckDone" type="info" @click="$emit('onCancelDrawer', true)">取消</el-button>
        <el-button v-else type="info" @click="showCheckCode = false">取消</el-button>
        <el-button v-if="!showCheckCode || codeCheckDone" type="info" @click="$emit('changeStatus', 1)">返回上一步</el-button>
        <el-button v-else type="primary" @click="getCode">下一步</el-button>
        <el-button v-if="isNarrow && !showCheckCode && shoppingCartWineList.length > 0" type="primary" @click="showAuth">获取验证码</el-button>
        <el-button v-if="!isNarrow || codeCheckDone" type="primary" @click="getWineHandle">确定取酒</el-button>
      </div>
    </div>
  </div>
</template>

<script>
import api_saveWine from "@/api/saveWine";
import keyBoard from "@/components/common/newKeyBoard.vue";
import api_vip from "@/api/vip";
export default {
  data() {
    return {
      customName: "",
      isBlack: false,
      WineList: [], // 当前流水可取酒水
      shoppingCartWineList: [], // 存酒购物车酒水
      focus: -1,

      timer: null,
      count: 60, // 验证码倒计时
      validateVal: "", // 验证码
      isRect: window.innerWidth >= 1024, // 屏幕是否超过1400
      is1920: window.innerWidth >= 1920,
      showCheckCode: false,
      codeCheckDone: false,
    };
  },
  methods: {
    init() {
      console.log(window.innerWidth)
      this.shoppingCartWineList = [];
      this.getOrderCanGetWine();
    },

    // 键盘
    // 根据currentInfo的c设置键盘输入，不能超过c的值
    changeNumHandle(value) {
      if (this.focus == -1) {
        return;
      }
      let currentInfo;
      let orginNum = 0;
      if (this.focus != "validateVal") {
        currentInfo = this.shoppingCartWineList[this.focus];
        orginNum = currentInfo.maxCount;
        if (!currentInfo) return;
      }
      switch (value) {
        case 11: // 清空
          if (this.focus == "validateVal") {
            this.validateVal = "";
          } else {
            currentInfo.c = 0;
          }
          break;
        case 10: // 回退(
          if (this.focus == "validateVal") {
            this.validateVal = this.validateVal
              .toString()
              .slice(0, this.validateVal.toString().length - 1);
          } else {
            currentInfo.c =
              currentInfo.c
                .toString()
                .slice(0, currentInfo.c.toString().length - 1) * 1;
          }
          break;
        default:
          if (this.focus == "validateVal") {
            this.validateVal = this.validateVal.toString() + value * 1;
          } else {
            currentInfo.c =
              currentInfo.c == 0
                ? value * 1
                : currentInfo.c.toString() + value * 1;
            if (currentInfo.c * 1 > orginNum) {
              currentInfo.c = orginNum;
            }
          }
          break;
      }
      this.$forceUpdate();
    },

    scrollHandle(type, direction) {
      let dom = this.$refs[type + "TableRef"];
      const step = 200;
      const scrollTop =
        direction === "down" ? dom.scrollTop + step : dom.scrollTop - step;
      dom.scrollTo(0, scrollTop);
    },

    // 获取订单流水可存酒水
    async getOrderCanGetWine() {
      const params = {
        phone_num: this.phoneNum.toString(), // string   客户手机号,用以返还客户姓名
        key: "", //   string     过滤关键字
      };

      try {
        const res = await api_saveWine.reqGetCanGetFromLib(params);
        if (res.code == 1) {
          this.customName = res.data.cust_name || "";
          this.isBlack = res.data.is_black == 1;
          this.WineList = (res.data.records || []).map((item) => ({
            ...item,
            canGet: true,
          }));
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取可取酒水列表失败", error);
      }
    },

    // 选择流水中酒水信息
    addWineToShoppingCart(itemInfo) {
      if (!itemInfo.canGet)
        return this.$message.warning("当前酒水可取数量已达到最大值");
      const hasItem = this.shoppingCartWineList.find(
        (item) => item.id == itemInfo.id
      );
      if (hasItem) {
        this.shoppingCartWineList = this.shoppingCartWineList.map((item) => ({
          ...item,
          c: item.id == itemInfo.id ? itemInfo.c : item.c,
        }));
      } else {
        this.shoppingCartWineList = [
          ...this.shoppingCartWineList,
          { ...itemInfo, maxCount: itemInfo.c },
        ];
      }
      this.WineList = this.WineList.map((item) => ({
        ...item,
        canGet: item.id == itemInfo.id ? false : item.canGet,
      }));
    },

    // 修改购物车数量/删除
    changeShoppingCartCount(itemInfo, count) {
      if (itemInfo.maxCount <= count) {
        itemInfo.c = itemInfo.maxCount;
      } else if (count <= 0) {
        // 删除
        const index = this.shoppingCartWineList.findIndex(
          (item) => item.id == itemInfo.id
        );
        if (index > -1) {
          this.shoppingCartWineList.splice(index, 1);
        }
        itemInfo.c = count;
      } else {
        itemInfo.c = count;
      }

      this.WineList = this.WineList.map((item) => ({
        ...item,
        canGet: item.id == itemInfo.id ? itemInfo.c < item.c : item.canGet,
      }));
    },
    getCode(){
      if (this.tabIndex == 2 && !this.validateVal) {
        this.$message.warning("请先验证手机验证码");
        return;
      }
      this.codeCheckDone = true;
    },
    showAuth(){
      this.showCheckCode = true;
      this.focus = "validateVal";
    },
    async getWineHandle() {

      try {
        if (this.tabIndex == 2 && !this.validateVal) {
          this.$message.warning("请先验证手机验证码");
          return;
        }
        let phone_num_auth_code = "";
        if (this.tabIndex == 1) {
          phone_num_auth_code = this.phoneValidateStr;
        } else if (this.tabIndex == 2) {
          phone_num_auth_code = await this.validatePhoneInfo();
          if (!phone_num_auth_code) return;
        } else if (this.tabIndex == 3) {
          phone_num_auth_code = this.superValidate;
        }
        const params = {
          seat_id: this.$store.state.orderInfo.saveWineCardInfo.id * 1, // int64    卡台Id
          invt_ids: this.shoppingCartWineList.map((item) => item.id * 1), //   []int64   存酒库存Id列表
          prd_cnts: this.shoppingCartWineList.map((item) => item.c * 1), //  []int  对应存酒库存Id的取酒商品数量
          phone_num_auth_code: phone_num_auth_code, // string  认证手机授权码
          phone_num: this.phoneNum, //  string  取酒客户手机号
        };
        const res = await api_saveWine.reqGetWineToNextLib(params);
        if (res.code == 1) {
          this.$message.success("取酒成功");
          this.$emit("onCancelDrawer", true);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("新增取酒订单失败", error);
      }
    },

    getOrderPersonName(orderPersonId) {
      return (
        (this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo.find(
          (el) => el.id === orderPersonId
        ) &&
          this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo.find(
            (el) => el.id === orderPersonId
          ).name) ||
        "散客"
      );
    },
    filterTime(timeNumber) {
      if (!timeNumber) return "";
      const month = timeNumber.slice(4, 6);
      const day = timeNumber.slice(6, 8);
      const hour = timeNumber.slice(8, 10);
      const minute = timeNumber.slice(10, 12);
      return `${month}/${day} ${hour}:${minute}`;
    },

    // 发送验证码
    async sendPhoneMessage() {
      if (this.count != 60) return;
      const params = {
        t: 200, //  int   操作类型 101 创建记名卡 102 会员卡修改绑定手机 103 会员卡绑定手机  105 微信端客人绑定安全手机  200  验证获取客人会员卡结账
        m: this.phoneNum, //  string   手机号
      };
      if (params.m.length != 11)
        return this.$message.warning("请输入正确的11位手机号");
      try {
        const res = await api_vip.reqSendPhoneMsg(params);
        if (res.code == 1) {
          this.$message.success("验证码发送成功");
          this.count--;
          this.loopSecond();
          this.$sessionStorage.setItem(
            "secondGetWineCount",
            (+new Date()).toString()
          );
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("发送验证码失败", error);
      }
    },

    // 倒计时
    loopSecond() {
      if (this.timer) clearInterval(this.timer);
      this.timer = setInterval(() => {
        this.count--;
        if (this.count == 0) {
          clearInterval(this.timer);
          this.count = 60;
        }
      }, 1000);
    },

    // 手机号验证
    async validatePhoneInfo() {
      const params = {
        m: this.phoneNum, //   string    手机号
        c: this.validateVal, //    string   验证码
      };

      if (params.c.length != 5) {
        this.$message.warning("请输入正确的五位验证码");
        return false;
      }
      try {
        const res = await api_vip.reqValidatePhoneMsg(params);
        if (res.code == 1) {
          return res.data.c;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("验证手机验证码失败", error);
      }
    },
  },
  props: {
    tabIndex: {
      default: 1,
    },
    stepTwoInfo: {},
    phoneNum: "",
    superValidate: "",
    phoneValidateStr: "",
  },
  computed: {
    btnText() {
      return this.count == 60 ? "发送验证码" : this.count + "s后发送";
    },
    isNarrow() {
      return window.innerWidth < 800 && this.tabIndex == 2;
    },
  },
  components: {
    keyBoard,
  },
};
</script>
<style lang="less" scoped>
@import "../../../../style/saveWine/newTable.less";
@import "../../../../style/common/newElementFormBtn.less";
</style>
<style scoped lang="less">
.step-two {
  // 头部
  color: #08080A;

  .top {
    background-color: #11182d;
    background: #ECEFF4;
    border-radius: 6px;
    height: 42px;
    padding: 0 16px;

    .left {
      font-size: 24px;
      font-family: PingFangSC, PingFang SC;
      font-weight: 500;
      color: #08080A;
    }

    .right {
      .card-name {
        font-size: 32px;
        font-family: PingFangSC, PingFang SC;
        font-weight: 500;
        color: #08080A;
        padding-right: 20px;
        position: relative;

        &:after {
          content: "";
          position: absolute;
          right: 0;
          top: 50%;
          width: 1px;
          height: 30px;
          background: #989FAF;
          transform: translateY(-50%);
        }
      }

      .info {
        padding-left: 20px;

        span {
          font-size: 16px;
          font-family: PingFangSC, PingFang SC;
          font-weight: 400;
          color: #08080A;

          &.date {
            margin-right: 20px;
          }
        }
      }
    }
  }

  .is-black {
    color: red;
  }

  // 列表
  .get-list {
    padding: 0 20px;
    height: calc(100vh - 178px);
    display: flex;
    flex-wrap: wrap;
    justify-content: space-between;

    .title {
      justify-content: space-between;
    }

    // 左侧
    .left {
      overflow: auto;
      box-sizing: border-box;
      flex-basis: 350px;
      flex-grow: 1;

      // border-right: 1px solid rgba(255, 255, 255, 0.2);
      .row-title {
        font-size: 24px;
        font-family: PingFangSC, PingFang SC;
        font-weight: 400;
        color: #1A1A21;
      }

      .table {
        width: 100%;

        .tbody {
          height: calc(100vh - 300px);
          overflow: auto;
          scroll-behavior: smooth;

          .get-icon {
            width: 38px;
            height: 38px;
            background: #3373E8;
            border-radius: 8px;
            font-size: 22px;
            font-family: PingFangSC, PingFang SC;
            font-weight: 600;
            color: #FFFFFF;
            text-align: center;
            line-height: 38px;
            cursor: pointer;

            &.opacity {
              background: rgba(51, 115, 232, 0.3);
              color: rgba(255, 255, 255, 0.3);
            }
          }
        }
      }
    }

    // 取酒侧
    .right {
      overflow: auto;
      box-sizing: border-box;
      margin-left: 10px;
      flex-basis: 280px;
      flex-grow: 1;

      .row-title {
        font-size: 24px;
        font-family: PingFangSC, PingFang SC;
        font-weight: 400;
        color: #1A1A21;
      }

      .table {
        width: 100%;
        height: calc(100vh - 400px);

        .tbody {
          height: 200px;
          overflow: auto;
          scroll-behavior: smooth;
        }

        .th,
        .td {
          width: 20%;

          &:nth-child(4) {
            width: 30%;

            img {
              width: 32px;
              cursor: pointer;
            }

            input {
              width: 68px;
              height: 32px;
              background: #FAFAFC;
              border-radius: 24px;
              border: 1px solid #C4CBD7;
              margin: 0 4px;
              font-size: 24px;
              font-family: PingFangSC, PingFang SC;
              font-weight: 500;
              color: #08080A;
              text-align: center;
              line-height: 32px;
            }

            // .onFocus {
            //   border: 1px solid #32b9ff;
            // }
          }

          &:nth-child(5) {
            img {
              width: 32px;
              cursor: pointer;
            }
          }
        }
      }

      .arrow {
        right: 300px;
      }
    }

    .arrow {
      width: 120px;
      height: 60px;
      cursor: pointer;

      .bg {

        .bg-left,
        .bg-right {
          width: 46px;
          height: 40px;
          background: #FFFFFF;
          // box-shadow: inset 0px 1px 1px 0px #2775BA;
          text-align: center;
          box-shadow: 0px 4px 4px 0px rgba(0, 0, 0, 0.1);
          border: 1px solid #989FAF;

          img {
            width: 20px;
            margin-top: 10px;
          }
        }

        .bg-left {
          border-radius: 8px 0px 0px 8px;
          border-right: none;

          img {
            transform: rotate(180deg);
          }
        }

        .bg-right {
          border-radius: 0 8px 8px 0;
        }
      }
    }

    
  }

  
  //  箭头
  .cap-content {
    display: flex;
    flex-direction: column;
    margin-bottom: 24px;
    .label {
      font-size: 24px;
      font-family: PingFangSC, PingFang SC;
      font-weight: 400;
      color: #1A1A21;
    }

    .value-content {
      display: flex;
      margin-top: 16px;

      .label {
        width: 100px;
      }

      .value {
        input {
          width: 256px;
          height: 44px;
          background: #FAFAFC;
          border-radius: 8px;
          border: 1px solid #C4CBD7;
          font-size: 20px;
          font-family: PingFangSC, PingFang SC;
          font-weight: 400;
          color: #08080A;
          box-sizing: border-box;
          padding-left: 12px;

          &:focus {
            border: 2px solid #3373E8;
          }

          &::placeholder {
            color: #7A7A7A;
          }
        }
      }
    }
  }

  .get-list-cloumn {
    flex-direction: column;
    flex-wrap: nowrap;
  }

  .form-btn {
    width: 100%;
    box-sizing: border-box;
    padding: 0 20px;

    .left {
      height: 100%;
      width: 50%;
      padding-right: 10px;
      box-sizing: border-box;
      // border-right: 1px solid rgba(255, 255, 255, 0.2);
    }

    .right {
      width: 50%;
      box-sizing: border-box;
    }
  }

  @media (orientation: portrait) {
    .get-list {
      .right {
        margin-top: 20px;
        padding-bottom: 100px;

        .table {
          height: calc(50vh - 100px);
        }
      }

      .left {
        .table {
          height: calc(50vh - 100px);
        }
      }

    }
  }
}
</style>
