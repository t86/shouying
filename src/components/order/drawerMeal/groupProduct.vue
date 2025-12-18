<template>
  <div class="group">
    <div class="group-title" layout="row" layout-align="space-between start">
      <div class="group-title-name">{{groupInfo.name}}</div>
      <div class="group-title-price">
        <span>{{ bindphone !== '' ? '会员单价:' : '单价:' }}</span>
        <span class="value">￥{{ calculatedPrice }}</span>
      </div>
      <div class="group-title-count">
        <span>点单数量:</span>
        <span class="value">{{groupInfo.count}}</span>
      </div>
      <div class="group-title-amt">
        <span>小计:</span>
        <span class="value">￥{{groupInfo.allAmt}}</span>
      </div>
    </div>
    <!-- 待替换商品 -->
    <div v-if="isUpdate" class="p-t-2 p-b-5">
      <span>待替换商品：</span>
      <span
        v-for="(item,i) in selectedInfoObj[0].beforeUpdateProduct"
        :key="i"
      >{{item.productInfo.name}} * {{item.selectedCount * item.prdCnt * groupInfo.count}}{{item.requireText?'（'+item.requireText+'）':''}}</span>
    </div>
    <!-- 选择列表 -->
    <div class="group-content">
      <div class="group-content-title" layout="row" layout-align="space-between center">
        <div class="group-content-title-left">套餐明细</div>
        <div class="group-content-title-right">已选列表</div>
      </div>
      <!-- 不可选列表 -->
      <div
        v-if="groupCanNotSelectArr && groupCanNotSelectArr.length>0"
        class="group-content-checked"
        layout="row"
        layout-align="space-between center"
      >
        <div class="group-content-checked-left">
          <ul layout="row" layout-align="start center">
            <li class="left" v-for="(item,i) in groupCanNotSelectArr" :key="i">
              <span>{{item.productInfo.name}} * {{item.prdCnt * groupInfo.count}}</span>
              <span
                v-if="item.productInfo.requireInfo.length>0"
                class="m-l-1 cursor require-btn"
                @click="requireBtnClickHandle('canNot',item)"
              >{{item.requireText?'改定制':'定制'}}</span>
            </li>
          </ul>
        </div>
        <div class="group-content-checked-right">
          <ul layout="row" layout-align="start center">
            <li v-for="(item,i) in groupCanNotSelectArr" :key="i">
              <span>{{item.productInfo.name}} * {{item.prdCnt * groupInfo.count}}</span>
              <span v-if="item.requireText">({{item.requireText}})</span>
            </li>
          </ul>
        </div>
      </div>
      <!-- 本次选择列表 -->
      <div
        v-for="(item,index) in groupCanSelectArr"
        :key="index"
        class="group-content-choose"
        layout="row"
        layout-align="space-between start"
      >
        <div class="group-content-choose-left">
          <p>从以下明细中选{{item.groupSelectCount}}次</p>
          <ul layout="row" layout-align="start center">
            <li
              v-for="(items,i) in item.productInfoList"
              :key="i"
              layout="row"
              layout-align="space-between center"
              :style="{'opacity': items.outSomethingCount == 0 || items.prdCnt * groupInfo.count > items.outSomethingCount ? '.3' : '1'}"
            >
              <span>{{items.productInfo.name}} * {{items.prdCnt * groupInfo.count}}</span>
              <span
                v-if="items.productInfo.requireInfo.length>0"
                class="m-l-2 cursor require-btn"
                @click="requireBtnClickHandle('can',items, item)"
              >定制</span>
              <img :src="imgSrc.add" @click="changeChecked('add',item,items)" />
            </li>
          </ul>
        </div>
        <div class="group-content-choose-right">
          <p>当前已选{{item.hadSelectedCount}}次</p>
          <ul layout="row" layout-align="start center">
            <li
              v-for="(items,i) in item.selectedProductsArr"
              :key="i"
              layout="row"
              layout-align="space-between center"
            >
              <span>{{items.productInfo.name}} * {{items.selectedCount * items.prdCnt * groupInfo.count}}</span>
              <span v-if="items.requireText">({{items.requireText}})</span>
              <img :src="imgSrc.sub" @click="changeChecked('sub',item,items,i)" />
              <p class="selected-count">{{items.selectedCount}}</p>
            </li>
          </ul>
        </div>
      </div>
    </div>

    <!-- 提交按钮 -->
    <div class="form-btn" layout="row" layout-align="center center">
      <el-button type="info" @click.stop="onCancelDrawer">取消</el-button>
      <el-button type="primary" @click.stop="onSubmit">确认</el-button>
    </div>

    <drawerChooseRequireInfo
      :showDrawer="requireDrawerInfo.showDrawer"
      :productInfo="requireDrawerInfo.productInfo"
      :requestInfoArr="requireDrawerInfo.requestInfoArr"
      :maxCount="requireDrawerInfo.maxSelectCount"
      :showSelectedCount="requireDrawerInfo.showSelectedCount"
      @updateRequireInfoArr="updateRequireInfoArr"
      @showOrHideDrawer="showOrHideRequireDrawer"
      @updateRequireCount="updateRequireCount"
    />

        <!-- 补交 -->
    <drawerBj 
      v-model="showBJDrawer" 
      :productInfo="productInfo"
      :groupParams="groupParams"
      @onCancelDrawer="onCancelDrawer" 
    />
  </div>
