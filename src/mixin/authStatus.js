export default {
  data() {
    return {
      authStationId: "",
      authStatusArr: [], // 1:服务员  2：营销  3：花篮  5：优惠2
    };
     // authStatusArr 改为 roleIds
    // 系统角色 1 咨客 2服务员 3营销 4特饮/花篮 5收银员 6系统管理员 7会员中心 8ERP管理员 9仓库管理员 10 存酒管理员 11 督查
  },
  methods: {
    getAuthStatus() {
      // 当前用户岗位id
      this.authStationId = this.$store.state.userInfo.station_id;

      /**
       * 判断是否有服务员权限身份
       */

      // 所有商品不限点的岗位id(可点商品没有限制的岗位id)
     const jobLimitInfoLis =  this.$store.state.cardPageInfo.resResultDataObj[
        "jobLimitInfo"
      ] || [];
      const notLimitStationId = jobLimitInfoLis.filter(
        (item) => item.status == 1 && this.authStationId == item.stationId
      );

      if (notLimitStationId.length > 0) {
        this.authStatusArr = [...new Set([...this.authStatusArr, 1])];
      } else {
        // 所有岗位可点的有效二级分类
       const jobSecondLimitInfo =  this.$store.state.cardPageInfo.resResultDataObj[
          "jobSecondLimitInfo"
        ] || [];
        const secondCategory = jobSecondLimitInfo.filter(
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
       *  判断是否有优惠2权限身份(优惠2) 
       *  权限身份：暂时特殊处理  roleIds 添加1000
       */
      const prdListOfYH2 = this.getSealConfigPrdId(3);

      let roleIds = this.$store.state.userInfo.roleIds;
      if (prdListOfYH2.length > 0){
        // this.authStatusArr = [...new Set([...this.authStatusArr, 5])];
        roleIds = [...new Set([...roleIds, 1000])];

      }
      
      /**
       * 判断是否有花篮/小费权限身份
       */
      // 关联花篮/小费商品
      const authFlowerPrd = this.$store.state.cardPageInfo.resResultDataObj[
        "authFlowerPrdList"
      ]|| [];
      
     const authFlowerPrdList = authFlowerPrd.filter(
        (item) => item.status == 1 && this.authStationId == item.station_id
      );
      if (authFlowerPrdList.length > 0)
        this.authStatusArr = [...new Set([...this.authStatusArr, 3])];

      this.$store.commit("updateUserInfo", {
        ...this.$store.state.userInfo,
        authStatusArr: this.authStatusArr, // 1:服务员  2：营销   3：花篮/小费  5:优惠2
        roleIds: roleIds
      });
    },

    // 获取营销身份的可点商品id  参数：type:2:优惠  3：优惠2
    getSealConfigPrdId(type = 2) {
      const roleLimitConfig = this.$store.state.cardPageInfo.resResultDataObj["roleLimitConfig"] || []
      const limitRoleFreeLimitIdList =
      roleLimitConfig.filter(
            (item) =>
              item.status == 1 &&
              item.station_id == this.authStationId &&
              item.auth_type == type
          )
          .map((item) => item.free_limit_id * 1);

      // 商品id
      const limitPrdDetail =this.$store.state.cardPageInfo.resResultDataObj[
        "limitPrdDetail"
      ] || []
      const prdList = 
       limitPrdDetail.filter(
          (item) =>
            item.status == 1 &&
            limitRoleFreeLimitIdList.includes(item.free_limit_id * 1)
        )
        .map((item) => item.prd_id * 1);

      return prdList;
    },

    // 检查是否有全场查单权限（督查）
    hasFullLookupPermission() {
      const userInfo = this.$store.state.userInfo;
      
      // 检查用户是否有督查角色
      if (!userInfo.roleIds || !userInfo.roleIds.includes(11)) {
        return false;
      }
      
      // 获取督查可查区域配置数据（56号数据）
      const supervisorRegionConfig = this.$store.state.cardPageInfo.resResultDataObj["supervisorRegionConfig"] || [];
      
      // 检查当前用户岗位是否有全场权限（region_id = 0）
      const hasFullAccess = supervisorRegionConfig.some(config => 
        config.status === 1 && 
        config.station_id === userInfo.station_id && 
        config.region_id === 0
      );
      
      return hasFullAccess;
    },

    // 获取督查区域权限ID列表
    getSupervisorRegionPermissions() {
      const userInfo = this.$store.state.userInfo;
      
      // 检查用户是否有督查角色
      if (!userInfo.roleIds || !userInfo.roleIds.includes(11)) {
        return [];
      }
      
      // 获取督查可查区域配置数据（56号数据）
      const supervisorRegionConfig = this.$store.state.cardPageInfo.resResultDataObj["supervisorRegionConfig"] || [];
      
      // 获取当前用户岗位的区域权限ID列表（排除全场查单的0）
      const regionPermissions = supervisorRegionConfig
        .filter(config => 
          config.status === 1 && 
          config.station_id === userInfo.station_id && 
          config.region_id !== 0
        )
        .map(config => config.region_id);
      
      return regionPermissions;
    },

    // 判断是否为督查区域权限ID
    isSupervisorRegionPermission(regionId) {
      const userInfo = this.$store.state.userInfo;
      
      // 检查用户是否有督查角色
      if (!userInfo.roleIds || !userInfo.roleIds.includes(11)) {
        return false;
      }
      
      // 获取督查可查区域配置数据（56号数据）
      const supervisorRegionConfig = this.$store.state.cardPageInfo.resResultDataObj["supervisorRegionConfig"] || [];
      
      // 检查该区域ID是否在当前用户的权限范围内
      return supervisorRegionConfig.some(config => 
        config.status === 1 && 
        config.station_id === userInfo.station_id && 
        config.region_id === regionId
      );
    },

    // 检查督查是否有某个区域的权限
    hasSupervisorRegionPermission(regionId) {
      const userInfo = this.$store.state.userInfo;
      
      // 检查用户是否有督查角色
      if (!userInfo.roleIds || !userInfo.roleIds.includes(11)) {
        return false;
      }
      
      // 如果有全场查单权限，可以查看所有区域
      if (this.hasFullLookupPermission()) {
        return true;
      }
      
      // 检查是否有该区域的权限
      return this.isSupervisorRegionPermission(regionId);
    },
  },
};
