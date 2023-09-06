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
            <areaMenu v-if="showMenuList" :menuList="menuList" />
          </ul>
          <!-- 展示搜索结果的二级菜单 -->
          <div v-else class="search-list">
            <div v-if="searchMenu.areaList.length > 0" class="cate-list">
              <p>区域列表：</p>
              <ul>
                <li
                  v-for="(item, index) in searchMenu.areaList"
                  :key="index"
                  layout="row"
                  layout-align="start center"
                  @click.stop="getSearchDetail(item, 'area')"
                >
                  <img :src="require('@/assets/img/file_list.png')" alt />
                  <span>{{ item.n }}</span>
                </li>
              </ul>
            </div>
            <div v-if="searchMenu.cardList.length > 0" class="prd-list">
              <p>卡台列表：</p>
              <ul>
                <li
                  v-for="(item, index) in searchMenu.cardList"
                  :key="index"
                  layout="row"
                  layout-align="start center"
                  @click.stop="getSearchDetail(item, 'card')"
                >
                  <img :src="require('@/assets/img/commodity_list.png')" alt />
                  <span>{{ item.n }}</span>
                </li>
              </ul>
            </div>
            <div
              v-if="
                searchMenu.areaList.length == 0 &&
                searchMenu.cardList.length == 0
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
        <areaTable v-if="menuIndex == 0" @getMenuList="getMenuList" />
        <cardTable v-if="menuIndex == 1" :menuList="menuList" @getMenuList="getMenuList"/>
        <!-- 新增或编辑 -->
        <addOrUpdateCard v-model="showDrawer" type="2" :menuList="menuList" :currentInfo="{id: cardId}" search="true" @getTableData="initSearchValHandle" />

      </div>
    </div>
  </div>
</template>
 
<script>
const menuWidth = 230;
import areaTable from "./cardConfigTable/area.vue";
import cardTable from "./cardConfigTable/card.vue";
import addOrUpdateCard from './cardConfigTable/cardTableCom/drawerAddOrUpdateCard.vue'
export default {
  data() {
    return {
      navWidth: menuWidth,
      searchVal: "",
      menuIndex: 0,  // 0:选中的是全部（表格中是区域） 1:选中的是区域（表格中是卡台列表）
      menuList: [],
      showMenuList: false,
      searchMenu: {
        areaList: [],
        cardList: [],
      },

      activeMenuId: 0,

      showDrawer: false, // 是否显示搜索中的物料信息
      cardId: '', // 当前修改的seatId
    };
  },
  methods: {
    init() {
      this.menuIndex = this.$route.query.menuIndex || 0
      this.getMenuList();
    },

    // 获取完整的menu
    async getMenuList() {
      try {
        const res = await this.$api.BMS.region.requestRegionTree()
        const isSearch = !!this.$route.query.search
        const menuIndex = this.$route.query.menuIndex || 0
        const menuId = this.$route.query.menuId || 0
        if(res.code == 1) {
          this.menuList = (res.data || []).map(item => {
            const find = this.menuList.find(items => items.id == item.id)
            let originShowList = false  // 初始菜单打开状态
            let areaShowList = false  // 搜索菜单时的区域菜单打开状态

            // 初始菜单打开状态
            if(find) {
              originShowList = find && find.showList
            } 

            // 菜单搜索
            if (isSearch) {
              if(this.menuIndex == 1) {
                // 搜索一级菜单
                areaShowList = item.id == menuId
              }
            }
            
            return {
              ...item,
              menuIndex: 1,
              showList: originShowList || areaShowList
            }
          })
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("获取完整的二级菜单列表失败", error);
      }
    },

    showOrHideMenuListHandle() {
      this.$router.push({
        name: 'cardConfig'
      })
      this.showMenuList = !this.showMenuList;
    },

    // 菜单模糊查询列表
    async getSearchMenuData(keyword) {
      const params = {
        name: keyword || this.searchVal  //   string   模糊查询关键字
      };

      try {
        const res = await this.$api.BMS.region.requestRegionSearch(params);
        if(res.code == 1) {
          res.data = res.data || []
          this.searchMenu.areaList = res.data.filter(item => item.t == 1)
          this.searchMenu.cardList = res.data.filter(item => item.t == 2)
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
        this.searchMenuList = [];
      } else {
        this.getSearchMenuData(this.searchVal);
      }
    },

    // 从模糊查询中点击分类或商品
    getSearchDetail(itemInfo, type) {
      if(type == 'area') {
        const menuId = itemInfo.id
        this.$router.push('/BMS/cardConfig?menuIndex=1&menuId=' + menuId + '&search=true')
        this.searchVal = "";
        this.searchMenu.oneCateList = []
        this.searchMenu.twoCateList = []
        this.searchMenu.prdList = []
        this.showMenuList = true;
      } else {
        // 打开物料商品
        this.cardId = itemInfo.id
        this.showDrawer = true
      }
    },

    // 在搜索商品详情后点击删除
    initSearchValHandle(){
      this.searchVal = ''
      this.searchMenuList = []
    }
  },
  mounted() {
    this.init();
  },
  components: {
    areaTable,
    cardTable,
    addOrUpdateCard
  },
  watch: {
    $route() {
      this.activeMenuId = this.$route.query.menuId || 0;
    },
    "$route": {
      handler() {
        this.init();
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "./cardConfig.less";
</style>