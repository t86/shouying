<template>
  <div class="container">
    <div class="nav-menu">
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
          <wineMenu v-if="showMenuList" :menuList="menuList" />
        </ul>
        <!-- 展示搜索结果的二级菜单 -->
        <div v-else class="search-list">
          <div v-if="searchMenu.wineCatList.length > 0" class="cate-list">
            <p>一级分类：</p>
            <ul>
              <li
                v-for="(item, index) in searchMenu.wineCatList"
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
          <div v-if="searchMenu.wineList.length > 0" class="cate-list">
            <p>二级分类：</p>
            <ul>
              <li
                v-for="(item, index) in searchMenu.wineList"
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
          <div v-if="searchMenu.wineList.length > 0" class="prd-list">
            <p>商品列表：</p>
            <ul>
              <li
                v-for="(item, index) in searchMenu.wineList"
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
              searchMenu.wineCatList.length == 0 &&
              searchMenu.wineList.length == 0
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
    <div class="nav-content">
        <wineCat v-if="menuIndex == 0" @getMenuList="getMenuList"/>
        <saveWine v-if="menuIndex == 1" :menuList="menuList"/>
      </div>
  </div>
  
</template>
 
<script>
const menuWidth = 230;
import IconButton from "@/components/IconButton.vue";
import CharactersButton from '@/components/CharactersButton.vue'
import wineCat from "./wineCat.vue"
import saveWine from "./saveWine.vue"
export default {
  data() {
    return {
      searchVal: '',
      menuIndex: 0, // 0:选中的是全部（表格中是一级分类） 1:选中的是一级分类（表格中是二级分类） 2:选中的是二级分类（表格中是商品列表）
      menuList: [],
      showMenuList: true,
      searchMenu: {
        wineCatList: [],
        wineList: [],
      },
      activeMenuId: 0,
      checked: false,
      indeterminate: false,
      catTableData: [],
      tableData: [],
      showCatDrawer: false,
      showDrawer: false,
      showPassTimeDrawer: false,
      dataInfo: {},
      selCatInfo: {}
    };
  },
  mounted() {
    this.init();
  },
  methods: {
    init() {
      this.menuIndex = this.$route.query.menuIndex || 0
    },
    showOrHideMenuListHandle() {
      this.$router.push({
        name: "wineInfo",
      });
      this.showMenuList = !this.showMenuList;
    },
    
    // 菜单模糊查询列表
    async getSearchMenuData(keyword) {
      const params = {
        name: keyword || this.searchVal  //   string   模糊查询关键字
      };

      try {
        const res = await this.$api.BMS.saveWine.reqGetWineCateFmName(params);
        if(res.code == 1) {
          res.data = res.data || []
          this.searchMenu.wineCatList = res.data.records.filter(item => item.t == 1)
          this.searchMenu.wineList = res.data.records.filter(item => item.t == 2)
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("模糊查询列表失败", error);
      }
    },
     // 获取完整的二级菜单列表
     async getMenuList() {
      try {
        const res = await this.$api.BMS.saveWine.reqGetWineCateList();
        const isSearch = !!this.$route.query.search;
        const menuIndex = this.$route.query.menuIndex || 0;
        const menuId = this.$route.query.menuId || 0;
        if (res.code == 1) {
          this.menuList = (res.data.records || []).map((item) => {
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
          });
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取完整的二级菜单列表失败", error);
      }
    },
    // 从模糊查询中点击分类或商品
    getSearchDetail(itemInfo, type) {
        const menuIndex = "1";
        const menuId = itemInfo.id;
        this.$router.push(
          "/BMS/wineInfo?menuIndex=" +
            menuIndex +
            "&menuId=" +
            menuId +
            "&n=" + itemInfo.n +
            "&f=" + itemInfo.f +
            "&l=" + itemInfo.l +
            "&search=true"
        );
        this.searchVal = "";
        this.showMenuList = true;
    },
    // 模糊搜索
    inputSearchHandle() {
      if (this.searchVal == "") {
        this.searchMenuList = [];
      } else {
        this.getSearchMenuData(this.searchVal);
      }
    },
    async getTableData() {
      try {
        const res = await this.$api.BMS.saveWine.reqGetWineList();
        if (res.code == 1) {
          this.tableData = (res.data.records || []).map(item => ({
            ...item,
            checked: false
          }));
          this.indeterminate = this.checked = false;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("存酒列表数据获取失败", error);
      }
    },
    
    initSearchValHandle() {
      this.searchVal = "";
      this.searchMenuList = [];
    },
    changeCheckboxHandle(type) {
      switch (type) {
        case "all":
          this.tableData.forEach(el => {
            el.checked = this.checked;
          });
          this.indeterminate = false;
          break;
        case "item":
          this.checked = this.tableData.every(item => item.checked);
          this.indeterminate =
            !this.checked && this.tableData.some(item => item.checked);
          break;
      }
    },
    showCatDrawerHandle() {
      this.showCatDrawer = !this.showCatDrawer;
    },
    showDrawerHandle() {
      this.showDrawer = !this.showDrawer;
    },

    showDrawerOfPassTime(){
      if(!this.showPassTimeDrawer && this.ids.length == 0) return this.$message.warning('请选择商品')
      this.showPassTimeDrawer = !this.showPassTimeDrawer
    },

    async deleteHandle() {
      if (this.ids.length == 0) {
        return this.$message.warning("请选择需要删除的理由");
      }
      const params = {
        prd_ids: this.ids //   []int64  请求id数组
      };
      try {
        const res = await this.$api.BMS.saveWine.reqDelWine(params);
        if (res.code == 1) {
          this.$message.success("删除成功");
          this.getTableData();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("删除失败", error);
      }
    }
  },

  components: {
    IconButton,
    CharactersButton,
    wineCat,
    saveWine
  },
  computed: {
    ids(){
      return this.tableData.filter(item => item.checked).map(item => item.id * 1)
    }
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

<style lang="less" scoped>
@import "./wineInfo.less";
@import "../../../../../style/erp/table.less";

.container {
  display: grid;
  grid-template-columns: 200px 1fr;
  grid-gap: 10px;

  .nav-menu {
    padding: 10px;
    padding-right: 20px;
    box-sizing: border-box;
    height: calc(100vh - 90px);
    float: left;
    border-right: 1px solid #eee;

    // 搜索框
    .search {
      height: 40px;
      position: relative;
      text-align: center;

      i {
        position: absolute;
        top: 8px;
        left: 12px;
      }

      /deep/input.el-input__inner {
        width: 100%;
        height: 30px;
        border-radius: 4px;
        background-color: transparent;
        color: #40404e;
        outline: none;
        padding-left: 30px;
        padding-right: 10px;
        border: 1px solid rgb(217, 217, 217);
      }
    }

    // 二级菜单
    .menu-list {
      height: calc(100% - 40px);
      overflow-y: auto;

      >ul.first-cate{
        padding-left: 0!important;
        img{
          width: 16px;
          vertical-align: middle;
        }
        span.name{
          display: inline-block;
          vertical-align: middle;
          line-height: 34px;
          cursor: pointer;
        }
        ul.second-cate{
          li{
            cursor: pointer;
            line-height: 34px;
            padding-left: 30px;
            box-sizing: border-box;
          }
        }
      }

      .search-list {
        p {
          font-size: 13px;
          line-height: 30px;
        }

        li {
          cursor: pointer;
          padding-left: 20px;
          border-radius: 6px;
          line-height: 34px;

          &:hover {
            background-color: #d7e9ff;
          }

          img {
            width: 16px;
            margin-right: 10px;
          }
        }
      }
    }
  }
}
</style>