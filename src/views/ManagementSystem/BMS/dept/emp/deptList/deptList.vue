<template>
    <div class="dept-list">
        <div class="title">下级部门</div>
        <div class="dept-list-controller">
            <icon-button @click.native="xingh" text="新增子部门" img="添加.png" colors="#383943"></icon-button>
            <icon-button @click.native="compileprinter" text="编辑" img="编辑.png" colors="#383943"></icon-button>
            <icon-button @click.native="noneffective" text="置为无效" img="无效.png" colors="#383943"></icon-button>
            <icon-button @click.native="effective" text="置为有效" img="有效.png" colors="#383943"></icon-button>
            <icon-button @click.native="printerdel" text="批量删除" img="删除.png" colors="#6B2830"
                         bjcolors="#491E24"></icon-button>
        </div>
        <div style="height:calc(100% - 100px);position: relative">
            <div style="display: inline-block;height:100%" class="meisfgr">
                <table class="zhuixiaoi" style="min-width: 850px;">
                    <thead class="mmodity" style="position:sticky;top:0;z-index:100">
                    <tr>
                        <th>
                            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll"
                                         @change="handleCheckAllChange">
                                全选&ensp;
                            </el-checkbox>
                        </th>
                        <th>部门名称</th>
                        <th>人员数量</th>
                        <th>状态</th>
                        <th>创建时间</th>
                        <th>更新时间</th>
                    </tr>
                    </thead>
                    <tbody class="limiting" ref="systemForm" @scroll="sysHandleScroll()" @mouseover="changeFlag(false)"
                           :style="{'width':tableDatas.length>12?'calc(100% + 6px)':'100%',
                    'border-bottom':tableDatas.length<MaxNumber?'0px':'',
                    'max-height':`${MaxHeight}px`}">
                    <tr v-for="(item,i) in tableDatas" :key="item.id" class="drag-list"
                        :class="multipleSelection.includes(item.id)? 'drag-list-check':''">
                        <td :style="{'color':item.s=='无效'?'#595959':''}">
                            <el-checkbox-group v-model="multipleSelection" @change="handleCheckedCitiesChange">
                                <el-checkbox :label="item.id">{{i+1}}&emsp;&ensp;</el-checkbox>
                            </el-checkbox-group>
                        </td>
                        <td :style="{'color':item.s=='无效'?'#595959':'',}">
                            <ellipsis-tooltip :text="item.n || '-----'"></ellipsis-tooltip>
                        </td>
                        <td :style="{'color':item.s=='无效'?'#595959':'',}">
                            <ellipsis-tooltip :text="item.ec + '' || '-----'"></ellipsis-tooltip>
                        </td>
                        <td :style="{'color':item.s=='无效'?'#595959':'',}">
                            <ellipsis-tooltip :text="item.s || '-----'"></ellipsis-tooltip>
                        </td>
                        <td :style="{'color':item.s=='无效'?'#595959':'',}">
                            <ellipsis-tooltip :text="item.c || '-----'"></ellipsis-tooltip>
                        </td>
                        <td :style="{'color':item.s=='无效'?'#595959':'',}">
                            <ellipsis-tooltip :text="item.u || '-----'"></ellipsis-tooltip>
                        </td>
                    </tr>
                    <div class="tiaodd" v-if="tableDatas.length<1">
                        <td class="nodata" style="height:100px !important">
                            <img src="../../../../../../assets/img/wu.png" alt="">
                            <div class="hint">暂无数据</div>
                        </td>
                    </div>
                  </tbody>
                </table>
            </div>
        </div>

        <!-- 新增  编辑-->
        <div v-show="dialogFormVisible" class="dialogFormVisible">
            <el-dialog :title="title?'新增部门':'编辑部门'" @close="dialogFormVisible = false"
                       :visible.sync="dialogFormVisible" :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="compatibility" v-show="id!=0">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>上级部门：
                        </div>
                        <div style="color:#40404e;;" class="controlling">{{parent_name}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>子部门：
                        </div>
                        <el-input v-model="materialStair" @blur="limitingRule(0)" placeholder="请输入子部门名称"
                                  ref="selectsse" class="controlling"/>
                        <div class="cwts">{{mistake}}</div>
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
                <div class="wwent" v-show="cwsm.cs.length>0">
                    <span>以下对象存在依赖，需同步设置为{{srnr | pand}}</span>
                    <characters-button @click.native="synchronizon" :disaed="kzsfjy" colors="#383943"
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
                    <el-button @click="dialogFible = false">关闭</el-button>
                </span>
            </el-dialog>
        </div>
    </div>
</template>
<script>
import IconButton from '@/components/IconButton.vue'//根据路径导入组件
import EllipsisTooltip from '@/components/EllipsisTooltip.vue'//根据路径导入组件
import CharactersButton from '@/components/CharactersButton.vue'//根据路径导入组件
import { sessionStorage, localStorage } from '@/utils/common/storage'
export default {
  name: 'DeptList',
  props: {
    id: {
      type: String,
      require: true
    }
  },
  data(){
    return {
      propsId: "",
      parent_name: "",

      tableDatas: [],//子部门目录
      multipleSelection: [],// 选中的内容
      isIndeterminate: false,// 子部门选择一部分
      checkAll: false,//子部门全选

      dialogFormVisible: false,//控制新建上级部门是否显示
      materialStair: "",//子部门名字
      title: true,//为新建还是编辑


      dialogFible: false,//控制错误2是否显示
      srnr: '',//文案
      cwsm: {
        ns: [],//不可操作列表
        cs: [],//可一键操作列表
      },//错误2说明
      kzsfjy: false,//控制同步按钮是否禁用

      mistake: '',//弹窗内错误提示
      windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight / 2,   //实时屏幕高度
      MaxHeight: 0,//滚动高度
      MaxNumber: 0,//最大个数

      flag: false
    }
  },
  mounted(){

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
    CharactersButton
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
    // 输入规则
    limitingRule(i){
      switch (Number(i)) {
        case 0:
          console.log(this.$overall.character(this.materialStair));
          this.$refs.selectsse.$refs.input.style.borderColor = '#CE4253'
          if (this.materialStair == '') {
            this.mistake = '请输入子部门名称'
          } else {
            if (this.$overall.character(this.materialStair) > 10) {
              this.mistake = '输入文字长度超过5'
            } else {
              this.$refs.selectsse.$refs.input.style.borderColor = '#555763'
              this.mistake = ''
            }
          }
          break
      }
    },
    // 重置规则样式
    czyangs(){
      this.$nextTick(() => {  //次要代码
        this.$refs.selectsse.$refs.input.style.borderColor = '#555763'
      })
    },
    //获取焦点
    edit(){
      this.$nextTick(() => {  //次要代码
        this.$refs.selectsse.focus();
      })
    },
    // 选择全选或取消
    handleCheckAllChange(val) {
      // console.log(this.tableDatas);
      // console.log(val);
      if (val) {
        // console.log(this.tableDatas);
        this.multipleSelection = []
        for (const key in this.tableDatas) {
          this.multipleSelection.push(this.tableDatas[key].id)
        }
      } else {
        this.multipleSelection = []
      }
      this.isIndeterminate = false;
    },
    // 控制单个选中
    handleCheckedCitiesChange(value) {
      let checkedCount = value.length;
      this.checkAll = checkedCount === this.tableDatas.length;
      this.isIndeterminate = checkedCount > 0 && checkedCount < this.tableDatas.length;
      // console.log(this.checkedCities);
    },
    // 获取子部门内容  标记
    demand(){
      this.$api.BMS.dept.requestdeptlist({id: Number(this.propsId)}).then(res => {
        // this.$parent.tiaoz(this.propsId,res.data)
        this.tableDatas = res.data || [];
        this.weik();

        this.$parent.demand()
      })

    },
    // 为空
    weik(){
      this.multipleSelection = []
      this.isIndeterminate = false
      this.checkAll = false
    },
    // 点开创建为空
    xingh(){
      this.parent_name = localStorage.getItem("parent_name");
      this.dialogFormVisible = true
      this.title = true
      this.materialStair = ''
      this.edit()
      this.czyangs()
      this.mistake = ''
    },
    // 创建子部门
    construction(){
      for (var i = 0; i < 1; i++) {
        this.limitingRule(i)
      }
      if (this.mistake != '') {
        this.$message.warning('请按提示正确填写')
      } else {
        this.$api.BMS.dept.requestdeptNew({
          pid: Number(this.propsId),
          name: this.materialStair,
        }).then(res => {
          if (res.code == 1 || res.code == 6) {
            if (res.msg === '') {
              this.$message({
                showClose: true,
                message: "操作成功",
                type: 'success'
              })
            } else {
              this.$message({
                showClose: true,
                message: res.msg, //"操作成功，状态无效；所属上级部门为无效状态",
                type: 'warning'
              })
            }
            this.weik()
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
        this.mistake = ''
        this.$api.BMS.dept.requestdeptGet({id: this.multipleSelection[0]}).then(res => {
          this.materialStair = res.data.name
          this.title = false
          this.parent_name = res.data.parent_name;
          this.dialogFormVisible = true
          this.edit()
          this.czyangs()
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
      for (var i = 0; i < 1; i++) {
        this.limitingRule(i)
      }
      if (this.mistake != '') {
        this.$message.warning('请按提示正确填写')
      } else {
        this.$api.BMS.dept.requestdeptSave({
          id: this.multipleSelection[0],
          name: this.materialStair,
        }).then(res => {
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "操作成功",
              type: 'success'
            })
            this.weik()
            this.demand()
            this.dialogFormVisible = false
          } else {
            this.$message.warning(res.msg)
          }
        })
      }
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
      this.$api.BMS.dept.requestdeptOb({
        op_status: Number(s),
        type_ids: tid,
        ids: id
      }).then(res => {
        if (res.code == 1) {
          for (const key in this.cwsm.cs) {
            this.cwsm.cs[key].jg = '成功'
          }
          this.demand()
          if (this.cwsm.ns.length < 1) {
            this.chdefrs()
          }
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
    // 无效
    noneffective(){
      if (this.multipleSelection.length > 0) {
        this.$api.BMS.dept.requestdeptDisable({ids: this.multipleSelection}).then(res => {
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
      if (this.multipleSelection.length > 0) {
        this.$api.BMS.dept.requestdeptEnable({ids: this.multipleSelection}).then(res => {
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
      if (this.multipleSelection.length > 0) {
        this.$api.BMS.dept.requestdeptDel({ids: this.multipleSelection}).then(res => {
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
          } else {
            this.$message.warning(res.msg)
          }
        })
      } else {
        this.$message.warning("请选择一个进行删除")
      }

    },
    // 滚动最大高度
    RollMaxHeight(i){
      var s = i - 48 - 60 - 55 - 40
      this.MaxHeight = s
      this.MaxNumber = Math.floor(s / 37)
      // console.log(i);
    }
  },
  watch: {
    id(newVal, oldVal){
      this.propsId = newVal;
      this.demand();
    },
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
    .dept-list {
        padding: 10px 0;
        height: 100%;
    }

    .dept-list .title {
        font-size: 16px;
        font-family: PingFangSC-Medium, PingFang SC;
        font-weight: 500;
        color: #40404e;
        line-height: 16px;
    }

    /* 必填 */
    .dept-list .mandatory {
        color: #40404e;
        width: 140px;
        text-align: right;
        line-height: 34px;

    }

    .dept-list .controlling {
        width: 230px !important;
        line-height: 34px;
    }

    .cwts {
        color: #CE4253;
        line-height: 34px;
        padding-left: 10px;
    }

    .dept-list .reqfieldsd {
        font-size: 16px;
        padding-right: 4px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 表格无数据时展示 */
    .dept-list .nodata {
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
    }

    .dept-list .nodata img {
        width: 60px;
        height: 60px;
    }

    .dept-list .nodata .hint {
        line-height: 36px;
        font-size: 13px !important;
    }

    /* 内容 */
    .dept-list .dept-list-headline {
        font-size: 30px;
        font-weight: bold;
        color: #40404e;
    }

    .dept-list .dept-list-controller {
        margin-top: 16px;
        height: 54px;
        width: 100%;
        /* width: 1400px; */
        background-color: #eee;
        display: flex;
        align-items: center;
    }

    .dept-list .layouts {
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .dept-list .compatibility {
        display: flex;
        /* align-items: center; */
        margin-bottom: 10px;
    }

    .dept-list .required {
        width: 60px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .dept-list .el-dialog {
        background-color: #f9f9f9;
    }

    .dept-list .el-input__inner {
        background-color: transparent;
        color: #40404e;
    }

    .dept-list .el-dialog__footer {
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }

    .dept-list .el-dialog__title, .dept-list .el-dialog__headerbtn .el-dialog__close, .dept-list .el-form-item__label {
        color: #1a1a21;
    }

    .dept-list .el-input {
        width: 100%;
    }

    .dept-list .el-form-item {
        display: flex;
        margin: 0;
    }

    .dept-list .el-table th.el-table__cell.is-leaf {
        background-color: #2A2B34;
        color: #40404e;
        border-bottom: 1px solid #383943;
        border-right: 1px solid #383943;
    }

    .dept-list .el-checkbox-group {
        display: flex;
        align-items: flex-end;
        justify-content: left;
    }

    .dept-list .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    /* 靠右 */
    .dept-list .el-dialog {
        margin: 0px 0px 0px auto !important;
        height: 100%;
        position: relative;
    }

    .dept-list .el-dialog__body {
        padding: 0px 0px 30px 20px;
        overflow-y: scroll !important;
        width: 100%;
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;

    }

    .dept-list .dialogFormVisible .el-dialog {
        width: 720px;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    /* 错误2 */
    .dept-list .diagrgeesfelogFor .el-dialog {
        width: 720px;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .dept-list .diagrgeesfelogFor .wwent {
        color: #ce4153;
        font-size: 14px;
        margin: 20px 0px 20px 20px;
        display: flex;
        align-items: center;
    }

    .dept-list .diagrgeesfelogFor .wentlb {
        margin-left: 20px;
        width: 640px;
    }

    .dept-list .diagrgeesfelogFor .zhuixiaoi {
        width: 100%;
    }

    .dept-list .diagrgeesfelogFor .zhuixiaoi .limiting {
        max-height: 280px !important;
        overflow-y: auto !important;
    }

    .dept-list .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(1), .dept-list .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(1) {
        width: 50px;
    }

    .dept-list .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(2), .dept-list .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(2) {
        width: 320px;
    }

    .dept-list .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(3), .dept-list .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(3) {
        width: 200px;
    }

    .dept-list .diagrgeesfelogFor .danykz .mmodity th:nth-of-type(2), .dept-list .diagrgeesfelogFor .danykz .drag-list td:nth-of-type(2) {
        width: 520px;
    }

    /* 无效颜色 */
    .dept-list .diagrgeesfelogFor .el-button--primary.is-disabled, .dept-list .diagrgeesfelogFor .el-button--primary.is-disabled:hover {
        background-color: #1F2846;
        color: #4e505a;
        border-color: #1F2846;
    }

    /* 仓库列表 */
    .dept-list .meisfgr {
        width: 100%;
        overflow-x: scroll;
    }

    .dept-list .zhuixiaoi {
        width: 100%;
        border-collapse: collapse;
        color: #40404e;
    }

    .dept-list .zhuixiaoi .mmodity tr th {
        height: 40px;
        line-height: 40px;
        text-align: left;
        padding-left: 20px;
        font-size: 14px;
        font-weight: 600;
    }

    .dept-list .zhuixiaoi .limiting .drag-list td {
        height: 36px;
        line-height: 36px;
        text-align: left;
        padding-left: 20px;
        font-size: 14px;
        font-weight: 400;
    }

    .dept-list .zhuixiaoi .limiting .drag-list {
        display: block;
        display: flex;
    }

    .dept-list .zhuixiaoi .mmodity {
        width: 100%;
        display: block;
    }

    .dept-list .zhuixiaoi .mmodity tr {
        display: flex;
        background-color: #f5f5f5;
    }

    .dept-list .zhuixiaoi .limiting {
        overflow-y: auto !important;
        max-height: 540px;
        display: block;
    }

    .dept-list .drag-list td:nth-of-type(1), .dept-list .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .dept-list .mmodity th:nth-of-type(2), .dept-list .drag-list td:nth-of-type(2) {
        width: 150px;
    }

    .dept-list .drag-list td:nth-of-type(3), .dept-list .mmodity th:nth-of-type(3) {
        width: 100px;
    }

    .dept-list .drag-list td:nth-of-type(4), .dept-list .mmodity th:nth-of-type(4) {
        width: 100px;
    }

    .dept-list .drag-list td:nth-of-type(5), .dept-list .mmodity th:nth-of-type(5) {
        width: 150px;
    }

    .dept-list .drag-list td:nth-of-type(6), .dept-list .mmodity th:nth-of-type(6) {
        width: 150px;
    }

    .dept-list .drag-list:nth-of-type(odd) {
        background-color: #f9f9f9;
        color: #40404e;
    }

    .dept-list .drag-list:nth-of-type(even) {
        background-color: #f5f5f5;
        color: #40404e;
    }

    .dept-list .zhuixiaoi .el-checkbox__label {
        color: #40404e;
    }

    .dept-list .zhuixiaoi .mmodity .el-checkbox__label {
        font-size: 12px;
    }
    .dept-list .zhuixiaoi .mmodity th .el-checkbox__label {
        font-size: 14px;
        font-weight: 600;
    }


    .drag-list-check {
        /* background: rgba(39, 52, 82, .5) !important; */
    }


</style>

