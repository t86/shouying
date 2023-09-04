<template>
    <div class="supplier">
        <div class="supplier-controller">
            <icon-button @click.native="xingh" text="新增供应商" img="btn_add.png" colors="#383943"></icon-button>
            <icon-button @click.native="compileprinter" text="编辑" img="btn_edit.png" colors="#383943"></icon-button>
            <icon-button @click.native="noneffective" text="置为无效" img="btn_in_vain.png" colors="#383943"></icon-button>
            <icon-button @click.native="effective" text="置为有效" img="btn_effective.png" colors="#383943"></icon-button>
            <icon-button @click.native="printerdel" text="批量删除" img="btn_delete.png" colors="#6B2830"
                         bjcolors="#491E24"></icon-button>
        </div>
        <div class="zsykd" style="display: inline-block;">
            <table class="zhuixiaoi">
                <thead class="mmodity">
                <tr>
                    <th>
                        <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll" @change="handleCheckAllChange">
                            全选
                        </el-checkbox>
                    </th>
                    <th>供应商名称</th>
                    <th>联系人</th>
                    <th>联系电话</th>
                    <th>创建时间</th>
                    <th>更新时间</th>
                    <th>状态</th>
                </tr>
                </thead>
                <tbody class="limiting" :style="{'border-bottom':tableData.length<1?'0px':'',
            'width':tableData.length>12?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`}">
                <tr v-for="(item,i) in tableData" :key="item.id" class="drag-list"
                    :class="multipleSelection.includes(item.id)? 'drag-list-check':''">
                    <td :style="{'color':item.s=='无效'?'#595959':''}">
                        <el-checkbox-group v-model="multipleSelection" @change="handleCheckedCitiesChange">
                            <el-checkbox :label="item.id">{{i+1}}</el-checkbox>
                        </el-checkbox-group>
                    </td>
                    <td :style="{'color':item.s=='无效'?'#595959':'',}">
                        <ellipsis-tooltip :text="item.n || '-----'"></ellipsis-tooltip>
                    </td>
                    <td :style="{'color':item.s=='无效'?'#595959':'',}">
                        <ellipsis-tooltip :text="item.cn || '-----'"></ellipsis-tooltip>
                    </td>
                    <td :style="{'color':item.s=='无效'?'#595959':'',}">
                        <ellipsis-tooltip :text="item.pn || '-----'"></ellipsis-tooltip>
                    </td>
                    <td :style="{'color':item.s=='无效'?'#595959':'',}">
                        <ellipsis-tooltip :text="item.c || '-----'"></ellipsis-tooltip>
                    </td>
                    <td :style="{'color':item.s=='无效'?'#595959':'',}">
                        <ellipsis-tooltip :text="item.u || '-----'"></ellipsis-tooltip>
                    </td>
                    <td :style="{'color':item.s=='无效'?'#595959':'',}">
                        <ellipsis-tooltip :text="item.s || '-----'"></ellipsis-tooltip>
                    </td>
                </tr>
                </tbody>
            </table>
            <div class="drag-list" v-if="tableData.length<1">
                <td class="nodata" :style="{'height':`${MaxHeight}px !important`}">
                    <img src="../../../../assets/img/wu.png" alt="">
                    <div class="hint">暂无数据</div>
                </td>
            </div>
        </div>

        <!-- 新增供应商  编辑-->
        <div v-show="dialogFormVisible" class="dialogFormVisible">
            <el-dialog :title="title?'新增供应商':'编辑供应商'" :visible.sync="dialogFormVisible"
                       @close="dialogFormVisible = false" :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>供应商名称：
                        </div>
                        <el-input type="textarea" v-model="supplier.name" ref="selectsse" :rows="1"
                                  placeholder="请输入供应商名称" class="controlling" show-word-limit
                                  :class="form_rule_msg_name?'error':''" @blur="validator('name')"/>
                        <div class="cwts">{{form_rule_msg_name}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>联系人：
                        </div>
                        <el-input v-model="supplier.linkman" placeholder="请输入联系人" class="controlling"
                                  :class="form_rule_msg_linkman?'error':''" @blur="validator('linkman')"/>
                        <div class="cwts">{{form_rule_msg_linkman}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>手机号码：
                        </div>
                        <el-input v-model="supplier.number" placeholder="请输入手机号码" class="controlling"
                                  oninput="this.value = this.value.replace(/[^0-9]/g, '');"
                                  :class="form_rule_msg_number?'error':''" @blur="validator('number')"/>
                        <div class="cwts">{{form_rule_msg_number}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>电子邮箱：
                        </div>
                        <el-input v-model="supplier.mailbox" placeholder="请输入电子邮箱" class="controlling"
                                  :class="form_rule_msg_mailbox?'error':''" @blur="validator('mailbox')"/>
                        <div class="cwts">{{form_rule_msg_mailbox}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>地址：
                        </div>
                        <el-input type="textarea" v-model="supplier.site" :rows="2" placeholder="请输入地址"
                                  class="controlling" :class="form_rule_msg_site?'error':''" @blur="validator('site')"/>
                        <div class="cwts">{{form_rule_msg_site}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>备注：
                        </div>
                        <el-input type="textarea" v-model="supplier.remark" :rows="3" class="controlling"
                                  placeholder="请输入备注" show-word-limit
                                  :class="form_rule_msg_remark?'error':''" @blur="validator('remark')"/>
                        <div class="cwts">{{form_rule_msg_remark}}</div>
                    </div>
                </el-form>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFormVisible = false">取消</el-button>
                    <el-button v-show="title" type="primary" @click="construction">新建</el-button>
                    <el-button v-show="!title" type="primary" @click="saveprinter">确认</el-button>
                </span>
            </el-dialog>
        </div>


        <!-- 无效有效删除 -->
        <div v-show="dialogFible" class="diagrgeesfelogFor">
            <el-dialog :title="srnr" :visible.sync="dialogFible" @close="dialogFible = false"
                       :close-on-click-modal="false">
                <div class="wwent">以下对象存在依赖，需人工处理依赖</div>
                <div class="wentlb">
                    <table class="zhuixiaoi">
                        <thead class="mmodity">
                        <tr>
                            <th>序号</th>
                            <th>说明</th>
                        </tr>
                        </thead>
                        <tbody class="limiting" :style="{'width':cwsm.ns.length>16?'calc(100% + 6px)':'100%'}">
                        <tr v-for="(item,i) in cwsm.ns" :key="i" class="drag-list">
                            <td>{{i+1}}</td>
                            <td>
                                <ellipsis-tooltip :text="item || '-----'"></ellipsis-tooltip>
                            </td>
                        </tr>
                        <tr class="drag-list" v-if="cwsm.ns.length<1">
                            <td class="nodata">
                                <img src="../../../../assets/img/wu.png" alt="">
                                <div class="hint">暂无数据</div>
                            </td>
                        </tr>

                        </tbody>
                    </table>
                </div>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFible = false">取消</el-button>
                </span>
            </el-dialog>
        </div>

    </div>
</template>
<script>
import EllipsisTooltip from '@/components/EllipsisTooltip.vue'//根据路径导入组件
import IconButton from '@/components/IconButton.vue'//根据路径导入组件
export default {
  data(){
    return {
      tableData: [],//供应商目录
      dialogFormVisible: false,//控制新建供应商是否显示
      supplier: {
        name: '',//名称
        linkman: '',//联系人
        number: "",//手机号码
        mailbox: "",//邮箱
        site: "",//地址
        remark: "",//备注描述
      },//供应商
      quantity: [],// 判断哪个要亮
      title: true,//为新建还是编辑


      multipleSelection: [],// 选中的内容
      isIndeterminate: false,// 供应商选择一部分
      checkAll: false,//供应商全选

      dialogFible: false,//控制错误2是否显示
      srnr: '',//文案
      cwsm: {
        ns: [],
        cs: [],
      },//错误2说明
      windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
      MaxHeight: 0,//滚动高度
      MaxNumber: 0,//最大个数

      form_rules: ["name", "linkman", "number", "mailbox", "site", "remark"],
      form_rule_msg_name: "",
      form_rule_msg_linkman: "",
      form_rule_msg_number: "",
      form_rule_msg_mailbox: "",
      form_rule_msg_site: "",
      form_rule_msg_remark: ""
    }
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
  filters: {
    pand: function (v) {
      if (v == '置为无效') {
        return '无效';
      } else if (v == '置为有效') {
        return '有效';
      } else if (v == '批量删除') {
        return '删除';
      }
    }
  },
  components: {
    IconButton,
    EllipsisTooltip,
  },
  computed: {},
  methods: {
    // form表单检测
    validator(val){
      switch (val) {
        case "name":
          if (this.supplier.name == '') {
            this.form_rule_msg_name = '请输入供应商名称'
          } else if (this.$overall.character(this.supplier.name) > 20) {
            this.form_rule_msg_name = '输入文字长度超过10'
          } else {
            this.form_rule_msg_name = ''
          }
          break;
        case "linkman":
          if (this.$overall.character(this.supplier.linkman) > 20) {
            this.form_rule_msg_linkman = '输入文字长度超过10'
          } else {
            this.form_rule_msg_linkman = ''
          }
          break;
        case "number":
          if (this.supplier.number && this.supplier.number.length != 11) {
            this.form_rule_msg_number = '请输入正确的手机号码'
          } else {
            this.form_rule_msg_number = ''
          }
          break;
        case "mailbox":
          let reg = /^[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+(\.[a-zA-Z0-9_-]+)+$/;
          if (this.supplier.mailbox && !reg.test(this.supplier.mailbox)) {
            this.form_rule_msg_mailbox = '请输入正确的电子邮箱'
          } else {
            this.form_rule_msg_mailbox = ''
          }
          break;
        case "site":
          if (this.$overall.character(this.supplier.site) > 60) {
            this.form_rule_msg_site = '输入文字长度超过30'
          } else {
            this.form_rule_msg_site = ''
          }
          break;
        case "remark":
          if (this.$overall.character(this.supplier.remark) > 280) {
            this.form_rule_msg_remark = '输入文字长度超过140'
          } else {
            this.form_rule_msg_remark = ''
          }
          break;
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
        console.log(this.$refs.selectsse);
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
      // console.log(this.checkedCities);
    },

    // 获取供应商内容  标记
    demand(){
      this.$api.ERP.supplier.requestsupplierlist().then(res => {
        console.log(res);
        if (res.code == 1) {
          this.tableData = res.data || []
          this.quantity = []
          this.multipleSelection = []
          this.isIndeterminate = false
          this.checkAll = false
          for (const key in res.data) {
            // console.log(res.data[key].d);
            if (this.quantity.length == 0) {
              this.quantity = [res.data[key].d == 1]
            } else {
              this.quantity.push(res.data[key].d == 1)
            }
          }
        } else {
          this.$message.warning(res.msg)
        }
      })

    },
    // 点开创建为空
    xingh(){
      this.form_rule_msg_name = ''
      this.form_rule_msg_linkman = ''
      this.form_rule_msg_number = ''
      this.form_rule_msg_mailbox = ''
      this.form_rule_msg_site = ''
      this.form_rule_msg_remark = ''
      this.dialogFormVisible = true
      this.title = true
      this.supplier.name = ''
      this.supplier.linkman = ''
      this.supplier.number = ''
      this.supplier.mailbox = ''
      this.supplier.site = ''
      this.supplier.remark = ''
      this.edit()
    },
    // 创建打印机
    construction(){
      this.form_rules.map(item => this.validator(item));
      if (
        this.form_rule_msg_name ||
        this.form_rule_msg_linkman ||
        this.form_rule_msg_number ||
        this.form_rule_msg_mailbox ||
        this.form_rule_msg_site ||
        this.form_rule_msg_remark
      ) return;
      if (this.supplier.name == '') {
        this.$message.warning('必选框不能为空')
      } else {
        this.$api.ERP.supplier.requestsuppliernew({
          name: this.supplier.name,
          contact_name: this.supplier.linkman,
          phone_num: this.supplier.number,
          email: this.supplier.mailbox,
          addr: this.supplier.site,
          remark: this.supplier.remark,
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
          } else {
            this.$message.warning(res.msg)
          }
        })
      }
    },
    // 获取编辑内容
    compileprinter(){
      if (this.multipleSelection.length == 1) {
        this.form_rule_msg_name = ''
        this.form_rule_msg_linkman = ''
        this.form_rule_msg_number = ''
        this.form_rule_msg_mailbox = ''
        this.form_rule_msg_site = ''
        this.form_rule_msg_remark = ''
        this.$api.ERP.supplier.requestsupplierget({id: this.multipleSelection[0]}).then(res => {
          console.log(res);
          this.supplier.name = res.data.name
          this.supplier.linkman = res.data.contact_name
          this.supplier.number = res.data.phone_num
          this.supplier.mailbox = res.data.email
          this.supplier.site = res.data.addr
          this.supplier.remark = res.data.remark
          this.title = false
          this.dialogFormVisible = true
          this.edit()
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
      if (
        this.form_rule_msg_name ||
        this.form_rule_msg_linkman ||
        this.form_rule_msg_number ||
        this.form_rule_msg_mailbox ||
        this.form_rule_msg_site ||
        this.form_rule_msg_remark
      ) return;
      if (this.supplier.name == '') {
        this.$message.warning('必选框不能为空')
      } else {
        this.$api.ERP.supplier.requestsuppliersave({
          id: this.multipleSelection[0],
          name: this.supplier.name,
          contact_name: this.supplier.linkman,
          phone_num: this.supplier.number,
          email: this.supplier.mailbox,
          addr: this.supplier.site,
          remark: this.supplier.remark,
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
          } else {
            this.$message.warning(res.msg)
          }
        })
      }
    },


    // 无效
    noneffective(){
      if (this.multipleSelection.length > 0) {
        this.$api.ERP.supplier.requestsupplierdisable({ids: this.multipleSelection}).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.demand()
            this.multipleSelection = []
            this.isIndeterminate = false
            this.checkAll = false
            this.$message({
              showClose: true,
              message: "操作成功",
              type: 'success'
            })
          } else if (res.code == 2) {
            this.dialogFible = true
            this.srnr = '置为无效'
            this.cwsm.ns = res.data.ns || []
            this.cwsm.cs = res.data.cs || []
          } else {
            this.$message.warning(res.msg)
          }
        })
      } else {
        this.$message.warning("请至少选择一个进行操作")
      }

    },
    // 有效
    effective(){
      if (this.multipleSelection.length > 0) {
        this.$api.ERP.supplier.requestsupplierenable({ids: this.multipleSelection}).then(res => {
          // console.log(res);
          if (res.code == 1) {
            this.multipleSelection = []
            this.isIndeterminate = false
            this.checkAll = false
            this.demand()
            this.$message({
              showClose: true,
              message: "操作成功",
              type: 'success'
            })
          } else if (res.code == 2) {
            this.dialogFible = true
            this.srnr = '置为有效'
            this.cwsm.ns = res.data.ns || []
            this.cwsm.cs = res.data.cs || []
          } else {
            this.$message.warning(res.msg)
          }
        })
      } else {
        this.$message.warning("请至少选择一个进行操作")
      }
    },
    // 删除
    printerdel(){
      if (this.multipleSelection.length > 0) {
        this.$api.ERP.supplier.requestsupplierdel({ids: this.multipleSelection}).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.demand()
            this.multipleSelection = []
            this.isIndeterminate = false
            this.checkAll = false
            this.$message({
              showClose: true,
              message: "操作成功",
              type: 'success'
            })
          } else if (res.code == 2) {
            this.dialogFible = true
            this.srnr = '批量删除'
            this.cwsm.ns = res.data.ns || []
            this.cwsm.cs = res.data.cs || []
          } else {
            this.$message.warning(res.msg)
          }
        })
      } else {
        this.$message.warning("请至少选择一个进行操作")
      }

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
  }

}
</script>
<style>
    .supplier {
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding: 20px 30px;
    }

    /* 必填 */
    .supplier .mandatory {
        color: #40404e;
        width: 140px;
        text-align: right;
        line-height: 34px;
    }

    .supplier .controlling {
        width: 230px !important;
    }

    .supplier .reqfieldsd {
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
    .supplier .tiaodd {
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

    .supplier .nodata {
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        padding: 0;
    }

    .supplier .drag-list .nodata img {
        width: 60px;
        height: 60px;
    }

    .supplier .drag-list .nodata .hint {
        line-height: 36px;
        font-size: 13px !important;
    }

    /* 内容 */
    .supplier .supplier-headline {
        font-size: 30px;
        font-weight: bold;
        color: #40404e;
    }

    .supplier .supplier-controller {
        /*margin-top: 30px;*/
        height: 54px;
        width: 100%;
        background-color: #eee;
        display: flex;
        align-items: center;
    }

    .supplier .layouts {
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .supplier .compatibility {
        display: flex;
        /* align-items: center; */
        margin-bottom: 10px;
    }

    .supplier .compatibil {
        margin-bottom: 10px;
    }

    .supplier .required {
        width: 60px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 取消按钮 */
    .supplier .el-dialog .el-button--default {
        background-color: #ccc;
        border: 1px solid #ccc;
        color: #40404e;
    }

    .supplier .el-dialog {
        background-color: #f9f9f9;
    }

    /* 靠右 */
    .supplier .el-dialog {
        margin: 0px 0px 0px auto !important;
        background-color: #f9f9f9;
        height: 100%;
        position: relative;
    }

    .supplier .el-dialog__footer {
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }

    .supplier .el-dialog__body {
        padding: 0px 0px 30px 20px;
        overflow-y: scroll !important;
        /* width: 100%; */
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;
    }

    .supplier .dialogFormVisible .el-dialog {
        width: 720px;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .supplier .el-input__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
    }

    .supplier .el-dialog__title, .supplier .el-dialog__headerbtn .el-dialog__close, .supplier .el-form-item__label {
        color: #1a1a21;
    }

    .supplier .el-input {
        width: 100%;
    }

    .supplier .el-form-item {
        display: flex;
        margin: 0;
    }

    .supplier .printer .el-dialog {
        width: 30vw;
    }

    .supplier .has-gutter {
        border: 1px solid #383943;
    }

    .supplier table thead tr th, .supplier table tbody tr td {
        height: 40px;
        font-size: 14px;
    }

    /* 改变多选框背景颜色和上下间距 */
    .supplier .el-checkbox-group {
        display: flex;
        align-items: flex-end;
        justify-content: left;
    }

    .supplier .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    /* 多行文本输入框 */
    .supplier .el-textarea__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
        border-color: rgb(217, 217, 217);
        border-radius: 2px;
    }

    /* .supplier .el-textarea{ */
    /* overflow: hidden; */
    /* } */
    .supplier .el-input__count {
        position: absolute;
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

    .supplier .el-input__count .el-input__count-inner {
        background-color: #1A1A20;

    }

    /* 错误2 */
    .store .diagrgeesfelogFor .el-dialog {
        width: 720px;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .store .diagrgeesfelogFor .wwent {
        color: #40404e;
        font-size: 14px;
        margin: 20px 0px 20px 20px;
    }

    .store .diagrgeesfelogFor .wentlb {
        margin-left: 20px;
        width: 640px;
    }

    .store .diagrgeesfelogFor .zhuixiaoi {
        width: 100%;
    }

    .store .diagrgeesfelogFor .limiting {
        max-height: 680px !important;
        overflow-y: scroll !important;
    }

    .store .diagrgeesfelogFor .drag-list td:nth-of-type(1), .store .diagrgeesfelogFor .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .store .diagrgeesfelogFor .mmodity th:nth-of-type(2), .store .diagrgeesfelogFor .drag-list td:nth-of-type(2) {
        width: 500px;
    }

    /* 仓库列表 */
    .zsykd {
        width: 100%;
        overflow-x: scroll !important;
    }

    .supplier .zhuixiaoi {
        width: 1600px;
        border-collapse: collapse;
        /* border: solid 1px #383943; */
        color: #40404e;
    }

    .supplier .zhuixiaoi .mmodity tr th {
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-size: 14px;
        font-weight: 600;
        color: #40404e;
        padding-left: 20px;
    }
    .supplier .zhuixiaoi .mmodity tr th .el-checkbox__label {
        font-size: 14px;
        font-weight: 600;
        color: #40404e;
    }

    .supplier .zhuixiaoi .limiting .drag-list td {
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-size: 14px;
        font-weight: 400;
        padding-left: 20px;
    }

    .supplier .zhuixiaoi .limiting .drag-list {
        display: flex;
    }

    .supplier .zhuixiaoi .mmodity {
        width: 100%;
        display: block;
    }

    .supplier .zhuixiaoi .mmodity tr {
        background-color: #f5f5f5;
        display: flex;
    }

    .supplier .zhuixiaoi .limiting {
        /*border-top: solid 1px #383943;*/
        overflow-y: auto !important;
        max-height: 540px;
        display: block;
    }

    .supplier .drag-list td:nth-of-type(1), .supplier .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .supplier .mmodity th:nth-of-type(2), .supplier .drag-list td:nth-of-type(2) {
        width: 300px;
    }

    .supplier .drag-list td:nth-of-type(3), .supplier .mmodity th:nth-of-type(3) {
        width: 200px;
    }

    .supplier .drag-list td:nth-of-type(4), .supplier .mmodity th:nth-of-type(4) {
        width: 200px;
    }

    .supplier .drag-list td:nth-of-type(5), .supplier .mmodity th:nth-of-type(5) {
        width: 200px;
    }

    .supplier .drag-list td:nth-of-type(6), .supplier .mmodity th:nth-of-type(6) {
        width: 200px;
    }

    .supplier .drag-list td:nth-of-type(7), .supplier .mmodity th:nth-of-type(7) {
        width: 100px;
    }

    .supplier .drag-list:nth-of-type(odd) {
        background-color: #f9f9f9;
        color: #40404e;
    }

    .supplier .drag-list:nth-of-type(even) {
        background-color: #f5f5f5;
        color: #40404e;
    }

    /* 全选颜色 */
    .supplier .zhuixiaoi .el-checkbox__label {
        color: #40404e;
    }

    .supplier .zhuixiaoi .mmodity .el-checkbox__label {
        font-size: 12px;
    }

    .drag-list-check {
        /* background: rgba(39, 52, 82, .5) !important; */
    }


</style>

