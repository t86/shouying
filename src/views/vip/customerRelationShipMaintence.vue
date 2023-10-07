<template>
    <div>
      <!-- 客户关系维护 -->
      <div class="vip ">
        <h3 class="title">客户关系维护</h3>
  
        <div class="search m-t-2 m-b-4">
          <div class="row" layout="row" layout-align="start center">
            <span class="label">操作日期:</span>
            <el-date-picker
              v-model="form.dateVal"
              type="daterange"
              range-separator="至"
              start-placeholder="开始日期"
              end-placeholder="结束日期"
              size="small"
              value-format="yyyy-MM-dd"
              style="width: 220px"
            ></el-date-picker>
            <span class="label">开卡推荐人:</span>
            <el-select
              style="width: 154px"
              v-model="form.personVal"
              filterable
              remote
              reserve-keyword
              placeholder="输入员工号可查询"
              :remote-method="remoteMethod"
              :loading="remoteLoading"
              size="small"
            >
              <el-option
                v-for="item in personOptions"
                :key="item.id"
                :label="item.name + ' (' + item.code + ')'"
                :value="item.id"
              ></el-option>
            </el-select>
            <el-input
              class="m-r-2 m-l-2"
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
        </div>

        
        <div class="amt-info" layout="row" layout-align="start center">
          <div class="m-r-6">
            <span class="label">新增会员人数:</span>
            <span>{{ amtInfo.cnt }}</span>
          </div>
          <div class="m-r-6">
            <span class="label">累计消费次数:</span>
            <span>{{ amtInfo.cc }}</span>
          </div>
          <div class="m-r-6">
            <span class="label">累计消费总额:</span>
            <span>¥{{ amtInfo.a.toFixed(2) }}</span>
          </div>
          <div class="m-r-6">
            <span class="label">累计消费金额（赠送）:</span>
            <span>¥{{ amtInfo.fa.toFixed(2) }}</span>
          </div>
          <div class="m-r-6">
            <span class="label">累计消费金额（储值）:</span>
            <span>¥{{ amtInfo.va.toFixed(2) }}</span>
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
                <div class="th">开卡推荐人</div>
                <div class="th">开卡日期</div>
                <div class="th">上次消费日期</div>
                <div class="th">距离上次消费天数</div>
                <div class="th">累计消费总额</div>
                <div class="th">累计消费金额（赠送）</div>
                <div class="th">累计消费金额（储值）</div>
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
                <div class="td">{{ item.b }}</div>
                <div class="td">{{ item.c }}</div>
                <div class="td">{{ item.cn }}</div>
                <div class="td">{{ item.ct }}</div>
                <div class="td">{{ item.cl }}</div>
                <div class="td">{{ item.s }}</div>
                <div class="td">{{ item.cr }}</div>
                <div class="td">{{ item.lc }}</div>
                <div class="td">{{ item.d }}</div>
                <div class="td">{{ item.a }}</div>
                <div class="td">{{ item.fa }}</div>
                <div class="td">{{ item.va }}</div>
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
          dateVal:[],
          personVal: ""
        },
        amtInfo: {
          a:0,
          cc:0,
          fa:0,
          va:0,
          cnt:0
        },
        remoteLoading: false,
        tableData: [],
        personOptions: [], // 开卡推荐人
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
          key: this.form.keyword, //         string   模糊查询关键字
          begin_day: this.form.dateVal[0],
          end_day: this.form.dateVal[1],
          sales_emp_id: this.form.personVal
        };
        try {
          const res = await api_vip.reqGetMbCardConsumeList(params);
          if (res.code == 1) {
            this.tableData = res.data.records || [];
            this.amtInfo = {cnt: res.data.new_mb_cnt }
            this.tableData.forEach(item => {
              if (!this.amtInfo.cc) {
                this.amtInfo.cc = 0
              }
              this.amtInfo.cc = item.cc * 1 +  this.amtInfo.cc;
              if (!this.amtInfo.a) {
                this.amtInfo.a = 0
              }
              this.amtInfo.a = item.a * 1 +  this.amtInfo.a;
              if (!this.amtInfo.fa) {
                this.amtInfo.fa = 0
              }
              this.amtInfo.fa = item.fa * 1 +  this.amtInfo.fa;
              if (!this.amtInfo.va) {
                this.amtInfo.va = 0
              }
              this.amtInfo.va = item.va * 1 +  this.amtInfo.va;
            })
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
          begin_day: this.form.dateVal[0],
          end_day: this.form.dateVal[1],
          sales_emp_id: this.form.personVal, // 开卡推荐人
        };
        try {
          const res = await api_vip.reqExportMbCardConsumeList(params);
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
      
    remoteMethod(query) {
      if (query !== "") {
        this.remoteLoading = true;
        const result =
          this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo || [];
        this.personOptions = result.filter(
          (item) => item.code.includes(query) || item.name.includes(query) || item.namePy.includes(query)
        );
        this.remoteLoading = false;
      } else {
        this.options = [];
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
  @import "../../style/vip/customerRelationShipMaintence.less";
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
  