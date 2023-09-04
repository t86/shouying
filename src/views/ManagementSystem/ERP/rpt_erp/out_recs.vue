<template>
    <div class="out_recs">
        <div class="out_recs-rkrq">
            <div class="rkrq">
                <span class="">入库日期：</span>
                <el-radio-group v-model="jindst" class="danxk">
                    <el-radio-button label="1">
                        <img v-show="jindst != 1" src="@/assets/img/date_label_grey.png" alt="">
                        <img v-show="jindst == 1" src="@/assets/img/date_label_selete.png" alt="">
                        近七天
                    </el-radio-button>
                    <el-radio-button label="2">
                        <img v-show="jindst != 2" src="@/assets/img/date_label_grey.png" alt="">
                        <img v-show="jindst == 2" src="@/assets/img/date_label_selete.png" alt="">
                        近1个月
                    </el-radio-button>
                    <el-radio-button label="3">
                        <img v-show="jindst != 3" src="@/assets/img/date_label_grey.png" alt="">
                        <img v-show="jindst == 3" src="@/assets/img/date_label_selete.png" alt="">
                        近3个月
                    </el-radio-button>
                </el-radio-group>
                <el-date-picker
                        v-model="Inbound.date"
                        type="daterange"
                        :editable="false"
                        :unlink-panels="true"
                        @input="adgg"
                        range-separator="至"
                        start-placeholder="开始日期"
                        end-placeholder="结束日期"
                        format="yyyy-MM-dd"
                        value-format="yyyy-MM-dd">
                </el-date-picker>
            </div>
            <div class="rkrq">
                <span>出库仓库：</span>
                <el-select v-model="Inbound.ckid" @change="demand" placeholder="全部" clearable>
                    <el-option label="全部" value="0"></el-option>
                    <el-option v-for="(item) in stores" :key="item.id" :label="item.n" :value="item.id"></el-option>
                </el-select>
            </div>
            <div class="rkrq">
                <span>订单类型：</span>
                <el-select v-model="Inbound.type" @change="demand" placeholder="全部" clearable>
                    <el-option label="全部" value="0"></el-option>
                    <el-option label="销售出库" value="11"></el-option>
                    <el-option label="调拨出库" value="3"></el-option>
                    <el-option label="其他出库" value="17"></el-option>
                </el-select>
            </div>
            <div class="rkrq">
                <span>一级分类：</span>
                <el-select v-model="stair" @change="demand" placeholder="全部" clearable>
                    <el-option label="全部" value="0"></el-option>
                    <el-option v-for="(item) in cates" :key="item.id" :label="item.n" :value="item.id"></el-option>
                </el-select>
            </div>
            <div class="rkrq">
                <span>二级分类：</span>
                <el-select v-model="twin" @change="demand" placeholder="全部" clearable>
                    <el-option label="全部" value="0"></el-option>
                    <el-option v-for="(item) in cateser" :key="item.id" :label="item.n" :value="item.id"></el-option>
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
            <div class="meisfgr" id="allexportareport" style="display: inline-block;">
                <table class="zhuixiaoi">
                    <thead class="mmodity">
                    <tr>
                        <th>序号</th>
                        <th>出库日期</th>
                        <th>订单类型</th>
                        <th>出库仓库</th>
                        <th>物料名称</th>
                        <th>入库仓库</th>
                        <th>出库单号</th>
                        <th>一级分类</th>
                        <th>二级分类</th>
                        <th>出库类型</th>
                        <th>出库单位</th>
                        <th>
                            <div class="alignment">出库数量</div>
                        </th>
                        <th>
                            <div class="alignment">出库成本单价</div>
                        </th>
                        <th>
                            <div class="alignment">出库成本小计</div>
                        </th>
                        <th>
                            <div class="alignment">出库单价</div>
                        </th>
                        <th>
                            <div class="alignment">出库小计</div>
                        </th>
                        <th>出库操作人</th>
                    </tr>
                    </thead>
                    <tbody class="limiting" ref="systemForm" @scroll="sysHandleScroll()"
                           @mouseover="changeFlag(false)" :style="{'border-bottom':tableData.length<1?'0px':'',
                    'width':tableData.length>13?'calc(100% + 6px)':'100%',
                    'max-height':`${MaxHeight}px`
                    }">
                    <tr v-for="(item,i) in tableData" :key="i" class="drag-list">
                        <td>{{i+1}}</td>
                        <td>{{item.ost}}</td>
                        <td>
                            <ellipsis-tooltip :text="item.rt || '---'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.osn || '---'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.n || '---'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.isn || '---'"></ellipsis-tooltip>
                        </td>
                        <td>{{item.c}}</td>
                        <td>
                            <ellipsis-tooltip :text="item.moc || '---'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.mtc || '---'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.ot || '---'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.un || '---'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <div class="alignment">{{item.oc}}</div>
                        </td>
                        <td>
                            <div class="alignment">{{item.op}}</div>
                        </td>
                        <td>
                            <div class="alignment">{{item.oa}}</div>
                        </td>
                        <td>
                            <div class="alignment">{{item.sp}}</div>
                        </td>
                        <td>
                            <div class="alignment">{{item.sa}}</div>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.oon || '---'"></ellipsis-tooltip>
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
            <div style="display: inline-block;position: absolute;top: 0;left: 0;z-index: 100;">
                <table class="zhuixiaoi zhuixiaoi_l" style="width: auto;">
                    <thead class="mmodity">
                    <tr>
                        <th>序号</th>
                        <th>出库日期</th>
                        <th>订单类型</th>
                        <th>出库仓库</th>
                        <th>物料名称</th>
                    </tr>
                    </thead>
                    <tbody class="limiting" ref="externalForm" @scroll="exterHandleScroll()"
                           @mouseover="changeFlag(true)" :style="{'border-bottom':tableData.length<1?'0px':'',
                    'width':tableData.length>13?'calc(100% + 6px)':'100%',
                    'max-height':`${MaxHeight}px`
                    }">
                    <tr v-for="(item,i) in tableData" :key="i" class="drag-list">
                        <td>{{i+1}}</td>
                        <td>{{item.ost}}</td>
                        <td>
                            <ellipsis-tooltip :text="item.rt || '---'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.osn || '---'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.n || '---'"></ellipsis-tooltip>
                        </td>
                    </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <div class="Pagination">
            <el-pagination
                    background
                    layout="prev, pager, next"
                    @current-change="handleCurrentChange"
                    :page-size="10"
                    :total="Inbound.rowcnt">
            </el-pagination>
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
        date: [],//日期
        ckid: '',//仓库id
        type: '',//订单
        namse: '',//内容
        pagenum: 1,//第几页
        pagecnt: 1,//总页数
        rowcnt: 1,//总行数
      },//出库
      stair: '',//一级
      twin: '',//二级
      stores: [],//仓库列表
      cates: [],// 一级分类列表
      cateser: [],//二级
      tableData: [],// 读取管理列表

      jindst: '1',
      windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
      MaxHeight: 0,//滚动高度
      MaxNumber: 0,//最大个数

      flag: false
    }
  },
  mounted(){
    this.$api.ERP.rpt_erp.requestrpt_erpparam_items().then(res => {
      console.log(res.data.cates);
      if (res.code == 1) {
        this.stores = res.data.stores
        this.cates = res.data.cates
      } else {
        this.$message.warning(res.msg)
      }
    })
    this.daterq();
    this.demand();
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
      var g = document.getElementsByClassName("out_recs-rkrq")[0].clientHeight;
      var s = i - 48 - 60 - 90 - g;
      this.MaxHeight = s
      this.MaxNumber = Math.floor(s / 37)
      console.log(this.MaxNumber);
      // console.log(i);
    },
    // 获取管理列表内容
    demand(){
      this.$api.ERP.rpt_erp.requestrpt_erpout_recs({
        page_num: this.Inbound.pagenum,
        page_size: 10,
        begin_day: this.Inbound.date[0],
        end_day: this.Inbound.date[1],
        store_id: this.Inbound.ckid || 0,
        record_type: Number(this.Inbound.type || 0),
        mat_one_cate_id: this.stair || 0,
        mat_two_cate_id: this.twin || 0,
        name: this.Inbound.namse,
      }).then(res => {
        console.log(res);
        if (res.code == 1) {
          this.tableData = res.data.datas || []
          this.Inbound.pagecnt = res.data.page_cnt
          this.Inbound.rowcnt = res.data.row_cnt
          this.Inbound.pagenum = res.data.page_num
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 使用自定义日期后取消单选框选择的
    adgg(i){
      console.log(i);
      this.jindst = ''
      this.demand()
    },
    // 日期
    daterq(){
      var now = new Date()
      var year = now.getFullYear()//年
      var month = (now.getMonth() + 1).toString().padStart(2, '0')//月
      var date = now.getDate().toString().padStart(2, '0');//日
      // var dangy = new Date(year,month,0).getDate()//当月有多少天
      // this.Inbound.date = [`${year}-${month}-01`,`${year}-${month}-${dangy}`]
      // 7天
      var now7 = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
      var year7 = now7.getFullYear()//年
      var month7 = (now7.getMonth() + 1).toString().padStart(2, '0')//月
      var date7 = now7.getDate().toString().padStart(2, '0');//日
      this.Inbound.date = [`${year7}-${month7}-${date7}`, `${year}-${month}-${date}`]
    },
    // 当前是多少页
    handleCurrentChange(val) {
      // console.log(`当前页: ${val}`);
      this.Inbound.pagenum = val
      this.demand()
    },
    // 重置
    resetstorage(){
      this.jindst = '1'
      this.Inbound.date = []
      this.Inbound.type = ''
      this.Inbound.ckid = ''
      this.Inbound.namse = ''
      this.Inbound.pagenum = 1
      this.Inbound.pagecnt = 1
      this.Inbound.rowcnt = 1
      this.tableData = []
      this.stair = ''
      this.twin = ''
      this.cateser = []
      this.daterq()
      this.demand();
    },
    // 导出Excel
    deriveExcel(){
      if (this.tableData.length > 0) {
        // 文件名
        const filename = '出库明细表.xlsx'
        // 获取表格元
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
    // 设置日期
    jindst: {
      deep: true,
      handler: function (after, before) {
        // console.log(after);
        var now = new Date()
        var year = now.getFullYear()//年
        var month = (now.getMonth() + 1).toString().padStart(2, '0')//月
        var date = now.getDate().toString().padStart(2, '0');//日
        // console.log(now.getTime());
        if (after == 1) {// 7天
          this.daterq()
          this.demand()
        } else if (after == 2) {//一个月
          // console.log(now.setMonth(now.getMonth()-1));
          now.setMonth(now.getMonth() - 1)
          var now1 = new Date(now.setMonth(now.getMonth() - 1 + 1))
          var year1 = now1.getFullYear()//年
          var month1 = (now1.getMonth() + 1).toString().padStart(2, '0')//月
          var date1 = now1.getDate().toString().padStart(2, '0');//日
          this.Inbound.date = [`${year1}-${month1}-${date1}`, `${year}-${month}-${date}`]
          this.demand()
        } else if (after == 3) {//3个月
          // console.log(now.setMonth(now.getMonth()-3));
          now.setMonth(now.getMonth() - 3)
          var now3 = new Date(now.setMonth(now.getMonth() - 1 + 1))
          var year3 = now3.getFullYear()//年
          var month3 = (now3.getMonth() + 1).toString().padStart(2, '0')//月
          var date3 = now3.getDate().toString().padStart(2, '0');//日
          this.Inbound.date = [`${year3}-${month3}-${date3}`, `${year}-${month}-${date}`]
          this.demand()
        }
      }
    },
    stair: function (i, f) {
      // console.log(i);
      this.twin = ''
      for (const key of this.cates) {
        // console.log(key);
        if (key.id == i) {
          this.cateser = key.ss || []
        }
      }
    }
  }

}
</script>
<style>
    .out_recs {
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding: 20px 30px;
    }

    /* 表格内文字居中 */
    .out_recs .alignment {
        text-align: right !important;
        padding-right: 15px;
    }

    /* 表格无数据时展示 */
    .out_recs .nodata {
        width: 100% !important;
        /*height: 250px !important;*/
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
    }

    .out_recs .nodata img {
        width: 60px;
        height: 60px;
    }

    .out_recs .nodata .hint {
        line-height: 40px;
        font-size: 13px !important;
    }

    .out_recs .tiaodd {
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

    .out_recs .out_recs-headline {
        font-size: 30px;
        font-weight: bold;
        color: #40404e;
    }

    .out_recs .out_recs-controller {
        margin-top: 20px;
        margin-bottom: 30px;
    }

    .out_recs .out_recs-rkrq {
        width: 100%;
        color: #40404e;
        overflow: hidden;
        font-size: 13px;
        line-height: 14px;
    }

    .out_recs .out_recs-rkrq .rkrq {
        display: inline-flex;
        align-items: center;
        margin: 0 0 14px 0;
    }

    .out_recs .out_recs-rkrq .rkrq:nth-child(1) {
        width: 670px !important;
    }

    .out_recs .out_recs-rkrq .rkrq:nth-child(2) {
        width: 275px !important;
    }

    .out_recs .out_recs-rkrq .rkrq:nth-child(3) {
        width: 275px !important;
    }

    .out_recs .out_recs-rkrq .rkrq:nth-child(4) {
        width: 275px !important;
    }

    .out_recs .out_recs-rkrq .rkrq:nth-child(5) {
        width: 275px !important;
    }

    .out_recs .out_recs-rkrq .rkrq:nth-child(6) {
        width: 190px !important;
        margin-right: 10px;
    }

    .out_recs .out_recs-rkrq .rkrq:nth-child(7) {
        width: 255px !important;
    }

    .out_recs .out_recs-rkrq .rkrq .danxk {
        height: 34px;
        margin-right: 10px;
        display: inline-flex;
        align-items: center;
    }

    .out_recs .out_recs-rkrq .rkrq .danxk img {
        display: inline-block;
        width: 12px;
        height: 12px;
        margin-right: 6px;
    }

    .out_recs .out_recs-rkrq .rkrq .danxk .el-radio-button {
        margin: 0 4px;
        box-shadow: none !important;
    }

    .out_recs .out_recs-rkrq .rkrq .danxk .el-radio-button__inner {
        border-radius: 19px !important;
        border: 0px !important;
        background-color: transparent;
        color: #40404e;
        font-size: 12px;
        display: flex;
        align-items: center;
        line-height: 16px;
        padding: 5px 15px;
    }

    .out_recs .out_recs-rkrq .rkrq .danxk .el-radio-button__orig-radio:checked + .el-radio-button__inner {
        background-color: transparent !important;
        color: #2170ff;
        box-shadow: none;
    }

    .el-month-table td .cell, .el-date-picker__header-label {
        color: #40404e;
    }

    .out_recs .el-date-editor.el-input {
        width: 220px;
    }

    .out_recs .ewdetai {
        color: #438dfd;
    }

    .out_recs .AddPrincipal {
        color: #4eadfc
    }

    .out_recs .compatibil {
        margin-bottom: 10px;
    }

    .out_recs .el-input__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
        height: 30px;
        line-height: 30px;
    }

    .out_recs .el-input {
        width: 190px;
    }

    .out_recs .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    .out_recs .has-gutter {
        border: 1px solid #f5f5f5;
    }

    .out_recs table thead tr th, .out_recs table tbody tr td {
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

    .out_recs .meisfgr {
        width: 100%;
        overflow-x: scroll !important;
    }

    /* 仓库列表 */
    .out_recs .zhuixiaoi {
        width: 100%;
        border-collapse: collapse;
        color: #40404e;
    }

    .out_recs .zhuixiaoi .mmodity tr th {
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-weight: 600;
        padding-left: 20px;
    }

    .out_recs .zhuixiaoi .limiting .drag-list td {
        height: 36px;
        line-height: 36px;
        text-align: left;
        white-space: normal;
        word-break: break-all;
        padding-left: 20px;
        font-weight: 400;
    }

    .out_recs .zhuixiaoi .limiting .drag-list {
        border-top: solid 1px #f5f5f5;
        display: block;
        /* width: calc(100% - 17px); */
        display: flex;
    }

    .out_recs .zhuixiaoi .mmodity {
        width: 100%;
        display: block;
    }

    .out_recs .zhuixiaoi .mmodity tr {
        background-color: #f5f5f5;
        display: flex;
    }

    .out_recs .zhuixiaoi .limiting {
        border-bottom: solid 1px #f5f5f5;
        overflow-y: auto !important;
        max-height: 540px;
        display: block;
    }

    .out_recs .drag-list td:nth-of-type(1), .out_recs .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .out_recs .mmodity th:nth-of-type(2), .out_recs .drag-list td:nth-of-type(2) {
        width: 130px;
    }

    .out_recs .drag-list td:nth-of-type(3), .out_recs .mmodity th:nth-of-type(3) {
        width: 100px;
    }

    .out_recs .drag-list td:nth-of-type(4), .out_recs .mmodity th:nth-of-type(4) {
        width: 100px;
    }

    .out_recs .drag-list td:nth-of-type(5), .out_recs .mmodity th:nth-of-type(5) {
        width: 100px;
    }

    .out_recs .drag-list td:nth-of-type(6), .out_recs .mmodity th:nth-of-type(6) {
        width: 100px;
    }

    .out_recs .drag-list td:nth-of-type(7), .out_recs .mmodity th:nth-of-type(7) {
        width: 100px;
    }

    .out_recs .drag-list td:nth-of-type(8), .out_recs .mmodity th:nth-of-type(8) {
        width: 150px;
    }

    .out_recs .drag-list td:nth-of-type(9), .out_recs .mmodity th:nth-of-type(9) {
        width: 150px;
    }

    .out_recs .drag-list td:nth-of-type(10), .out_recs .mmodity th:nth-of-type(10) {
        width: 100px;
    }

    .out_recs .drag-list td:nth-of-type(11), .out_recs .mmodity th:nth-of-type(11) {
        width: 100px;
    }

    .out_recs .drag-list td:nth-of-type(12), .out_recs .mmodity th:nth-of-type(12) {
        width: 100px;
    }

    .out_recs .drag-list td:nth-of-type(13), .out_recs .mmodity th:nth-of-type(13) {
        width: 120px;
    }

    .out_recs .drag-list td:nth-of-type(14), .out_recs .mmodity th:nth-of-type(14) {
        width: 120px;
    }

    .out_recs .drag-list td:nth-of-type(15), .out_recs .mmodity th:nth-of-type(15) {
        width: 120px;
    }

    .out_recs .drag-list td:nth-of-type(16), .out_recs .mmodity th:nth-of-type(16) {
        width: 100px;
    }

    .out_recs .drag-list td:nth-of-type(17), .out_recs .mmodity th:nth-of-type(17) {
        width: 130px;
    }

    .out_recs .drag-list:nth-of-type(odd) {
        background-color: #f9f9f9;
        color: #40404e;
    }

    .out_recs .drag-list:nth-of-type(even) {
        background-color: #f5f5f5;
        color: #40404e;
    }

    .out_recs .zhuixiaoi .el-checkbox__label {
        color: #40404e;
    }

    /*  */
    .out_recs .zhuixiaoi .chaoguogai {
        height: 20px;
        /* text-align: center; */
        line-height: 20px;
        width: 136px;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    /* 日期选择器 */
    .out_recs .out_recs-rkrq .rkrq .el-range-editor .el-range-input {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
    }

    .out_recs .out_recs-rkrq .rkrq .el-date-editor .el-range-separator, .out_recs .out_recs-rkrq .rkrq .el-date-editor .el-range__icon {
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

    /* 分页 */
    .out_recs .Pagination {
        /* width: 1093px; */
        text-align: right;
        margin-top: 20px;
    }

    .out_recs .Pagination .el-pagination.is-background .btn-next, .out_recs .Pagination .el-pagination.is-background .btn-prev, .out_recs .Pagination .el-pagination.is-background .el-pager li {
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #606266;
        color: #40404e;
    }

    .out_recs .Pagination .btn-prev {
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #606266;
    }

    .out_recs .Pagination .el-pagination {
        padding: 0;
    }

    .out_recs .Pagination .el-pagination .btn-next .el-icon, .out_recs .Pagination .el-pagination .btn-prev .el-icon {
        color: #40404e;
    }

    .out_recs .Pagination .el-pagination.is-background .el-pager li:not(.disabled).active {
        color: #409EFF;
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #409EFF;
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

