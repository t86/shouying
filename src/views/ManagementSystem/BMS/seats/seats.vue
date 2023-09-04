<template>
    <div class="seats">
        <div class="searchselect">
            <el-input v-model="nr" prefix-icon="el-icon-search" class="classifysearch" placeholder="搜索" clearable
                      @clear="dainj"/>
            <div class="collapse" v-show="sfshow" style="padding-left:6px" :style="{'max-height':`${MaxHeight}px`}">
                <el-collapse v-model="stairNames" @change="stairhandleChange" accordion>
                    <el-collapse-item name="全部">
                        <router-link to="/BMS/seats/region" :style="{'background-color':gaibland=='全部'?'':''}"
                                     slot="title" class="routerlinkyus collapse-title">
                            <img class="icons" src="@/assets/img/file_list.png" alt="">
                            <ellipsis-tooltip text="全部"></ellipsis-tooltip>
                        </router-link>
                        <!-- 区域列表 stair -->
                        <div v-for="(stair,i) in classify" :style="{'background-color':gaibland==stair.id?'#d7e9ff':''}"
                             style="width: calc(100% - 35px);padding-left: 35px;border-radius:6px"
                             :key="i" class="collapse-title" @click="secondhandleChange(stair)">
                            <img class="icons" src="@/assets/img/file_list.png" alt="">
                            <router-link :to="`/BMS/seats/seat/${stair.id}`" class="routerlinkyus" style="width: calc(100% - 18px);">
                                <ellipsis-tooltip :text="stair.n || '-----'"></ellipsis-tooltip>
                            </router-link>
                        </div>
                    </el-collapse-item>
                </el-collapse>
            </div>
            <div class="eresult" v-show="!sfshow">
                <div class="lbao" v-show="searchesult.sl > 0">
                    <div class="liebia" v-show="searchesult.yij.length > 0">区域列表：</div>
                    <div class="yansnafe" v-show="searchesult.yij.length > 0">
                        <div class="lbnrs" v-for="(stair,i) in searchesult.yij" :key="i" @click="xuanzyij(stair.id+'')">
                            <img class="icons" src="@/assets/img/file_list.png" alt="">
                            <ellipsis-tooltip :text="stair.n || '-----'"></ellipsis-tooltip>
                        </div>
                    </div>
                    <div class="liebia" v-show="searchesult.erj.length > 0">卡台列表：</div>
                    <div class="yansnafe" v-show="searchesult.erj.length > 0">
                        <div class="lbnrs"  v-for="(stair,i) in searchesult.erj" :key="i" @click="xuanzerj(stair.id+'')">
                            <img class="icons" src="@/assets/img/file_list.png"  alt="">
                            <ellipsis-tooltip  :text="stair.n || '-----'"></ellipsis-tooltip>
                        </div>
                    </div>
                </div>
                <div class="meiy" v-show="searchesult.sl == 0">
                    <img src="../../../../assets/img/wu.png" alt="">
                    <div>未搜索到相关数据</div>
                </div>
            </div>
        </div>
        <div style="width: calc(100% - 200px);">
            <router-view/>
        </div>

        <!-- 编辑卡台 -->
        <div class="dialogFormVisible" v-show="dialogFormVisible">
            <el-dialog title="编辑卡台" :visible.sync="dialogFormVisible"
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
                        <el-input v-model="Area.Quantitys" placeholder="请填写数字" oninput="this.value = this.value.replace(/[^0-9]/g, '');"
                                  class="controlling" :class="form_rule_msg_quantitys?'error':''"
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
                    <el-button @click="showOrHideDetailDialog" type="danger">删除</el-button>
                    <el-button @click="dialogFormVisible = false">取消</el-button>
                    <el-button type="primary" @click="saveSeat">保存</el-button>
                </span>
            </el-dialog>
        </div>

      
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
        <p style="line-height:40px">确认删除此卡台信息？</p>
        <span slot="footer" class="dialog-footer">
          <el-button @click="showOrHideDetailDialog">取 消</el-button>
          <el-button type="primary" @click="deleteSureHandle">确 定</el-button>
        </span>
      </el-dialog>
    </div>
