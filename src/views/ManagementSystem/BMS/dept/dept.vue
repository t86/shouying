<template>
    <div class="Singless dept">
        <div class="searchselect">
            <el-input v-model="nr" prefix-icon="el-icon-search" class="classifysearch" placeholder="搜索" clearable
                      @clear="dainj"/>
            <div class="collapse" v-show="sfshow" :style="{'max-height':`${MaxHeight}px`}">
                <el-collapse v-model="stairNames" @change="stairhandleChange" accordion>
                    <el-collapse-item name="全部">
                        <router-link to="/BMS/dept/emp/0"
                                     slot="title" class="routerlinkyus collapse-title">
                            <img class="icons" src="@/assets/img/文件夹.png" alt="">
                            <ellipsis-tooltip text="全部"></ellipsis-tooltip>
                        </router-link>

                        <menus :classify="classify" :deptIds="deptIds" :gaibland="gaibland" @onChange="onChange"/>

                    </el-collapse-item>
                </el-collapse>
            </div>
            <div class="eresult" v-show="!sfshow">
                <div class="lbao" v-show="searchesult.sl > 0">
                    <div class="liebia" v-show="searchesult.yij.length > 0">部门列表：</div>
                    <div class="yansnafe" v-show="searchesult.yij.length > 0">
                        <div class="lbnrs" v-for="(stair,i) in searchesult.yij" :key="i"
                             :style="{'background-color':deptId==stair.id?'#D7E9FF':''}"
                             @click="xuanzyij(stair.id+'')">
                            <img class="icons" src="@/assets/img/文件夹.png" alt="">
                            <ellipsis-tooltip :text="stair.n || '-----'"></ellipsis-tooltip>
                        </div>
                    </div>
                    <div class="liebia" v-show="searchesult.wl.length > 0">员工列表(姓名+工号)：</div>
                    <div class="yansnafe" v-show="searchesult.wl.length > 0">
                        <div class="lbnrs" v-for="(stair,i) in searchesult.wl" :key="i" @click="xuanzwl(stair.id)">
                            <img class="icons" src="@/assets/img/商品列表.png" alt="">
                            <ellipsis-tooltip :text="stair.n || '-----'"></ellipsis-tooltip>
                        </div>
                    </div>
                </div>
                <div class="meiy" v-show="searchesult.sl == 0">
                    <img src="../../../../assets/img/wu.png" alt="">
                    <div>未搜索到相关数据</div>
                </div>
            </div>
        </div>
        <div style="width: calc(100% - 236px);">
            <router-view/>
        </div>

        <!-- 新增  编辑-->
        <div v-show="dialogFormVisible" class="dialogFormVisible">
            <el-dialog title="编辑员工" @close="dialogFormVisible = false"
                       :visible.sync="dialogFormVisible" :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>上级部门：
                        </div>
                        <div style="color:#40404e;;" class="controlling">{{parent_name}}</div>
                    </div>

                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>姓名：
                        </div>
                        <el-input v-model="materialStair" @blur="limitingRule(0)" placeholder="请输入员工姓名"
                                  ref="selectsse" class="controlling"/>
                        <div class="cwts">{{mistake}}</div>
                    </div>

                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>简拼：
                        </div>
                        <div style="color:#40404e;line-height: 40px;" class="controlling">
                            {{namePy}}
                        </div>
                    </div>

                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>岗位：
                        </div>
                        <el-select v-model="stationId" placeholder="请选择岗位" class="controlling">
                            <el-option v-for="(each,i) in station_list" :key="i" :label="each.n"
                                       :value="each.id +''"></el-option>
                        </el-select>
                    </div>

                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>工号：
                        </div>
                        <el-input v-model="code" oninput="this.value = this.value.replace(/[^0-9]/g, '');"
                                  placeholder="请输入员工工号"
                                  :maxLength="8"
                                  ref="codeRef" class="controlling" @blur="limitingRule(1)"/>
                        <div class="cwts">{{codeRefMistake}}</div>
                    </div>
                    <div class="layouts">可使用系统自动生成的编号，也可以手动修改(长度不超过8，只支持数字)</div>

                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>性别：
                        </div>
                        <el-form-item>
                            <el-radio v-model="sex" label="1">男</el-radio>
                            <el-radio v-model="sex" label="2">女</el-radio>
                        </el-form-item>
                    </div>

                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>员工直属上级：
                        </div>
                        <el-select
                                v-model="upperEmpId"
                                filterable
                                remote
                                reserve-keyword
                                placeholder="请输入姓名或工号"
                                :remote-method="toMatItems"
                                ref="upperEmpIdRef"
                                class="topwidth"
                                :loading="loading">
                            <el-option
                                    v-for="item in empoptions"
                                    :key="item.id"
                                    :label="item.n"
                                    :value="item.id">
                            </el-option>
                        </el-select>
                    </div>

                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>电话：
                        </div>
                        <el-input :maxlength="11" oninput="this.value = this.value.replace(/[^0-9]/g, '');"
                                  v-model="phoneNum" placeholder="请输入员工电话"
                                  ref="phoneNumRef" class="controlling"></el-input>
                        <!--<div class="cwts">{{mistake}}</div>-->
                    </div>
                </el-form>
                <span slot="footer" class="dialog-footer">
                    <el-button v-show="!title" type="primary" @click="resetPwdHandle">重置密码</el-button>
                    <el-button v-show="!title" type="primary" v-if="currentEmpInfo.wc==1" @click="destoryCard">作废卡</el-button>
                    <el-button v-show="!title" type="primary" @click="makeCardHandle">{{currentEmpInfo.wc == 1 ? '清卡' : '制卡'}}</el-button>
                    <el-button @click="showOrHideDetailDialog" type="danger">删除</el-button>
                    <el-button @click="dialogFormVisible = false">取消</el-button>
                    <el-button v-show="!title" type="primary" @click="saveprinter">确认</el-button>
                </span>
            </el-dialog>

            
            <!-- 无效有效删除 -->
            <div v-show="dialogFible" class="diagrgeesfelogFor">
              <el-dialog
                :title="srnr"
                :visible.sync="dialogFible"
                @close="dialogFible = false"
                :close-on-click-modal="false"
                width="50%"
              >
                <div style="color:red;line-height:40px" v-show="cwsm.ns.length>0">以下对象存在依赖，需人工处理依赖</div>
                <div v-show="cwsm.ns.length>0">
                  <table style="width:100%">
                    <thead >
                      <tr>
                        <th style="width:30%;line-height:30px;text-align:center">序号</th>
                        <th style="width:70%;line-height:30px;text-align:center">说明</th>
                      </tr>
                    </thead>
                    <tbody :style="{'width':cwsm.ns.length>6?'calc(100% + 6px)':'100%'}">
                      <tr v-for="(item,i) in cwsm.ns" :key="i" >
                        <td style="width:30%;line-height:30px;text-align:center">{{i+1}}</td>
                        <td style="width:70%;line-height:30px;text-align:center">{{item || '-----'}}</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
                <span slot="footer" class="dialog-footer">
                  <el-button @click="dialogFible = false">关闭</el-button>
                </span>
              </el-dialog>
            </div>

            <!-- 删除确认框 -->
            <el-dialog title="确认删除" :visible.sync="dialogDelVisible" width="30%" :before-close="showOrHideDetailDialog">
              <p style="line-height:40px">确认删除此员工信息？</p>
              <span slot="footer" class="dialog-footer">
                <el-button @click="showOrHideDetailDialog">取 消</el-button>
                <el-button type="primary" @click="deleteEmpSureHandle">确 定</el-button>
              </span>
            </el-dialog>

        </div>

        <!-- 制卡/清卡操作模态框 -->
        <div layout="row" style="width:100vw;height:100vw;background:rgba(0,0,0,.3);position:fixed;left:0;top:0;z-index:999999" @keyup.esc="showMakeCardModal=false" v-if="showMakeCardModal">
          <div style="padding:30px 20px;width:400px;background:#fefefe;position:absolute;top:40vh;left:50%;transform:translate(-50%,-50%);border-radius:10px">
            <p style="line-height:100px;text-align:center;font-size:20px">请将卡片放置于读卡器感应区</p>
            <div style="width:80px;height:36px;margin:20px auto 0;line-height:36px;border-radius:8px;background:#ccc;text-align:center;cursor:pointer" @click="showMakeCardModal=false">取消操作</div>
          </div>
        </div>
    </div>
