<template>
  <!-- 存取酒记录 -->
  <div class="save-and-get-report">
    <div class="top" layout="row" layout-align="start center">
      <div class="label fs14">存取日期：</div>
      <div class="value m-r-2">
        <el-date-picker style="width:140px" v-model="start_day" type="date" :clearable="false" size="small"
          value-format="yyyy-MM-dd" placeholder="开始日期"></el-date-picker>
        <span>至</span>
        <el-date-picker style="width:140px" v-model="end_day" type="date" :clearable="false" size="small"
          value-format="yyyy-MM-dd" placeholder="结束日期"></el-date-picker>
      </div>
      <el-select v-model="selectVal" size="small" style="width:100px" placeholder="请选择">
        <el-option
          v-for="item in options"
          :key="item.value"
          :label="item.label"
          :value="item.value"
        ></el-option>
      </el-select>
      <el-input
        v-model="keyword"
        style="width:310px"
        class="m-r-2 m-l-2"
        size="small"
        placeholder="输入客人姓名/手机号码/商品/卡台/存酒流水号"
      ></el-input>
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button size="small" @click="resetHandle">重置</el-button>
    </div>
    <div class="btn-area m-t-4">
      <el-button type="primary" size="small" @click="printerHandle">补打小票</el-button>
      <el-button type="primary" size="small" @click="exportExcelHandle">导出</el-button>
    </div>

    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="start center">
            <div class="th">
              <el-checkbox
                :indeterminate="isIndeterminate"
                v-model="checkAll"
                @change="changeCheckboxHandle('all')"
              >全选</el-checkbox>
            </div>
            <div class="th">超级码</div>
            <div class="th">客人姓名</div>
            <div class="th">联系方式</div>
            <div class="th">卡台</div>
            <div class="th">订台人</div>
            <div class="th">服务员</div>
            <div class="th">存/取酒时间</div>
            <div class="th">出/入库时间</div>
            <div class="th">出/入库操作人</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" :class="{'selected': item.checked}" v-for="(item, index) in tableData" :key="item.id">
            <div class="coll" layout="row" layout-align="space-between center">
              <div class="td" layout="row" layout-align="start center">
                <el-checkbox
                  v-model="item.checked"
                  @change="changeCheckboxHandle('item')"
                >{{index + 1}}</el-checkbox>
                <span class="tips m-l-2" :class="[item.t == 1 ? 'blue' : 'red']">{{item.t == 1 ? '存' : '取'}}</span>
                <i
                  class="m-l-2"
                  style="border:1px solid #ccc;cursor:pointer"
                  @click="item.show = !item.show"
                  :class="[item.show ? 'el-icon-minus' : 'el-icon-plus']"
                ></i>
              </div>
              <div class="th">{{item.us}}</div>
              <div class="td">{{item.c}}</div>
              <div class="td">{{item.p}}</div>
              <div class="td">{{item.s}}</div>
              <div class="td">{{item.se}}</div>
              <div class="td">{{item.we}}</div>
              <div class="td">{{item.bt}}</div>
              <div class="td">{{item.ot}}</div>
              <div class="td">{{item.on}}</div>
            </div>
            <div class="detail-list" v-if="item.show">
              <div class="tr-thead" layout="row" layout-align="space-between center">
                <div class="tr-th">酒水名称</div>
                <div class="tr-th">规格</div>
                <div class="tr-th">每瓶克数</div>
                <div class="tr-th">数量</div>
                <div class="tr-th">过期时间</div>
                <div class="tr-th">授权人</div>
                <div class="tr-th">备注姓名</div>
                <div class="tr-th">备注手机号</div>
                <div class="tr-th">存酒流水号</div>
              </div>
              <div class="tr-tbody">
                <div
                  class="tr-tr"
                  layout="row"
                  layout-align="space-between center"
                  v-for="items in (item.os || [])"
                  :key="items.id"
                >
                  <div class="tr-td">{{items.n}}</div>
                  <div class="tr-td">{{items.u}}</div>
                  <div class="tr-td">{{items.g}}</div>
                  <div class="tr-td">{{items.c}}</div>
                  <div class="tr-td">{{items.e}}</div>
                  <div class="tr-td">{{items.a}}</div>
                  <div class="tr-td">{{items.rn}}</div>
                  <div class="tr-td">{{items.rp}}</div>
                  <div class="tr-td" style="user-select: text;">{{items.i}}</div>
                </div>
              </div>
            </div>
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
      start_day: "",
      end_day: "",
      selectVal: 0,
      checkAll: false,
      options:[{
        label: '全部',
        value: 0
      },{
        label: '存酒',
        value: 1
      },{
        label: '取酒',
        value: 2
      }],
      tableData: []
    };
  },
  methods: {
    async getTableData() {
      const params = {
        start_day: this.start_day, //  string  存取开始日期
        end_day: this.end_day, // string  存取结束日期
        type_id: this.selectVal * 1, //  int    类型 0 全部 1 存酒 2 取酒
        key: this.keyword || "" //  string   模糊查询关键字
      };

      try {
        const res = await api_wine.reqGetSaveAndGetWineList(params);
        if (res.code == 1) {
          res.data.records = res.data.records || [];
          res.data.records.forEach(el => {
            el.os = el.os || []
            el.show = true
            el.checked = false;
            el.isIndeterminate = false
          });

          this.checkAll = false
          this.tableData = res.data.records;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("存酒库列表数据获取失败", error);
      }
    },

    // 补打小票
    async printerHandle() {
      const checkedList = this.tableData.filter(item => item.checked)
      if(checkedList.length <= 0) return this.$message.warning('请选择需要打印小票的订单')
      const params = {
        type_ids: checkedList.map(item => item.t * 1), //   []int  小票类型 1 存酒 2 取酒
        ids: checkedList.map(item => item.o * 1)  //   []int64   对应小票类型的需要补丁的订单列表
      };
      try {
        const res = await api_wine.reqPrintSaveAndGetWineList(params);
        if (res.code == 1) {
          this.$message.success("打印成功");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("打印小票失败", error);
      }
    },

    async exportExcelHandle(){
      const params = {
        start_day: this.start_day, //  string  存取开始日期
        end_day: this.end_day, // string  存取结束日期
        type_id: this.selectVal * 1, //  int    类型 0 全部 1 存酒 2 取酒
        key: this.keyword || "" //  string   模糊查询关键字
      }
      try {
        const res = await api_wine.reqExportExcelOfSaveAndGetReport(params);
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

    resetHandle() {
      const oneHour = +new Date('2023/07/22 12:00:00') - +new Date('2023/07/22 11:00:00')
      const date = new Date(+new Date() - 8 * oneHour)
      const year = date.getFullYear();
      const month = (date.getMonth() + 1).toString().padStart(2, 0);
      const day = date
        .getDate()
        .toString()
        .padStart(2, 0);
      const now = year + "-" + month + "-" + day;
      this.start_day = now;
      this.end_day = now;
      this.selectVal = 0
      this.keyword = "";
      this.getTableData();
    }
  },
  created() {
    this.resetHandle();
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
.save-and-get-report {
  padding: 20px;
  .table-content {
    width: 100%;
    overflow-x: auto;
    overflow-y: hidden;
    .table {
      min-width: 1300px;
      .thead .th {
        font-size: 15px;
          &:nth-child(3),
          &:nth-child(6),
          &:nth-child(7){
            width: 40%;
          }
      }
      .tbody {
        height: calc(100vh - 260px);
        overflow: auto;
        .tr {
          background-color: #ddd!important;
          margin-top: 2px;
          .td {
            background-color: #ddd!important;
          }
          &:hover{
            .td {
              background-color: #ddd!important;

            }
          }
        }
        .coll {
          height: 40px;
          font-size: 15px;
          .td {
            font-weight: 600;
          }
          .td:nth-child(3),
          .td:nth-child(6),
          .td:nth-child(7){
            width: 40%;
          }

          .tips {
            width: 26px;
            height: 26px;
            line-height: 26px;
            text-align: center;
            color: #fff;
            border-radius: 50%;
            font-size: 14px;
            &.blue {
              background-color: #409EFF;
            }
            &.red{
              background-color: #F56C6C;
            }
          }
          
        }
        .detail-list {
          font-size: 13px;
          .tr-thead {
            height: 30px;
            width: 100%;
            background-color: #eee;
            .tr-th {
              font-weight: 600;
              width: 50%;
              color: #6A6A74;
              &:nth-child(1){
                padding-left: 20px;
              }
              /deep/.el-checkbox__label{
                font-weight: 600;
              }
            }
          }
          .tr-tbody {
            // max-height: 200px;
            // overflow: auto;
            .tr-tr {
              min-height: 30px;
              &:hover{
                background-color: #d7e9ff!important;
              }
              &:nth-child(2n){
                background-color: #eee;
              }
              &:nth-child(2n + 1){
                background-color: #f9f9f9;
              }
              .tr-td {
                width: 50%;
                &:nth-child(1){
                  padding-left: 20px;
                }
              }
            }
          }
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