</template>
<script>
import IconButton from '@/components/IconButton.vue'//根据路径导入组件
import EllipsisTooltip from '@/components/EllipsisTooltip.vue'//根据路径导入组件
import { sessionStorage, localStorage } from '@/utils/common/storage'
import eventVue from '@/utils/eventVue';
export default {
  data() {
    return {
      id: '', // 搜索id
      nr: '',// 搜索内容
      stairNames: '全部',// 全部
      secondNames: '',// 区域id
      classify: [],//区域数据

      gaibland: '全部',//选中哪一个状态

      searchesult: {
        yij: [],
        erj: [],
        sl: ''
      },//模糊查询结果
      sfshow: true,//是否查询

      Area: {
        Place: "",
        Name: "",
        Quantitys: 1,
        radio: '',
        profession: ''
      },//卡台信息
      id:"",
      region_id:"",
      dialogFormVisible: false,//控制编辑卡台是否显示
      parent_name:"",

      windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
      MaxHeight: 0,//滚动高度

      form_rules: ["name", "quantitys"],
      form_rule_msg_name: "",
      form_rule_msg_quantitys: "",


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
    }

    eventVue.$on('reloadReginList', () => {
      this.demand()
    })

  },
  components: {
    EllipsisTooltip,
    IconButton
  },

  methods: {
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
      }
    },
    // 请求数据
    demand(){
      this.$api.BMS.region.requestRegionTree().then(res => {
        if (res.code == 1) {
          this.classify = res.data || [];
        } else {
          this.$message.warning(res.msg)
        }
      })

    },
    // 请求区域数据
    stairhandleChange(val) {
      this.secondNames = "全部";
    },

    // 请求卡台数据 获取区域id
    secondhandleChange(item){
      console.log(item)
      this.secondNames = item.id;
      localStorage.setItem("parent_name", item.n)
    },

    // 给卡台添加区域id
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
      this.nr = ''
      this.sfshow = true
      this.stairNames = '全部'
      this.secondNames = id
      this.$router.push(`/BMS/seats/seat/${id}`)
    },
    // 查询选择 二级
    xuanzerj(id){
      this.id = id
      this.form_rule_msg_name = ''
      this.form_rule_msg_quantitys = ''
      this.$api.BMS.seat.requestseatget({id:Number(id)}).then(res => {
        this.Area.Name = res.data.name
        this.Area.Quantitys = res.data.capacity
        this.Area.radio = res.data.seat_type + ''
        this.Area.profession = res.data.biz_type + ''
        this.dialogFormVisible = true;
        this.id = res.data.id;
        this.region_id = res.data.region_id;
        this.parent_name = res.data.region_name;
      })
    },

    // 保存编辑内容
    saveSeat(){
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_name || this.form_rule_msg_quantitys) return;
      var reg = /^[0-9]*$/
      if (reg.test(this.Area.Quantitys)) {
        this.$api.BMS.seat.requestseatsave({
          id: this.id,
          name: this.Area.Name,
          capacity: parseInt(this.Area.Quantitys),
          seat_type: Number(this.Area.radio),
          biz_type: Number(this.Area.profession),
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "保存成功",
              type: 'success'
            })
            this.dialogFormVisible = false
          } else {
            this.$message({message: res.msg, type: 'warning',})
          }
        })
      } else {
        this.$message({message: '请输入纯数字后在保存', type: 'warning',})
      }

    },
    // 查询选择 物料
    xuanzwl(id){

    },

    dainj(){
      console.log(1234);
    },

    // 滚动最大高度
    RollMaxHeight(i){
      var s = i - 48 - 60 - 34 - 10
      this.MaxHeight = s
    },

    showOrHideDetailDialog(){
      this.dialogDelVisible = !this.dialogDelVisible
    },

    async deleteSureHandle(){
      const params = {ids: [this.id]}
      try {
        const res = await this.$api.BMS.seat.requestseatdel(params)
        if (res.code == 1) {
          this.$message.success('操作成功')
          this.showOrHideDetailDialog()
          this.dialogFormVisible = false;
          this.nr = ''
          eventVue.$emit('reloadTableData')
        } else if (res.code == 2) {
          this.dialogFible = true;
          this.srnr = "批量删除";
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

  },
  computed: {},
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
              sl: ''
            }
            this.sfshow = false
            this.$api.BMS.region.requestRegionSearch({name: after}).then(res => {
              if (res.code == 1) {
                for (const key in res.data) {
                  if (res.data[key].t == 1) {
                    this.searchesult.yij.push(res.data[key])
                  } else if (res.data[key].t == 2) {
                    this.searchesult.erj.push(res.data[key])
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
    secondNames: {
      deep: true,
      handler: function (after, before) {
         console.log(after);
        if (after != '') {
          this.gaibland = after
        } else {
          this.gaibland = this.$route.params.id
        }
      }
    },
  }
}
</script>
<style>
    .seats {
        /* width: calc(100% - 40px);
        height: calc(100% - 80px);
        padding:40px 20px; */
        height: calc(100% - 40px);
        display: flex;

    }

    .searchselect {
        padding-top: 40px;
        width: 200px;
        height: 100%;
        border-right: 1px solid #eee;
    }

    .searchselect .classifysearch {
        width: 180px;
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

    .searchselect .collapse .stair .el-collapse-item__header {
        padding-left: 18px;
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
    .seats .eresult {

        /* padding-right: 6px; */
        max-height: 700px;
        overflow-x: scroll;
        overflow: overlay;
    }

    .seats .eresult .lbao {
        margin-top: 20px;
    }

    .seats .eresult .lbao .liebia {
        height: 40px;
        line-height: 40px;
        font-size: 12px;
        color: #8C8C8C;
        padding-left: 10px;
    }

    .seats .eresult .lbao .yansnafe {
        margin: 0 10px;
        border-radius: 6px;
    }

    .seats .eresult .lbao .lbnrs {
        height: 40px;
        width: 100%;
        display: flex;
        align-items: center;
    }

    .seats .eresult .lbao .lbnrs:hover {
        background-color: #ddd;
        border-radius: 6px;
        cursor: pointer;
    }

    .seats .eresult .lbao .lbnrs img {
        margin-left: 14px;
        width: 14px;
        height: 14px;
    }

    .seats .eresult .lbao .lbnrs div {
        margin-left: 4px;
        color: #40404e;
        font-size: 14px;
    }

    .seats .searchselect .eresult .meiy {
        display: flex;
        flex-direction: column;
        align-items: center;
        padding-top: 128px;
    }

    .seats .searchselect .eresult .meiy img {
        width: 60px;
        height: 60px;
    }

    .seats .searchselect .eresult .meiy div {
        margin-top: 20px;
        font-size: 14px;
        color: #40404e;
    }


    /* 靠右 */
    .seats .el-dialog {
        margin: 0px 0px 0px auto !important;
        background-color: #f9f9f9;
        height: 100%;
        position: relative;
    }

    .seats .el-dialog__footer {
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }

    .seats .el-dialog__body {
        padding: 0px 0px 30px 20px;
        overflow-y: scroll !important;
        /* width: 100%; */
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;
    }

    .seats .el-dialog {
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .seats .dialogFormVisible .el-dialog {
        width: 550px !important;
    }

    .seats .compatibility {
        display: flex;
        /* align-items: center; */
        margin-bottom: 10px;
    }

    .seats .compatibility1 {
        display: flex;
        align-items: center;
        margin-bottom: 15px;
    }

    .seats .compatibility1 .el-input__inner {
        width: 90px;
    }

    .seats .required {
        width: 40px;
        color: red;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .seats .el-dialog .el-button--default {
        background-color: #ccc;
        border: 1px solid #ccc;
        color: #40404e;
    }

    .seats .el-dialog {
        background-color: #f9f9f9;
    }

    .seats .el-input__inner {
        background-color: transparent;
        color: #40404e;
    }

    .seats .el-dialog__header, .seats .el-dialog__footer {
        background-color: #1a1a21;
    }

    .seats .el-dialog__title, .seats .el-dialog__headerbtn .el-dialog__close, .seats .el-form-item__label {
        color: #1a1a21;
    }

    .seats .el-form-item {
        display: flex;
        margin: 0;
    }


    /* 必填 */
    .seats .mandatory {
        color: #40404e;
        width: 140px;
        text-align: right;
        padding-top: 10px;
    }

    .seats .controlling {
        width: 230px !important;
        line-height: 40px;
        color: #40404e;
    }

    .seats .controlleingsg {
        width: 300px !important;
        line-height: 40px;
        color: #40404e;
        display: flex;
    }

    .seats .controlleingsg input {
        width: 98px !important;
    }

    .seats .controlleingsg .ateast {
        margin: 0 10px;
    }

    .seats .reqfieldsd {
        font-size: 16px;
        padding-right: 4px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 改限制字体数量的颜色背景 */
    .seats .el-input .el-input__count .el-input__count-inner {
        background: none;
        color: #40404e;
    }

    .seats .kaitanm .el-input__suffix {
        background-color: #1A1A20;
        color: #40404e;
        right: -45px;
        top: 8px;
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }
</style>