</template>
<script>
import IconButton from '@/components/IconButton.vue'//根据路径导入组件
import EllipsisTooltip from '@/components/EllipsisTooltip.vue'//根据路径导入组件
import { sessionStorage, localStorage } from '@/utils/common/storage'
import Menus from './menus.vue'//根据路径导入组件
import eventVue from '@/utils/eventVue';

export default {
  data() {
    return {
      showMakeCardModal: false, // 制卡/清卡操作模态框
      nr: '',// 搜索内容
      stairNames: '全部',// 全部
      classify: [],//一级二级分类数据
      gaibland: '全部',//选中哪一个状态

      searchesult: {
        yij: [],
        erj: [],
        wl: [],
        sl: ''
      },//模糊查询结果
      sfshow: true,//是否查询
      wuliaoid: '',//物料id

      deptIds: [],

      currentEmpInfo: {},  // 当前修改的员工信息
      id: "",
      deptId: "",
      dialogFormVisible: false,//控制新建上级部门是否显示
      materialStair: "",//员工名字
      stationId: "",//岗位id
      code: "",//员工工号
      sex: "1",//员工性别
      namePy: "", //员工姓名拼音首字母
      phoneNum: "", //员工电话
      upperEmpId: "", //直属上级
      title: true,//为新建还是编辑
      empoptions: [],// 模糊查询列表
      loading: false, // 是否正在从远程获取数据
      codeRefMistake: '',//弹窗内错误提示
      mistake: '',//弹窗内错误提示
      parent_name: "",
      station_list: [],

      windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
      MaxHeight: 0,//滚动高度

      dialogDelVisible: false,  // 是否显示删除确认框
            
      dialogFible: false, //控制错误2是否显示
      srnr: "", //文案
      cwsm: {
        ns: [], //不可操作列表
        cs: [] //可一键操作列表
      }, //错误2说明
    }
  },
  mounted(){
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
    }

  },
  components: {
    EllipsisTooltip,
    IconButton,
    Menus
  },

  methods: {
    // 保存编辑内容
    saveprinter(){
      for (var i = 0; i < 1; i++) {
        this.limitingRule(i)
      }
      if (this.mistake != '') {
        this.$message.warning('请按提示正确填写')
      } else {
        this.$api.BMS.emp.requestEmpSave({
          id: this.id,
          dept_id: Number(this.deptId), //部门Id
          name: this.materialStair,  //员工姓名
          station_id: Number(this.stationId), //岗位Id
          name_py: this.namePy,   //NamePy 员工姓名拼音首字母
          code: this.code,    //Code 员工工号
          sex: Number(this.sex),     //Sex 性别 1 男 2 女
          phone_num: this.phoneNum,   //PhoneNum 联系电话
          upper_emp_id: Number(this.upperEmpId),   //UpperEmpId 直属上级
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "操作成功",
              type: 'success'
            })
            this.dialogFormVisible = false;
            this.demand();
          } else {
            this.$message.warning(res.msg)
          }
        })
      }
    },
    // 根据输入的内容模糊查找
    toMatItems(query) {
      if (query !== '') {
        this.loading = true;
        this.$api.BMS.emp.requestEmpUpperItems({
          name: query,
          page_num: 1,
          page_size: 9999999,
        }).then(res => {
          console.log(res);
          this.empoptions = res.data || []
          this.loading = false;
        })
      } else {
        this.empoptions = [];
      }
    },
    // 输入规则
    limitingRule(i){
      switch (Number(i)) {
        case 0:
          this.$refs.selectsse.$refs.input.style.borderColor = '#CE4253'
          if (this.materialStair == '') {
            this.mistake = '请输入员工姓名'
          } else {
            if (this.$overall.character(this.materialStair) > 20) {
              this.mistake = '输入文字长度超过10'
            } else {
              this.$refs.selectsse.$refs.input.style.borderColor = '#555763'
              this.mistake = ''
            }
          }
          break;
        case 1:
          this.$refs.codeRef.$refs.input.style.borderColor = '#CE4253'
          if (this.code == '') {
            this.codeRefMistake = '请输入员工工号'
          } else {
            if (this.code.length > 8) {
              this.codeRefMistake = '输入工号长度超过8'
            } else {
              this.$refs.codeRef.$refs.input.style.borderColor = '#555763'
              this.codeRefMistake = ''
            }
          }
          break
      }
    },
    // 请求数据
    demand(){
      this.$api.BMS.dept.requestDeptTree().then(res => {
        if (res.code == 1) {
          this.renderTree(res.data, 1)
          this.classify = res.data || [];
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    renderTree(data, l) {
      return data.map((item) => {
        item.l = l;
        if (item.subs) {
          this.renderTree(item.subs, l + 1);
        }
      });
    },
    // 请求物料一级分类数据
    stairhandleChange(val) {
      console.log(val)
    },

    onChange(val, l){
      let index = localStorage.getItem("menuLen")
      if (val != '') {
        this.gaibland = val
      } else {
        this.gaibland = this.$route.params.id
      }
      this.deptIds[index] = val;
    },

    // 给二级分类添加一级分类id
    tjflyj(){
      for (const key in this.searchesult.erj) {
        for (const iterator of this.classify) {
          for (const terat in iterator.subs) {
            if (this.searchesult.erj[key].id == iterator.subs[terat].id) {
              this.searchesult.erj[key].yij = iterator.id
            }
          }
        }
      }
    },
    // 查询选择 一级
    xuanzyij(id){
      this.deptId = id;
      this.$router.push(`/BMS/dept/emp/${id}`)
    },

    // 查询选择 物料
    xuanzwl(id){
      this.id = id;
      this.$api.BMS.emp.requestEmpGet({id}).then(res => {
        if (!res.data) return;
        this.$router.push(`/BMS/dept/emp/${res.data.emp.dept_id}`)
        this.empoptions = res.data.emp.upper_emp_id ? [{
          id: res.data.emp.upper_emp_id + "", n: res.data.emp.upper_emp_name
        }] : []
        this.currentEmpInfo = res.data.emp || {}
        this.materialStair = res.data.emp.name
        this.stationId = res.data.emp.station_id + ""
        this.parent_name = res.data.emp.dept_name
        this.deptId = res.data.emp.dept_id
        this.code = res.data.emp.code
        this.sex = res.data.emp.sex + ""
        this.namePy = res.data.emp.name_py
        this.phoneNum = res.data.emp.phone_num
        this.upperEmpId = res.data.emp.upper_emp_id ? res.data.emp.upper_emp_id + "" : ""
        this.station_list = res.data.stations || []

        this.title = false
        this.dialogFormVisible = true
        this.mistake = ''
      })
    },

    dainj(){
      console.log(1234);
      this.deptIds = [];
      this.gaibland = "全部";
      this.$router.push(`/BMS/dept/emp/0`)
    },
    // 滚动最大高度
    RollMaxHeight(i){
      var s = i - 48 - 60 - 34 - 10
      this.MaxHeight = s
    },

    
    showOrHideDetailDialog(){
      this.dialogDelVisible = !this.dialogDelVisible
    },

    async deleteEmpSureHandle(){
      const params = {ids: [this.id]}
      try {
        const res = await this.$api.BMS.emp.requestEmpDel(params)
        if (res.code == 1) {
          this.$message.success('操作成功')
          this.showOrHideDetailDialog()
          this.dialogFormVisible = false
          this.nr = ''
          eventVue.$emit('reloadTableData')
        } else if (res.code == 2) {
          this.dialogFible = true
          this.srnr = '批量删除'
          res.data.ns = res.data.ns || []
          res.data.cs = (res.data.cs || []).map(item => item.r)
          this.cwsm.ns = res.data.ns || []
          this.cwsm.ns = [...res.data.ns, ...res.data.cs]
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('删除员工失败', error)
      }
    },

    /**
     * 制卡
     */
    makeCardHandle(){
      const itemInfo = this.currentEmpInfo || {}
      try {
        const termType = atool.getTermType();
        if(termType == 'pc') {
          this.showMakeCardModal = true
          this.readCard(itemInfo)
        } else {
          this.$message.warning('当前设备不支持制卡')
        }
      } catch (error) {
        this.$message.warning('当前设备不支持该功能')
      }
    },

    // 读取卡号
    readCard(itemInfo) {
      let cardNo = ''
      try {
        setTimeout(() => {
          cardNo = atool.getCardNo();
          if(!cardNo) {
            if(this.showMakeCardModal) this.readCard(itemInfo)
          } else {
            itemInfo.wc == 1 ? this.getClearCardInfo(cardNo, itemInfo) : this.getBeginCardInfo(cardNo, itemInfo)
          }
        }, 1000);
      } catch (error) {
        console.log('cardNo信息获取失败：', error)
      }
    },
    // 开始制卡
    async getBeginCardInfo(cardNo, itemInfo){
      const params = {
        card_no: cardNo, //    string   卡号
        emp_id: itemInfo.id * 1, //     int64    关联员工
      }
      try {
        const res = await this.$api.BMS.emp.reqBeginMakeCard(params)
        if(res.code == 1) {
          try {
            const result = atool.doRegCard(res.data.card_pass, res.data.card_verify_data)
            if(result === '0') {
              this.makeCardEnd(cardNo, itemInfo)
            } else {
              this.$message.warning('制卡失败')
              this.showMakeCardModal = false
            }
          } catch (e) {
            console.log('制卡失败', e)
          }
        } else {
          this.$message.warning(res.msg)
          this.showMakeCardModal = false
        }
      } catch (error) {
        this.showMakeCardModal = false
        console.log('制卡begin失败', error)
      }
    },

    // 结束制卡
    async makeCardEnd(cardNo, itemInfo) {
      const params = {
        card_no: cardNo, //    string  卡号
        emp_id: itemInfo.id * 1, //     int64   关联员工
      }
      try {
        const res = await this.$api.BMS.emp.reqEndMakeCard(params)
        if(res.code == 1) {
          this.$message.success('制卡成功')
          this.dialogFormVisible = false
          this.showMakeCardModal = false
        } else {
          this.showMakeCardModal = false
          this.$message.warning(res.msg)
        }
      } catch (error) {
        this.showMakeCardModal = false
        console.log('制卡结束失败', error)
      }
    },

    // 开始清卡
    async getClearCardInfo(cardNo, itemInfo){
      const params = {
        emp_id: itemInfo.id * 1, //     int64    关联员工
      }
      try {
        const res = await this.$api.BMS.emp.reqBeginClearCard(params)
        if(res.code == 1) {
          if(res.data.card_no != cardNo) return this.$message.warning('当前员工的绑定卡与当前所刷的卡不一致')
          try {
            const result = atool.doClearCard(res.data.card_pass)
            if(result === '0') {
              this.clearCardEnd(cardNo, itemInfo)
            } else {
              this.$message.warning('清卡失败')
              this.showMakeCardModal = false
            }
          } catch (e) {
            this.showMakeCardModal = false
            console.log('清卡失败', e)
          }
        } else {
          this.showMakeCardModal = false
          this.$message.warning(res.msg)
        }
      } catch (error) {
        this.showMakeCardModal = false
        console.log('清卡begin失败', error)
      }
    },

    // 结束清卡
    async clearCardEnd(cardNo, itemInfo) {
      const params = {
        card_no: cardNo, //    string  卡号
        emp_id: itemInfo.id * 1, //     int64   关联员工
      }
      try {
        const res = await this.$api.BMS.emp.reqEndClearCard(params)
        if(res.code == 1) {
          this.$message.success('清卡成功')
          this.dialogFormVisible = false
          this.showMakeCardModal = false
        } else {
          this.showMakeCardModal = false
          this.$message.warning(res.msg)
        }
      } catch (error) {
        this.showMakeCardModal = false
        console.log('清卡end失败', error)
      }
    },

    // 重置密码
    async resetPwdHandle(){
      const params = {
        ids: [this.currentEmpInfo.id * 1]
      }
      try {
        const res = await this.$api.BMS.emp.requestEmpBatchResetPwd(params)
        if(res.code == 1) {
          this.$message.success('重置密码为666666成功')
          this.dialogFormVisible = false
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('重置密码失败', error)
      }
    },

    // 作废卡
    async destoryCard(){
      const params = {
        emp_id: this.currentEmpInfo.id * 1  //   int64  员工Id
      }

      try {
        const res = await this.$api.BMS.emp.reqDestoryCard(params)
        if(res.code == 1) {
          this.$message.success('作废卡成功')
          this.dialogFormVisible = false
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('作废失败', error)
      }
    }
  },
  computed: {},
  watch: {
    materialStair: {
      deep: true,
      handler: function (after, before) {
        if (after != before) {
          this.$api.UtilAuth.util.requestutilpy({str: after}).then(res => {
            this.namePy = res.data || ''
          })
        }
      }
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
    // 模糊查询
    nr: {
      deep: true,
      handler: function (after, before) {
        // console.log(after);
        if (this.timer) {
          clearTimeout(this.timer)
        }
        this.timer = setTimeout(() => {
          if (after == '') {
            this.sfshow = true
          } else {
            this.searchesult = {
              yij: [],
              erj: [],
              wl: [],
              sl: ''
            }
            this.sfshow = false
            this.$api.BMS.dept.requestDeptSearch({name: after}).then(res => {
              if (res.code == 1) {
                for (const key in res.data) {
                  if (res.data[key].t == 1) {
                    this.searchesult.yij.push(res.data[key])
                  } else if (res.data[key].t == 2) {
                    this.searchesult.wl.push(res.data[key])
                  }
                }
                this.tjflyj()
                // console.log(res.data);
                var s = res.data || []
                this.searchesult.sl = s.length
              } else {
                this.$message.warning(res.msg)
              }
            })
          }

        }, 500)
      }
    },
    //
    stairNames: {
      deep: true,
      handler: function (after, before) {
        console.log(after);
        this.gaibland = '全部'
        // if(after != ''){
        //     this.gaibland = after
        // }else{
        //     this.gaibland = '全部'
        // }
      }
    },
  }
}
</script>
<style>
    .Singless {
        /* width: calc(100% - 40px);
        height: calc(100% - 80px);
        padding:40px 20px; */
        height: calc(100%);
        display: flex;

    }

    .dept .searchselect {
        padding-top: 40px;
        width: 236px;
        height: 100%;
        border-right: 1px solid #eee;
    }

    .dept .searchselect .classifysearch {
        width: 216px;
        margin-left: 10px;
    }

    .searchselect .el-input {
        font-size: 12px;
    }

    .searchselect .routerlinkyus {
        color: #08080A;
        position: relative;
    }

    .searchselect .routerlinkyus:after {
        content: " ";
        width: 40px;
        height: 40px;
        position: absolute;
        left: -40px;
        top: 0;

    }

    /* 折叠面板 */
    .searchselect .collapse {
        padding-right: 6px;
        padding-left: 6px;
        max-height: 700px;
        overflow-x: scroll;
        overflow: overlay;
    }

    .searchselect .collapse .el-collapse {
        border-top: 0px !important;
    }

    /* slot放到左边 */
    .searchselect .collapse .collapse-title {
        display: flex;
        align-items: center;
        flex: 1 0 90%;
        order: 1;
        line-height: 40px;
    }

    .searchselect .collapse .el-collapse-item__header {
        flex: 1 0 auto;
        order: -1;
        font-size: 14px !important;
        background-color: #f9f9f9 !important;
        border-bottom: 0px !important;
        color: #8c8c8c;
        height: 40px;
        /* padding-left: 18px; */
        font-size: 18px;
        /* margin: 4px 6px 4px 6px; */

        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 图标大小 */
    .searchselect .collapse .icons {
        width: 14px;
        height: 14px;
        margin-right: 4px;
    }

    .searchselect .collapse .el-collapse-item__arrow {
        margin: 0 4px 0 auto;
    }

    .searchselect .collapse .el-collapse-item__wrap {
        background-color: #f9f9f9 !important;
        border-bottom: 0px;
    }

    .searchselect .collapse .el-collapse-item__content {
        padding-bottom: 0px;
    }

    /* 一级列表 */
    .searchselect .collapse .stair {

    }

    /* 二级列表 */
    .searchselect .collapse .second {
        display: flex;
        align-items: center;
        height: 40px;
        line-height: 40px;
        padding-left: 54px;
        text-align: left;
        color: #8c8c8c;
        font-size: 14px;
        /* 鼠标小手 */
        cursor: pointer;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
        border-radius: 6px;
    }

</style>
<style>
    .Singless .eresult {

        /* padding-right: 6px; */
        max-height: 700px;
        overflow-x: scroll;
        overflow: overlay;
    }

    .Singless .eresult .lbao {
        margin-top: 20px;
    }

    .Singless .eresult .lbao .liebia {
        height: 40px;
        line-height: 40px;
        font-size: 12px;
        color: #8C8C8C;
        padding-left: 10px;
    }

    .Singless .eresult .lbao .yansnafe {
        margin: 0 10px;
        border-radius: 6px;
    }

    .Singless .eresult .lbao .lbnrs {
        height: 40px;
        width: 100%;
        display: flex;
        align-items: center;
    }

    .Singless .eresult .lbao .lbnrs:hover {
        background-color: #D7E9FF;
        border-radius: 6px;
    }

    .Singless .eresult .lbao .lbnrs img {
        margin-left: 14px;
        width: 14px;
        height: 14px;
    }

    .Singless .eresult .lbao .lbnrs div {
        margin-left: 4px;
        color: #40404e;
        font-size: 14px;
    }

    .Singless .searchselect .eresult .meiy {
        display: flex;
        flex-direction: column;
        align-items: center;
        padding-top: 128px;
    }

    .Singless .searchselect .eresult .meiy img {
        width: 60px;
        height: 60px;
    }

    .Singless .searchselect .eresult .meiy div {
        margin-top: 20px;
        font-size: 14px;
        color: #40404e;
    }
</style>
<style>
    /* 表格无数据时展示 */
    .Singless .drag-list .nodata {
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
    }

    .Singless .drag-list .nodata img {
        width: 60px;
        height: 60px;
    }

    .Singless .drag-list .nodata .hint {
        font-size: 13px !important;
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

    /* 靠右 */
    .Singless .el-dialog {
        margin: 0px 0px 0px auto !important;
        height: 100%;
        position: relative;
    }

    .Singless .el-dialog__body {
        padding: 0px 0px 30px 20px;
        overflow-y: scroll !important;
        width: 100%;
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;

    }

    .Singless .el-dialog {
        border-left: 1px solid #f9f9f9;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .Singless .el-dialog__footer {
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }

    /* 必填 */
    .Singless .mandatory {
        color: #40404e;
        width: 140px;
        text-align: right;
        /* padding-top: 10px; */
        line-height: 34px;
    }

    .Singless .controlling {
        width: 230px !important;
        line-height: 40px;
    }

    .Singless .reqfieldsd {
        font-size: 16px;
        padding-right: 4px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .Singless .dialogPrinter .el-form {
        padding-top: 10px !important;
    }

    .Singless .el-dialog .el-button--default {
        background-color: #ccc;
        border: 1px solid #ccc;
        color: #40404e;
    }

    .Singless .el-dialog {
        background-color: #f9f9f9;
    }

    .Singless .el-input__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
    }

    .Singless .el-dialog__title, .Singless .el-dialog__headerbtn .el-dialog__close, .Singless .el-form-item__label {
        color: #1a1a21;
        display: flex;
        align-items: center;
    }

    .Singless table {
        border-collapse: collapse;
        /* border: solid 1px #f5f5f5; */
        color: #40404e;
    }

    /* 新建商品 */
    .Singless .dialogPrinter .el-dialog {
        /* width: 50vw !important;
        min-width: 620px !important;
        max-width:620px !important; */
        width: 1280px;
    }

    .Singless .dialogPrinter .el-dialog__body {
        padding: 10px;
    }

    .Singless .dialogPrinter .Materialunit {
        width: 1060px;
        border: 1px solid #ccc;
        padding: 10px;
    }

    .Singless .dialogPrinter .biaot {
        font-size: 24px;
        color: #40404e;
        text-align: center;
        margin-bottom: 10px;
    }

    .Singless .dialogPrinter .compa-tib {
        color: #40404e;
    }

    .Singless .dialogPrinter .rial-unit {
        display: flex;
    }

    .Singless .dialogPrinter .rial-unit .miaos {
        line-height: 34px;
        width: 630px;
        margin-left: 20px;
        color: #40404e;
    }

    .Singless .dialogPrinter .el-button--mini, .el-button--small {
        font-size: 14px !important;
    }

    .Singless .compatibil {
        margin-bottom: 10px;
    }

    .Singless .compatibility {
        display: flex;
        /* align-items: center; */
        margin-bottom: 5px;
    }

    /* 列表配置 */
    .Singless .dialogPrinter table {
        width: 1060px;
        margin-top: 10px;
        font-size: 14px;
        /* overflow: hidden; */
        display: inline-block;
    }

    .Singless .dialogPrinter table .drag-list {
        display: inline-block;
        width: 100% !important;
    }

    .Singless .dialogPrinter table .mmodity tr th {
        height: 40px;
        line-height: 40px;
        text-align: left;
        padding-left: 20px;
        font-size: 14px;
        font-weight: 600;
    }

    .Singless .dialogPrinter table .mmodity tr th .el-checkbox__label {
        font-size: 14px;
        font-weight: 600;
    }

    .Singless .dialogPrinter table .limiting .drag-list td {
        height: 40px;
        line-height: 40px;
        text-align: left;
        padding-left: 20px;
        font-size: 14px;
        font-weight: 400;
    }

    .Singless .dialogPrinter table .limiting .drag-list {
        border-top: solid 1px #f5f5f5;
        display: block;
        display: flex;
    }

    .Singless .dialogPrinter table .mmodity {
        width: 100%;
        display: block;
    }

    .Singless .dialogPrinter table .mmodity tr {
        background-color: #f5f5f5;
        display: flex;
    }

    .Singless .dialogPrinter table .limiting {
        overflow-y: scroll !important;
        max-height: 200px !important;
        border-bottom: solid 1px #f5f5f5;
        display: block;
    }

    /* 单位 */
    .Singless .dialogPrinter .Mater-unit .drag-list .nodata {
        height: 180px !important;
    }

    .Singless .dialogPrinter .Mater-unit .drag-list td {
        line-height: 39px !important;
        display: flex;
        align-items: center;
    }

    .Singless .dialogPrinter .Mater-unit .lans {
        color: #409EFF;
    }

    .Singless .dialogPrinter .Mater-unit .lans:hover {
        color: #66b1ff;
    }

    .Singless .dialogPrinter .Mater-unit .drag-list td:nth-of-type(1), .Singless .dialogPrinter .Mater-unit .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .Singless .dialogPrinter .Mater-unit .drag-list td:nth-of-type(2), .Singless .dialogPrinter .Mater-unit .mmodity th:nth-of-type(2) {
        width: 200px;
    }

    .Singless .dialogPrinter .Mater-unit .drag-list td:nth-of-type(3), .Singless .dialogPrinter .Mater-unit .mmodity th:nth-of-type(3) {
        width: 100px;
    }

    .Singless .dialogPrinter .Mater-unit .drag-list td:nth-of-type(4), .Singless .dialogPrinter .Mater-unit .mmodity th:nth-of-type(4) {
        width: 150px;
    }

    .Singless .dialogPrinter .Mater-unit .drag-list td:nth-of-type(5), .Singless .dialogPrinter .Mater-unit .mmodity th:nth-of-type(5) {
        width: 150px;
    }

    /* Mater-unit */
    /* 扩展属性 */
    .Singless .dialogPrinter .annkz {
        display: flex;
        justify-content: center;
    }

    .Singless .dialogPrinter .extend-unit {
        margin-top: 10px;
        font-size: 14px;
        /* overflow: hidden; */
        display: inline-block;
    }

    .Singless .dialogPrinter .extend-unit .drag-list .nodata {
        height: 180px !important;
    }

    .Singless .dialogPrinter .extend-unit .drag-list td:nth-of-type(1), .Singless .dialogPrinter .extend-unit .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .Singless .dialogPrinter .extend-unit .drag-list td:nth-of-type(2), .Singless .dialogPrinter .extend-unit .mmodity th:nth-of-type(2) {
        width: 200px;
    }

    .Singless .dialogPrinter .extend-unit .drag-list td:nth-of-type(3), .Singless .dialogPrinter .extend-unit .mmodity th:nth-of-type(3) {
        width: 380px;
    }

    /* 自定义属性 */
    .Singless .user-defined .el-dialog {
        width: 720px !important;
    }

    .Singless .user-defined .explain {
        /* color: #40404e; */
        /* margin-bottom:10px ; */
        margin-top: 20px;
        color: #ce4153;
        font-size: 12px;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .Singless .user-defined .el-form {
        padding-top: 20px !important;
    }

    .Singless .user-defined .attribute {
        /* width: 90%; */
        width: 350px;
        display: flex;
        flex-direction: column;
    }

    .Singless .user-defined .attribute > div {
        display: flex;
    }

    .Singless .user-defined .el-input {
        width: 230px;
        margin-bottom: 10px;
    }

    .Singless .user-defined .el-form-item__content {
        /* width: 100%; */
        display: flex;
        margin-bottom: 10px;
    }

    .Singless .user-defined .compatibil .compatibility {
        align-items: flex-start;
    }

    .Singless .user-defined .compatibil .compatibility .el-button {
        width: 40px;
        height: 40px;
        margin-left: 10px;
    }

    /* 编辑商品 */
    .Singless .dialogPrinter .needattention {
        /* margin-bottom: 10px; */
        font-size: 12px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .Singless .dialogPrinter .fenge {
        box-sizing: border-box;
        width: 100%;
        border: 1px solid #ccc;
        padding: 10px 0;
        margin-bottom: 10px;
    }

    .Singless .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(1), .Singless .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .Singless .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(2), .Singless .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(2) {
        width: 170px;
    }

    .Singless .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(3), .Singless .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(3) {
        width: 70px;
    }

    .Singless .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(4), .Singless .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(4) {
        width: 140px;
    }

    .Singless .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(5), .Singless .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(5) {
        width: 140px;
    }

    .Singless .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(6), .Singless .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(6) {
        width: 70px;
    }

    .Singless .dialogPrinter .fenge .Mater-unit .el-button + .el-button {
        margin-left: 0;
    }

    /* 编辑 添加物料单位 */
    .Singless .editaddunit .el-dialog {
        width: 720px !important;
    }

    .Singless .editaddunit .requimeiytgy {
        color: #40404e;
        font-size: 20px;
    }

    .dept .searchselect .collapse .stair .el-collapse-item__header {
        padding-left: 0;
    }

    .dept .layouts {
        font-size: 12px;
        margin-left: 140px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
        margin-bottom: 10px;
    }

    .dept .dialogFormVisible .el-dialog {
        width: 720px;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .dept .el-form-item {
        margin-bottom: 0;
    }

</style>