<template>
  <div class="menu-list">
    <div class="nav">
      <!-- 二级菜单 -->
      <div class="nav-menu" :style="{ width: navWidth + 'px' }">
        <div class="search">
          <i class="el-icon-search"></i>
          <el-input
            size="mini"
            clearable
            v-model="searchVal"
            placeholder="搜索"
            @input="inputSearchHandle"
          />
        </div>
        <div class="menu-list">
          <!-- 完整分类菜单 -->
          <ul v-if="!searchVal" class="first-cate">
            <div class="pointer p-l-2" @click="showOrHideMenuListHandle">
              <i
                :class="{ rotate: showMenuList }"
                style="color: #8c8c8c"
                class="el-icon-caret-right"
              ></i>
              <img :src="require('@/assets/img/file_list.png')" alt />
              <span class="name">全部</span>
            </div>
            <secondBmsMenu v-if="showMenuList" :menuList="menuList" />
          </ul>
          <!-- 展示搜索结果的二级菜单 -->
          <div v-else class="search-list">
            <div v-if="searchMenu.oneCateList.length > 0" class="cate-list">
              <p>一级分类：</p>
              <ul>
                <li
                  v-for="(item, index) in searchMenu.oneCateList"
                  :key="index"
                  layout="row"
                  layout-align="start center"
                  @click.stop="getSearchDetail(item, 'oneCate')"
                >
                  <img :src="require('@/assets/img/file_list.png')" alt />
                  <span>{{ item.n }}</span>
                </li>
              </ul>
            </div>
            <div v-if="searchMenu.twoCateList.length > 0" class="cate-list">
              <p>二级分类：</p>
              <ul>
                <li
                  v-for="(item, index) in searchMenu.twoCateList"
                  :key="index"
                  layout="row"
                  layout-align="start center"
                  @click.stop="getSearchDetail(item, 'twoCate')"
                >
                  <img :src="require('@/assets/img/file_list.png')" alt />
                  <span>{{ item.n }}</span>
                </li>
              </ul>
            </div>
            <div v-if="searchMenu.prdList.length > 0" class="prd-list">
              <p>商品列表：</p>
              <ul>
                <li
                  v-for="(item, index) in searchMenu.prdList"
                  :key="index"
                  layout="row"
                  layout-align="start center"
                  @click.stop="getSearchDetail(item, 'prd')"
                >
                  <img :src="require('@/assets/img/commodity_list.png')" alt />
                  <span>{{ item.n }}</span>
                </li>
              </ul>
            </div>
            <div
              v-if="
                searchMenu.oneCateList.length == 0 &&
                searchMenu.twoCateList.length == 0 &&
                searchMenu.prdList.length == 0
              "
              class="no-data m-t-4"
              style="text-align: center"
            >
              <img
                style="width: 60px"
                :src="require('@/assets/img/wu.png')"
                alt
              />
              <div class="fs12 m-t-2">暂无查找内容</div>
            </div>
          </div>
        </div>
      </div>
      <!-- 菜单对应内容 -->
      <div class="nav-content" :style="{ 'margin-left': navWidth + 10 + 'px' }">
        <oneCateTable
          v-if="menuIndex == 0"
          ref="oneCateTable"
          @getMenuList="getMenuList"
        />
        <twoCateTable
          v-if="menuIndex == 1"
          ref="twoCateTable"
          :menuList="menuList"
          @getMenuList="getMenuList"
        />
        <prdTable
          v-if="menuIndex == 2"
          ref="prdTable"
          :menuList="menuList"
          @getMenuList="getMenuList"
        />
        <!-- 新增或编辑单品 -->
        <addOrUpdatePrd
          v-model="showDrawer"
          :currentInfo="{ id: prdId }"
          type="2"
          :search="true"
          @initSearchValHandle="initSearchValHandle"
        />
        <!-- 新增或编辑套餐 -->
        <addOrUpdateGroupPrd
          v-model="showGroupDrawer"
          :currentInfo="{ id: prdId }"
          :type="2"
          :search="true"
          @initSearchValHandle="initSearchValHandle"
        />
      </div>
    </div>
  </div>
</template>

