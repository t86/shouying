<template>
    <div class="Seat">
        <div class="Seat-controller">
            <icon-button @click.native="xingh" text="新增卡台" img="添加.png" colors="#f5f5f5"></icon-button>
            <icon-button @click.native="compileSeat" text="编辑" img="编辑.png" colors="#f5f5f5"></icon-button>
            <icon-button @click.native="noneffective" text="置为无效" img="无效.png" colors="#f5f5f5"></icon-button>
            <icon-button @click.native="effective" text="置为有效" img="有效.png" colors="#f5f5f5"></icon-button>
            <icon-button @click.native="Seatdel" text="批量删除" img="删除.png" colors="#6B2830"
                         bjcolors="#491E24"></icon-button>
            <icon-button @click.native="plnewly" text="批量新增" img="批量新增.png" colors="#f5f5f5"></icon-button>
            <characters-button @click.native="toCheck" colors="#f5f5f5" wz='预览二维码'></characters-button>
            <characters-button @click.native="downloadExpQr" colors="#f5f5f5" wz='导出全部卡台二维码'></characters-button>
            <div class="percentage" v-show="percentage">
                <span class="percentage_label">二维码生成进度：</span>
                <div class="percentage_value">
                    <el-progress :percentage="percentage"></el-progress>
                </div>
            </div>
        </div>
        <div style="position: relative">
            <div class="substance">
                <table class="zhuixiaoi">
                    <thead>
                    <tr>
                        <th class="outline">
                            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll"
                                         @change="handleCheckAllChange">全选
                            </el-checkbox>
                        </th>
                        <th>卡台名称</th>
                        <th>可坐人数</th>
                        <th>卡台类型</th>
                        <th>业务类型</th>
                        <th>创建时间</th>
                        <th>更新时间</th>
                        <th>状态</th>
                    </tr>
                    </thead>
                    <tbody class="limiting" ref="systemForm" @scroll="sysHandleScroll()" @mouseover="changeFlag(false)"
                           :style="{'border-bottom':tableData.length<1?'0px':'',
                    'width':tableData.length>MaxNumber?'calc(100% + 6px)':'100%',
                    'max-height':`${MaxHeight}px`}">
                    <tr v-for="(item,i) in tableData" :key="i" class="drag-list"
                        :class="checkedCities.includes(item.id)? 'drag-list-check':''">
                        <td class="first" :style="{'color':item.s=='无效'?'#595959':''}">
                            <el-checkbox-group v-model="checkedCities"
                                               @change="handleCheckedCitiesChange">
                                <el-checkbox :label="item.id">{{i+1}}&emsp;&ensp;</el-checkbox>
                            </el-checkbox-group>
                        </td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.n}}</td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.cp}}</td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.st}}</td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.bt}}</td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.c}}</td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.u}}</td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.s}}</td>

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
                    <thead>
                    <tr>
                        <th class="outline">
                            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll"
                                         @change="handleCheckAllChange">全选
                            </el-checkbox>
                        </th>
                        <th>卡台名称</th>
                    </tr>
                    </thead>
                    <tbody class="limiting" ref="externalForm" @scroll="exterHandleScroll()"
                           @mouseover="changeFlag(true)"
                           :style="{'border-bottom':tableData.length<1?'0px':'',
                    'width':tableData.length>MaxNumber?'calc(100% + 6px)':'100%',
                    'max-height':`${MaxHeight}px`}">
                    <tr v-for="(item,i) in tableData" :key="i" class="drag-list"
                        :class="checkedCities.includes(item.id)? 'drag-list-check':''">
                        <td class="first" :style="{'color':item.s=='无效'?'#595959':''}">
                            <el-checkbox-group v-model="checkedCities"
                                               @change="handleCheckedCitiesChange">
                                <el-checkbox :label="item.id">{{i+1}}&emsp;&ensp;</el-checkbox>
                            </el-checkbox-group>
                        </td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.n}}</td>

                    </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- 新建卡台 -->
        <div class="dialogFormVisible" v-show="dialogFormVisible">
            <el-dialog :title="compileSeatss?'新建卡台':'编辑卡台'" :visible.sync="dialogFormVisible"
                       :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>当前区域：
                        </div>
                        <div class="controlling">{{parent_name}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>卡台名称：
                        </div>
                        <el-input v-model="Area.Name" placeholder="请填写卡台名称" show-word-limit
                                  class="controlling kaitanm" :class="form_rule_msg_name?'error':''"
                                  @blur="validator('name')"/>
                        <div class="cwts">{{form_rule_msg_name}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>可坐人数：
                        </div>
                        <el-input v-model="Area.Quantitys" oninput="this.value = this.value.replace(/[^0-9]/g, '');"
                                  placeholder="请填写数字" class="controlling" :class="form_rule_msg_quantitys?'error':''"
                                  @blur="validator('quantitys')"/>
                        <div class="cwts">{{form_rule_msg_quantitys}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>卡台类型：
                        </div>
                        <el-select v-model="Area.radio" placeholder="请选择类型" class="controlling">
                            <el-option label="散台" value="1"></el-option>
                            <el-option label="吧台" value="2"></el-option>
                            <el-option label="卡座" value="3"></el-option>
                            <el-option label="包厢" value="4"></el-option>
                        </el-select>
                    </div>

                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>业务类型：
                        </div>
                        <el-select v-model="Area.profession" placeholder="请选择类型" class="controlling">
                            <el-option label="实体台" value="1"></el-option>
                            <el-option label="虚拟台" value="2"></el-option>
                        </el-select>
                    </div>
                </el-form>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFormVisible = false">取消</el-button>
                    <el-button v-show="compileSeatss" type="primary" @click="construction">新建</el-button>
                    <el-button v-show="!compileSeatss" type="primary" @click="saveSeat">保存</el-button>
                </span>
            </el-dialog>
        </div>
        <!-- 批量添加 -->
        <div class="volumeProduction" v-show="volumeProduction">
            <el-dialog title="批量新增" :visible.sync="volumeProduction" :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="explain">说明：如果卡台已存在，批量添加时则会跳过</div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>当前区域：
                        </div>
                        <div class="controlling">{{parent_name}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>编号：
                        </div>
                        <div class="controlleingsg">
                            <el-input v-model="BatchAdd.start" placeholder="起始编号" maxLength="3"
                                      oninput="this.value = this.value.replace(/[^0-9]/g, '');"/>
                            <div class="ateast">至</div>
                            <el-input v-model="BatchAdd.finish" placeholder="结束编号" maxLength="3"
                                      oninput="this.value = this.value.replace(/[^0-9]/g, '');"/>
                            <el-checkbox style="margin-left: 30px;" v-model="BatchAdd.DeleteBigit">删除数字4、7、13
                            </el-checkbox>
                        </div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>编号位数：
                        </div>
                        <el-input-number v-model="BatchAdd.Digits" :min='1' :max='3' placeholder="请填写位数"/>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>卡台名称前缀：
                        </div>
                        <el-input v-model="BatchAdd.prefix" placeholder="名称格式“卡台前缀”+“编号”" class="controlling"
                                  :class="form_rule_msg_prefix?'error':''" @blur="validator('prefix')"/>
                        <div class="cwts">{{form_rule_msg_prefix}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>可坐人数：
                        </div>
                        <el-input v-model="BatchAdd.CanSit" placeholder="请输入人数" class="controlling"
                                  oninput="this.value = this.value.replace(/[^0-9]/g, '');"
                                  :class="form_rule_msg_canSit?'error':''" @blur="validator('canSit')"/>
                        <div class="cwts">{{form_rule_msg_canSit}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>卡台类型：
                        </div>
                        <el-select v-model="BatchAdd.radio" placeholder="请选择类型" class="controlling">
                            <el-option label="散台" value="1"></el-option>
                            <el-option label="吧台" value="2"></el-option>
                            <el-option label="卡座" value="3"></el-option>
                            <el-option label="包厢" value="4"></el-option>
                        </el-select>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>业务类型：
                        </div>
                        <el-select v-model="BatchAdd.profession" placeholder="请选择类型" class="controlling">
                            <el-option label="实体台" value="1"></el-option>
                            <el-option label="虚拟台" value="2"></el-option>
                        </el-select>
                    </div>
                </el-form>
                <div class="preview">
                    <div class="mandatory" style="padding-top: 0px;">卡台预览：</div>
                    <div class="Taketogenerate">
                        <div>
                            <span v-for="(dar,i) in BatchPreview.first" :key="i">{{dar}}、</span>
                        </div>
                        <div v-show="BatchPreview.lengthJudge">
                            <div>......</div>
                            <div class="fg">
                                <div v-for="(dar,i) in BatchPreview.last" :key="i">{{dar}}、</div>
                            </div>
                        </div>
                        <div>待生成{{BatchPreview.quantity}}个卡台</div>
                    </div>
                </div>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="volumeProduction = false">取消</el-button>
                    <el-button type="primary" @click="batchtj">添加</el-button>
                </span>
            </el-dialog>
        </div>

        <!-- 无效有效删除 -->
        <div v-show="dialogFible" class="diagrgeesfelogFor">
            <el-dialog :title="srnr" :visible.sync="dialogFible" @close="dialogFible = false"
                       :close-on-click-modal="false">
                <div class="wwent" v-show="cwsm.cs.length>0">
                    <span>以下对象存在依赖，需同步设置为{{srnr | pand}}</span>
                    <characters-button @click.native="synchronizon" :disaed="kzsfjy" colors="#f5f5f5"
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
                              {{item.r || '-----'}}
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
                              {{item || '-----'}}
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

        <!-- 图片预览 -->
        <div class="imgDetails" v-show="imgDetails">
            <el-dialog title="图片预览" @close="imgDetails = false" :visible.sync="imgDetails"
                       :close-on-click-modal="false">
                <div style="display: flex;height: 100%;align-items: center;justify-content: center ">
                    <img style="height: auto;width: 500px;"
                         :src="`${imgSrc}`"
                         alt="">
                </div>
                <span slot="footer" class="dialog-footer">
                  <el-button @click="imgDetails = false">关闭</el-button>
                </span>
            </el-dialog>
        </div>
    </div>
</template>
<script>
import {mapActions, mapState, mapMutations} from "vuex"
import IconButton from '@/components/IconButton.vue'//根据路径导入组件
import EllipsisTooltip from '@/components/EllipsisTooltip.vue'//根据路径导入组件
import CharactersButton from '@/components/CharactersButton.vue'//根据路径导入组件
import { projectName, projectConfig } from '@/utils/config/projectConfig.js'
import { sessionStorage, localStorage } from '@/utils/common/storage'
import eventVue from '@/utils/eventVue';
export default {
  name: "Seat",
  data(){
    return {
      parent_name: "",
      id: "",
      tableData: [],//卡台目录
      dialogFormVisible: false,//控制新建区域是否显示
      Area: {
        Place: "",
        Name: "",
        Quantitys: 1,
        radio: '',
        profession: ''
      },//区域名称

      compileSeatss: false,//控制
      imgDetails: false,//预览控制
      imgSrc: "", //预览地址

      quantity: [],// 判断哪个要亮
      getRowKeys(row){
        return row.id
      },//根据id来判断选择
      expands: [],// 选中展开的区域
      volumeProduction: false,//控制批量添加是否显示
      BatchAdd: {
        start: '',//起始编号
        finish: '',//结束编号
        Digits: '',//编号位数
        prefix: '',//卡台名称前缀
        CanSit: 8,//可坐人数
        DeleteBigit: false,//删除数字
        radio: '',//卡台类型  1 散台   2  吧台  3 卡座 4 包厢
        profession: ''//业务类型 1 实体台  2 虚拟台
      },//批量添加
      BatchPreview: {
        first: [],//开始
        last: [],//结束
        quantity: 0,//数量
        lengthJudge: false,//判断结束有值没
      },//批量预览

      http: (process.env.NODE_ENV === 'development' ? projectConfig[projectName]['development'] : projectConfig[projectName]['product']) + '/exp',//路径

      isIndeterminate: false,//全选或者全不选
      checkAll: false,//全部选中触发
      checkedCities: [],//已选择内容

      dialogFible: false,//控制错误2是否显示
      srnr: '',//文案
      cwsm: {
        ns: [],//不可操作列表
        cs: [],//可一键操作列表
      },//错误2说明
      kzsfjy: false,//控制同步按钮是否禁用

      windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
      MaxHeight: 0,//滚动高度
      MaxNumber: 0,//最大个数

      form_rules: ["name", "quantitys"],
      form_rule_msg_name: "",
      form_rule_msg_quantitys: "",
      form_rules_pl: ["prefix", "canSit"],
      form_rule_msg_prefix: "",
      form_rule_msg_canSit: "",

      flag: false,
      percentage: undefined,
      job_id: ""
    }
  },
  mounted(){
    this.id = +this.$route.params.id;
    this.refresh(+this.$route.params.id);

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
    eventVue.$on('reloadTableData', () => {
      this.refresh(+this.$route.params.id);
    })
  },
  computed: {},
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
  methods: {
    //预览二维码
    toCheck(){
      if (this.checkedCities.length == 1) {
        this.$api.BMS.seat.requestSeatPreviewQr({seat_id: this.checkedCities[0]}).then(res => {
          console.log(res)
          const blob = new Blob([res]);
          const objectURL = URL.createObjectURL(blob);
          this.imgSrc = objectURL;
          this.imgDetails = true;
        })
      } else {
        this.$message({
          message: '请选择一个进行操作',
          type: 'warning',
        })
      }
    },

    //导出全部卡台二维码
    downloadExpQr(){
      let that = this;
      this.$api.BMS.seat.requestSeatExpQr().then(res => {
        if (res.code == 1) {
          that.job_id = res.data;
          that.getExpQrPercent();
        }
      })
    },

    //获取文件下载进度
    getExpQrPercent(){
      let that = this, http = that.http;
      this.$api.BMS.seat.requestSeatGetExpQrPercent({job_id: that.job_id}).then(res => {
        if (res.code == 1) {
          if (res.data >= 100) {
            that.percentage = 100;
            let url = http + "/" + that.job_id;
            const a = document.createElement('a')//添加a标签
            document.body.appendChild(a);
            a.href = url
            a.setAttribute('download', 'TemplateFile.xlsx') // 下载文件的名称及文件类型后缀
            a.click()//点击标签
            document.body.removeChild(a); // 下载完成移除元素
            window.URL.revokeObjectURL(url); // 释放掉blob对象
          } else {
            that.percentage = +res.data;
            setTimeout(() => {
              that.getExpQrPercent();
            }, 1000)
          }
        }
      })
    },

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
          if (this.Area.Name == '') {
            this.form_rule_msg_name = '请输入卡台名称'
          } else if (this.$overall.character(this.Area.Name) > 16) {
            this.form_rule_msg_name = '输入文字长度超过8'
          } else {
            this.form_rule_msg_name = ''
          }
          break;
        case "quantitys":
          if (this.Area.Quantitys == '') {
            this.form_rule_msg_quantitys = '请输入可坐人数'
          } else if (this.$overall.character(this.Area.Quantitys) > 2) {
            this.form_rule_msg_quantitys = '输入文字长度超过1'
          } else {
            this.form_rule_msg_quantitys = ''
          }
          break;
        case "canSit":
          if (this.$overall.character(this.BatchAdd.CanSit) > 2) {
            this.form_rule_msg_canSit = '输入文字长度超过1'
          } else {
            this.form_rule_msg_canSit = ''
          }
          break;
        case "prefix":
          if (this.$overall.character(this.BatchAdd.prefix) > 6) {
            this.form_rule_msg_prefix = '输入文字长度超过3'
          } else {
            this.form_rule_msg_prefix = ''
          }
          break
      }
    },
    // 滚动最大高度
    RollMaxHeight(i){
      var s = i - 48 - 60 - 55 - 37
      this.MaxHeight = s
      this.MaxNumber = Math.floor(s / 37)
    },
    // 控制全选或者全不选
    handleCheckAllChange(val) {
      if (val) {
        this.checkedCities = []
        for (const key in this.tableData) {
          this.checkedCities.push(this.tableData[key].id)
        }
      } else {
        this.checkedCities = []
      }
      this.isIndeterminate = false
    },
    // 控制单个选中
    handleCheckedCitiesChange(value) {
      let checkedCount = value.length;
      this.checkAll = checkedCount === this.tableData.length;
      this.isIndeterminate = checkedCount > 0 && checkedCount < this.tableData.length;
    },
    // 刷新卡台
    refresh(id){
      this.$api.BMS.seat.requestseatlist({id: Number(id)}).then(res => {
        this.tableData = res.data || [];
        this.checkedCities = []
        this.isIndeterminate = false
        this.checkAll = false
      })
    },
    // 打开新增卡台
    xingh(){
      this.form_rule_msg_name = ''
      this.form_rule_msg_quantitys = ''
      this.parent_name = localStorage.getItem("parent_name");
      this.dialogFormVisible = true
      this.compileSeatss = true
      this.beEmpty()
    },
    // 新增卡台
    construction(){
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_name || this.form_rule_msg_quantitys) return;
      if (this.Area.Name == '') {
        this.$message.warning('必选框不能为空')
      } else {
        if (this.Area.Quantitys <= 30 && this.Area.Quantitys >= 0) {
          this.$api.BMS.seat.requestseatnew({
            region_id: this.id,
            seat_name: this.Area.Name,
            capacity: parseInt(this.Area.Quantitys),
            seat_type: Number(this.Area.radio),
            biz_type: Number(this.Area.profession),
          }).then(res => {
            // console.log(res);
            if (res.code == 1 || res.code == 6) {
              if (res.msg === '') {
                this.$message({
                  showClose: true,
                  message: "新增成功",
                  type: 'success'
                })
              } else {
                this.$message({
                  showClose: true,
                  message: res.msg,
                  type: 'warning'
                })
              }
              this.refresh(this.id)
              this.dialogFormVisible = false
              this.beEmpty()
            } else {
              this.$message({message: res.msg, type: 'warning',})
            }
          })
        } else {
          this.$message({message: '可坐人数不在[0,30]范围内', type: 'warning',})
        }

      }
    },
    // 编辑内容
    compileSeat(){
      this.form_rule_msg_name = ''
      this.form_rule_msg_quantitys = ''
      if (this.checkedCities.length == 1) {
        this.$api.BMS.seat.requestseatget({id: this.checkedCities[0]}).then(res => {
          this.parent_name = localStorage.getItem("parent_name");
          this.Area.Name = res.data.name
          this.Area.Quantitys = res.data.capacity
          this.Area.radio = res.data.seat_type + ''
          this.Area.profession = res.data.biz_type + ''
          this.dialogFormVisible = true
          this.compileSeatss = false
        })

      } else {
        this.$message({
          message: '请选择一个进行编辑',
          type: 'warning',
        })
      }
    },
    // 保存编辑内容
    saveSeat(){
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_name || this.form_rule_msg_quantitys) return;
      var reg = /^[0-9]*$/
      if (reg.test(this.Area.Quantitys)) {
        this.$api.BMS.seat.requestseatsave({
          id: this.checkedCities[0],
          name: this.Area.Name,
          capacity: parseInt(this.Area.Quantitys),
          seat_type: Number(this.Area.radio),
          biz_type: Number(this.Area.profession),
        }).then(res => {
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "保存成功",
              type: 'success'
            })
            this.beEmpty()
            this.refresh(this.id)
            this.dialogFormVisible = false
          } else {
            this.$message({message: res.msg, type: 'warning',})
          }
        })
      } else {
        this.$message({message: '请输入纯数字后在保存', type: 'warning',})
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
      this.$api.BMS.seat.requestSeatOb({
        op_status: Number(s),
        type_ids: tid,
        ids: id
      }).then(res => {
        if (res.code == 1) {
          for (const key in this.cwsm.cs) {
            this.cwsm.cs[key].jg = '成功'
          }
          this.refresh(this.$route.params.id)
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
      this.$api.BMS.seat.requestseatdisable({ids: this.checkedCities}).then(res => {
        if (res.code == 1) {
          this.refresh(this.id)
          this.dialogFible = false
          this.$message({
            showClose: true,
            message: "更改状态成功",
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
          this.$message({message: res.msg, type: 'warning',})
        }
      })
    },
    // 有效
    effective(){
      this.$api.BMS.seat.requestseatenable({ids: this.checkedCities}).then(res => {
        if (res.code == 1) {
          this.refresh(this.id)
          this.dialogFible = false
          this.$message({
            showClose: true,
            message: "更改状态成功",
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
          this.$message({message: res.msg, type: 'warning',})
        }
      })
    },
    // 删除
    Seatdel(){
      if (this.checkedCities.length > 0) {
        this.$api.BMS.seat.requestseatdel({ids: this.checkedCities}).then(res => {
          if (res.code == 1) {
            this.dialogFible = false
            this.$message({
              showClose: true,
              message: "删除成功",
              type: 'success'
            })
            this.refresh(this.id)
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
            this.$message({message: res.msg, type: 'warning',})
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
    beEmpty(){
      this.Area.Name = ""
      this.Area.Quantitys = 1
      this.Area.radio = ''
      this.Area.profession = ''

    },
    // 控制批量新增开关
    plnewly(){
      this.form_rule_msg_prefix = "";
      this.form_rule_msg_canSit = "";
      this.volumeProduction = true;
      this.parent_name = localStorage.getItem("parent_name");
      this.BatchAdd = {
        start: '',//起始编号
        finish: '',//结束编号
        Digits: '',//编号位数
        prefix: '',//卡台名称前缀
        CanSit: 8,//可坐人数
        DeleteBigit: false,//删除数字
        radio: '',//卡台类型  1 散台   2  吧台  3 卡座 4 包厢
        profession: ''//业务类型 1 实体台  2 虚拟台
      },
        this.BatchPreview = {
          first: [],//开始
          last: [],//结束
          quantity: 0,//数量
          lengthJudge: false,//判断结束有值没
        }
    },
    // 批量添加卡台
    batchtj(){
      this.form_rules_pl.map(item => this.validator(item));
      if (this.form_rule_msg_prefix || this.form_rule_msg_canSit) return;
      if (!this.BatchAdd.start || !this.BatchAdd.finish || !this.BatchAdd.radio || !this.BatchAdd.profession) {
        this.$message.warning('必选框不能为空');
        return
      }
      if (this.BatchAdd.CanSit == '') {
        this.BatchAdd.CanSit = 8
      }
      this.$api.BMS.seat.requestseatbatch_new({
        region_id: this.id,
        begin_num: parseInt(this.BatchAdd.start),
        end_num: parseInt(this.BatchAdd.finish),
        num_length: parseInt(this.BatchAdd.Digits),
        exclude_spec_num: parseInt(this.BatchAdd.DeleteBigit ? 1 : 2),
        name_prefix: this.BatchAdd.prefix,
        capacity: parseInt(this.BatchAdd.CanSit),
        seat_type: Number(this.BatchAdd.radio),
        biz_type: Number(this.BatchAdd.profession),
      }).then(res => {
        if (res.code == 1 || res.code == 6) {
          this.refresh(this.id)
          this.volumeProduction = false
          if (res.msg === '') {
            this.$message({
              showClose: true,
              message: "新增成功",
              type: 'success'
            })
          } else {
            this.$message({
              showClose: true,
              message: res.msg,
              type: 'warning'
            })
          }
        } else if (res.code == -20015) {
          this.$message({
            message: res.msg,
            type: 'warning',
          })
        } else {
          this.$message({
            message: res.msg,
            type: 'warning',
          })
        }
      })
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
    // 监听路由变化
    '$route': function () {
      this.id = +this.$route.params.id;
      this.refresh(+this.$route.params.id)
    },
    // 监听批量添加内容是否改变
    BatchAdd: {
      deep: true,
      handler: function (after, before) {
        if (after.start == '' || after.finish == '' || after.Digits == '' || after.Digits * 1 < after.finish.length) {
          if (after.start == '' || after.finish == '') {
            // this.$message({message: '编号不能为空', type: 'warning',})
          } else if (after.finish < after.start) {
            this.$message({message: '结束编号不能小于起始编号', type: 'warning',})
          } else {
            // console.log(after);
            // 填写的编号位数不能小于结束编号的位数 自动补充
            if (after.Digits * 1 < after.finish.length) {
              this.BatchAdd.Digits = parseInt(after.finish.length)
            }
            // 判断前缀长度不能超过3
            if (this.BatchAdd.prefix.length > 6) {
              this.$message({message: '前缀长度不能超过3位', type: 'warning',})
            }
          }
        } else {
          if (after.finish < after.start) {
            this.$message({message: '结束编号不能小于起始编号', type: 'warning',})
          } else if (this.BatchAdd.prefix.length > 6) {
            this.$message({message: '前缀长度不能超过3位', type: 'warning',})
          } else if (after.Digits * 1 > 3) {
            this.$message({message: '填写的编号位数不能大于3', type: 'warning',})
            this.BatchAdd.Digits = 3
          } else {
            this.$api.BMS.seat.requestseatbatch_new_preview({
              begin_num: parseInt(this.BatchAdd.start),
              end_num: parseInt(this.BatchAdd.finish),
              num_length: parseInt(this.BatchAdd.Digits),
              exclude_spec_num: parseInt(this.BatchAdd.DeleteBigit ? 1 : 2),
              name_prefix: this.BatchAdd.prefix,
            }).then(res => {
              if (res.code == 500) {
                this.$message({message: '服务器异常，请稍后再试', type: 'warning',})
              } else if (res.code == -20015) {
                this.$message({message: res.msg, type: 'warning',})
              } else if (res.code == 1) {
                this.BatchPreview.first = res.data.first_seats || []
                this.BatchPreview.last = res.data.last_seats || []
                this.BatchPreview.quantity = res.data.expect_new_cnt
                if (res.data.last_seats == null) {
                  this.BatchPreview.lengthJudge = false
                }
              }
            })
          }

        }
      }
    },
    // 监听批量预览
    BatchPreview: {
      deep: true,
      handler: function (after, before) {
        if (after.last.length > 0) {
          this.BatchPreview.lengthJudge = true
        }
      }
    }

  }

}
</script>
<style>
    /* 靠右 */
    .Seat .el-dialog {
        margin: 0px 0px 0px auto !important;
        background-color: #f9f9f9;
        height: 100%;
        position: relative;
    }

    .Seat .el-dialog__footer {
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }

    .Seat .el-dialog__body {
        padding: 0px 0px 30px 20px;
        overflow-y: scroll !important;
        /* width: 100%; */
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;
    }

    .Seat .el-dialog {
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .Seat {
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding: 20px 30px;
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

    /* 区域无效改变颜色 */
    .Seat .wuxiao > td > div {
        color: #595959 !important;
    }

    .Seat .wuxiao:hover > td > div {
        color: #595959 !important;
    }

    /* 必填 */
    .Seat .mandatory {
        color: #40404e;
        width: 140px;
        text-align: right;
        padding-top: 10px;
    }

    .Seat .controlling {
        width: 230px !important;
        line-height: 40px;
        color: #40404e;
    }

    .Seat .controlleingsg {
        width: 300px !important;
        line-height: 40px;
        color: #40404e;
        display: flex;
    }

    .Seat .controlleingsg input {
        width: 98px !important;
    }

    .Seat .controlleingsg .ateast {
        margin: 0 10px;
    }

    .Seat .reqfieldsd {
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
    .Seat .drag-list .nodata {
        /*border-left: solid 1px #f5f5f5;*/
        /*border-bottom: solid 1px #f5f5f5;*/
        width: 1400px !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
    }

    .Seat .drag-list .nodata img {
        width: 60px;
        height: 60px;
    }

    .Seat .drag-list .nodata .hint {
        font-size: 13px !important;
    }

    .Seat .tiaodd {
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

    .Seat .nodata {
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        padding: 0;
    }

    .Seat .nodata img {
        width: 60px;
        height: 60px;
    }

    .Seat .nodata .hint {
        line-height: 36px;
        font-size: 13px !important;
    }

    .el-table__empty-text {
        background-color: #1A1A20;
        border-right: solid 1px #f5f5f5;
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
    }

    .el-table__empty-text img {
        width: 60px;
        height: 60px;
    }

    .el-table__empty-text .hint {
        font-size: 13px !important;
        color: #40404e6b;
    }

    /* 鼠标进入不改变颜色 */
    .Seat .el-table__body tr:nth-of-type(odd):hover > td {
        background-color: #1A1A20;
        color: #F0F0F0;
    }

    .Seat .el-table__body tr:nth-of-type(even):hover > td {
        background-color: #e5e5e5;
        color: #F0F0F0;
    }

    /* 改限制字体数量的颜色背景 */
    .Seat .el-input .el-input__count .el-input__count-inner {
        background: none;
        color: #40404e;
    }

    .Seat .kaitanm .el-input__suffix {
        background-color: #1A1A20;
        color: #40404e;
        right: -45px;
        top: 8px;
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 没一级分类的时候 */
    .Seat .between {
        display: flex;
        flex-direction: column;
        align-items: center;
        margin-top: 170px;
        padding-right: 400px;
    }

    .Seat .between img {
        width: 100px;
        height: 100px;
    }

    .Seat .between .period {
        margin-top: 30px;
        color: #a3a3a3;
        font-size: 18px;
    }

    .Seat .el-table__body-wrapper {
        max-height: 500px;
        overflow-y: auto;
        width: 1086px !important;
    }

    .Seat .el-table .el-table__cell {
        padding: 6px 0
    }

    .Seat .el-table {
        overflow: inherit;
    }

    .Seat .dianj > .el-table__body-wrapper {
        /* width: calc(100% + 17px); */
        max-height: 500px;
        overflow-y: scroll;

    }

    .Seat-headline {
        font-size: 30px;
        font-weight: bold;
        color: #40404e;
    }

    .Seat-controller {
        max-width: 1400px;
        /*margin-top: 30px;*/
        min-height: 54px;
        background-color: #e5e5e5;
        display: flex;
        align-items: center;
        flex-wrap: wrap;
    }

    .Seat .layouts {
        color: red;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .Seat .correspondent {
        position: relative;
        /* max-height: 290px; */
        /* overflow: auto; */
        width: 100%
    }

    .Seat .explain {
        color: #ce4153;
        margin-left: 10px;
        margin-bottom: 10px;
        font-size: 13px;
    }

    .Seat .compatibility {
        display: flex;
        /* align-items: center; */
        margin-bottom: 10px;
    }

    .Seat .compatibility1 {
        display: flex;
        align-items: center;
        margin-bottom: 15px;
    }

    .Seat .compatibility1 .el-input__inner {
        width: 90px;
    }

    .Seat .required {
        width: 40px;
        color: red;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .Seat .el-dialog .el-button--default {
        background-color: #ccc;
        border: 1px solid #ccc;
        color: #40404e;
    }

    .Seat .el-dialog {
        background-color: #f9f9f9;
    }

    .Seat .el-input__inner {
        background-color: transparent;
        color: #40404e;
    }

    .Seat .el-dialog__header, .Seat .el-dialog__footer {
        background-color: #1A1A21;
    }

    .Seat .el-dialog__title, .Seat .el-dialog__headerbtn .el-dialog__close, .Seat .el-form-item__label {
        color: #1a1a21;
    }

    .Seat .el-form-item {
        display: flex;
        margin: 0;
    }

    .el-table {
        background-color: rgba(0, 0, 0, 0);
    }

    .Seat .el-table th.el-table__cell.is-leaf {
        background-color: #2A2B34;
        color: #40404e;
        border-bottom: 1px solid #f5f5f5;
        border-right: 1px solid #f5f5f5;
        height: 40px;
    }

    .Seat .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    .Seat .Seat .el-dialog {
        width: 30vw;
    }

    .Seat .has-gutter {
        border: 1px solid #f5f5f5;
    }

    .Seat .el-table__empty-block {
        background-color: #e5e5e5 !important;
    }

    .Seat .el-table__empty-text {
        color: #40404e;
    }

    .Seat .el-table__body td.el-table__cell {
        border-bottom: 1px solid #f5f5f5;
        border-right: 1px solid #f5f5f5;
        height: 40px;
    }

    .Seat .el-table--border, .Seat .el-table--group {
        border-top: 1px solid #f5f5f5;
        border-left: 1px solid #f5f5f5;
    }

    .Seat .el-table--border::after,
    .Seat .el-table--group::after,
    .Seat .el-table::before {
        background-color: #f5f5f5;
    }

    .Seat table thead tr th, .Seat table tbody tr td {
        height: 40px;
        font-size: 14px;
    }

    .Seat .el-table td.el-table__cell div {
        color: #40404e;
    }

    .Seat .el-table__cell.el-table__expanded-cell {
        padding: 10px 20px 10px 40px;
        background-color: rgba(0, 0, 0, 0);
    }

    .Seat .el-table__cell.el-table__expanded-cell:hover {
        background-color: rgba(0, 0, 0, 0);
    }

    .Seat .substance {
        width: 100%;
        overflow-x: scroll !important;
        /* overflow: hidden; */
        /* height: 60px; */
        /* padding-left: 50px; */
    }

    .Seat .el-table tr:nth-of-type(odd) {
        background-color: #1A1A20;
        color: #F0F0F0;
    }

    .Seat .el-table tr:nth-of-type(even) {
        background-color: #e5e5e5;
        color: #F0F0F0;
    }

    .Seat .volumeProduction .el-dialog {
        width: 50vw !important;
        min-width: 590px !important;
        max-width: 660px !important;
    }

    .Seat .volumeProduction .el-checkbox__label {
        color: #40404e;
    }

    .Seat .dialogFormVisible .el-dialog {
        width: 550px !important;
    }

    .Seat .consumption {
        display: flex;
        align-items: center;
        height: 40px;
    }

    .Seat .consumption .el-radio {
        color: #40404e;

    }

    .Seat .preview {
        color: #40404e;
        display: flex;
        /* border-top: 1px solid #40404e; */
        /* padding-top: 20px; */
    }

    .Seat .ktyl {
        margin-left: 60px;
    }

    .Seat .Taketogenerate span {
        padding: 0 3px;
        line-height: 20px;
    }

    .Seat .Taketogenerate .fg {
        width: 400px;
        display: flex;
        flex-wrap: wrap;
    }

</style>
<style>
    /* 移动标签 */
    .Seat .zhuixiaoi {
        width: 1400px;
        /*display: inline-block;*/
        border-collapse: collapse;
        color: #40404e;
    }

    .Seat .zhuixiaoi .List-move {
        transition: transform 0.2s;
    }

    .Seat .zhuixiaoi thead, .Seat .zhuixiaoi thead tr, .Seat .zhuixiaoi tbody tr {
        width: 100% !important;

    }

    .Seat .zhuixiaoi tbody {
        display: inline-block;
        width: 100% !important;
    }

    .Seat .zhuixiaoi thead {
        /* width: 100% !important; */
        display: block;
    }

    .Seat .zhuixiaoi .drag-list {
        /*margin: 0 auto;*/
        /* width: 100% !important; */
        /* height: 40px; */
        /*line-height: 40px;*/
        /*text-align: center;*/
        /* border: solid 1px #f5f5f5; */
        display: flex;
    }

    .Seat .zhuixiaoi thead th {
        height: 36px;
        line-height: 36px;
        text-align: center;
        /*border-right: solid 1px #f5f5f5;*/
        /*border-top: solid 1px #f5f5f5;*/
        /*border-bottom: solid 1px #f5f5f5;*/
        font-size: 14px;
        font-weight: 600;
    }

    .Seat .zhuixiaoi thead th .el-checkbox__label{
      font-weight: 600;
      font-size: 14px;
    }

    .Seat .zhuixiaoi thead th:nth-of-type(1) {
        /*border-left: solid 1px #f5f5f5;*/
    }

    .Seat .zhuixiaoi tbody td {
        height: 36px;
        line-height: 36px;
        text-align: center;
        /*border-right: solid 1px #f5f5f5;*/
        /* border-top: solid 1px #f5f5f5; */
        /*border-bottom: solid 1px #f5f5f5;*/
        font-size: 14px;
        font-weight: 400;
    }

    .Seat .zhuixiaoi thead tr {
        font-weight: 600;
        background-color: #f5f5f5;
    }

    .Seat .zhuixiaoi tr {
        display: flex;
    }

    .Seat .drag-list:nth-of-type(odd) {
        background-color: #f9f9f9;
    }

    .Seat .drag-list:nth-of-type(even) {
        background-color: #f5f5f5;
    }

    .Seat .drag-list:hover td {
        /*background-color: #3C3D46;*/
    }

    .Seat .zhuixiaoi .limiting {
        overflow-y: auto !important;
        max-height: 540px;
        border-bottom: solid 1px #f5f5f5;
        display: block;
    }

    .Seat .drag-list td:nth-of-type(1), .Seat .zhuixiaoi thead th:nth-of-type(1) {
        width: 80px;
    }

    .Seat .drag-list td:nth-of-type(2), .Seat .zhuixiaoi thead th:nth-of-type(2) {
        width: 240px !important;
    }

    .Seat .drag-list td:nth-of-type(3), .Seat .zhuixiaoi thead th:nth-of-type(3) {
        width: 100px;
    }

    .Seat .drag-list td:nth-of-type(4), .Seat .zhuixiaoi thead th:nth-of-type(4) {
        width: 140px;
    }

    .Seat .drag-list td:nth-of-type(5), .Seat .zhuixiaoi thead th:nth-of-type(5) {
        width: 140px;
    }

    .Seat .drag-list td:nth-of-type(6), .Seat .zhuixiaoi thead th:nth-of-type(6) {
        width: 140px;
    }

    .Seat .drag-list td:nth-of-type(7), .Seat .zhuixiaoi thead th:nth-of-type(7) {
        width: 140px;
    }

    .Seat .drag-list td:nth-of-type(8), .Seat .zhuixiaoi thead th:nth-of-type(8) {
        width: 70px;
    }

    .Seat .zhuixiaoi .el-checkbox__label {
        color: #40404e;
        font-size: 12px;
    }

    .Seat .zhuixiaoi .mmodity .el-checkbox__label {
        font-size: 12px;
    }

    /* 错误2 */
    .Seat .diagrgeesfelogFor .el-dialog {
        width: 720px;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .Seat .diagrgeesfelogFor .wwent {
        color: #ce4153;
        font-size: 14px;
        margin: 20px 0px 20px 20px;
        display: flex;
        align-items: center;
    }

    .Seat .diagrgeesfelogFor .wentlb {
        margin-left: 20px;
        width: 640px;
    }

    .Seat .diagrgeesfelogFor .zhuixiaoi {
        width: 100%;
    }

    .Seat .diagrgeesfelogFor .zhuixiaoi .limiting {
        max-height: 280px !important;
        overflow-y: auto !important;
    }

    .Seat .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(1), .Seat .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(1) {
        width: 50px;
    }

    .Seat .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(2), .Seat .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(2) {
        width: 320px;
    }

    .Seat .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(3), .Seat .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(3) {
        width: 200px;
    }

    .Seat .diagrgeesfelogFor .danykz .mmodity th:nth-of-type(2), .Seat .diagrgeesfelogFor .danykz .drag-list td:nth-of-type(2) {
        width: 520px;
    }

    /* 无效颜色 */
    .Seat .diagrgeesfelogFor .el-button--primary.is-disabled, .Seat .diagrgeesfelogFor .el-button--primary.is-disabled:hover {
        background-color: #1F2846;
        color: #4e505a;
        border-color: #1F2846;
    }

    .Seat .el-input-number__decrease, .Seat .el-input-number__increase {
        background-color: rgba(0, 0, 0, 0);
    }

    .Seat .el-radio__label {
        color: #40404e;
    }

    .tr_disabled {
        color: #595959;
    }

    .drag-list-check {
        /* background: rgba(39, 52, 82, .5) !important; */
    }

    /* 图片预览 */
    .Seat .imgDetails .el-dialog {
        width: 600px;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .Seat .el-progress__text {
        color: #40404e;
    }

    .Seat .el-progress-bar {
        width: 65%;
    }

    .Seat .percentage{
        width:400px;
        display: flex;
        align-items: center;
        margin-left: 15px;
        min-height: 50px;
    }

    .Seat .percentage_label{
        font-size: 12px;
        color: #40404e;
        display: inline-block;
    }

    .Seat .percentage_value{
        display: inline-block;
        width: 300px;
    }

</style>