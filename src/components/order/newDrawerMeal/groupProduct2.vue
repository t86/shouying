<template>
  <div class="group">
    <div class="group-title" layout="row" layout-align="space-between start">
      <div class="group-title-name">{{ groupInfo.name }}</div>
      <div class="group-title-price">
        <span>单价:</span>
        <span class="value">￥{{ groupInfo.price }}</span>
      </div>
      <div class="group-title-count">
        <span>点单数量:</span>
        <span class="value" style="color: #08080A;">{{ groupInfo.count }}</span>
      </div>
      <div class="group-title-amt">
        <span>小计:</span>
        <span class="value">￥{{ groupInfo.allAmt }}</span>
      </div>
    </div>
    <!-- 待替换商品 -->
    <div v-if="isUpdate" class="p-t-2 p-b-5" style="color: #08080A; font-size: 18px;">
      <span>待替换商品：</span>
      <span
          v-for="(item,i) in selectedInfoObj[0].beforeUpdateProduct"
          :key="i"
      >{{ item.productInfo.name }} * {{ item.selectedCount * item.prdCnt * groupInfo.count }}{{ item.requireText ? '（' + item.requireText + '）' : '' }}</span>
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
              <span>{{ item.productInfo.name }} * {{ item.prdCnt * groupInfo.count }}</span>
              <span
                  v-if="item.productInfo.requireInfo.length>0"
                  class="m-l-1 cursor require-btn"
                  @click="requireBtnClickHandle('canNot',item)"
              >{{ item.requireText ? '改定制' : '定制' }}</span>
            </li>
          </ul>
        </div>
        <div class="group-content-checked-right">
          <ul layout="row" layout-align="start center">
            <li v-for="(item,i) in groupCanNotSelectArr" :key="i">
              <span>{{ item.productInfo.name }} * {{ item.prdCnt * groupInfo.count }}</span>
              <span v-if="item.requireText">({{ item.requireText }})</span>
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
          <p class="title">从以下明细中选{{ item.groupSelectCount }}次</p>
          <ul layout="row" layout-align="start center">
            <li
                v-for="(items,i) in item.productInfoList"
                :key="i"
                layout="row"
                layout-align="space-between center"
                :style="{'opacity': items.outSomethingCount == 0 || items.prdCnt * groupInfo.count > items.outSomethingCount ? '.3' : '1'}"
            >
              <span>{{ items.productInfo.name }} * {{ items.prdCnt * groupInfo.count }}</span>
              <!--              v-if="items.productInfo.requireInfo.length>0"-->
              <span
                  class="m-l-2 cursor require-btn"
                  @click="requireBtnClickHandle('can',items, item)"
              >定制</span>
              <img :src="imgSrc.add" @click="changeChecked('add',item,items)"/>
            </li>
          </ul>
        </div>
        <div class="group-content-choose-right">
          <p class="title">当前已选{{ item.hadSelectedCount }}次</p>
          <ul layout="row" layout-align="start center">
            <li
                v-for="(items,i) in item.selectedProductsArr"
                :key="i"
                layout="row"
                layout-align="space-between center"
            >
              <span>{{ items.productInfo.name }} * {{ items.selectedCount * items.prdCnt * groupInfo.count }}</span>
              <span v-if="items.requireText">({{ items.requireText }})</span>
              <img :src="imgSrc.del" @click="changeChecked('sub',item,items,i)"/>
              <p class="selected-count">{{ items.selectedCount }}</p>
            </li>
          </ul>
        </div>
      </div>
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

import add from "@/assets/order-img/new_order_add.png";
import sub from "@/assets/order-img/new-meal-sub.png";
import del from "@/assets/order-img/new-delete.png";

import drawerChooseRequireInfo from "@/components/order/newDrawerMeal/drawerChooseRequireInfo";
// 补交
import drawerBj from "@/components/order/newDrawerMeal/drawerBj/index.vue";

