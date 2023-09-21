<template>
  <div>
    <!-- 扣款记录 -->
    <div class="vip make-money-to-vip">
      <h3 class="title">扣款记录</h3>

      <div class="search m-t-2 m-b-4">
        <div class="row">
          <span class="label">扣款日期:</span>
          <el-date-picker
            v-model="form.dateVal"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            size="small"
            value-format="yyyy-MM-dd"
            style="width: 280px"
          ></el-date-picker>
        </div>
        <div class="row">
          <span class="label">扣款类型:</span>
          <el-select
            v-model="form.typeVal"
            size="small"
            placeholder="请选择扣款类型"
            style="width: 200px"
          >
            <el-option
              v-for="item in form.typeOption"
              :key="item.id"
              :label="item.name"
              :value="item.id"
            ></el-option>
          </el-select>
        </div>
        <div class="row another" layout="row" layout-align="start center">
          <el-input
            class="m-r-2"
            v-model="form.keyword"
            size="small"
            placeholder="姓名/手机号/会员卡号"
            style="width: 200px"
          ></el-input>
          <button class="btn primary m-l-4" @click="getTableData">查询</button>
          <button class="btn info m-l-4" @click="resetHandle">重置</button>
          <button
            class="btn info m-l-4"
            @click="exportExcel"
            v-if="$store.getters.vipAuth"
          >
            导出
          </button>
        </div>
      </div>

      <div class="amt-info" layout="row" layout-align="start center">
        <div class="m-r-6">
          <span class="label">扣款总金额:</span>
          <span>¥{{ amtInfo.amt }}</span>
        </div>
        <div class="m-r-6">
          <span class="label">储值扣款总金额:</span>
          <span>¥{{ amtInfo.val_amt }}</span>
        </div>
        <div class="m-r-6">
          <span class="label">赠送扣款总金额:</span>
          <span>¥{{ amtInfo.free_amt }}</span>
        </div>
      </div>

      <div class="contain">
        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="space-between center">
              <div class="th">序号</div>
              <div class="th">扣款日期</div>
              <div class="th">扣款类型</div>
              <div class="th">会员姓名</div>
              <div class="th">绑定手机</div>
              <div class="th">联系手机</div>
              <div class="th">会员卡号</div>
              <div class="th">卡类型</div>
              <div class="th">会员卡等级</div>
              <div class="th">扣款-储值金额</div>
              <div class="th">扣款-赠送金额</div>
              <div class="th">赠送积分</div>
              <div class="th">操作人</div>
              <div
                class="th"
                :style="{
                  visibility: $store.getters.vipAuth ? 'visible' : 'hidden',
                }"
              >
                操作
              </div>
            </div>
          </div>
          <div class="tbody">
            <div
              class="tr"
              v-for="(item, index) in tableData"
              :key="index"
              layout="row"
              layout-align="space-between center"
            >
              <div class="td">{{ index + 1 }}</div>
              <div class="td">{{ item.d }}</div>
              <div class="td">{{ item.t }}</div>
              <div class="td">{{ item.n }}</div>
              <div class="td">{{ item.bp }}</div>
              <div class="td">{{ item.cp }}</div>
              <div class="td">{{ item.cn }}</div>
              <div class="td">{{ item.ct }}</div>
              <div class="td">{{ item.cl }}</div>
              <div class="td fs16-bold">{{ item.va }}</div>
              <div class="td fs16-bold">{{ item.fa }}</div>
              <div class="td">{{ item.p }}</div>
              <div class="td">{{ item.o }}</div>
              <div
                class="td"
                :style="{
                  visibility: $store.getters.vipAuth ? 'visible' : 'hidden',
                }"
              >
                <span @click="printHandle(item)">重打小票</span>
              </div>
            </div>
            <div class="no-data" v-if="tableData.length == 0">
              <img :src="require('@/assets/vip-imgs/empty.png')" alt />
              <p>暂无数据</p>
            </div>
          </div>
        </div>
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
import api_vip from "@/api/vip";
export default {
  data() {
    return {
      form: {
        dateVal: [],
        typeVal: 0,
        typeOption: [
          {
            id: 0,
            name: "全部",
          },
          {
            id: 1,
            name: "业务扣款",
          },
          {
            id: 2,
            name: "错充扣款",
          },
        ],
        keyword: "",
      },
      tableData: [],
      amtInfo: {},
      pageInfo: {
        page: 1,
        pageSize: 20,
        total: 10000,
      },
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
      this.form.dateVal = [result, result];
    },
    async getTableData() {
      const params = {
        page_num: this.pageInfo.page * 1, //    int    第几页
        page_size: this.pageInfo.pageSize * 1, //   int     每页行数
        begin_day: this.form.dateVal[0], //   string  扣款开始日期 格式  yyyy-mm-dd
        end_day: this.form.dateVal[1], //     string   扣款结束日期 格式 yyyy-mm-dd
        type_id: this.form.typeVal * 1, //     int     扣款类型 0 代表不限制  1 业务扣款  2  充错扣款
        key: this.form.keyword, //         string   模糊查询关键字, 客户姓名,姓名首字母,手机号,会员卡号 , 空, 表示不限制
      };
      try {
        const res = await api_vip.reqGetVipCarSubMoneyListReport(params);
        if (res.code == 1) {
          this.tableData = res.data.datas || [];
          this.pageInfo.total = res.data.row_cnt || 0;
          this.amtInfo = {
            free_amt: res.data.free_amt,
            val_amt: res.data.val_amt,
            amt: res.data.amt,
          };
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取充值记录失败", error);
      }
    },
    async printHandle(itemInfo) {
      const params = {
        log_id: itemInfo.id * 1, //   int64   重打订单Id
      };
      try {
        const res = await api_vip.reqPrintTicketNew(params);
        res.code == 1
          ? this.$message.success("重打小票成功")
          : this.$message.warning(res.msg);
      } catch (error) {
        console.log("重打小票失败", error);
      }
    },
    resetHandle() {
      this.initDate();
      this.form.typeVal = 0;
      this.form.keyword = "";
      this.getTableData();
    },
    async exportExcel() {
      const params = {
        begin_day: this.form.dateVal[0], //   string  扣款开始日期 格式  yyyy-mm-dd
        end_day: this.form.dateVal[1], //     string   扣款结束日期 格式 yyyy-mm-dd
        type_id: this.form.typeVal * 1, //     int     扣款类型 0 代表不限制  1 业务扣款  2  充错扣款
        key: this.form.keyword, //         string   模糊查询关键字, 客户姓名,姓名首字母,手机号,会员卡号 , 空, 表示不限制
      };
      try {
        const res = await api_vip.reqExportExcelForSubMoney(params);
        if (!res.msg) {
          const url = window.URL.createObjectURL(
            new Blob([res], {
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            })
          );
          const a = document.createElement("a"); //添加a标签
          document.body.appendChild(a);
          a.href = url;
          a.setAttribute("download", res.fileName); // 下载文件的名称及文件类型后缀
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
    changePageHandle(page) {
      this.pageInfo.page = page;
      this.getTableData();
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
@import "../../style/vip/vipPay.less";
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
