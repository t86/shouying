<template>
    <div class="d_yy">
        <div class="stairfl">
            <div>状&emsp;&emsp;态：</div>
            <div class="stairastrict">
                <el-radio-group v-model="Inbound.state" class="container">
                    <el-radio-button label="0">全部</el-radio-button>
                    <el-radio-button label="3">待处理</el-radio-button>
                    <el-radio-button label="2">已处理</el-radio-button>
                    <el-radio-button label="1">已完成</el-radio-button>
                </el-radio-group>
            </div>
        </div>
        <div class="d_yy-rkrq">
            <div class="rkrq">
                <span class="">操作时间：</span>
                <el-date-picker
                        v-model="Inbound.date"
                        type="daterange"
                        :editable="false"
                        :unlink-panels="true"
                        @change="demand"
                        range-separator="至"
                        start-placeholder="开始日期"
                        end-placeholder="结束日期"
                        format="yyyy-MM-dd"
                        value-format="yyyy-MM-dd">
                </el-date-picker>
            </div>
            <div class="rkrq">
                <!-- <el-button type="primary" @click="demand">查询</el-button> -->
                <el-button type="primary" @click="resetstorage">重置</el-button>
            </div>
        </div>
        <div style="position: relative">
            <div class="meisfgr" style="display: inline-block;">
                <table class="zhuixiaoi">
                    <thead class="mmodity">
                    <tr>
                        <th>序号</th>
                        <th>单号</th>
                        <th>子单号</th>
                        <th>物料名称</th>
                        <th>一级分类</th>
                        <th>二级分类</th>
                        <th>出库单位</th>
                        <th>
                            <div class="alignment">出库数量</div>
                        </th>
                        <th>
                            <div class="alignment">异议数量</div>
                        </th>
                        <th>备注</th>
                        <th>状态</th>
                        <th>出库仓库</th>
                        <th>出库操作人</th>
                        <th>入库仓库</th>
                        <th>出库日期</th>
                    </tr>
                    </thead>
                    <tbody class="limiting" ref="systemForm" @scroll="sysHandleScroll()"
                           @mouseover="changeFlag(false)" :style="{'border-bottom':tableData.length<1?'0px':'',
                'width':tableData.length>13?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`
                }">
                    <tr v-for="(item,i) in tableData" :key="item.id" class="drag-list">
                        <td>{{i+1}}</td>
                        <td>{{item.cd}}</td>
                        <td>
                            <div class="ewdetai" @click="compileprinter(item.id,item)">
                                {{item.id}}
                            </div>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.n || '----'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.moc || '----'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.mtc || '----'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.un || '----'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <div class="alignment">{{item.c}}</div>
                        </td>
                        <td>
                            <div class="alignment">{{item.yc}}</div>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.r || '----'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.s || '----'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.osn || '----'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.oen || '----'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.isn || '----'"></ellipsis-tooltip>
                        </td>
                        <td>{{item.ost}}</td>
                    </tr>
                    </tbody>
                </table>
                <div class="tiaodd" v-if="tableData.length<1">
                    <td class="nodata" :style="{'height':`${MaxHeight}px !important`}">
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
                        <th>单号</th>
                        <th>子单号</th>
                        <th>物料名称</th>
                    </tr>
                    </thead>
                    <tbody class="limiting" ref="externalForm" @scroll="exterHandleScroll()"
                           @mouseover="changeFlag(true)" :style="{'border-bottom':tableData.length<1?'0px':'',
                'width':tableData.length>13?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`
                }">
                    <tr v-for="(item,i) in tableData" :key="item.id" class="drag-list">
                        <td>{{i+1}}</td>
                        <td>{{item.cd}}</td>
                        <td>
                            <div class="ewdetai" @click="compileprinter(item.id,item)">
                                {{item.id}}
                            </div>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.n || '----'"></ellipsis-tooltip>
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
                    :page-size="Inbound.jlines"
                    :total="Inbound.rowcnt">
            </el-pagination>
        </div>


        <!-- 驳回 -->
        <div v-show="dialogFormVisible" class="dialogFormVisible">
            <el-dialog title="驳回" :visible.sync="dialogFormVisible" @close="dialogFormVisible = false"
                       :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>驳回原因：
                        </div>
                        <el-input type="textarea" class="controlling" v-model="reject" :rows="3" ref="selectsse"
                                  placeholder="驳回原因" show-word-limit
                                  :class="form_rule_msg_reject?'error':''" @blur="validator('reject')"/>
                        <div class="cwts">{{form_rule_msg_reject}}</div>
                    </div>
                </el-form>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFormVisible = false">取消</el-button>
                    <el-button type="primary" @click="construction">确认</el-button>
                </span>
            </el-dialog>
        </div>
        <!-- 详细信息 -->
        <div v-show="cfdetails" class="viewdetailscls">
            <el-dialog title="详细信息" :visible.sync="cfdetails" @close="cfdetails = false" :close-on-click-modal="false">
                <div ref="print" id="print">
                    <div class="printd_yy">
                        <div class="monad">异议订单</div>
                        <span class="nrxx">异议信息：</span>
                        <el-form label-position="left">
                            <div class="tidsesfe">
                                <div class="compatibility">
                                    <div class="mandatory" style="">
                                        <span class="reqfieldsd"></span>单号：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.cd || '---'}}</div>
                                </div>
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>物料名称：
                                    </div>
                                    <div class="materialnr controlling">
                                        <ellipsis-tooltip :text="viewdetails.n || '----'"></ellipsis-tooltip>
                                    </div>
                                </div>
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>一级分类：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.moc || '---'}}</div>
                                </div>
                            </div>
                            <div class="tidsesfe">
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>二级分类：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.mtc || '---'}}</div>
                                </div>
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>出库仓库：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.osn || '---'}}</div>
                                </div>
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>入库仓库：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.isn || '---'}}</div>
                                </div>
                            </div>
                            <div class="tidsesfe">
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>出库数量：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.c+'' || '---'}}</div>
                                </div>
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>异议数量：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.yc }}</div>
                                </div>
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>异议锁定数量：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.lyc }}</div>
                                </div>
                            </div>
                            <div class="tidsesfe">
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>状态：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.s || '---'}}</div>
                                </div>
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>出库时间：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.ost || '---'}}</div>
                                </div>
                            </div>
                            <div class="tidsesfe">
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>备注：
                                    </div>
                                    <div class="materialnr gaib">
                                        <ellipsis-tooltip :text="viewdetails.r || '----'"></ellipsis-tooltip>
                                    </div>
                                </div>
                            </div>

                        </el-form>
                        <span class="nrxx">异议记录：</span>
                        <div class="yyjl">
                            <table class="zhuixiaoi">
                                <thead class="mmodity">
                                <tr>
                                    <th>子单号</th>
                                    <th>名称</th>
                                    <th>一级分类</th>
                                    <th>二级分类</th>
                                    <th>单位</th>
                                    <th>确认数量</th>
                                    <th>确认小计</th>
                                    <th>异议数量</th>
                                    <th>异议小计</th>
                                    <th>异议备注</th>
                                    <th>操作人</th>
                                    <th>操作方</th>
                                    <th>操作时间</th>
                                </tr>
                                </thead>
                                <tbody class="limiting" v-if="viewdeta"
                                       :style="{'width':viewdeta.length>7?'calc(100% + 6px)':'100%'}">
                                <tr v-for="(item,i) in viewdeta" :key="i" class="drag-list">
                                    <td>{{item.id}}</td>
                                    <td>
                                        <ellipsis-tooltip :text="item.n || '----'"></ellipsis-tooltip>
                                    </td>
                                    <td>
                                        <ellipsis-tooltip :text="item.moc || '----'"></ellipsis-tooltip>
                                    </td>
                                    <td>
                                        <ellipsis-tooltip :text="item.mtc || '----'"></ellipsis-tooltip>
                                    </td>
                                    <td>
                                        <ellipsis-tooltip :text="item.un || '----'"></ellipsis-tooltip>
                                    </td>
                                    <td>
                                        <div class="alignment">{{item.dc}}</div>
                                    </td>
                                    <td>
                                        <div class="alignment">{{item.da}}</div>
                                    </td>
                                    <td>
                                        <div class="alignment">{{item.yc}}</div>
                                    </td>
                                    <td>
                                        <div class="alignment">{{item.ya}}</div>
                                    </td>
                                    <td>
                                        <ellipsis-tooltip :text="item.r || '----'"></ellipsis-tooltip>
                                    </td>
                                    <td>
                                        <ellipsis-tooltip :text="item.oen || '----'"></ellipsis-tooltip>
                                    </td>
                                    <td>
                                        <ellipsis-tooltip :text="item.yo || '----'"></ellipsis-tooltip>
                                    </td>
                                    <td>{{item.ot}}</td>
                                </tr>
                                <tr class="drag-list" v-if="viewdeta.length<1">
                                    <td class="nodata">
                                        <img src="../../../../assets/img/wu.png" alt="">
                                        <div class="hint">暂无数据</div>
                                    </td>
                                </tr>
                                </tbody>
                            </table>
                        </div>
                        <div class="signature show">
                            <div>
                                <span>签收人：</span>
                                <div class="xian"></div>
                            </div>
                            <div>
                                <span>送货人：</span>
                                <div class="xian"></div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="ys">
                    <div>说明：</div>
                    <div>1、异议红冲：异议数量直接红冲（适用情形：实际出库8瓶，但出库单数量填写成10瓶）</div>
                    <div>2、异议报损：异议数量自动生成其他出库（报损）单（适用情形：实际出库10瓶，出库单数量也为10瓶，但是有2瓶破损）</div>
                </div>
                <span slot="footer" class="dialog-footer">
                    <el-button type="primary" v-show="viewdetails.status == 1" v-print="print">打印</el-button>
                    <el-button type="primary" v-show="viewdetails.s == '待处理'" @click="manage">异议红冲</el-button>
                    <el-button type="primary" v-show="viewdetails.s == '待处理'" @click="xingh">异议报损</el-button>
                    <el-button type="primary" v-show="viewdetails.s == '待处理'" @click="noneffective">驳回</el-button>
                    <el-button @click="cfdetails = false">关闭</el-button>
                </span>
            </el-dialog>
        </div>
    </div>
