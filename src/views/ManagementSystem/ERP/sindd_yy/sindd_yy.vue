<template>
    <div class="sindyy">
        <div class="stairfl">
            <div class="classification">状&emsp;&emsp;态：</div>
            <div class="stairastrict">
                <el-radio-group v-model="Inbound.state" class="container">
                    <el-radio-button label="0">全部</el-radio-button>
                    <el-radio-button label="3">待处理</el-radio-button>
                    <el-radio-button label="2">已处理</el-radio-button>
                    <el-radio-button label="1">已完成</el-radio-button>
                </el-radio-group>
            </div>
        </div>
        <div class="sindyy-rkrq">
            <div class="rkrq">
                <span class="">出库日期：</span>
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
                'width':tableData.length>12?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`}">
                    <tr v-for="(item,i) in tableData" :key="item.id" class="drag-list">
                        <td>{{i+1}}</td>
                        <td>{{item.cd}}</td>
                        <td>
                            <div class="ewdetai" @click="showviewdetails(item.id,item)">
                                {{item.id}}
                            </div>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.n || '-----'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.moc || '-----'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.mtc || '-----'"></ellipsis-tooltip>
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
                            <ellipsis-tooltip :text="item.r || '-----'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.s || '-----'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.osn || '-----'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.oen || '-----'"></ellipsis-tooltip>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.isn || '-----'"></ellipsis-tooltip>
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
                'width':tableData.length>12?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`}">
                    <tr v-for="(item,i) in tableData" :key="item.id" class="drag-list">
                        <td>{{i+1}}</td>
                        <td>{{item.cd}}</td>
                        <td>
                            <div class="ewdetai" @click="showviewdetails(item.id,item)">
                                {{item.id}}
                            </div>
                        </td>
                        <td>
                            <ellipsis-tooltip :text="item.n || '-----'"></ellipsis-tooltip>
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


        <!-- 查看详情 -->
        <div v-show="cfdetails" class="viewdetailscls">
            <el-dialog title="查看详情" :visible.sync="cfdetails" @close="cfdetails = false" :close-on-click-modal="false">
                <div id="print">
                    <div class="printsindyy">
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
                                    <div class="materialnr controlling">{{viewdetails.n || '---'}}</div>
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
                                        <span class="reqfieldsd"></span>一级分类：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.moc || '---'}}</div>
                                </div>
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
                            </div>
                            <div class="tidsesfe">
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>入库仓库：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.isn || '---'}}</div>
                                </div>
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>出库数量：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.c }}</div>
                                </div>
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>异议数量：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.yc }}</div>
                                </div>
                            </div>
                            <div class="tidsesfe">
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>异议锁定数量：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.lyc }}</div>
                                </div>
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>状态：
                                    </div>
                                    <div class="materialnr controlling">{{viewdetails.s || '---'}}</div>
                                </div>
                            </div>
                            <div class="tidsesfe">
                                <div class="compatibility">
                                    <div class="mandatory">
                                        <span class="reqfieldsd"></span>备注：
                                    </div>
                                    <div class="materialnr  gaib">{{viewdetails.r || '---'}}</div>
                                </div>
                            </div>

                        </el-form>

                        <span class="nrxx" style="margin-top: 0px;">异议记录：</span>
                        <div class="nr">
                            <table class="zhuixiaoi">
                                <thead class="mmodity">
                                <tr>
                                    <th>子单号</th>
                                    <th>名称</th>
                                    <th>一分类</th>
                                    <th>二分类</th>
                                    <th>单位</th>
                                    <th>
                                        <div class="alignment">确认数量</div>
                                    </th>
                                    <th>
                                        <div class="alignment">确认小计</div>
                                    </th>
                                    <th>
                                        <div class="alignment">异议数量</div>
                                    </th>
                                    <th>
                                        <div class="alignment">异议小计</div>
                                    </th>
                                    <th>异议备注</th>
                                    <th>操作人</th>
                                    <th>操作方</th>
                                    <th>操作时间</th>
                                </tr>
                                </thead>
                                <tbody class="limiting" v-if="viewdeta" :style="{'border-bottom':viewdeta.length<1?'0px':'',
                                    'width':viewdeta.length>7?'calc(100% + 6px)':'100%'}">
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
                                <!-- <tr class="drag-list" v-if="viewdeta.length<1">
                                    <td class="nodata">
                                        <img src="../../../../assets/img/wu.png" alt="">
                                        <div class="hint">暂无数据</div>
                                    </td>
                                </tr> -->
                                </tbody>
                            </table>
                            <div class="tiaodd" v-if="viewdeta.length<1">
                                <td class="nodata">
                                    <img src="../../../../assets/img/wu.png" alt="">
                                    <div class="hint">暂无数据</div>
                                </td>
                            </div>
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

                <span slot="footer" class="dialog-footer">
                    <el-button @click="cfdetails = false">关闭</el-button>
                    <el-button type="primary" v-show="viewdetails.status == 1" v-print="print">打印</el-button>
                    <el-button type="primary" v-show="viewdetails.s == '已处理'" @click="xingh">撤销异议</el-button>
                    <el-button type="primary" v-show="(viewdetails.lyc != '0') == (viewdetails.s == '待处理')"
                               @click="noneffective">驳回</el-button>
                    <el-button type="primary" v-show="viewdetails.s == '待处理'" @click="compileprinter">确定入库</el-button>
                </span>
            </el-dialog>
        </div>

        <!-- 撤销异议 -->
        <div v-show="dialogible" class="dialogFormVisblee">
            <el-dialog title="撤销异议" :visible.sync="dialogible" @close="dialogible = false"
                       :close-on-click-modal="false">
                <div class="fandjc">撤销后系统会使用最新的"操作后出库数"完成调拨入库, 是否确认?</div>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogible = false">取消</el-button>
                    <el-button type="primary" @click="xingh">确认</el-button>
                </span>
            </el-dialog>
        </div>
        <!-- 确定入库 -->
        <div v-show="dialogiblecl" class="dialogFormVisblee">
            <el-dialog title="确定入库" :visible.sync="dialogiblecl" @close="dialogiblecl = false"
                       :close-on-click-modal="false">
                <div class="fandjc">确认入库后系统会使用最新的"操作后出库数"完成调拨入库, 是否确认?</div>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogiblecl = false">取消</el-button>
                    <el-button type="primary" @click="compileprinter">确认</el-button>
                </span>
            </el-dialog>
        </div>
        <!-- 驳回 -->
        <div v-show="dialogFormVisible" class="dialogFormVisible">
            <el-dialog title="驳回" :visible.sync="dialogFormVisible" @close="dialogFormVisible = false"
                       :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>物料名字：
                        </div>
                        <div class="controlling">{{ProductLibrary.n}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>一级分类：
                        </div>
                        <div class="controlling">{{ProductLibrary.moc}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>二级分类：
                        </div>
                        <div class="controlling">{{ProductLibrary.mtc}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>出库单位：
                        </div>
                        <div class="controlling">{{ProductLibrary.un}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>出库数量：
                        </div>
                        <div class="controlling">{{ProductLibrary.c}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>异议锁定数量：
                        </div>
                        <div class="controlling">{{ProductLibrary.lyc}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>异议数量：
                        </div>
                        <div class="controlling">
                            <el-input v-model="ProductLibrary.sl " placeholder="请输出异议数量" class=" altersl"/>
                        </div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>备注：
                        </div>
                        <el-input class="controlling" type="textarea" v-model="ProductLibrary.bz" :rows="3"
                                  placeholder="请输入备注" show-word-limit
                                  :class="form_rule_msg_remark?'error':''" @blur="validator('remark')"/>
                        <div class="cwts">{{form_rule_msg_remark}}</div>
                    </div>
                </el-form>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFormVisible = false">取消</el-button>
                    <el-button type="primary" @click="construction">确认</el-button>
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
      },//出库
      tableData: [],// 读取管理列表
      multipleSelection: [],// 选中的内容

      dialogible: false,//控制撤销异议是否显示
      dialogiblecl: false,//控制处理是否显示
      dialogFormVisible: false,//控制驳回是否显示
      ProductLibrary: {},//驳回

      viewdetails: {},//查看详情内容
      viewdeta: [],//异议流水列表

      controljy: true,
      cfdetails: false,// 控制查看详情显示与否

      print: {
        id: 'print',
        popTitle: '异议订单', // 打印配置页上方标题
        // extraHead: '调拨入库单',
      },
      windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
      MaxHeight: 0,//滚动高度
      MaxNumber: 0,//最大个数

      form_rules: ["remark"],
      form_rule_msg_remark: "",

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
        case "remark":
          if (this.$overall.character(this.ProductLibrary.bz) > 280) {
            this.form_rule_msg_remark = '输入文字长度超过140'
          } else {
            this.form_rule_msg_remark = ''
          }
          break
      }
    },
    // 滚动最大高度
    RollMaxHeight(i){
      var s = i - 48 - 60 - 70 - 60 - 70
      this.MaxHeight = s
      this.MaxNumber = Math.floor(s / 37)
      console.log(this.MaxNumber);
      // console.log(i);
    },
    // soutdd_yy.requestd_yy
    // 打印
    Print(){
      myPrint(this.$refs.print);
      function myPrint(obj) {
        newWindow.print();

      }
    },
    // 日期
    daterq(){
      var now = new Date()
      var year = now.getFullYear()//年
      var month = (now.getMonth() + 1).toString().padStart(2, '0')//月
      var date = now.getDate().toString().padStart(2, '0');//日
      var dangy = new Date(year, month, 0).getDate()//当月有多少天
      this.Inbound.date = [`${year}-${month}-01`, `${year}-${month}-${dangy}`]
    },
    // 获取管理列表内容  查询
    demand(){
      console.log(this.Inbound.state);
      this.$api.ERP.soutdd_yy.requestd_yyin_list({
        page_num: this.Inbound.pagenum,
        page_size: 10,
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
    },
    // 当前是多少页
    handleCurrentChange(val) {
      // console.log(`当前页: ${val}`);
      this.Inbound.pagenum = val
      this.demand()
    },
    // 重置
    resetstorage(){
      this.Inbound.date = []
      this.Inbound.state = '3'
      this.Inbound.pagenum = 1
      this.Inbound.pagecnt = 1
      this.Inbound.rowcnt = 1
      this.tableData = []
      this.daterq()
      this.demand()
    },
    //  确定入库
    compileprinter(){
      console.log(this.multipleSelection);
      this.$api.ERP.soutdd_yy.requestd_yyin_confirm({id: this.multipleSelection[0]}).then(res => {
        console.log(res);
        if (res.code == 1) {
          this.demand()
          this.cfdetails = false
          this.$message({showClose: true, message: "操作成功", type: 'success'})
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 撤销异议
    xingh(){
      console.log(this.multipleSelection);
      this.$api.ERP.soutdd_yy.requestd_yyin_cancel({id: this.multipleSelection[0]}).then(res => {
        console.log(res);
        if (res.code == 1) {
          this.cfdetails = false
          this.demand()
          this.$message({showClose: true, message: "操作成功", type: 'success'})
        } else {
          this.$message.warning(res.msg)
        }
      })

    },
    // 打开驳回
    noneffective(){
      this.form_rule_msg_remark = '';
      console.log(this.viewdetails);
      this.dialogFormVisible = true
      this.ProductLibrary = {
        id: this.viewdetails.id,
        n: this.viewdetails.n,
        moc: this.viewdetails.moc,
        mtc: this.viewdetails.mtc,
        un: this.viewdetails.un,
        c: this.viewdetails.c,
        lyc: this.viewdetails.lyc,
        sl: '',
        bz: '',
      }
    },
    // 驳回提交
    construction(){
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_remark) return;
      if (this.ProductLibrary.sl == '' || this.ProductLibrary.bz == '') {
        this.$message.warning('必填项不能为空')
      } else {
        this.$api.ERP.soutdd_yy.requestd_yyin_back({
          id: this.ProductLibrary.id,
          cnt: Number(this.ProductLibrary.sl),
          remark: this.ProductLibrary.bz,
        }).then(res => {
          if (res.code == 1) {
            this.dialogFormVisible = false
            this.cfdetails = false
            this.demand()
            this.$message({showClose: true, message: "操作成功", type: 'success'})
          } else {
            this.$message.warning(res.msg)
          }
        })
      }
    },
    // 读取详情, 用于信息展示
    showviewdetails(id, item){
      this.viewdetails = item || {}
      this.multipleSelection = [id]
      this.$api.ERP.soutdd_yy.req_in_yy_dtls({id}).then(res => {
        if (res.code == 1) {
          this.isIndeterminate = true
          this.viewdeta = res.data.records || []
          this.cfdetails = true
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
  },
  computed: {
    Inboundstate(){
      return JSON.parse(JSON.stringify(this.Inbound.state))
    },
    ProductLibra(){
      return JSON.parse(JSON.stringify(this.ProductLibrary))
    },
  },
  watch: {
    windowHeigh(val) {
      let that = this;
      this.RollMaxHeight(val)
      //   console.log("实时屏幕高度：",val, that.windowHeigh );
    },
    windowWidt (val) {
      let that = this;
      //   console.log("实时屏幕宽度：",val, that.windowWidt );
    },
    // 只能输入数字
    ProductLibra: {
      deep: true,
      handler: function (after, before) {
        var reg = /^[0-9]*$/g
        if (reg.test(after.sl)) {
          if (after.sl > after.lyc) {
            console.log(after.lyc);
            this.ProductLibrary.sl = after.lyc + ''
            this.$message({
              message: '异议数量不得超过异议锁定数量',
              type: 'warning',
            })
          }
        } else {
          this.ProductLibrary.sl = before.sl + ''
        }
      }
    },
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
    .sindyy .el-dialog {
        margin: 0px 0px 0px auto !important;
        background-color: #f9f9f9;
        height: 100%;
        position: relative;
    }

    .sindyy .el-dialog__footer {
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }

    .sindyy .el-dialog__body {
        padding: 0px 20px 30px 20px;
        overflow-y: scroll !important;
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;
    }

    .sindyy .el-dialog {
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .sindyy {
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding: 20px 30px;
    }

    .sindyy .gaib {
        width: 500px !important;
        display: flex;
        align-items: center;
    }

    .monad, .show {
        display: none;
    }

    .sindyy .meisfgr {
        position: relative;
        /*margin-top: 6px;*/
    }

    .sindyy .tiaodd {
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

    .sindyy .nodata {
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        padding: 0;
    }

    .sindyy .nodata img {
        width: 60px;
        height: 60px;
    }

    .sindyy .nodata .hint {
        line-height: 36px;
        font-size: 13px !important;
    }

    /* 必填 */
    .sindyy .mandatory {
        color: #40404e;
        width: 140px;
        text-align: right;
        /* padding-top: 10px; */
    }

    .sindyy .controlling {
        width: 230px !important;
        /* line-height: 40px; */
    }

    .sindyy .reqfieldsd {
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
    .sindyy .alignment {
        text-align: right !important;
        padding-right: 15px;
    }

    /* 表格无数据时展示 */
    .sindyy .nodata {
        /* border-left:solid 1px #f5f5f5; */
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
    }

    .sindyy .nodata img {
        width: 60px;
        height: 60px;
    }

    .sindyy .nodata .hint {
        line-height: 40px;
        font-size: 13px !important;
    }

    .sindyy .sindyy-headline {
        font-size: 30px;
        font-weight: bold;
        color: #40404e;
    }

    /* 给一级分类二级分类加外边距和圆角 */
    .sindyy .el-radio-button {
        margin-right: 6px;
        margin-bottom: 6px;
        /* overflow: hidden; */
        /* border: 1px solid #f5f5f5; */
        height:30px;
    }

    .sindyy .el-radio-button__inner {
        padding: 6px 20px;
        border-radius: 4px !important;
    }

    /* 去除瑕疵 */
    .sindyy .el-radio-button__orig-radio:checked + .el-radio-button__inner {
        box-shadow: none
    }

    /* 选中状态颜色背景边框 */
    .sindyy .el-radio-button__orig-radio:checked + .el-radio-button__inner {
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #6A9EFF !important;
        color: #6A9EFF;
    }

    .sindyy .sindyy-rkrq {
        width: 1600px;
        color: #40404e;
        margin: 14px 0;
        display: flex;
        font-size: 13px;
        line-height: 14px;
    }

    .sindyy .sindyy-rkrq .rkrq {
        margin-right: 15px;
        display: flex;
        align-items: center;
    }

    .sindyy .ewdetai {
        color: #438dfd;
    }

    .sindyy .fandjc {
        font-size: 20px;
        color: #40404e;
        font-weight: bold;
        padding: 20px 0;
    }

    .sindyy .layouts {
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .sindyy .AddPrincipal {
        color: #4eadfc
    }

    .sindyy .compatibility {
        display: flex;
        align-items: center;
        margin-bottom: 10px;

    }

    .sindyy .compatibil {
        margin-bottom: 10px;
    }

    .sindyy .required {
        width: 60px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* .sindyy .altersl{
        width: 150px !important;
    } */
    /* 取消按钮 */
    .sindyy .el-dialog .el-button--default {
        background-color: #ccc;
        border: 1px solid #ccc;
        color: #40404e;
    }

    .sindyy .el-dialog {
        background-color: #f9f9f9;
    }

    .sindyy .el-input__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
        text-align: left;
    }

    .sindyy .el-dialog__title, .sindyy .el-dialog__headerbtn .el-dialog__close, .sindyy .el-form-item__label {
        color: #1a1a21;
    }

    .sindyy .el-input {
        width: 190px;
    }

    .sindyy .el-form-item {
        display: flex;
        margin: 0;
    }

    /* 改变多选框背景颜色和上下间距 */
    .sindyy .el-checkbox-group {
        display: flex;
        align-items: flex-end;
        justify-content: center;
    }

    .sindyy .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    .sindyy .el-dialog {
        width: 30vw;
    }

    .sindyy .has-gutter {
        border: 1px solid #f5f5f5;
    }

    .sindyy .dialogFormVisible .el-dialog {
        width: 500px;
        /* width: 80vw !important; */
        /* min-width: 520px !important;
        max-width:540px !important; */
    }

    .sindyy .dialogFormVisblee .el-dialog {
        width: 500px;
        /* width: 80vw !important; */
        /* min-width: 520px !important;
        max-width:540px !important; */
    }

    .sindyy table thead tr th, .sindyy table tbody tr td {
        height: 40px;
        font-size: 14px;
    }

    /* 一级分类和二级分类文字颜色更改 */
    .sindyy .stairfl {
        display: flex;
        align-items: center;
        margin: 0 0 14px 0;
        font-size: 13px;
        line-height: 14px;
    }

    .sindyy .stairfl .classification {
        color: #40404e;
    }

    .sindyy .stairfl .stairastrict {
        height: 34px;
        display: flex;
        align-items: center;
    }

    .sindyy .stairfl .container {
        height: 30px;
    }

    /* 更改单选框颜色 */
    .sindyy .el-radio-button__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
        border: 1px solid #f5f5f5;
        font-size: 14px;
    }

    .sindyy .el-radio-button:first-child .el-radio-button__inner {
        border-left: 1px solid #f5f5f5;
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
        color: #40404E;
    }

    .el-select-dropdown {
        border: 1px solid #f5f5f5;
    }

    .xdownbox {
        display: none;
    }

    /* 新增仓库 */
    .sindyy .el-tag {
        background-color: rgba(0, 0, 0, 0);
        margin-right: 10px;
        margin-bottom: 10px;
        color: #40404e;
    }

    .sindyy .el-tag i {
        color: #40404e;
    }

    .sindyy .tidsesfe {
        display: flex;
        margin-top: 10px;
    }

    /* 多行文本输出框 */
    .sindyy .el-textarea__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
        /* width: calc(100% + 30px); */
    }

    .sindyy .el-input__count {
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

    /* 新增物料 */
    .sindyy .addmaterial {
        margin-top: 20px;
        padding-top: 20px;
        border-top: 2px solid #443f3f;
    }

    .sindyy .materialnr {
        color: #40404e;
    }

    .sindyy .dialogFormVisible .compatibility {
        margin-bottom: 15px;
    }

    .sindyy .dialogFormVisible .zhuixiaoi {
        margin-top: 20px;
    }

    .sindyy .dialogFormVisible .controlling {
        color: #40404e;
    }

    .sindyy .dialogFormVisible .drag-list td:nth-of-type(2), .sindyy .dialogFormVisible .mmodity th:nth-of-type(2) {
        width: 300px;
    }

    .sindyy .dialogFormVisible .drag-list td:nth-of-type(3), .sindyy .dialogFormVisible .mmodity th:nth-of-type(3) {
        width: 170px;
    }

    .sindyy .dialogFormVisible .drag-list td:nth-of-type(4), .sindyy .dialogFormVisible .mmodity th:nth-of-type(4) {
        width: 80px;
    }

    .sindyy .dialogFormVisible .drag-list td:nth-of-type(5), .sindyy .dialogFormVisible .mmodity th:nth-of-type(5) {
        width: 140px;
    }

    .sindyy .dialogFormVisible .el-input-number {
        width: 100%;
    }

    /* 禁用状态颜色 */
    .sindyy .dialogFormVisible .el-input.is-disabled .el-input__inner {
        background-color: rgba(255, 255, 255, 0.075);
        color: #b2b7c0
    }

    /* 查看 */
    .sindyy .viewdetailscls .el-dialog {
        width: 1280px;
        /* margin: 90px auto 0 !important; */
        /* width: 80vw !important; */
        /* min-width: 520px !important;
        max-width:540px !important; */
    }

    /* 必填 */
    .sindyy .viewdetailscls .mandatory {
        color: #40404e;
    }

    .sindyy .viewdetailscls .zhuixiaoi {
        padding: 20px 0;
    }

    .sindyy .viewdetailscls .juz {
        display: flex;
        justify-content: center;
    }

    .sindyy .viewdetailscls .addmaterial .dindan {
        color: #40404e;
        font-size: 14px;
        margin-bottom: 20px;
    }

    .sindyy .viewdetailscls .el-form {
        padding: 0px;
        margin: 20px;
        background-color: #eee;
        border: 1px solid #f5f5f5;
        border-radius: 8px
    }

    .sindyy .viewdetailscls .nrxx {
        color: #40404e;
        font-size: 18px;
        font-weight: bold;
        display: inline-block;
        margin-top: 20px;
        margin-left: 20px;
    }

    .sindyy .viewdetailscls .nr {
        max-width: 1180px;
        margin-left: 20px;
        margin-top: 20px;
        overflow-x: scroll;
    }

    .sindyy .viewdetailscls .materialnr {
        width: 200px;
    }

    .sindyy .viewdetailscls .materialnrs {
        width: 600px;
    }

    .sindyy .viewdetailscls .materialnr, .sindyy .viewdetailscls label, .sindyy .viewdetailscls .materialnrs {
        color: #40404e;
        font-size: 14px;
    }

    .sindyy .viewdetailscls .drag-list td:nth-of-type(1), .sindyy .viewdetailscls .mmodity th:nth-of-type(1) {
        width: 130px;
    }

    .sindyy .viewdetailscls .drag-list td:nth-of-type(2), .sindyy .viewdetailscls .mmodity th:nth-of-type(2) {
        width: 200px;
    }

    .sindyy .viewdetailscls .drag-list td:nth-of-type(3), .sindyy .viewdetailscls .mmodity th:nth-of-type(3) {
        width: 150px;
    }

    .sindyy .viewdetailscls .drag-list td:nth-of-type(4), .sindyy .viewdetailscls .mmodity th:nth-of-type(4) {
        width: 150px;
    }

    .sindyy .viewdetailscls .drag-list td:nth-of-type(5), .sindyy .viewdetailscls .mmodity th:nth-of-type(5) {
        width: 100px;
    }

    .sindyy .viewdetailscls .drag-list td:nth-of-type(6), .sindyy .viewdetailscls .mmodity th:nth-of-type(6) {
        width: 100px;
    }

    .sindyy .viewdetailscls .drag-list td:nth-of-type(7), .sindyy .viewdetailscls .mmodity th:nth-of-type(7) {
        width: 100px;
    }

    .sindyy .viewdetailscls .drag-list td:nth-of-type(8), .sindyy .viewdetailscls .mmodity th:nth-of-type(8) {
        width: 100px;
    }

    .sindyy .viewdetailscls .drag-list td:nth-of-type(9), .sindyy .viewdetailscls .mmodity th:nth-of-type(9) {
        width: 100px;
    }

    .sindyy .viewdetailscls .drag-list td:nth-of-type(10), .sindyy .viewdetailscls .mmodity th:nth-of-type(10) {
        width: 130px;
    }

    .sindyy .viewdetailscls .drag-list td:nth-of-type(11), .sindyy .viewdetailscls .mmodity th:nth-of-type(11) {
        width: 150px;
    }

    .sindyy .viewdetailscls .drag-list td:nth-of-type(12), .sindyy .viewdetailscls .mmodity th:nth-of-type(12) {
        width: 150px;
    }

    .sindyy .viewdetailscls .drag-list td:nth-of-type(13), .sindyy .viewdetailscls .mmodity th:nth-of-type(13) {
        width: 130px;
    }

    /* 添加物料 */
    /* 模糊查询 */
    .sindyy .search .el-dialog {
        width: 450px;
        /* width: 50vw !important;
        min-width: 550px !important;
        max-width:560px !important; */
    }

    /* 物料信息 */
    .sindyy .search .materialsoutformation {
        margin-top: 20px;
        padding-top: 10px;
        border-top: 2px solid rgb(88, 88, 88);
    }

    .sindyy .search .materialsoutformation .information {
        color: #40404e;
        font-size: 14px;
        margin-bottom: 12px;
    }

    .sindyy .search .materialsoutformation .materialnr {
        color: #40404e;
    }

    .sindyy .search .materialsoutformation .protyfsfg {
        margin: 0 0 10px;
        color: #40404e;
        width: 360px;
        display: flex;
        justify-content: space-between;
    }

    .sindyy .search .materialsoutformation .protyfsfg input {
        width: 230px;
    }

    .sindyy .search .zhuixiaoi .limiting .drag-list td {
        /* height: 14px;
        line-height: 20px;
        padding: 23px 0; */
        line-height: 20px;
        display: flex;
        justify-content: center;
        align-items: center;
        line-height: none;
    }

    .sindyy .search .el-input-number {
        width: 100%;
    }

    .sindyy .search .drag-list td:nth-of-type(2), .sindyy .search .mmodity th:nth-of-type(2) {
        width: 300px;
    }

    .sindyy .search .drag-list td:nth-of-type(3), .sindyy .search .mmodity th:nth-of-type(3) {
        width: 90px;
    }

    .sindyy .search .drag-list td:nth-of-type(4), .sindyy .search .mmodity th:nth-of-type(4) {
        width: 90px;
    }

    .sindyy .search .drag-list td:nth-of-type(5), .sindyy .search .mmodity th:nth-of-type(5) {
        width: 150px;
    }

    /* 字体不居中 */
    .sindyy .search .el-input-number .el-input__inner {
        text-align: left;
    }

    /* 仓库列表 */
    .zsykd {
        width: 100%;
        overflow-x: scroll !important;
        /*margin-top: 6px;*/
    }

    .sindyy .zhuixiaoi {
        /* width: 1085px;m */
        /* width: 70vw; */
        /* min-width: 1040px;
        max-width: 1100px; */
        /* height: 60vh; */
        /* max-height: 340px !important; */
        /* max-height: 800px !important; */
        overflow: hidden;
        /* display: inline-block; */
        border-collapse: collapse;
        /* border: solid 1px #f5f5f5; */
        color: #40404e;
    }

    .sindyy .zhuixiaoi .mmodity tr th {
        height: 40px;
        line-height: 40px;
        text-align: left;
        font-weight: 600;
        padding-left: 20px;
        color: #40404e;
    }
    .sindyy .zhuixiaoi .mmodity tr th .el-checkbox__label {
        font-size: 14px;
        font-weight: 600;
        color: #40404e;
    }

    .sindyy .zhuixiaoi .limiting .drag-list td {
        height: 40px;
        line-height: 40px;
        text-align: left;
        white-space: normal;
        word-break: break-all;
        padding-left: 20px;
    }

    .sindyy .zhuixiaoi .limiting .drag-list {
        display: block;
        border-top: solid 1px #f5f5f5;
        display: flex;
    }

    .sindyy .zhuixiaoi .mmodity {
        width: 100%;
        display: block;
    }

    .sindyy .zhuixiaoi .mmodity tr {
        border-top: solid 1px #f5f5f5;
        display: flex;
        background-color: #f5f5f5;
    }

    .sindyy .zhuixiaoi .limiting {
        /*border-top: solid 1px #f5f5f5;*/
        overflow-y: auto !important;
        max-height: 540px;
        border-bottom: solid 1px #f5f5f5;
        display: block;
    }

    .sindyy .meisfgr {
        width: 100%;
        overflow-x: scroll !important;
        /* border-right:1px solid #f5f5f5; */
        /* border-left:1px solid #f5f5f5; */
    }


    .sindyy .meisfgr .drag-list td:nth-of-type(1), .sindyy .meisfgr .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .sindyy .meisfgr .drag-list td:nth-of-type(2), .sindyy .meisfgr .mmodity th:nth-of-type(2) {
        width: 130px;
    }

    .sindyy .meisfgr .drag-list td:nth-of-type(3), .sindyy .meisfgr .mmodity th:nth-of-type(3) {
        width: 150px;
    }

    .sindyy .meisfgr .drag-list td:nth-of-type(4), .sindyy .meisfgr .mmodity th:nth-of-type(4) {
        width: 200px;
    }

    .sindyy .meisfgr .drag-list td:nth-of-type(5), .sindyy .meisfgr .mmodity th:nth-of-type(5) {
        width: 200px;
    }

    .sindyy .meisfgr .drag-list td:nth-of-type(6), .sindyy .meisfgr .mmodity th:nth-of-type(6) {
        width: 200px;
    }

    .sindyy .meisfgr .drag-list td:nth-of-type(7), .sindyy .meisfgr .mmodity th:nth-of-type(7) {
        width: 120px;
    }

    .sindyy .meisfgr .drag-list td:nth-of-type(8), .sindyy .meisfgr .mmodity th:nth-of-type(8) {
        width: 100px;
    }

    .sindyy .meisfgr .drag-list td:nth-of-type(9), .sindyy .meisfgr .mmodity th:nth-of-type(9) {
        width: 100px;
    }

    .sindyy .meisfgr .drag-list td:nth-of-type(10), .sindyy .meisfgr .mmodity th:nth-of-type(10) {
        width: 150px;
    }

    .sindyy .meisfgr .drag-list td:nth-of-type(11), .sindyy .meisfgr .mmodity th:nth-of-type(11) {
        width: 120px;
    }

    .sindyy .meisfgr .drag-list td:nth-of-type(12), .sindyy .meisfgr .mmodity th:nth-of-type(12) {
        width: 120px;
    }

    .sindyy .meisfgr .drag-list td:nth-of-type(13), .sindyy .meisfgr .mmodity th:nth-of-type(13) {
        width: 120px;
    }

    .sindyy .meisfgr .drag-list td:nth-of-type(14), .sindyy .meisfgr .mmodity th:nth-of-type(14) {
        width: 120px;
    }

    .sindyy .meisfgr .drag-list td:nth-of-type(15), .sindyy .meisfgr .mmodity th:nth-of-type(15) {
        width: 150px;
    }

    .sindyy .drag-list td:nth-of-type(1), .sindyy .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .sindyy .mmodity th:nth-of-type(2), .sindyy .drag-list td:nth-of-type(2) {
        width: 150px;
    }

    .sindyy .drag-list td:nth-of-type(3), .sindyy .mmodity th:nth-of-type(3) {
        width: 130px;
    }

    .sindyy .drag-list td:nth-of-type(4), .sindyy .mmodity th:nth-of-type(4) {
        width: 140px;
    }

    .sindyy .drag-list td:nth-of-type(5), .sindyy .mmodity th:nth-of-type(5) {
        width: 140px;
    }

    .sindyy .drag-list td:nth-of-type(6), .sindyy .mmodity th:nth-of-type(6) {
        width: 140px;
    }

    .sindyy .drag-list td:nth-of-type(7), .sindyy .mmodity th:nth-of-type(7) {
        width: 140px;
    }

    .sindyy .drag-list td:nth-of-type(8), .sindyy .mmodity th:nth-of-type(8) {
        width: 140px;
    }

    .sindyy .drag-list td:nth-of-type(9), .sindyy .mmodity th:nth-of-type(9) {
        width: 130px;
    }

    .sindyy .drag-list td:nth-of-type(10), .sindyy .mmodity th:nth-of-type(10) {
        width: 150px;
    }

    .sindyy .drag-list:nth-of-type(odd) {
        background-color: #f9f9f9;
        color: #40404e;
    }

    .sindyy .drag-list:nth-of-type(even) {
        background-color: #f5f5f5;
        color: #40404e;
    }

    .sindyy .zhuixiaoi .el-checkbox__label {
        color: #40404e;
    }

    .sindyy .zhuixiaoi .mmodity .el-checkbox__label {
        font-size: 12px;
    }

    /*  */
    .sindyy .zhuixiaoi .chaoguogai {
        height: 20px;
        /* text-align: center; */
        line-height: 20px;
        width: 136px;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    /* 日期选择器 */
    .sindyy .sindyy-rkrq .rkrq .el-range-editor .el-range-input {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
    }

    .sindyy .sindyy-rkrq .rkrq .el-date-editor .el-range-separator, .sindyy .sindyy-rkrq .rkrq .el-date-editor .el-range__icon {
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
    .sindyy .Pagination {
        /*width: 1600px;*/
        text-align: right;
        margin-top: 20px;
    }

    .sindyy .Pagination .el-pagination.is-background .btn-next, .sindyy .Pagination .el-pagination.is-background .btn-prev, .sindyy .Pagination .el-pagination.is-background .el-pager li {
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #606266;
        color: #40404e;
    }

    .sindyy .Pagination .btn-prev {
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #606266;

    }

    .sindyy .Pagination .el-pagination {
        padding: 0;
    }

    .sindyy .Pagination .el-pagination .btn-next .el-icon, .sindyy .Pagination .el-pagination .btn-prev .el-icon {
        color: #40404e;
    }

    .sindyy .Pagination .el-pagination.is-background .el-pager li:not(.disabled).active {
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

        .printsindyy .nrxx {
            color: #000;
            font-size: 20px;
            display: inline-block;
            padding-top: 30px;
        }

        .printsindyy .nr .nrxx {
            padding-top: 10px;
        }

        .printsindyy .monad {
            font-weight: bold;
            display: block;
            font-size: 30px;
            margin-top: 50px;
            color: #000;
            text-align: center;
        }

        .printsindyy .tidsesfe {
            display: flex;
        }

        .printsindyy .compatibility {
            display: flex;
            align-items: center;
        }

        .printsindyy .mandatory {
            color: #000;
            width: 140px;
            text-align: right;
            /* padding-top: 10px; */
        }

        .printsindyy .controlling {
            width: 370px !important;
            line-height: 40px;
        }

        .printsindyy .reqfieldsd {
            font-size: 14px;
            padding-right: 4px;
            color: #ce4153;
            /* 文字不可选中 */
            -webkit-user-select: none;
            -moz-user-select: none;
            -ms-user-select: none;
            user-select: none;
        }

        .printsindyy .zhuixiaoi {
            overflow: hidden;
            border-collapse: collapse;
            color: #000;
        }

        .printsindyy .zhuixiaoi tr th {
            height: 36px;
            line-height: 36px;
            text-align: center;
            /* border: solid 1px #f5f5f5; */
            border-top: solid 1px #f5f5f5;
            border-right: solid 1px #f5f5f5;
            border-bottom: solid 1px #f5f5f5;
            background-color: #2d2e38;
            font-weight: 400;
        }

        .printsindyy .zhuixiaoi .mmodity th:nth-of-type(1) {
            border-left: solid 1px #f5f5f5;
        }

        .printsindyy .zhuixiaoi .limiting .drag-list td {
            height: 36px;
            line-height: 36px;
            text-align: center;
            white-space: normal;
            word-break: break-all;
            /* border: solid 1px #f5f5f5; */
            border-bottom: solid 1px #f5f5f5;
            border-right: solid 1px #f5f5f5;
        }

        .printsindyy .zhuixiaoi .limiting .drag-list td:nth-of-type(1) {
            border-left: solid 1px #f5f5f5;
        }

        .printsindyy .zhuixiaoi .limiting .drag-list {
            display: block;
            display: flex;

        }

        .printsindyy .zhuixiaoi .mmodity {
            width: 100%;
            display: block;
        }

        .printsindyy .zhuixiaoi .mmodity tr {
            display: flex;
        }

        .printsindyy .el-form-item {
            display: flex;
            margin: 0;
        }

        .printsindyy .drag-list td, .printsindyy .mmodity th {
            font-size: 13px;
        }

        .printsindyy .el-dialog {
            width: 1100px;
        }

        .printsindyy .el-form {
            padding-top: 10px;
        }

        .printsindyy .addmaterial {
            display: flex;
            justify-content: center;
        }

        .printsindyy .materialnr {
            width: 200px;
        }

        .printsindyy .materialnrs {
            width: 600px;
        }

        .printsindyy .materialnr, .printsindyy label, .printsindyy .materialnrs {
            color: #000;
        }

        .printsindyy .zhuixiaoi {
            margin-top: 20px;
        }

        .printsindyy .drag-list td:nth-of-type(1), .printsindyy .mmodity th:nth-of-type(1) {
            width: 150px;
        }

        .printsindyy .drag-list td:nth-of-type(2), .printsindyy .mmodity th:nth-of-type(2) {
            width: 110px;
        }

        .printsindyy .drag-list td:nth-of-type(3), .printsindyy .mmodity th:nth-of-type(3) {
            width: 110px;
        }

        .printsindyy .drag-list td:nth-of-type(4), .printsindyy .mmodity th:nth-of-type(4) {
            width: 110px;
        }

        .printsindyy .drag-list td:nth-of-type(5), .printsindyy .mmodity th:nth-of-type(5) {
            width: 110px;
        }

        .printsindyy .drag-list td:nth-of-type(6), .printsindyy .mmodity th:nth-of-type(6) {
            width: 150px;
        }

        .printsindyy .drag-list td:nth-of-type(7), .printsindyy .mmodity th:nth-of-type(7) {
            width: 170px;
        }

        .printsindyy .drag-list td:nth-of-type(8), .printsindyy .mmodity th:nth-of-type(8) {
            width: 130px;
        }

        .printsindyy .signature {
            display: flex;
            margin-top: 50px;
        }

        .printsindyy .signature > div {
            margin-left: 30px;
            display: flex;
        }

        .printsindyy .signature span {
            font-size: 20px;
        }

        .printsindyy .signature .xian {
            width: 180px;
            height: 30px;
            border-bottom: 1px solid #000;
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