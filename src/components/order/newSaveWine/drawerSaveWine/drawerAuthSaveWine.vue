<template>
  <div>
    <el-drawer title="授权存酒" append-to-body :visible.sync="show" direction="rtl" size="95%" :before-close="onCancelDrawer">
      <div class="content">
        <div class="session m-b-10">
          <div v-if="status == 1" layout="row" layout-align="space-between center">
            <div class="left-area">
              <div class="nav" layout="row" layout-align="start start">
                <div class="nav-left">
                  <ul class="first-menu" ref="firstMenuRef">
                    <li :class="{ active: firstCategoryActiveId === item.id }" v-for="(item, index) in firstCategoryList"
                      :key="index" @click="changeFirstCategory(item)">
                      <span>{{ item.n }}</span>
                    </li>
                  </ul>
                  <li class="arrow">
                    <div class="bg" layout="row" layout-align="center center">
                      <div class="bg-left" @click="scrollHandle('first', 'up')">
                        <img :src="require('@/assets/order-img/arrow-Bottom.png')" alt />
                      </div>
                      <div class="bg-right" @click="scrollHandle('first', 'down')">
                        <img :src="require('@/assets/order-img/arrow-Bottom.png')" alt />
                      </div>
                    </div>
                  </li>
                </div>
                <div class="nav-right">
                  <ul class="second-menu" ref="secondMenuRef">
                    <li :class="{ active: secondCategoryActiveId === item.id }"
                      v-for="(item, index) in secondCategoryList" :key="index" @click="changeSecondCategory(item.id)">
                      <div class="item" layout="row" layout-align="center center">
                        <span>{{ item.n }}</span>
                      </div>
                    </li>
                  </ul>
                  <li class="arrow">
                    <div class="bg" layout="row" layout-align="center center">
                      <div class="bg-left" @click="scrollHandle('second', 'up')">
                        <img :src="require('@/assets/order-img/arrow-Bottom.png')" alt />
                      </div>
                      <div class="bg-right" @click="scrollHandle('second', 'down')">
                        <img :src="require('@/assets/order-img/arrow-Bottom.png')" alt />
                      </div>
                    </div>
                  </li>
                </div>
              </div>
              <div class="prd-list" ref="cardListRef" layout="row" layout-align="center start">
                <ul class="center-type" :style="{ width: centerType + 'px' }" layout="row" layout-align="start start">
                  <li class="prd-item" v-for="item in productList"
                    :key="item.id" @click="chooseWindInfoHandle(item)">
                    <div class="prd-item-div">
                      <div class="item-img" v-if="pic_show">
                        <img class="item-img"
                          :src="item.picName ? pic_prefix_url + item.picName : require('@/assets/order-img/defaultImg.png')" />
                      </div>
                      <span>{{ item.n }}</span>
                      <!-- <p class="english-name one-txt-cut">{{ item.nameEng }}</p> -->
                      <img :src="require('@/assets/order-img/fangdatu.png')" class="fangda"
                        @click.stop="clickDescImage(item)" v-if="pic_show" />
                    </div>
                  </li>
                </ul>
                <!-- arrow -->
                <div class="arrow" style="top: 0px">
                  <div class="bg" layout="row" layout-align="center center">
                    <div class="bg-left" @click="scrollArrowHandle('up')">
                      <img :src="require('@/assets/order-img/arrow-Bottom.png')" alt />
                    </div>
                    <div class="bg-right" @click="scrollArrowHandle('down')">
                      <img :src="require('@/assets/order-img/arrow-Bottom.png')" alt />
                    </div>
                  </div>
                </div>
              </div>
              <p v-if="productList.length == 0" class="tips">暂无数据</p>
            </div>

            <div class="right-area">
              <div class="title">所选列表</div>
              <div class="table-content">
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
                  <div class="tbody">
                    <div class="tr" layout="row" layout-align="space-between center" v-for="item in resultWineList"
                      :key="item.id">
                      <div class="td one-txt-cut tdfs">{{ item.name }}</div>
                      <div class="td tdfs">
                        {{
                          item.selectVal == 1 ? "整瓶" : item.selectVal + "瓶"
                        }}
                      </div>
                      <div class="td tdfs">{{ item.allWeight || "-" }}</div>
                      <div class="td " layout="row" layout-align="start center">
                        <img :src="
                          item.count > 1
                            ? require('@/assets/order-img/new_sub.png')
                            : require('@/assets/order-img/new-sub-disabled.png')
                        " @click="item.count = Math.max(item.count - 1, 1)" />
                        <input type="number" :min="1" v-model="item.count" />
                        <img :src="require('@/assets/order-img/new_order_add.png')" @click="item.count++" />
                      </div>
                      <div class="td" layout="row" layout-align="start center">
                        <img @click="deleteWineHandle(item)" :src="require('@/assets/order-img/new-delete.png')" />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- 授权 -->
          <div v-else class="authorization">
            <ul layout="row" layout-align="center start">
              <li class="authorization-left">
                <p class="p-b-2" style="font-size: 24px;
      font-family: PingFangSC, PingFang SC;
      font-weight: 400;
      color: #1A1A21;">授权商品和数量</p>
                <div class="table">
                  <div class="thead">
                    <div class="tr" layout="row" layout-align="start start">
                      <div class="th">序号</div>
                      <div class="th">商品名称</div>
                      <div class="th">规格</div>
                      <div class="th">每瓶克数</div>
                      <div class="th">数量</div>
                    </div>
                  </div>
                  <div class="tbody">
                    <div class="tr" layout="row" layout-align="start start" v-for="(item, index) in resultWineList"
                      :key="item.id">
                      <div class="td">{{ index + 1 }}</div>
                      <div class="td one-txt-cut">{{ item.name }}</div>
                      <div class="td">
                        {{
                          item.selectVal == 1 ? "整瓶" : item.selectVal + "瓶"
                        }}
                      </div>
                      <div class="td">{{ item.allWeight || "-" }}</div>
                      <div class="td">{{ item.count }}</div>
                    </div>
                  </div>
                </div>
              </li>
              <li class="authorization-right">
                <authorization :authorizationInfo="authorizationInfo"
                  @updateAuthorizationInfo="updateAuthorizationInfo" />
              </li>
            </ul>
          </div>

          <!-- 选择酒水详细信息 -->
          <drawerChooseWineInfo v-model="showChooseDrawer" :type="2" :currentWineInfo="currentWineInfo"
            @addAuthWineHandle="addAuthWineHandle" />
        </div>
        <!-- 提交按钮 -->
        <div class="form-btn" layout="row" layout-align="center center">
          <el-button type="info" @click.stop="onCancelDrawer">取消</el-button>
          <el-button type="primary" v-if="status == 2" @click.stop="onSubmit('self')">自己授权</el-button>
          <el-button type="primary" @click.stop="onSubmit('another')">授权</el-button>
        </div>
      </div>

      <ImagePreview :dialogVisible="dialogVisible" :imgSrc="bigImageUrl" @handleCloseClick="handleCloseClick" />
    </el-drawer>
  </div>
