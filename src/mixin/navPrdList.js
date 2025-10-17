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
        // 当前岗位可点商品没有限制（收银员）
        // 注意：督察角色的查单权限不等于点单权限，督察在点单时应该按照其岗位配置的可点商品
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
       * 修复：移除 isWaiter 条件，对于拥有服务员权限的用户，不管打开什么类型的卡台都需要构建 FWYSecondCategory
       */
      if (true) {
        if ((this.$store.state.userInfo.roleIds.includes(2) 
        || this.$store.state.userInfo.roleIds.includes(4)) 
        && !isGQ) {
          // 服务员 特饮
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
        // 估清（不包括督察，督察的查单权限不等于点单权限）
        currentAreaAllProduct = this.$store.state.cardPageInfo.resResultDataObj[
          "areaProduct"
        ].filter((el) => el.status == 1);
      } else {
        // 服务员  或  营销  或  花篮  或  优惠  或  优惠2  或  督察（督察按区域过滤）
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
       *  修复：对于拥有服务员权限的用户，不管打开什么类型的卡台（服务员卡台或营销卡台），
       *  都需要构建服务员商品列表，因为在营销卡台中也需要显示 canOrderMeal 权限标记
       */
      if ((this.$store.state.userInfo.roleIds.includes(2) 
      || this.$store.state.userInfo.roleIds.includes(4)) 
      && !isGQ) {
        console.log('🔍 [DEBUG] 开始构建服务员商品列表');
        console.log('  - currentAreaAllProduct 数量:', currentAreaAllProduct.length);
        console.log('  - FWYSecondCategory 数量:', FWYSecondCategory.length);
        console.log('  - stationAllProduct 数量:', stationAllProduct.length);
        
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
        
        console.log('🔍 [DEBUG] 服务员商品列表构建完成:');
        console.log('  - FWYAreaPrdList 数量:', FWYAreaPrdList.length);
        console.log('  - FWYSecondCategoryPrdList 数量:', FWYSecondCategoryPrdList.length);
        console.log('  - FWYAllProductList (过滤前) 数量:', FWYAllProductList.length);
      }
      // 去掉元数据42中所有服务员的不可点商品
      let noOrderPrdList = this.$store.state.cardPageInfo.resResultDataObj["orderPrdList"]
      .filter(item => item.station_id == authStationId && item.status == 1).map(item => item.prd_id)
      FWYAllProductList = FWYAllProductList.filter(item => !noOrderPrdList.includes(item.id))
      
      console.log('🔍 [DEBUG] FWYAllProductList (过滤后) 数量:', FWYAllProductList.length, FWYAllProductList.slice(0, 3).map(p => ({id: p.id, name: p.name, canOrderMeal: p.canOrderMeal})))

      /**
       * 营销
       */
      if (this.$store.state.userInfo.roleIds.includes(3) 
        && (this.$store.state.orderInfo.currentCardInfo.isYX) && !isGQ) {
        // 营销在当前区域下可点商品
        const YXAreaPrdList = [];

        currentAreaAllProduct.forEach((el) => {
          // const find = stationAllProduct.find((item) => item.id == el.prd_id && item.prdType == 1);
          const find = stationAllProduct.find((item) => item.id == el.prd_id);
          if (find)
            YXAreaPrdList.push({
              ...find,
              canSeal:true,
            });
        });

        const prdList = stationAllProduct.filter((item) =>
          prdListId.includes(item.id * 1)
        );

        /* 从  'roleLimitConfig',     // 36-角色限额限量配置 
         'limitPrdDetail',      // 37-限额限量实际明细商品(最终效果) 
         获取配置商品id列表， 
         roleLimitConfig结构station_id: el[0], // 角色id
          auth_type: el[1], // 授权类型 2 优惠 3 优惠2
          free_limit_id: el[2], // 限额配置Id,
          status: el[3]  // 状态 1 有效 2 无效 3 删除 
        limitPrdDetail结构  free_limit_id: el[0], // 限额配置Id
          prd_id: el[1], // 商品Id
          status: el[2]  // 状态 1 有效 2 无效 3 删除
          */
        const limitConfig = this.$store.state.cardPageInfo.resResultDataObj["roleLimitConfig"]
        const limitPrdDetail = this.$store.state.cardPageInfo.resResultDataObj["limitPrdDetail"]
        const limitPrdDetailList = limitPrdDetail.filter(item => item.status == 1).filter(item => prdListId.includes(item.prd_id * 1))
        const limitConfigList = limitConfig.filter(item => item.status == 1 && item.auth_type == 2).filter(item => limitPrdDetailList.findIndex(i => i.free_limit_id == item.free_limit_id) >= 0)
        const limitConfigIdList = limitConfigList.map(item => item.free_limit_id * 1)
        const limitPrdDetailIdList = limitPrdDetailList.filter(item => limitConfigIdList.includes(item.free_limit_id * 1)).map(item => item.prd_id * 1)
        const yhPrdList = stationAllProduct.filter(item => limitPrdDetailIdList.includes(item.id * 1))


        // 营销可优惠商品
        const YXCanSealAllPrdList = yhPrdList.map((item) => ({
          ...item,
          canSeal: true,
        }));

        // 当前区域下商品 与 可优惠总商品求 交集
        YXCanSealAllPrdList.forEach((el) => {
          const find = YXAreaPrdList.find((item) => item.id == el.id);
          if (find) YXAllProductList.push({...find});
        });

      }
      console.log('YXAllProductList: ', YXAllProductList)

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
      let resultDDProductArr = []; // 点单系统（服务员、营销、花篮、督察）的可点商品

      if (this.$store.state.userInfo.authStatus == 4 || isGQ) {
        // 收银员（不包括督察，督察按岗位配置过滤商品）
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
        
        console.log('🔍 [DEBUG] FWYAllProductList 数量:', FWYAllProductList.length, FWYAllProductList.map(p => p.name));
        console.log('🔍 [DEBUG] YXAllProductList 数量:', YXAllProductList.length, YXAllProductList.map(p => p.name));
        console.log('🔍 [DEBUG] YH2AllProductList 数量:', YH2AllProductList.length, YH2AllProductList.map(p => p.name));

        // 合并服务员 和 营销，以id为唯一键合并FWYAllProductList和YXAllProductList
        // 关键修复：既可点又可优惠的商品，需要同时保留 canOrderMeal 和 canSeal 标记
        const tempResultProductArrList = [
          ...FWYAllProductList,
          ...YXAllProductList,
        ].filter(
          (item, index, arr) =>
            arr.findIndex((items) => item.id == items.id) == index
        );
        
        console.log('🔍 [DEBUG] tempResultProductArrList 合并去重后数量:', tempResultProductArrList.length);
        
        // 标记每个商品的权限：canOrderMeal（可点）和 canSeal（可优惠）
        tempResultProductArrList.forEach((el) => {
          const findFWYPrd = FWYAllProductList.find((item) => item.id == el.id);
          const findYXPrd = YXAllProductList.find((item) => item.id == el.id);
          
          // 初始化为 undefined
          el.canOrderMeal = undefined;
          el.canSeal = undefined;
          
          // 如果在服务员列表中，标记为可点
          if (findFWYPrd) {
            el.canOrderMeal = true;
          }
          // 如果在营销列表中，标记为可优惠
          if (findYXPrd) {
            el.canSeal = true;
          }
          
          console.log(`🔍 [DEBUG] 权限标记 - 商品 ${el.name} (${el.id}): canOrderMeal=${el.canOrderMeal}, canSeal=${el.canSeal}`);
          
          // 关键：如果同时在两个列表中，会同时拥有 canOrderMeal: true 和 canSeal: true
        });

        // 在原服务员 与 营销合并基础上 与 优惠2 合并 求并集
        const tempResultProductArrList2 = [
          ...tempResultProductArrList,
          ...YH2AllProductList,
        ].filter(
          (item, index, arr) =>
            arr.findIndex((items) => item.id == items.id) == index
        );
        
        // 标记优惠2权限，同时保留原有的 canOrderMeal 和 canSeal
        tempResultProductArrList2.forEach((el) => {
          const findMergePrd = tempResultProductArrList.find((item) => item.id == el.id);
          const findYH2Prd = YH2AllProductList.find((item) => item.id == el.id);
          
          // 继承之前的权限标记
          if (findMergePrd) {
            el.canOrderMeal = findMergePrd.canOrderMeal;
            el.canSeal = findMergePrd.canSeal;
          }
          
          // 如果在优惠2列表中，添加 canSealYH2 标记
          if (findYH2Prd) {
            el.canSealYH2 = true;
          }
          
          // 关键：既可点又可优惠2的商品，会同时拥有多个权限标记
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

      console.log('🔍 [DEBUG] resultDDProductArr 生成完成，数量:', resultDDProductArr.length);
      }

      // 给收银系统的所有商品匹配自己在点单系统的身份权限
      if (this.$store.state.userInfo.authStatus == 4 || isGQ) {
        // 收银系统（不包括督察）
        resultSYProductArr.forEach((el) => {
          const find = resultDDProductArr.find((item) => item.id == el.id);
          if (find) {
            // 重要：保留所有权限标记，确保既可点又可优惠的商品能正确触发选择弹窗
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
        // 点单系统（服务员、营销、督察等）
        console.log('🔍 [DEBUG] 点单系统路径 - 直接复制 resultDDProductArr');
        resultProductArr = [...resultDDProductArr];
      }

      console.log('🔍 [DEBUG] 当前卡台 bizType:', this.$store.state.orderInfo.currentCardInfo.bizType);
      
      // 判断是否当前卡台为补交卡台（不能点优惠/优惠2）
      if (this.$store.state.orderInfo.currentCardInfo.bizType == 3 && !isGQ) {
        console.log('🔍 [DEBUG] 补交卡台处理 - 过滤前数量:', resultProductArr.length);
        resultProductArr = resultProductArr.filter(
          (item) =>
            (!item.canSeal && !item.canSealYH2) ||
            item.canHL ||
            item.canOrderMeal
        );

        resultProductArr = resultProductArr.map((item) => ({
          ...item,
          // canSeal: false,
          canSealYH2: false,
        }));
        console.log('🔍 [DEBUG] 补交卡台处理 - 过滤后数量:', resultProductArr.length);
      }
      console.log('resultProductArr--------------:', resultProductArr)

      
      // 点单系统 - 花篮/赔偿商品处理
      // if (sessionStorage.getItem("client") == "order" 
      // 修复：只要有服务员或特饮角色，并且配置了花篮商品权限，就可以看到花篮商品，不受卡台类型限制
      const hasWaiterOrDrinkRole = this.$store.state.userInfo.roleIds.includes(2) || this.$store.state.userInfo.roleIds.includes(4);
      
      if (true && hasWaiterOrDrinkRole && !isGQ) {
        resultProductArr = [...stationAllProduct.filter(item => this.$store.state.cardPageInfo.resResultDataObj[
          "authFlowerPrdList"
        ].findIndex(i => i.prd_id == item.id && i.station_id == authStationId && i.status == '1') >= 0).map(item => {
          // 重要：保留所有权限标记，包括 canSealYH2 和 canHL
          const original = resultProductArr.find(i => i.id == item.id)
          if(original) {
            return {
              ...item,
              canOrderMeal: original.canOrderMeal,
              canSeal: original.canSeal,
              canSealYH2: original.canSealYH2,
              canHL: true  // 花篮商品标记
            }
          }
          return {...item, canHL: true}
        }), ...resultProductArr]
      }

      // if (sessionStorage.getItem("client") == "order" 
      if (true
      && (this.$store.state.orderInfo.currentCardInfo.bizType == '3' || this.$store.state.orderInfo.currentCardInfo.bizType == '4') && !isGQ) {
        console.log('🔍 [DEBUG] 功能性卡台处理 - bizType:', this.$store.state.orderInfo.currentCardInfo.bizType);
        console.log('🔍 [DEBUG] 功能性卡台处理 - 处理前 resultProductArr:', resultProductArr);
        
        // 先从stationAllProduct筛选出符合条件的商品
        let tmpArr = [...stationAllProduct.filter(item => this.$store.state.cardPageInfo.resResultDataObj[
          "funcOrderPrdConfig"
        ].findIndex(i => i.prd_id == item.id && i.seat_id == this.$store.state.orderInfo.currentCardInfo.id && i.status == '1') >= 0)]
        
        console.log('🔍 [DEBUG] 功能性卡台处理 - tmpArr:', tmpArr);
        
        resultProductArr = tmpArr.map(item => {
          const original = resultProductArr.find(i => i.id == item.id)
          console.log(`🔍 [DEBUG] 功能性卡台处理 - 商品 ${item.name} (${item.id}), original:`, original);
          if(original) {
            // 重要：保留所有权限标记
            const result = {
              ...item,
              canOrderMeal: original.canOrderMeal,
              canSeal: original.canSeal,
              canSealYH2: original.canSealYH2,
              canHL: original.canHL
            };
            console.log(`🔍 [DEBUG] 功能性卡台处理 - 商品 ${item.name} 权限保留结果:`, result);
            return result;
          }
          console.log(`🔍 [DEBUG] 功能性卡台处理 - 商品 ${item.name} 未找到 original，返回 null`);
          return null
        }).filter(item => item !== null) // 移除未匹配的项
        
        console.log('🔍 [DEBUG] 功能性卡台处理 - 处理后 resultProductArr:', resultProductArr);
      }

      /* 通过 this.$store.state.cardPageInfo.resResultDataObj["areaProduct"]，结构如下
      [{
      "region_id": "231590956410106",
      "status": "1",
      "prd_id": "232162229462095",
      "mklib_id": "231590944409827"
      }] 过滤resultProductArr中 数据，不在当前区域的都排除掉
      */
      // if (sessionStorage.getItem("client") == "order" && !isGQ) {
      if (true && !isGQ) {
        resultProductArr = resultProductArr.filter(i => currentAreaAllProduct.findIndex(
          (item) => item.prd_id == i.id && item.region_id == this.$store.state.orderInfo.currentCardInfo.regionId && item.status == '1'
        ) >= 0);
      }

      /*  根据card.js secondCategoryInfo 3) 商品二级分类 id,name,status,dsp,oneCateId,enable_time_limit,begin_time,end_time,begin_time2,end_time2
      商品二级分类Id,分类名称,分类状态:1有效 2无效 3 删除, 分类显示顺序, 二级分类所属一级分类Id,开启时间段限制 1 开启 2 未开启,时间段1开始时间格式hh24:mi,时间段1结束时间,时间段2开始时间,时间段2结束时间 
      里的 enable_time_limit,begin_time,end_time,begin_time2,end_time2，判断当前商品是否在时间段内
      如果二级分类下没有商品，隐藏二级分类，如果一级分类下没有商品隐藏一级分类
      */
      if (!isGQ) {
        const secondCategoryInfo = this.$store.state.cardPageInfo.resResultDataObj.secondCategoryInfo
        const nowTime = new Date().getTime()
        resultProductArr = resultProductArr.filter(item => {
          const find = secondCategoryInfo.find(el => el.id == item.twoCateId)
          if (find && find.enable_time_limit == 1) {
            const beginTime = new Date(new Date().toLocaleDateString() + ' ' + find.begin_time).getTime()
            const endTime = new Date(new Date().toLocaleDateString() + ' ' + find.end_time).getTime()
            const beginTime2 = new Date(new Date().toLocaleDateString() + ' ' + find.begin_time2).getTime()
            const endTime2 = new Date(new Date().toLocaleDateString() + ' ' + find.end_time2).getTime()
            if (nowTime < beginTime || nowTime > endTime) {
              if (nowTime < beginTime2 || nowTime > endTime2) {
                return false
              }
            }
          }
          return true
        })


      if (this.redeem == 0) {
        resultProductArr = resultProductArr.filter(item => ![12,22,32].includes(item.prdType*1))
      } else {
        resultProductArr = resultProductArr.filter(item => [this.redeem].includes(item.prdType*1))
      }
    }
      console.log('navprdlist redeem', this.redeem, resultProductArr)
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
