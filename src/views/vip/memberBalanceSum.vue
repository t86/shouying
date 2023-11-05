<template>
    <div>
      <!-- 会员卡余额汇总表 -->
      <div class="vip memberBalanceSum">
        <h3 class="title">会员卡余额汇总表</h3>
  
        <div class="title m-t-2">
          <div class="search">
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
              >
                导出
              </button>
            </div>
            <div style="color: red;margin-top: 10px;">
            该列表包含不记名会员卡余额
            </div>
          </div>
          <div class="total">

              <div>当天充值储值额:<span style="color: red;">{{format(totalInfo.dept_val)}}</span></div>
              <div>当天充值赠送额:<span style="color: red;">{{format(totalInfo.dept_free)}}</span></div>
              <div>当天充值汇总:<span style="color: red;">{{format(totalInfo.dept_val + totalInfo.dept_free)}}</span></div>
              <div>当天充值积分:<span style="color: red;">{{totalInfo.dept_pt}}</span></div>
              <div>当天消费储值额:<span style="color: red;">{{format(totalInfo.csm_val)}}</span></div>
              <div>当天消费赠送额:<span style="color: red;">{{format(totalInfo.csm_free)}}</span></div>
              <div>当天消费汇总:<span style="color: red;">{{format(totalInfo.csm_val + totalInfo.csm_free)}}</span></div>
              <div>当天消费积分:<span style="color: red;">{{totalInfo.csm_pt}}</span></div>
              <div>储值余额:<span style="color: red;">{{format(totalInfo.free_bal)}}</span></div>
              <div>赠送余额:<span style="color: red;">{{format(totalInfo.val_bal)}}</span></div>
              <div>全部余额汇总:<span style="color: red;">{{format(totalInfo.val_bal + totalInfo.free_bal)}}</span></div>
              <div>积分余额:<span style="color: red;">{{totalInfo.pt_bal}}</span></div>
          </div>
        </div>
  

        <div class="contain">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">序号</div>
                <div class="th">姓名</div>
                <div class="th">绑定手机号</div>
                <div class="th">联系手机</div>
                <div class="th">会员卡号</div>
                <div class="th">卡类型</div>
                <div class="th">会员卡等级</div>
                <div class="th">充值金额</div>
                <div class="th">赠送金额</div>
                <div class="th">总余额</div>
                <div class="th">积分余额</div>
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
                <div class="td">{{ item.n }}</div>
                <div class="td">{{ item.bp }}</div>
                <div class="td">{{ item.cp }}</div>
                <div class="td">{{ item.cn }}</div>
                <div class="td">{{ item.ct }}</div>
                <div class="td">{{ item.cl }}</div>
                <div class="td fs16-bold">{{ item.vb }}</div>
                <div class="td fs16-bold">{{ item.fb }}</div>
                <div class="td fs16-bold">{{ item.b }}</div>
                <div class="td fs16-bold">{{ item.p }}</div>
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
          keyword: "",
        },
        tableData: [],
        totalInfo:{},
        pageInfo: {
          page: 1,
          pageSize: 20,
          total: 10000,
        },
      };
    },
    methods: {
      format(number) {
        if(number == 0) return number.toString();
        number = number.toString();

        let decimalIndex = number.length - 2; 
        return number.substring(0, decimalIndex) + "." + number.substring(decimalIndex);
      },
      async getTableData() {
        const params = {
          page_num: this.pageInfo.page * 1, //    int    第几页
          page_size: this.pageInfo.pageSize * 1, //   int     每页行数
          key: this.form.keyword, //         string   模糊查询关键字, 客户姓名,姓名首字母,手机号,会员卡号 , 空, 表示不限制
        };
        try {
          const res = await api_vip.reqGetVipBalanceListReport(params);
          if (res.code == 1) {
            this.tableData = res.data.datas || [];
            this.totalInfo = res.data.total_info || {};
            this.pageInfo.total = res.data.row_cnt || 0;
          } else {
            this.$message.warning(res.msg);
          }
        } catch (error) {
          console.log("获取记录失败", error);
        }
      },
      resetHandle() {
        this.form.keyword = "";
        this.getTableData();
      },
      async exportExcel() {
        const params = {
          key: this.form.keyword, //         string   模糊查询关键字, 客户姓名,姓名首字母,手机号,会员卡号 , 空, 表示不限制
        };
        try {
          const res = await api_vip.reqExportExcelForVipBalance(params);
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
      changePageHandle(page) {
        this.pageInfo.page = page;
        this.getTableData();
      },
    },
    mounted() {
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
  