</template>
<script>
import EllipsisTooltip from '@/components/EllipsisTooltip.vue'//根据路径导入组件
export default {
  data(){
    return {
      Inbound: {
        date: [],//日期
        state: '3',//类型
        pagenum: 1,//第几页
        pagecnt: 1,//总页数
        rowcnt: 1,//总行数
        jlines: 10,//每页多少行
      },//出库
      tableData: [],// 读取管理列表
      reject: '',//驳回原因
      viewdetails: {},//查看详情内容
      viewdeta: [],//异议流水列表
      multipleSelection: [],// 操作哪个单子

      cfdetails: false,// 控制详情显示与否
      dialogFormVisible: false,//控制驳回是否显示
      print: {
        id: 'print',
        popTitle: '异议订单', // 打印配置页上方标题
        // extraHead: '调拨入库单',
      },
      windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
      MaxHeight: 0,//滚动高度
      MaxNumber: 0,//最大个数

      form_rules: ["reject"],
      form_rule_msg_reject: "",

      flag: false
    }
  },
  mounted(){
    this.daterq()
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
  computed: {},
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
    // form表单检测
    validator(val){
      switch (val) {
        case "reject":
          if (this.$overall.character(this.reject) > 280) {
            this.form_rule_msg_reject = '输入文字长度超过140'
          } else {
            this.form_rule_msg_reject = ''
          }
          break
      }
    }
    ,
// 滚动最大高度
    RollMaxHeight(i)
    {
      var g = document.getElementsByClassName("d_yy-rkrq")[0].clientHeight;
      var s = i - 48 - 60 - 55 - 40 - 50 - g;
      this.MaxHeight = s
      this.MaxNumber = Math.floor(s / 37)
      console.log(this.MaxNumber);
      // console.log(i);
    }
    ,
// 打印
    Print()
    {
      myPrint(this.$refs.print);
      function myPrint(obj) {
        newWindow.print();
      }
    }
    ,
// 日期
    daterq()
    {
      var now = new Date()
      var year = now.getFullYear()//年
      var month = (now.getMonth() + 1).toString().padStart(2, '0')//月
      var date = now.getDate().toString().padStart(2, '0');//日
      var dangy = new Date(year, month, 0).getDate()//当月有多少天
      this.Inbound.date = [`${year}-${month}-01`, `${year}-${month}-${dangy}`]
    }
    ,
// 获取管理列表内容  查询
    demand()
    {
      this.$api.ERP.soutdd_yy.requestd_yyout_list({
        page_num: this.Inbound.pagenum,
        page_size: this.Inbound.jlines,
        status: Number(this.Inbound.state),
        begin_day: this.Inbound.date[0],
        end_day: this.Inbound.date[1]
      }).then(res => {
        console.log(res);
        if (res.code == 1) {
          this.tableData = res.data.datas || []
          this.Inbound.pagecnt = res.data.page_cnt
          this.Inbound.rowcnt = res.data.row_cnt
          this.Inbound.pagenum = res.data.page_num
          this.multipleSelection = []
          this.isIndeterminate = false
          this.checkAll = false
        } else {
          this.$message.warning(res.msg)
        }
      })
    }
    ,
// 当前是多少页
    handleCurrentChange(val)
    {
      // console.log(`当前页: ${val}`);
      this.Inbound.pagenum = val
      this.demand()
    }
    ,
// 重置
    resetstorage()
    {
      this.Inbound.date = []
      this.Inbound.state = '3'
      this.Inbound.pagenum = 1
      this.Inbound.pagecnt = 1
      this.Inbound.rowcnt = 1
      this.demand()
      this.daterq()
    }
    ,
// 打开驳回
    noneffective(){
      this.form_rule_msg_reject = '';
      this.dialogFormVisible = true
      this.reject = ''
      this.$nextTick(() => {  //次要代码
        this.$refs.selectsse.focus();
      })
    }
    ,
// 驳回
    construction(){
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_reject) return;
      this.$api.ERP.soutdd_yy.requestd_yyout_back({
        id: this.multipleSelection[0],
        remark: this.reject
      }).then(res => {
        if (res.code == 1) {
          this.demand()
          this.dialogFormVisible = false
          this.cfdetails = false
          this.$message({
            showClose: true,
            message: "操作成功",
            type: 'success'
          })
        } else {
          this.$message.warning(res.msg)
        }
      })
    }
    ,
// 打开处理
    compileprinter(id, item)
    {
      this.viewdetails = item || {}
      this.multipleSelection = [id]
      this.$api.ERP.soutdd_yy.req_out_yy_dtls({id}).then(res => {
        this.viewdeta = res.data.records || []
        this.cfdetails = true
      })
    }
    ,
// 异议红冲
    manage()
    {
      this.$api.ERP.soutdd_yy.requestd_yyout_hc({id: this.multipleSelection[0]}).then(res => {
        if (res.code == 1) {
          this.cfdetails = false
          this.$message({
            showClose: true,
            message: "操作成功",
            type: 'success'
          })
          this.demand()
        } else {
          this.$message.warning(res.msg)
        }
      })
    }
    ,
// 异议报损
    xingh()
    {
      this.$api.ERP.soutdd_yy.requestd_yyout_bs({id: this.multipleSelection[0]}).then(res => {
        if (res.code == 1) {
          this.cfdetails = false
          this.$message({
            showClose: true,
            message: "操作成功",
            type: 'success'
          })
          this.demand()
        } else {
          this.$message.warning(res.msg)
        }
      })

    }
    ,
  },
  computed: {
    Inboundstate()
    {
      return JSON.parse(JSON.stringify(this.Inbound.state))
    }
    ,
  }
  ,
  watch: {
    windowHeigh(val)
    {
      let that = this;
      this.RollMaxHeight(val)
      //   console.log("实时屏幕高度：",val, that.windowHeigh );
    }
    ,
    windowWidt(val)
    {
      let that = this;
      this.RollMaxHeight(that.windowHeigh)
      //   console.log("实时屏幕宽度：",val, that.windowWidt );
    }
    ,
    Inboundstate: {
      deep: true,
      handler: function (after, before) {
        this.demand()
      }
    }
  }

}
</script>
<style>
    /* 靠右 */
    .d_yy .el-dialog {
        margin: 0px 0px 0px auto !important;
        background-color: #f9f9f9;
        height: 100%;
        position: relative;
    }

    .d_yy .el-dialog__footer {
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }

    .d_yy .el-dialog__body {
        padding: 0px 20px 30px 20px;
        overflow-y: scroll !important;
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;
    }

    .d_yy .el-dialog {
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .d_yy {
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding: 20px 30px;
    }

    .d_yy .gaib {
        width: 500px !important;
        display: flex;
        align-items: center;
    }

    .monad, .show {
        display: none;
    }

    /* 必填 */
    .d_yy .mandatory {
        color: #40404e;
        width: 140px;
        text-align: right;
        /* padding-top: 10px; */
        line-height: 40px;
    }

    .d_yy .controlling {
        width: 230px !important;
        line-height: 40px;
    }

    .d_yy .reqfieldsd {
        font-size: 14px;
        padding-right: 4px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 表格内文字右对齐 */
    .d_yy .alignment {
        text-align: right !important;
        padding-right: 15px;
    }

    /* 表格无数据时展示 */
    .d_yy .nodata {
        /* border-left:solid 1px #383943; */
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
    }

    .d_yy .nodata img {
        width: 60px;
        height: 60px;
    }

    .d_yy .nodata .hint {
        font-size: 13px !important;
    }

    /* 没内容时，固定展示无数据 */
    .d_yy .meisfgr {
        position: relative;
    }

    .d_yy .tiaodd {
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

    /* 红冲处理 报损处理 */
    .apply {
        margin-top: 30px;
        font-size: 20px;
        color: #40404e;
    }

    /* 全选字体大小 */
    .d_yy .zhuixiaoi .mmodity .el-checkbox__label {
        font-size: 12px;
    }

    /* 给一级分类二级分类加外边距和圆角 */
    .d_yy .el-radio-button {
        margin-right: 6px;
        margin-bottom: 6px;
        height: 30px;
    }

    .d_yy .el-radio-button__inner {
        border-radius: 4px !important;
        padding: 6px 20px;
    }

    /* 去除瑕疵 */
    .d_yy .el-radio-button__orig-radio:checked + .el-radio-button__inner {
        box-shadow: none
    }

    /* 选中状态颜色背景边框 */
    .d_yy .el-radio-button__orig-radio:checked + .el-radio-button__inner {
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #6A9EFF !important;
        color: #6A9EFF;
    }

    .d_yy .d_yy-headline {
        font-size: 30px;
        font-weight: bold;
        color: #40404e;
    }

    .d_yy .d_yy-controller {
        margin-top: 20px;
        margin-bottom: 30px;
    }

    .d_yy .d_yy-rkrq {
        width: 100%;
        color: #40404e;
        overflow: hidden;
        font-size: 13px;
        line-height: 14px;
    }

    .d_yy .d_yy-rkrq .rkrq {
        display: inline-flex;
        align-items: center;
        margin: 0 0 14px 0;
    }

    .d_yy .d_yy-rkrq .rkrq:nth-child(1) {
        width: 370px !important;
    }

    .d_yy .d_yy-rkrq .rkrq:nth-child(2) {
        width: 150px !important;
    }

    .d_yy .ewdetai {
        color: #2170ff;
        cursor: pointer;
    }

    .d_yy .layouts {
        font-size: 14px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .d_yy .AddPrincipal {
        color: #4eadfc
    }

    .d_yy .compatibility {
        display: flex;
        /* align-items: center; */
        margin-bottom: 10px;

    }

    .d_yy .compatibil {
        margin-bottom: 10px;
    }

    .d_yy .required {
        display: inline-block;
        width: 60px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 取消按钮 */
    .d_yy .el-dialog .el-button--default {
        background-color: #ccc;
        border: 1px solid #ccc;
        color: #40404e;
    }

    .d_yy .dialogFormVisible .el-dialog {
        width: 50vw !important;
        min-width: 520px !important;
        max-width: 540px !important;
    }

    .d_yy .el-dialog {
        background-color: #f9f9f9;
    }

    .d_yy .el-input__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
        height: 30px;
        line-height: 30px;
    }

    .d_yy .el-dialog__title, .d_yy .el-dialog__headerbtn .el-dialog__close, .d_yy .el-form-item__label {
        color: #1a1a21;
    }

    .d_yy .el-input {
        width: 190px;
    }

    .d_yy .el-form-item {
        display: flex;
        margin: 0;
    }

    .d_yy .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    .d_yy .el-dialog {
        width: 30vw;
    }

    .d_yy table thead tr th, .d_yy table tbody tr td {
        height: 40px;
        font-size: 14px;
    }

    /* 一级分类和二级分类文字颜色更改 */
    .d_yy .stairfl {
        display: flex;
        align-items: center;
        margin: 0 0 14px 0;
        font-size: 13px;
        line-height: 14px;
    }

    .d_yy .stairfl div:nth-of-type(1) {
        color: #40404e;
        margin-right: 8px;
    }

    .d_yy .stairfl .stairastrict {
        height: 34px;
        display: flex;
        align-items: center;
    }

    .d_yy .stairfl .container {
        height: 30px;
    }

    /* 更改单选框颜色 */
    .d_yy .el-radio-button__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
        border: 1px solid #ccc;
        font-size: 14px;
    }

    .d_yy .el-radio-button:first-child .el-radio-button__inner {
        border-left: 1px solid #ccc;
    }

    /* 新增仓库 */
    .d_yy .el-tag {
        background-color: rgba(0, 0, 0, 0);
        margin-right: 10px;
        margin-bottom: 10px;
        color: #40404e;
    }

    .d_yy .el-tag i {
        color: #40404e;
    }

    .d_yy .tidsesfe {
        display: flex;
    }

    /* 多行文本输出框 */
    .d_yy .el-textarea__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
        width: 100;
    }

    .d_yy .el-input__count {
        background-color: #1A1A20;
        color: #40404e;
        right: -45px;
        height: 20px;
        bottom: 5px;
        line-height: 20px;
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 查看 */
    .d_yy .viewdetailscls .el-dialog {
        width: 1280px;
        /* margin: 80px auto 0 !important; */
        /* width: 80vw !important; */
        /* min-width: 520px !important;
        max-width:540px !important; */
    }

    .d_yy .viewdetailscls .el-form {
        padding: 0px;
        margin: 20px;
        background-color: #eee;
        border-radius: 8px
    }

    /* 必填 */
    .d_yy .viewdetailscls .mandatory {
        color: #40404e;
    }

    .d_yy .viewdetailscls .ys {
        margin-top: 40px;
        font-size: 14px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;

    }

    .d_yy .viewdetailscls .el-form {
        padding-top: 10px;
    }

    .d_yy .viewdetailscls .compatibility {
        margin-bottom: 0px;
    }

    .d_yy .viewdetailscls .compatibil {
        margin-bottom: 0px;
    }

    .d_yy .viewdetailscls .yyjl {
        max-width: 1190px;
        overflow-x: scroll;
        margin-left: 20px;
    }

    .d_yy .viewdetailscls .zhuixiaoi {
        margin-top: 20px;
    }

    .d_yy .viewdetailscls .zhuixiaoi .limiting {
        /* overflow-y: auto !important;
        max-height: 320px !important; */
    }

    .d_yy .viewdetailscls .juz {
        display: flex;
        justify-content: center;
    }

    .d_yy .viewdetailscls .nrxx {
        color: #40404e;
        font-size: 20px;
        font-weight: bold;
        margin-left: 20px;
        display: inline-block;
        margin-top: 20px;
    }

    .d_yy .viewdetailscls .el-radio__label {
        font-size: 14px;
    }

    .d_yy .viewdetailscls .materialnr {
        width: 200px;
    }

    .d_yy .viewdetailscls .materialnr, .d_yy .viewdetailscls label, .d_yy .viewdetailscls .materialnrs {
        color: #40404e;
        font-size: 14px;
    }

    .d_yy .viewdetailscls .drag-list td:nth-of-type(1), .d_yy .viewdetailscls .mmodity th:nth-of-type(1) {
        width: 130px;
    }

    .d_yy .viewdetailscls .drag-list td:nth-of-type(2), .d_yy .viewdetailscls .mmodity th:nth-of-type(2) {
        width: 200px;
    }

    .d_yy .viewdetailscls .drag-list td:nth-of-type(3), .d_yy .viewdetailscls .mmodity th:nth-of-type(3) {
        width: 130px;
    }

    .d_yy .viewdetailscls .drag-list td:nth-of-type(4), .d_yy .viewdetailscls .mmodity th:nth-of-type(4) {
        width: 130px;
    }

    .d_yy .viewdetailscls .drag-list td:nth-of-type(5), .d_yy .viewdetailscls .mmodity th:nth-of-type(5) {
        width: 100px;
    }

    .d_yy .viewdetailscls .drag-list td:nth-of-type(6), .d_yy .viewdetailscls .mmodity th:nth-of-type(6) {
        width: 100px;
    }

    .d_yy .viewdetailscls .drag-list td:nth-of-type(7), .d_yy .viewdetailscls .mmodity th:nth-of-type(7) {
        width: 100px;
    }

    .d_yy .viewdetailscls .drag-list td:nth-of-type(8), .d_yy .viewdetailscls .mmodity th:nth-of-type(8) {
        width: 100px;
    }

    .d_yy .viewdetailscls .drag-list td:nth-of-type(9), .d_yy .viewdetailscls .mmodity th:nth-of-type(9) {
        width: 100px;
    }

    .d_yy .viewdetailscls .drag-list td:nth-of-type(10), .d_yy .viewdetailscls .mmodity th:nth-of-type(10) {
        width: 100px;
    }

    .d_yy .viewdetailscls .drag-list td:nth-of-type(11), .d_yy .viewdetailscls .mmodity th:nth-of-type(11) {
        width: 100px;
    }

    .d_yy .viewdetailscls .drag-list td:nth-of-type(12), .d_yy .viewdetailscls .mmodity th:nth-of-type(12) {
        width: 150px;
    }

    .d_yy .viewdetailscls .drag-list td:nth-of-type(13), .d_yy .viewdetailscls .mmodity th:nth-of-type(13) {
        width: 150px;
    }

    /* 仓库列表 */
    .d_yy .zhuixiaoi {
        width: 100%;
        border-collapse: collapse;
        color: #40404e;
    }

    .d_yy .zhuixiaoi .mmodity tr th {
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-size: 14px;
        font-weight: 600;
        color: #40404e;
        padding-left: 20px;
    }

    .d_yy .zhuixiaoi .limiting .drag-list td {
        height: 36px;
        line-height: 36px;
        text-align: left;
        white-space: normal;
        word-break: break-all;
        font-size: 14px;
        font-weight: 400;
        padding-left: 20px;
    }

    .d_yy .zhuixiaoi .limiting .drag-list {
        display: block;
        display: flex;
    }

    .d_yy .zhuixiaoi .mmodity {
        width: 100%;
        display: block;
    }

    .d_yy .zhuixiaoi .mmodity tr {
        background-color: #f5f5f5;
        display: flex;
    }

    .d_yy .zhuixiaoi .limiting {
        overflow-y: auto !important;
        max-height: 540px;
        display: block;
    }

    .d_yy .meisfgr {
        width: 100%;
        overflow-x: scroll !important;
    }

    .d_yy .drag-list td:nth-of-type(1), .d_yy .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .d_yy .drag-list td:nth-of-type(2), .d_yy .mmodity th:nth-of-type(2) {
        width: 130px;
    }

    .d_yy .drag-list td:nth-of-type(3), .d_yy .mmodity th:nth-of-type(3) {
        width: 130px;
    }

    .d_yy .drag-list td:nth-of-type(4), .d_yy .mmodity th:nth-of-type(4) {
        width: 180px;
    }

    .d_yy .drag-list td:nth-of-type(5), .d_yy .mmodity th:nth-of-type(5) {
        width: 130px;
    }

    .d_yy .drag-list td:nth-of-type(6), .d_yy .mmodity th:nth-of-type(6) {
        width: 130px;
    }

    .d_yy .drag-list td:nth-of-type(7), .d_yy .mmodity th:nth-of-type(7) {
        width: 120px;
    }

    .d_yy .drag-list td:nth-of-type(8), .d_yy .mmodity th:nth-of-type(8) {
        width: 100px;
    }

    .d_yy .drag-list td:nth-of-type(9), .d_yy .mmodity th:nth-of-type(9) {
        width: 100px;
    }

    .d_yy .drag-list td:nth-of-type(10), .d_yy .mmodity th:nth-of-type(10) {
        width: 100px;
    }

    .d_yy .drag-list td:nth-of-type(11), .d_yy .mmodity th:nth-of-type(11) {
        width: 100px;
    }

    .d_yy .drag-list td:nth-of-type(12), .d_yy .mmodity th:nth-of-type(12) {
        width: 120px;
    }

    .d_yy .drag-list td:nth-of-type(13), .d_yy .mmodity th:nth-of-type(13) {
        width: 120px;
    }

    .d_yy .drag-list td:nth-of-type(14), .d_yy .mmodity th:nth-of-type(14) {
        width: 120px;
    }

    .d_yy .drag-list td:nth-of-type(15), .d_yy .mmodity th:nth-of-type(15) {
        width: 150px;
    }

    /* .d_yy .meisfgr .drag-list td:nth-of-type(16),.d_yy .meisfgr .mmodity th:nth-of-type(16){
        width: 150px;
    }   
    .d_yy .meisfgr .drag-list td:nth-of-type(17),.d_yy .meisfgr .mmodity th:nth-of-type(17){
        width: 150px;
    }  */

    .d_yy .drag-list:nth-of-type(odd) {
        background-color: #f9f9f9;
        color: #40404e;
    }

    .d_yy .drag-list:nth-of-type(even) {
        background-color: #f5f5f5;
        color: #40404e;
    }

    .d_yy .zhuixiaoi .el-checkbox__label {
        color: #40404e;
    }

    /*  */
    .d_yy .zhuixiaoi .chaoguogai {
        height: 20px;
        /* text-align: center; */
        line-height: 20px;
        width: 136px;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    /* 日期选择器 */
    .d_yy .d_yy-rkrq .rkrq .el-range-editor .el-range-input {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
    }

    .d_yy .d_yy-rkrq .rkrq .el-date-editor .el-range-separator, .d_yy .d_yy-rkrq .rkrq .el-date-editor .el-range__icon {
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
    .d_yy .Pagination {
        /*width: 1600px;*/
        text-align: right;
        margin-top: 20px;
    }

    .d_yy .Pagination .el-pagination.is-background .btn-next, .d_yy .Pagination .el-pagination.is-background .btn-prev, .d_yy .Pagination .el-pagination.is-background .el-pager li {
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #606266;
        color: #40404e;
    }

    .d_yy .Pagination .btn-prev {
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #606266;
    }

    .d_yy .Pagination .el-pagination {
        padding: 0;
    }

    .d_yy .Pagination .el-pagination .btn-next .el-icon, .d_yy .Pagination .el-pagination .btn-prev .el-icon {
        color: #40404e;
    }

    .d_yy .Pagination .el-pagination.is-background .el-pager li:not(.disabled).active {
        color: #409EFF;
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #409EFF;
    }
</style>

<style media="print">
    @page {
        size: auto A4 landscape;
        margin: 5mm;
    }

    @media print {
        html {
            /* margin-left: 30px; */
        }

        .printd_yy .show {
            display: block;
        }

        .printd_yy .nrxx {
            color: #000;
            font-size: 20px;
            display: inline-block;
            /* padding-top: 30px; */
        }

        .printd_yy .nr .nrxx {
            padding-top: 10px;
        }

        .printd_yy .monad {
            font-weight: bold;
            display: block;
            font-size: 30px;
            margin-top: 50px;
            color: #000;
            text-align: center;
        }

        .printd_yy .tidsesfe {
            display: flex;
        }

        .printd_yy .compatibility {
            display: flex;
            align-items: center;
        }

        .printd_yy .mandatory {
            color: #000;
            width: 140px;
            text-align: right;
            /* padding-top: 10px; */
        }

        .printd_yy .controlling {
            width: 370px !important;
            line-height: 40px;
        }

        .printd_yy .reqfieldsd {
            font-size: 14px;
            padding-right: 4px;
            color: #ce4153;
            /* 文字不可选中 */
            -webkit-user-select: none;
            -moz-user-select: none;
            -ms-user-select: none;
            user-select: none;
        }

        .printd_yy .zhuixiaoi {
            overflow: hidden;
            border-collapse: collapse;
            color: #000;
        }

        .printd_yy .zhuixiaoi tr th {
            height: 40px;
            line-height: 40px;
            text-align: center;
            background-color: #2d2e38;
            font-weight: 400;
        }

        .printd_yy .zhuixiaoi .mmodity th:nth-of-type(1) {
            border-left: solid 1px transparent;
        }

        .printd_yy .zhuixiaoi .limiting .drag-list td {
            height: 40px;
            line-height: 40px;
            text-align: center;
            white-space: normal;
            word-break: break-all;
        }

        .printd_yy .zhuixiaoi .limiting .drag-list td:nth-of-type(1) {
            border-left: solid 1px transparent;
        }

        .printd_yy .zhuixiaoi .limiting .drag-list {
            display: block;
            display: flex;

        }

        .printd_yy .zhuixiaoi .mmodity {
            width: 100%;
            display: block;
        }

        .printd_yy .zhuixiaoi .mmodity tr {
            display: flex;
        }

        .printd_yy .el-form-item {
            display: flex;
            margin: 0;
        }

        .printd_yy .drag-list td, .printd_yy .mmodity th {
            font-size: 13px;
        }

        .printd_yy .el-dialog {
            width: 1100px;
        }

        .printd_yy .el-form {
            padding-top: 10px;
        }

        .printd_yy .addmaterial {
            display: flex;
            justify-content: center;
        }

        .printd_yy .materialnr {
            width: 200px;
        }

        .printd_yy .materialnrs {
            width: 600px;
        }

        .printd_yy .materialnr, .printd_yy label, .printd_yy .materialnrs {
            color: #000;
        }

        .printd_yy .zhuixiaoi {
            margin-top: 20px;
        }

        .printd_yy .drag-list td:nth-of-type(1), .printd_yy .mmodity th:nth-of-type(1) {
            width: 150px;
        }

        .printd_yy .drag-list td:nth-of-type(2), .printd_yy .mmodity th:nth-of-type(2) {
            width: 110px;
        }

        .printd_yy .drag-list td:nth-of-type(3), .printd_yy .mmodity th:nth-of-type(3) {
            width: 110px;
        }

        .printd_yy .drag-list td:nth-of-type(4), .printd_yy .mmodity th:nth-of-type(4) {
            width: 110px;
        }

        .printd_yy .drag-list td:nth-of-type(5), .printd_yy .mmodity th:nth-of-type(5) {
            width: 110px;
        }

        .printd_yy .drag-list td:nth-of-type(6), .printd_yy .mmodity th:nth-of-type(6) {
            width: 150px;
        }

        .printd_yy .drag-list td:nth-of-type(7), .printd_yy .mmodity th:nth-of-type(7) {
            width: 170px;
        }

        .printd_yy .drag-list td:nth-of-type(8), .printd_yy .mmodity th:nth-of-type(8) {
            width: 130px;
        }

        .printd_yy .signature {
            display: flex;
            margin-top: 50px;
        }

        .printd_yy .signature > div {
            margin-left: 30px;
            display: flex;
        }

        .printd_yy .signature span {
            font-size: 20px;
        }

        .printd_yy .signature .xian {
            width: 180px;
            height: 30px;
        }
    }

    .el-input__icon {
        line-height: 30px;
    }

    .out_sum .el-input {
        opacity: 1;
        width: 190px;
    }

    .el-button {
        font-size: 13px;
        line-height: 14px;
        padding: 8px 20px;
        height: 30px;
    }

    .el-range-editor.el-input__inner {
        width: 287px;
        height: 30px;
        line-height: 30px;
    }

    .el-date-editor .el-range__close-icon {
        line-height: 22px;
    }

</style>