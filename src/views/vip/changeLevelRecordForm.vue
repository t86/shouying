<template>
  <div>
    <!-- 更改等级记录表 -->
    <div class="vip memberConsumeRank">
      <h3 class="title">更改等级记录表</h3>

      <div class="search m-t-2 m-b-4">
        <div class="row another" layout="row" layout-align="start center">
          <span class="label">更改日期:</span>
          <el-date-picker style="width:130px" v-model="form.change_day" type="date" :clearable="false" size="small"
            value-format="yyyy-MM-dd" placeholder="开始日期"></el-date-picker>
            <el-input class="m-r-2 m-l-2" v-model="form.keyword" size="small" placeholder="姓名/手机号/会员卡号"
            style="width: 200px"></el-input>
          <button class="btn primary m-l-4" @click="getTableData">查询</button>
          <button class="btn info m-l-4" @click="resetHandle">重置</button>
          <button class="btn info m-l-4" @click="exportExcel">
            导出
          </button>
        </div>
      </div>

      <div class="contain">
        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="space-between center">
              <div class="th">序号</div>
              <div class="th">操作时间</div>
              <div class="th">操作人</div>
              <div class="th">会员姓名</div>
              <div class="th">绑定手机</div>
              <div class="th">联系手机</div>
              <div class="th">会员卡号</div>
              <div class="th">卡类型</div>
              <div class="th">会员卡等级</div>
              <div class="th">注销前卡储值金额</div>
              <div class="th">注销前卡赠送金额</div>
              <div class="th">注销前卡剩余积分</div>
            </div>
          </div>
          <div class="tbody">
            <div class="tr" v-for="(item, index) in tableData" :key="index" layout="row"
              layout-align="space-between center">
              <div class="td">{{ index + 1 }}</div>
              <div class="td">{{ item.o }}</div>
              <div class="td">{{ item.e }}</div>
              <div class="td">{{ item.m }}</div>
              <div class="td">{{ item.b }}</div>
              <div class="td">{{ item.c }}</div>
              <div class="td">{{ item.n }}</div>
              <div class="td">{{ item.t }}</div>
              <div class="td">{{ item.l }}</div>
              <div class="td">{{ item.vb }}</div>
              <div class="td">{{ item.fb }}</div>
              <div class="td">{{ item.pb }}</div>
            </div>
            <div class="no-data" v-if="tableData.length == 0">
              <img :src="require('@/assets/vip-imgs/empty.png')" alt />
              <p>暂无数据</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
  
<script>
import api_vip from "@/api/vip";
export default {
  data() {
    return {
      form: {
        keyword: "",
        change_day: "",
      },
      tableData: [],
    };
  },
  methods: {
    initDate() {
      const oneHour =
        +new Date("2023/07/22 12:00:00") - +new Date("2023/07/22 11:00:00");
      const date = new Date(+new Date() - 8 * oneHour);
      const year = date.getFullYear();
      const month = (date.getMonth() + 1).toString().padStart(2, 0);
      const day = date.getDate().toString().padStart(2, 0);
      const result = year + "-" + month + "-" + day;
      this.form.begin_day = result;
      this.form.end_day = result;
    },
    async getTableData() {
      const params = {
        key: this.form.keyword, //         string   模糊查询关键字
        begin_day: this.form.begin_day,
        end_day: this.form.end_day
      };
      try {
        const res = await api_vip.reqGetMbCardZxList(params);
        if (res.code == 1) {
          this.tableData = res.data.records || [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取记录失败", error);
      }
    },
    resetHandle() {
      this.initDate();
      this.form.keyword = "";
      this.getTableData();
    },
    async exportExcel() {
      const params = {
        key: this.form.keyword, //         string   模糊查询关键字
        begin_day: this.form.begin_day,
        end_day: this.form.end_day
      };
      try {
        const res = await api_vip.reqExportMbCardZxList(params);
        if (!res.msg) {
          const url = window.URL.createObjectURL(
            new Blob([res], {
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
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
  },
  mounted() {
    this.initDate();
    this.getTableData();
  },
};
</script>
  
<style scoped lang="less">
@import "../../style/vip/vip.less";
@import "../../style/vip/vipBtn.less";
@import "../../style/vip/vipPagination.less";
@import "../../style/vip/memberBalanceSum.less";
</style>
<style>
.el-select-dropdown__empty {
  background-color: #bec5d5 !important;
}

.el-scrollbar .el-scrollbar__view.el-select-dropdown__list {
  background-color: #bec5d5 !important;
}

.el-picker-panel {
  background-color: #bec5d5 !important;
}

/* 日期选择器 */
.el-date-picker__header-label {
  color: #1a1a21;
}

.el-date-table th,
.el-picker-panel__content {
  color: #1a1a21;
}
</style>
<style scoped>
.el-select-dropdown__item {
  color: rgba(255, 255, 255, 0.8);
  font-size: 14px;
}

.el-select-dropdown__item.hover,
.el-select-dropdown__item:hover {
  background-color: rgba(90, 90, 90, 0.5) !important;
}

.el-select-dropdown__item {
  color: #1a1a21;
}
</style>
  