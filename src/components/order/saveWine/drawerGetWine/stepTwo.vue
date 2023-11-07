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
          <span
            >订位人：{{
              getOrderPersonName(
                $store.state.orderInfo.saveWineCardInfo.salesEmpId
              )
            }}</span
          >
        </div>
      </div>
    </div>

    <!-- 剩余取酒详情 -->
    <div class="get-list">
      <div class="left">
        <div class="title fs16 m-t-3 m-b-3">剩余取酒详情</div>
        <div class="table-content" layout="column">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">名称</div>
                <div class="th">规格</div>
                <div class="th">每瓶克数</div>
                <div class="th">存酒时间</div>
                <div class="th">过期时间</div>
                <div class="th">剩余可取数量</div>
              </div>
            </div>
            <div class="tbody" ref="firstTableRef">
              <div
                class="tr"
                layout="row"
                layout-align="space-between center"
                v-for="item in WineList"
                :key="item.id"
              >
                <div class="td" :class="{ 'is-black': isBlack }">
                  {{ item.n }}
                </div>
                <div class="td">{{ item.u }}</div>
                <div class="td">{{ item.g || "-" }}</div>
                <div class="td">{{ item.i }}</div>
                <div class="td">{{ item.e }}</div>
                <div
                  class="td"
                  layout="row"
                  layout-align="space-between center"
                >
                  <div class="count">{{ item.c }}</div>
                  <div
                    class="get-icon"
                    :class="{ opacity: !item.canGet }"
                    @click="addWineToShoppingCart(item)"
                  >
                    取
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="arrow">
            <div class="bg" layout="row" layout-align="center center">
              <div class="bg-left" @click="scrollHandle('first', 'up')">
                <img :src="require('@/assets/order-img/arrowBottom.png')" alt />
              </div>
              <div class="bg-right" @click="scrollHandle('first', 'down')">
                <img :src="require('@/assets/order-img/arrowBottom.png')" alt />
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="right">
        <div class="title fs16 m-t-3 m-b-3">取酒详情</div>
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
              <div
                class="tr"
                layout="row"
                layout-align="space-between center"
                v-for="(item, index) in shoppingCartWineList"
                :key="item.id"
              >
                <div class="td" :class="{ 'is-black': isBlack }">
                  {{ item.n }}
                </div>
                <div class="td">{{ item.u }}</div>
                <div class="td">{{ item.g || "-" }}</div>
                <div class="td" layout="row" layout-align="start center">
                  <img
                    :src="
                      item.c > 1
                        ? require('@/assets/order-img/sub.png')
                        : require('@/assets/order-img/sub-disabled.png')
                    "
                    @click="
                      changeShoppingCartCount(item, Math.max(item.c * 1 - 1, 1))
                    "
                  />
                  <input
                    type="number"
                    :class="{ onFocus: focus == index }"
                    @click="focus = index"
                    :min="1"
                    v-model="item.c"
                    @input="changeShoppingCartCount(item, Math.max(item.c, 1))"
                  />
                  <img
                    :src="
                      item.c < item.maxCount
                        ? require('@/assets/order-img/order_add.png')
                        : require('@/assets/order-img/add-disabled.png')
                    "
                    @click="changeShoppingCartCount(item, item.c * 1 + 1)"
                  />
                </div>
                <div
                  class="td"
                  layout="row"
                  layout-align="space-between center"
                >
                  <img
                    :src="require('@/assets/order-img/delete.png')"
                    @click="changeShoppingCartCount(item, 0)"
                  />
                </div>
              </div>
            </div>
          </div>
          <div class="arrow">
            <div class="bg" layout="row" layout-align="center center">
              <div class="bg-left" @click="scrollHandle('second', 'up')">
                <img :src="require('@/assets/order-img/arrowBottom.png')" alt />
              </div>
              <div class="bg-right" @click="scrollHandle('second', 'down')">
                <img :src="require('@/assets/order-img/arrowBottom.png')" alt />
              </div>
            </div>
          </div>
          <div
            v-if="tabIndex == 2"
            class="coll"
            layout="row"
            layout-align="start center"
            style="margin-top: 10px"
          >
            <div class="label">验证码</div>
            <div class="value">
              <input
                v-model="validateVal"
                :class="{ focus: focus == 'validateVal' }"
                @click="focus = 'validateVal'"
                placeholder="请输入验证码"
              />
            </div>
            <el-button
              style="margin-left: 10px"
              :type="count == 60 ? 'primary' : 'info'"
              :disabled="count != 60"
              size="small"
              @click="sendPhoneMessage"
              >{{ btnText }}</el-button
            >
          </div>

          <keyBoard
            class="kebBoard"
            :itemWidth="66"
            :width="204"
            @changeNum="changeNumHandle"
          />
        </div>
      </div>
    </div>

    <!-- 底部按钮 -->
    <div class="form-btn" layout="row" layout-align="space-between center">
      <div class="left" layout="row" layout-align="end center">
        <!-- <el-button type="primary" @click="showChooseWineParamsOfAuthDrawer=true">授权存酒</el-button> -->
      </div>
      <div class="right" layout="row" layout-align="end center">
        <el-button type="info" @click="$emit('onCancelDrawer', true)"
          >取消</el-button
        >
        <el-button type="info" @click="$emit('changeStatus', 1)"
          >返回上一步</el-button
        >
        <el-button type="primary" @click="getWineHandle">确定取酒</el-button>
      </div>
    </div>
  </div>
</template>

