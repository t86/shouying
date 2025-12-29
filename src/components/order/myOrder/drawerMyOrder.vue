<template>
  <!-- 
    我的点单页面，收银系统未支付订单
    赠送、自用、退单、选择套餐需要更改的套餐组、退单套餐查看套餐明细 
  -->
  <div class="my-order-drawer">
    <el-drawer :title="title" :visible.sync="show" direction="rtl" :size="size" :before-close="onCancelDrawer">
      <div class="content">
        <!-- 优惠人 -->
        <div v-if="status == 9" class="my-order-drawer-content">
          <!-- 授权 -->
          <div class="authorization">
            <div layout="row" layout-align="center start">
              <div class="authorization-left" layout="col" layout-align="start center">
                <p class="m-b-5 fs16">优惠商品：{{ currentItemInfo.productInfo && currentItemInfo.productInfo.name }}</p>
                <p class="m-b-5 fs16">优惠数量：{{ currentItemInfo.pc }}</p>
                <p class="m-b-5 fs16">优惠金额：{{ (currentItemInfo.pa * 1).toFixed(2) }}</p>
                <p class="m-b-5 fs16">原优惠人：{{ currentItemInfo.authInfo && currentItemInfo.authInfo.name }}</p>
              </div>
              <div class="authorization-right">
                <authorization :authorizationInfo="authorizationInfo"
                  @updateAuthorizationInfo="updateAuthorizationInfo" />
              </div>
            </div>
          </div>
        </div>
        <!-- 退单1 / 优惠 2 / 自用3 -->
        <div v-if="status == 1 || status == 2 || status == 3" class="my-order-drawer-content">
          <div v-if="subStatus == 1">
            <!-- 表单 -->
            <div class="form">
              <el-form label-position="right" label-width="150px" :model="formData" @submit.native.prevent>
                <!-- 商品名称 -->
                <el-form-item label="商品名称">{{ currentProductInfo.productInfo.name }}</el-form-item>
                <!-- 退单商品数量 -->
                <el-form-item :label="(status == 1 ? '退单' : (status == 2 ? '优惠' : '自用')) + '数量'" class="change-count">
                  <img
                    :src="((currentItemInfo.io == 1 && status == 1) || (currentProductInfo.productInfo.prdType == 3 || currentProductInfo.productInfo.prdType == 8 || currentProductInfo.productInfo.prdType == 5) && $store.state.userInfo.authStatus != 4) || currentProductInfo.productInfo.prdType == 4 || productCount == 1 ? imgSrc.subDisabled : imgSrc.sub"
                    @click="changeCount('sub')" />
                  <input type="number" min="1"
                    :disabled="(currentItemInfo.io == 1 && status == 1) || currentProductInfo.productInfo.prdType == 4 || ((currentProductInfo.productInfo.prdType == 3 || currentProductInfo.productInfo.prdType == 8 || currentProductInfo.productInfo.prdType == 5) && $store.state.userInfo.authStatus != 4)"
                    v-model="productCount" @input="changeCount('input')" />
                  <img
                    :src="currentProductInfo.productInfo.prdType == 4 || productCount >= currentProductInfo.pc ? imgSrc.addDisabled : imgSrc.add"
                    @click="changeCount('add')" />
                </el-form-item>
                <!-- 退单金额 -->
                <el-form-item class="back-order-amt" v-if="status == 1" label="退单金额">
                  <input
                    v-if="$store.state.userInfo.authStatus == 4 && (currentProductInfo.productInfo.prdType == 3 || currentProductInfo.productInfo.prdType == 8 || currentProductInfo.productInfo.prdType == 5)"
                    :disabled="backOrder.backOrderAmt == currentItemInfo.pa && productCount == currentItemInfo.pc"
                    v-model="backOrder.backOrderAmt" placeholder="请输入退款金额" @input="backOrderInputHandle" />
                  <span v-else>￥{{ refundAmount }}</span>
                </el-form-item>
                <!-- 退单、赠送理由 -->
                <el-form-item :label="'选择' + (status == 1 ? '退单' : (status == 2 ? '优惠' : '自用')) + '理由'"
                  class="required required6">
                  <ul class="reason-list" layout="row" layout-align="start center">
                    <li :class="{ 'active': isReasonActive(item) }" 
                        v-for="item in reasonList" 
                        :key="item.id"
                        @click="handleReasonClick(item)">{{ item.name }}</li>
                  </ul>
                </el-form-item>
              </el-form>
            </div>
          </div>
          <!-- 授权 -->
          <div v-else class="authorization">
            <p class="m-b-5 fs16">当前卡台：{{ $store.state.orderInfo.currentCardInfo.name }}</p>
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
                      <div class="td">{{ currentProductInfo.productInfo.name }}</div>
                      <div class="td">{{ productCount }}</div>
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
        </div>
        <!-- 更改套餐明细 -->
        <div v-if="status == 4">
          <p v-if="subStatus == 1" class="red">请选择更改的套餐明细</p>
          <ul v-if="subStatus == 1" class="choose-detail">
            <li v-for="(item, i) in updateDetail.groupList" :key="i" layout="row" layout-align="start center">
              <div class="left">
                <input type="radio" v-model="updateDetail.detailIndex" :value="i" />
              </div>
              <div class="right" layout="row" layout-align="start center">
                <p v-for="(items, index) in item.list" :key="index">{{ items.groupInfo.name }} * {{ items.sel_cnts ?
                  items.sel_cnts * items.dtl_prd_cnts * item.count : items.sc * items.dpc * item.count }}{{ items.r ?
    '（' + items.r + '）' : '' }}</p>
                <!-- items.sel_cnts是点单系统中的字段，items.sc是收银系统中的字段，此处所用的三元表达式用于区分点单系统和收银系统 -->
              </div>
            </li>
          </ul>

          <!-- 更改明细 -->
          <div v-if="subStatus == 2" class="add-requested">
            <groupProduct :productInfo="updateDetail.productInfo" :singleInfo="updateDetail.singleInfo"
              :selectedInfoObj="updateDetail.selectedInfoObj" isUpdate="true" @updateSelectedArr="updateSelectedArr" />
          </div>

          <!-- 更改明细授权 -->
          <div v-if="subStatus == 3">
            <div class="authorization">
              <p class="m-b-5 fs16">当前卡台：{{ $store.state.orderInfo.currentCardInfo.name }}</p>
              <ul layout="row" layout-align="center start">
                <li class="authorization-left">
                  <div class="pro-list">
                    <div class="pro-list-origin">
                      <p class="m-b-2 fs14">要更改的明细</p>
                      <div class="list-detail" layout="row" layout-align="start center">
                        <span v-for="(item, index) in updateDetail.selectedInfoObj[0].beforeUpdateProduct" :key="index">{{
                          item.productInfo.name }} * {{ item.selectedCount * item.prdCnt *
    updateDetail.singleInfo.prd_cnt }}{{ item.requireText ? '（' + item.requireText + '）' : ''
  }}</span>
                      </div>
                    </div>

                    <div class="pro-list-change">
                      <p class="m-b-2 fs14">更改后的套餐明细</p>
                      <div class="list-detail" layout="row" layout-align="start center">
                        <span v-for="(item, index) in updateDetail.selectedInfoObj[0].selectedProductsArr" :key="index">{{
                          item.productInfo.name }} * {{ item.selectedCount * item.prdCnt *
    updateDetail.singleInfo.prd_cnt }}{{ item.requireText ? '（' + item.requireText + '）' : ''
  }}</span>
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
          </div>
        </div>

        <!-- 退款套餐查看套餐明细 -->
        <div v-if="status == 5">
          <div class="table">
            <div class="thead">
              <div class="tr">
                <div class="th">明细项</div>
                <div class="th">数量</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" v-for="(item, i) in currentProductInfo.si" :key="i">
                <div class="td">{{ item.groupInfo.name }}{{ item.r ? '（' + item.r + '）' : '' }}</div>
                <div class="td">{{ !isNaN(item.sc * item.dpc) ? item.sc * item.dpc * currentItemInfo.pc : item.s * item.c
                  *
                  currentItemInfo.pc }}</div>
              </div>
            </div>
          </div>
        </div>

        <!-- 批量优惠/批量优惠2/批量退单 -->
        <div v-if="status == 6 || status == 7 || status == 8" class="seal-many">
          <div v-if="subStatus == 1">
            <div class="title m-b-4">请选择需要{{ status == 8 ? '退单' : '优惠' }}{{ status == 7 ? '2' : '' }}的商品</div>
            <div class="table">
              <div class="thead">
                <div class="tr" layout="row" layout-align="space-between center">
                  <div class="th">
                    <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll"
                      @change="changeCheckBox('all')">全选</el-checkbox>
                  </div>
                  <div class="th">名称</div>
                  <div class="th">数量</div>
                  <div class="th">{{ status == 8 ? '退单' : '优惠' }}{{ status == 7 ? '2' : '' }}数量</div>
                  <div class="th" v-if="status == 8" style="width:25%">退单小计</div>
                  <div class="th" v-if="status == 8" style="width:15%">店单人</div>
                </div>
              </div>
              <div class="tbody" :class="{ give: status == 6 }">
                <div class="coll online" layout="row" layout-align="space-between center"
                  v-for="(item, index) in sealProductList" :key="item.id">
                  <!-- 线上订单 -->
                  <div v-if="item.oid" class="tr online" layout="row" layout-align="space-between center">
                    <div class="td">
                      <el-checkbox v-model="item.checked" @change="changeCheckBox('item')">{{ index + 1 }}</el-checkbox>
                    </div>
                    <div class="td" :style="{ 'width': status == 8 ? '125%' : '' }">
                      <div class="column p-t-1 p-b-1" v-for="items in item.canBackOrderList" :key="items.id" layout="row"
                        layout-align="space-between center">
                        <div class="td-td" :style="{ 'width': status == 8 ? '32%' : '' }">{{ items.productInfo.name }}
                        </div>
                        <div class="td-td" :style="{ 'width': status == 8 ? '14%' : '' }">{{ items.pc }}</div>
                        <div class="td-td" :style="{ 'width': status == 8 ? '44%' : '' }">
                          <img
                            :src="items.changeCount == 1 || status == 8 ? require('@/assets/order-img/sub-disabled.png') : require('@/assets/order-img/sub.png')"
                            @click="changeCountOfSeal('sub', items)" alt />
                          <input type="number" :min="1" :disabled="status == 8" v-model="items.changeCount"
                            @input="changeCountOfSeal('input', items)" />
                          <img
                            :src="items.changeCount >= items.pc ? require('@/assets/order-img/add-disabled.png') : require('@/assets/order-img/order_add.png')"
                            @click="changeCountOfSeal('add', items)" alt />
                        </div>
                        <div class="td-td" v-if="status == 8" style="width:25%">{{ items.allAmt }}</div>
                        <div class="td-td" v-if="status == 8" style="width:15%">{{ items.personInfo &&
                          items.personInfo.name }}</div>
                      </div>
                    </div>
                  </div>
                  <!-- 线下订单 -->
                  <div v-else class="tr offline" layout="row" layout-align="space-between center">
                    <div class="td">
                      <el-checkbox v-model="item.checked" @change="changeCheckBox('item')">{{ index + 1 }}</el-checkbox>
                    </div>
                    <div class="td">{{ item.productInfo.name }}</div>
                    <div class="td">{{ item.pc }}</div>
                    <div class="td">
                      <img
                        :src="item.changeCount == 1 ? require('@/assets/order-img/sub-disabled.png') : require('@/assets/order-img/sub.png')"
                        @click="changeCountOfSeal('sub', item)" alt />
                      <input type="number" :min="1" v-model="item.changeCount"
                        @input="changeCountOfSeal('input', item)" />
                      <img
                        :src="item.changeCount >= item.pc ? require('@/assets/order-img/add-disabled.png') : require('@/assets/order-img/order_add.png')"
                        @click="changeCountOfSeal('add', item)" alt />
                    </div>

                    <div class="td" v-if="status == 8" style="width:25%">
                      <div v-if="['5', '3', '8'].indexOf(item.productInfo.prdType) > -1">
                        <input style="width:80%;height:26px;padding: 0 8px" v-if="item.changeCount < item.pc"
                          type="number" @input="changeAmtHandle(item)" v-model="item.allAmt" min="0"
                          placeholder="请输入金额" />
                        <span v-else>{{ item.allAmt }}</span>
                      </div>
                      <div v-else>{{ item.pp == 0 ? (item.pa * 1).toFixed(2) : (item.pp * item.changeCount).toFixed(2) }}
                      </div>
                    </div>
                    <div class="td" v-if="status == 8" style="width:15%">{{ item.personInfo && item.personInfo.name }}
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="form" v-if="status == 6 || status == 8">
              <el-form label-position="right" label-width="150px" :model="formData" @submit.native.prevent>
                <el-form-item>
                  <ul class="reason-list" layout="row" layout-align="start center">
                    <li :class="{ 'active': isReasonActive(item) }" 
                        v-for="item in reasonList" 
                        :key="item.id"
                        @click="handleReasonClick(item)">{{ item.name }}</li>
                  </ul>
                </el-form-item>
                <el-form-item :label="'选择批量' + (status == 6 ? '优惠' : '退单') + '理由'">
                  <input v-model="formData.reason" 
                         style="width:60%;height:34px;padding: 0 20px" 
                         placeholder="请输入理由" />
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
                    <div class="tr" layout="row" layout-align="start start"
                      v-for="(item, index) in sealManyInfo.choosePrdList" :key="item.id">
                      <div class="td">{{ index + 1 }}</div>
                      <div class="td">{{ item.productInfo.name }}</div>
                      <div class="td">{{ item.pc }}</div>
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
        </div>


        <!-- 取消优惠 -->

        <div v-if="status == 10" class="my-order-drawer-content">
          <div v-if="subStatus == 1">
            <!-- 表单 -->
            <div class="form">
              <el-form label-position="right" label-width="150px" :model="formData" @submit.native.prevent>
                <!-- 商品名称 -->
                <el-form-item label="当前商品">{{ currentItemInfo.productInfo && currentItemInfo.productInfo.name
                }}</el-form-item>
                <el-form-item label="优惠数量">{{ currentItemInfo.pc }}</el-form-item>
                <el-form-item label="优惠小计">{{ (currentItemInfo.pa * 1).toFixed(2) }}</el-form-item>
                <el-form-item label="优惠人">{{ currentItemInfo.authInfo && currentItemInfo.authInfo.name }}</el-form-item>
                <!-- 退单、赠送理由 -->
                <el-form-item label="选择取消原因" class="required required6">
                  <ul class="reason-list" layout="row" layout-align="start center">
                    <li :class="{ 'active': isReasonActive(item) }" 
                        v-for="item in reasonList" 
                        :key="item.id"
                        @click="handleReasonClick(item)">{{ item.name }}</li>
                  </ul>
                </el-form-item>
              </el-form>
            </div>
          </div>
        </div>


        <div v-if="status == 11" class="my-order-drawer-content">
          <!-- 表单 -->
          <div class="form">
            <el-form label-position="right" label-width="150px"  @submit.native.prevent>
              <h3 class="m-b-4 m-l-4">修改下单人</h3>
              <!-- 修改下单人 -->
              <el-form-item  label="原下单人：">{{ formData.originName }}</el-form-item>
              <el-form-item label="下单人：">
                <input-select
                  :autoFocus="true"
                  style="width: 200px"
                  :value="formData.sales.sales_name"
                  placeholder="请输入姓名或工号"
                  :optionsList="formData.sales.sales_info_option"
                  @selectInputHandle="inputSealName"
                  @selectOptionItem="changeSealName"
                  @selectBlurHandle="selectBlurHandle"
                ></input-select>
              </el-form-item>
            </el-form>
          </div>
        </div>


        <div v-if="status == 99" class="my-order-drawer-content">
          <div class="form">
            <el-form label-position="right" label-width="150px"  @submit.native.prevent>
              <h3 class="m-b-4 m-l-4">修改授权人</h3>
              <el-form-item  label="原授权人：">{{  }}</el-form-item>
              <el-form-item label="授权人：">
                <input-select
                    :autoFocus="true"
                    style="width: 200px"
                    :value="formData.aes.sales_name"
                    placeholder="请输入姓名或工号"
                    :optionsList="formData.aes.sales_info_option"
                    @selectInputHandle="inputAeName"
                    @selectOptionItem="changeAeName"
                    @selectBlurHandle="selectAeBlurHandle"
                ></input-select>
              </el-form-item>
            </el-form>
          </div>
        </div>

        <!-- 批量提交优惠2 -->
        <drawerYH2Submit ref="drawerYH2Submit" :showDrawer="sealMany2Info.showYH2Drawer"
          :selectedProList="sealMany2Info.choosePrdList" :showSelfBtn="sealMany2Info.authLimits"
          @showOrHideDrawer="showOrHideYH2Drawer" @showOrHideAnotherDrawer="onCancelDrawer" />

        <!-- 提交按钮 -->
        <div class="form-btn" layout="row" layout-align="center center">
          <el-button type="info" @click.stop="onCancelDrawer(false)">{{ status == 5 ? '关闭' : '取消' }}</el-button>
          <el-button
            v-if="(status == 9 || (status == 1 || (status == 2 && currentItemInfo && currentItemInfo.productInfo && currentItemInfo.productInfo.canSeal) || status == 3) && subStatus == 2) || (status == 4 && subStatus == 3) || (status == 6 && subStatus == 2)"
            type="primary" @click.stop="onSubmit('self')">自己授权</el-button>
          <el-button type="primary" v-if="status == 10" @click.stop="onSubmit('another')">下一步</el-button>
          <el-button type="primary" v-if="status != 5 && status != 10" @click.stop="onSubmit('another')">{{ submitTxt
          }}</el-button>
        </div>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import eventVue from '@/utils/eventVue';

