<template>
  <!-- 批量赠送 -->
  <div class="give-more">
    <el-drawer
      :title="title"
      :visible.sync="show"
      direction="rtl"
      :size="size"
      :before-close="onCancelDrawer"
    >
      <!-- 批量赠送 、 批量自用 -->
      <div class="content">
        <div v-if="status==1||status==2" class="give-more-content">
          <!-- 选择购物车赠送商品明细 -->
          <div v-if="subStatus==1">
            <!-- 表单 -->
            <div v-if="status==1||status==2">
              <div v-if="subStatus==1">
                <!-- 表单 -->
                <div class="form">
                  <el-form label-position="right" label-width="150px" :model="formData" @submit.native.prevent>
                    <!-- 商品名称 -->
                    <el-form-item label="商品名称">{{currentProductInfo.productInfo.name}}</el-form-item>
                    <!-- 退单商品数量 -->
                    <el-form-item :label="status==1?'优惠':'自用'+'数量'" class="change-count">
                      <img
                        :src="currentProductInfo.productInfo.prdType==4||productCount==1?imgSrc.subDisabled:imgSrc.sub"
                        @click="changeCount('sub')"
                      />
                      <input
                        type="number"
                        min="1"
                        :disabled="currentProductInfo.productInfo.prdType==4"
                        v-model="productCount"
                        @input="changeCount('input')"
                      />
                      <img
                        :src="currentProductInfo.productInfo.prdType==4||productCount>=currentProductInfo.pc?imgSrc.addDisabled:imgSrc.add"
                        @click="changeCount('add')"
                      />
                    </el-form-item>
                    <!-- 退单金额 -->
                    <el-form-item
                      v-if="status==1"
                      label="优惠金额"
                    >￥{{(currentItemInfo.pp*productCount).toFixed(2)}}</el-form-item>
                    <!-- 赠送类型 -->
                    <!-- <el-form-item v-if="status==1" label="选择赠送类型" class="required required6">
                      <el-radio
                        v-for="(item,index) in formData.authTypeList"
                        :key="index"
                        v-model="formData.radio"
                        style="margin-left:0"
                        :label="item.id"
                      >{{item.name}}</el-radio>
                    </el-form-item> -->
                    <!-- 退单、赠送理由 -->
                    <el-form-item
                      :label="'选择'+(status==1?'优惠':'自用')+'理由'"
                      class="required required6"
                    >
                      <ul class="reason-list" layout="row" layout-align="start center">
                        <li :class="{'active': formData.reason == item.name}" v-for="item in reasonList" :key="item.id" @click="formData.reason=item.name">{{item.name}}</li>
                      </ul>
                    </el-form-item>
                  </el-form>
                </div>
              </div>
              <!-- 授权 -->
              <div v-else class="authorization">
                <ul layout="row" layout-align="center start">
                  <li class="authorization-left">
                    <p class="p-b-2">授权商品和数量</p>
                    <div class="table">
                      <div class="thead">
                        <div class="tr" layout="row" layout-align="start start">
                          <div class="th">序号</div>
                          <div class="th">商品名称</div>
                          <div class="th">数量</div>
                        </div>
                      </div>
                      <div class="tbody">
                        <div class="tr" layout="row" layout-align="start start">
                          <div class="td">1</div>
                          <div class="td">{{currentProductInfo.productInfo.name}}</div>
                          <div class="td">{{productCount}}</div>
                        </div>
                      </div>
                    </div>
                  </li>
                  <li class="authorization-right">
                    <authorization
                      :authorizationInfo="authorizationInfo"
                      @updateAuthorizationInfo="updateAuthorizationInfo"
                    />
                  </li>
                </ul>
              </div>
            </div>
          </div>
          <!-- 授权 -->
          <div v-else class="authorization">
            <p class="m-b-5 fs16">当前卡台：{{$store.state.orderInfo.currentCardInfo.name}}</p>
            <ul layout="row" layout-align="center start">
              <li class="authorization-left">
                <p class="p-b-2">授权商品和数量</p>
                <div class="table">
                  <div class="thead">
                    <div class="tr" layout="row" layout-align="start start">
                      <div class="th">序号</div>
                      <div class="th">商品名称</div>
                      <div class="th">数量</div>
                    </div>
                  </div>
                  <div class="tbody">
                    <div class="tr" layout="row" layout-align="start start">
                      <div class="td">1</div>
                      <div class="td">{{currentProductInfo.productInfo.name}}</div>
                      <div class="td">{{productCount}}</div>
                    </div>
                  </div>
                </div>
              </li>
              <li class="authorization-right">
                <authorization
                  :authorizationInfo="authorizationInfo"
                  @updateAuthorizationInfo="updateAuthorizationInfo"
                />
              </li>
            </ul>
          </div>
        </div>

        <!-- 加要求 -->
        <div v-if="status==3">
          <ul class="add-requested">
            <li
              v-for="(item,i) in currentItemInfo.si"
              :key="i"
              layout="row"
              layout-align="start center"
            >
              <div class="left">
                <input type="radio" v-model="requireDrawerInfo.chooseIndex" :value="i" />
              </div>
              <div class="right" layout="row" layout-align="start center">
                <p>{{item.groupInfo.name}} * {{item.s * item.c * currentItemInfo.pc }}{{item.r ? '（'+item.r+'）':''}}</p>
              </div>
            </li>
          </ul>
          <!-- 套餐选定的单品定制要求 -->
          <drawerChooseRequireInfo
            :showDrawer="requireDrawerInfo.showDrawer"
            :productInfo="requireDrawerInfo.productInfo"
            :requestInfoArr="requireDrawerInfo.requestInfoArr"
            notCloseDrawer="true"
            @updateRequireInfoArr="updateRequestInfoArr"
            @showOrHideDrawer="showOrHideRequireDrawer"
          />
        </div>

        <!-- 更改套餐明细 -->
        <div v-if="status==4">
          <p v-if="subStatus==1" class="red">请选择更改的套餐明细</p>
          <ul v-if="subStatus==1" class="choose-detail">
            <li
              v-for="(item,i) in updateDetail.groupList"
              :key="i"
              layout="row"
              layout-align="start center"
            >
              <div class="left">
                <input type="radio" v-model="updateDetail.detailIndex" :value="i" />
              </div>
              <div class="right" layout="row" layout-align="start center">
                <p
                  v-for="(items,index) in item.list"
                  :key="index"
                >{{items.groupInfo.name}} * {{items.s * items.c * item.count }}{{items.r ? '（'+items.r+'）':''}}</p>
              </div>
            </li>
          </ul>

          <!-- 更改明细 -->
          <div v-if="subStatus==2" class="add-requested">
            <groupProduct
              :productInfo="updateDetail.productInfo"
              :singleInfo="updateDetail.singleInfo"
              :selectedInfoObj="updateDetail.selectedInfoObj"
              isUpdate="true"
              @updateSelectedArr="updateSelectedArr"
            />
          </div>
        </div>

        <!-- 批量优惠/批量优惠2 -->
        <div v-if="status==6 || status==7" class="seal-many">
          <div v-if="subStatus == 1">
            <div class="title m-b-4">请选择需要优惠{{status==6?'':'2'}}的商品</div>
            <div class="table">
              <div class="thead">
                <div class="tr" layout="row" layout-align="space-between center">
                  <div class="th">
                    <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll" @change="changeCheckBox('all')">全选</el-checkbox>
                  </div>
                  <div class="th">名称</div>
                  <div class="th">数量</div>
                  <div class="th">优惠{{status == 6 ? '' : '2'}}数量</div>
                </div>
              </div>
              <div class="tbody" :class="{give: status==6}">
                <div class="tr" layout="row" layout-align="space-between center" v-for="(item, index) in sealProductList" :key="item.id">
                  <div class="td">
                    <el-checkbox v-model="item.checked" @change="changeCheckBox('item')">{{index + 1}}</el-checkbox>
                  </div>
                  <div class="td">{{item.productInfo.name}}</div>
                  <div class="td">{{item.pc}}</div>
                  <div class="td">
                    <img
                      :src="item.changeCount==1?require('@/assets/order-img/sub-disabled.png'):require('@/assets/order-img/sub.png')"
                      @click="changeCountOfSeal('sub',item)"
                      alt
                    />
                    <input
                      type="number"
                      :min="1"
                      v-model="item.changeCount"
                      @input="changeCountOfSeal('input',item)"
                    />
                    <img
                      :src="item.changeCount>=item.pc?require('@/assets/order-img/add-disabled.png'):require('@/assets/order-img/order_add.png')"
                      @click="changeCountOfSeal('add',item)"
                      alt
                    />
                  </div>
                </div>
              </div>
            </div>
            
            <div class="form m-t-6" v-if="status==6">
              <el-form label-position="right" label-width="150px" :model="formData" @submit.native.prevent>
                <el-form-item label="选择批量优惠理由">
                  <ul class="reason-list" layout="row" layout-align="start center">
                    <li :class="{'active': formData.reason == item.name}" v-for="item in reasonList" :key="item.id" @click="formData.reason=item.name">{{item.name}}</li>
                  </ul>
                </el-form-item>
              </el-form>
            </div>
          </div>
          
          <!-- 授权 -->
          <div v-else class="authorization">
            <ul layout="row" layout-align="center start">
              <li class="authorization-left">
                <p class="p-b-2">授权商品和数量</p>
                <div class="table">
                  <div class="thead">
                    <div class="tr" layout="row" layout-align="start start">
                      <div class="th">序号</div>
                      <div class="th">商品名称</div>
                      <div class="th">数量</div>
                    </div>
                  </div>
                  <div class="tbody">
                    <div class="tr" layout="row" layout-align="start start" v-for="(item,index) in sealManyInfo.choosePrdList" :key="item.id">
                      <div class="td">{{index + 1}}</div>
                      <div class="td">{{item.productInfo.name}}</div>
                      <div class="td">{{item.pc}}</div>
                    </div>
                  </div>
                </div>
              </li>
              <li class="authorization-right">
                <authorization
                  :authorizationInfo="authorizationInfo"
                  @updateAuthorizationInfo="updateAuthorizationInfo"
                />
              </li>
            </ul>
          </div>

        </div>

        <!-- 批量提交优惠2 -->
        <drawerYH2Submit
          ref="drawerYH2Submit"
          :showDrawer="sealMany2Info.showYH2Drawer"
          :selectedProList="sealMany2Info.choosePrdList"
          :showSelfBtn="sealMany2Info.authLimits"
          @showOrHideDrawer="showOrHideYH2Drawer"
          @showOrHideAnotherDrawer="onCancelDrawer"
        />

        <!-- 提交按钮 -->
        <div class="form-btn" layout="row" layout-align="center center">
          <el-button type="info" @click.stop="onCancelDrawer(false)">取消</el-button>
          <el-button
            v-if="(subStatus==2&&((status==1 && currentItemInfo.productInfo.canSeal) || status== 2 || status == 3)) || (status == 6 && subStatus==2 && sealManyInfo.authLimits)"
            type="primary"
            @click.stop="onSubmit('self')"
          >自己授权</el-button>
          <el-button type="primary" @click.stop="onSubmit('another')">{{submitTxt}}</el-button>
        </div>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import eventVue from '@/utils/eventVue';

