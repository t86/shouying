<template>
    <div class="month_invs">
        <div class="month_invs-rkrq">
            <div class="rkrq">
                <span class="">日期：</span>
                <el-date-picker
                  v-model="Inbound.date"
                  :editable="false"
                  style="width:220px"
                  :unlink-panels="true"
                  @change="demand"
                  type="daterange"
                  :clearable="false"
                  size="small"
                  value-format="yyyy-MM-dd"
                  range-separator="至"
                  start-placeholder="开始日期"
                  end-placeholder="结束日期"
                  >
                </el-date-picker>
            </div>
            <div class="rkrq">
                <span>仓库名称：</span>
                <el-select v-model="Inbound.type" placeholder="全部" @change="demand" clearable>
                    <el-option label="全部" value="0"></el-option>
                    <el-option v-for="(item) in stores" :key="item.id" :label="item.n" :value="item.id"></el-option>
                </el-select>
            </div>
            <div class="rkrq">
                <el-input v-model="Inbound.namse" @input="demand" placeholder="物料名称或简写"></el-input>
            </div>
            <div class="rkrq">
                <!-- <el-button type="primary" @click="demand">查询</el-button> -->
                <el-button type="primary" @click="resetstorage">重置</el-button>
                <el-button type="primary" @click="deriveExcel">导出Excel</el-button>
            </div>
        </div>

        <div style="position: relative">
            <div style="display: inline-block;" id="allexportareport" class="meisfgr">
                <table class="zhuixiaoi">
                    <thead class="mmodity">
                    <tr>
                        <th>序号</th>
                        <th>仓库名称</th>
                        <th>物料名称</th>
                        <th>单位名称</th>
                        <th>一级分类</th>
                        <th>二级分类</th>
                        <th>
                            <div class="alignment">上月结存数量</div>
                        </th>
                        <th>
                            <div class="alignment">上月结存金额</div>
                        </th>
                        <th>
                            <div class="alignment">入库数量</div>
                        </th>
                        <th>
                            <div class="alignment">入库金额</div>
                        </th>
                        <th>
                            <div class="alignment">出库数量</div>
                        </th>
                        <th>
                            <div class="alignment">出库成本金额</div>
                        </th>
                        <th>
                            <div class="alignment">出库销售金额</div>
                        </th>
                        <th>
                            <div class="alignment">本月结存数量</div>
                        </th>
                        <th>
                            <div class="alignment">本月加权单价</div>
                        </th>
                        <th>
                            <div class="alignment">本月结存金额</div>
                        </th>
                    </tr>
                    </thead>
                    <tbody class="limiting" ref="systemForm" @scroll="sysHandleScroll()"
                           @mouseover="changeFlag(false)" :style="{'border-bottom':tableData.length<1?'0px':'',
                'width':tableData.length>12?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`
                }">
                    <tr v-for="(item,i) in tableData" :key="i" class="drag-list">
                        <td>{{i+1}}</td>
                        <td>
                            <ellipsis-tooltip :text="item.sn || '---'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.n || '---'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.un || '---'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.moc || '---'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.mtc || '---'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <div class="alignment">{{item.pc}}</div>
                        </td>
                        <td>
                            <div class="alignment">{{item.pa}}</div>
                        </td>
                        <td>
                            <div class="alignment">{{item.ic}}</div>
                        </td>
                        <td>
                            <div class="alignment">{{item.ia}}</div>
                        </td>
                        <td>
                            <div class="alignment">{{item.oc}}</div>
                        </td>
                        <td>
                            <div class="alignment">{{item.oa}}</div>
                        </td>
                        <td>
                            <div class="alignment">{{item.os}}</div>
                        </td>
                        <td>
                            <div class="alignment">{{item.c}}</div>
                        </td>
                        <td>
                            <div class="alignment">{{item.p}}</div>
                        </td>
                        <td>
                            <div class="alignment">{{item.a}}</div>
                        </td>
                    </tr>
                    </tbody>
                </table>
                <div class="tiaodd" v-if="tableData.length<1">
                    <td class="nodata" :style="{'height':`${MaxHeight}px`}">
                        <img src="../../../../assets/img/wu.png" alt="">
                        <div class="hint">暂无数据</div>
                    </td>
                </div>
            </div>
            <div style="display: inline-block;position: absolute;top: 0;left: 0;z-index: 100;background-color: #f9f9f9;">
                <table class="zhuixiaoi zhuixiaoi_l" style="width: auto;">
                    <thead class="mmodity">
                    <tr>
                        <th>序号</th>
                        <th>仓库名称</th>
                        <th>物料名称</th>
                    </tr>
                    </thead>
                    <tbody class="limiting" ref="externalForm" @scroll="exterHandleScroll()"
                           @mouseover="changeFlag(true)" :style="{'border-bottom':tableData.length<1?'0px':'',
                'width':tableData.length>12?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`
                }">
                    <tr v-for="(item,i) in tableData" :key="i" class="drag-list">
                        <td>{{i+1}}</td>
                        <td>
                            <ellipsis-tooltip :text="item.sn || '---'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.n || '---'"></ellipsis-tooltip>
                        </td>
                    </tr>
                    </tbody>
                </table>
            </div>

        </div>
    </div>
