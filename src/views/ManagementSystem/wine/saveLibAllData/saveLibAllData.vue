<template>
  <!-- 存酒库库存 -->
  <div class="save-lib-all-data">
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
      <el-button size="primary" @click="exportExcelHandle">导出</el-button>
    </div>
    <div class="table-content m-t-3">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">商品名称</div>
            <div class="th">整瓶</div>
            <div class="th">0.1</div>
            <div class="th">0.2</div>
            <div class="th">0.3</div>
            <div class="th">0.4</div>
            <div class="th">0.5</div>
            <div class="th">0.6</div>
            <div class="th">0.7</div>
            <div class="th">0.8</div>
            <div class="th">0.9</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" layout="row" layout-align="space-between center" v-for="item in tableData" :key="item.id">
            <div class="td one-txt-cut">{{item.p}}</div>
            <div class="td"><span class="link" @click="showDrawerHandle(item, item.p10, '1')">{{item.p10 || ''}}</span></div>
            <div class="td"><span class="link" @click="showDrawerHandle(item, item.p1, '0.1')">{{item.p1 || ''}}</span></div>
            <div class="td"><span class="link" @click="showDrawerHandle(item, item.p2, '0.2')">{{item.p2 || ''}}</span></div>
            <div class="td"><span class="link" @click="showDrawerHandle(item, item.p3, '0.3')">{{item.p3 || ''}}</span></div>
            <div class="td"><span class="link" @click="showDrawerHandle(item, item.p4, '0.4')">{{item.p4 || ''}}</span></div>
            <div class="td"><span class="link" @click="showDrawerHandle(item, item.p5, '0.5')">{{item.p5 || ''}}</span></div>
            <div class="td"><span class="link" @click="showDrawerHandle(item, item.p6, '0.6')">{{item.p6 || ''}}</span></div>
            <div class="td"><span class="link" @click="showDrawerHandle(item, item.p7, '0.7')">{{item.p7 || ''}}</span></div>
            <div class="td"><span class="link" @click="showDrawerHandle(item, item.p8, '0.8')">{{item.p8 || ''}}</span></div>
            <div class="td"><span class="link" @click="showDrawerHandle(item, item.p9, '0.9')">{{item.p9 || ''}}</span></div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img src="@/assets/img/wu.png" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>
    <drawerShowAllData v-model="showDrawer" :currentInfo="currentInfo" />
  </div>
</template>
 
<script>
import { keyHandle } from "../../../../mixin/keyhandle";
import api_wine from "@/api/wine";
import drawerShowAllData from './drawerShowAllData.vue'
export default {
  data() {
    return {
      keyword: '',
      tableData: [],
      currentInfo: {},
      showDrawer: false
    };
  },
  methods: {
    async getTableData(){
      const params = {
        key: this.keyword || ''  //  string   商品名称关键字
      }
      try {
        const res = await api_wine.reqGetSaveLibGrid(params)
        if(res.code == 1) {
          this.tableData = res.data.records || []
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取存酒库库存数据失败', error)
      }
    },

    showDrawerHandle(itemInfo, count, g){
      if(count <= 0) return
      this.currentInfo = {
        n: itemInfo.p,
        id: itemInfo.id,
        g
      }
      this.showDrawer = true
    },

    async exportExcelHandle(){
      const params = {
        key: ''  //  string   商品名称关键字  当前导出为全部，不用做筛选
      }
      try {
        const res = await api_wine.reqExportExcelOfGridReport(params);
        if (!res.msg) {
          const url = window.URL.createObjectURL(
            new Blob([res], {
              type:
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            })
          );
          const a = document.createElement("a"); //添加a标签
          document.body.appendChild(a);
          a.href = url;
          a.setAttribute("download", decodeURIComponent(res.fileName)); // 下载文件的名称及文件类型后缀
          a.click(); //点击标签
          document.body.removeChild(a); // 下载完成移除元素
          window.URL.revokeObjectURL(url); // 释放掉blob对象
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("导出excel失败", error);
      }
    },

    resetHandle(){
      this.keyword = ''
      this.getTableData()
    }
  },
  created() {
    this.resetHandle()
  },
  mixins: [keyHandle],
  components: {
    drawerShowAllData
  },
};
</script>

<style lang="less" scoped>
@import "../../../../style/wine/table.less";
</style>
<style scoped lang="less">
.save-lib-all-data {
  padding: 20px;
  .table-content {
    .table {
      .thead .th {
        font-size: 15px;
      }
      .tbody {
        height: calc(100vh - 200px);
        overflow-y: auto;
      }
      .th,.td{

        &:nth-child(1){
          width: 70%;
        }

        .link {
          color: #2170ff;
          cursor: pointer;
        }
      }
    }
  }
}
</style>