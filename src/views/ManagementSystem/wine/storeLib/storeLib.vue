<template>
  <!-- 充公库 -->
  <div class="store-lib">
    <div class="top" layout="row" layout-align="start center">
      <el-input
        v-model="keyword"
        style="width:200px"
        class="m-r-2"
        size="small"
        placeholder="商品名称"
      ></el-input>
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button size="small" @click="resetHandle">重置</el-button>
    </div>
    <div class="btn-area m-t-4">
      <el-button type="primary" size="small" @click="getStoreWineHandle">充公出库</el-button>
    </div>

    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th" layout="row" layout-align="start center">
              <div style="width: 60px;text-align:left">
                <el-checkbox
                  :indeterminate="isIndeterminate"
                  v-model="checkAll"
                  @change="changeCheckboxHandle('all')"
                >全选</el-checkbox>
              </div>
            </div>
            <div class="th">商品名称</div>
            <div class="th">规格</div>
            <div class="th">库存数量</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            :class="{'selected': item.checked}"
            layout="row"
            layout-align="space-between center"
            v-for="(item, index) in tableData"
            :key="item.id"
          >
            <div class="td" layout="row" layout-align="start center">
              <div style="width: 60px;text-align:left">
                <el-checkbox
                  v-model="item.checked"
                  @change="changeCheckboxHandle('item')"
                >{{index + 1}}</el-checkbox>
              </div>
            </div>
            <div class="td">{{item.n}}</div>
            <div class="td">{{item.u}}</div>
            <div class="td">{{item.c}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>

    <!-- 充公出库 -->
    <drawerGetLib v-model="showDrawer" :currentInfoList="currentInfoList" :storeList="storeList" @getTableData="getTableData" />

  </div>
</template>
 
<script>
import { keyHandle } from "@/mixin/keyhandle";
import api_wine from "@/api/wine";
import drawerGetLib from "./drawerGetLib.vue";
export default {
  data() {
    return {
      keyword: "",
      checkAll: false,
      tableData: [],

      storeList: [], // 仓库列表

      showDrawer: false,
      currentInfoList: [] // 当前选择的商品列表
    };
  },
  methods: {
    async getTableData() {
      const params = {
        key: this.keyword //   string   搜索关键字
      };

      try {
        const res = await api_wine.reqGetStoreLibList(params);
        if (res.code == 1) {
          this.tableData = (res.data.records || []).map(item => ({
            ...item,
            checked: false
          }));

          this.storeList = res.data.stores || []

          this.checkAll = false;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("用户列表数据获取失败", error);
      }
    },

    changeCheckboxHandle(type) {
      switch (type) {
        case "all":
          this.tableData.forEach(el => {
            el.checked = this.checkAll;
          });
          break;
        case "item":
          this.checkAll = this.tableData.every(item => item.checked);
          break;
      }
    },

    // 充公出库
    getStoreWineHandle() {
      const currentInfoList = this.tableData.filter(item => item.checked);
      if (currentInfoList.length <= 0)
        return this.$message.warning("请选择需要出库的商品");
      this.showDrawer = true;
      this.currentInfoList = currentInfoList;
    },

    resetHandle() {
      this.keyword = "";
      this.getTableData();
    }
  },
  created() {
    this.resetHandle();
  },
  components: {
    drawerGetLib
  },
  mixins: [keyHandle],
  computed: {
    isIndeterminate() {
      return !this.checkAll && this.tableData.some(item => item.checked);
    }
  }
};
</script>

<style lang="less" scoped>
@import "../../../../style/wine/table.less";
</style>
<style scoped lang="less">
.store-lib{
  padding: 20px;

  .table {
    .tbody {
      height: calc(100vh - 250px);
      overflow: auto;
    }
  }
}
</style>