<template>
  <div class="menu-list">
    <!-- 门店管理二级菜单 -->
    <div class="nav fs14">
      <!-- 二级菜单 -->
      <!-- <div class="nav-menu" :style="{ width: navWidth + 'px' }"> -->
        <!-- <div class="search">
          <i class="el-icon-search"></i>
          <el-input size="mini" clearable v-model="searchVal" placeholder="搜索" @input="inputSearchHandle" />
        </div>
        <div class="menu-list"> -->
          <!-- 完整分类菜单 -->
          <!-- <ul v-if="!searchVal" class="first-cate">
            <div
              class="pointer p-l-2"
              @click="showOrHideMenuListHandle"
            >
              <i
                :class="{ rotate: showMenuList }"
                style="color: #8c8c8c"
                class="el-icon-caret-right"
              ></i>
              <img src="@/assets/img/文件夹.png" alt />
              <span class="name">全部</span>
            </div>
            <secondEmployeeListNavBarItem v-if="showMenuList" :menuList="menuList" />
          </ul> -->
          <!-- 展示搜索结果的二级菜单 -->
          <!-- <div v-else class="search-list">
            <div v-if="searchMenu.groupList.length > 0" class="cate-list">
              <p>部门列表：</p>
              <ul>
                <li
                  v-for="(item, index) in searchMenu.groupList"
                  :key="index"
                  layout="row"
                  layout-align="start center"
                  @click.stop="getAreaDetail(item, 'group')"
                >
                  <img src="@/assets/img/文件夹.png" alt />
                  <span>{{ item.n }}</span>
                </li>
              </ul>
            </div>
            <div v-if="searchMenu.employeeList.length > 0" class="prd-list">
              <p>员工列表：</p>
              <ul>
                <li
                  v-for="(item, index) in searchMenu.employeeList"
                  :key="index"
                  layout="row"
                  layout-align="start center"
                  @click.stop="getAreaDetail(item, 'employee')"
                >
                  <img src="@/assets/img/商品列表.png" alt />
                  <span>{{ item.n }}</span>
                </li>
              </ul>
            </div>
            <div
              v-if="
                searchMenu.groupList.length == 0 &&
                searchMenu.employeeList.length == 0
              "
              class="no-data m-t-4"
              style="text-align: center"
            >
              <img style="width: 60px" src="@/assets/img/wu.png" alt />
              <div class="fs12 m-t-2">暂无查找内容</div>
            </div>
          </div> -->
        <!-- </div> -->
      <!-- </div> -->
      <!-- 菜单对应内容 -->
      <!-- <div class="nav-content" :style="{ 'margin-left': navWidth + 10 + 'px' }"> -->
        <cutPrdTableCom />
      <!-- </div> -->
    </div>
  </div>
</template>
 
<script>
const menuWidth = 230;
import cutPrdTableCom from "./cutPrdTableCom/cutPrdTable.vue";
export default {
  data() {
    return {
      navWidth: menuWidth,
      searchVal: "",
      menuList: [],
      showMenuList: false,
      searchMenu: {
        groupList: [],
        employeeList: [],
        employeeId: ""
      },

      activeMenuId: 0
    };
  },
  methods: {
    init() {
      this.getMenuList();
    },

    // 获取完整的二级菜单列表
    async getMenuList() {
      if (this.menuList.length > 0) return;
      try {
        const res = await this.$api.BMS.dept.requestDeptTree();
        if(res.code == 1) {
          this.menuList = res.data || [];
          this.$router.replace({
            name: "cutPrd",
            query: {
              menuId: this.menuList.length == 0 ? 0 : this.menuList[0].id
            }
          });
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("获取完整的二级菜单列表失败", error);
      }
    },

    showOrHideMenuListHandle() {
      this.showMenuList = !this.showMenuList;
    },

    // 二级菜单模糊查询列表
    async getSearchMenuData(keyword) {
      keyword = keyword || this.searchVal;
      const params = {
        name: keyword //   string   模糊查询关键字
      };

      try {
        const res = await this.$api.BMS.dept.requestDeptSearch(params);
        if(res.code == 1) {
          res.data = res.data || [];
          this.searchMenu.groupList = res.data.filter(
            item => item.t == 1
          );
          this.searchMenu.employeeList = []
        } else {
          this.$message.warning(res.msg)
        }

      } catch (error) {
        console.log("模糊查询二级菜单列表失败", error);
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

    // 从模糊查询中点击分类
    getAreaDetail(itemInfo, type) {
      const menuId = type == "group" ? itemInfo.id : itemInfo.p;
      this.searchMenu.employeeId = type == "group" ? "" : itemInfo.id;
      this.searchVal = "";
      this.searchMenu.groupList = [];
      this.searchMenu.employeeList = [];
      this.activeMenuId = menuId;
      this.showMenuList = true;
      this.$router.replace({
        name: "cutPrd",
        query: {
          menuId: menuId
        }
      });

      this.setMenuShowListStatus(this.menuList, menuId);
    },

    // 递归处理模糊搜索完之后的菜单展开状态
    setMenuShowListStatus(menuList, menuId) {
      menuList.forEach(el => {
        el.showList = el.id == menuId;
        if (!el.showList) {
          el.subs && this.setMenuShowListStatus(el.subs, menuId);
        } else {
          if (el.pid != 0) {
            this.setMenuShowListStatus(this.menuList, el.pid);
          }
        }
      });
    }
  },
  mounted() {
    this.init();
  },
  components: {
    cutPrdTableCom
  },
  watch: {
  }
};
</script>

<style scoped lang="less">
@import "./menuList.less";
</style>