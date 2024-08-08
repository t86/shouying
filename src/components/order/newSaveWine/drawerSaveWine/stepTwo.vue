<template>
  <div class="step-two">
    <div class="top" layout="row" layout-align="space-between center">
      <div class="left">
        <span>{{ tabIndex == 2 ? phoneNum : customPhoneNum }}</span>
        <span>{{ tabIndex == 2 ? customName : customPhoneName }}</span>
      </div>
      <div class="right" layout="row" layout-align="start center">
        <div class="card-name">{{ checkedOrderInfo.c }}</div>
        <div class="info">
          <span class="date">{{ checkedOrderInfo.o }}</span>
          <span>订位人：{{ checkedOrderInfo.s }}</span>
        </div>
      </div>
    </div>

    <div>
      <Slider :visible="sliderVisible" style="width: 80%; text-align: center" v-if="sliderVisible"  :options="[1, 30, 60, 90, 150, 300, 500]" :current="selectedSaveWineItem.e" @confirm="handleConfirm" @cancel="handleCancel" />
    </div>

    <!-- 存酒内容 -->
    <div class="save-list" layout="row" layout-align="space-between start">
      <div class="left">
        <div class="title fs16 m-t-3 m-b-3">可存酒水</div>
        <div class="table-content">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">名称</div>
                <div class="th">剩余可存数量</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" layout="row" layout-align="space-between center" v-for="item in notAuthWineList"
                :key="item.id">
                <div class="td one-txt-cut" style="font-size: 22px; font-weight: 400;">{{ item.n }}</div>
                <div class="td" style="font-size: 22px; font-weight: 400;" layout="row"
                  layout-align="space-between center">
                  <div class="count">{{ item.c }}</div>
                  <div class="save-icon" :class="{ opacity: !item.canSave }"
                    @click="showChooseWineParamsOfNotAuthHandle(item)">
                    存
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="right">
        <div class="title fs16 m-t-3 m-b-3">存酒单</div>
        <div class="table-content">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">名称</div>
                <div class="th">规格</div>
                <div class="th">每瓶克数</div>
                <div class="th">数量</div>
                <div class="th">有效期</div>
                <div class="th">授权人</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" layout="row" layout-align="space-between center" v-for="item in shoppingCartWineList"
                :key="item.id">
                <div class="td" style="font-size: 22px; font-weight: 400;">{{ item.n }}</div>
                <div class="td" style="font-size: 22px; font-weight: 400;">{{ item.u }}</div>
                <div class="td" style="font-size: 22px; font-weight: 400;">{{ item.g || "-" }}</div>
                <div class="td" style="font-size: 22px; font-weight: 400;" layout="row" layout-align="start center">
                  <img :src="
                    item.c > 1
                      ? require('@/assets/order-img/new_sub.png')
                      : require('@/assets/order-img/new-sub-disabled.png')
                  " @click="
  changeShoppingCartCount(item, Math.max(1, item.c * 1 - 1))
" />
                  <input type="number" :min="1" v-model="item.c" @input="
                    changeShoppingCartCount(item, Math.max(item.c * 1, 1))
                  " />
                  <img :src="
                    (item.a == '-' && !item.disabled) ||
                      (item.a != '-' && item.c < item.ac)
                      ? require('@/assets/order-img/new_order_add.png')
                      : require('@/assets/order-img/new-add-disabled.png')
                  " @click="changeShoppingCartCount(item, item.c * 1 + 1)" />
                </div>
                <div class="td" style="font-size: 22px; font-weight: 400;" layout="row" layout-align="start center">
<!--                  <img :src="hasAuthChangeSaveWineDays? require('@/assets/order-img/new_sub.png'): require('@/assets/order-img/new-sub-disabled.png')" @click="minusSaveWineDays(item)" />-->
                  <input type="number" :min="1" v-model="item.e" @input="" disabled @change="changeSaveWineDays($event, item)" />
