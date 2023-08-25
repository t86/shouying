<template>
    <div class="freelmt">
        <div class="freelmt-controller">
            <icon-button @click.native="xingh" text="新增" img="添加.png" colors="#383943"></icon-button>
            <icon-button @click.native="compileprinter" text="编辑" img="编辑.png" colors="#383943"></icon-button>
            <icon-button @click.native="printerdel" text="批量删除" img="删除.png" colors="#6B2830"
                         bjcolors="#491E24"></icon-button>
        </div>
        <div style="position: relative">
            <div class="zsykd" style="display: inline-block;">
                <table class="zhuixiaoi">
                    <thead class="mmodity">
                    <tr>
                        <th>
                            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll"
                                         @change="handleCheckAllChange">
                                全选&ensp;
                            </el-checkbox>
                        </th>
                        <th>名称</th>
                        <th>日限量</th>
                        <th>日限额</th>
                        <th>月限量</th>
                        <th>月限额</th>
                        <th>商品组数量</th>
                        <th>创建时间</th>
                        <th>更新时间</th>
                    </tr>
                    </thead>
                    <tbody class="limiting" ref="systemForm" @scroll="sysHandleScroll()"
                           @mouseover="changeFlag(false)" :style="{'border-bottom':tableData.length<1?'0px':'',
                'width':tableData.length>MaxNumber?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`}">
                    <tr v-for="(item,i) in tableData" :key="item.id" class="drag-list"
                        :class="multipleSelection.includes(item.id)? 'drag-list-check':''">
                        <td :style="{'color':item.s=='无效'?'#595959':''}">
                            <el-checkbox-group v-model="multipleSelection" @change="handleCheckedCitiesChange">
                                <el-checkbox :label="item.id">{{i+1}}&emsp;&ensp;</el-checkbox>
                            </el-checkbox-group>
                        </td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.n}}</td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.dc}}</td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.da}}</td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.mc}}</td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.ma}}</td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.ic || '---'}}</td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.c || '---'}}</td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.u}}</td>
                    </tr>
                    </tbody>
                </table>
                <div class="drag-list" v-if="tableData.length<1">
                    <td class="nodata" :style="{'height':`${MaxHeight}px !important`}">
                        <img src="@/assets/img/wu.png" alt="">
                        <div class="hint">暂无数据</div>
                    </td>
                </div>
            </div>
            <div style="display: inline-block;position: absolute;top: 0;left: 0;z-index: 100;">
                <table class="zhuixiaoi zhuixiaoi_l" style="width: auto;">
                    <thead class="mmodity">
                    <tr>
                        <th>
                            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll"
                                         @change="handleCheckAllChange">
                                全选&ensp;
                            </el-checkbox>
                        </th>
                        <th>名称</th>
                    </tr>
                    </thead>
                    <tbody class="limiting" ref="externalForm" @scroll="exterHandleScroll()"
                           @mouseover="changeFlag(true)" :style="{'border-bottom':tableData.length<1?'0px':'',
                'width':tableData.length>MaxNumber?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`}">
                    <tr v-for="(item,i) in tableData" :key="item.id" class="drag-list"
                        :class="multipleSelection.includes(item.id)? 'drag-list-check':''">
                        <td :style="{'color':item.s=='无效'?'#595959':''}">
                            <el-checkbox-group v-model="multipleSelection" @change="handleCheckedCitiesChange">
                                <el-checkbox :label="item.id">{{i+1}}&emsp;&ensp;</el-checkbox>
                            </el-checkbox-group>
                        </td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.n}}</td>
                    </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <div v-show="dialogFormVisible" class="dialogFormVisible">
            <el-dialog :title="title?'新增':'编辑'" @close="dialogFormVisible = false" :visible.sync="dialogFormVisible"
                       :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>名称：
                        </div>
                        <el-input v-model="freelmt.name" placeholder="请输入名称" ref="selectsse"
                                  show-word-limit class="controlling" :class="form_rule_msg_name?'error':''"
                                  @blur="validator('name')"/>
                        <div class="cwts">{{form_rule_msg_name}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>日限数量：
                        </div>
                        <div class="controlling">
                            <el-radio v-model="freelmt.DayCntLimitsf" :label="true">不限</el-radio>
                            <el-radio v-model="freelmt.DayCntLimitsf" :label="false">限制</el-radio>
                            <div style="display: flex;align-items: center;">
                                <el-input v-model="freelmt.DayCntLimitsz" :disabled="freelmt.DayCntLimitsf"/> &ensp;
                                <div>个</div>
                            </div>

                        </div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>日限金额：
                        </div>
                        <div class="controlling">
                            <el-radio v-model="freelmt.DayAmtLimitsf" :label="true">不限</el-radio>
                            <el-radio v-model="freelmt.DayAmtLimitsf" :label="false">限制</el-radio>
                            <div style="display: flex;align-items: center;">
                                <el-input v-model="freelmt.DayAmtLimitsz" :disabled="freelmt.DayAmtLimitsf"/> &ensp;
                                <div>元</div>
                            </div>
                        </div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>月限数量：
                        </div>
                        <div class="controlling">
                            <el-radio v-model="freelmt.MonthCntLimitsf" fill='#ce4153' :label="true">不限</el-radio>
                            <el-radio v-model="freelmt.MonthCntLimitsf" fill='#ce4153' :label="false">限制</el-radio>
                            <div style="display: flex;align-items: center;">
                                <el-input v-model="freelmt.MonthCntLimitsz" :disabled="freelmt.MonthCntLimitsf"/> &ensp;
                                <div>个</div>
                            </div>
                        </div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>月限金额：
                        </div>
                        <div class="controlling">
                            <el-radio v-model="freelmt.MonthAmtLimitsf" :label="true">不限</el-radio>
                            <el-radio v-model="freelmt.MonthAmtLimitsf" :label="false">限制</el-radio>
                            <div style="display: flex;align-items: center;">
                                <el-input v-model="freelmt.MonthAmtLimitsz" :disabled="freelmt.MonthAmtLimitsf"/> &ensp;
                                <div>元</div>
                            </div>
                        </div>
                    </div>
                </el-form>
                <div class="dotwire"></div>
                <div class="compatibility">
                    <div style="width: 250px; color: #40404e ;margin-left: 60px;">
                        <span class="reqfieldsd">*</span>商品组（至少选择一个商品组）：
                    </div>

                </div>
                <div class="compatibility">
                    <div class="mandatory">
                        <span class="reqfieldsd"></span>
                    </div>
                    <div class="controllings">
                        <el-tree
                                ref="defaultnode"
                                node-key="id"
                                :data="Commodimessage"
                                show-checkbox
                                :props="defaultProps"
                                @check="handleBucketClick"
                                :default-checked-keys="Selecteefault"
                                empty-text='暂无商品组，请先创建'
                        >
                        </el-tree>
                    </div>
                </div>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFormVisible = false">取消</el-button>
                    <el-button v-show="title" type="primary" @click="construction">新建</el-button>
                    <el-button v-show="!title" type="primary" @click="saveprinter">保存</el-button>
                    <!-- <el-button  type="primary" @click="construction">新建</el-button> -->
                </span>
            </el-dialog>
        </div>
    </div>
</template>
<script>
import IconButton from '@/components/IconButton.vue'//根据路径导入组件
export default {
  data(){
    return {
      tableData: [],//区域
      dialogFormVisible: false,//控制新增是否显示
      freelmt: {
        name: '',
        DayCntLimitsf: true,//日限数量
        DayCntLimitsz: '',
        DayAmtLimitsf: true,//日限金额
        DayAmtLimitsz: '',
        MonthCntLimitsf: true,//月限数量
        MonthCntLimitsz: '',
        MonthAmtLimitsf: true,//月限金额
        MonthAmtLimitsz: '',
      },//限额限量

      Commodimessage: [],//选择二级列表全部内容
      defaultProps: {
        children: 'ts',
        label: 'n'
      },
      Selecteefault: [],// 默认选中节点
      xzclassify: [],//选中的商品组
      title: true,// 判断是新建还是编辑

      multipleSelection: [],// 选中的内容
      isIndeterminate: false,// 供应商选择一部分
      checkAll: false,//供应商全选
      windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
      MaxHeight: 0,//滚动高度
      MaxNumber: 0,//最大个数

      form_rules: ["name"],
      form_rule_msg_name: "",

      flag: false
    }
  },
  components: {
    IconButton
  },
  mounted(){
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
  computed: {},
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
        case "name":
          if (this.freelmt.name == '') {
            this.form_rule_msg_name = '请输入名称'
          } else if (this.$overall.character(this.freelmt.name) > 20) {
            this.form_rule_msg_name = '输入文字长度超过10'
          } else {
            this.form_rule_msg_name = ''
          }
          break
      }
    },
    // 滚动最大高度
    RollMaxHeight(i){
      var s = i - 48 - 60 - 55 - 37
      this.MaxHeight = s
      this.MaxNumber = Math.floor(s / 37)
      console.log(this.MaxNumber);
      // console.log(i);
    },
    //获取焦点
    edit(){
      this.$nextTick(() => {  //次要代码
        this.$refs.selectsse.focus();
        //   console.log(this.$refs);
      })
    },
    // 选择全选或取消
    handleCheckAllChange(val) {
      if (val) {
        this.multipleSelection = []
        for (const key in this.tableData) {
          this.multipleSelection.push(this.tableData[key].id)
        }
      } else {
        this.multipleSelection = []
      }
      this.isIndeterminate = false;
    },
    // 控制单个选中
    handleCheckedCitiesChange(value) {
      let checkedCount = value.length;
      this.checkAll = checkedCount === this.tableData.length;
      this.isIndeterminate = checkedCount > 0 && checkedCount < this.tableData.length;
    },
    // 获取低消组管理列表
    demand(){
      this.$api.BMS.freelmt.requestfreelmtlist().then(res => {
        console.log(res);
        if (res.code == 1) {
          this.tableData = res.data || []
        } else {
          this.$message.warning(res.msg)
        }
      })

    },
    // 点开创建  获取信息
    xingh(){
      this.form_rule_msg_name = ''
      this.freelmt = {
        name: '',
        DayCntLimitsf: true,//日限数量
        DayCntLimitsz: '',
        DayAmtLimitsf: true,//日限金额
        DayAmtLimitsz: '',
        MonthCntLimitsf: true,//月限数量
        MonthCntLimitsz: '',
        MonthAmtLimitsf: true,//月限金额
        MonthAmtLimitsz: '',
      }
      this.dialogFormVisible = true
      this.title = true
      this.edit()
      this.xzclassify = []
      this.Selecteefault = []
      this.$api.BMS.freelmt.requestfreelmtget({id: 0}).then(res => {
        console.log(res);
        if (res.code == 1) {
          this.Commodimessage = [{
            n: '以下全部',
            ts: res.data.prd_grps || [],
          }]
        } else {
          this.$message.warning(res.msg)
        }
      })
      // console.log(this.xzclassify);
    },
    // 选中的节点
    handleBucketClick(nodeObj, SelectedObj){
      console.log(SelectedObj.checkedKeys)   // 这是选中的节点的key数组
      this.xzclassify = []
      for (const iterator of SelectedObj.checkedKeys) {
        if (iterator != undefined) {
          this.xzclassify.push(iterator)
        }
      }
    },
    // 创建限额限量
    construction(){
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_name) return;
      this.$api.BMS.freelmt.requestfreelmtnew({
        name: this.freelmt.name,
        day_cnt_limit: Number(this.freelmt.DayCntLimitsf ? '-1' : this.freelmt.DayCntLimitsz),
        day_amt_limit: Number(this.freelmt.DayAmtLimitsf ? '-1' : this.freelmt.DayAmtLimitsz),
        month_cnt_limit: Number(this.freelmt.MonthCntLimitsf ? '-1' : this.freelmt.MonthCntLimitsz),
        month_amt_limit: Number(this.freelmt.MonthAmtLimitsf ? '-1' : this.freelmt.MonthAmtLimitsz),
        prd_grps: this.xzclassify,
      }).then(res => {
        console.log(res);
        if (res.code == 1) {
          this.$message({
            showClose: true,
            message: "新增成功",
            type: 'success'
          })
          this.demand()
          this.dialogFormVisible = false
          this.bempty()
        } else {
          this.$message.warning(res.msg)
        }
      })

    },

    // 编辑内容
    compileprinter(){
      if (this.multipleSelection.length == 1) {
        this.form_rule_msg_name = ''
        this.$api.BMS.freelmt.requestfreelmtget({id: this.multipleSelection[0]}).then(res => {
          if (res.code == 1) {
            console.log(res.data);
            this.xzclassify = []

            this.Commodimessage = [{
              n: '以下全部',
              ts: res.data.prd_grps || [],
            }]
            for (const iterator of res.data.prd_grps) {
              if (iterator.s == 1) {
                this.Selecteefault.push(iterator.id)
                this.xzclassify.push(iterator.id)
              }
            }
            this.freelmt = {
              name: res.data.name,
              DayCntLimitsf: res.data.day_cnt_limit == -1 ? true : false,//日限数量
              DayCntLimitsz: res.data.day_cnt_limit == -1 ? '' : res.data.day_cnt_limit,
              DayAmtLimitsf: res.data.day_amt_limit == -1 ? true : false,//日限金额
              DayAmtLimitsz: res.data.day_amt_limit == -1 ? '' : res.data.day_amt_limit,
              MonthCntLimitsf: res.data.month_cnt_limit == -1 ? true : false,//月限数量
              MonthCntLimitsz: res.data.month_cnt_limit == -1 ? '' : res.data.month_cnt_limit,
              MonthAmtLimitsf: res.data.month_amt_limit == -1 ? true : false,//月限金额
              MonthAmtLimitsz: res.data.month_amt_limit == -1 ? '' : res.data.month_amt_limit,
            }

            this.dialogFormVisible = true
            this.title = false
          } else {
            this.$message.warning(res.msg)
          }
        })
      } else {
        this.$message({
          message: '请选择一个进行编辑',
          type: 'warning',
        })
      }
    },
    // 保存编辑内容
    saveprinter(){
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_name) return;
      this.$api.BMS.freelmt.requestfreelmtsave({
        id: this.multipleSelection[0],
        name: this.freelmt.name,
        day_cnt_limit: Number(this.freelmt.DayCntLimitsf ? '-1' : this.freelmt.DayCntLimitsz),
        day_amt_limit: Number(this.freelmt.DayAmtLimitsf ? '-1' : this.freelmt.DayAmtLimitsz),
        month_cnt_limit: Number(this.freelmt.MonthCntLimitsf ? '-1' : this.freelmt.MonthCntLimitsz),
        month_amt_limit: Number(this.freelmt.MonthAmtLimitsf ? '-1' : this.freelmt.MonthAmtLimitsz),
        prd_grps: this.xzclassify,
      }).then(res => {
        console.log(res);
        if (res.code == 1) {
          this.$message({
            showClose: true,
            message: "操作成功",
            type: 'success'
          })
          this.demand()
          this.dialogFormVisible = false
          this.bempty()
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 删除
    printerdel(){
      if (this.multipleSelection.length > 0) {
        this.$api.BMS.freelmt.requestfreelmtdel({ids: this.multipleSelection}).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.demand()
            this.$message({
              showClose: true,
              message: "操作成功",
              type: 'success'
            })
            this.bempty()
          } else {
            this.$message.warning(res.msg)
          }
        })
      } else {
        this.$message({
          message: '请先选择区域',
          type: 'warning',
        })
      }

    },
    // 为空
    bempty(){
      this.multipleSelection = []
      this.isIndeterminate = false
      this.checkAll = false
    }
  },
  computed: {
    freelmts(){
      return JSON.parse(JSON.stringify(this.freelmt))
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
    freelmts: {
      deep: true,
      handler: function (after, before) {
        var reg = /^[0-9]*$/
        console.log(reg.test(after.DayCntLimitsz));
        if (!reg.test(after.DayCntLimitsz)) {
          this.freelmt.DayCntLimitsz = before.DayCntLimitsz
          this.$message.warning('请输入数字')
        }
        if (!reg.test(after.DayAmtLimitsz)) {
          this.freelmt.DayAmtLimitsz = before.DayAmtLimitsz
          this.$message.warning('请输入数字')
        }
        if (!reg.test(after.MonthCntLimitsz)) {
          this.freelmt.MonthCntLimitsz = before.MonthCntLimitsz
          this.$message.warning('请输入数字')
        }
        if (!reg.test(after.MonthAmtLimitsz)) {
          this.freelmt.MonthAmtLimitsz = before.MonthAmtLimitsz
          this.$message.warning('请输入数字')
        }
      }
    }
  }
}
</script>
<style>
    /* 靠右 */
    .freelmt .el-dialog {
        margin: 0px 0px 0px auto !important;
        background-color: #f9f9f9;
        height: 100%;
        position: relative;
    }

    .freelmt .el-dialog__footer {
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }

    .freelmt .el-dialog__body {
        padding: 0px 0px 30px 20px;
        overflow-y: scroll !important;
        /* width: 100%; */
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;
    }

    .freelmt .el-dialog {
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .freelmt {
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding: 20px 30px;
    }

    /* 树状结构 */
    .freelmt .dialogFormVisible .el-tree-node__content:hover, .el-tree-node__content, .el-tree-node:focus > .el-tree-node__content {
        background-color: transparent;
    }

    .freelmt .dialogFormVisible .el-tree {
        color: #40404e;
        background-color: transparent;
    }

    /* 输入框禁用颜色 */
    .el-input.is-disabled .el-input__inner {
        background-color: rgba(255, 255, 255, 0.075);
    }

    /* 单选框框文字颜色 */
    .el-radio {
        color: #40404e;
    }

    /* 必填 */
    .freelmt .mandatory {
        color: #40404e;
        width: 140px;
        text-align: right;
    }

    .freelmt .controlling {
        color: #40404e;
        width: 280px !important;
        display: flex;
        align-items: center;
    }

    .freelmt .controllings {
        color: #40404e;
        width: 280px !important;
    }

    .freelmt .reqfieldsd {
        font-size: 14px;
        padding-right: 4px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 表格无数据时展示 */
    .freelmt .tiaodd {
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

    .freelmt .nodata {
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        padding: 0;
    }

    .freelmt .nodata img {
        width: 60px;
        height: 60px;
    }

    .freelmt .nodata .hint {
        line-height: 36px;
        font-size: 13px !important;
    }

    /* 改限制字体数量的颜色背景 */
    .freelmt .el-input .el-input__count .el-input__count-inner {
        background: none;
        color: #40404e;
    }

    .freelmt .el-input__suffix {
        background-color: #1A1A20;
        color: #40404e;
        right: -45px;
        /* height: 20px; */
        top: 8px;
        /* line-height: 20px; */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .freelmt .compatibility {
        display: flex;
        align-items: center;
        margin-bottom: 10px;
    }

    .freelmt-headline {
        font-size: 30px;
        font-weight: bold;
        color: #40404e;
    }

    .freelmt-controller {
        /*margin-top: 30px;*/
        height: 54px;
        /*width: 1600px;*/
        background-color: #eee;
        display: flex;
        align-items: center;
    }

    .freelmt .dialogFormVisible .el-dialog {
        width: 620px !important;
    }

    /* 点线 */
    .freelmt .dialogFormVisible .dotwire {
        width: 100%;
        border-top: 1px dotted #383943;
        margin-bottom: 10px;
    }

    /* 单选框改变颜色 */
    .freelmt .el-radio__inner {
        background-color: transparent !important;
    }

    .el-radio__input.is-checked+.el-radio__label{
      color: #2A5DE9;
    }

    .freelmt .el-radio__input.is-checked .el-radio__inner {
        background-color: #2A5DE9 !important;
    }

    .freelmt .el-radio__inner::after {
        background-color: #e5e5e5 !important;
    }

    .freelmt .el-dialog .el-button--default {
        background-color: #ccc;
        border: 1px solid #ccc;
        color: #40404e;
    }

    .freelmt .el-dialog {
        background-color: #f9f9f9;
    }

    .freelmt .el-dialog__header, .freelmt .el-dialog__footer {
        background-color: #22232B;
    }

    .freelmt .el-dialog__title, .freelmt .el-dialog__headerbtn .el-dialog__close, .freelmt .el-form-item__label {
        color: #1a1a21;
    }

    .freelmt .el-checkbox__input {
        background-color: transparent;
    }

    .freelmt .el-dialog {
        width: 30vw;
    }

    /* 改变多选框背景颜色和上下间距 */
    .freelmt .el-checkbox-group {
        display: flex;
        align-items: flex-end;
        justify-content: left;
    }

    .freelmt .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    /* 列表 */
    .zsykd {
        width: 100%;
        overflow-x: scroll !important;
    }

    .freelmt .zhuixiaoi {
        width: 1600px;
        border-collapse: collapse;
        color: #40404e;
    }

    .freelmt .zhuixiaoi .mmodity tr th {
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-size: 14px;
        font-weight: 600;
        color: #40404e;
        padding-left: 20px;
    }

    .freelmt .zhuixiaoi .mmodity tr th .el-checkbox__label {
        font-size: 14px;
        font-weight: 600;
        color: #40404e;
    }

    .freelmt .zhuixiaoi .limiting .drag-list td {
        height: 36px;
        line-height: 36px;
        text-align: left;
        /*border-right: solid 1px #383943;*/
        /*border-top: solid 1px #383943;*/
        font-size: 14px;
        font-weight: 400;
        padding-left: 20px;
    }

    .freelmt .zhuixiaoi .limiting .drag-list td:nth-of-type(1) {
        /*border-left: solid 1px #383943;*/
    }

    .freelmt .zhuixiaoi .limiting .drag-list {
        display: block;
        display: flex;
    }

    .freelmt .zhuixiaoi .mmodity {
        width: 100%;
        display: block;
    }

    .freelmt .zhuixiaoi .mmodity tr {
        background-color: #f5f5f5;
        display: flex;
    }

    .freelmt .zhuixiaoi .limiting {
        overflow-y: auto !important;
        max-height: 540px;
        display: block;
    }

    .freelmt .drag-list td:nth-of-type(1), .freelmt .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .freelmt .mmodity th:nth-of-type(2), .freelmt .drag-list td:nth-of-type(2) {
        width: 240px;
    }

    .freelmt .drag-list td:nth-of-type(3), .freelmt .mmodity th:nth-of-type(3) {
        width: 100px;
    }

    .freelmt .drag-list td:nth-of-type(4), .freelmt .mmodity th:nth-of-type(4) {
        width: 100px;
    }

    .freelmt .drag-list td:nth-of-type(5), .freelmt .mmodity th:nth-of-type(5) {
        width: 100px;
    }

    .freelmt .drag-list td:nth-of-type(6), .freelmt .mmodity th:nth-of-type(6) {
        width: 100px;
    }

    .freelmt .drag-list td:nth-of-type(7), .freelmt .mmodity th:nth-of-type(7) {
        width: 100px;
    }

    .freelmt .drag-list td:nth-of-type(8), .freelmt .mmodity th:nth-of-type(8) {
        width: 140px;
    }

    .freelmt .drag-list td:nth-of-type(9), .freelmt .mmodity th:nth-of-type(9) {
        width: 140px;
    }

    .freelmt .drag-list:nth-of-type(odd) {
        background-color: #f9f9f9;
        color: #40404e;
    }

    .freelmt .drag-list:nth-of-type(even) {
        background-color: #f5f5f5;
        color: #40404e;
    }

    /* 全选颜色 */
    .freelmt .zhuixiaoi .el-checkbox__label {
        color: #40404e;
    }

    .freelmt .zhuixiaoi .mmodity .el-checkbox__label {
        font-size: 12px;
    }

    .drag-list-check {
        /* background: rgba(39, 52, 82, .5) !important; */
    }
</style>

