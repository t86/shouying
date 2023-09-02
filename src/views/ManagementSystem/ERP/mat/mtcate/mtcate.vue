<template>
    <div class="mtcate">
        <!-- <div class="mtcate-headline">物料二级分类</div> -->
        <div class="mtcate-controller">
            <icon-button @click.native="xingh" text="新增二级分类" img="btn_add.png" colors="#383943"></icon-button>
            <icon-button @click.native="compileprinter" text="编辑" img="btn_edit.png" colors="#383943"></icon-button>
            <icon-button @click.native="noneffective" text="置为无效" img="btn_in_vain.png" colors="#383943"></icon-button>
            <icon-button @click.native="effective" text="置为有效" img="btn_effective.png" colors="#383943"></icon-button>
            <icon-button @click.native="printerdel" text="批量删除" img="btn_delete.png" colors="#6B2830"></icon-button>
        </div>
        <div style="position: relative">
            <div style="display: inline-block;" class="meisfgr">
                <table class="zhuixiaoi" style="min-width: 970px;">
                    <thead class="mmodity">
                    <tr>
                        <th>
                            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll"
                                         @change="handleCheckAllChange">全选&ensp;
                            </el-checkbox>
                        </th>
                        <th>二级分类名称</th>
                        <th>创建时间</th>
                        <th>更新时间</th>
                        <th>状态</th>
                    </tr>
                    </thead>
                    <tbody class="limiting" ref="systemForm" @scroll="sysHandleScroll()"
                           @mouseover="changeFlag(false)" :style="{
                    'width':tableDatas.length>12?'calc(100% + 6px)':'100%',
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
                <div class="tiaodd" v-if="tableDatas.length<1">
                    <td class="nodata" :style="{'height':`${MaxHeight}px !important`}">
                        <img src="../../../../../assets/img/wu.png" alt="">
                        <div class="hint">暂无数据</div>
                    </td>
                </div>
            </div>
            <div style="display: inline-block;position: absolute;top: 0;left: 0;z-index: 100;">
                <table class="zhuixiaoi zhuixiaoi_l" style="min-width:auto;">
                    <thead class="mmodity">
                    <tr>
                        <th>
                            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll"
                                         @change="handleCheckAllChange">全选&ensp;
                            </el-checkbox>
                        </th>
                        <th>二级分类名称</th>
                    </tr>
                    </thead>
                    <tbody class="limiting" ref="externalForm" @scroll="exterHandleScroll()"
                           @mouseover="changeFlag(true)" :style="{
                    'width':tableDatas.length>12?'calc(100% + 6px)':'100%',
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
                    </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- 新增  编辑-->
        <div v-show="dialogFormVisible" class="dialogFormVisible">
            <el-dialog :title="title?'新增二级级分类':'编辑二级级分类'" @close="dialogFormVisible = false"
                       :visible.sync="dialogFormVisible" :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>一级分类：
                        </div>
                        <div style="color:#40404e;;" class="controlling">{{hqyjc.n}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>二级分类：
                        </div>
                        <el-input v-model="materialStair" @blur="limitingRule(0)" placeholder="请输入二级分类名称"
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
export default {
  data(){
    return {
      tableDatas: [],//二级分类目录
      multipleSelection: [],// 选中的内容
      isIndeterminate: false,// 二级分类选择一部分
      checkAll: false,//二级分类全选

      dialogFormVisible: false,//控制新建一级分类是否显示
      materialStair: "",//二级分类名字
      title: true,//为新建还是编辑
      id: '',//一级id
      hqyjc: {},//一级分类信息


      dialogFible: false,//控制错误2是否显示
      srnr: '',//文案
      cwsm: {
        ns: [],//不可操作列表
        cs: [],//可一键操作列表
      },//错误2说明
      kzsfjy: false,//控制同步按钮是否禁用

      mistake: '',//弹窗内错误提示
      windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
      MaxHeight: 0,//滚动高度
      MaxNumber: 0,//最大个数

      flag: false
    }
  },
  mounted(){
    // this.demand()
    // console.log(w);
    console.log(this.$route.params.id);
    this.id = this.$route.params.id
    this.demand()
    // this.$parent.demand()
    this.hqyjcl()

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
            this.mistake = '请输入二级分类名称'
          } else {
            if (this.$overall.character(this.materialStair) > 60) {
              this.mistake = '输入文字长度超过30'
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
    // 获取一级分类内容
    hqyjcl(){
      this.$api.ERP.mocate.requestmocatelist().then(res => {
        console.log(res);
        if (res.code == 1) {
          for (const key in res.data) {
            if (this.id == res.data[key].id) {
              this.hqyjc = res.data[key]
            }
          }
        } else {
          this.$message.warning(res.msg)
        }
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
    // 获取二级分类内容  标记
    demand(){
      this.$api.ERP.mtcate.requestmtcatelist({id: Number(this.id)}).then(res => {
        console.log(res);
        // this.$parent.tiaoz(this.id,res.data)
        this.tableDatas = res.data || [];
        var s = []
        for (const iterator of this.tableDatas) {
          s.push(iterator.id)
        }
        for (var i = 0; i < this.multipleSelection.length; i++) {
          if (s.indexOf(this.multipleSelection[i]) == -1) {
            this.multipleSelection.splice(i, 1)
          }
        }
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
      this.dialogFormVisible = true
      this.title = true
      this.materialStair = ''
      this.edit()
      this.czyangs()
      this.mistake = ''
    },
    // 创建二级分类
    construction(){
      for (var i = 0; i < 1; i++) {
        this.limitingRule(i)
      }
      if (this.mistake != '') {
        this.$message.warning('请按提示正确填写')
      } else {
        this.$api.ERP.mtcate.requestmtcatenew({
          mat_one_cate_id: Number(this.id),
          name: this.materialStair,
        }).then(res => {
          console.log(res);
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
                message: res.msg,
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
        this.$api.ERP.mtcate.requestmtcateget({id: this.multipleSelection[0]}).then(res => {
          console.log(res);
          this.materialStair = res.data.name
          this.title = false
          this.dialogFormVisible = true
          this.edit()
          this.czyangs()
          this.mistake = ''
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
        this.$api.ERP.mtcate.requestmtcatesave({
          id: this.multipleSelection[0],
          name: this.materialStair,
        }).then(res => {
          console.log(res);
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
      this.$api.ERP.mtcate.requestmtcateob({
        op_status: Number(s),
        type_ids: tid,
        ids: id
      }).then(res => {
        if (res.code == 1) {
          for (const key in this.cwsm.cs) {
            this.cwsm.cs[key].jg = '成功'
          }
          this.demand()
          this.chdefrs()
          this.dialogFible = false
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
        this.$api.ERP.mtcate.requestmtcatedisable({ids: this.multipleSelection}).then(res => {
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
        this.$api.ERP.mtcate.requestmtcateenable({ids: this.multipleSelection}).then(res => {
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
        this.$api.ERP.mtcate.requestmtcatedel({ids: this.multipleSelection}).then(res => {
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
      var s = i - 48 - 60 - 55 - 37
      this.MaxHeight = s
      this.MaxNumber = Math.floor(s / 37)
      console.log(this.MaxNumber);
      // console.log(i);
    }
  },
  watch: {
    '$route': function () {
      console.log(this.$route.params.id);
      this.id = this.$route.params.id
      this.demand()
      this.hqyjcl()
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
    .mtcate {
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding: 20px 30px;
    }

    /* 必填 */
    .mtcate .mandatory {
        color: #40404e;
        width: 140px;
        text-align: right;
        line-height: 34px;

    }

    .mtcate .controlling {
        width: 230px !important;
        line-height: 34px;
    }

    .cwts {
        color: #CE4253;
        line-height: 34px;
        padding-left: 10px;
    }

    .mtcate .reqfieldsd {
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
    .mtcate .nodata {
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
    }

    .mtcate .nodata img {
        width: 60px;
        height: 60px;
    }

    .mtcate .nodata .hint {
        line-height: 36px;
        font-size: 13px !important;
    }

    /* 内容 */
    .mtcate .mtcate-headline {
        font-size: 30px;
        font-weight: bold;
        color: #40404e;
    }

    .mtcate .mtcate-controller {
        /* margin-top: 30px; */
        height: 54px;
        width: 100%;
        /* width: 1400px; */
        background-color: #eee;
        display: flex;
        align-items: center;
    }

    .mtcate .layouts {
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .mtcate .compatibility {
        display: flex;
        /* align-items: center; */
        margin-bottom: 10px;
    }

    .mtcate .required {
        width: 60px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .mtcate .el-dialog {
        background-color: #f9f9f9;
    }

    .mtcate .el-input__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
    }

    .mtcate .el-dialog__footer {
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }

    .mtcate .el-dialog__title, .mtcate .el-dialog__headerbtn .el-dialog__close, .mtcate .el-form-item__label {
        color: #1a1a21;
    }

    .mtcate .el-input {
        width: 100%;
    }

    .mtcate .el-form-item {
        display: flex;
        margin: 0;
    }

    .mtcate .el-table th.el-table__cell.is-leaf {
        background-color: #2A2B34;
        color: #40404e;
        border-bottom: 1px solid #383943;
        border-right: 1px solid #383943;
    }

    .mtcate .el-checkbox-group {
        display: flex;
        align-items: flex-end;
        justify-content: left;
    }

    .mtcate .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    /* 靠右 */
    .mtcate .el-dialog {
        margin: 0px 0px 0px auto !important;
        height: 100%;
        position: relative;
    }

    .mtcate .el-dialog__body {
        padding: 0px 0px 30px 20px;
        overflow-y: scroll !important;
        width: 100%;
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;

    }

    .mtcate .dialogFormVisible .el-dialog {
        width: 720px;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    /* 错误2 */
    .mtcate .diagrgeesfelogFor .el-dialog {
        width: 720px;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .mtcate .diagrgeesfelogFor .wwent {
        color: #ce4153;
        font-size: 14px;
        margin: 20px 0px 20px 20px;
        display: flex;
        align-items: center;
    }

    .mtcate .diagrgeesfelogFor .wentlb {
        margin-left: 20px;
        width: 640px;
    }

    .mtcate .diagrgeesfelogFor .zhuixiaoi {
        width: 100%;
    }

    .mtcate .diagrgeesfelogFor .zhuixiaoi .limiting {
        max-height: 280px !important;
        overflow-y: auto !important;
    }

    .mtcate .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(1), .mtcate .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(1) {
        width: 50px;
    }

    .mtcate .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(2), .mtcate .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(2) {
        width: 320px;
    }

    .mtcate .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(3), .mtcate .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(3) {
        width: 200px;
    }

    .mtcate .diagrgeesfelogFor .danykz .mmodity th:nth-of-type(2), .mtcate .diagrgeesfelogFor .danykz .drag-list td:nth-of-type(2) {
        width: 520px;
    }

    /* 无效颜色 */
    .mtcate .diagrgeesfelogFor .el-button--primary.is-disabled, .mtcate .diagrgeesfelogFor .el-button--primary.is-disabled:hover {
        background-color: #1F2846;
        color: #4e505a;
        border-color: #1F2846;
    }

    /* 仓库列表 */
    .mtcate .meisfgr {
        width: 100%;
        overflow-x: scroll;
    }

    .mtcate .zhuixiaoi {
        width: 100%;
        border-collapse: collapse;
        color: #40404e;
    }

    .mtcate .zhuixiaoi .mmodity tr th {
        height: 40px;
        line-height: 40px;
        text-align: left;
        padding-left: 20px;
        font-size: 14px;
        font-weight: 600;
        color: #1a1a21;
    }

    .mtcate .zhuixiaoi .limiting .drag-list td {
        height: 36px;
        line-height: 36px;
        text-align: left;
        padding-left: 20px;
        font-size: 14px;
        font-weight: 400;
    }

    .mtcate .zhuixiaoi .limiting .drag-list {
        display: block;
        display: flex;
    }

    .mtcate .zhuixiaoi .mmodity {
        width: 100%;
        display: block;
    }

    .mtcate .zhuixiaoi .mmodity tr {
        display: flex;
        background-color: #f5f5f5;
    }

    .mtcate .zhuixiaoi .limiting {
        overflow-y: auto !important;
        max-height: 540px;
        display: block;
    }

    .mtcate .drag-list td:nth-of-type(1), .mtcate .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .mtcate .mmodity th:nth-of-type(2), .mtcate .drag-list td:nth-of-type(2) {
        width: 300px;
    }

    .mtcate .drag-list td:nth-of-type(3), .mtcate .mmodity th:nth-of-type(3) {
        width: 200px;
    }

    .mtcate .drag-list td:nth-of-type(4), .mtcate .mmodity th:nth-of-type(4) {
        width: 200px;
    }

    .mtcate .drag-list td:nth-of-type(5), .mtcate .mmodity th:nth-of-type(5) {
        width: 100px;
    }

    .mtcate .drag-list:nth-of-type(odd) {
        background-color: #f9f9f9;
        color: #40404e;
    }

    .mtcate .drag-list:nth-of-type(even) {
        background-color: #f5f5f5;
        color: #40404e;
    }

    .mtcate .zhuixiaoi .el-checkbox__label {
        color: #40404e;
    }

    .mtcate .zhuixiaoi .mmodity .el-checkbox__label {
        font-size: 14px;
    }
    
    .mtcate .zhuixiaoi .mmodity th .el-checkbox__label {
        font-weight: 600;
        color: #1a1a21;
    }

    .drag-list-check {
        /* background: rgba(39, 52, 82, .5) !important; */
    }


</style>