</template>
 
<script>
import api_order from "@/api/order";
import common_order from "@/utils/common/order";
import { getProductPrice } from '@/utils/priceCalculator';

import add from "@/assets/order-img/order_add.png";
import sub from "@/assets/order-img/sub.png";

import drawerChooseRequireInfo from "@/components/order/drawerMeal/drawerChooseRequireInfo";
// 补交
import drawerBj from "@/components/order/drawerMeal/drawerBj/index.vue";

export default {
  data() {
    return {
      calculatedPrice: 0, // 使用 getProductPrice 计算出的实际价格
      bindphone: '', // 会员手机号
      groupInfo: {}, // 当前选择的套餐信息
      groupDetailArr: [], // 当前套餐中的商品明细
      groupCanSelectArr: [], // 可选的商品明细列表
      groupCanNotSelectArr: [], // 不可选的商品明细
      imgSrc: {
        add,
        sub
      },

      requireDrawerInfo: {
        showDrawer: false,
        productInfo: {},
        requestInfoArr: [],
        currentType: "", // 当前定制或修改的是属于可选还是不可选  值：canNot / can
        groupItem: {}, // 当前定制可选项的套餐组
        currentItem: {}, // 当前定制要求或修改要求的单品
        maxSelectCount: 1, // 当前可选商品选择的做大数量
        selectedCount: 1, // 当前可选商品已选择的数量
        showSelectedCount: false, // 是否显示定制要求的选择次数
      },

      showBJDrawer: false,
      groupParams: {}
    };
  },
  methods: {
    init() {
      console.log('🚀🚀🚀 [旧套餐组件] init() 方法开始执行');
      const groupInfo = JSON.parse(JSON.stringify(this.productInfo));
      groupInfo.count = this.singleInfo.prd_cnt;
      console.log('🚀🚀🚀 [旧套餐组件] groupInfo:', groupInfo);
      
      // 使用统一的价格计算函数
      const businessData = this.$store.state.cardPageInfo.resResultDataObj.businessData || [];
      const cardInfo = this.$store.state.orderInfo.currentCardInfo;
      const currentBusiness = businessData.find(ite => ite.seatId * 1 == cardInfo.seatId * 1);
      const businessEmpList = this.$store.state.cardPageInfo.resResultDataObj.businessEmpList || [];
      this.bindphone = currentBusiness && currentBusiness.csm_cust_phone || '';
      
      // 获取原价
      const originalPrice = this.productInfo.vipPrice || this.productInfo.price || "0";
      console.log('🚀🚀🚀 [旧套餐组件] 原价:', originalPrice);

      // ========== 严格判断是否为会员 ==========
      // 必须：csm_cust_phone 是字符串且去除空格后不为空
      const csmCustPhone = currentBusiness ? (currentBusiness.csm_cust_phone || '') : '';
      const isMember = !!(csmCustPhone && typeof csmCustPhone === 'string' && csmCustPhone.trim() !== '');

      console.log('=== [旧套餐组件] 套餐价格计算详情 ===');
      console.log('productInfo:', this.productInfo);
      console.log('价格字段:', {
        price: this.productInfo.price,
        mbPrice: this.productInfo.mbPrice,
        mb_price: this.productInfo.mb_price,
        vipPrice: this.productInfo.vipPrice
      });
      console.log('业务数据:', {
        businessData_length: businessData.length,
        currentBusiness: currentBusiness,
        csm_cust_phone: csmCustPhone,
        csm_cust_phone_type: typeof csmCustPhone,
        csm_cust_phone_trimmed: csmCustPhone ? csmCustPhone.trim() : '',
        cardInfo_seatId: cardInfo ? cardInfo.seatId : ''
      });
      console.log('🔍🔍🔍 [旧套餐组件] isMember 判断结果:', isMember, 'csmCustPhone:', JSON.stringify(csmCustPhone));
      console.log('🔍🔍🔍 [旧套餐组件] 继续执行到 getProductPrice 之前');
      
      // 使用 getProductPrice 计算显示价格（会根据会员状态、商务状态等自动选择正确的价格）
      // 注意：这个价格可能包含会员价，但我们要根据 isMember 来决定是否使用
      let displayPrice = getProductPrice(this.productInfo, cardInfo, currentBusiness, businessEmpList);
      this.calculatedPrice = parseFloat(displayPrice) || parseFloat(originalPrice) || 0;
      console.log('🔍🔍🔍 [旧套餐组件] getProductPrice 执行完成，displayPrice:', displayPrice, 'calculatedPrice:', this.calculatedPrice);

      const mbPrice = parseFloat(this.productInfo.mbPrice || this.productInfo.mb_price || "0") || 0;
      console.log('💰💰💰 [旧套餐组件] priceInfo 结果:', {
        displayPrice,
        calculatedPrice: this.calculatedPrice,
        originalPrice,
        isMember,
        mbPrice: mbPrice
      });
      console.log('🔍🔍🔍 [旧套餐组件] 开始计算小计，isMember:', isMember);
      
      // 小计计算逻辑：
      // - 如果是会员，使用会员价（通过 getProductPrice 计算，已包含会员价）
      // - 如果是散客，强制使用原价，不管 getProductPrice 返回什么
      // 关键：判断是否要使用会员价来计算小计
      let unitPriceForCalc;
      if (isMember) {
        // 是会员：使用 getProductPrice 计算出的价格（可能包含会员价、商务会员价等）
        unitPriceForCalc = this.calculatedPrice;
        console.log('✅✅✅ [旧套餐组件] 是会员，使用会员价计算小计:', unitPriceForCalc);
      } else {
        // 是散客：强制使用原价，不使用任何会员价
        // 即使 getProductPrice 返回了会员价，散客也必须用原价
        unitPriceForCalc = parseFloat(originalPrice) || 0;
        console.log('❌❌❌ [旧套餐组件] 不是会员，强制使用原价计算小计:', unitPriceForCalc, '原价:', originalPrice, 'calculatedPrice:', this.calculatedPrice);

        // 额外检查：如果 calculatedPrice 等于会员价，但 isMember 是 false，说明判断有误，强制使用原价
        if (mbPrice > 0 && Math.abs(this.calculatedPrice - mbPrice) < 0.01) {
          console.warn('⚠️⚠️⚠️ [旧套餐组件] 警告：检测到 calculatedPrice 是会员价，但 isMember 是 false，强制使用原价');
          unitPriceForCalc = parseFloat(originalPrice) || 0;
        }
      }

      // 小计 = 单价 * 数量
      groupInfo.allAmt = (unitPriceForCalc * this.singleInfo.prd_cnt).toFixed(2);
      console.log('💰💰💰 [旧套餐组件] 最终小计:', {
        allAmt: groupInfo.allAmt,
        unitPrice: unitPriceForCalc,
        prd_cnt: this.singleInfo.prd_cnt,
        isMember: isMember,
        calculatedPrice: this.calculatedPrice,
        originalPrice: originalPrice
      });
      this.groupInfo = groupInfo;
      // 更新已选的明细信息
      if (this.isUpdate) {
        this.groupCanSelectArr = [
          ...JSON.parse(JSON.stringify(this.selectedInfoObj))
        ];
      } else {
        this.getGroupDetail(groupInfo.id);
      }
      this.getSelectedCount();
      this.$forceUpdate();
    },

    // 获取当前套餐明细
    getGroupDetail(productId) {
      this.groupDetailArr = this.$store.state.cardPageInfo.resResultDataObj.goodsDetailInfo.filter(
        el => el.status == 1 && el.prdId == productId
      );

      // 排序
      this.groupCanSelectArr = this.groupDetailArr
        .filter(el => el.grpId != 1)
        .sort((a, b) => a.seqId - b.seqId);
      this.groupCanNotSelectArr = this.groupDetailArr
        .filter(el => el.grpId == 1)
        .sort((a, b) => a.seqId - b.seqId);

      this.groupCanSelectArr = JSON.parse(JSON.stringify(this.groupCanSelectArr))
      this.groupCanSelectArr.forEach(el => {
        el.productInfo = common_order.getProductInfoFromGroup(el.dtlPrdId);
        el.requireText = "";
        el.productInfo.requireInfo = common_order.getRequireInfo(
          el.productInfo.twoCateId
        );
      });

      // 通过grpId进行分类
      const groupIdList = new Set(this.groupCanSelectArr.map(el => el.grpId));
      const resultGroupCanSelectArr = [];
      const outSomethingPrdList = this.$store.state.cardPageInfo.resResultDataObj["prdOutOfSomething"].filter(item => item.status == 1)

      groupIdList.forEach(el => {
        const findInfo = this.groupCanSelectArr.filter(ele => ele.grpId == el);
        findInfo.forEach(ele => {
          // 添加可选商品的估清数量属性
          const find = outSomethingPrdList.find( item => item.id == ele.dtlPrdId)
          ele.outSomethingCount = find ? find.cnt : 'many'
        })
        resultGroupCanSelectArr.push({
          grpId: el,
          productInfoList: findInfo,
          groupSelectCount: findInfo.length > 0 ? findInfo[0].grpSelCnt : 0, // 当前套餐可选的商品数量
          selectedProductsArr: [], // 已选商品列表
          hadSelectedCount: 0 // 已选商品数量
        });
      });

      this.groupCanSelectArr = JSON.parse(
        JSON.stringify(resultGroupCanSelectArr)
      );

      this.groupCanNotSelectArr.forEach(el => {
        const productInfo = common_order.getProductInfoFromGroup(el.dtlPrdId);
        productInfo.requireInfo = common_order.getRequireInfo(
          productInfo.twoCateId
        );
        el.productInfo = productInfo;
        el.requireText = "";
      });
    },

    // 改变所选套餐
    changeChecked(type, item, items, index, requireText = "") {
      switch (type) {
        case "add":
          if (item.hadSelectedCount >= item.groupSelectCount)
            return this.$message.warning("当前可选数量已达到最大值");

          const selectedInfo = item.selectedProductsArr.find(
            el =>
              el.dtlPrdId === items.dtlPrdId && el.requireText === requireText
          );
          
          items = selectedInfo || { ...items };
          const selectedCount = selectedInfo
            ? (items.selectedCount || 0) + this.requireDrawerInfo.selectedCount
            : this.requireDrawerInfo.selectedCount;

          // 用完定制要求的商品数量以后，重置数量为1
          this.requireDrawerInfo.selectedCount = 1
          // 判断可点商品数量单品是否超出估清值
          if(items.outSomethingCount != 'many' && items.prdCnt * selectedCount * this.groupInfo.count > items.outSomethingCount) 
            return this.$message.warning(`目前此商品数量仅剩${items.outSomethingCount}，小于所需数量${items.prdCnt * selectedCount * this.groupInfo.count}，不可选择`)
            
          items.selectedCount = JSON.parse(JSON.stringify(selectedCount))
          
          items.requireText = requireText;
          if (!selectedInfo) item.selectedProductsArr.push(items);
          break;
        case "sub":
          items.selectedCount = Math.max(items.selectedCount - 1, 0);
          if (items.selectedCount == 0)
            item.selectedProductsArr.splice(index, 1);
          break;
      }

      if (this.isUpdate) {
        this.$emit("updateSelectedArr", item);
      }
      this.getSelectedCount(item);
      this.$forceUpdate();
    },

    getSelectedCount(item) {
      if (!item) return;
      let count = 0;
      item.selectedProductsArr.forEach(el => {
        count += el.selectedCount;
      });
      item.hadSelectedCount = count;
    },

    onCancelDrawer() {
      this.$emit("closeDrawerHandle");
    },

    async onSubmit() {
      // 校验可选明细数量是否选够
      const validateCanSelectPrdCount = this.groupCanSelectArr.every(item => item.groupSelectCount == item.hadSelectedCount)
      if(!validateCanSelectPrdCount) return this.$message.warning('可选套餐组商品数量与已选数量不匹配')

      const { canNotSelectInfo, canSelectInfo } = this.getSubmitData();

      // ========== 提交时的价格计算 ==========
      // 严格判断是否为会员
      const businessData = this.$store.state.cardPageInfo.resResultDataObj.businessData || [];
      const cardInfo = this.$store.state.orderInfo.currentCardInfo;
      const currentBusiness = businessData.find(ite => ite.seatId * 1 == cardInfo.seatId * 1);
      const businessEmpList = this.$store.state.cardPageInfo.resResultDataObj.businessEmpList || [];

      // 严格判断是否为会员：csm_cust_phone 必须是字符串且去除空格后不为空
      const csmCustPhone = currentBusiness ? (currentBusiness.csm_cust_phone || '') : '';
      const isMember = !!(csmCustPhone && typeof csmCustPhone === 'string' && csmCustPhone.trim() !== '');

      let prdPrice;
      if (isMember) {
        // 是会员：使用 getProductPrice 计算出的价格
        prdPrice = this.calculatedPrice || this.groupInfo.price || 0;
        console.log('📤📤📤 [套餐提交] 是会员，使用会员价:', prdPrice);
      } else {
        // 是散客：强制使用原价
        const originalPrice = this.productInfo.vipPrice || this.productInfo.price || "0";
        prdPrice = parseFloat(originalPrice) || this.groupInfo.price || 0;
        console.log('📤📤📤 [套餐提交] 不是会员，强制使用原价:', prdPrice, '原价:', originalPrice);
      }

      console.log('📤📤📤 [套餐提交] 最终提交价格:', {
        prdPrice: prdPrice,
        isMember: isMember,
        calculatedPrice: this.calculatedPrice,
        groupInfo_price: this.groupInfo.price,
        csmCustPhone: JSON.stringify(csmCustPhone)
      });

      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64  卡台Id
        prd_id: this.groupInfo.id * 1, //     int64  商品Id
        prd_cnt: this.groupInfo.count * 1, //    int    商品数量 赔偿类商品只能=1
        prd_price: Math.round(prdPrice * 100), //  string 商品单价,用于做二次验证，单位：分
        grp_ids: [...canNotSelectInfo.grpId, ...canSelectInfo.grpId], //    []int  套餐组Ids
        dtl_prd_ids: [...canNotSelectInfo.dtlPrdId, ...canSelectInfo.dtlPrdId], // []int  套餐组Id对应的选中明细商品
        dtl_prd_cnts: [...canNotSelectInfo.prdCnt, ...canSelectInfo.prdCnt], // []int  选中明细商品项的商品数, 用于二次验证
        sel_cnts: [...canNotSelectInfo.grpSelCnt, ...canSelectInfo.grpSelCnt], //   []int   套餐组对应的商品项的选中次数
        requirements: [
          ...canNotSelectInfo.requireText,
          ...canSelectInfo.requireText
        ] // []string  要求
      };

      // 判断是否为关联功能台
      if(this.$store.state.orderInfo.currentCardInfo.bizType == 3) {
        this.groupParams = {...params}
        return this.showBJDrawer = true
      }

      try {
        const res = await api_order.reqAddGroupToShopping(params);
        if (res.code === 1) {
          this.$message.success("加入购物车成功");
          this.$store.dispatch("getShoppingCount", this);
          this.onCancelDrawer();
        } else this.$message.warning(res.msg);
      } catch (error) {
        console.log("套餐加入购物车失败", error);
      }
    },

    // -----------------套餐定制单品 start --------------------
    requireBtnClickHandle(type, item, groupItem) {
      this.requireDrawerInfo.showSelectedCount = type === 'can'
      if (type === "can") {
        if (groupItem.hadSelectedCount == groupItem.groupSelectCount) {
          return this.$message.warning("当前可选数量已达到最大值");
        }

        this.requireDrawerInfo.groupItem = groupItem;
        this.requireDrawerInfo.maxSelectCount =
          groupItem.groupSelectCount - groupItem.hadSelectedCount;
      }
      this.requireDrawerInfo.currentType = type;
      this.requireDrawerInfo.currentItem = item;
      this.requireDrawerInfo.requestInfoArr = JSON.parse(
        JSON.stringify(item.requireText.split(";"))
      );
      this.requireDrawerInfo.productInfo = JSON.parse(
        JSON.stringify(item.productInfo)
      );
      this.showOrHideRequireDrawer();
    },

    updateRequireInfoArr(requireList) {
      if (this.requireDrawerInfo.currentType == "canNot") {
        this.requireDrawerInfo.currentItem.requireText = requireList.join(";");
      } else {
        this.changeChecked(
          "add",
          this.requireDrawerInfo.groupItem,
          this.requireDrawerInfo.currentItem,
          0,
          requireList.join(";")
        );
      }
      this.$forceUpdate();
    },

    updateRequireCount(count) {
      this.requireDrawerInfo.selectedCount = count;
    },

    showOrHideRequireDrawer() {
      this.requireDrawerInfo.showDrawer = !this.requireDrawerInfo.showDrawer;
    },

    // -----------------套餐定制单品 end --------------------

    getSubmitData() {
      const canSelectInfo = {
        grpId: [],
        dtlPrdId: [],
        prdCnt: [],
        grpSelCnt: [],
        requireText: []
      };
      const canNotSelectInfo = {
        grpId: [],
        dtlPrdId: [],
        prdCnt: [],
        grpSelCnt: [],
        requireText: []
      };

      this.groupCanSelectArr.forEach(el => {
        el.selectedProductsArr.forEach(ele => {
          if (ele.selectedCount) {
            canSelectInfo.grpId.push(ele.grpId * 1);
            canSelectInfo.dtlPrdId.push(ele.dtlPrdId * 1);
            canSelectInfo.prdCnt.push(ele.prdCnt * 1);
            canSelectInfo.grpSelCnt.push(ele.selectedCount * 1);
            canSelectInfo.requireText.push(ele.requireText);
          }
        });
      });

      this.groupCanNotSelectArr.forEach(el => {
        canNotSelectInfo.grpId.push(el.grpId * 1);
        canNotSelectInfo.dtlPrdId.push(el.dtlPrdId * 1);
        canNotSelectInfo.prdCnt.push(el.prdCnt * 1);
        canNotSelectInfo.grpSelCnt.push(1);
        canNotSelectInfo.requireText.push(el.requireText);
      });

      return {
        canNotSelectInfo,
        canSelectInfo
      };
    }
  },
  mounted() {
    this.init();
  },
  components: {
    drawerChooseRequireInfo,
    drawerBj
  },
  props: ["productInfo", "singleInfo", "selectedInfoObj", "isUpdate"],
  watch: {
    selectedInfoObj: {
      deep: true,
      handler() {
        this.init();
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/order/orderMeal/drawerMeal/groupProduct.less";
@import "../../../style/common/elementFormBtn.less";
</style>