<template>
    <div class="wine-info">
        <div class="top" layout="row" layout-align="start center">
        <characters-button @click.native="showCatDrawerHandle" colors="transparent" wz='新增商品'></characters-button>
        <characters-button @click.native="deleteHandle" colors="transparent" wz='批量删除'></characters-button>
        <characters-button @click.native="showDrawerOfPassTime" colors="transparent" wz='批量更改存酒分类'></characters-button>
      </div>

        <!-- table -->
        
        <div class="table-content">
        <div class="table">
            <div class="thead">
            <div class="tr" layout="row" layout-align="start center">
                <div class="th">
                <el-checkbox
                    v-model="checked"
                    :indeterminate="indeterminate"
                    @change="changeCheckboxHandle('all')"
                >序号</el-checkbox>
                </div>
                <div class="th">商品名称</div>
                <div class="th">一级分类</div>
                <div class="th">二级分类</div>
            </div>
            </div>
            <div class="tbody">
            <div
                class="tr"
                :class="{'selected': item.checked}"
                v-for="(item,index) in tableData"
                :key="index"
                layout="row"
                layout-align="start center"
            >
                <div class="td">
                <el-checkbox v-model="item.checked" @change="changeCheckboxHandle('item')">{{index+1}}</el-checkbox>
                </div>
                <div class="td">{{item.n}}</div>
                <div class="td">{{item.on}}</div>
                <div class="td">{{item.tn}}</div>
            </div>
            <div class="no-data" v-if="tableData.length==0">
                <img src="@/assets/img/wu.png" alt />
                <p>暂无数据</p>
            </div>
            </div>
          </div>
        </div>
        <drawerAddWine
        :showDrawer="showCatDrawer"
        @showDrawerHandle="showCatDrawerHandle"
        @getTableData="getTableData"
        />
        <drawerPassTime
        :showDrawer="showPassTimeDrawer"
        :ids="ids"
        @showDrawerHandle="showDrawerOfPassTime"
        @getTableData="getTableData"
        />
    </div>
  </template>
   
  <script>
  const menuWidth = 230;
  import IconButton from "@/components/IconButton.vue";
  import CharactersButton from '@/components/CharactersButton.vue'
  import drawerAddWine from "./drawerAddWineCom/drawerAddWineCom.vue";
  import drawerPassTime from "./drawerAddWineCom/drawerPassTimeCom.vue";
  export default {
    data() {
      return {
        checked: false,
        indeterminate: false,
        catTableData: [],
        tableData: [],
        showCatDrawer: false,
        showDrawer: false,
        showPassTimeDrawer: false,
        dataInfo: {},
        defaultProps: {
          children: 'children',
          label: 'label'
        }
      };
    },
    methods: {
      async getTableData() {
        console.log(this.$route.query.menuId)
        try {
          const res = await this.$api.BMS.saveWine.reqGetWineList({
            wine_cate_id: this.$route.query.menuId * 1 || 0,
          });
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
    created() {
      this.getTableData()
    },
    components: {
      IconButton,
      CharactersButton,
      drawerAddWine,
      drawerPassTime
    },
    computed: {
      ids(){
        return this.tableData.filter(item => item.checked).map(item => item.id * 1)
      }
    },
    watch: {
    '$route': {
      handler() {
        this.getTableData()
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