</template>
<script>
import EllipsisTooltip from '@/components/EllipsisTooltip.vue'//根据路径导入组件
import FileSaver from 'file-saver';
import XLSX from 'xlsx';
export default {
  data(){
    return {
      Inbound: {
        date: '',//日期
        type: '',//仓库id
        namse: '',//内容
      },//出库
      stores: [],//仓库列表
      tableData: [],// 读取管理列表
      windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
      MaxHeight: 0,//滚动高度
      MaxNumber: 0,//最大个数

      flag: false
    }
  },
  mounted(){
    this.daterq()
    this.$api.ERP.rpt_erp.requestrpt_erpparam_items().then(res => {
      if (res.code == 1) {
        this.stores = res.data.stores
      } else {
        this.$message.warning(res.msg)
      }
    })
    this.demand()
    this.RollMaxHeight(this.windowHeigh)
    var that = this;
    window.onresize = () => {
      return (() => {
        window.fullHeight = document.documentElement.clientHeight;
        window.fullWidth = document.documentElement.clientWidth;
        that.windowHeigh = window.fullHeight;  // 高
        that.windowWidt = window.fullWidth; // 宽
      })()
    };
  },
  components: {
    EllipsisTooltip
  },
  methods: {
    //滚动条监听
    changeFlag(flag) {
      this.flag = flag
    },
    // 左右滚动条滚动同步
    sysHandleScroll() {
      if (!this.flag) {
        this.$refs.externalForm.scrollTop = this.$refs.systemForm.scrollTop
      }
    },
    exterHandleScroll() {
      if (this.flag) {
        this.$refs.systemForm.scrollTop = this.$refs.externalForm.scrollTop
      }
    },
    // 滚动最大高度
    RollMaxHeight(i){
      var g = document.getElementsByClassName("month_invs-rkrq")[0].clientHeight;
      var s = i - 48 - 60 - 55 - g;
      this.MaxHeight = s
      this.MaxNumber = Math.floor(s / 37)
    },
    // 获取管理列表内容
    demand(){
      this.$api.ERP.rpt_erp.requestrpt_erpmonth_invs({
        start_day: this.Inbound.date[0],
        end_day: this.Inbound.date[1],
        store_id: this.Inbound.type || 0,
        name: this.Inbound.namse,
      }).then(res => {
        if (res.code == 1) {
          this.tableData = res.data.records || []
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 日期
    daterq(){
      const date = new Date();
      const year = date.getFullYear();
      const month = (date.getMonth() + 1).toString().padStart(2, 0);
      const day = date.getDate().toString().padStart(2, 0);
      const now = year + "-" + month + "-" + day;
      this.Inbound.date = [now, now]
    },
    // 重置
    resetstorage(){
      this.daterq()
      this.Inbound.type = ''
      this.Inbound.namse = ''
      this.tableData = []

      this.daterq()
      this.demand();
    },
    // 导出Excel
    deriveExcel(){
      if (this.tableData.length > 0) {
        // 文件名
        const filename = '物料库存表.xlsx'
        // 获取表格元素
        const wb = XLSX.utils.table_to_book(document.getElementById("allexportareport"))
        const wbout = XLSX.write(wb, {bookType: 'xlsx', bookSST: true, type: 'array'})
        try {
          FileSaver.saveAs(new Blob([wbout], {type: 'application/octet-stream'}), filename)
        } catch (e) {
          console.log(e)
        }
        return wbout
      } else {
        this.$message.warning("暂无内容,无法导出")
      }
    },


  },
  computed: {},
  watch: {
    windowHeigh(val) {
      let that = this;
      this.RollMaxHeight(val)
      //   console.log("实时屏幕高度：",val, that.windowHeigh );
    },
    windowWidt (val) {
      let that = this;
      this.RollMaxHeight(that.windowHeigh)
      //   console.log("实时屏幕宽度：",val, that.windowWidt );
    },
  }

}
</script>
<style>
    .month_invs {
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding: 20px 30px;
    }

    /* 表格内文字居中 */
    .month_invs .alignment {
        text-align: right !important;
    }

    /* 表格无数据时展示 */
    .month_invs .nodata {
        width: 100% !important;
        /*height: 250px !important;*/
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
    }

    .month_invs .nodata img {
        width: 60px;
        height: 60px;
    }

    .month_invs .nodata .hint {
        line-height: 40px;
        font-size: 13px !important;
    }

    .month_invs .month_invs-headline {
        font-size: 30px;
        font-weight: bold;
        color: #40404e;
    }

    .month_invs .month_invs-controller {
        margin-top: 20px;
        margin-bottom: 30px;
    }

    .month_invs .month_invs-rkrq {
        width: 100%;
        color: #40404e;
        overflow: hidden;
        font-size: 13px;
        line-height: 14px;
    }

    .month_invs .month_invs-rkrq .rkrq {
        display: inline-flex;
        align-items: center;
        margin: 0 0 14px 0;
    }

    .month_invs .month_invs-rkrq .rkrq:nth-child(1) {
        width: 275px !important;
    }

    .month_invs .month_invs-rkrq .rkrq:nth-child(2) {
        width: 275px !important;
    }

    .month_invs .month_invs-rkrq .rkrq:nth-child(3) {
        width: 190px !important;
        margin-right: 10px;
    }

    .month_invs .month_invs-rkrq .rkrq:nth-child(4) {
        width: 255px !important;
    }

    .el-month-table td .cell, .el-date-picker__header-label {
        color: #40404e;
    }

    .month_invs .el-date-editor.el-input {
        width: 220px;
    }

    .month_invs .ewdetai {
        color: #438dfd;
    }

    .month_invs .AddPrincipal {
        color: #4eadfc
    }

    .month_invs .compatibil {
        margin-bottom: 10px;
    }

    .month_invs .el-input__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
        height: 30px;
        line-height: 30px;
    }

    .month_invs .el-input {
        width: 190px;
    }

    .month_invs .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    .month_invs .has-gutter {
        border: 1px solid #f5f5f5;
    }

    .month_invs table thead tr th, .month_invs table tbody tr td {
        font-size: 14px;
    }

    /* 下拉框 */
    .el-select-dropdown__wrap {
        background-color: #f5f5f5;
    }

    .el-select-dropdown__empty {
        background-color: #f5f5f5;
        color: #40404e;
    }

    .el-select-dropdown__item.selected {
        background-color: #e5e5e5;
    }

    .el-select__popper.el-popper[role="tooltip"] {
        border: 1px solid #f5f5f5;
    }

    .el-select__popper.el-popper[role="tooltip"][data-popper-placement^="bottom"] .el-popper__arrow::before {
        border: 1px solid #f5f5f5;
        background-color: #f5f5f5;
    }

    .el-select-dropdown__item.hover, .el-select-dropdown__item:hover {
        background-color: #e5e5e5;
    }

    .el-select-dropdown__item.selected {
        color: #40404e;
    }

    .el-select-dropdown__item {
        color: #40404E
    }

    .el-select-dropdown {
        border: 1px solid #f5f5f5;
    }

    .xdownbox {
        display: none;
    }

    .month_invs .meisfgr {
        width: 100%;
        overflow-x: scroll !important;
    }

    .month_invs .tiaodd {
        position: sticky;
        left: 0;
        top: 44px;
        width: 100% !important;
        display: inline-block;

        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 仓库列表 */
    .month_invs .zhuixiaoi {
        width: 100%;
        border-collapse: collapse;
        overflow-x: auto !important;
        color: #40404e;
    }

    .month_invs .zhuixiaoi .mmodity tr th {
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-weight: 600;
        padding-left: 20px;
    }

    .month_invs .zhuixiaoi .limiting .drag-list td {
        height: 36px;
        line-height: 36px;
        text-align: left;
        white-space: normal;
        word-break: break-all;
        font-weight: 400;
        padding-left: 20px;
    }

    .month_invs .zhuixiaoi .limiting .drag-list {
        display: block;
        display: flex;
        padding-right: 20px;
        border-bottom: solid 1px #f5f5f5;
    }

    .month_invs .zhuixiaoi .mmodity {
        width: 100%;
        display: block;
    }

    .month_invs .zhuixiaoi .mmodity tr {
        background-color: #f5f5f5;
        padding-right: 20px;
        display: flex;
    }

    .month_invs .zhuixiaoi .limiting {
        border-bottom: solid 1px #f5f5f5;
        overflow-y: auto !important;
        max-height: 540px;
        display: block;
    }

    .month_invs .drag-list td:nth-of-type(1), .month_invs .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .month_invs .mmodity th:nth-of-type(2), .month_invs .drag-list td:nth-of-type(2) {
        width: 100px;
    }

    .month_invs .drag-list td:nth-of-type(3), .month_invs .mmodity th:nth-of-type(3) {
        width: 150px;
    }

    .month_invs .drag-list td:nth-of-type(4), .month_invs .mmodity th:nth-of-type(4) {
        width: 100px;
    }

    .month_invs .drag-list td:nth-of-type(5), .month_invs .mmodity th:nth-of-type(5) {
        width: 120px;
    }

    .month_invs .drag-list td:nth-of-type(6), .month_invs .mmodity th:nth-of-type(6) {
        width: 120px;
    }

    .month_invs .drag-list td:nth-of-type(7), .month_invs .mmodity th:nth-of-type(7) {
        width: 120px;
    }

    .month_invs .drag-list td:nth-of-type(8), .month_invs .mmodity th:nth-of-type(8) {
        width: 120px;
    }

    .month_invs .drag-list td:nth-of-type(9), .month_invs .mmodity th:nth-of-type(9) {
        width: 120px;
    }

    .month_invs .drag-list td:nth-of-type(10), .month_invs .mmodity th:nth-of-type(10) {
        width: 120px;
    }

    .month_invs .drag-list td:nth-of-type(11), .month_invs .mmodity th:nth-of-type(11) {
        width: 120px;
    }

    .month_invs .drag-list td:nth-of-type(12), .month_invs .mmodity th:nth-of-type(12) {
        width: 120px;
    }

    .month_invs .drag-list td:nth-of-type(13), .month_invs .mmodity th:nth-of-type(13) {
        width: 120px;
    }

    .month_invs .drag-list td:nth-of-type(14), .month_invs .mmodity th:nth-of-type(14) {
        width: 120px;
    }

    .month_invs .drag-list td:nth-of-type(15), .month_invs .mmodity th:nth-of-type(15) {
        width: 120px;
    }

    .month_invs .drag-list td:nth-of-type(16), .month_invs .mmodity th:nth-of-type(16) {
        width: 120px;
    }

    .month_invs .drag-list:nth-of-type(odd) {
        background-color: #f9f9f9;
        color: #40404e;
    }

    .month_invs .drag-list:nth-of-type(even) {
        background-color: #f5f5f5;
        color: #40404e;
    }

    .month_invs .zhuixiaoi .el-checkbox__label {
        color: #40404e;
    }

    /*  */
    .month_invs .zhuixiaoi .chaoguogai {
        height: 20px;
        /* text-align: center; */
        line-height: 20px;
        width: 136px;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    /* 日期选择器 */
    .month_invs .month_invs-rkrq .rkrq .el-range-editor .el-range-input {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
    }

    .month_invs .month_invs-rkrq .rkrq .el-date-editor .el-range-separator, .month_invs .month_invs-rkrq .rkrq .el-date-editor .el-range__icon {
        color: #40404e;
        line-height: 22px;
    }

    .el-picker-panel {
        background-color: #1A1A20;
    }

    /* 年月日 */
    .el-date-range-picker__header {
        color: #40404e;
    }

    /* 加减年月  */
    .el-icon-d-arrow-left, .el-icon-arrow-left, .el-icon-d-arrow-right, .el-icon-arrow-right {
        color: #40404e;
    }

    .el-date-table tbody tr th {
        color: #40404e;
    }

    .el-date-table td.next-month, .el-date-table td.prev-month {
        color: #77797c;
    }

    .el-picker-panel {
        color: #40404e;
    }

    .in-range {
        color: #000;
    }

    .el-date-table td.in-range div {
        background-color: #F2F6FC;
    }

    .el-input__icon{
        line-height: 30px;
    }

    .out_sum .el-input {
        width: 190px;
    }

    .el-button{
        font-size: 13px;
        line-height: 14px;
        padding: 8px 20px;
        height:30px;
    }

    .el-range-editor.el-input__inner{
        width: 287px;
        height: 30px;
        line-height: 30px;
    }

    .el-date-editor .el-range__close-icon{
        line-height: 22px;
    }

</style>