import api_order from "@/api/order";
import common_order from "@/utils/common/order";

import add from "@/assets/order-img/order_add.png";
import sub from "@/assets/order-img/sub.png";
import addDisabled from "@/assets/order-img/add-disabled.png";
import subDisabled from "@/assets/order-img/sub-disabled.png";

import selectCheckbox from "@/components/order/selectCheckbox";
import groupProduct from "@/components/order/drawerMeal/groupProduct";
import authorization from "@/components/order/shoppingCart/authorization";
import drawerChooseRequireInfo from "@/components/order/drawerMeal/drawerChooseRequireInfo";
import drawerYH2Submit from "@/components/order/drawerMeal/drawerYH2Submit.vue";

import md5 from "js-md5";
export default {
  data() {
    return {
      show: false,
      // 赠送、自用
      subStatus: 1, // 1: 自用、授权处于第一步选择商品及数量页面  2：自用、授权处于授权页面
      productCount: 1, // 退单赠送等操作的商品数量
      currentProductInfo: {
        productInfo: {
          name: "",
          prdType: 1
        }
      }, // 当前需要操作的商品信息
      formData: {
        radio: "2",
        authTypeList: [], // 赠送类型
        reason: '',
      },
      // 授权
      authorizationInfo: {
        userName: "",
        passWord: ""
      },
      // 加要求
      requireDrawerInfo: {
        chooseIndex: 0, // 选择套餐组中的单品索引值
        shoppingCartId: "", // 当前单品的购物车id
        showDrawer: false,
        productInfo: {}, //  当前单品的单品信息
        requestInfoArr: [] // 当前单品修改前的定制要求
      },
      // 更改明细
      updateDetail: {
        detailIndex: 0, // 更改套餐明细角标
        productInfo: {}, // 当前修改订单信息
        singleInfo: {}, // 当前订单的数量和要求
        groupList: [], // 当前套餐组列表
        selectedInfoObj: [] // 已选明细
      },

      // 优惠/优惠2选择商品相关
      checkAll: false, // 选择需要批量优惠/批量优惠2的商品
      sealProductList: [], // 优惠/优惠2商品列表

      // 批量优惠
      sealManyInfo: {
        authLimits: false, // 是否有所选商品的优惠权限
        choosePrdList: [],  // 批量选择的优惠商品列表
      },

      // 批量优惠2
      sealMany2Info: {
        showYH2Drawer: false,
        authLimits: false, // 是否有所选商品的优惠权限
        choosePrdList: [],  // 批量选择的优惠2商品列表
      },

      imgSrc: {
        add,
        sub,
        addDisabled,
        subDisabled
      }
    };
  },
  methods: {
    /**
     * 优惠、自用
     */

    // 更改赠送、自用商品数量
    changeCount(type) {
      switch (type) {
        case "add":
          this.productCount = Math.min(
            this.productCount + 1,
            this.currentItemInfo.pc
          );
          break;
        case "sub":
          this.productCount = Math.max(this.productCount - 1, 1);
          break;
        case "input":
          this.productCount = Math.min(
            this.productCount,
            this.currentItemInfo.pc
          );
          this.productCount = Math.max(this.productCount, 1);
          this.$forceUpdate();
          break;
      }
    },

    // initRadio() {
    //   // 获取赠送类型初始值
    //   const opentype = this.$store.state.orderInfo.currentCardInfo.openType; // 1 消费 2 内招 3 外招 4 气氛 5 全转 6 半转
    //   switch (opentype * 1) {
    //     case 1:
    //     case 5:
    //     case 6:
    //       this.formData.radio = "2";
    //       break;
    //     case 2:
    //       this.formData.radio = "3";
    //       break;
    //     case 3:
    //       this.formData.radio = "5";
    //       break;
    //   }
    //   // 获取当前商品的赠送类型
    //   this.formData.authTypeList = common_order.getAuthTypeList(
    //     this.currentItemInfo.productInfo.twoCateId
    //   );
    // },

    goAuthorization() {
      if (!this.formData.reason)
        return this.$message.warning(
          `请选择${this.status == 1 || this.status == 6 ? (this.status == 1 ? "优惠" : '优惠2') : "自用"}理由`
        );

      this.subStatus = 2;
    },

    updateAuthorizationInfo({ key, value }) {
      this.authorizationInfo[key] = value;
    },

    // -------------套餐组单品加定制要求start----------------

    // 接收单品单品定制要求的值
    updateRequestInfoArr(requireList) {
      this.requireDrawerInfo.requestInfoArr = requireList;
      this.submitGroupProductRequire();
    },

    // 套餐组单品加定制要求提交
    async submitGroupProductRequire() {
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64  卡台Id
        id: this.requireDrawerInfo.shoppingCartId * 1, //         int64   购物车项Id
        grp_id:
          this.currentItemInfo.si[this.requireDrawerInfo.chooseIndex]["gid"] *
          1, //     int   套餐组Id
        dtl_prd_id:
          this.currentItemInfo.si[this.requireDrawerInfo.chooseIndex]["i"] * 1, // int64   套餐组Id对应的明细商品Id
        dtl_prd_cnts:
          this.currentItemInfo.si[this.requireDrawerInfo.chooseIndex]["c"] * 1, // int 明细商品项的商品数
        sel_cnts:
          this.currentItemInfo.si[this.requireDrawerInfo.chooseIndex]["s"] * 1, //   int  套餐组对应的商品项的选中次数
        src_requirement: this.currentItemInfo.si[
          this.requireDrawerInfo.chooseIndex
        ]["r"], // string   原要求
        requirement: this.requireDrawerInfo.requestInfoArr.join(";") // string    现要求
      };
      try {
        const res = await api_order.reqUpdateGroupProductRequire(params);
        if (res.code == 1) {
          this.showOrHideRequireDrawer();
          this.onCancelDrawer(true);
          this.$parent.getShoppingCartData();
          this.$message.success("修改成功");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("套餐中的单品修改要求失败", error);
      }
    },

    showOrHideRequireDrawer() {
      this.requireDrawerInfo.showDrawer = !this.requireDrawerInfo.showDrawer;
    },

    // -------------套餐组单品加定制要求end----------------

    // ----------------修改套餐明细start-----------------

    // 获取修改套餐组的明细
    getGroupDetail(productId, groupId) {
      const groupDetailArr = this.$store.state.cardPageInfo.resResultDataObj.goodsDetailInfo.filter(
        el => el.status == 1 && el.prdId == productId
      );

      // 排序
      const groupCanSelectArr = JSON.parse(JSON.stringify(groupDetailArr))
        .filter(el => el.grpId != 1)
        .sort((a, b) => a.seqId - b.seqId);

      groupCanSelectArr.forEach(el => {
        el.productInfo = common_order.getProductInfoFromGroup(el.dtlPrdId);
      });

      const resultGroupCanSelectArr = [];

      const findInfo = groupCanSelectArr.filter(ele => ele.grpId == groupId);
      findInfo.forEach(el => {
        el.productInfo.requireInfo = common_order.getRequireInfo(
          el.productInfo.twoCateId
        );
        el.requireText = "";
      });

      resultGroupCanSelectArr.push({
        grpId: groupId,
        productInfoList: findInfo,
        groupSelectCount: 0, // 当前套餐中待替换商品选中的次数可选的商品数量
        selectedProductsArr: [], // 已选商品列表
        hadSelectedCount: 0 // 已选商品数量
      });

      return resultGroupCanSelectArr;
    },

    /**
     * 更改明细
     */

    updateSelectedArr(selectProInfo) {
      this.updateDetail.selectedInfoObj = [selectProInfo];
    },

    // 刷卡授权
    swipingOrderHandle(empCardInfo){
      if(this.show && this.subStatus == 2) {
        const childrenVNode = this.$children[0].$children || []
        childrenVNode.forEach(el => {
          if(el.$el.className == 'auth') {
            if(el.tabIndex == 1) {
              // 刷卡
              if (this.status == 1 || this.status == 6 ) {
                // 单个优惠/批量优惠
                this.onSubmit('another', empCardInfo, 2)
              }
            } else {
              this.$message.warning('当前为输入账号授权，不可刷卡')
            }
          }
        })
      } else if (this.status == 7) {
        // 批量优惠2
        const childrenVNodeYH2 = this.$refs.drawerYH2Submit.$children[0].$children || []
        childrenVNodeYH2.forEach(el => {
          if(el.$el.className == 'auth') {
            if(el.tabIndex == 1) {
              // 刷卡
              el.onSubmit('another', empCardInfo, 2)
            } else {
              this.$message.warning('当前为输入账号授权，不可刷卡')
            }
          }
        })
      } else {
        this.$message.warning('刷卡无效，请在登录或授权时进行刷卡！')
      }
    },

    
    getCodeAndPwd(personType, empCardInfo, type){
      let authEmpCode = ''
      let authEmpPasswd = ''
      if(type == 1) {
        // 账号密码授权
        authEmpCode = personType == "self" ? "" : this.authorizationInfo.userName
        authEmpPasswd = personType == "self" ? "" : md5(this.authorizationInfo.passWord).toString().toUpperCase()
      } else {
        // 刷卡授权
        authEmpCode = empCardInfo.cardNo
        authEmpPasswd = md5(empCardInfo.password).toString().toUpperCase()
      }
      return {
        authEmpCode,
        authEmpPasswd
      }
    },

    // 提交
    async onSubmit(personType, empCardInfo={} , type=1) {
      // personType:{self:自己授权, another:别人授权}
      let params = {};
      let authEmpCode = ''
      let authEmpPasswd = ''
      switch (this.status) {
        case 1: // 优惠
        case 2: // 自用
          if (this.subStatus == 1) return this.goAuthorization();

          authEmpCode = this.getCodeAndPwd(personType, empCardInfo, type).authEmpCode
          authEmpPasswd = this.getCodeAndPwd(personType, empCardInfo, type).authEmpPasswd

          params = {
            auth_emp_code: authEmpCode, // string  授权员工工号, 如果不传, 代表本账号授权
            auth_emp_passwd: authEmpPasswd, // string  授权员工密码
            auth_reason: this.formData.reason, // string   授权理由
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64    卡台Id
            shopping_cart_ids: [this.currentProductInfo.id * 1], // []int64    要授权的购物车项Id
            auth_cnts: [this.productCount], //  []int   要授权的购物车项Id对应的数量
            pass_type : type  // 1:账号密码， 2：刷卡
          };

          if (!params.auth_emp_code && personType != "self")
            return this.$message.warning("请输入授权员工号");
          if (!params.auth_emp_passwd && personType != "self")
            return this.$message.warning("请输入授权密码");
          try {
            const res = await api_order.reqAuthorizationShopping(params);
            if (res.code == 1) {
              this.$message.success(
                `${this.status == 1 ? "优惠" : "自用"}成功`
              );
              this.$parent.getShoppingCartData();
              this.onCancelDrawer(true);
            } else {
              window.loopReadCard()
              this.$message.warning(res.msg);
            }
          } catch (error) {
            window.loopReadCard()
            console.log("优惠授权失败", error);
          }
          break;
        case 3: // 更改套餐要求（选择当前套餐中需要更改的单品）
          const currentItemInfo = JSON.parse(
            JSON.stringify(this.currentItemInfo)
          );
          currentItemInfo.si.forEach(el => {
            el.requireInfo = common_order.getRequireInfo(
              el.groupInfo.twoCateId
            );
          });
          this.requireDrawerInfo.shoppingCartId = currentItemInfo.id;
          this.requireDrawerInfo.productInfo =
            currentItemInfo.si[this.requireDrawerInfo.chooseIndex];
          this.requireDrawerInfo.requestInfoArr = currentItemInfo.si[
            this.requireDrawerInfo.chooseIndex
          ].r.split(";");
          this.showOrHideRequireDrawer();
          break;
        case 4: // 更改明细
          if (this.subStatus == 1) {
            this.subStatus = 2;
            this.initGroupProductInfo();
          } else {
            const {
              selectedProductsArr
            } = this.updateDetail.selectedInfoObj[0];

            const {
              beforeUpdateProduct
            } = this.updateDetail.selectedInfoObj[0];

            params = {
              seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, // int64   卡台Id
              id: this.currentProductInfo.id * 1, // int64    购物车项Id
              grp_ids: selectedProductsArr[0].grpId * 1, // int     套餐组Id
              dtl_prd_ids:
                this.updateDetail.selectedInfoObj[0].beforeUpdateProduct[0]
                  .dtlPrdId * 1, // int64    套餐组Id对应的需要替换的商品Id
              dest_dtl_prd_ids: selectedProductsArr.map(el => el.dtlPrdId * 1), // []int64   目标明细商品Ids
              dest_sel_cnts: selectedProductsArr.map(
                el => el.selectedCount * 1
              ), // []int    目标明细商品项选中数
              requirement: beforeUpdateProduct[0].requireText, // string   要求
              dest_requirements: selectedProductsArr.map(el => el.requireText) // []string  目标明细商品要求
            };
            try {
              const res = await api_order.reqUpdateGroupDetail(params);
              if (res.code === 1) {
                this.$message.success("修改明细成功");
                this.$parent.getShoppingCartData();
                this.onCancelDrawer(true);
              } else this.$message.warning(res.msg);
            } catch (error) {
              console.log("更改套餐明细失败", error);
            }
          }
          break;
        case 6:
          // 确认批量优惠商品
          if (this.subStatus == 1) {
            this.sealManyInfo.choosePrdList = this.sealProductList.filter(item => item.checked && item.changeCount > 0).map(item =>({
              ...item,
              pc: item.changeCount
            }))
            if (this.sealManyInfo.choosePrdList.length == 0) return this.$message.warning('请选择需要批量优惠的商品')
            // 判断当前操作人员是否有全部商品优惠的权限
            this.sealManyInfo.authLimits = this.sealManyInfo.choosePrdList.every(item => item.productInfo.canSeal)
            return this.goAuthorization();
          }

          // 授权批量优惠
          authEmpCode = this.getCodeAndPwd(personType, empCardInfo, type).authEmpCode
          authEmpPasswd = this.getCodeAndPwd(personType, empCardInfo, type).authEmpPasswd

          params = {
            auth_emp_code: authEmpCode, // string  授权员工工号, 如果不传, 代表本账号授权
            auth_emp_passwd: authEmpPasswd, // string  授权员工密码
            auth_reason: this.formData.reason, // string   授权理由
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64    卡台Id
            shopping_cart_ids: this.sealManyInfo.choosePrdList.map(item => item.id * 1), // []int64    要授权的购物车项Id
            auth_cnts: this.sealManyInfo.choosePrdList.map(item => item.pc * 1), //  []int   要授权的购物车项Id对应的数量
            pass_type : type  // 1:账号密码， 2：刷卡
          };

          if (!params.auth_emp_code && personType != "self")
            return this.$message.warning("请输入授权员工号");
          if (!params.auth_emp_passwd && personType != "self")
            return this.$message.warning("请输入授权密码");
          try {
            const res = await api_order.reqAuthorizationShopping(params);
            if (res.code == 1) {
              this.$message.success('批量优惠成功');
              this.$parent.getShoppingCartData();
              this.onCancelDrawer(true);
              this.redirectToCardList();
            } else {
              window.loopReadCard()
              this.$message.warning(res.msg);
            }
          } catch (error) {
            window.loopReadCard()
            console.log("批量优惠授权失败", error);
          }
          
          break
        case 7:  // 批量优惠2
          this.sealMany2Info.choosePrdList = this.sealProductList.filter(item => item.checked && item.changeCount > 0).map(item =>({
            ...item,
            pc: item.changeCount
          }))
          if (this.sealMany2Info.choosePrdList.length == 0) return this.$message.warning('请选择需要批量优惠2的商品')
          // 判断当前操作人员是否有全部商品优惠2的权限
          this.sealMany2Info.authLimits = this.sealMany2Info.choosePrdList.every(item => item.productInfo.canSeal)
          this.showOrHideYH2Drawer()
          
          break
      }
    },

    redirectToCardList() {
      const authStatus = this.$store.state.userInfo.authStatus;
      const targetRouteName = authStatus == 4 ? 'moneyCard' : 'orderCard';
      if (this.$route.name === targetRouteName) return;
      this.$router.replace({ name: targetRouteName }).catch(() => {});
    },

    initGroupProductInfo() {
      const { currentItemInfo: info } = this;
      this.updateDetail.productInfo = info.productInfo;
      this.updateDetail.productInfo.requireInfo = common_order.getRequireInfo(
        this.updateDetail.productInfo.twoCateId
      );

      this.updateDetail.singleInfo = {
        prd_cnt: info.pc,
        requirement: info.r
      };
      this.updateDetail.selectedInfoObj = this.getGroupDetail(
        this.updateDetail.productInfo.id,
        this.updateDetail.groupList[this.updateDetail.detailIndex]["grpId"]
      );

      // 获取已选中的套餐组商品列表
      const selectedInfo = [];
      this.updateDetail.selectedInfoObj[0].productInfoList.forEach(el => {
        const infoObj = this.updateDetail.groupList[
          this.updateDetail.detailIndex
        ]["list"].find(ele => el.dtlPrdId == ele.dtl_prd_ids);

        const infoObjIndex = this.updateDetail.groupList[
          this.updateDetail.detailIndex
        ]["list"].findIndex(ele => el.dtlPrdId == ele.dtl_prd_ids);
        if (infoObj) {
          el.selectedCount = this.updateDetail.groupList[
            this.updateDetail.detailIndex
          ]["list"][infoObjIndex].sel_cnts;

          // copy赋值修改前的商品信息并赋值定制要求
          const itemInfo = JSON.parse(JSON.stringify(el));
          itemInfo.requireText = this.updateDetail.groupList[
            this.updateDetail.detailIndex
          ]["list"][0].r;
          selectedInfo.push(itemInfo);
        }
      });

      this.updateDetail.selectedInfoObj[0].groupSelectCount =
        selectedInfo[0].selectedCount; // 当前套餐中待替换商品选中的次数可选的商品数量
      // 赋值（已选中的套餐组商品展示在待替换商品处）
      this.updateDetail.selectedInfoObj[0][
        "beforeUpdateProduct"
      ] = selectedInfo;
    },

    /**
     * 批量优惠
     */
    // 更改结账优惠商品数量
    changeCountOfSeal(type, info) {
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
        this.$forceUpdate();
      }
    },

    showOrHideYH2Drawer(){
      this.sealMany2Info.showYH2Drawer = !this.sealMany2Info.showYH2Drawer
    },

    // 选择需要批量优惠/批量优惠2的商品
    changeCheckBox(type){
      switch(type){
        case 'all':
          this.sealProductList = this.sealProductList.map(item => ({
            ...item,
            checked: this.checkAll
          }))
          break
        case 'item':
          this.checkAll = this.sealProductList.every(item => item.checked)
          break
      }
    },

    onCancelDrawer(isClose) {
      this.authorizationInfo.userName = "";
      this.authorizationInfo.passWord = "";
      if (this.subStatus == 2 && !isClose) {
        this.subStatus = 1;
        window.stopLoopReadCard()
      } else {
        this.currentProductInfo = {
          productInfo: {
            name: "",
            prdType: 1
          }
        };
        this.$emit("showOrHideDrawer", this.status);
      }
    }
  },
  created() {},
  mounted() {},
  props: ["showDrawer", "status", "currentItemInfo", "shoppingCartList"],
  computed: {
    title() {
      let title = "";
      switch (this.status) {
        case 1:
          title = "优惠";
          break;
        case 2:
          title = "自用";
          break;
        case 3:
          title = "选择加要求的商品";
          break;
        case 4:
          title = this.subStatus == 1 ? "选择套餐明细" : "更改套餐明细";
          break;
        case 6:
          title = '批量优惠'
          break
        case 7:
          title = '批量优惠2'
          break
      }
      if (this.subStatus != 1 && this.status != 4) title = "授权";
      return title;
    },
    size() {
      let size = "60%";
      if ((this.status === 4 && this.subStatus == 1) ||this.status == 3) size = "40%";
      if(this.status == 6 || this.status == 7) size = '80%'
      if (this.subStatus == 2) size = "88%";
      return size;
    },
    submitTxt() {
      let txt = "确认";
      return txt;
    },

    reasonList(){ // 优惠理由
      return this.$store.state.cardPageInfo.resResultDataObj.reasonList.filter(item => item.status == 1 && item.type_id == 1)
    },


    isIndeterminate(){
      return !this.checkAll && this.sealProductList.some(item => item.checked)
    }
  },
  components: {
    selectCheckbox,
    groupProduct,
    authorization,
    drawerChooseRequireInfo,
    drawerYH2Submit
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        eventVue.$off('empShoppingCartHandle')
        eventVue.$on('empShoppingCartHandle', empCardInfo => { this.swipingOrderHandle(empCardInfo) })

        this.subStatus = 1;

        if(this.status < 6) {
          // 优惠 自用  加要求  更改明细
          this.currentProductInfo = this.currentItemInfo.id
          ? this.currentItemInfo
          : {
              productInfo: {
                name: "",
                prdType: 1
              }
            };
        }

        switch (this.status) {
          case 1: // 赠送
            // this.initRadio();
          case 2: // 自用
            this.productCount = 1;
            this.formData.reason = "";
            break;
          case 3: // 加要求
            break;
          case 4: // 更改明细
            if (this.subStatus == 1) {
              const objInfo = JSON.parse(
                JSON.stringify(this.currentProductInfo)
              );
              this.updateDetail.productItemInfo = JSON.parse(
                JSON.stringify(objInfo)
              );
              const grpIdListArr = objInfo.si.filter(el => el["gid"] != 1);
              const groupList = [];
              Array.from(new Set(grpIdListArr.map(el => el.gid))).forEach(
                el => {
                  groupList.push({
                    count: objInfo.pc,
                    grpId: el,
                    list: grpIdListArr
                      .filter(ele => ele.gid == el)
                      .map(item => ({
                        ...item,
                        dtl_prd_ids: item.i,
                        sel_cnts: item.s
                      }))
                  });
                }
              );

              const resultGroupList = [];
              groupList.forEach((el, i) => {
                el.list.forEach(ele => {
                  resultGroupList.push({
                    count: el.count,
                    grpId: el.grpId,
                    list: [ele]
                  });
                });
              });
              this.updateDetail.groupList = resultGroupList;
            }

            break;

          case 6:  // 批量优惠
          case 7:  // 批量优惠2
            this.checkAll = true
            this.sealProductList = this.shoppingCartList.filter(item => item.at !=2 && item.at != 3 && (item.productInfo.prdType == 1 || item.productInfo.prdType == 7 || item.productInfo.prdType == 6)).map(item => ({
              ...item,
              changeCount: item.pc,
              checked: true
            }))
            break
            
        }
      } else {
        window.stopLoopReadCard()
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementTable.less";
@import "../../../style/order/orderMeal/newShoppingCart/drawerGiveHeMore.less";
</style>