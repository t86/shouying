<template>
  <div class="menu-list">
    <div class="nav">
      <!-- 二级菜单 -->
      <div class="nav-menu" :style="{ width: navWidth + 'px' }">
        <div class="search">
          <i class="el-icon-search"></i>
          <el-input size="mini" clearable v-model="searchVal" placeholder="搜索" @input="inputSearchHandle" />
        </div>
        <div class="menu-list">
          <!-- 完整分类菜单 -->
          <ul v-if="!searchVal" class="first-cate">
            <div
              class="pointer p-l-2"
              @click="showOrHideMenuListHandle"
            >
              <i
                :class="{ rotate: showMenuList }"
                style="color: #8c8c8c"
                class="el-icon-caret-right"
              ></i>
              <img :src="require('@/assets/img/file_list.png')" alt />
              <span class="name">全部</span>
            </div>
            <requireMenu v-if="showMenuList" :menuList="menuList" />
          </ul>
          <!-- 展示搜索结果的二级菜单 -->
          <div v-else class="search-list">
            <div v-if="searchMenu.typeList.length > 0" class="cate-list">
              <p>要求类型列表：</p>
              <ul>
                <li
                  v-for="(item, index) in searchMenu.typeList"
                  :key="index"
                  layout="row"
                  layout-align="start center"
                  @click.stop="getSearchDetail(item, 'type')"
                >
                  <img :src="require('@/assets/img/file_list.png')" alt />
                  <span>{{ item.n }}</span>
                </li>
              </ul>
            </div>
            <div v-if="searchMenu.detailList.length > 0" class="prd-list">
              <p>要求明细列表：</p>
              <ul>
                <li
                  v-for="(item, index) in searchMenu.detailList"
                  :key="index"
                  layout="row"
                  layout-align="start center"
                  @click.stop="getSearchDetail(item, 'detail')"
                >
                  <img :src="require('@/assets/img/commodity_list.png')" alt />
                  <span>{{ item.n }}</span>
                </li>
              </ul>
            </div>
            <div
              v-if="
                searchMenu.typeList.length == 0 &&
                searchMenu.detailList.length == 0
              "
              class="no-data m-t-4"
              style="text-align: center"
            >
              <img style="width: 60px" :src="require('@/assets/img/wu.png')" alt />
              <div class="fs12 m-t-2">暂无查找内容</div>
            </div>
          </div>
        </div>
      </div>
      <!-- 菜单对应内容 -->
      <div class="nav-content" :style="{ 'margin-left': navWidth + 10 + 'px' }">
        <requireTypeTable v-if="!$route.query.menuId" />
        <requireDetailTable v-else />
      </div>
    </div>
  </div>
</template>
 
<script>
const menuWidth = 230;
export default {
  data() {
    return {
      navWidth: menuWidth,
      searchVal: "",
      menuList: [],
      showMenuList: true,
      searchMenu: {
        typeList: [],
        detailList: []
      },

      showDrawer: false, // 是否显示搜索中的物料信息
      cardId: '', // 当前修改的seatId
    };
  },
  methods: {
    init() {
      this.getMenuList();
    },

    // 获取完整的menu
    async getMenuList() {
      try {
        const res = await this.$api.BMS.require.requestRqmTree()
        const isSearch = !!this.$route.query.search
        const menuId = this.$route.query.menuId || 0
        if(res.code == 1) {
          this.menuList = (res.data || []).map(item => {
            const find = this.menuList.find(items => items.id == item.id)
            let originShowList = false  // 初始菜单打开状态
            let showMenuList = false  // 搜索菜单时的区域菜单打开状态

            // 初始菜单打开状态
            if(find) {
              originShowList = find && find.showList
            } 

            // 菜单搜索
            if (isSearch) {
                // 搜索菜单
                showMenuList = item.id == menuId
            }
            
            return {
              ...item,
              showList: originShowList || showMenuList
            }
          })
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("获取完整的menu列表失败", error);
      }
    },

    showOrHideMenuListHandle() {
      this.$router.push({
        name: 'requireConfig'
      })
      this.showMenuList = !this.showMenuList;
    },

    // 菜单模糊查询列表
    async getSearchMenuData(keyword) {
      const params = {
        name: keyword || this.searchVal  //   string   模糊查询关键字
      };

      try {
        const res = await this.$api.BMS.require.requestRqmSearch(params);
        if(res.code == 1) {
          res.data = res.data || []
          this.searchMenu.typeList = res.data.filter(item => item.t == 1)
          this.searchMenu.detailList = res.data.filter(item => item.t == 2)
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("模糊查询列表失败", error);
      }
    },

    // 模糊搜索
    inputSearchHandle() {
      if (this.searchVal == "") {
        this.searchMenu.typeList = [];
        this.searchMenu.detailList = [];
      } else {
        this.getSearchMenuData(this.searchVal);
      }
    },

    // 从模糊查询中点击分类或商品
    getSearchDetail(itemInfo, type) {
        const menuId = itemInfo.rt
        this.$router.push('/BMS/requireConfig?menuId=' + menuId + '&search=true')

        this.searchVal = "";
        this.searchMenu.typeList = []
        this.searchMenu.detailList = []
    },

    // 在搜索商品详情后点击删除
    initSearchValHandle(){
      this.searchVal = ''
      this.searchMenu.typeList = []
      this.searchMenu.detailList = []
    }
  },
  mounted() {
    this.init();
  },
  components: {
    requireTypeTable: () => import('./requireConfigTable/requireTypeTable.vue'),
    requireDetailTable: () => import('./requireConfigTable/requireDetailTable.vue')
  }
};
</script>

<style scoped lang="less">
@import "./requireConfig.less";
</style>