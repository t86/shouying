export default {
  methods: {
    getMenuInfo(isGQ) {
      console.log('getMenuInfo', isGQ);
      // 当前用户岗位id
      const authStationId = this.$store.state.userInfo.station_id;

      // 所有有效一级分类
      const firstCategoryAll = this.$store.state.cardPageInfo.resResultDataObj[
        "firstCategoryInfo"
      ].filter((el) => el.status == 1);

      // 所有有效二级分类
      const secondCategoryAll = this.$store.state.cardPageInfo.resResultDataObj[
        "secondCategoryInfo"
      ].filter((el) => el.status == 1);

      // 所有商品不限点的岗位id(可点商品没有限制的岗位id)
      const notLimitStationId = this.$store.state.cardPageInfo.resResultDataObj[
        "jobLimitInfo"
      ].filter((el) => el.status == 1);

      // 所有岗位可点的有效二级分类
      const secondCategory = this.$store.state.cardPageInfo.resResultDataObj[
        "jobSecondLimitInfo"
      ].filter((el) => el.status == 1);

      let SYSecondCategory = []; // 收银系统能点的二级分类
      let prdListId = []; // 营销商品可优惠商品id
      let FWYSecondCategory = []; // 服务员可点二级分类
      let YXSecondCategory = []; // 营销可点二级分类
      // let HLSecondCategory = []; // 花篮可点二级分类

      let YH2PrdListId = []; // 优惠2可优惠商品id

      if (this.$store.state.userInfo.authStatus == 4 || isGQ) {
        // 当前岗位可点商品没有限制
        // 此时此刻不需要进行岗位限制的筛选
        // 只需要获取所有的商品二级分类即可
        // 此处为了配合接下来的流程中区域筛选，将数据处理成与有限制的可点商品二级分类一致的
        secondCategoryAll.forEach((el, index) => {
          SYSecondCategory.push({
            twoCateId: el.id,
          });
        });
      }
      /**
       * 无论是否为收银系统，都要去查看当前登录账号对商品的可点权限，目的是为了在收银系统中，对商品进行优惠操作时，如果自己有权限则显示自己优惠按钮，否则不显示
       */
      if (true) {
        if ((this.$store.state.userInfo.roleIds.includes(2) 
        || this.$store.state.userInfo.roleIds.includes(4)) 
        && this.$store.state.orderInfo.currentCardInfo.isWaiter) {
          // 服务员 特饮 且是服务员可点卡台
          // 查看是否为不限可点
          if (
            notLimitStationId
              .map((item) => item.stationId * 1)
              .includes(authStationId * 1)
          ) {
            // 当前岗位可点商品没有限制
            // 此时此刻不需要进行岗位限制的筛选
            // 只需要获取所有的商品二级分类即可
            // 此处为了配合接下来的流程中区域筛选，将数据处理成与有限制的可点商品二级分类一致的
            FWYSecondCategory = secondCategoryAll.map((item) => ({
              twoCateId: item.id,
            }));
          } else {
            FWYSecondCategory = secondCategory.filter(
              (el) =>
                el.stationId == authStationId &&
                el.authType == 1 &&
                el.status == 1 // authType:1  服务员可点
            );
          }
        }

        if (this.$store.state.userInfo.roleIds.includes(3)
        && (this.$store.state.orderInfo.currentCardInfo.isYX)) {
          // 营销
          prdListId = getSealConfigPrdId(this);
        }

        // if (this.$store.state.userInfo.roleIds.includes(4)) {
        //   // 花篮  // 特饮/花篮权限绑定在商品上，需要在绑定的商品上做筛选
        // }

        if (this.$store.state.userInfo.roleIds.includes(1000)) {
          // 优惠2
          YH2PrdListId = getSealConfigPrdId(this, 3);
        }
      }
      function getSealConfigPrdId(that, type = 2) {
        const limitRoleFreeLimitIdList =
          that.$store.state.cardPageInfo.resResultDataObj["roleLimitConfig"]
            .filter(
              (item) =>
                item.status == 1 &&
                item.station_id == authStationId &&
                item.auth_type == type
            )
            .map((item) => item.free_limit_id * 1);

        // 商品id
        const prdListId = that.$store.state.cardPageInfo.resResultDataObj[
          "limitPrdDetail"
        ]
          .filter(
            (item) =>
              item.status == 1 &&
              limitRoleFreeLimitIdList.includes(item.free_limit_id * 1)
          )
          .map((item) => item.prd_id * 1);

        return prdListId;
      }

      // 当前卡台区域下可点商品(用于筛选区域下可点商品（每个身份都需要筛选）)
      let currentAreaAllProduct = [];
      if ((this.$route.name == "moneyCard" && this.$store.state.userInfo.authStatus == 4) 
      || (this.$route.name == 'orderCard' && this.$store.state.userInfo.authStatus == 2)
      || isGQ
      ) {
        // 估清
        currentAreaAllProduct = this.$store.state.cardPageInfo.resResultDataObj[
          "areaProduct"
        ].filter((el) => el.status == 1);
      } else {
        // 服务员  或  营销  或  花篮  或  优惠  或  优惠2
        currentAreaAllProduct = this.$store.state.cardPageInfo.resResultDataObj[
          "areaProduct"
        ].filter(
          (el) =>
            el.status == 1 &&
            el.region_id == this.$store.state.orderInfo.currentCardInfo.regionId
        );
      }

      // 所有二级分类下所有单品和套餐
      let stationAllProduct = this.$store.state.cardPageInfo.resResultDataObj[
        "goodsAroundInfo"
      ].filter((el) => el.status == 1);

      let FWYAllProductList = []; // 服务员可点商品
      let YXAllProductList = []; // 营销可优惠商品
      // let HLAllProductList = []; // 花篮可点商品
      let YH2AllProductList = []; // 优惠2可优惠商品

      /**
       *  服务员
       */
      if ((this.$store.state.userInfo.roleIds.includes(2) 
      || this.$store.state.userInfo.roleIds.includes(4)) 
      && this.$store.state.orderInfo.currentCardInfo.isWaiter) {
        // 当前区域下服务员可点商品
        const FWYAreaPrdList = [];
        currentAreaAllProduct.forEach((el) => {
          // 查询商品的同时，筛选掉服务员点单不可见商品
          const find = stationAllProduct.find(
            (item) => item.id == el.prd_id && item.useType != 2
          );
          if (find)
            FWYAreaPrdList.push({
              ...find,
              canOrderMeal: true,
            });
        });

        // 服务员可点二级分类下的商品
        const FWYSecondCategoryPrdList = [];
        FWYSecondCategory.forEach((el) => {
          // 服务员可点商品需要过滤掉'特饮'和'小费'商品(商品类型:1存货(关联erp) 7普通(不关联erp) 2套餐 3 时价特饮(关联erp) 4 小费 5 赔偿 6 联营,13 定价特饮 14 定价小费)
          const findList = stationAllProduct.filter(
            (item) =>
              el.twoCateId == item.twoCateId &&
              item.useType != 2 &&
              item.prdType != 3 &&
              item.prdType != 4 &&
              item.prdType != 13 &&
              item.prdType != 14
          );
          let newList = []
          findList.forEach((ele) => {
            newList.push({...ele,canOrderMeal:true })
          });
          FWYSecondCategoryPrdList.push(...newList);
        });

        FWYAreaPrdList.forEach((el) => {
          const find = FWYSecondCategoryPrdList.find(
            (item) => item.id == el.id
          );
          if (find) FWYAllProductList.push({...find});
        });
      }
      // 去掉元数据42中所有服务员的不可点商品
      let noOrderPrdList = this.$store.state.cardPageInfo.resResultDataObj["orderPrdList"]
      .filter(item => item.station_id == authStationId && item.status == 1).map(item => item.prd_id)
      FWYAllProductList = FWYAllProductList.filter(item => !noOrderPrdList.includes(item.id))

      /**
       * 营销
       */
      if (this.$store.state.userInfo.roleIds.includes(3) 
        && (this.$store.state.orderInfo.currentCardInfo.isYX)) {
        // 营销在当前区域下可点商品
        const YXAreaPrdList = [];
        currentAreaAllProduct.forEach((el) => {
          const find = stationAllProduct.find((item) => item.id == el.prd_id && item.prdType == 1);
          if (find)
            YXAreaPrdList.push({
              ...find,
              canSeal:true,
            });
        });

        const prdList = stationAllProduct.filter((item) =>
          prdListId.includes(item.id * 1)
        );

        // 营销可优惠商品
        const YXCanSealAllPrdList = prdList.map((item) => ({
          ...item,
          canSeal: true,
        }));

        // 当前区域下商品 与 可优惠总商品求 交集
        YXCanSealAllPrdList.forEach((el) => {
          const find = YXAreaPrdList.find((item) => item.id == el.id);
          if (find) YXAllProductList.push({...find});
        });

      }

      /**
       *  优惠2
       */
      if (this.$store.state.userInfo.roleIds.includes(1000)) {
        // 优惠2在当前区域下可点商品
        const YH2AreaPrdList = [];
        currentAreaAllProduct.forEach((el) => {
          // 查询优惠2商品的同时，筛选（优惠2不支持套餐、特饮、小费、赔偿） 即 prdType : 1存货(单品，关联erp) 2套餐 3 存货花篮/特饮(关联erp) 4 小费 5 赔偿 6 联营 7普通(不关联erp)
          const find = stationAllProduct.find(
            (item) =>
              item.id == el.prd_id &&
              item.prdType != 2 &&
              item.prdType != 3 &&
              item.prdType != 4 &&
              item.prdType != 5
          );
          if (find)
            YH2AreaPrdList.push({
              ...find,
              canSealYH2: true,
            });
        });

        const prdList = stationAllProduct.filter((item) =>
          YH2PrdListId.includes(item.id * 1)
        );

        // 优惠2可点商品
        const YH2CanSealAllPrdList = prdList.map((item) => ({
          ...item,
          canSealYH2: true,
        }));

        // 当前区域下可点商品 与 可优惠2总商品求 交集
        YH2CanSealAllPrdList.forEach((el) => {
          // const find = YH2AreaPrdList.find(item => item.id == el.id && item.useType != 2)  // 过滤掉仅用于优惠的商品
          const find = YH2AreaPrdList.find((item) => item.id == el.id);
          if (find) YH2AllProductList.push({...find});
        });
      }

      /**
       * 花篮
       */
      // if (this.$store.state.userInfo.roleIds.includes(4)) {
      //   // 花篮在当前区域下可点商品
      //   const HLAreaPrdList = [];
      //   currentAreaAllProduct.forEach((el) => {
      //     const find = stationAllProduct.find(
      //       (item) => item.id == el.prd_id && item.useType != 2
      //     );
      //     if (find)
      //       HLAreaPrdList.push({
      //         ...find,
      //         canHL: true,
      //       });
      //   });

      //   // 花篮绑定在商品上，通过商品岗位筛选可点商品
      //   const authFlowerPrdList =
      //     this.$store.state.cardPageInfo.resResultDataObj[
      //       "authFlowerPrdList"
      //     ].filter(
      //       (item) =>
      //         item.status == 1 &&
      //         item.station_id == this.$store.state.userInfo.station_id
      //     );

      //   // 商品配置过花篮的商品
      //   let HLCanHLPrdList = [];
      //   stationAllProduct.forEach((el) => {
      //     const findProduct = authFlowerPrdList.find(
      //       (ele) => ele.prd_id == el.id
      //     );
      //     if (findProduct)
      //       HLCanHLPrdList.push({
      //         ...el,
      //         canHL: true,
      //       });
      //   });

      //   // 当前区域下商品 与 花篮商品求 交集
      //   HLCanHLPrdList.forEach((el) => {
      //     const find = HLAreaPrdList.find((item) => item.id == el.id);
      //     if (find) HLAllProductList.push({...find});
      //   });
      // }

      // 最终展示在页面上的商品列表
      let resultProductArr = [];

      // 此处将两个系统分开，是为了让收银人获取到在点单系统中自己对商品的优惠权限（收银系统中，优惠授权时，如果自己又此商品的优惠权限，则显示自己授权，否则不显示）
      let resultSYProductArr = []; // 收银点单的可点商品
      let resultDDProductArr = []; // 点单系统（服务员、营销、花篮）的可点商品

      if (this.$store.state.userInfo.authStatus == 4 || isGQ) {
        // 收银员
        const SYResultProductArrList = [];
        stationAllProduct.forEach((el) => {
          const findProduct = currentAreaAllProduct.find(
            (ele) => ele.prd_id == el.id
          );
          if (findProduct) SYResultProductArrList.push({...el});
        });

        SYResultProductArrList.forEach((el) => {
          const resultProduct = SYSecondCategory.find(
            (ele) => el.twoCateId == ele.twoCateId
          );
          if (resultProduct) resultSYProductArr.push({...el});
        });

        // console.log('resultSYProductArr', resultSYProductArr)
      }

      // 获取所有系统中的权限
      if (true) {
        // 服务员、营销、花篮、优惠2

        // 合并服务员 和  营销
        const mergePrdList = [];
        // FWYAllProductList.filter(item => YXAllProductList.find(items => item.id == items.id))
        FWYAllProductList.forEach((el) => {
          const find = YXAllProductList.find((item) => item.id == el.id);
          if (find) mergePrdList.push({...find});
        });

        const tempResultProductArrList = [
          ...FWYAllProductList,
          ...YXAllProductList,
        ].filter(
          (item, index, arr) =>
            arr.findIndex((items) => item.id == items.id) == index
        );
        mergePrdList.forEach((el) => {
          const findFWYPrd = FWYAllProductList.find((item) => item.id == el.id);
          const findYXPrd = YXAllProductList.find((item) => item.id == el.id);
          if (findFWYPrd && findYXPrd) {
            (el.canOrderMeal = findFWYPrd.canOrderMeal),
              (el.canSeal = findYXPrd.canSeal);
          }
        });

        tempResultProductArrList.forEach((el) => {
          const find = mergePrdList.find((item) => item.id == el.id);
          if (find) {
            el.canOrderMeal = find.canOrderMeal;
            el.canSeal = find.canSeal;
          }
        });

        // 在原服务员  与  营销 合并基础上 与  优惠2  合并  求并集
        const mergePrdList2 = [];
        tempResultProductArrList.forEach((el) => {
          const find = YH2AllProductList.find((item) => item.id == el.id);
          if (find) mergePrdList2.push({...find});
        });

        const tempResultProductArrList2 = [
          ...tempResultProductArrList,
          ...YH2AllProductList,
        ].filter(
          (item, index, arr) =>
            arr.findIndex((items) => item.id == items.id) == index
        );
        mergePrdList2.forEach((el) => {
          const findMergePrd = tempResultProductArrList.find(
            (item) => item.id == el.id
          );
          const findYH2Prd = YH2AllProductList.find((item) => item.id == el.id);
          if (findMergePrd && findYH2Prd) {
            (el.canOrderMeal = findMergePrd.canOrderMeal),
              (el.canSeal = findMergePrd.canSeal);
            el.canSealYH2 = findYH2Prd.canSealYH2;
          }
        });

        tempResultProductArrList2.forEach((el) => {
          const find = mergePrdList2.find((item) => item.id == el.id);
          if (find) {
            el.canOrderMeal = find.canOrderMeal;
            el.canSeal = find.canSeal;
            el.canSealYH2 = find.canSealYH2;
          }
        });

        //  在原合并基础上  再次  合并  花篮/消费/赔偿
        //  花篮/消费/赔偿 商品需要授权，因此如果与之前合并的商品发生冲突，则全部视为花篮花篮/消费/赔偿 商品处理
        // const mergePrdList3 = [];
        // tempResultProductArrList2.forEach((el) => {
        //   const find = HLAllProductList.find((item) => item.id == el.id);
        //   if (find) mergePrdList3.push({...find});
        // });

        // const tempResultProductArrList3 = [
        //   ...tempResultProductArrList2,
        //   ...HLAllProductList,
        // ].filter(
        //   (item, index, arr) =>
        //     arr.findIndex((items) => item.id == items.id) == index
        // );
        // mergePrdList3.forEach((el) => {
        //   const findMergePrd = tempResultProductArrList2.find(
        //     (item) => item.id == el.id
        //   );
        //   const findHLPrd = HLAllProductList.find((item) => item.id == el.id);
        //   if (findMergePrd && findHLPrd) {
        //     // el.canOrderMeal = false  // findMergePrd.canOrderMeal,
        //     // el.canSeal = false  //  findMergePrd.canSeal
        //     // el.canSealYH2 = false  // findMergePrd.canSealYH2
        //     (el.canOrderMeal = findMergePrd.canOrderMeal),
        //       (el.canSeal = findMergePrd.canSeal);
        //     el.canSealYH2 = findMergePrd.canSealYH2;
        //     el.canHL = findHLPrd.canHL;
        //   }
        // });

        // tempResultProductArrList3.forEach((el) => {
        //   const find = mergePrdList3.find((item) => item.id == el.id);
        //   if (find) {
        //     el.canOrderMeal = find.canOrderMeal;
        //     el.canSeal = find.canSeal;
        //     el.canSealYH2 = find.canSealYH2;
        //     el.canHL = find.canHL;
        //   }
        // });

        // 点单系统中的人员权限
        resultDDProductArr = [...tempResultProductArrList2];

        // console.log('resultDDProductArr', resultDDProductArr)
      }

      // 给收银系统的所以商品匹配自己在点单系统的身份权限
      if (this.$store.state.userInfo.authStatus == 4 || isGQ) {
        // 收银系统
        resultSYProductArr.forEach((el) => {
          const find = resultDDProductArr.find((item) => item.id == el.id);
          if (find) {
            resultProductArr.push({
              ...el,
              canOrderMeal: find.canOrderMeal,
              canSeal: find.canSeal,
              canHL: find.canHL,
              canSealYH2: find.canSealYH2,
            });
          } else {
            resultProductArr.push({ ...el });
          }
        });
      } else {
        // 点单系统
        resultProductArr = [...resultDDProductArr];
      }

      // 判断是否当前卡台为补交卡台（不能点优惠/优惠2）
      if (this.$store.state.orderInfo.currentCardInfo.bizType == 3) {
        resultProductArr = resultProductArr.filter(
          (item) =>
            (!item.canSeal && !item.canSealYH2) ||
            item.canHL ||
            item.canOrderMeal
        );

        resultProductArr = resultProductArr.map((item) => ({
          ...item,
          canSeal: false,
          canSealYH2: false,
        }));
      }

      /* 通过 this.$store.state.cardPageInfo.resResultDataObj["areaProduct"]，结构如下
      [{
      "region_id": "231590956410106",
      "status": "1",
      "prd_id": "232162229462095",
      "mklib_id": "231590944409827"
      }] 过滤resultProductArr中 数据，不在当前区域的都排除掉
      */

      // 点单系统
      if (sessionStorage.getItem("client") == "order" 
      && (this.$store.state.userInfo.roleIds.includes(2) 
      || this.$store.state.userInfo.roleIds.includes(4)) 
      && this.$store.state.orderInfo.currentCardInfo.isWaiter){
        resultProductArr = [...stationAllProduct.filter(item => this.$store.state.cardPageInfo.resResultDataObj[
          "authFlowerPrdList"
        ].findIndex(i => i.prd_id == item.id && i.station_id == authStationId && i.status == '1') >= 0).map(item => {
          return {...item, canHL: true}
        }), ...resultProductArr]
      }

      if (sessionStorage.getItem("client") == "order" 
      && (this.$store.state.orderInfo.currentCardInfo.bizType == '3' || this.$store.state.orderInfo.currentCardInfo.bizType == '4')) {
        let tmpArr = [...stationAllProduct.filter(item => this.$store.state.cardPageInfo.resResultDataObj[
          "funcOrderPrdConfig"
        ].findIndex(i => i.prd_id == item.id && i.seat_id == this.$store.state.orderInfo.currentCardInfo.id && i.status == '1') >= 0).map(item => {
          return {...item}
        })]

        // 从tmpArr过滤所有resultProductArr包含的商品
        resultProductArr = tmpArr.filter(item => resultProductArr.find(i => i.id == item.id))
      }

      resultProductArr = resultProductArr.filter(i => currentAreaAllProduct.findIndex(
        (item) => item.prd_id == i.id && item.region_id == this.$store.state.orderInfo.currentCardInfo.regionId && item.status == '1'
      ) >= 0);

      // 通过最终商品获取最终当前岗位对应的二级分类
      const secondCategoryInfoArr = [];
      secondCategoryAll.forEach((el) => {
        const secondCategoryInfo = resultProductArr.find(
          (ele) => el.id == ele.twoCateId
        );
        if (secondCategoryInfo)
          secondCategoryInfoArr.push({
            ...el,
            twoCateId: el.id,
          });
      });

      // 通过最终二级分类在所有二级分类中匹配出含有一级分类id的二级分类总和
      const resultSecondCategoryInfoArr = [];
      secondCategoryAll.forEach((el) => {
        const secondCategoryInfo = secondCategoryInfoArr.find(
          (ele) => el.id == ele.twoCateId
        );
        if (secondCategoryInfo) resultSecondCategoryInfoArr.push({...el});
      });

      // 通过匹配到的二级分类获取一级分类
      const resultFirstCategoryInfoArr = [];
      firstCategoryAll.forEach((el) => {
        const firstCategoryInfo = resultSecondCategoryInfoArr.find(
          (ele) => el.id == ele.oneCateId
        );
        if (firstCategoryInfo) resultFirstCategoryInfoArr.push({...el});
      });

      // 排序（从小到大）
      this.firstCategoryList = resultFirstCategoryInfoArr.sort(
        (a, b) => a.dsp - b.dsp
      );
      this.secondCategoryListAll = resultSecondCategoryInfoArr.sort(
        (a, b) => a.dsp - b.dsp
      );

 
      this.productListAll = resultProductArr.sort((a, b) => a.dsp - b.dsp);

      this.$emit("updateProductsList", {
        // 所有可点商品
        key: "allProductsList",
        value: resultProductArr,
      });
      this.$store.commit("updateOrderInfo", {
        // 储存所有有效商品(包含可点和不可点)
        key: "allProductsList",
        value: stationAllProduct,
      });
      this.$store.commit("updateOrderInfo", {
        // 储存所有可点商品
        key: "productAll",
        value: resultProductArr,
      });

      if (this.$route.name == "orderMealList") {
        // 点单系统
        const { mustOrderPrdId } = this.$route.query;
        if (mustOrderPrdId) this.getMustPrdInfo();
        else this.changeFirstCategory();
      } else if (this.$route.name == "moneyCard" || this.$route.name == 'orderCard' ) {
        // 沽清(默认选中第一个一级菜单)
        this.changeFirstCategory();
      }
    },
  },
};
