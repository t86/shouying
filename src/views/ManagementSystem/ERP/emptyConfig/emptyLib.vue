<template>
  <div class="empty-lib">
    <div class="top" layout="row" layout-align="start center">
      <el-input v-model="keyword" size="small" placeholder="请输入商品名称" style="width: 200px;margin-right:10px"></el-input>
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button type="primary" size="small" @click="resetHandle">重置</el-button>
    </div>

    <div class="button m-t-3 m-b-3">
      <el-button type="primary" size="small" @click="showDrawerHandle">批量出库</el-button>
    </div>

    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">
              <el-checkbox
                v-model="checkAll"
                :indeterminate="isIndeterminate"
                @change="changeCheckboxHandle('all')"
              >全选</el-checkbox>
            </div>
            <div class="th">空瓶名称</div>
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
              <el-checkbox
                v-model="item.checked"
                @change="changeCheckboxHandle('item')"
              >{{index + 1}}</el-checkbox>
            </div>
            <div class="td">{{item.n}}</div>
            <div class="td">{{item.c}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
        <!-- 批量出库 -->
        <drawerManyOutLib v-model="showDrawer" :currentList="currentList" @getTableData="getTableData" />
      </div>
      <div class="pagination">
        <el-pagination
          background
          layout="prev, pager, next"
          :total="pageInfo.total"
          :page-size="pageInfo.pageSize"
          :current-page="pageInfo.page"
          @current-change="changePageHandle"
        ></el-pagination>
      </div>
    </div>
  </div>
</template>
 
<script>
// 批量出库
import drawerManyOutLib from './emptyLibCom/drawerManyOutLib.vue'
  export default {
    data() {
      return {
        checkAll: false,
        keyword: '',
        tableData: [],
        currentList: [],  // 当前选中的列表
        showDrawer: false,
        
        pageInfo: {
          page: 1,
          pageSize: 20,
          total: 0
        }
      }
    },
    methods: {
      async getTableData() {
        const params = {
          page_num: this.pageInfo.page * 1, //   int  指定第几页
          page_size: this.pageInfo.pageSize, //  int  每页行数
          key: this.keyword //  string   商品名称关键字
        };

        try {
          const res = await this.$api.ERP.emptyLib.getEmptyLibList(params);
          if (res.code == 1) {
            this.tableData = (res.data.records || []).map(item => ({
              ...item,
              checked: false
            }));
            this.checkAll = false;
            this.pageInfo.total = res.data.row_cnt || 0;
          } else {
            this.$message.warning(res.msg);
          }
        } catch (error) {
          console.log("空瓶仓列表获取失败", error);
        }
      },

      changeCheckboxHandle(type) {
        switch (type) {
          case "all":
            this.tableData = this.tableData.map(item => ({
              ...item,
              checked: this.checkAll
            }));
            break;
          case "item":
            this.checkAll = this.tableData.every(item => item.checked);
            break;
        }
      },

      showDrawerHandle(){
        this.currentList = this.tableData.filter(item => item.checked)
        if(this.currentList.length <= 0) return this.$message.warning('请选择需要出库的订单')
        this.showDrawer = true
      },

      changePageHandle(page) {
        this.pageInfo.page = page;
        this.getTableData();
      },

      resetHandle() {
        this.keyword = ''
        this.pageInfo.page = 1
        this.getTableData()
      }
 
    },
    created() {
      this.resetHandle();
    },
    components: {
      drawerManyOutLib
    },
    computed: {
      isIndeterminate() {
        return !this.checkAll && this.tableData.some(item => item.checked);
      }
    },
  }
 
</script>

<style lang="less" scoped>
@import "../../../../style/erp/table.less";
</style>
<style scoped lang="less">
.empty-lib {
  padding: 20px;
  .table {
    .tbody {
      height: calc(100vh - 270px);
      overflow: auto;

      .primary {
        color: #2170ff;
        cursor: pointer;
      }
    }
  }
}

</style>