export default {
  data() {
    return {
      isSubmitting: false,
      groupInfo: {}, // 当前选择的套餐信息
      groupDetailArr: [], // 当前套餐中的商品明细
      groupCanSelectArr: [], // 可选的商品明细列表
      groupCanNotSelectArr: [], // 不可选的商品明细
      imgSrc: {
        add,
        sub,
        del
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
      const groupInfo = JSON.parse(JSON.stringify(this.productInfo));
      console.log('groupInfo', groupInfo)
      groupInfo.count = this.singleInfo.prd_cnt;
      groupInfo.allAmt = (groupInfo.price * this.singleInfo.prd_cnt).toFixed(2);
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
      
      console.log('=== 套餐明细初始化调试 ===');
      console.log('所有套餐明细 groupDetailArr:', this.groupDetailArr);
      console.log('固定商品 groupCanNotSelectArr:', this.groupCanNotSelectArr);
      console.log('可选商品 groupCanSelectArr (初始):', this.groupCanSelectArr);

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
          const find = outSomethingPrdList.find(item => item.id == ele.dtlPrdId)
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

          items = selectedInfo || {...items};
          const selectedCount = selectedInfo
              ? (items.selectedCount || 0) + this.requireDrawerInfo.selectedCount
              : this.requireDrawerInfo.selectedCount;

          // 用完定制要求的商品数量以后，重置数量为1
          this.requireDrawerInfo.selectedCount = 1
          // 判断可点商品数量单品是否超出估清值
          if (items.outSomethingCount != 'many' && items.prdCnt * selectedCount * this.groupInfo.count > items.outSomethingCount)
            return this.$message.warning(`目前此商品数量仅剩${items.outSomethingCount}，小于所需数量${items.prdCnt * selectedCount * this.groupInfo.count}，不可选择`)

          items.selectedCount = JSON.parse(JSON.stringify(selectedCount))

          items.requireText = requireText;
          if (!selectedInfo) item.selectedProductsArr.push(items);
          break;
        case "sub":
          // items.selectedCount = Math.max(items.selectedCount - 1, 0);
          // if (items.selectedCount == 0)
          //   item.selectedProductsArr.splice(index, 1);

          items.selectedCount = 0
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

      if (!this.isSubmitting) {
        this.isSubmitting = true;
        this.$emit('submitting', true);
      } else {
        return this.$message.warning('请勿重复提交')
      }

      // 校验可选明细数量是否选够
      const validateCanSelectPrdCount = this.groupCanSelectArr.every(item => item.groupSelectCount == item.hadSelectedCount)
      if (!validateCanSelectPrdCount) {
        this.isSubmitting = false;
        this.$emit('submitting', false);
        return this.$message.warning('可选套餐组商品数量与已选数量不匹配')
      }

      const {canNotSelectInfo, canSelectInfo} = this.getSubmitData();
      // let params = {
      //   seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64  卡台Id
      //   prd_id: this.groupInfo.id * 1, //     int64  商品Id
      //   prd_cnt: this.groupInfo.count * 1, //    int    商品数量 赔偿类商品只能=1
      //   prd_price: Math.round(this.groupInfo.price * 100), //  string 商品单价,用于做二次验证
      //   grp_ids: [...canNotSelectInfo.grpId, ...canSelectInfo.grpId], //    []int  套餐组Ids
      //   dtl_prd_ids: [...canNotSelectInfo.dtlPrdId, ...canSelectInfo.dtlPrdId], // []int  套餐组Id对应的选中明细商品
      //   dtl_prd_cnts: [...canNotSelectInfo.prdCnt, ...canSelectInfo.prdCnt], // []int  选中明细商品项的商品数, 用于二次验证
      //   sel_cnts: [...canNotSelectInfo.grpSelCnt, ...canSelectInfo.grpSelCnt], //   []int   套餐组对应的商品项的选中次数
      //   requirements: [
      //     ...canNotSelectInfo.requireText,
      //     ...canSelectInfo.requireText
      //   ] // []string  要求
      // };
      let params = {
        order_id: this.csmInfo.order_id,      //OrderId 核销上下文订单Id
        kq_order_id: this.csmInfo.kq_order_id,     //DyOrderId 卡券订单Id
        verify_token: this.csmInfo.verify_token,     //VerifyToken 核销卡券验证时使用
        wkday_id: this.csmInfo.wkday_id,      //WkdayId 营业日Id
        csm_id: this.csmInfo.csm_id,      //CsmId 流水Id
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1,        //SeatId 卡台Id
        pt_sku_id: this.csmInfo.pt_sku_id,
        title: this.csmInfo.title,     //Title 卡券名称
        prd_id: this.csmInfo.prd_id,      //PrdId 兑换套餐Id,云端返回
        prd_price:Math.round(this.groupInfo.price * 100),      //PrdPrice 套餐金额,单位分,需前端格式化
        coupon_pay_amt: this.csmInfo.coupon_pay_amt,      //CouponPayAmt 卡券支付金额,单位分,需前端格式化
        receipt_code: this.csmInfo.receipt_code,     //ReceiptCode 券码(美团对应实际券码,抖音对应订单id,推广对应custKqId)
        prd_type: this.csmInfo.prd_type,        //PrdType 套餐类型
        use_cnt_per_csm: this.csmInfo.use_cnt_per_csm,        //UseCntPerCsm 当台可使用张数
        use_exclusive_mode: this.csmInfo.use_exclusive_mode,        //UseExclusiveMode 使用模式 1 独享 2 共享
        grp_ids: [...canNotSelectInfo.grpId, ...canSelectInfo.grpId], //    []int  套餐组Ids
        dtl_prd_ids: [...canNotSelectInfo.dtlPrdId, ...canSelectInfo.dtlPrdId], // []int  套餐组Id对应的选中明细商品
        dtl_prd_cnts: [...canNotSelectInfo.prdCnt, ...canSelectInfo.prdCnt], // []int  选中明细商品项的商品数, 用于二次验证
        sel_cnts: [...canNotSelectInfo.grpSelCnt, ...canSelectInfo.grpSelCnt], //   []int   套餐组对应的商品项的选中次数
        requirements: [
          ...canNotSelectInfo.requireText,
          ...canSelectInfo.requireText
        ] // []string  要求
      }
      console.log('=== 兑换券核销调试信息 ===');
      console.log('groupCanNotSelectArr (固定商品):', this.groupCanNotSelectArr);
      console.log('groupCanSelectArr (可选商品):', this.groupCanSelectArr);
      console.log('canNotSelectInfo:', canNotSelectInfo);
      console.log('canSelectInfo:', canSelectInfo);
      console.log('数组长度检查:');
      console.log('固定商品数量:', this.groupCanNotSelectArr.length);
      console.log('grp_ids length:', params.grp_ids.length, '内容:', params.grp_ids);
      console.log('dtl_prd_ids length:', params.dtl_prd_ids.length, '内容:', params.dtl_prd_ids);
      console.log('dtl_prd_cnts length:', params.dtl_prd_cnts.length, '内容:', params.dtl_prd_cnts);
      console.log('sel_cnts length:', params.sel_cnts.length, '内容:', params.sel_cnts);
      console.log('requirements length:', params.requirements.length, '内容:', params.requirements);
      console.log('完整参数:', params);

      const res = await api_order.csm_coupon_v2(params)
      if(res.code === 1) {
        this.$message.success("卡券核销成功");
        this.onCancelDrawer();
      } else {
        this.$message.error(res.msg);
      }
      // 无论成功失败都需要重置提交状态
      this.isSubmitting = false;
      this.$emit('submitting', false);

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
            canSelectInfo.dtlPrdId.push(parseInt(ele.dtlPrdId));
            canSelectInfo.prdCnt.push(ele.prdCnt * 1);
            canSelectInfo.grpSelCnt.push(ele.selectedCount * 1);
            canSelectInfo.requireText.push(ele.requireText);
          }
        });
      });

      this.groupCanNotSelectArr.forEach(el => {
        canNotSelectInfo.grpId.push(el.grpId * 1);
        canNotSelectInfo.dtlPrdId.push(parseInt(el.dtlPrdId));
        canNotSelectInfo.prdCnt.push(el.prdCnt * 1);
        canNotSelectInfo.grpSelCnt.push(1); // 安全处理，避免除零
        canNotSelectInfo.requireText.push(el.requireText || '');
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
  props: ["productInfo", "singleInfo", "selectedInfoObj", "isUpdate", "dyInfo", "mtInfo", 'csmInfo'],
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
@import "../../../style/order/orderMeal/newDrawerMeal/groupProduct.less";
@import "../../../style/common/newElementFormBtn.less";
</style>