<script>
const menuWidth = 230;
import oneCateTable from "./prdConfigTable/oneCateTable.vue";
import twoCateTable from "./prdConfigTable/twoCateTable.vue";
import prdTable from "./prdConfigTable/prdTable.vue";
import addOrUpdatePrd from "./prdConfigTable/prdTableCom/drawerAddOrUpdatePrd.vue";
import addOrUpdateGroupPrd from "./prdConfigTable/prdTableCom/drawerAddOrUpdateGroupPrd.vue";
export default {
  data() {
    return {
      navWidth: menuWidth,
      searchVal: "",
      menuIndex: 0, // 0:选中的是全部（表格中是一级分类） 1:选中的是一级分类（表格中是二级分类） 2:选中的是二级分类（表格中是商品列表）
      menuList: [],
      showMenuList: false,
      searchMenu: {
        oneCateList: [],
        twoCateList: [],
        prdList: [],
        prdId: "",
      },

      activeMenuId: 0,

      showDrawer: false, // 是否显示搜索中的单品信息
      showGroupDrawer: false, // 是否显示搜索中的套餐信息
      prdId: "", // 当前修改的商品id(用于编辑中，删除商品)
    };
  },
  methods: {
    init() {
      this.menuIndex = this.$route.query.menuIndex || 0;
      this.getMenuList();
    },

    // 获取完整的二级菜单列表
    async getMenuList() {
      try {
        const res = await this.$api.BMS.Prd.requestprdcatetree();
        const isSearch = !!this.$route.query.search;
        const menuIndex = this.$route.query.menuIndex || 0;
        const menuId = this.$route.query.menuId || 0;
        if (res.code == 1) {
          this.menuList = (res.data || []).map((item) => {
            const find = this.menuList.find((items) => items.id == item.id);
            let originShowList = false; // 初始菜单打开状态
            let oneCateShowList = false; // 搜索菜单时的一级菜单打开状态
            let twoCateShowList = false; // 搜索菜单时的二级菜单打开状态

            // 初始菜单打开状态
            if (find) {
              originShowList = find && find.showList;
            }

            // 菜单搜索
            if (isSearch) {
              if (this.menuIndex == 1) {
                // 搜索一级菜单
                oneCateShowList = item.id == menuId;
              } else if (this.menuIndex == 2) {
                // 搜索二级菜单
                const findTwoCate = item.subs.find(
                  (items) => items.id == menuId
                );
                if (findTwoCate) twoCateShowList = true;
              }
            }

            return {
              ...item,
              menuIndex: 1,
              showList: originShowList || oneCateShowList || twoCateShowList,
              subs: (item.subs || []).map((items) => ({
                ...items,
                menuIndex: 2,
              })),
            };
          });
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取完整的二级菜单列表失败", error);
      }
    },

    showOrHideMenuListHandle() {
      this.$router.push({
        name: "prdConfig",
      });
      this.showMenuList = !this.showMenuList;
    },

    // 菜单模糊查询列表
    async getSearchMenuData(keyword) {
      const params = {
        name: keyword || this.searchVal, //   string   模糊查询关键字
      };

      try {
        const res = await this.$api.BMS.Prd.requestprdcatesearch(params);
        if (res.code == 1) {
          res.data = res.data || [];
          this.searchMenu.oneCateList = res.data.filter((item) => item.t == 1);
          this.searchMenu.twoCateList = res.data.filter((item) => item.t == 2);
          this.searchMenu.prdList = res.data.filter(
            (item) => item.t == 3 || item.t == 4
          );
          this.searchMenu.prdId = "";
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("模糊查询失败", error);
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
      if (type == "oneCate" || type == "twoCate") {
        const menuIndex = type == "oneCate" ? "1" : "2";
        const menuId = itemInfo.id;
        this.$router.push(
          "/BMS/prdConfig?menuIndex=" +
            menuIndex +
            "&menuId=" +
            menuId +
            "&search=true"
        );
        this.searchVal = "";
        this.searchMenu.oneCateList = [];
        this.searchMenu.twoCateList = [];
        this.searchMenu.prdList = [];
        this.showMenuList = true;
      } else {
        this.$router.push(
          "/BMS/prdConfig?prd=" +
            itemInfo.id +
            "&search=true"
        );
        // 打开物料商品
        this.prdId = itemInfo.id;
        if (itemInfo.t == 3) {
          // 单品
          this.showDrawer = true;
        } else {
          // 套餐
          this.showGroupDrawer = true;
        }
      }
    },

    // 在搜索商品详情后点击删除
    initSearchValHandle() {
      this.searchVal = "";
      this.searchMenuList = [];
      if (!this.$route.query.menuIndex) {
        // 目前页面停留在一级菜单，更新一级菜单中显示的所有商品
        this.$refs.oneCateTable.getPrdTableData();
      } else if (this.$route.query.menuIndex == 2) {
        // 目前页面停留在商品列表，需要更新商品列表
        this.$refs.prdTable.getTableData();
      }
    },
  },
  mounted() {
    this.init();
  },
  props: {
    year: {
      default: "",
    },
    month: {
      default: "",
    },
  },
  components: {
    oneCateTable,
    twoCateTable,
    prdTable,
    addOrUpdatePrd,
    addOrUpdateGroupPrd,
  },
  watch: {
    $route() {
      this.activeMenuId = this.$route.query.menuId || 0;
    },
    $route: {
      handler() {
        this.init();
      },
    },
  },
};
</script>

<style scoped lang="less">
@import "./prdConfig.less";
</style>