import api_order from "@/api/order";
import api_money from "@/api/money";
import common_order from "@/utils/common/order";
import { buildPriceContextFromStore, calcItemAmount } from "@/utils/orderItemPrice";

import add from "@/assets/order-img/order_add.png";
import sub from "@/assets/order-img/sub.png";
import addDisabled from "@/assets/order-img/add-disabled.png";
import subDisabled from "@/assets/order-img/sub-disabled.png";

import selectCheckbox from "@/components/order/selectCheckbox";
import groupProduct from "@/components/order/drawerMeal/groupProduct";
import authorization from "@/components/order/shoppingCart/authorizationWithNoPwd";
// import authorization from "@/components/order/shoppingCart/authorization";
import inputSelect from "@/components/book/inputSelect";
import drawerYH2Submit from "@/components/order/drawerMeal/drawerYH2Submit.vue";

import md5 from "js-md5";
export default {
  data() {
    return {
      backOrderIndex: 0,  // 批量退单的数量下标

      show: false,
      // 赠送、自用、更改套餐明细
      subStatus: 1, // 1: 自用、授权处于第一步选择商品及数量页面  2：自用、授权处于授权页面  3:更改套餐明细授权
      productCount: 1, // 退单赠送等操作的商品数量
      currentProductInfo: {
        productInfo: {
          name: "",
          prdType: 1
        }
      }, // 当前需要操作的商品信息
      formData: {
        radio: "1",
        selectedReasonId: '', // 添加选中的理由 ID
        reason: '',
        isCustomReason: false,
        originName: '', // 原下单人
        originAe:'', //原授权人
        sales: {
          sales_name: "", // 订位人名称
          sales_emp_id: "", // 订位人id
          sales_info_option: [], // 下单人下拉框选项
        }, // 下单人
        aes: {
          sales_name: "", // 授权人
          sales_emp_id: "", // id
          sales_info_option: [], // 下拉框选项
        }, // 授权人
      },

      backOrder: {
        backOrderAmt: ""
      },

      // 授权
      authorizationInfo: {
        userName: "",
        passWord: ""
      },

      // 更改明细
      updateDetail: {
        detailIndex: 0, // 更改套餐明细角标
        productInfo: {}, // 当前修改订单信息
        singleInfo: {}, // 当前订单的数量和要求
        groupList: [], // 当前套餐组列表
        selectedInfoObj: [
          // 已选择要更改的商品相关明细
          {
            beforeUpdateProduct: [], // 替换前商品数据
            selectedProductsArr: [] // 替换后的商品列表
          }
        ]
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
      },
    };
  },
  methods: {

     // 获取模糊查询订位人的相关信息
     inputSealName(query) {
      this.formData.sales.sales_name = query;
      this.formData.sales.sales_phone = "";
      this.formData.sales.sales_emp_id = "";
      const sealInfoArr =
        this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo || [];
      const results = query
        ? sealInfoArr.filter(
            (el) =>
              el.code.toString().includes(query) ||
              el.name.toString().includes(query) ||
              el.namePy.toString().includes(query.toLowerCase())
          )
        : sealInfoArr;
      this.formData.sales.sales_info_option = results;
    },
    inputAeName(query) {
      this.formData.aes.sales_name = query;
      this.formData.aes.sales_phone = "";
      this.formData.aes.sales_emp_id = "";
      const sealInfoArr =
          this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo || [];
      const results = query
          ? sealInfoArr.filter(
              (el) =>
                  el.code.toString().includes(query) ||
                  el.name.toString().includes(query) ||
                  el.namePy.toString().includes(query.toLowerCase())
          )
          : sealInfoArr;
      this.formData.aes.sales_info_option = results;
    },
    // 选择订位人的信息
    changeSealName(info) {
      this.formData.sales.sales_name = info.name;
      this.formData.sales.sales_phone = info.phoneNum;
      this.formData.sales.sales_emp_id = info.id;
      this.formData.sales.sales_info_option = [];
    },
    changeAeName(info) {
      this.formData.aes.sales_name = info.name;
      this.formData.aes.sales_phone = info.phoneNum;
      this.formData.aes.sales_emp_id = info.id;
      this.formData.aes.sales_info_option = [];
    },
    selectBlurHandle() {
      this.formData.sales.sales_info_option = [];
    },
    selectAeBlurHandle() {
      this.formData.aes.sales_info_option = [];
    },
    /**
     * 退单
     */

    // 收银系统特饮花篮退单金额输入框
    backOrderInputHandle() {
      if (this.backOrder.backOrderAmt * 1 > this.currentItemInfo.pa) {
        this.$message.warning(
          "退单金额不可超过可退单金额" + this.currentItemInfo.pa + "元"
        );
      }
      this.backOrder.backOrderAmt = Math.min(
        this.backOrder.backOrderAmt * 1,
        this.currentItemInfo.pa
      );
    },

    // 更改赠送、自用商品数量
    changeCount(type) {
      if (this.currentItemInfo.productInfo.prdType == 4)
        return this.$message.warning("小费数量不可修改");

      // 线上订单不支持修改数量
      if (this.status == 1 && this.currentItemInfo.io == 1) {
        return this.$message.warning('线上订单退单不支持修改数量')
      }
      switch (type) {
        case "add":
          this.productCount = Math.min(
            this.productCount + 1,
            this.currentItemInfo.pc
          );
          break;
        case "sub":
          if (
            (this.currentProductInfo.productInfo.prdType == 3 ||
              this.currentProductInfo.productInfo.prdType == 8 ||
              this.currentProductInfo.productInfo.prdType == 5) &&
            this.$store.state.userInfo.authStatus != 4
          )
            return;
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

      // 当数量达到了总数量，退单金额为全部金额
      this.backOrder.backOrderAmt =
        this.productCount == this.currentItemInfo.pc
          ? this.currentItemInfo.pa * 1
          : "";
    },

    goAuthorization() {
      // if (!this.formData.reason) return this.$message.warning('请输入理由');
      this.subStatus = 2;
    },

    updateAuthorizationInfo({ key, value }) {
      this.authorizationInfo[key] = value;
    },

    // 获取修改套餐组的明细
    getGroupDetail(productId, groupId) {
      const groupDetailArr = this.$store.state.cardPageInfo.resResultDataObj.goodsDetailInfo.filter(
        el => el.status == 1 && el.prdId == productId
      );

      // 排序
      const groupCanSelectArr = groupDetailArr
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

    // 刷卡授权
    swipingOrderHandle(empCardInfo) {
      if (this.show && (this.subStatus == 2 || this.status == 9)) {
        const childrenVNode = this.$children[0].$children || []
        childrenVNode.forEach(el => {
          if (el.$el.className == 'auth') {
            if (el.tabIndex == 1) {
              // 刷卡
              if (this.status == 1) {
                // 退单
                this.orderBack('another', empCardInfo, 2)
              } else if (this.status == 2) {
                // 优惠
                this.onSubmit('another', empCardInfo, 2)
              } else if (this.status == 6) {
                // 批量优惠
                this.onSubmit('another', empCardInfo, 2)
              }
              else if (this.status == 9) {
                // 修改优惠人
                this.onSubmit('another', empCardInfo, 2)
              }
            } else {
              this.$message.warning('当前为输入账号授权，不可刷卡')
            }
          }
        })
      } else if (this.show && this.status == 4 && this.subStatus == 3) {
        this.$nextTick(() => {
          const childrenVNode = this.$children[0].$children || []
          childrenVNode.forEach(el => {
            if (el.$el.className == 'auth') {
              if (el.tabIndex == 1) {
                // 修改明细
                this.changGroupFromOrderPerson('another', empCardInfo, 2)
              } else {
                this.$message.warning('当前为输入账号授权，不可刷卡')
              }
            }
          })
        })
      } else if (this.status == 7) {
        // 批量优惠2
        const childrenVNodeYH2 = this.$refs.drawerYH2Submit.$children[0].$children || []
        childrenVNodeYH2.forEach(el => {
          if (el.$el.className == 'auth') {
            if (el.tabIndex == 1) {
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

    getCodeAndPwd(personType, empCardInfo, type) {
      let authEmpCode = ''
      let authEmpPasswd = ''
      if (type == 1) {
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

    // 下单商品退单(单个商品退单)
    async orderBack(personType, empCardInfo = {}, type = 1) {
      if (!this.formData.reason) return this.$message.warning('请选择退单理由')
      let back_amt = "";
      if (
        [3, 5, 8].includes(this.currentItemInfo.productInfo.prdType * 1)
      ) {
        // 花篮/赔偿
        if (this.$store.state.userInfo.authStatus == 4) {
          back_amt = this.backOrder.backOrderAmt.toString();
          if (!back_amt) return this.$message.warning("请输入退款金额");
        } else {
          back_amt = this.currentItemInfo.pa.toString();
        }
      }

      const { authEmpCode, authEmpPasswd } = this.getCodeAndPwd(personType, empCardInfo, type)


      const loading = this.$loading({
        lock: true,
        text: "Loading",
        spinner: "el-icon-loading",
        background: "rgba(0, 0, 0, 0.7)"
      });

      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64  卡台Id
        order_id: this.currentItemInfo.id * 1, //   int64   订单项Id
        back_cnt: this.productCount * 1, //   int     退商品数量 小费类型数量必须=1
        back_amt, //   string  退商品金额 花篮/存货花篮/赔偿 需要传退单金额,其他不要传
        back_remark: this.formData.reason || "", // string  退单理由
        auth_emp_code: authEmpCode, // string  授权员工工号, 如果不传, 代表本账号授权
        auth_emp_passwd: authEmpPasswd, // string   授权员工密码
        pass_type: type  // 1:账号密码， 2：刷卡
      };

      try {
        const api = this.currentItemInfo.isOnline ? 'reqBackOnlineOrder' : 'reqBackOrder'
        const res = await api_order[api](params);
        if (res.code === 1) {
          this.onCancelDrawer(true);
          switch (this.$route.name) {
            case "myOrder": // 点单系统，我的订单页面
              this.$message.success("退单成功");
              this.$parent.getOrderedData();
              break;
            case "payOrder": // 收银系统，未支付订单页面
              this.$message.success("退单成功");
              this.$parent.$parent.getOrderInfo();
              break;
          }
        } else if (res.code == 2) {
          if (this.subStatus == 2) {
            window.loopReadCard()
            this.$message.warning(res.msg)
          }
          if (this.subStatus == 1) this.goAuthorization();
        } else {
          if (this.subStatus == 2) window.loopReadCard()
          this.$message.warning(res.msg);
        }
      } catch (error) {
        window.loopReadCard()
        console.log("退单失败");
      }

      loading.close();
    },

    // 收银批量退单(批量循环退单)
    async orderBackMany(currentItemInfo, personType, empCardInfo = {}, type = 1, callback) {
      let back_amt = "";
      if (
        [3, 5, 8].includes(currentItemInfo.productInfo.prdType * 1)
      ) {
        // 花篮/赔偿
        back_amt = currentItemInfo.allAmt.toString();
      }

      const { authEmpCode, authEmpPasswd } = this.getCodeAndPwd(personType, empCardInfo, type)

      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64  卡台Id
        order_id: currentItemInfo.id * 1, //   int64   订单项Id
        back_cnt: currentItemInfo.pc * 1, //   int     退商品数量 小费类型数量必须=1
        back_amt, //   string  退商品金额 花篮/存货花篮/赔偿 需要传退单金额,其他不要传
        back_remark: this.formData.reason || "", // string  退单理由
        auth_emp_code: authEmpCode, // string  授权员工工号, 如果不传, 代表本账号授权
        auth_emp_passwd: authEmpPasswd, // string   授权员工密码
        pass_type: type  // 1:账号密码， 2：刷卡
      };

      try {
        const api = currentItemInfo.io == 1 ? 'reqBackOnlineOrder' : 'reqBackOrder'
        const res = await api_order[api](params);
        if (res.code === 1) {
          callback && callback()
        } else if (res.code == 2) {
          if (this.subStatus == 2) {
            window.loopReadCard()
            this.$message.warning(res.msg)
          }
          if (this.subStatus == 1) this.goAuthorization();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("退单失败");
      }
    },

    // 更改批量退单赔偿、小费商品金额
    changeAmtHandle(itemInfo) {
      if (itemInfo.allAmt * 1 > itemInfo.pa * 1) {
        this.$message.warning('不可超过最大金额' + itemInfo.pa)
        itemInfo.allAmt = itemInfo.pa * 1
      } else if (itemInfo.allAmt * 1 < 0) {
        this.$message.warning('最小金额为0')
        itemInfo.allAmt = 0
      }
    },
    /**
     * 更改明细
     */

    updateSelectedArr(selectProInfo) {
      this.updateDetail.selectedInfoObj = [selectProInfo];
    },

    // 非收银员更改套餐明细
    async changGroupFromOrderPerson(personType, empCardInfo = {}, type = 1) {
      const {
        selectedProductsArr
      } = this.updateDetail.selectedInfoObj[0];

      const {
        beforeUpdateProduct
      } = this.updateDetail.selectedInfoObj[0];

      const { authEmpCode, authEmpPasswd } = this.getCodeAndPwd(personType, empCardInfo, type)

      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, // int64   卡台Id
        auth_emp_code: authEmpCode, // string  授权员工工号, 如果不传, 代表本账号授权
        auth_emp_passwd: authEmpPasswd, // string  授权员工密码
        order_id: this.currentProductInfo.id * 1, // int64    购物车项Id
        // grp_id: selectedProductsArr[0].grpId * 1, // int     套餐组Id
        // dtl_prd_id:
        //   this.updateDetail.selectedInfoObj[0].beforeUpdateProduct[0]
        //     .dtlPrdId * 1, // int64  套餐组Id对应的被替换明细商品Id
        // requirement: beforeUpdateProduct[0].requireText, // string   套餐组Id对应的被替换明细商品要求

        // order_dtl_id: '', // int64      //OrderDtlId 被替换子订单项的Id
        order_dtl_id: this.updateDetail.groupList[this.updateDetail.detailIndex].list[0].id, // int64 OrderDtlId 被替换子订单项的Id

        dest_dtl_prd_ids: selectedProductsArr.map(el => el.dtlPrdId * 1), // []int64   套餐组Id对应的替换目标商品列表
        dest_dtl_prd_sel_cnts: selectedProductsArr.map(
          el => el.selectedCount * 1
        ), // []int    对应上面dest_dtl_prd_ids的选中数
        dest_requirements: selectedProductsArr.map(el => el.requireText), // []string  套餐组Id对应的替换目标商品要求
        pass_type: type  // 1:账号密码， 2：刷卡
      };

      try {
        const res = await api_order.reqChangeOrderDetailWhenNotOrdered(params);
        if (res.code === 1) {
          this.$message.success("修改明细成功");
          this.onCancelDrawer(true);
          this.$parent.getOrderedData();
        } else if (res.code == 2) {
          if (this.subStatus == 2) this.subStatus = 3;
          else {
            window.loopReadCard()
            this.$message.warning(res.msg);
          }
        } else {
          window.loopReadCard()
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("更改套餐明细失败", error);
      }
    },

    // 取消优惠
    async orderCancelDiscounts() {
      if (!this.formData.reason) return this.$message.warning('请选择取消优惠原因')
      this.$confirm("取消优惠后，商品将进入未结账列表，需要客人结账，请确认是否取消优惠", "确认", {
        distinguishCancelAndClose: true,
        confirmButtonText: "确定",
        cancelButtonText: "取消",
      }).then(async () => {
        try {
          const params = {
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64    卡台Id
            order_id: this.currentItemInfo.id * 1, // int64   订单项Id
            remark: this.formData.reason, //  int  修改后数量 =0表示删除
          };
          const res = await api_order.reqCancelDiscount(params);
          if (res.code === 1) {
            this.$message.success('取消优惠成功');
            this.onCancelDrawer(true);
            switch (this.$route.name) {
              case "myOrder": // 点单系统，我的订单页面
                this.$parent.getOrderedData();
                break;
              case "payOrder": // 收银系统，未支付订单页面
                this.$parent.$parent.getOrderInfo();
                break;
            }
          } else {
            this.$message.warning(res.msg);
          }
        } catch (error) {
          console.log("取消优惠失败", error);
        }
      })
        .catch(() => {

        });
    },
    // 提交
    async onSubmit(personType, empCardInfo = {}, type = 1) {
      // personType:{self:自己授权, another:别人授权}
      let authEmpCode = ''
      let authEmpPasswd = ''
      let params = {}
      switch (this.status) {
        case 1: // 退单
          this.orderBack(this.subStatus == 1 ? 'self' : 'another', {}, 1)
          break;
        case 2: // 优惠
        case 3: // 自用
          if (this.subStatus == 1) return this.goAuthorization();

          authEmpCode = this.getCodeAndPwd(personType, empCardInfo, type).authEmpCode
          authEmpPasswd = this.getCodeAndPwd(personType, empCardInfo, type).authEmpPasswd

          params = {
            auth_emp_code: authEmpCode, // string  授权员工工号, 如果不传, 代表本账号授权
            auth_emp_passwd: authEmpPasswd, // string  授权员工密码
            auth_reason: this.formData.reason, // string   授权理由
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64    卡台Id
            order_ids: [this.currentProductInfo.id * 1], // int64   订单项Id
            auth_cnts: [this.productCount * 1], //  int   授权商品数量
            pass_type: type  // 1:账号密码， 2：刷卡
          };

          if (!params.auth_emp_code && personType != "self") {
            return this.$message.warning("请输入授权员工号");
          }
          if (!params.auth_emp_passwd && personType != "self") {
            return this.$message.warning("请输入授权密码");
          }
          try {
            const res = await api_order.reqGiveSomeWhenHadOrdered(params);
            if (res.code == 1) {
              this.$message.success(
                `${this.status == 2 ? "优惠" : "自用"}成功`
              );
              this.onCancelDrawer(true);
              switch (this.$route.name) {
                case "myOrder": // 点单系统，我的订单页面
                  this.$parent.getOrderedData();
                  break;
                case "payOrder": // 收银系统，未支付订单页面
                  this.$parent.$parent.getOrderInfo();
                  break;
              }
            } else {
              window.loopReadCard()
              this.$message.warning(res.msg);
            }
          } catch (error) {
            window.loopReadCard()
            console.log("优惠授权失败", error);
          }
          break;
        case 4: // 更改明细
          if (this.subStatus == 1) {
            this.subStatus = 2;
            this.initGroupProductInfo();
          } else if (this.subStatus == 2) {
            // 判断当前身份，如果为收银员，则不需要授权，否则必须授权(服务员默认调用自己授权，无权限时别人授权)
            if (this.$store.state.userInfo.authStatus == 4) {
              // 收银系统
              const {
                selectedProductsArr
              } = this.updateDetail.selectedInfoObj[0];

              const {
                beforeUpdateProduct
              } = this.updateDetail.selectedInfoObj[0];

              params = {
                seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64  卡台Id
                order_id: this.currentProductInfo.id * 1, //   int64   订单项Id
                // grp_id: selectedProductsArr[0].grpId * 1, //     int    套餐组Id
                // dtl_prd_id:
                //   this.updateDetail.selectedInfoObj[0].beforeUpdateProduct[0]
                //     .dtlPrdId * 1, // int64    套餐组Id对应的被替换明细商品Id
                // requirement: beforeUpdateProduct[0].requireText, // string   套餐组Id对应的被替换明细商品要求
                order_dtl_id: this.updateDetail.groupList[this.updateDetail.detailIndex].list[0].id, // int64 OrderDtlId 被替换子订单项的Id
                dest_dtl_prd_ids: selectedProductsArr.map(
                  el => el.dtlPrdId * 1
                ), // []int64    套餐组Id对应的替换目标商品列表
                dest_dtl_prd_sel_cnts: selectedProductsArr.map(
                  el => el.selectedCount * 1
                ), // []int    对应上面dest_dtl_prd_ids的选中数
                dest_requirements: selectedProductsArr.map(el => el.requireText) // []string    套餐组Id对应的替换目标商品要求
              };

              try {
                const res = await api_money.reqUpdateGroupProductDetail(params);
                if (res.code == 1) {
                  this.onCancelDrawer(true);
                  switch (this.$route.name) {
                    case "myOrder": // 点单系统，我的订单页面
                      this.$parent.getOrderedData();
                      break;
                    case "payOrder": // 收银系统，未支付订单页面
                      this.$parent.$parent.getOrderInfo();
                      break;
                  }
                } else {
                  window.loopReadCard()
                  this.$message.warning(res.msg);
                }
              } catch (error) {
                window.loopReadCard()
                console.log("更改套餐明细失败", error);
              }
              return;
            } else {
              // 点单系统，自己授权
              this.changGroupFromOrderPerson('self')
            }
          } else if (this.subStatus == 3) {
            // 提交更改明细授权(点单系统)(自己没权限，别人授权)
            this.changGroupFromOrderPerson('another')
          }
          break;

        case 6:
          // 确认批量优惠商品
          if (this.subStatus == 1) {
            this.sealManyInfo.choosePrdList = this.sealProductList.filter(item => item.checked && item.changeCount > 0).map(item => ({
              ...item,
              pc: item.changeCount
            }))
            if (this.sealManyInfo.choosePrdList.length == 0) return this.$message.warning('请选择需要批量优惠的商品和数量')
            // 判断当前操作人员是否有全部商品优惠的权限
            this.sealManyInfo.authLimits = this.sealManyInfo.choosePrdList.every(item => item.productInfo.canSeal)
            return this.goAuthorization();
          }

          authEmpCode = this.getCodeAndPwd(personType, empCardInfo, type).authEmpCode
          authEmpPasswd = this.getCodeAndPwd(personType, empCardInfo, type).authEmpPasswd

          params = {
            auth_emp_code: authEmpCode, // string  授权员工工号, 如果不传, 代表本账号授权
            auth_emp_passwd: authEmpPasswd, // string  授权员工密码
            auth_reason: this.formData.reason, // string   授权理由
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64    卡台Id
            order_ids: this.sealManyInfo.choosePrdList.map(item => item.id * 1), // []int64    要授权的购物车项Id
            auth_cnts: this.sealManyInfo.choosePrdList.map(item => item.pc * 1), //  []int   要授权的购物车项Id对应的数量
            pass_type: type  // 1:账号密码， 2：刷卡
          };

          if (!params.auth_emp_code && personType != "self") {
            return this.$message.warning("请输入授权员工号");
          }
          if (!params.auth_emp_passwd && personType != "self") {
            return this.$message.warning("请输入授权密码");
          }
          try {
            const res = await api_order.reqGiveSomeWhenHadOrdered(params);
            if (res.code == 1) {
              this.$message.success('批量优惠成功');
              this.onCancelDrawer(true);
              switch (this.$route.name) {
                case "myOrder": // 点单系统，我的订单页面
                  this.$parent.getOrderedData();
                  break;
                case "payOrder": // 收银系统，未支付订单页面
                  this.$parent.$parent.getOrderInfo();
                  break;
              }
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
          this.sealMany2Info.choosePrdList = this.sealProductList.filter(item => item.checked && item.changeCount > 0).map(item => ({
            ...item,
            pc: item.changeCount
          }))
          if (this.sealMany2Info.choosePrdList.length == 0) return this.$message.warning('请选择需要批量优惠2的商品')
          // 判断当前操作人员是否有全部商品优惠2的权限
          this.sealMany2Info.authLimits = this.sealMany2Info.choosePrdList.every(item => item.productInfo.canSeal)
          this.showOrHideYH2Drawer()

          break
        case 8:  // 批量退单
          if (!this.formData.reason) return this.$message.warning('请选择退单理由')
          this.backOrderIndex = 0
          const onlineBackPrdList = this.sealProductList.filter(item => item.checked && item.oid).map(item => item.canBackOrderList).flat()
          const localBackPrdList = this.sealProductList.filter(item => item.checked && !item.oid)
          const backManyPrdList = [...onlineBackPrdList, ...localBackPrdList].map(item => ({
            ...item,
            pc: item.changeCount
          }))
          if (backManyPrdList.length == 0) return this.$message.warning('请选择需要批量退单的商品')
          if (backManyPrdList.some(item => item.allAmt == '')) return this.$message.warning('请输入退单小计金额')
          backManyPrdList.forEach(el => {
            setTimeout(() => {
              this.orderBackMany(el, 'self', {}, 1, backManyPrdList => {
                this.$parent.$parent.getOrderInfo();
                // this.$message.success('退单成功')
                this.$emit('closeBackDrawer', true);

              })
            }, 200 * this.backOrderIndex);
            this.backOrderIndex += 1
          })

          break
        case 9:
          authEmpCode = this.getCodeAndPwd(personType, empCardInfo, type).authEmpCode
          authEmpPasswd = this.getCodeAndPwd(personType, empCardInfo, type).authEmpPasswd

          params = {
            auth_emp_code: authEmpCode, // string  授权员工工号, 如果不传, 代表本账号授权
            auth_emp_passwd: authEmpPasswd, // string  授权员工密码
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64    卡台Id
            order_id: this.currentProductInfo.id * 1, // int64   订单项Id
            pass_type: type  // 1:账号密码， 2：刷卡
          };

          if (!params.auth_emp_code && personType != "self") {
            return this.$message.warning("请输入授权员工号");
          }
          if (!params.auth_emp_passwd && personType != "self") {
            return this.$message.warning("请输入授权密码");
          }
          try {
            const res = await api_order.chg_yh_auth_emp(params);
            if (res.code == 1) {
              this.$message.success('修改优惠/优惠2授权人成功');
              this.onCancelDrawer(true);
              switch (this.$route.name) {
                case "myOrder": // 点单系统，我的订单页面
                  this.$parent.getOrderedData();
                  break;
                case "payOrder": // 收银系统，未支付订单页面
                  this.$parent.$parent.getOrderInfo();
                  break;
              }
            } else {
              window.loopReadCard()
              this.$message.warning(res.msg);
            }
          } catch (error) {
            window.loopReadCard()
            console.log("修改优惠/优惠2授权人失败", error);
          }
          break
        case 10: // 取消优惠
          this.orderCancelDiscounts()
          break;
        case 11: // 修改订位人
          this.changeWkorderWaiter()
          break
        case 99://修改授权人
              this.changeShouquan()
      }
    },

    async changeShouquan(){
      console.log('---------------changeShouquan')
      try{
        const params = {
          seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64    卡台Id
          order_id: this.currentItemInfo.id * 1, // int64   订单项Id
          auth_emp_id: this.formData.aes.sales_emp_id * 1, // string   订位人
        };
        const res = await api_money.chg_wkorder_auther(params)
        if (res.code == 1) {
          this.$message.success('修改授权人成功');
          this.$parent.$parent.getOrderInfo();
          this.onCancelDrawer(true);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("修改授权人失败", error);
      }
    },
    async changeWkorderWaiter(){
      try{
        const params = {
          seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64    卡台Id
          order_id: this.currentItemInfo.id * 1, // int64   订单项Id
          waiter_emp_id: this.formData.sales.sales_emp_id * 1, // string   订位人
        };
        const res = await api_money.reqChgWkorderWaiter(params)
        if (res.code == 1) {
          this.$message.success('修改下单人成功');
          this.$parent.$parent.getOrderInfo();
          this.onCancelDrawer(true);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("修改订位人失败", error);
      }
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
            if (this.status == 8 && info.io == 1) {
              // 线上订单批量退单
              return this.$message.warning('线上订单不可修改退单数量')
            }
            count = Math.max(count - 1, 1);
            break;
          case "input":
            count = Math.min(count, info.pc);
            count = Math.max(count, 1);
            break;
        }
        info.changeCount = count;
        if (['5', '3', '8'].indexOf(info.productInfo.prdType) > -1) {
          if (info.changeCount == info.pc) {
            info.allAmt = info.pa
          }
        }
        this.$forceUpdate();
      }
    },

    showOrHideYH2Drawer() {
      this.sealMany2Info.showYH2Drawer = !this.sealMany2Info.showYH2Drawer
    },

    // 选择需要批量优惠/批量优惠2的商品
    changeCheckBox(type) {
      switch (type) {
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
      this.authorizationInfo = {}
      this.authorizationInfo.userName = "";
      this.authorizationInfo.passWord = "";
      if (this.subStatus > 1 && !isClose) {
        this.subStatus -= 1;
      } else {
        this.currentProductInfo = {
          productInfo: {
            name: "",
            prdType: 1
          }
        };
        this.$emit("showOrHideDrawer", this.status);
      }
    },

    isReasonActive(item) {
      return this.formData.selectedReasonId === item.id;
    },

    handleReasonClick(item) {
      this.formData.selectedReasonId = item.id; // 记录选中的理由 ID
      
      if (item.id === "1") {
        this.formData.reason = "";
        this.formData.isCustomReason = true;
      } else {
        this.formData.reason = item.name;
        this.formData.isCustomReason = false;
      }
    }
  },
  created() { },
  mounted() { },
  props: {
    showDrawer: {
      default: false
    },
    status: {
      default: 1
    },
    currentItemInfo: {
      default: () => ({
        productInfo: {
          name: "",
          prdType: 1
        }
      })
    },
    orderList: {
      default: () => []
    }
  },
  computed: {
    // ✅ 计算退单金额（使用通用价格计算逻辑，优先使用 p2 会员价）
    refundAmount() {
      if (!this.currentProductInfo) return '0.00';

      try {
        const ctx = buildPriceContextFromStore(this.$store);
        // 创建一个临时商品对象，包含退单数量
        const tempItem = {
          ...this.currentProductInfo,
          pc: this.productCount,
          changeCount: this.productCount
        };
        const amt = calcItemAmount(tempItem, ctx);
        return (amt || 0).toFixed(2);
      } catch (e) {
        // fallback to original logic
        return this.currentProductInfo.pp * 1 == 0
          ? this.currentProductInfo.pa
          : (this.currentProductInfo.pp * this.productCount).toFixed(2);
      }
    },
    title() {
      let title = "";
      switch (this.status) {
        case 1:
          title = "退单";
          break;
        case 2:
          title = "优惠";
          break;
        case 3:
          title = "自用";
          break;
        case 4:
          title =
            this.subStatus == 1
              ? "选择套餐明细"
              : this.subStatus == 2
                ? "更改套餐明细"
                : "更改套餐明细授权";
          break;
        case 5:
          title = "查看套餐明细";
          break;
        case 6:
          title = '批量优惠'
          break
        case 7:
          title = '批量优惠2'
          break
        case 8:
          title = '批量退单'
          break
        case 9:
          title = '修改优惠人'
          break
        case 10:
          title = '取消优惠'
      }
      if (this.status != 4 && this.subStatus != 1) title = "授权";
      return title;
    },
    size() {
      let size = "60%";
      if ((this.status === 4 && this.subStatus == 1) || this.status == 5) size = "40%";
      if (this.status == 6 || this.status == 7) size = '80%'
      if (this.subStatus == 2 || this.subStatus == 3) size = "88%";
      return size;
    },
    submitTxt() {
      let txt = "确认";
      return txt;
    },
    reasonList() { // 优惠1、退单2理由  4取消原因
      let typeId;
      if (this.status == 1 || this.status == 8) {
        typeId = 2
      } else if (this.status == 10) {
        typeId = 4
      } else {
        typeId = 1
      }
      let reasons = this.$store.state.cardPageInfo.resResultDataObj.reasonList.filter(item => item.status == 1 && item.type_id == typeId)
      if(typeId === 1) {
        reasons.push({
          id:"1",
          name:"自定义",
          status:"1",
          type_id:"1",
        })
      }
      return reasons
    },

    isIndeterminate() {
      return !this.checkAll && this.sealProductList.some(item => item.checked)
    },
  },
  components: {
    selectCheckbox,
    inputSelect,
    groupProduct,
    authorization,
    drawerYH2Submit
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        // 监听刷卡
        eventVue.$off('empMyOrderHandle')
        eventVue.$on('empMyOrderHandle', empCardInfo => { this.swipingOrderHandle(empCardInfo) })

        this.subStatus = 1;
        this.formData.reason = '';

        if (this.status < 6 || this.status == 9) {
          // 优惠 自用  加要求  更改明细 修改优惠人
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
          case 1: // 退单
            if (this.$store.state.userInfo.authStatus == 4) {
              // 收银系统收银人
              // 特饮、花篮退单可选择数量，需要手动填写退款金额
              this.backOrder.backOrderAmt = this.currentProductInfo.pa;
              this.productCount = this.currentProductInfo.pc * 1;
            } else {
              if (
                this.currentProductInfo.productInfo.prdType == 8 ||
                this.currentProductInfo.productInfo.prdType == 3 ||
                this.currentProductInfo.productInfo.prdType == 5
              ) {
                // 点单系统：特饮、花篮退款全部退，不允许选择数量
                this.productCount = this.currentProductInfo.pc * 1;
              } else {
                this.productCount = 1;
              }
            }
            this.formData.reason = "";
            break;
          case 2: // 赠送
          // this.initRadio();
          case 3: // 自用
            this.productCount = 1;
            this.formData.reason = "";
            break;
          case 5: // 退单套餐查看商品明细
            break;
          case 4: // 修改明细
            if (this.subStatus == 1) {
              const objInfo = JSON.parse(
                JSON.stringify(this.currentProductInfo)
              );
              this.updateDetail.productItemInfo = JSON.parse(
                JSON.stringify(objInfo)
              );
              /*
               此处用于区分收银系统和点单系统（通过字段名区分）
               明细商品项的商品数：点单系统用的c,收银系统用的dpc
               -------------start-------------------
              */
              if (objInfo.si && objInfo.si[0] && objInfo.si[0]["dpc"]) {
                // 收银系统 (添加与点单系统匹配的字段)
                objInfo.si.forEach(el => {
                  el.grp_ids = el.gid;
                  el.dtl_prd_ids = el.dpi;
                  el.dtl_prd_cnts = el.dpc;
                  el.sel_cnts = el.sc;
                });
              } else if (objInfo.si && objInfo.si[0] && objInfo.si[0]["c"]) {
                // 点单系统
                objInfo.si.forEach(el => {
                  el.grp_ids = el.gid;
                  el.dtl_prd_ids = el.i;
                  el.dtl_prd_cnts = el.c;
                  el.sel_cnts = el.s;
                });
              }
              /*
               此处用于区分收银系统和点单系统（通过字段名区分）
               明细商品项的商品数：点单系统用的c,收银系统用的dpc
               -------------end-------------------
              */
              const groupList = [];
              const grpIdListArr = objInfo.si.filter(el => el["grp_ids"] != 1);
              Array.from(new Set(grpIdListArr.map(el => el.grp_ids))).forEach(
                el => {
                  groupList.push({
                    count: objInfo.pc,
                    grpId: el,
                    list: grpIdListArr.filter(ele => ele.grp_ids == el)
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

            const offLineOrder = this.orderList.filter(item => !item.oid).filter(item => item.at != 2 && item.at != 3 && !item.back && (item.productInfo.prdType == 1 || item.productInfo.prdType == 2 || item.productInfo.prdType == 7 || item.productInfo.prdType == 6))

            this.sealProductList = offLineOrder.map(item => ({
              ...item,
              changeCount: item.pc,
              checked: true
            }))

            break
          case 8:  // 批量退单
            this.backOrderIndex = 0
            const onlineOrder = this.orderList.filter(item => item.oid)
            onlineOrder.forEach(el => {
              el.checked = true
              el.canBackOrderList = el.resultNotPayData.filter(item => !item.back).map(item => ({
                ...item,
                changeCount: item.pc,
                allAmt: item.pa
              }))
            })

            const resultOnlineOrder = onlineOrder.filter(item => item.canBackOrderList.length > 0).map(item => ({
              ...item,
              changeCount: item.pc,
            }))

            const offLineOrders = this.orderList.filter(item => !item.oid).filter(item => item.at != 2 && item.at != 3 && !item.back).map(item => ({
              ...item,
              changeCount: item.pc,
              checked: true,
              allAmt: item.pa
            }))
            this.sealProductList = [...offLineOrders, ...resultOnlineOrder]
            this.checkAll = this.sealProductList.every(item => item.checked)
            break
          case 10: // 取消优惠
            this.formData.reason = "";
            break;
          case 11: // 修改下单人
            this.formData.originName = this.currentItemInfo.personInfo.name;
            break;
          case 99:
            this.formData.originAe = this.currentItemInfo.authInfo.name;

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
@import "../../../style/order/orderMeal/myOrder/drawerMyOrder.less";
</style>