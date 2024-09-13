<template>
  <div class="yuliu">
    <el-drawer
      title="开台预留"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="90%"
    >
      <p class="white p-t-4 p-b-4 p-l-6 fs14">最近刷新时间：{{loadTime}}</p>
      <div class="search white p-l-6 p-b-4" layout="row" layout-align="space-between center">
        <button class="export m-r-6" @click="exportExcelHandle">导出Excel</button>
      </div>
      <!-- 订单表格
      预留时间、预留客人姓名、客人电话、订位人部门、订位人、区域、台号、卡台标记、状态（开台、预留、拉台）、状态变更时间、备注
          records    []*ResGetBookListItem //Records 记录列表
            --------------------------------
            引用 ResGetBookListItem 格式:
              b          string     //BookTime 预留时间
              n          string     //CustomerName 客户姓名
              p          string     //CustomerPhone 客户手机
              d          string     //SalesDeptName 订位部门
              e          string     //SalesEmpName 订位人姓名
              r          string     //RegionName 区域名称
              sn         string     //SeatName 卡台名称
              m          string     //Mark 标签
              s          string     //Status 状态
              c          string     //StatusChgTime 状态变更时间
              rm         string     //Remark 备注
        普通失败, 返回编码<>1, 数据为空
     -->
      <div class="table">
        <div class="content">
          <div class="thead">
            <div class="tr">
              <th class="th w80">序号</th>
              <th class="th w90">预留时间</th>
              <th class="th w120">预留客人姓名</th>
              <th class="th w120">客人电话</th>
              <th class="th w120">订位人部门</th>
              <th class="th w90">订位人</th>
              <th class="th w120">区域</th>
              <th class="th w120">台号</th>
              <th class="th w90">卡台标记</th>
              <th class="th w90">状态</th>
              <th class="th w120">状态变更时间</th>
              <th class="th w150">备注</th>
              <th class="th w150">咨客</th>
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
                  <div class="td w80">{{i+1}}</div>
                  <div class="td w90">{{item.b}}</div>
                  <div class="td w120">{{item.n}}</div>
                  <div class="td w120">{{item.p}}</div>
                  <div class="td w120">{{item.d}}</div>
                  <div class="td w90">{{item.e}}</div>
                  <div class="td w120">{{item.r}}</div>
                  <div class="td w120">{{item.sn}}</div>
                  <div class="td w90">{{item.m}}</div>
                  <div class="td w90">{{item.s}}</div>
                  <div class="td w120">{{item.c}}</div>
                  <div class="td w120">{{item.rm}}</div>
                  <div class="td w120">{{item.on}}</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_book from "@/api/Book";
import mySelect from "@/components/book/select";
import { cloneDeep } from "lodash-es";

let originSelectOption = [];
let originPersonList = [];  // 原始的所有有效订位人id
export default {
  data () {
    return {
      show: false,
      loadTime: '',
      tableData: [],
    };
  },
  methods: {
    getReloadTime () {
      const date = new Date();
      const Y = date.getFullYear();
      const M = (date.getMonth() + 1).toString().padStart(2, 0);
      const D = date.getDate().toString().padStart(2, 0);
      const hour = date.getHours().toString().padStart(2, 0);
      const minute = date.getMinutes().toString().padStart(2, 0);
      const second = date.getSeconds().toString().padStart(2, 0);
      this.loadTime = `${Y}-${M}-${D} ${hour}:${minute}:${second}`
    },

    async getTableData () {
      this.getReloadTime();
      try {
        const res = await api_book.reqGetBookList()
        if (res.code == 1) {
          this.tableData = res.data.records || [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {

      }
    },

    async exportExcelHandle () {
      try {
        const res = await api_book.reqExportBookList();
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
    mySelect
  },
  watch: {
    showDrawer (newVal) {
      this.show = newVal;
      if (newVal) this.getTableData();
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/common/elementFormBtn.less";
@import "../../../style/common/scrollBar.less";
@import "../../../style/book/machine/drawerReservedRecord.less";
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