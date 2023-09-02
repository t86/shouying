<template>
  <!-- 菜单子选项 -->
  <ul style="padding-left:14px;width:170px">
    <li class="item" v-for="(item,index) in menuList" :key="index">
      <div>
        <div
          class="menu-name pointer"
          :class="{'active': $route.query.menuId == item.id}"
          @click.stop="showOrHideListHandle(item)"
          layout="row"
          layout-align="start center"
        >
          <i
            v-if="item.subs"
            :class="{'rotate': item.showList}"
            class="el-icon-caret-right p-r-1"
          ></i>
          <i style="width:18px" v-else></i>
          <div class="menu-name-contain cursor" layout="row" layout-align="start center">
            <img src="@/assets/img/file_list.png" alt />
            <span class="name">{{item.n}}</span>
          </div>
        </div>
        <secondMenu v-if="item.showList" :menuList="item.subs" />
      </div>
    </li>
  </ul>
</template>
 
<script>
export default {
  data() {
    return {
      currentMenuId: "",
      menuListArr: []
    };
  },
  methods: {
    // 用户点击二级菜单
    clickSecondNavBarItemHandle(itemInfo) {
      this.$router.push({
        name: this.$route.name,
        query: { menuIndex: itemInfo.menuIndex , menuId: itemInfo.id}
      });
    },
    showOrHideListHandle(itemInfo) {
      this.currentMenuId = itemInfo.id;
      itemInfo.showList = !itemInfo.showList;
      this.clickSecondNavBarItemHandle(itemInfo);
      this.$forceUpdate();
    }
  },
  props: {
    menuList: {
      default: () => []
    }
  }
};
</script>

<style lang="less" scoped>
@color: #2170ff;

.item {
  width: 100%;
  .name {
    display: block;
    width: 100px;
    font-size: 14px;
    color: #40404e;
    line-height: 34px;
  }

  .menu-name {
    padding-left: 4px;
    &.active{
      background-color: #d7e9ff;
      border-radius: 6px;
    }
    &-contain {
      >img {
        width: 16px;
        height: 16px;
        margin-right: 10px;
      }
    }
    
    .rotate {
      transform: rotate(90deg);
    }

    .el-icon-caret-right:before{
      color: rgb(140, 140, 140);
    }
  }
}
</style>