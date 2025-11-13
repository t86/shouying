<template>
  <!-- 日实时库存 -->
  <div class="now-invt-report">
    <div class="top" layout="row" layout-align="start center">
      <el-input
        v-model="keyword"
        style="width:200px"
        class="m-r-2"
        size="small"
        placeholder="输入酒水名称"
      ></el-input>
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button size="small" @click="resetHandle">重置</el-button>
      <el-button type="primary" size="small" @click="exportExcelHandle">导出</el-button>
    </div>

    <div class="update-time m-t-2" v-if="updateTime">
      数据更新时间: {{ updateTime }}
    </div>

    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="center center">
            <div class="th">序号</div>
            <div class="th">酒水名称</div>
            <div class="th">规格</div>
            <div class="th">昨日库存</div>
            <div class="th">今日存酒</div>
            <div class="th">今日取酒</div>
            <div class="th">今日充公</div>
            <div class="th">今日借酒</div>
            <div class="th">今日还酒</div>
            <div class="th">今日库存</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" v-for="(item, index) in tableData" :key="index" layout="row" layout-align="space-between center">
            <div class="td">{{ index + 1 }}</div>
            <div class="td one-txt-cut">{{ item.n || '-' }}</div>
            <div class="td">{{ item.u || '-' }}</div>
            <div class="td">{{ item.b || 0 }}</div>
            <div class="td">{{ item.c || 0 }}</div>
            <div class="td">{{ item.q || 0 }}</div>
            <div class="td">{{ item.g || 0 }}</div>
            <div class="td">{{ item.br || 0 }}</div>
            <div class="td">{{ item.r || 0 }}</div>
            <div class="td">{{ item.a || 0 }}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img src="@/assets/img/wu.png" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>

  </div>
</template>
 
<script>
import { keyHandle } from "../../../../mixin/keyhandle";
import api_wine from "@/api/wine";
export default {
  data() {
    return {
      keyword: "",
      tableData: [],
      updateTime: ""
    };
  },
  methods: {
    async getTableData() {
      // 根据接口文档，需要传入records数组
      // 如果接口支持搜索关键字，可以添加key参数
      const params = {
        records: [] // 根据接口文档要求传入records数组
      };
      
      // 如果接口支持搜索关键字过滤，可以添加key参数
      if (this.keyword) {
        params.key = this.keyword;
      }

      try {
        const res = await api_wine.reqGetWineNowInvtList(params);
        if (res.code == 1) {
          let data = res.data.records || [];
          
          // 如果前端需要根据关键字过滤，可以在这里处理
          if (this.keyword && data.length > 0) {
            const keyword = this.keyword.toLowerCase();
            data = data.filter(item => {
              const name = (item.n || '').toLowerCase();
              return name.includes(keyword);
            });
          }
          
          this.tableData = data;
          
          // 设置更新时间
          const now = new Date();
          const year = now.getFullYear();
          const month = String(now.getMonth() + 1).padStart(2, '0');
          const day = String(now.getDate()).padStart(2, '0');
          const hour = String(now.getHours()).padStart(2, '0');
          const minute = String(now.getMinutes()).padStart(2, '0');
          this.updateTime = `${year}-${month}-${day} ${hour}:${minute}`;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("日实时库存数据获取失败", error);
      }
    },

    async exportExcelHandle(){
      // 导出接口根据文档不需要参数
      const params = {};
      try {
        const res = await api_wine.reqExportWineNowInvtList(params);
        if (!res.msg) {
          const url = window.URL.createObjectURL(
            new Blob([res], {
              type:
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            })
          );
          const a = document.createElement("a");
          document.body.appendChild(a);
          a.href = url;
          a.setAttribute("download", decodeURIComponent(res.fileName || "日实时库存报表.xlsx"));
          a.click();
          document.body.removeChild(a);
          window.URL.revokeObjectURL(url);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("导出excel失败", error);
      }
    },

    resetHandle() {
      this.keyword = "";
      this.getTableData();
    }
  },
  created() {
    this.getTableData();
  },
  mixins: [keyHandle]
};
</script>

<style scoped lang="less">
.now-invt-report {
  padding: 20px;

  .update-time {
    font-size: 14px;
    color: #666;
  }

  .table-content {
    position: relative;
    width: 100%;
    height: calc(100vh - 180px);
    overflow: auto;
    
    .table {
      .thead {
        position: sticky;
        top: 0;
        z-index: 10;
        background-color: #eee;
        
        .th {
          font-size: 15px;
          font-weight: 600;
          padding: 12px 10px;
          white-space: nowrap;
        }
      }
      
      .tbody {
        .tr {
          min-height: 44px;
          font-size: 14px;
          
          &:nth-child(2n) {
            background-color: #f5f5f5;
          }
          
          &:hover {
            background-color: #d7e9ff !important;
            .td {
              background-color: #d7e9ff !important;
            }
          }
        }
        
        .td {
          padding: 12px 10px;
          text-align: center;
          white-space: nowrap;
        }
      }
      
      .tr {
        display: flex;
        
        .th, .td {
          flex: 1;
          min-width: 0;
          
          &:nth-child(1) {
            flex: 0 0 60px; // 序号
            padding-left: 15px;
          }
          
          &:nth-child(2) {
            flex: 1.5; // 酒水名称
            text-align: left;
            padding-left: 15px;
          }
          
          &:nth-child(3) {
            flex: 0.8; // 规格
          }
          
          &:nth-child(4),
          &:nth-child(5),
          &:nth-child(6),
          &:nth-child(7),
          &:nth-child(8),
          &:nth-child(9),
          &:nth-child(10) {
            flex: 1; // 其他列
          }
        }
      }
    }
    
    .no-data {
      text-align: center;
      padding: 80px 0;
      
      img {
        width: 60px;
      }
      
      p {
        margin-top: 10px;
        font-size: 14px;
        color: #999;
      }
    }
  }

  .formula-tip {
    display: flex;
    justify-content: flex-end;
    
    .formula-box {
      background-color: #fff3cd;
      border: 1px solid #ffc107;
      border-radius: 6px;
      padding: 12px 20px;
      font-size: 14px;
      color: #856404;
      font-weight: 500;
    }
  }
}

.one-txt-cut {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

@media (orientation: portrait) {
  .now-invt-report {
    padding: 15px;
    
    .table-content {
      height: calc(100vh - 250px);
      
      .table {
        .thead .th,
        .tbody .td {
          font-size: 12px;
          padding: 10px 6px;
        }
      }
    }
  }
}

@media (max-width: 900px) {
  .now-invt-report {
    padding: 15px;
    
    .table-content {
      .table {
        .thead .th,
        .tbody .td {
          font-size: 12px;
          padding: 8px 4px;
        }
      }
    }
  }
}
</style>

<style>
/* 日期选择器 */
.el-date-picker__header-label {
  color: #1a1a21;
}
.el-date-table th,
.el-picker-panel__content {
  color: #1a1a21;
}
.el-range-editor--small .el-range-input {
  background-color: transparent;
}
</style>

