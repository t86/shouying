<template>
  <div>
    <el-drawer
        title="入客数据实时汇总表"
        :visible.sync="show"
        :before-close="closeDrawerHandle"
        direction="rtl"
        size="90%"
    >
      <div class="search white p-l-6 p-b-4" layout="row" layout-align="space-between center">
        <button class="export m-r-6" @click="exportExcelHandle">导出Excel</button>
      </div>

      <div class="table">
        <div class="content">
          <div class="thead">
            <div class="tr">
              <div class="th w150">部门/区域</div>
              <div class="th w120">20点(含前)</div>
              <div class="th w120">21点</div>
              <div class="th w120">22点</div>
              <div class="th w120">23点</div>
              <div class="th w120">0点</div>
              <div class="th w120">1点</div>
              <div class="th w120">2点</div>
              <div class="th w120">3点</div>
              <div class="th w120">4点</div>
              <div class="th w120">5点</div>
              <div class="th w120">6点(含后)</div>
            </div>
          </div>
          <div class="tbody" ref="scrollDom">
            <div
                v-if="tableData.length==0"
                style="text-align:center;transform:translateY(40px)"
            >暂无数据</div>
            <div v-else ref="scrollItem">
              <div class="coll" v-for="(item,i) in tableData" :key="i">
                <div class="detail tr">
                  <div class="td w150">{{item.n}}</div>
                  <div class="td w120">{{item.c20}}</div>
                  <div class="td w120">{{item.c21}}</div>
                  <div class="td w120">{{item.c22}}</div>
                  <div class="td w120">{{item.c23}}</div>
                  <div class="td w120">{{item.c00}}</div>
                  <div class="td w120">{{item.c01}}</div>
                  <div class="td w120">{{item.c02}}</div>
                  <div class="td w120">{{item.c03}}</div>
                  <div class="td w120">{{item.c04}}</div>
                  <div class="td w120">{{item.c05}}</div>
                  <div class="td w120">{{item.c06}}</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>


      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_book from "@/api/Book";

export default {
  data () {
    return {
      show: false,
      tableData: [],
    };
  },
  methods: {
    async getTableData () {
      const params = {
      }
      try {
        const res = await api_book.reqGetSeatOpening(params);
        if (res.code === 1) {
          this.tableData = res.data.records || [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {

      }
    },

    resetSearchVal () {
    },

    async exportExcelHandle () {
      const params = {
      }

      try {
        const res = await api_book.reqExportSeatOpening(params);
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

    closeDrawerHandle () {
      this.$emit("showOrHideDrawer", false);
    },

    onCancelDrawer () {
      this.closeDrawerHandle();
    },
  },
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    }
  },
  components: {

  },
  watch: {
    showDrawer (newVal) {
      this.show = newVal;
      if (newVal) {
        this.getTableData();
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/common/elementFormBtn.less";
@import "../../../style/common/scrollBar.less";
@import "../../../style/book/machine/drawerSeatOpening.less";
</style>

<style scoped lang="less">
/deep/.select-com {
  font-size: 14px;
}

/deep/.options li {
  font-size: 14px;
}
</style>

<style>
.el-cascader__dropdown {
  background-color: #202c4a;
  color: rgba(255, 255, 255, 0.8);
}

.el-cascader-node {
  color: rgba(255, 255, 255, 0.8);
  font-size: 14px;
}

.el-cascader-node:not(.is-disabled):focus,
.el-cascader-node:not(.is-disabled):hover {
  background-color: rgba(90, 90, 90, 0.5);
}

.el-cascader-panel {
  border: none;
}
</style>