<!--                  <img :src="hasAuthChangeSaveWineDays? require('@/assets/order-img/new_order_add.png'): require('@/assets/order-img/new-add-disabled.png')" @click="plusSaveWineDays(item)" />-->
                  <img :src="require('@/assets/img/btn_edit.png')" @click="showSaveWineDays(item)" v-if="hasAuthChangeSaveWineDays"/>
                </div>
                <div class="td" layout="row" layout-align="space-between center">
                  <span style="font-size: 22px; font-weight: 400;">{{ item.a }}</span>
                  <img :src="require('@/assets/order-img/new-delete.png')" @click="changeShoppingCartCount(item, 0)" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <drawerChooseWineInfo v-model="showChooseWineParamsOfNotAuthDrawer" :checkedOrderInfo="checkedOrderInfo"
        :currentWineInfo="currentWineInfo" :maxCount="currentWineCanAddShoppingCartMaxCount"
        @getShoppingCartWineList="getShoppingCartWineList" />

      <drawerAuthSaveWine v-model="showChooseWineParamsOfAuthDrawer" :checkedOrderInfo="checkedOrderInfo"
        @getShoppingCartWineList="getShoppingCartWineList" />
    </div>


    <!-- 底部按钮 -->
    <div class="form-btn" layout="row" layout-align="space-between center">
      <div class="left" layout="row" layout-align="center center">
        <el-button type="primary" @click="showChooseWineParamsOfAuthDrawer = true">授权存酒</el-button>
      </div>
      <div class="right" layout="row" layout-align="center center">
        <el-button type="info" @click="$emit('onCancelDrawer', true)">取消</el-button>
        <el-button type="info" @click="$emit('changeStatus', 1)" style="">返回上一步</el-button>
        <el-button type="primary" @click="saveWineHandle">确定存酒</el-button>
      </div>
    </div>
  </div>
</template>

<script>
import api_saveWine from "@/api/saveWine";

import drawerChooseWineInfo from "./drawerChooseWineInfo.vue";
import drawerAuthSaveWine from "./drawerAuthSaveWine.vue";
import Slider from "../../../slider2";

