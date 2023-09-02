<template>
    <div class="printer">
        <div class="printer-controller">
            <icon-button @click.native="xingh" text="新增打印机" img="btn_add.png" colors="transparent"></icon-button>
            <icon-button @click.native="compileprinter" text="编辑" img="btn_edit.png" colors="transparent"></icon-button>
            <icon-button @click.native="noneffective" text="置为无效" img="btn_in_vain.png" colors="transparent"></icon-button>
            <icon-button @click.native="effective" text="置为有效" img="btn_effective.png" colors="transparent"></icon-button>
            <icon-button @click.native="printerdel" text="批量删除" img="btn_delete.png" colors="transparent"
                         bjcolors="transparent"></icon-button>
            <characters-button @click.native="detection" colors="transparent" wz='检测'></characters-button>
            <characters-button @click.native="printTestHandle" colors="transparent" wz='打印测试'></characters-button>
        </div>
        <div class="zsykd" style="display: inline-block;">
            <table class="zhuixiaoi" style="min-width: 1191px;">
                <thead class="mmodity">
                <tr>
                    <th>
                        <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll" @change="handleCheckAllChange">
                            全选
                        </el-checkbox>
                    </th>
                    <th>打印机名称</th>
                    <th>IP地址</th>
                    <th>创建时间</th>
                    <th>更新时间</th>
                    <th>状态</th>
                </tr>
                </thead>
                <tbody class="limiting" :style="{'border-bottom':tableData.length<1?'0px':'',
                'width':tableData.length>MaxNumber?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`}">
                <tr v-for="(item,i) in tableData" :key="item.id" class="drag-list"
                    :class="multipleSelection.includes(item.id)? 'drag-list-check':''">
                    <td :style="{'color':item.s=='无效'?'#595959':''}">
                        <el-checkbox-group v-model="multipleSelection" @change="handleCheckedCitiesChange">
                            <el-checkbox :label="item.id">{{i+1}}</el-checkbox>
                        </el-checkbox-group>
                    </td>
                    <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.n}}</td>
                    <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.i || '---'}}</td>
                    <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.c || '---'}}</td>
                    <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.u}}</td>
                    <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.s}}</td>
                </tr>
                </tbody>
            </table>
            <div class="tiaodd" v-if="tableData.length<1">
                <td class="nodata" :style="{'height':`${MaxHeight}px !important`}">
                    <img src="@/assets/img/wu.png" alt="">
                    <div class="hint">暂无数据</div>
                </td>
            </div>
        </div>


        <!-- 新建打印机  编辑 -->
        <div v-show="dialogFormVisible" class="dialogFormVisible">
            <el-dialog :title="compileprinterss?'新建打印机':'编辑打印机'" @close="dialogFormVisible = false"
                       :visible.sync="dialogFormVisible" :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>打印机名称：
                        </div>
                        <el-input v-model="printer.printername" ref="selectsse" placeholder="请输入打印机名称"
                                  class="controlling" :class="form_rule_msg_name?'error':''" @blur="validator('name')"/>
                        <div class="cwts">{{form_rule_msg_name}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>IP地址：
                        </div>
                        <el-input v-model="printer.printerIP" placeholder="请输入打印机ID地址" class="controlling"/>
                    </div>
                </el-form>
                <div class="layouts">IP地址格式为：a.b.c.d;其中a,b,c,d均为0-254的数字</div>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFormVisible = false">取消</el-button>
                    <el-button v-show="compileprinterss" type="primary" @click="construction">确认</el-button>
                    <el-button v-show="!compileprinterss" type="primary" @click="saveprinter">保存</el-button>
                </span>
            </el-dialog>
        </div>

        <!-- 无效有效删除 -->
        <div v-show="dialogFible" class="diagrgeesfelogFor">
            <el-dialog :title="srnr" :visible.sync="dialogFible" @close="dialogFible = false"
                       :close-on-click-modal="false">
                <div class="wwent" v-show="cwsm.cs.length>0">
                    <span>以下对象存在依赖，需同步设置为{{srnr | pand}}</span>
                    <characters-button @click.native="synchronizon" :disaed="kzsfjy" colors="transparent"
                                       :wz="`同步${srnr}`"></characters-button>
                </div>
                <div class="wentlb" v-show="cwsm.cs.length>0">
                    <table class="zhuixiaoi">
                        <thead class="mmodity">
                        <tr>
                            <th>序号</th>
                            <th>说明</th>
                            <th>处理结果</th>
                        </tr>
                        </thead>
                        <tbody class="limiting" :style="{'width':cwsm.cs.length>6?'calc(100% + 6px)':'100%'}">
                        <tr v-for="(item,i) in cwsm.cs" :key="i" class="drag-list">
                            <td>{{i+1}}</td>
                            <td>
                                <ellipsis-tooltip :text="item.r || '-----'"></ellipsis-tooltip>
                            </td>
                            <td v-show="item.jg == '成功'" style="color: #00BC72;">{{item.jg}}</td>
                            <td v-show="item.jg == '---'">{{item.jg}}</td>
                            <td v-show="item.jg == '失败'" style="color: #E13B50;">{{item.jg}}</td>
                        </tr>
                        </tbody>
                    </table>
                </div>
                <div class="wwent" v-show="cwsm.ns.length>0">以下对象存在依赖，需人工处理依赖</div>
                <div class="wentlb danykz" v-show="cwsm.ns.length>0">
                    <table class="zhuixiaoi">
                        <thead class="mmodity">
                        <tr>
                            <th>序号</th>
                            <th>说明</th>
                        </tr>
                        </thead>
                        <tbody class="limiting" :style="{'width':cwsm.ns.length>6?'calc(100% + 6px)':'100%'}">
                        <tr v-for="(item,i) in cwsm.ns" :key="i" class="drag-list">
                            <td>{{i+1}}</td>
                            <td>
                                <ellipsis-tooltip :text="item || '-----'"></ellipsis-tooltip>
                            </td>
                        </tr>
                        </tbody>
                    </table>
                </div>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFible = false">取消</el-button>
                    <!-- <el-button type="primary" :disabled="snlufg" @click="chdefrs">重试</el-button> -->
                </span>
            </el-dialog>
        </div>
    </div>
</template>
<script>
import EllipsisTooltip from '@/components/EllipsisTooltip.vue'//根据路径导入组件
import IconButton from '@/components/IconButton.vue'//根据路径导入组件
import CharactersButton from '@/components/CharactersButton.vue'//根据路径导入组件
export default {
  data(){
    return {
      tableData: [],//打印机目录
      dialogFormVisible: false,//控制新建打印机是否显示
      printer: {
        printername: '',//打印机名称
        printerIP: '',//打印机IP
        printerID: "",//打印机ID
      },//打印机
      compileprinterss: false,//控制是新建还是编辑

      multipleSelection: [],// 选中的内容
      isIndeterminate: false,// 供应商选择一部分
      checkAll: false,//供应商全选


      dialogFible: false,//控制错误2是否显示
      srnr: '',//文案
      cwsm: {
        ns: [],//不可操作列表
        cs: [],//可一键操作列表
      },//错误2说明
      kzsfjy: false,//控制同步按钮是否禁用
      snlufg: false,//控制重试按钮是否禁用
      windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
      MaxHeight: 0,//滚动高度
      MaxNumber: 0,//最大个数

      form_rules: ["name"],
      form_rule_msg_name: ""
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
    EllipsisTooltip,
    IconButton,
    CharactersButton
  },
  computed: {},
  methods: {
    // form表单检测
    validator(val){
      switch (val) {
        case "name":
          if (this.printer.printername == '') {
            this.form_rule_msg_name = '请输入打印机名称'
          } else if (this.$overall.character(this.printer.printername) > 20) {
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
    // 获取打印机内容  标记
    demand(){
      this.$api.BMS.printer.requestprinterlist().then(res => {
        console.log(res);
        if (res.code == 1) {
          this.tableData = res.data || []
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    //获取焦点
    edit(){
      this.$nextTick(() => {  //次要代码
        this.$refs.selectsse.focus();
        console.log(this.$refs);
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
    // 创建打印机
    construction(){
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_name) return;
      if (this.printer.printername == '' || this.printer.printerIP == '') {
        this.$message.warning('必选框不能为空')
      } else {
        this.$api.BMS.printer.requestprinternew({
          name: this.printer.printername,
          ip_addr: this.printer.printerIP,
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "操作成功",
              type: 'success'
            })
            this.ktsewf()
            this.demand()
            this.dialogFormVisible = false
            this.printer.printername = ''
            this.printer.printerIP = ''
          } else {
            this.$message.warning(res.msg)
          }
        })
      }
    },
    // 编辑内容
    compileprinter(){
      if (this.multipleSelection.length == 1) {
        this.form_rule_msg_name = ''
        this.$api.BMS.printer.requestprinterget({id: this.multipleSelection[0]}).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.compileprinterss = false
            this.printer.printername = res.data.name
            this.printer.printerIP = res.data.ip_addr
            this.printer.printerID = parseInt(res.data.id)
            this.dialogFormVisible = true
            this.edit()
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
      this.$api.BMS.printer.requestprintersave({
        id: this.printer.printerID,
        ip_addr: this.printer.printerIP,
        name: this.printer.printername
      }).then(res => {
        console.log(res);
        if (res.code == 1) {
          this.$message({
            showClose: true,
            message: "操作成功",
            type: 'success'
          })
          this.demand()
          this.printer.printername = ''
          this.printer.printerIP = ''
          this.printer.printerID = ''
          this.dialogFormVisible = false
          this.ktsewf()
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 为空
    weik(){
      this.multipleSelection = []
      this.isIndeterminate = false
      this.checkAll = false
    },

    // 重试
    chdefrs(){
      if (this.srnr == '置为无效') {
        this.noneffective()
      } else if (this.srnr == '置为有效') {
        this.effective()
      } else if (this.srnr == '批量删除') {
        this.printerdel()
      }
    },
    // 同步
    synchronizon(){
      this.kzsfjy = true
      var s = ''
      if (this.srnr == '置为无效') {
        s = 2
      } else if (this.srnr == '置为有效') {
        s = 1
      } else if (this.srnr == '批量删除') {
        s = 3
      }
      var tid = []
      var id = []
      for (const iterator of this.cwsm.cs) {
        tid.push(iterator.tid)
        id.push(iterator.id)
      }
      console.log(tid, id, s);
      this.$api.BMS.printer.requestprinterob({
        op_status: Number(s),
        type_ids: tid,
        ids: id
      }).then(res => {
        console.log(res);
        if (res.code == 1) {
          for (const key in this.cwsm.cs) {
            this.cwsm.cs[key].jg = '成功'
          }
          this.demand()
          this.letbutton()
          this.$message({
            showClose: true,
            message: "操作成功",
            type: 'success'
          })
          this.dialogFible = false
          this.chdefrs()
        } else if (res.code == 2) {
          for (const key in this.cwsm.cs) {
            for (const keys in res.data) {
              if (this.cwsm.cs[key].id == res.data[keys].id) {
                this.cwsm.cs[key].jg = '失败'
              }
            }
          }
          for (const key in this.cwsm.cs) {
            if (this.cwsm.cs[key].jg == '---') {
              this.cwsm.cs[key].jg = '成功'
            }
          }
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 判断是否放开重试按钮
    letbutton(){
      var s = true
      if (this.cwsm.ns.length < 1) {
        s = false
      }
      for (const iterator of this.cwsm.cs) {
        if (iterator.jg == '成功') {
          s = false
        } else {
          s = true
          break;
        }
      }
      this.snlufg = s
    },
    // 无效
    noneffective(){
      this.snlufg = false
      if (this.multipleSelection.length > 0) {
        this.$api.BMS.printer.requestprinterdisable({ids: this.multipleSelection}).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.demand()
            this.weik()
            this.dialogFible = false
            this.$message({
              showClose: true,
              message: "操作成功",
              type: 'success'
            })
          } else if (res.code == 2) {
            this.dialogFible = true
            this.kzsfjy = false
            this.srnr = '置为无效'
            this.cwsm.ns = res.data.ns || []
            for (const key in res.data.cs) {
              res.data.cs[key].jg = '---'
            }
            this.cwsm.cs = res.data.cs || []
            if (this.cwsm.ns.length > 0 || this.cwsm.cs.length > 0) {
              this.snlufg = true
            }
          } else {
            this.$message.warning(res.msg)
          }
        })
      } else {
        this.$message.warning("请选择一个进行更改")
      }
    },
    // 有效
    effective(){
      this.snlufg = false
      if (this.multipleSelection.length > 0) {
        this.$api.BMS.printer.requestprinterenable({ids: this.multipleSelection}).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.demand()
            this.weik()
            this.dialogFible = false
            this.$message({
              showClose: true,
              message: "操作成功",
              type: 'success'
            })
          } else if (res.code == 2) {
            this.dialogFible = true
            this.kzsfjy = false
            this.srnr = '置为有效'
            this.cwsm.ns = res.data.ns || []
            for (const key in res.data.cs) {
              res.data.cs[key].jg = '---'
            }
            this.cwsm.cs = res.data.cs || []
            if (this.cwsm.ns.length > 0 || this.cwsm.cs.length > 0) {
              this.snlufg = true
            }
          } else {
            this.$message.warning(res.msg)
          }
        })
      } else {
        this.$message.warning("请选择一个进行删除")
      }
    },
    // 删除
    printerdel(){
      this.snlufg = false
      if (this.multipleSelection.length > 0) {
        this.$api.BMS.printer.requestprinterdel({ids: this.multipleSelection}).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.demand()
            this.weik()
            this.dialogFible = false
            this.$message({
              showClose: true,
              message: "操作成功",
              type: 'success'
            })
          } else if (res.code == 2) {
            this.dialogFible = true
            this.kzsfjy = false
            this.srnr = '批量删除'
            this.cwsm.ns = res.data.ns || []
            for (const key in res.data.cs) {
              res.data.cs[key].jg = '---'
            }
            this.cwsm.cs = res.data.cs || []
            if (this.cwsm.ns.length > 0 || this.cwsm.cs.length > 0) {
              this.snlufg = true
            }
          } else {
            this.$message.warning(res.msg)
          }
        })
      } else {
        this.$message.warning("请选择一个进行删除")
      }

    },


    // 检测
    detection(){
      if (this.multipleSelection.length == 1) {
        this.$api.BMS.printer.requestprinterchk({id: this.multipleSelection[0]}).then(res => {
          console.log(res);
          if (res.code == 26) {
            this.$message({
              showClose: true,
              message: "打印机连接出现故障！请修复故障后再重新检测！",
              type: 'error',
            })
          } else if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "打印机连接正常",
              type: 'success'
            })
          } else {
            this.$message.warning(res.msg)
          }
        })
      } else {
        this.$message({
          message: '请选择一个进行检测',
          type: 'warning',
        })
      }
    },

    // 测试打印
    async printTestHandle(){
      if (this.multipleSelection.length != 1) return this.$message.warning('请选择一个进行打印测试')
      const params = {
        id: this.multipleSelection[0]  // int64    请求id
      }
      try {
        const res = await this.$api.BMS.printer.requestprinterprt(params)
        res.code == 1 ? this.$message.success('打印测试成功') : this.$message.warning(res.msg);
      } catch (error) {
        console.log('打印测试失败', error);
      }
    },

    // 点开创建name为空
    xingh(){
      this.form_rule_msg_name = ''
      this.dialogFormVisible = true
      this.printer.printername = ''
      this.printer.printerIP = ''
      this.compileprinterss = true
      this.edit()
    },
    ktsewf(){
      this.multipleSelection = []
      this.isIndeterminate = false
      this.checkAll = false
    }


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
    /* 靠右 */
    .printer .el-dialog {
        margin: 0px 0px 0px auto !important;
        background-color: #f9f9f9;
        height: 100%;
        position: relative;
    }

    .printer .el-dialog__footer {
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }

    .printer .el-dialog__body {
        padding: 0px 0px 30px 20px;
        overflow-y: scroll !important;
        /* width: 100%; */
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;
    }

    .printer .el-dialog {
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .printer {
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding: 20px 30px;
    }

    /* 必填 */
    .printer .mandatory {
        color: #1A1A21;
        width: 140px;
        text-align: right;
    }

    .printer .controlling {
        color: #1A1A21;
        width: 230px !important;
    }

    .printer .reqfieldsd {
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
    .printer .tiaodd {
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

    .printer .nodata {
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        padding: 0;
    }

    .printer .nodata img {
        width: 60px;
        height: 60px;
    }

    .printer .nodata .hint {
        line-height: 36px;
        font-size: 13px !important;
    }

    .printer .printer-headline {
        font-size: 30px;
        font-weight: bold;
        color: #1A1A21;
    }

    .printer .printer-controller {
        /*margin-top: 30px;*/
        height: 54px;
        /* width: 1600px; */
        background-color: #EEEEEE;
        /* background-color: #202026; */
        display: flex;
        align-items: center;
        /* border-top: 1px solid #2c2d36; */
    }

    .printer .layouts {
        font-size: 12px;
        margin-left: 83px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .printer .compatibility {
        display: flex;
        align-items: center;
        margin-bottom: 10px;
    }

    /* 取消按钮 */
    .printer .el-dialog .el-button--default {
        background-color: #ccc;
        border: 1px solid #ccc;
        color: #1A1A21;
    }
    .printer .el-dialog .el-button--primary {
        background-color: #2170ff;
        border: 1px solid #2170ff;
        color: #FFF;
    }

    .printer .el-dialog {
        background-color: #f9f9f9;
    }

    .printer .el-input__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #1A1A21;
    }

    .printer .el-dialog__header, .printer .el-dialog__footer {
        background-color: #f5f5f5;
    }

    .printer .el-dialog__title, .printer .el-dialog__headerbtn .el-dialog__close, .printer .el-form-item__label {
        color: #1A1A21;
    }

    .printer .el-input {
        width: 100%;
    }

    .printer .el-form-item {
        display: flex;
        margin: 0;
    }

    .printer .dialogFormVisible .el-dialog {
        width: 720px;
    }

    /* 改变多选框背景颜色和上下间距 */
    .printer .el-checkbox-group {
        display: flex;
        align-items: flex-end;
        justify-content: left;
    }

    .printer .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    /* 错误2 */
    .printer .diagrgeesfelogFor .el-dialog {
        width: 720px;
        border-left: 1px solid #383943;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.5)
    }

    .printer .diagrgeesfelogFor .wwent {
        color: #ce4153;
        font-size: 14px;
        margin: 20px 0px 20px 20px;
        display: flex;
        align-items: center;
    }

    .printer .diagrgeesfelogFor .wentlb {
        margin-left: 20px;
        width: 640px;
    }

    .printer .diagrgeesfelogFor .zhuixiaoi {
        width: 100%;
    }

    .printer .diagrgeesfelogFor .zhuixiaoi .limiting {
        max-height: 280px !important;
        overflow-y: scroll !important;
    }

    .printer .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(1), .printer .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(1) {
        width: 50px;
    }

    .printer .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(2), .printer .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(2) {
        width: 320px;
    }

    .printer .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(3), .printer .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(3) {
        width: 200px;
    }

    .printer .diagrgeesfelogFor .danykz .mmodity th:nth-of-type(2), .printer .diagrgeesfelogFor .danykz .drag-list td:nth-of-type(2) {
        width: 520px;
    }

    /* 无效颜色 */
    .printer .diagrgeesfelogFor .el-button--primary.is-disabled, .printer .diagrgeesfelogFor .el-button--primary.is-disabled:hover {
        background-color: #ddd;
        color: #1A1A21;
        border-color: #ddd;
    }

    /* 列表 */
    .zsykd {
        width: 100%;
        overflow-x: scroll !important;
    }

    .printer .zhuixiaoi {
        width: 1600px;
        border-collapse: collapse;
        color: #1A1A21;
    }

    .printer .zhuixiaoi .mmodity tr th {
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-size: 14px;
        font-weight: 400;
        padding-left: 20px;
    }

    .printer .zhuixiaoi .limiting .drag-list td {
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-size: 14px;
        font-weight: 400;
        padding-left: 20px;
    }

    .printer .zhuixiaoi .limiting .drag-list {
        display: block;
        display: flex;
    }

    .printer .zhuixiaoi .mmodity {
        width: 100%;
        display: block;
    }

    .printer .zhuixiaoi .mmodity tr {
        /* border-top: solid 1px #383943; */
        background-color: #f5f5f5;
        /* background-color: #2d2e38; */
        display: flex;
    }
    .printer .zhuixiaoi .mmodity tr th{
      font-weight: 600;
    }
    .printer .zhuixiaoi .mmodity tr th .el-checkbox__label{
      font-weight: 600;
      font-size: 14px;
    }

    .printer .zhuixiaoi .limiting {
        /*border-top: solid 1px #383943;*/
        overflow-y: auto !important;
        max-height: 540px;
        /* border-bottom: solid 1px #383943; */
        display: block;
    }

    .printer .drag-list td:nth-of-type(1), .printer .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .printer .mmodity th:nth-of-type(2), .printer .drag-list td:nth-of-type(2) {
        width: 240px;
    }

    .printer .drag-list td:nth-of-type(3), .printer .mmodity th:nth-of-type(3) {
        width: 140px;
    }

    .printer .drag-list td:nth-of-type(4), .printer .mmodity th:nth-of-type(4) {
        width: 140px;
    }

    .printer .drag-list td:nth-of-type(5), .printer .mmodity th:nth-of-type(5) {
        width: 140px;
    }

    .printer .drag-list td:nth-of-type(6), .printer .mmodity th:nth-of-type(6) {
        width: 60px;
    }

    .printer .drag-list:nth-of-type(odd) {
        background-color: #F9F9F9;
        color: #40404E;
        /* color: #1A1A21; */
    }

    .printer .drag-list:nth-of-type(even) {
        background-color: #F5F5F5;
        color: #40404E;
    }

    /* 全选颜色 */
    .printer .zhuixiaoi .el-checkbox__label {
        color: #1A1A21;
    }

    .printer .zhuixiaoi .mmodity .el-checkbox__label {
        font-size: 12px;
    }

    .drag-list-check {
        /* background: rgba(39, 52, 82, .5) !important; */
    }
</style>

<style scoped>
/deep/.el-checkbox .el-checkbox__inner{
  border: 1px solid #8C8C8C;
}
/deep/.el-checkbox .el-checkbox__label{
  color: #40404E!important;
}
</style>