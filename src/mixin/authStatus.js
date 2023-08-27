export default {
  data() {
    return {
      authStationId: "",
      authStatusArr: [], // 1:服务员  2：营销  3：花篮  5：优惠2
    };
  },
  methods: {
    getAuthStatus() {
      // 当前用户岗位id
      this.authStationId = this.$store.state.userInfo.station_id;

      /**
       * 判断是否有服务员权限身份
       */

      // 所有商品不限点的岗位id(可点商品没有限制的岗位id)
      const notLimitStationId = this.$store.state.cardPageInfo.resResultDataObj[
        "jobLimitInfo"
      ].filter(
        (item) => item.status == 1 && this.authStationId == item.stationId
      );

      if (notLimitStationId.length > 0) {
        this.authStatusArr = [...new Set([...this.authStatusArr, 1])];
      } else {
        // 所有岗位可点的有效二级分类
        const secondCategory = this.$store.state.cardPageInfo.resResultDataObj[
          "jobSecondLimitInfo"
        ].filter(
          (item) => item.status == 1 && this.authStationId == item.stationId
        );
        if (secondCategory.length > 0)
          this.authStatusArr = [...new Set([...this.authStatusArr, 1])];
      }

      /**
       * 判断是否有营销权限身份(优惠)
       */

      const prdList = this.getSealConfigPrdId();

      if (prdList.length > 0)
        this.authStatusArr = [...new Set([...this.authStatusArr, 2])];

      /**
       * 判断是否有优惠2权限身份(优惠2)
       */
      const prdListOfYH2 = this.getSealConfigPrdId(3);

      if (prdListOfYH2.length > 0)
        this.authStatusArr = [...new Set([...this.authStatusArr, 5])];

      /**
       * 判断是否有花篮/小费权限身份
       */
      // 关联花篮/小费商品
      const authFlowerPrdList = this.$store.state.cardPageInfo.resResultDataObj[
        "authFlowerPrdList"
      ].filter(
        (item) => item.status == 1 && this.authStationId == item.station_id
      );
      if (authFlowerPrdList.length > 0)
        this.authStatusArr = [...new Set([...this.authStatusArr, 3])];

      this.$store.commit("updateUserInfo", {
        ...this.$store.state.userInfo,
        authStatusArr: this.authStatusArr, // 1:服务员  2：营销   3：花篮/小费  5:优惠2
      });
    },

    // 获取营销身份的可点商品id  参数：type:2:优惠  3：优惠2
    getSealConfigPrdId(type = 2) {
      const limitRoleFreeLimitIdList =
        this.$store.state.cardPageInfo.resResultDataObj["roleLimitConfig"]
          .filter(
            (item) =>
              item.status == 1 &&
              item.station_id == this.authStationId &&
              item.auth_type == type
          )
          .map((item) => item.free_limit_id * 1);

      // 商品id
      const prdList = this.$store.state.cardPageInfo.resResultDataObj[
        "limitPrdDetail"
      ]
        .filter(
          (item) =>
            item.status == 1 &&
            limitRoleFreeLimitIdList.includes(item.free_limit_id * 1)
        )
        .map((item) => item.prd_id * 1);

      return prdList;
    },
  },
};