export default {
  data() {
    return {
      selectedSaveWineItem: {},
      sliderVisible: false,
      // customName: '',
      notAuthWineList: [], // 当前流水可存酒水
      shoppingCartWineList: [], // 存酒购物车酒水
      showChooseWineParamsOfNotAuthDrawer: false,
      currentWineCanAddShoppingCartMaxCount: 0, // 当前流水酒水可加入购物车的最大数量
      currentWineInfo: {}, // 当前流水添加购物车酒水信息

      showChooseWineParamsOfAuthDrawer: false, // 授权存酒
    };
  },
  methods: {
    async handleConfirm(value) {
      this.sliderVisible = false
      this.selectedSaveWineItem.e = value
      let res = await this.updateSaveWineDays(this.selectedSaveWineItem)
      console.log(res)
      if (res.code === 1) {
        this.$message.success('修改有效期成功');
        await this.getShoppingCartWineList();
      } else {
        this.$message.warning(res.msg);
        await this.getShoppingCartWineList();
      }
      console.log('确认值:', value);
    },
    handleCancel() {
      this.sliderVisible = false
      console.log('取消操作');
    },
    async init() {
      await this.getOrderCanSaveWine();
      await this.getShoppingCartWineList();
    },
    // 获取订单流水可存酒水
    async getOrderCanSaveWine() {
      const params = {
        csm_id: this.checkedOrderInfo.id * 1, //    int64    流水Id
        cust_phone_num:
          this.tabIndex == 2
            ? this.phoneNum.toString() || "-"
            : this.customPhoneNum.toString() || "-", // string   客户手机号,用以返还客户姓名
      };

      try {
        const res = await api_saveWine.reqGetCanSaveWineList(params);
        if (res.code == 1) {
          this.notAuthWineList = (res.data.records || []).map((item) => ({
            ...item,
            canSave: true,
          }));
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取订单流水可存酒水列表失败", error);
      }
    },

    // 获取存酒购物车已存酒水
    async getShoppingCartWineList() {
      const params = {
        csm_id: this.checkedOrderInfo.id * 1, //    int64      //CsmId 流水Id
      };
      try {
        const res = await api_saveWine.reqGetShoppingCartWine(params);
        if (res.code == 1) {
          const shoppingCartWineList = (res.data.records || []).map((item) => ({
            ...item,
            disabled: false,
          }));
          this.shoppingCartWineList = JSON.parse(
            JSON.stringify(shoppingCartWineList)
          );

          this.notAuthWineList.forEach((el) => {
            // 非授权商品
            const currentWineList = this.shoppingCartWineList.filter(
              (item) => item.p == el.id && item.a == "-"
            );
            // 非授权酒水总数
            const currentWineAllCount = currentWineList.reduce(
              (a, b) => a + b.c * 1,
              0
            );
            el.canSave = currentWineAllCount < el.c;
          });

          // 设置非授权酒水数量加号按钮是否可点
          this.shoppingCartWineList.forEach((el) => {
            const currentWineAllCount = shoppingCartWineList
              .filter((item) => item.p == el.p && item.a == "-")
              .reduce((a, b) => a + b.c * 1, 0);
            const maxCount = this.notAuthWineList
              .filter((item) => item.id == el.p)
              .reduce((a, b) => a + b.c * 1, 0);
            if (currentWineAllCount >= maxCount) el.disabled = true;
          });
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取订单流水可存酒水列表失败", error);
      }
    },

    // 选择流水中酒水信息
    async showChooseWineParamsOfNotAuthHandle(itemInfo) {
      if (!itemInfo.canSave)
        return this.$message.warning("当前酒水所存数量已达到最大值");
      this.currentWineInfo = { ...itemInfo };
      // 非授权酒水可加入购物车的最大数量
      this.currentWineCanAddShoppingCartMaxCount =
        itemInfo.c -
        this.shoppingCartWineList
          .filter((item) => item.p == itemInfo.id)
          .reduce((a, b) => a + b.c * 1, 0);
      this.showChooseWineParamsOfNotAuthDrawer = true;
    },

    async updateSaveWineDays(item){
      const params = {
        id: item.id * 1, //   int64    购物车Id
        c: item.c * 1, //  int    目标商品数量,0表示删除
        d: item.e * 1
      };
      return await api_saveWine.reqUpdateWineCount(params)
    },

    // 修改购物车数量/删除
    async changeShoppingCartCount(itemInfo, count) {
      console.log(itemInfo);
      if (itemInfo.a == "-") {
        // 非授权酒水
        const currentWineList = this.shoppingCartWineList.filter(
          (item) => item.p == itemInfo.p && item.a == "-"
        );
        // 修改数量之前的当前酒水总量
        const currentWineAllCount = currentWineList.reduce(
          (a, b) => a + b.c * 1,
          0
        );
        // 修改之后的当前酒水总量
        const resultWineAllCount = currentWineAllCount - itemInfo.c + count * 1;

        const maxCount = this.notAuthWineList
          .filter((item) => item.id == itemInfo.p)
          .reduce((a, b) => a + b.c * 1, 0);

        if (resultWineAllCount > maxCount && count > 0) {
          // 超出总量
          return this.$message.warning("当前所修改数量已超过可存最大数量");
        }
      }
      const params = {
        id: itemInfo.id * 1, //   int64    购物车Id
        c: count * 1, //  int    目标商品数量,0表示删除
        d: itemInfo.e * 1
      };

      try {
        const res = await api_saveWine.reqUpdateWineCount(params);
        if (res.code == 1) {
          this.getShoppingCartWineList();
          this.$message.success("修改成功");
        } else {
          this.$message.warning(res.msg);
          this.getShoppingCartWineList();
        }
      } catch (error) {
        console.log("修改购物车数量失败", error);
      }
    },

    async minusSaveWineDays(item){
      console.log(item)
      if(!this.hasAuthChangeSaveWineDays){
        return
      }
      if(item.e > 1) {
        item.e --
        let res = await this.updateSaveWineDays(item)
        console.log(res)
        if (res.code === 1) {
          this.$message.success('修改有效期成功');
          await this.getShoppingCartWineList();
        } else {
          this.$message.warning(res.msg);
          await this.getShoppingCartWineList();
        }
      }
    },
    async plusSaveWineDays(item){
      console.log(item)
      if(!this.hasAuthChangeSaveWineDays){
        return
      }
      item.e++
      let res = await this.updateSaveWineDays(item)
      console.log(res)
      if (res.code === 1) {
        this.$message.success('修改有效期成功');
        await this.getShoppingCartWineList();
      } else {
        this.$message.warning(res.msg);
        await this.getShoppingCartWineList();
      }
    },
    showSaveWineDays(item){
      this.sliderVisible = false
      this.selectedSaveWineItem = item
      this.sliderVisible = true
    },
    async changeSaveWineDays(days,item){
      console.log(days, item)
      let res = await this.updateSaveWineDays(item)
      console.log(res)
      if (res.code === 1) {
        this.$message.success('修改有效期成功');
        await this.getShoppingCartWineList();
      } else {
        this.$message.warning(res.msg);
        await this.getShoppingCartWineList();
      }
    },

    async saveWineHandle() {
      const params = {
        sc_ids: this.shoppingCartWineList.map((item) => item.id * 1), //   []int64    购物车Id列表
        phone_num_auth_code:
          this.tabIndex == 3
            ? ""
            : this.tabIndex == 4
              ? this.superValidate
              : this.phoneValidateStr, //  string  认证手机授权码
        phone_num: this.tabIndex == 3 ? "-" : this.phoneNum, //  string    客户手机号
        cust_name: this.tabIndex == 3 ? "-" : this.customName || "", //  string   客人姓名
        remark_cust_phone: this.tabIndex == 3 ? this.customPhoneNum : "", // string   备注客户手机号, 当酒水存到客服中心的时候
        remark_cust_name: this.tabIndex == 3 ? this.customPhoneName : "-", // string   备注客户姓名, 当酒水存到客服中心的时候
      };
      try {
        const res = await api_saveWine.reqCreateSaveWineOrder(params);
        if (res.code == 1) {
          this.$message.success("存酒成功");
          this.$emit("onCancelDrawer", true);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("新增存酒订单失败", error);
      }
    },
  },
  props: {
    stepTwoInfo: {},
    tabIndex: {
      default: 1, // 1:授权码  2：手机号验证  3：客户中心存酒  4：超级授权码
    },
    phoneNum: "", // 客户手机验证的手机号
    customName: "", // 客户手机号验证中的客户姓名
    customPhoneNum: "", // 客户中心存酒手机号
    customPhoneName: "", // 客户中心存酒客户姓名
    superValidate: "", // 超级授权码
    phoneValidateStr: "",
    checkedOrderInfo: {},
  },
  components: {
    Slider,
    drawerChooseWineInfo,
    drawerAuthSaveWine,
  },
  computed: {
    hasAuthChangeSaveWineDays(){
      return (
          this.$store.state.userInfo.roleIds.includes(2) && this.$store.state.userInfo.sys_modules.includes(83)
      );
    }
  },
  watch: {
    stepTwoInfo: {
      handler(newVal) { },
      deep: true,
      immediate: true,
    },
  },
};
</script>
<style lang="less" scoped>
@import "../../../../style/saveWine/newTable.less";
@import "../../../../style/common/newElementFormBtn.less";
</style>
<style scoped lang="less">
.step-two {
  color: #08080A;

  // 头部
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

  // 列表
  .save-list {
    margin-top: 20px;
    padding: 0 20px;
    height: calc(100vh - 198px);

    // 左侧
    .left {
      width: 36%;
      height: 100%;
      overflow: auto;
      padding-right: 10px;
      box-sizing: border-box;
      border-right: 1px solid rgba(255, 255, 255, 0.2);

      .title {
        font-size: 24px;
        font-family: PingFangSC, PingFang SC;
        font-weight: 400;
        color: #1A1A21;
      }

      .table {
        .tbody {
          height: calc(100vh - 270px);
          overflow: auto;

          .save-icon {
            line-height: 38px;
            text-align: center;

            font-size: 22px;
            color: #fff;
            border-radius: 6px;
            cursor: pointer;
            width: 38px;
            height: 38px;
            background: #3373E8;
            border-radius: 6px;

            &.opacity {
              opacity: 0.3;
            }
          }
        }
      }
    }

    // 右侧
    .right {
      width: 64%;
      height: 100%;
      overflow: auto;
      padding-left: 10px;
      box-sizing: border-box;

      .title {
        font-size: 24px;
        font-family: PingFangSC, PingFang SC;
        font-weight: 400;
        color: #1A1A21;
      }

      .table {
        .tbody {
          height: calc(100vh - 270px);
          overflow: auto;
        }

        .th,
        .td {
          width: 20%;

          &:nth-child(4),
          &:nth-child(5) {
            width: 25%;

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
              font-size: 24px;
              font-family: PingFangSC, PingFang SC;
              font-weight: 500;
              color: #08080A;
              line-height: 32px;
              text-align: center;
              box-sizing: border-box;
            }
          }

          &:nth-child(6) {
            img {
              width: 32px;
              cursor: pointer;
            }
          }
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
      width: 36%;
      padding-right: 10px;
      box-sizing: border-box;
      border-right: 1px solid #C4CBD7;
    }

    .right {
      width: 64%;
      box-sizing: border-box;
    }
  }
}
</style>