</template>

<script>
import eventVue from "@/utils/eventVue";
const cardWidth = 272;
import api_saveWine from "@/api/saveWine";
import drawerChooseWineInfo from "./drawerChooseWineInfo.vue";
import authorization from "@/components/order/newShoppingCart/authorization";
import ImagePreview from "@/components/ImagePreview";
import md5 from "js-md5";
export default {
  data() {
    return {
      status: 1, // 1:选择商品   2：授权
      centerType: 100, // 卡台版心宽度

      keyword: "",
      firstCategoryList: [], // 所有一级分类列表数据集合
      secondCategoryList: [], // 当前一级分类下二级分类列表数据集合
      firstCategoryActiveId: "",
      secondCategoryActiveId: "",
      productList: [], // 当前展示出来的商品
      productListAll: [], // 当前有效可点的商品/套餐列表

      showChooseDrawer: false, //  选择酒水drawer
      currentWineInfo: {},

      resultWineList: [],

      // 授权
      authorizationInfo: {
        userName: "",
        passWord: "",
      },
      pic_prefix_url: "",
      dialogVisible: false,
      bigImageUrl: "",
      pic_show: false
    };
  },
  methods: {
    getPicUrl() {
      this.pic_prefix_url = this.$store.state.cardPageInfo.resResultDataObj.storeStatusInfo[0].pic_prefix_url;
      let showAmt = this.$store.state.cardPageInfo.resResultDataObj.showAmt.find((item) => item.id == 8);
      this.pic_show = showAmt && showAmt.param1 === '1';
    },
    getCenterType() {
      this.$nextTick(() => {
        const containWidth = this.$refs.cardListRef.offsetWidth;
        const oneLineCount = Math.floor(containWidth / cardWidth);
        this.centerType = oneLineCount * cardWidth;
      });
      this.getNavData(1);
    },

    // 过滤掉没有商品的一级和二级菜单分类
    filterEmptyCate(cateList = [], prdList = []) {
      cateList.forEach((el) => {
        el.ss = (el.ss || []).filter((item) => item.s == 1);
        el.ss.forEach((ele) => {
          ele.hasPrd = !!prdList.find((item) => item.t == ele.id);
        });
        el.ss = el.ss.filter((item) => item.hasPrd);
        el.hasPrd = el.ss.some((item) => item.hasPrd);
      });
      return cateList.filter((item) => item.hasPrd);
    },

    async getNavData(init = 2) {
      const params = {
        name: this.keyword, //  string   模糊查询,名字或拼音
        is_init: init * 1, //    int    1 页面初始化, 会返回一级分和二级分类信息  2 非初始化(只返回刷新后的主数据)
        one_cate_id: init == 1 ? 0 : this.firstCategoryActiveId * 1, //  int64   一级分类id, 0表示不限制
        two_cate_id: init == 1 ? 0 : this.secondCategoryActiveId * 1, // int64    二级分类id, 0表示不限制
      };
      try {
        const res = await api_saveWine.reqGetCanAuthSaveWineList(params);
        if (res.code == 1) {
          this.productListAll = res.data.items || [];

          if (init == 1) {
            const cateList = (res.data.cates || []).filter(
              (item) => item.s == 1
            );
            this.firstCategoryList = this.filterEmptyCate(
              cateList,
              this.productListAll
            );
            if (this.firstCategoryList.length > 0) {
              this.firstCategoryActiveId = this.firstCategoryList[0].id;
              this.changeFirstCategory(this.firstCategoryList[0]);
            }
          }
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("可授权存酒商品获取失败", error);
      }
    },

    changeFirstCategory(firstItemInfo) {
      this.firstCategoryActiveId = firstItemInfo.id;
      this.secondCategoryList = (firstItemInfo.ss || []).filter(
        (item) => item.s == 1
      );
      if (this.secondCategoryList.length > 0) {
        this.changeSecondCategory(this.secondCategoryList[0].id);
      }
    },

    changeSecondCategory(secondCateId) {
      this.secondCategoryActiveId = secondCateId;
      this.productList = this.productListAll.filter(
        (item) => item.t == this.secondCategoryActiveId
      );
    },

    // 点击放大镜放大图片
    clickDescImage(item) {
      this.bigImageUrl = item.picName ? this.pic_prefix_url + item.picName : require('@/assets/order-img/defaultImg.png')
      this.dialogVisible = true;
    },
    handleCloseClick(done) {
      // 在关闭对话框前重置状态
      this.dialogVisible = false;
    },

    // 选择商品规格等信息
    chooseWindInfoHandle(itemInfo = {}) {
      this.currentWineInfo = { ...itemInfo, c: 99999999999999 };
      this.showChooseDrawer = true;
    },

    // 临时购物车增加商品
    addAuthWineHandle(resultList) {
      const resultWineListArr = resultList.map((item) => ({
        ...item,
        name: this.currentWineInfo.n,
        id: this.currentWineInfo.id,
      }));
      const resultWineList = [];
      const tempWineList = [...this.resultWineList, ...resultWineListArr];

      tempWineList.forEach((el) => {
        const index = resultWineList.findIndex(
          (item) =>
            item.name == el.name &&
            item.selectVal == el.selectVal &&
            item.allWeight == el.allWeight
        );
        if (index > -1) {
          resultWineList[index].count =
            resultWineList[index].count * 1 + el.count * 1;
        } else {
          resultWineList.push(el);
        }
      });

      this.resultWineList = resultWineList;
    },

    // 当前临时购物车删除
    deleteWineHandle(itemInfo) {
      const index = this.resultWineList.findIndex(
        (item) => item.id == itemInfo.id
      );
      if (index > -1) this.resultWineList.splice(index, 1);
    },

    getCodeAndPwd(personType, empCardInfo, type) {
      let authEmpCode = "";
      let authEmpPasswd = "";
      if (type == 1) {
        // 账号密码授权
        authEmpCode =
          personType == "self" ? "" : this.authorizationInfo.userName;
        authEmpPasswd =
          personType == "self"
            ? ""
            : md5(this.authorizationInfo.passWord).toString().toUpperCase();
      } else {
        // 刷卡授权
        authEmpCode = empCardInfo.cardNo;
        authEmpPasswd = md5(empCardInfo.password).toString().toUpperCase();
      }
      return {
        authEmpCode,
        authEmpPasswd,
      };
    },

    async onSubmit(personType, empCardInfo = {}, type = 1) {
      if (this.status == 1) {
        if (this.resultWineList.length == 0) {
          this.$message.warning("没有需要授权的商品");
          return;
        }
        this.status = 2;
      } else {
        const authEmpCode = this.getCodeAndPwd(
          personType,
          empCardInfo,
          type
        ).authEmpCode;
        const authEmpPasswd = this.getCodeAndPwd(
          personType,
          empCardInfo,
          type
        ).authEmpPasswd;
        const params = {
          auth_emp_code: authEmpCode, // string    授权人工号
          auth_emp_passwd: authEmpPasswd, // string    授权人密码
          pass_type: type, //  int     1 验证 员工号/密码  2 验证卡号/卡数据 为兼容之前的账号密码认证, 当=2的时候验证卡号和卡密, 共用emp_code,password
          csm_id: this.checkedOrderInfo.id * 1, //   int64   流水Id
          prd_ids: this.resultWineList.map((item) => item.id * 1), //    []int64  商品Id列表
          unit_types: this.resultWineList.map((item) =>
            item.selectVal.toString()
          ), // []string   规格列表,对应上面的商品列表
          prd_cnts: this.resultWineList.map((item) => item.count * 1), //   []int     商品数量,对应上面的商品列表
          g_cnts: this.resultWineList.map((item) => item.allWeight * 1), //  []int   克数,,对应上面的商品列表
        };
        if (!params.auth_emp_code && personType != "self")
          return this.$message.warning("请输入授权员工号");
        if (!params.auth_emp_passwd && personType != "self")
          return this.$message.warning("请输入授权密码");
        try {
          const res = await api_saveWine.reqAddAuthWine(params);
          if (res.code == 1) {
            this.$message.success("授权成功");
            this.$emit("getShoppingCartWineList");
            this.onCancelDrawer(true);
          } else {
            window.loopReadCard();
            this.$message.warning(res.msg);
          }
        } catch (error) {
          window.loopReadCard();
          console.log("存酒授权失败", error);
        }
      }
    },

    updateAuthorizationInfo({ key, value }) {
      this.authorizationInfo[key] = value;
    },

    scrollHandle(type, direction) {
      let dom = this.$refs[type + "MenuRef"];
      const step = 200;
      const scrollTop =
        direction === "down" ? dom.scrollTop + step : dom.scrollTop - step;
      dom.scrollTo(0, scrollTop);
    },

    scrollArrowHandle(direction) {
      let dom = this.$refs.cardListRef;
      const step = 200;
      const scrollTop =
        direction === "down" ? dom.scrollTop + step : dom.scrollTop - step;
      dom.scrollTo(0, scrollTop);
    },

    onCancelDrawer(isClose) {
      if (this.status > 1 && !isClose) return (this.status -= 1);
      this.show = false;
    },

    // 刷卡授权
    swipingOrderHandle(empCardInfo) {
      if (this.show && this.status == 2) {
        const childrenVNode = this.$children[0].$children || [];
        childrenVNode.forEach((el) => {
          if (el.$el.className == "auth") {
            if (el.tabIndex == 1) {
              // 刷卡
              this.onSubmit("another", empCardInfo, 2);
            } else {
              this.$message.warning("当前为输入账号授权，不可刷卡");
            }
          }
        });
      } else {
        this.$message.warning("刷卡无效，请在登录或授权时进行刷卡！");
      }
    },
  },
  props: {
    value: false,
    checkedOrderInfo: {
      default: () => ({}),
    },
  },
  components: {
    drawerChooseWineInfo,
    authorization,
    ImagePreview
  },
  computed: {
    show: {
      get() {
        return this.value;
      },
      set(val) {
        this.$emit("input", val);
      },
    },
  },
  mounted() {
    this.getPicUrl()
  },
  watch: {
    value(newVal) {
      this.show = newVal;
      if (newVal) {
        this.resultWineList = [];
        this.status = 1;
        this.getCenterType();
      }
    },
    status(newVal) {
      if (newVal == 2) {
        eventVue.$off("saveWineToShoppingCartHandle");
        eventVue.$on("saveWineToShoppingCartHandle", (empCardInfo) => {
          this.swipingOrderHandle(empCardInfo);
        });
      }
    },
  },
};
</script>

<style scoped lang="less">
@import "../../../../style/common/newElementDrawer.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/common/newElementFormBtn.less";
@import "../../../../style/common/scrollBar.less";
@import "../../../../style/saveWine/newTable.less";
@import "../../../../style/order/orderMeal/orderMealNav.less";
</style>

<style lang="less" scoped>
.content {
  box-sizing: border-box;
  color: rgba(255, 255, 255, 0.8);
  font-size: 14px;

  .left-area {
    transform: translate(0, 0);
    height: calc(100vh - 140px);
    width: 50%;
    padding-left: 180px;
    box-sizing: border-box;
    border-right: 1px solid rgba(255, 255, 255, 0.15);

    .nav {
      height: 100%;

      .nav-left {
        ul.first-menu {
          height: calc(100vh - 200px);
          overflow-y: auto;
          color: #fff;
          scroll-behavior: smooth;

          li {
            margin-top: 4px;
            // position: relative;
            width: 90px;
            height: 64px;
            background: #FAFAFC;
            box-shadow: 0px 2px 4px 0px #C4CBD7;
            border-radius: 8px;
            // line-height: 64px;
            font-weight: 500;
            color: #08080A;
            font-size: 22px;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;

            span {
              text-align: center;
            }

            &.active {

              background: #989FAF;

              color: #FFFFFF;
            }
          }
        }
      }

      .nav-right {
        ul.second-menu {
          height: calc(100vh - 200px);
          overflow-y: auto;
          color: #fff;
          scroll-behavior: smooth;

          li {
            margin-top: 4px;
            width: 90px;
            height: 64px;

            background: #FFFFFF;
            border-radius: 8px;
            font-weight: 500;
            color: #08080A;
            font-size: 22px;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;

            span {
              text-align: center;
            }

            &.active {


              background: #3373E8;

              color: #FFFFFF;
            }
          }
        }
      }
    }

    .prd-list {
      width: 100%;
      height: 100%;
      overflow: auto;
      scroll-behavior: smooth;
      margin-top: 60px;
      margin-left: 10px;
      height: calc(100vh - 200px);

      .center-type {
        flex-wrap: wrap;

        .prd-item {
          margin-right: 10px;
          margin-top: 10px;
          width: 272px;
          box-sizing: border-box;
          position: relative;
          background: #FAFAFC;
          border-radius: 6px;
          display: flex;
          flex-direction: column;
          cursor: pointer;

          div {
            img {
              width: 272px;
              height: 272px;
            }
          }

          span {
            display: inline-block;
            height: 64px;
            width: 100%;
            padding: 10px;
            box-sizing: border-box;
            font-size: 18px;
            font-family: PingFangSC, PingFang SC;
            font-weight: 400;
            color: #08080A;

          }

          .english-name {
            height: 18px;
            font-size: 16px;
            font-family: PingFangSC-Regular, PingFang SC;
            font-weight: 400;
            color: #9B5911;
            line-height: 18px;
          }

          .fangda {
            position: absolute;
            right: 4px;
            top: 4px;
            width: 40px;
            height: 40px;
            z-index: 1;
          }
        }
      }

      //  箭头
      .arrow {
        width: 120px;
        height: 60px;
        position: fixed;
        right: 0;
        top: 0;
        cursor: pointer;
        z-index: 99;

        .bg {
          margin-top: 10px;

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

    .tips {
      text-align: center;
      margin-top: 20px;
      color: #08080A;
    }
  }

  .right-area {
    height: calc(100vh - 140px);
    width: 50%;
    padding: 10px;
    box-sizing: border-box;

    .title {
      margin-bottom: 10px;
      font-size: 24px;
      font-family: PingFangSC, PingFang SC;
      font-weight: 400;
      color: #1A1A21;
    }

    .table {
      .tbody {
        height: calc(100vh - 230px);
        overflow: auto;
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
            font-size: 24px;
            font-family: PingFangSC, PingFang SC;
            font-weight: 500;
            color: #08080A;
            text-align: center;
            line-height: 32px;
          }
        }

        &:nth-child(5) {
          width: 10%;

          img {
            width: 32px;
            cursor: pointer;
          }
        }
      }

      .tdfs {
        font-size: 20px;
        font-family: PingFangSC, PingFang SC;
        font-weight: 400;
        color: #08080A;
      }
    }
  }

  // 授权
  .authorization {
    margin-top: 10px;
    padding: 20px;
    box-sizing: border-box;

    &-left {
      width: 50%;
      padding-right: 10px;
      box-sizing: border-box;
      border-right: 1px solid rgba(255, 255, 255, 0.2);

      .table {
        font-size: 14px;

        .tr {
          padding: 10px;

          .th,
          .td {
            width: 30%;
            font-size: 20px;
            font-family: PingFangSC, PingFang SC;
            font-weight: 400;
            color: #08080A;
          }

          .th:nth-child(1),
          .td:nth-child(1),
          .th:nth-child(5),
          .td:nth-child(5) {
            width: 20%;
          }
        }

        .thead {
          background-color: rgba(216, 229, 255, 0.08);
        }

        .tbody {
          height: calc(100vh - 250px);
          overflow-y: auto;

          .tr:nth-child(2n) {
            background-color: rgba(255, 255, 255, 0.04);
          }
        }
      }
    }

    // 授权刷卡或输入账号密码
    &-right {
      width: 50%;
    }
  }
}
</style>
