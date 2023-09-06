<template>
    <div class="seat_grp">
        <div class="seat_grp-controller">
            <icon-button @click.native="xingh" text="新增" img="btn_add.png" colors="#383943"></icon-button>
            <icon-button @click.native="compileprinter" text="编辑" img="btn_edit.png" colors="#383943"></icon-button>
            <icon-button @click.native="printerdel" text="批量删除" img="btn_delete.png" colors="#6B2830"
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
                        <th>低消组名称</th>
                        <th>包含卡台数量</th>
                        <th>最低消费额</th>
                        <th>创建时间</th>
                        <th>更新时间</th>
                    </tr>
                    </thead>
                    <tbody class="limiting" ref="systemForm" @scroll="sysHandleScroll()" @mouseover="changeFlag(false)"
                           :style="{'border-bottom':tableData.length<1?'0px':'',
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
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.sc || '---'}}</td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">
                            <div class="money">{{item.m || '---'}}</div>
                        </td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.c || '---'}}</td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.u}}</td>
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
            <div style="display: inline-block;position: absolute;top: 0;left: 0;z-index: 100;">
                <table class="zhuixiaoi zhuixiaoi_l" style="width: auto">
                    <thead class="mmodity">
                    <tr>
                        <th>
                            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll"
                                         @change="handleCheckAllChange">
                                全选&ensp;
                            </el-checkbox>
                        </th>
                        <th>低消组名称</th>
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

        <!-- 新增  编辑-->
        <div v-show="dialogFormVisible" class="dialogFormVisible">
            <el-dialog :title="title?'新增':'编辑'" @close="dialogFormVisible = false" :visible.sync="dialogFormVisible"
                       :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>低消组名称：
                        </div>
                        <el-input v-model="reoffset.name" placeholder="请输入低消组名称" ref="selectsse" class="controlling"
                                  :class="form_rule_msg_name?'error':''" @blur="validator('name')"/>
                        <div class="cwts">{{form_rule_msg_name}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>最低消费金额(元)：
                        </div>
                        <el-input v-model="reoffset.min_csm" placeholder="请输入最低消费金额(元)" class="controlling"/>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>卡台列表：
                        </div>
                        <el-button type="primary" @click="Selecta">选择</el-button>
                    </div>
                    <table class="zhuixaoise" v-show="Cardmachine.length > 0">
                        <thead class="mmodity">
                        <tr>
                            <th>区域名称</th>
                            <th>区域状态</th>
                            <th>卡台名称</th>
                            <th>卡台状态</th>
                        </tr>
                        </thead>
                        <tbody class="limiting" :style="{'width':'100%'}">
                        <tr v-for="(item,i) in Cardmachine" :key="i" class="drag-list">
                            <td>{{item.n}}</td>
                            <td>{{item.s == 1? '有效':'无效'}}</td>
                            <td>
                                <div class="divbigesd" v-for="(ite,j) in item.is" :key="j">
                                    <div class="data">
                                        {{ite.n}}
                                    </div>
                                    <div v-if="j+1 != item.is.length" class="xian"></div>
                                </div>
                            </td>
                            <td>
                                <div class="divbigesd" v-for="(ite,j) in item.is" :key="j">
                                    <div class="data">
                                        {{ite.s == 1? '有效':'无效'}}
                                    </div>
                                    <div v-if="j+1 != item.is.length" class="xian"></div>
                                </div>
                            </td>
                        </tr>
                        </tbody>
                    </table>
                </el-form>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFormVisible = false">取消</el-button>
                    <el-button v-show="title" type="primary" @click="construction">新建</el-button>
                    <el-button v-show="!title" type="primary" @click="saveprinter">确认</el-button>
                </span>
            </el-dialog>
        </div>
        <!-- 选择卡台 -->
        <div v-show="Offsetgoupcf" class="Selectkajata">
            <el-dialog title="选择卡台" @close="Offsetgoupcf = false" :visible.sync="Offsetgoupcf"
                       :close-on-click-modal="false">
                <div class="seat_grpssdw" v-for="(item,i) in regions" :key="i" v-show="item.is.length > 0">
                    <div class="area">{{item.n}}</div>
                    <div class="dispflexlay">
                        <div v-for="(iere,j) in item.is" :key="j">
                            <label :for="iere.id" v-show="iere.po">
                                <div class="everylast"
                                     :style="{'border':iere.pd==true?'solid 2px #2170FF':'solid 2px transparent'}">
                                    <div>
                                        <div class="name" style="font-size: 22px;" ref="name">{{iere.n}}</div>
                                        <div class="quits" style="font-size: 16px;" ref="quits">{{iere.si | unit}}</div>
                                    </div>
                                    <img class="yellow" v-show="iere.pd==true" src="../../../../assets/img/assign_cards_to_select.png"
                                         alt="">
                                </div>
                                <input type="checkbox" style="display:none" :value="iere.id" :id="iere.id"
                                       v-model="selective">
                            </label>
                            <div v-show="!iere.po">
                                <div class="everylast" style="border:solid 2px transparent;opacity: 0.25;">
                                    <div style="background-color:#c7c7c7;">
                                        <div class="name" style="font-size: 22px;" ref="name">{{iere.n}}</div>
                                        <div class="quits" style="font-size: 16px;" ref="quits">{{iere.si | unit}}</div>
                                    </div>
                                </div>
                                <input type="checkbox" style="display:none" :value="iere.id" :id="iere.id"
                                       v-model="selective">
                            </div>
                        </div>


                    </div>
                </div>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="Offsetgoupcf = false">取消</el-button>
                    <el-button type="primary" @click="optfor">确认</el-button>
                </span>
            </el-dialog>
        </div>
    </div>
</template>
<script>
import IconButton from '@/components/IconButton.vue'//根据路径导入组件
let thia;
export default {
  data(){
    return {
      tableData: [],//列表
      regions: [],//区域卡台列表
      seat_grps: [],//低消组定义,  用以id映射名称 使用
      dialogFormVisible: false,//控制新建是否显示
      reoffset: {
        id: '',
        name: '',
        min_csm: '',
        seat_ids: []
      },//低消组
      Cardmachine: [],//低消组卡台列表
      multipleSelection: [],// 选中的内容
      isIndeterminate: false,// 选择一部分
      checkAll: false,//全选

      title: true,//判断是新建还是编辑
      Offsetgoupcf: false,//是否显示选择卡台

      selective: [],//选中卡台id

      wdadg: [],
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
    this.demand()
    this.Toconfigure();
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
  beforeCreate(){
    thia = this
  },
  filters: {
    unit(v){
      if (v != 0) {
        for (const key in thia.seat_grps) {
          if (thia.seat_grps[key].id == v) {
            return thia.seat_grps[key].n
          }
        }
      }

    }
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
        case "name":
          if (this.reoffset.name == '') {
            this.form_rule_msg_name = '请输入低消组名称'
          } else if (this.$overall.character(this.reoffset.name) > 20) {
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
    // 获取待配置卡台列表
    Toconfigure(){
      this.$api.BMS.seat_grp.requestseat_grpseat_map().then(res => {
        console.log(res);
        if (res.code == 1) {
          for (const key in res.data.regions) {
            res.data.regions[key].is = res.data.regions[key].is || []
            for (const ke in res.data.regions[key].is) {
              if (res.data.regions[key].is[ke].si == 0) {
                res.data.regions[key].is[ke].po = true
              } else {
                res.data.regions[key].is[ke].po = false
              }
              if (this.selective.length > 0) {
                for (const iterator of this.selective) {
                  if (iterator == res.data.regions[key].is[ke].id) {
                    res.data.regions[key].is[ke].pd = true
                  }
                }
              } else {
                res.data.regions[key].is[ke].pd = false
              }
            }
          }
          this.regions = res.data.regions || []
          console.log(this.regions);
          this.seat_grps = res.data.seat_grps || []
        } else {
          this.$message.warning(res.msg)
        }
      })
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
    // 获取列表信息内容
    demand(){
      this.$api.BMS.seat_grp.requestseat_grplist().then(res => {
        console.log(res);
        if (res.code == 1) {
          this.tableData = res.data || []
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 打开创建
    xingh(){
      this.form_rule_msg_name = ''
      this.dialogFormVisible = true
      this.reoffset = {
        name: '',
        min_csm: '',
        seat_ids: []
      },//低消组
        this.Cardmachine = []
      this.selective = []
      this.title = true
      this.edit()
      this.Toconfigure()
    },
    // 创建
    construction(){
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_name) return;
      if (this.reoffset.name == '' || this.reoffset.min_csm == '' || this.reoffset.seat_ids.length == 0) {
        this.$message.warning('请填写或选择必填项')
      } else {
        this.$api.BMS.seat_grp.requestseat_grpnew({
          name: this.reoffset.name,
          min_csm_amt: Number(this.reoffset.min_csm),
          seat_ids: this.reoffset.seat_ids,
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
      }

    },
    // 打开选择卡台
    Selecta(){
      this.Offsetgoupcf = true
      this.selective = []
      for (const iterator of this.Cardmachine) {
        for (const key of iterator.is) {
          this.selective.push(key.id)
        }
      }
      this.characterssize()
      console.log(this.regions);

    },
    // 根据文字长度改变文字大小
    characterssize(){
      this.$nextTick(() => {  //次要代码
        console.log(this.$refs);
        for (const key in this.$refs.name) {
          this.$refs.name[key].style.fontSize = '22px'
          while (this.$refs.name[key].offsetWidth < this.$refs.name[key].scrollWidth) {
            var w = this.$refs.name[key].style.fontSize.indexOf('p')
            this.$refs.name[key].style.fontSize = Number(this.$refs.name[key].style.fontSize.substr(0, w)) - 1 + 'px'
          }
        }
        for (const key in this.$refs.quits) {
          this.$refs.quits[key].style.fontSize = '16px'
          while (this.$refs.quits[key].offsetWidth < this.$refs.quits[key].scrollWidth) {
            var w = this.$refs.quits[key].style.fontSize.indexOf('p')
            this.$refs.quits[key].style.fontSize = Number(this.$refs.quits[key].style.fontSize.substr(0, w)) - 1 + 'px'
          }
        }
      })
    },
    // 选择完毕
    optfor(){
      this.reoffset.seat_ids = this.selective
      this.Cardmachine = []
      for (const i in this.regions) {
        for (const j in this.regions[i].is) {
          for (const ke of this.selective) {
            if (this.regions[i].is[j].id == ke) {
              console.log(this.Cardmachine.length > 0);
              if (this.Cardmachine.length > 0) {
                var w = 0
                for (const k in this.Cardmachine) {
                  if (this.Cardmachine[k].n == this.regions[i].n) {
                    w = 0
                    this.Cardmachine[k].is.push(this.regions[i].is[j])
                  } else {
                    w = w + 1
                  }
                }
                if (w == this.Cardmachine.length) {
                  w = 0
                  this.Cardmachine.push({
                    n: this.regions[i].n,
                    s: this.regions[i].s,
                    is: [this.regions[i].is[j]],
                  })
                }
              } else {
                this.Cardmachine.push({
                  n: this.regions[i].n,
                  s: this.regions[i].s,
                  is: [this.regions[i].is[j]],
                })
              }
            }
          }
        }
      }
      console.log(this.Cardmachine);
      this.Offsetgoupcf = false
    },
    // 编辑内容
    compileprinter(){
      if (this.multipleSelection.length == 1) {
        this.form_rule_msg_name = ''
        this.$api.BMS.seat_grp.requestseat_grpget({id: this.multipleSelection[0]}).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.reoffset.id = res.data.id
            this.reoffset.name = res.data.name
            this.reoffset.min_csm = res.data.min_csm_amt
            var s = []
            for (const iterator of res.data.regions) {
              for (const key of iterator.is) {
                s.push(key.id)
              }
            }
            for (const key in this.regions) {
              for (const ky in this.regions[key].is) {
                for (const ittor of s) {
                  if (this.regions[key].is[ky].id == ittor) {
                    this.regions[key].is[ky].po = true
                    console.log(this.regions[key].is[ky].po);
                  }
                }
              }
            }

            this.selective = s
            this.reoffset.seat_ids = s

            this.dialogFormVisible = true
            this.title = false


            this.Cardmachine = res.data.regions
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
      this.$api.BMS.seat_grp.requestseat_grpsave({
        id: this.multipleSelection[0],
        name: this.reoffset.name,
        min_csm_amt: Number(this.reoffset.min_csm),
        seat_ids: this.reoffset.seat_ids,
      }).then(res => {
        if (res.code == 1) {
          this.$message({
            showClose: true,
            message: "操作成功",
            type: 'success'
          })
          this.demand()
          this.dialogFormVisible = false
          this.bempty()
          this.Toconfigure()
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 删除
    printerdel(){
      if (this.multipleSelection.length > 0) {
        this.$api.BMS.seat_grp.requestseat_grpdel({ids: this.multipleSelection}).then(res => {
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
    selectives(){
      return JSON.parse(JSON.stringify(this.selective))
    },
    reoffsetss(){
      return JSON.parse(JSON.stringify(this.reoffset))
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
    // 根据选择了哪一个卡台给卡台加上对号或去掉对号
    selectives: {
      deep: true,
      handler: function (after, before) {
        // console.log(after);
        for (const key in this.regions) {
          for (const ke in this.regions[key].is) {
            this.regions[key].is[ke].pd = false
            for (const inde of after) {
              if (inde == this.regions[key].is[ke].id) {
                this.regions[key].is[ke].pd = true
              }
            }
          }
        }
      }
    },
    // 输入数字
    reoffsetss: {
      deep: true,
      handler: function (after, before) {
        if (after.min_csm != before.min_csm) {
          var reg = /^[0-9]*$/
          if (!reg.test(after.min_csm)) {
            this.$message({
              message: '请输入数字',
              type: 'warning'
            });
            this.reoffset.min_csm = before.min_csm
          }
        }
      }
    },


  }
}
</script>
<style>

    /* 靠右 */
    .seat_grp .el-dialog {
        margin: 0px 0px 0px auto !important;
        background-color: #f9f9f9;
        height: 100%;
        position: relative;
    }

    .seat_grp .el-dialog__footer {
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }

    .seat_grp .el-dialog__body {
        padding: 0px 0px 30px 20px;
        overflow-y: scroll !important;
        /* width: 100%; */
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;
    }

    .seat_grp .el-dialog {
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .seat_grp {
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding: 20px 30px;
    }

    /* 金额 */
    .money {
        /*text-align: right !important;*/
        padding: 0 10px;
    }

    /* 必填 */
    .seat_grp .mandatory {
        color: #40404e;
        width: 140px;
        text-align: right;
    }

    .seat_grp .controlling {
        color: #40404e;
        width: 230px
    }

    .seat_grp .reqfieldsd {
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
    .seat_grp .tiaodd {
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

    .seat_grp .nodata {
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        padding: 0;
    }

    .seat_grp .nodata img {
        width: 60px;
        height: 60px;
    }

    .seat_grp .nodata .hint {
        line-height: 36px;
        font-size: 13px !important;
    }

    .seat_grp .tiaodd {
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

    .seat_grp .nodata {
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        padding: 0;
    }

    .seat_grp .nodata img {
        width: 60px;
        height: 60px;
    }

    .seat_grp .nodata .hint {
        line-height: 36px;
        font-size: 13px !important;
    }

    /* 改限制字体数量的颜色背景 */
    .seat_grp .el-input .el-input__count .el-input__count-inner {
        background: none;
        color: #40404e;
    }

    .seat_grp .el-input__suffix {
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

    .seat_grp .compatibility {
        display: flex;
        align-items: center;
        margin-bottom: 10px;
    }

    .seat_grp-headline {
        font-size: 30px;
        font-weight: bold;
        color: #40404e;
    }

    .seat_grp-controller {
        /*margin-top: 30px;*/
        height: 54px;
        /*width: 1600px;*/
        background-color: #eee;
        display: flex;
        align-items: center;
    }

    .seat_grp .el-dialog .el-button--default {
        background-color: #ccc;
        border: 1px solid #ccc;
        color: #40404e;
    }

    .seat_grp .el-dialog {
        background-color: #f9f9f9;
    }

    .seat_grp .el-dialog__header, .seat_grp .el-dialog__footer {
        background-color: #1a1a21;
    }

    .seat_grp .el-dialog__title, .seat_grp .el-dialog__headerbtn .el-dialog__close, .seat_grp .el-form-item__label {
        color: #1a1a21;
    }

    .seat_grp .el-checkbox__input {
        background-color: transparent;
    }

    .seat_grp .el-dialog {
        width: 30vw;
    }

    /* 改变多选框背景颜色和上下间距 */
    .seat_grp .el-checkbox-group {
        display: flex;
        align-items: flex-end;
        justify-content: left;
    }

    .seat_grp .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    /* 列表 */
    .zsykd {
        width: 100%;
        overflow-x: scroll !important;
    }

    .seat_grp .zhuixiaoi {
        width: 1600px;
        border-collapse: collapse;
        color: #40404e;
    }

    .seat_grp .zhuixiaoi .mmodity tr th {
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-size: 14px;
        font-weight: 600;
        padding-left: 20px;
        color: #40404e;
    }

    .seat_grp .zhuixiaoi .mmodity tr th:nth-of-type(1) .el-checkbox__label {
        font-weight: 600;
        font-size: 14px;
        color: #40404e;
    }

    .seat_grp .zhuixiaoi .limiting .drag-list td {
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-size: 14px;
        font-weight: 400;
        padding-left: 20px;
    }

    .seat_grp .zhuixiaoi .limiting .drag-list {
        display: block;
        display: flex;
    }

    .seat_grp .zhuixiaoi .mmodity {
        width: 100%;
        display: block;
    }

    .seat_grp .zhuixiaoi .mmodity tr {
        display: flex;
        background-color: #f5f5f5;
    }

    .seat_grp .zhuixiaoi .limiting {
        overflow-y: auto !important;
        max-height: 540px;
        display: block;
    }

    .seat_grp .drag-list td:nth-of-type(1), .seat_grp .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .seat_grp .mmodity th:nth-of-type(2), .seat_grp .drag-list td:nth-of-type(2) {
        width: 240px;
    }

    .seat_grp .drag-list td:nth-of-type(3), .seat_grp .mmodity th:nth-of-type(3) {
        width: 140px;
    }

    .seat_grp .drag-list td:nth-of-type(4), .seat_grp .mmodity th:nth-of-type(4) {
        width: 140px;
    }

    .seat_grp .drag-list td:nth-of-type(5), .seat_grp .mmodity th:nth-of-type(5) {
        width: 140px;
    }

    .seat_grp .drag-list td:nth-of-type(6), .seat_grp .mmodity th:nth-of-type(6) {
        width: 140px;
    }

    .seat_grp .drag-list:nth-of-type(odd) {
        background-color: #f9f9f9;
        color: #40404e;
    }

    .seat_grp .drag-list:nth-of-type(even) {
        background-color: #f5f5f5;
        color: #40404e;
    }

    /* 全选颜色 */
    .seat_grp .zhuixiaoi .el-checkbox__label {
        color: #40404e;
    }

    .seat_grp .zhuixiaoi .mmodity .el-checkbox__label {
        font-size: 12px;
    }

    /* 新增列表 */
    .seat_grp .dialogFormVisible .zhuixaoise {
        /* width:800px; */
        border-collapse: collapse;
        color: #40404e;
        margin-left: 40px;
    }

    .seat_grp .dialogFormVisible .el-dialog {
        width: 700px !important;
    }

    .seat_grp .dialogFormVisible .zhuixaoise .mmodity tr th {
        height: 40px;
        line-height: 40px;
        text-align: center;
        border-right: solid 1px #383943;
        border-top: solid 1px #383943;
        border-bottom: solid 1px #383943;
        background-color: #f5f5f5;
        font-size: 14px;
        font-weight: 400;
    }

    .seat_grp .dialogFormVisible .zhuixaoise .mmodity tr th:nth-of-type(1) {
        border-left: solid 1px #383943;
    }

    .seat_grp .dialogFormVisible .zhuixaoise .limiting .drag-list td {
        text-align: center;
        border-right: solid 1px #383943;
        border-bottom: solid 1px #383943;
        font-size: 14px;
        font-weight: 400;
    }

    .seat_grp .dialogFormVisible .zhuixaoise .limiting .drag-list td:nth-of-type(1) {
        border-left: solid 1px #383943;
    }

    .seat_grp .dialogFormVisible .ewdefed {
        color: #40404e;
        font-size: 20px;
        margin: 20px 0 10px 10px;
        line-height: 30px;
    }

    .seat_grp .dialogFormVisible .zhuixaoise {
        min-width: 602px !important;
        display: inline-block;
    }

    .seat_grp .dialogFormVisible .divbigesd {
        display: flex;
        flex-direction: column;
    }

    .seat_grp .dialogFormVisible .divbigesd .data {
        height: 30px;
        line-height: 30px;
    }

    .seat_grp .dialogFormVisible .divbigesd .xian {
        height: 1px;
        background-color: #383943;
    }
    .seat_grp .dialogFormVisible .zhuixaoise .drag-list td,.seat_grp .dialogFormVisible .zhuixaoise .mmodity th{
      padding-left: 0;
    }

    .seat_grp .dialogFormVisible .zhuixaoise .drag-list td:nth-of-type(1), .seat_grp .dialogFormVisible .zhuixaoise .mmodity th:nth-of-type(1) {
        width: 140px;
    }

    .seat_grp .dialogFormVisible .zhuixaoise .drag-list td:nth-of-type(2), .seat_grp .dialogFormVisible .zhuixaoise .mmodity th:nth-of-type(2) {
        width: 140px;
    }

    .seat_grp .dialogFormVisible .zhuixaoise .drag-list td:nth-of-type(3), .seat_grp .dialogFormVisible .zhuixaoise .mmodity th:nth-of-type(3) {
        width: 140px;
    }

    .seat_grp .dialogFormVisible .zhuixaoise .drag-list td:nth-of-type(4), .seat_grp .dialogFormVisible .zhuixaoise .mmodity th:nth-of-type(4) {
        width: 140px;
    }
</style>
<style>
    .seat_grp .Selectkajata .el-dialog {
        width: 1160px !important;
    }

    .seat_grp .Selectkajata .el-dialog__body {
        padding: 20px 20px 10px;
    }

    .seat_grp .Selectkajata .seat_grpssdw {
        background-color: #f9f9f9;
        margin-bottom: 10px;
        padding: 5px 5px;
    }

    .seat_grp .Selectkajata .area {
        font-size: 18px;
        color: #40404e;
        margin-left: 15px;
        margin-top: 1px;
        margin-bottom: 4px;
    }

    .seat_grp .Selectkajata .dispflexlay {
        display: flex;
        flex-wrap: wrap;
    }

    .seat_grp .Selectkajata .dispflexlay .everylast {
        margin: 0 0 4px 4px;
        position: relative;
        padding: 3px;
        box-sizing: border-box;
    }

    .seat_grp .Selectkajata .dispflexlay .everylast .yellow {
        width: 24px;
        height: 24px;
        position: absolute;
        top: 0px;
        left: 0px;
    }

    .seat_grp .Selectkajata .dispflexlay .everylast > div {
        width: 97px;
        height: 56px;
        background-color: #eee;
        border: solid 1px #888;

        color: #40404e;
        box-sizing: border-box;
        padding: 4px 6px;
        display: flex;
        flex-direction: column;
        justify-content: space-between;
    }

    .seat_grp .Selectkajata .dispflexlay .everylast > div div {
        width: 100%;
        font-weight: bold;
        white-space: nowrap;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .drag-list-check {
        /* background: rgba(39, 52, 82, .5) !important; */
    }

</style>