<script>
import api_saveWine from "@/api/saveWine";
import keyBoard from "@/components/common/keyBoard.vue";
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
    };
  },
  methods: {
    init() {
      this.shoppingCartWineList = [];
      this.getOrderCanGetWine();
    },

    // 键盘
    changeNumHandle(value) {
      if (this.focus == -1) {
        return;
      }
      let currentInfo;
      if (this.focus != "validateVal") {
        currentInfo = this.shoppingCartWineList[this.focus];
        if (!currentInfo) return;
      }
      switch (value) {
        case 10: // 清空
          if (this.focus == "validateVal") {
            this.validateVal = "";
          } else {
            currentInfo.c = 0;
          }
          break;
        case 12: // 回退(
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

    async getWineHandle() {
      
      try {
        if(this.tabIndex == 2 && !this.validateVal){
        this.$message.warning("请先验证手机验证码");
        return;
      }
      let phone_num_auth_code = "";
      if (this.tabIndex == 1){
        phone_num_auth_code = this.phoneValidateStr;
      } else if (this.tabIndex == 2) {
        phone_num_auth_code =  await this.validatePhoneInfo();
        if(!phone_num_auth_code) return;
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
  },
  components: {
    keyBoard,
  },
};
</script>
<style lang="less" scoped>
@import "../../../../style/saveWine/table.less";
@import "../../../../style/common/elementFormBtn.less";
</style>
<style scoped lang="less">
.step-two {
  color: rgba(255, 255, 255, 0.8);
  font-size: 14px;

  // 头部
  .top {
    background-color: #11182d;
    padding: 0 20px 20px;
    .left {
      font-size: 24px;
      color: #fff;
    }
    .right {
      .card-name {
        color: #fff;
        font-size: 24px;
        padding-right: 20px;
        position: relative;
        &:after {
          content: "";
          position: absolute;
          right: 0;
          top: 0;
          width: 1px;
          height: 100%;
          background: rgba(255, 255, 255, 0);
          // background: linear-gradient(
          //   180deg,
          //   rgba(255, 255, 255, 0) 0%,
          //   #ffffff 53%,
          //   rgba(255, 255, 255, 0) 100%
          // );
          opacity: 0.5;
        }
      }

      .info {
        padding-left: 20px;
        span {
          font-size: 14px;
          color: #aed8ff;

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
    // 左侧
    .left {
      overflow: auto;
      box-sizing: border-box;
      width: 40%;
      // border-right: 1px solid rgba(255, 255, 255, 0.2);

      .table {
        width: 100%;
        .tbody {
          height: calc(70vh - 200px);
          overflow: auto;
          scroll-behavior: smooth;
          .get-icon {
            width: 36px;
            height: 28px;
            line-height: 28px;
            text-align: center;
            font-size: 18px;
            color: #fff;
            background: #4b89ff;
            border-radius: 6px;
            cursor: pointer;
            &.opacity {
              opacity: 0.2;
            }
          }
        }
      }
    }
    // 右侧
    .right {
      overflow: auto;
      box-sizing: border-box;
      height: 100%;
      margin-left: 10px;
      flex: 1;
      .table {
        width: calc(100% - 250px);
        .tbody {
          height: calc(50vh - 200px);
          overflow: auto;
          scroll-behavior: smooth;
        }
        .th,
        .td {
          width: 20%;
          &:nth-child(4) {
            width: 30%;
            img {
              width: 20px;
              cursor: pointer;
            }
            input {
              width: 50px;
              height: 26px;
              border-radius: 13px;
              margin: 0 6px;
              font-size: 14px;
              text-align: center;
              box-sizing: border-box;
            }
            .onFocus {
              border: 1px solid #32b9ff;
            }
          }
          &:nth-child(5) {
            img {
              width: 20px;
              cursor: pointer;
            }
          }
        }
      }
      .arrow {
        right: 300px;
      }
      .kebBoard {
        position: absolute;
        right: 0;
        top: 0;
      }
      .label {
        width: 50px;
      }
      .value {
        position: relative;
        flex-wrap: nowrap;
        flex-shrink: 0;
        width: 120px;
        input {
          width: 108px;
          height: 36px;
          background: rgba(0, 0, 0, 0.2);
          border-radius: 8px;
          border: 1px solid rgba(255, 255, 255, 0.15);
          padding: 0 10px;
          box-sizing: border-box;
          margin-right: 10px;
          &:focus {
            background: rgba(0, 0, 0, 0.2);
            border: 1px solid #32b9ff;
            box-shadow: 0px 0px 8px 0px rgba(26, 137, 255, 0.8);
          }
        }

        .focus {
          background: rgba(0, 0, 0, 0.2);
          border: 1px solid #32b9ff;
          box-shadow: 0px 0px 8px 0px rgba(26, 137, 255, 0.8);
        }
      }
      .focus {
        background: rgba(0, 0, 0, 0.2);
        border: 1px solid #32b9ff;
        box-shadow: 0px 0px 8px 0px rgba(26, 137, 255, 0.8);
      }
    }

    //  箭头
    .arrow {
      width: 120px;
      height: 60px;
      cursor: pointer;

      .bg {
        margin-top: 10px;

        .bg-left,
        .bg-right {
          width: 46px;
          height: 40px;
          background: #0d172d;
          box-shadow: inset 0px 1px 1px 0px #2775ba;
          text-align: center;

          img {
            width: 20px;
            margin-top: 10px;
          }
        }

        .bg-left {
          border-radius: 30px 0px 0px 30px;

          img {
            transform: rotate(180deg);
          }
        }

        .bg-right {
          border-radius: 0 30px 30px 0;
        }
      }
    }
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
}
</style>
