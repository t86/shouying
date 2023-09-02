<template>
  <div class="Singless">
    <div class="searchselect">
      <el-input
        v-model="nr"
        prefix-icon="el-icon-search"
        class="classifysearch"
        placeholder="搜索"
        clearable
        @clear="dainj"
      />
      <div class="collapse" v-show="sfshow" :style="{'max-height':`${MaxHeight}px`}">
        <el-collapse v-model="stairNames" @change="stairhandleChange" accordion>
          <el-collapse-item name="全部">
            <!-- <span slot="title" class=" " >
                        <img class="icons" src="@/assets/img/file_list.png"  alt="">
                        <router-link to="/ERP/mat/mocate" class="routerlinkyus" >
                            <div>全部</div>
                        </router-link>
            </span> #162C69-->
            <router-link to="/ERP/mat/mocate" slot="title" class="routerlinkyus collapse-title">
              <img class="icons" src="@/assets/img/file_list.png" alt />
              <ellipsis-tooltip text="全部"></ellipsis-tooltip>
            </router-link>
            <!-- 一级分类列表 stair -->
            <div v-for="(stair,i) in classify" :key="i" class="stair">
              <el-collapse v-model="secondNames" @change="secondhandleChange" accordion>
                <el-collapse-item :name="stair.id+''">
                  <span slot="title" class="collapse-title" style="width: calc(100% - 18px);">
                    <img class="icons" src="@/assets/img/file_list.png" alt />
                    <router-link
                      :to="`/ERP/mat/mtcate/${stair.id}`"
                      class="routerlinkyus"
                      style="width: calc(100% - 18px);"
                    >
                      <ellipsis-tooltip :text="stair.n || '-----'"></ellipsis-tooltip>
                    </router-link>
                  </span>
                  <!-- 二级分类列表 second -->
                  <div
                    v-for="(second,j) in stair.subs"
                    :style="{'background-color':gaibland==second.id?'#d7e9ff':''}"
                    :key="j"
                    class="second"
                    @click="materialhandleChange(second.id+'')"
                  >
                    <img class="icons" src="@/assets/img/file_list.png" alt />
                    <router-link
                      :to="`/ERP/mat/mats/${second.id}`"
                      class="routerlinkyus"
                      style="width: calc(100% - 18px);"
                    >
                      <ellipsis-tooltip :text="second.n || '-----'"></ellipsis-tooltip>
                    </router-link>
                  </div>
                </el-collapse-item>
              </el-collapse>
            </div>
          </el-collapse-item>
        </el-collapse>
      </div>
      <div class="eresult" v-show="!sfshow">
        <div class="lbao" v-show="searchesult.sl > 0">
          <div class="liebia" v-show="searchesult.yij.length > 0">一级分类列表：</div>
          <div class="yansnafe" v-show="searchesult.yij.length > 0">
            <div
              class="lbnrs"
              v-for="(stair,i) in searchesult.yij"
              :key="i"
              @click="xuanzyij(stair.id+'')"
            >
              <img class="icons" src="@/assets/img/file_list.png" alt />
              <ellipsis-tooltip :text="stair.n || '-----'"></ellipsis-tooltip>
            </div>
          </div>
          <div class="liebia" v-show="searchesult.erj.length > 0">二级分类列表：</div>
          <div class="yansnafe" v-show="searchesult.erj.length > 0">
            <div
              class="lbnrs"
              v-for="(stair,i) in searchesult.erj"
              :key="i"
              @click="xuanzerj(stair.id+'',stair.yij+'')"
            >
              <img class="icons" src="@/assets/img/file_list.png" alt />
              <ellipsis-tooltip :text="stair.n || '-----'"></ellipsis-tooltip>
            </div>
          </div>
          <div class="liebia" v-show="searchesult.wl.length > 0">物料列表：</div>
          <div class="yansnafe" v-show="searchesult.wl.length > 0">
            <div
              class="lbnrs"
              v-for="(stair,i) in searchesult.wl"
              :key="i"
              @click="xuanzwl(stair)"
            >
              <img class="icons" src="@/assets/img/commodity_list.png" alt />
              <ellipsis-tooltip :text="stair.n || '-----'"></ellipsis-tooltip>
            </div>
          </div>
        </div>
        <div class="meiy" v-show="searchesult.sl == 0">
          <img src="../../../../assets/img/wu.png" alt />
          <div>未搜索到相关数据</div>
        </div>
      </div>
    </div>
    <div style="width: calc(100% - 200px);">
      <router-view />
    </div>
    <!-- 编辑物料 -->
    <div class="dialogPrinter" v-show="redact">
      <el-dialog
        title="编辑物料"
        :visible.sync="redact"
        @close="gaunbbjym"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div class="fenge">
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd">*</span>物料名称：
                </div>
                <el-input
                  v-model="compileMaterial.name"
                  placeholder="请输入物料名称"
                  ref="selectsse"
                  class="controlling"
                />
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd"></span>拼音简写：
                </div>
                <div
                  style="color:#40404e;line-height: 40px;"
                  class="controlling"
                >{{compileMaterial.phoneticize}}</div>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd"></span>物料空瓶回收：
                </div>
                <el-radio v-model="compileMaterial.rtn_bottle" label="1">有</el-radio>
                <el-radio v-model="compileMaterial.rtn_bottle" label="2">无</el-radio>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd">*</span>物料单位：
                </div>
                <div style="display: flex;justify-content: space-between;">
                  <el-select
                    v-model="compileMaterial.specification"
                    placeholder="请选择物料单位"
                    class="controlling"
                  >
                    <el-option
                      v-for="each in compileMaterial.ficati"
                      :key="each.id"
                      :label="each.n"
                      :value="each.id"
                    ></el-option>
                  </el-select>
                </div>
              </div>
            </div>
          </div>
          <!-- <div class="fenge">
                        <div class="compatibil">
                            <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>物料单位：
                            </div>
                                <div class="Materialunit">
                                    <div class="rial-unit">
                                        <icon-button @click.native="addunitpopup" text="新增" img="btn_add.png" colors="#f5f5f5"></icon-button>
                                        <icon-button @click.native="deleteunit" text="删除" img="btn_delete.png" colors="#6B2830"  bjcolors="#491E24"></icon-button>                                        
                                        <div class="miaos">【如物料有多种单位；例如支、箱等，则需要将不同的单位都添加；基础单位必须排在第一个】</div>
                                    </div>
                                    <table class="Mater-unit">
                                        <thead class="mmodity">
                                            <tr>
                                                <th>
                                                    <el-checkbox :indeterminate="compile_isIndeterminate" v-model="compile_checkAll" @change="compile_handleCheckAllChange">行号</el-checkbox>
                                                </th>
                                                <th>单位</th>
                                                <th>比例</th>
                                                <th>默认采购价</th>
                                                <th>默认销售价</th>
                                                <th>操作</th>
                                            </tr>
                                        </thead>
                                        <tbody class="limiting" :style="{
                                            'width':compileMaterial.Materialunit.length>4?'calc(100% + 6px)':'calc(100% + 6px)',
                                            'border-bottom':compileMaterial.Materialunit.length<1?'0px':''}">
                                            <tr v-for="(item,i) in this.compileMaterial.Materialunit" :key="i" class="drag-list">
                                                <td>
                                                    <el-checkbox-group v-model="compile_checkedCities" @change="compile_handleCheckedCitiesChange">
                                                        <el-checkbox  :label="item.lineid">{{i+1}}</el-checkbox>
                                                    </el-checkbox-group> 
                                                </td>
                                                <td>
                                                    <el-select :disabled="compileMaterial.Materialunit[i].id!=''"   v-model="compileMaterial.Materialunit[i].id" placeholder="请选择物料单位">
                                                        <el-option v-for="each in compileMaterial.ListUnits" :key="each.id" :label="each.n" :value="each.id"></el-option>
                                                    </el-select>
                                                </td>
                                                <td>{{item.ratio}}</td>
                                                <td>
                                                    <el-input :disabled="!item.savecompile" v-model="item.bp" placeholder="输入价格"/>
                                                </td>
                                                <td>
                                                    <div v-show="item.ut == 2">—</div>
                                                    <el-input :disabled="!item.savecompile" v-show="item.ut == 1" v-model="item.sp" placeholder="输入价格"/>
                                                </td>
                                                <td>
                                                    <div class="lans" v-show="item.savecompile" @click="saveline(item,i)">保存</div>
                                                    <div class="lans" v-show="!item.savecompile" @click="compileline(item)">编辑</div>
                                                    
                                                </td>
                                            </tr>
                                            <tr class="drag-list"  v-if="compileMaterial.Materialunit.length<1">
                                                <td class="nodata">
                                                    <img src="../../../../assets/img/wu.png" alt="">
                                                    <div class="hint">暂无数据</div>
                                                </td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>                        
          </div>-->
        </el-form>
        <!-- <div class="biaot">扩展属性</div>
                <div class="fenge">
                    <div class="annkz">
                        <icon-button @click.native="addpropertyedit" style="margin: 0px 8px;" text="新增" img="btn_add.png" colors="#f5f5f5"></icon-button>
                        <icon-button @click.native="compileaddcroperty" style="margin: 0px 8px;"  text="编辑" img="btn_edit.png" colors="#f5f5f5"></icon-button>
                        <icon-button @click.native="delteperty" style="margin: 0px 8px;"  text="批量删除" img="btn_delete.png" colors="#6B2830"  bjcolors="#491E24"></icon-button>           
                    </div>
                    <el-form label-position="left">
                      <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>自定义属性：<br>（最多添加6个）
                            </div>
                            <table class="extend-unit" style="margin-left: 10px;">
                                <thead class="mmodity">
                                    <tr>
                                        <th>
                                            <el-checkbox :indeterminate="comperty_isIndeterminate" v-model="comperty_checkAll" @change="comperty_handleCheckAllChange">行号</el-checkbox>
                                        </th>
                                        <th>属性名称</th>
                                        <th>属性值</th>
                                    </tr>
                                </thead>
                                <tbody class="limiting" :style="{
                                    'width':compileMaterial.customprop.length>4?'calc(100% + 6px)':'calc(100% + 6px)',
                                    'border-bottom':compileMaterial.customprop.length<1?'0px':''}">
                                    <tr v-for="(item,i) in compileMaterial.customprop" :key="i" class="drag-list">
                                        <td>
                                            <el-checkbox-group v-model="comperty_checkedCities" @change="comperty_handleCheckedCitiesChange">
                                                <el-checkbox  :label="item.id">{{i+1}}</el-checkbox>
                                            </el-checkbox-group> 
                                        </td>
                                        <td>
                                            {{item.n}}
                                        </td>
                                        <td>
                                            <span v-for="(ite) in compileMaterial.customprop[i].ts" :key="ite.id" >{{ite.n}}；</span>
                                        </td>
                                    </tr>
                                    <tr class="drag-list"  v-if="compileMaterial.customprop.length<1">
                                        <td class="nodata">
                                            <img src="../../../../assets/img/wu.png" alt="">
                                            <div class="hint">暂无数据</div>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                      </div>
                    </el-form>
        </div>-->
        <span slot="footer" class="dialog-footer">
          <el-button @click="showOrHideDetailDialog" type="danger">删除</el-button>
          <el-button @click="gaunbbjym">关闭</el-button>
          <el-button type="primary" size="medium" @click="SaveChangesBasics">保存</el-button>
        </span>
      </el-dialog>
    </div>
    <!-- 添加物料单位 -->
    <div class="editaddunit" v-show="compileAddDialog">
      <el-dialog
        title="添加物料单位"
        :visible.sync="compileAddDialog"
        @close="compileAddDialog = false"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>单位：
              </div>
              <el-select v-model="addbjpopup.unitid" placeholder="请选择物料单位" class="controlling">
                <el-option
                  v-for="each in compileMaterial.ListUnits"
                  :key="each.id"
                  :label="each.n"
                  :value="each.id"
                ></el-option>
              </el-select>
            </div>
          </div>
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>比例：
              </div>
              <div style="color:#40404e ;" class="controlling">{{addbjpopup.proportion}}</div>
            </div>
          </div>
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>默认采购价：
              </div>
              <el-input v-model="addbjpopup.purchase" placeholder="默认采购价" class="controlling" />
            </div>
          </div>
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>默认销售价：
              </div>
              <el-input
                v-show="addbjpopup.ut == 1"
                v-model="addbjpopup.market"
                placeholder="默认销售价"
                class="controlling"
              />
              <div class="requimeiytgy controlling" v-show="addbjpopup.ut != 1">------</div>
            </div>
          </div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="compileAddDialog = false">取消</el-button>
          <el-button type="primary" @click="compileaddMaterialunit">添加</el-button>
        </span>
      </el-dialog>
    </div>
    <!-- 添加自定义属性 -->
    <div class="user-defined" v-show="controlproperty">
      <el-dialog
        title="添加自定义属性"
        :visible.sync="controlproperty"
        @close="controlproperty = false"
        :close-on-click-modal="false"
      >
        <div class="explain">说明：输入属性名称和属性值！例如属性：颜色；属性值：白色、红色；至少要有一个属性值！</div>
        <el-form label-position="left">
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>属性名：
              </div>
              <el-input v-model="attrs.n" placeholder="请输入属性名称" class="controlling" ref="slfs" />
            </div>
          </div>
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>属性值：
              </div>
              <div class="attribute">
                <div v-for="(item,i) in attrs.ns" :key="i">
                  <el-input v-model="attrs.ns[i]" placeholder="请输入属性值" ref="selectsse" />
                  <icon-button
                    v-show="attrs.ns.length != 1"
                    @click.native="attrs.ns.splice(i,1)"
                    style="margin: 0px 8px;"
                    text="批量删除"
                    img="btn_delete.png"
                    colors="#6B2830"
                    bjcolors="#491E24"
                  ></icon-button>
                  <icon-button
                    v-show="attrs.ns.length == i+1"
                    @click.native="xinz"
                    style="margin: 0px 8px;"
                    text="新增"
                    img="btn_add.png"
                    colors="#f5f5f5"
                  ></icon-button>
                </div>
              </div>
            </div>
          </div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="controlproperty = false">取消</el-button>
          <el-button type="primary" @click="addnatureproperty">新建</el-button>
        </span>
      </el-dialog>
    </div>
    <!-- 编辑自定义属性  -->
    <div class="user-defined" v-show="compiletrolprope">
      <el-dialog
        title="编辑自定义属性"
        :visible.sync="compiletrolprope"
        @close="compiletrolprope = false"
        :close-on-click-modal="false"
      >
        <div class="explain">说明：输入属性名称和属性值！例如属性：颜色；属性值：白色、红色；至少要有一个属性值！</div>
        <el-form label-position="left">
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>属性名：
              </div>
              <el-input
                v-model="compilecustomsx.nr.n"
                placeholder="请输入属性名称"
                class="controlling"
                ref="slfs"
              />
            </div>
          </div>
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>属性值：
              </div>
              <div class="attribute">
                <div v-for="(item,i) in compilecustomsx.nr.ts" :key="i">
                  <el-input v-model="item.n" placeholder="请输入属性值" ref="selectsse" />
                  <icon-button
                    v-show="compilecustomsx.nr.ts.length != 1"
                    @click.native="delecpilecuspperty(item.id,i)"
                    style="margin: 0px 8px;"
                    text="批量删除"
                    img="btn_delete.png"
                    colors="#6B2830"
                    bjcolors="#491E24"
                  ></icon-button>
                  <icon-button
                    v-show="compilecustomsx.nr.ts.length == i+1"
                    @click.native="addcpilecuspperty"
                    style="margin: 0px 8px;"
                    text="新增"
                    img="btn_add.png"
                    colors="#f5f5f5"
                  ></icon-button>
                </div>
              </div>
            </div>
          </div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="compiletrolprope = false">取消</el-button>
          <el-button type="primary" @click="customcompilenature">保存</el-button>
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
      <p style="line-height:40px">确认删除此物料信息？</p>
      <span slot="footer" class="dialog-footer">
        <el-button @click="showOrHideDetailDialog">取 消</el-button>
        <el-button type="primary" @click="deleteSureHandle">确 定</el-button>
      </span>
    </el-dialog>
  </div>
</template>
<script>
import IconButton from "@/components/IconButton.vue"; //根据路径导入组件
import EllipsisTooltip from "@/components/EllipsisTooltip.vue"; //根据路径导入组件
import { sessionStorage, localStorage } from '@/utils/common/storage'
import eventVue from '@/utils/eventVue';

let oneCateId = ''
let twoCateId = ''
export default {
  data() {
    return {
      nr: "", // 搜索内容
      stairNames: "", // 全部
      secondNames: "", // 一级级分类id
      materialNames: "", // 二级分类id
      classify: [], //一级二级分类数据

      gaibland: "", //选中哪一个状态

      dialogFible: false,

      searchesult: {
        yij: [],
        erj: [],
        wl: [],
        sl: ""
      }, //模糊查询结果
      sfshow: true, //是否查询
      wuliaoid: "", //物料id

      attrs: {}, //添加物料属性
      redact: false, //编辑商品
      compileMaterial: {
        name: "", //物料名称
        phoneticize: "", //拼音
        specification: "", //物料规格
        rtn_bottle: "2", // 1 有 2 无
        Materialunit: [], //物料单位
        ficati: [], //规格列表
        ListUnits: [], //单位列表
        customprop: [] //自定义属性列表
      }, //编辑物料内容
      compile_isIndeterminate: false, // 物料单位全选或者全不选
      compile_checkAll: false, //物料单位全部选中触发
      compile_checkedCities: [], //物料单位已选择内容
      compileAddDialog: false, // 控制编辑新增弹窗
      addbjpopup: {
        unitid: "", //单位id
        proportion: "", //比例
        purchase: "", //默认采购价
        market: "", //默认销售价
        ut: "1" //控制
      }, //新增物理单位单位

      comperty_isIndeterminate: false, // 编辑 物料属性全选或者全不选
      comperty_checkAll: false, // 编辑 物料属性全部选中触发
      comperty_checkedCities: [], // 编辑 物料属性已选择内容
      controlproperty: false, //控制 新增 物料属性添加自定义属性的弹窗
      compiletrolprope: false, //控制  物料属性编辑自定义属性的弹窗
      compilecustomsx: {
        nr: {}, //内容
        delid: [], //删除的id
        addname: [], //在后面新增的属性明细项名
        chg: [] //修改的
      }, // 编辑  编辑自定义属性

      windowWidt: document.documentElement.clientWidth, //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight, //实时屏幕高度
      MaxHeight: 0, //滚动高度

      
      dialogDelVisible: false,  // 是否显示删除确认框
      
      dialogFible: false, //控制错误2是否显示
      srnr: "", //文案
      cwsm: {
        ns: [], //不可操作列表
        cs: [] //可一键操作列表
      }, //错误2说明
    };
  },
  mounted() {
    this.$root.$on('next', () => { 
      this.demand() // 调用父路由中的方法
    })
    this.demand();
    // console.log(localStorage.getItem("openstair"));
    // console.log(localStorage.getItem("opentwo"));
    if (localStorage.getItem("openstair") == "") {
      this.stairNames = "";
    } else {
      this.stairNames = localStorage.getItem("openstair");
    }
    if (localStorage.getItem("opentwo") == "") {
      this.secondNames = "";
    } else {
      this.secondNames = localStorage.getItem("opentwo");
    }

    this.RollMaxHeight(this.windowHeigh);
    var that = this;
    window.onresize = () => {
      return (() => {
        window.fullHeight = document.documentElement.clientHeight;
        window.fullWidth = document.documentElement.clientWidth;
        that.windowHeigh = window.fullHeight; // 高
        that.windowWidt = window.fullWidth; // 宽
      })();
    };
  },
  components: {
    EllipsisTooltip,
    IconButton
  },

  methods: {
    // 请求数据
    demand() {
      this.$api.ERP.mcate.requestmcatetree().then(res => {
        if (res.code == 1) {
          // console.log(res.data);
          this.classify = res.data || [];
        } else {
          this.$message.warning(res.msg);
        }
      });
    },
    // 请求物料一级分类数据
    stairhandleChange(val) {
      console.log("1", val);
      localStorage.setItem("openstair", val);
      if (val == "") {
        this.secondNames = "";
        localStorage.setItem("opentwo", "");
      } else {
        if (this.secondNames == "") {
          this.materialNames = "";
          localStorage.setItem("openthree", "");
        }
      }
    },
    // 请求二级分类数据 获取一级分类id
    secondhandleChange(val) {
      // console.log(val);
      localStorage.setItem("opentwo", val);
      if (val == "") {
        this.materialNames = "";
        localStorage.setItem("openthree", "");
      }
    },
    // 请求物料数据  获取二级分类id
    materialhandleChange(val) {
      console.log(val);
      this.materialNames = val;
      localStorage.setItem("openthree", val);
    },

    // 给二级分类添加一级分类id
    tjflyj() {
      for (const key in this.searchesult.erj) {
        for (const iterator of this.classify) {
          for (const terat in iterator.subs) {
            if (this.searchesult.erj[key].id == iterator.subs[terat].id) {
              this.searchesult.erj[key].yij = iterator.id;
            }
          }
        }
      }
    },
    // 查询选择 一级
    xuanzyij(id) {
      this.nr = "";
      this.sfshow = true;
      this.stairNames = "全部";
      this.secondNames = id;
      this.materialNames = "";
      this.$router.push(`/ERP/mat/mtcate/${id}`);
      console.log(this.materialNames);
    },
    // 查询选择 二级
    xuanzerj(id, yij) {
      console.log(id, yij);
      this.nr = "";
      this.sfshow = true;
      this.stairNames = "全部";
      this.secondNames = yij;
      this.materialNames = id;
      this.$router.push(`/ERP/mat/mats/${id}`);
    },
    // 查询选择 物料
    xuanzwl(itemInfo) {
      const id = itemInfo.id
      oneCateId = itemInfo.oi
      twoCateId = itemInfo.ti
      this.wuliaoid = id;
      this.$api.ERP.mat.requestmatget({ id: id }).then(res => {
        this.compileMaterial.ficati = (res.data.units || []).filter(
            item => item.s == 1
          );
        this.compileMaterial.ListUnits = res.data.mat_unit_dfn;
        this.compileMaterial.Materialunit = [];
        for (const key in res.data.mat.mat_units) {
          this.compileMaterial.Materialunit.push({
            lineid: res.data.mat.mat_units[key].id, //行id
            id: res.data.mat.mat_units[key].ui, //单位id
            ratio: "", //比例
            bp: res.data.mat.mat_units[key].bp, //采购价
            sp: res.data.mat.mat_units[key].sp, //销售价\
            savecompile: false
          });
        }
        this.compileMaterial.name = res.data.mat.name;
        this.compileMaterial.phoneticize = res.data.mat.name_py;
        this.compileMaterial.rtn_bottle = res.data.mat.rtn_bottle.toString();
        this.compileMaterial.specification = res.data.mat.unit_id;
        this.compileMaterial.customprop = res.data.mat.mat_attrs || [];
        this.redact = true;
        this.unit_isIndeterminate = false;
        this.unit_checkAll = false;
      });
    },

    dainj() {
      console.log(1234);
    },

    // 编辑 物料单位控制全选或者全不选
    compile_handleCheckAllChange(val) {
      // console.log(this.compileMaterial.Materialunit);
      if (val) {
        // console.log(this.merchandise);
        this.compile_checkedCities = [];
        for (const key in this.compileMaterial.Materialunit) {
          console.log(this.compileMaterial.Materialunit[key].lineid);
          this.compile_checkedCities.push(
            this.compileMaterial.Materialunit[key].lineid
          );
        }
      } else {
        this.compile_checkedCities = [];
      }
      this.compile_isIndeterminate = false;
    },
    // 编辑 物料单位控制单个选中
    compile_handleCheckedCitiesChange(value) {
      let checkedCount = value.length;
      this.compile_checkAll =
        checkedCount === this.compileMaterial.Materialunit.length;
      this.compile_isIndeterminate =
        checkedCount > 0 &&
        checkedCount < this.compileMaterial.Materialunit.length;
      // console.log(this.checkedCities);
    },
    // 保存更改基础信息
    SaveChangesBasics() {
      this.$api.ERP.mat
        .requestmatchg({
          id: Number(this.wuliaoid),
          name: this.compileMaterial.name,
          mat_one_cate_id: Number(oneCateId),
          mat_two_cate_id: Number(twoCateId),
          name_py: this.compileMaterial.phoneticize,
          unit_id: this.compileMaterial.specification,
          rtn_bottle: this.compileMaterial.rtn_bottle * 1 // int  空瓶回收 1 回收 2 不回收
        })
        .then(res => {
          // console.log(res);
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
            this.gaunbbjym()
            this.nr = ''
            // this.refresh(this.classify.stairSecond[this.classify.stairfl].ss[this.classify.Secondfl].id)
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    // 只刷新物料单位信息
    refreshMaterialUnit() {
      this.$api.ERP.mat
        .requestmatget_only_unit({ id: Number(this.wuliaoid) })
        .then(res => {
          console.log(res);
          for (const key in res.data) {
            this.compileMaterial.Materialunit[key].bp = res.data[key].bp;
            this.compileMaterial.Materialunit[key].sp = res.data[key].sp;
            this.compileMaterial.Materialunit[key].lineid = res.data[key].id;
            this.compileMaterial.Materialunit[key].id = res.data[key].ui;
          }
        });
    },
    // 编辑物料单位行
    compileline(i) {
      console.log(i);
      i.savecompile = true;
    },
    // 保存物料单位行
    saveline(item, i) {
      console.log(item);
      if (this.compileMaterial.Materialunit[i].ut == 2) {
        this.compileMaterial.Materialunit[i].sp = "0.00";
      }
      this.$api.ERP.mat
        .requestmatchg_unit({
          id: Number(this.wuliaoid),
          mat_mat_unit_id: item.lineid,
          mat_unit_id: item.id,
          unit_buy_price: this.compileMaterial.Materialunit[i].bp,
          unit_sell_price: this.compileMaterial.Materialunit[i].sp
        })
        .then(res => {
          console.log(res);
          if (res.code == 1) {
            item.savecompile = false;
            this.refreshMaterialUnit();
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    // 新增物料单位弹窗
    addunitpopup() {
      this.refreshMaterialUnit();
      this.compileAddDialog = true;
      this.addbjpopup = {
        unitid: "", //单位id
        proportion: "", //比例
        purchase: "", //默认采购价
        market: "", //默认销售价
        ut: "1" //控制
      };
      this.edit();
    },
    // 新增物料单位
    compileaddMaterialunit() {
      // console.log(this.addbjpopup.market==""?0:this.addbjpopup.marke);
      // addbjpopup
      this.$api.ERP.mat
        .requestmatadd_unit({
          id: Number(this.wuliaoid),
          mat_unit_id: this.addbjpopup.unitid,
          unit_buy_price: this.addbjpopup.purchase,
          unit_sell_price:
            this.addbjpopup.market == "" ? "0" : this.addbjpopup.market
        })
        .then(res => {
          console.log(res);
          if (res.code == 1) {
            this.compileAddDialog = false;
            this.refreshMaterialUnit();
            this.compileMaterial.Materialunit.push({
              ui: "", //单位id
              id: "", //行id
              ratio: "", //比例
              bp: "", //采购价
              sp: "", //销售价
              savecompile: false,
              ut: this.addbjpopup.ut
            });
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
          } else {
            this.$message.warning(res.msg);
          }
        });
      // console.log(this.compileMaterial.Materialunit);
    },
    // 编辑 删除物料单位
    deleteunit() {
      // console.log(this.compile_checkedCities);
      this.$api.ERP.mat
        .requestmatrm_unit({
          id: Number(this.wuliaoid),
          mat_mat_unit_ids: this.compile_checkedCities
        })
        .then(res => {
          console.log(this.compileMaterial.Materialunit);
          console.log(this.compile_checkedCities);
          if (res.code == 1) {
            if (
              this.compileMaterial.Materialunit.length ==
              this.compile_checkedCities.length
            ) {
              this.compileMaterial.Materialunit.splice(0);
            } else {
              for (
                var i = 0;
                i < this.compileMaterial.Materialunit.length;
                i++
              ) {
                for (var j = 0; j < this.compile_checkedCities.length; j++) {
                  if (
                    this.compile_checkedCities[j] ==
                    this.compileMaterial.Materialunit[i].lineid
                  ) {
                    this.compileMaterial.Materialunit.splice(i, 1);
                    i = i - 1;
                  }
                }
              }
            }
            this.compile_isIndeterminate = false; // 物料单位全选或者全不选
            this.compile_checkAll = false; //物料单位全部选中触发
            this.compile_checkedCities = []; //物料单位已选择内容
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
          } else {
            this.$message.warning(res.msg);
          }

          console.log(res);
        });
    },
    // 编辑 物料单位控制全选或者全不选
    comperty_handleCheckAllChange(val) {
      if (val) {
        // console.log(this.merchandise);
        this.comperty_checkedCities = [];
        for (const key in this.compileMaterial.customprop) {
          console.log(key);
          this.comperty_checkedCities.push(
            this.compileMaterial.customprop[key].id
          );
        }
      } else {
        this.comperty_checkedCities = [];
      }
      this.comperty_isIndeterminate = false;
    },
    // 编辑 物料单位控制单个选中
    comperty_handleCheckedCitiesChange(value) {
      // console.log(value);
      let checkedCount = value.length;
      this.comperty_checkAll =
        checkedCount === this.compileMaterial.customprop.length;
      this.comperty_isIndeterminate =
        checkedCount > 0 &&
        checkedCount < this.compileMaterial.customprop.length;
      // console.log(this.checkedCities);
    },
    // 只刷新物料属性信息
    refreshMaterialProperty() {
      this.$api.ERP.mat
        .requestmatget_only_attr({ id: Number(this.wuliaoid) })
        .then(res => {
          console.log(res.data);
          this.compileMaterial.customprop = res.data || [];
        });
    },
    // 打开添加自定义属性
    addpropertyedit() {
      console.log(this.compileMaterial.customprop);
      // if(this.compileMaterial.customprop){
      //     this.compileMaterial.customprop = []
      // }
      this.refreshMaterialProperty();
      console.log(this.compileMaterial.customprop);
      if (this.compileMaterial.customprop.length > 5) {
        this.$message({ message: "自定义属性已添加6个", type: "error" });
      } else {
        this.addcompileproperty = true;
        this.controlproperty = true;
        this.attrs = {
          n: "",
          ns: [""],
          i: this.compileMaterial.customprop.length + 1
        };
        this.$nextTick(() => {
          //次要代码
          this.$refs.slfs.focus();
        });
      }
    },
    // 添加自定义属性
    addnatureproperty() {
      if (this.attrs.n == "" && this.attrs.ns[0] == "") {
        this.$message({ message: "请填写必填项", type: "error" });
      } else {
        console.log(this.attrs);
        console.log(Number(this.wuliaoid));
        this.$api.ERP.mat
          .requestmatadd_attr({
            id: Number(this.wuliaoid),
            attr_name: this.attrs.n,
            dtl_names: this.attrs.ns
          })
          .then(res => {
            console.log(res);
            if (res.code == 1) {
              this.controlproperty = false;
              this.$message({
                showClose: true,
                message: "操作成功",
                type: "success"
              });
              this.refreshMaterialProperty();
            } else {
              this.$message.warning(res.msg);
            }
          });
      }
    },
    // 编辑自定义属性
    compileaddcroperty() {
      // console.log(this.compileMaterial.customprop);
      // console.log(this.comperty_checkedCities);
      if (this.compileMaterial.customprop.length != 0) {
        if (this.comperty_checkedCities.length == 1) {
          for (const key in this.compileMaterial.customprop) {
            if (
              this.compileMaterial.customprop[key].id ==
              this.comperty_checkedCities[0]
            ) {
              this.compilecustomsx.nr = JSON.parse(
                JSON.stringify(this.compileMaterial.customprop[key])
              );
              this.compiletrolprope = true;
              this.$nextTick(() => {
                //次要代码
                this.$refs.slfs.focus();
              });
            }
          }
        } else {
          this.$message({ message: "请选择一个进行编辑", type: "error" });
        }
      } else {
        this.$message({
          message: "请添加一个自定义属性，选中后在编辑",
          type: "error"
        });
      }
    },
    // 删除编辑自定义属性
    delecpilecuspperty(id, i) {
      console.log(id);
      this.compilecustomsx.nr.ts.splice(i, 1);

      if (id) {
        this.compilecustomsx.delid.push(id);
      }
    },
    // 增加编辑自定义属性
    addcpilecuspperty() {
      this.compilecustomsx.nr.ts.push({
        n: ""
      });
      this.$nextTick(() => {
        //次要代码
        this.$refs.selectsse[this.$refs.selectsse.length - 1].focus();
        console.log(this.$refs.selectsse);
      });
    },
    // 保存编辑自定义属性
    customcompilenature() {
      // console.log(this.comperty_checkedCities);
      this.compilecustomsx.addname = [];
      for (const key in this.compilecustomsx.nr.ts) {
        if (!this.compilecustomsx.nr.ts[key].id) {
          // console.log(this.compilecustomsx.nr.Items[key].n);
          this.compilecustomsx.addname.push(this.compilecustomsx.nr.ts[key].n);
        }
      }
      var s = "";
      this.compilecustomsx.chg = [];
      for (const ke in this.compileMaterial.customprop) {
        if (
          this.comperty_checkedCities[0] ==
          this.compileMaterial.customprop[ke].id
        ) {
          for (const ki in this.compileMaterial.customprop[ke].ts) {
            // console.log(this.compileMaterial.customprop[ke]);
            s = this.compileMaterial.customprop[ke].n;
            for (const key in this.compilecustomsx.nr.ts) {
              // console.log(this.compileMaterial.customprop[ke].Items[ki].n);
              // console.log(this.compilecustomsx.nr.Items[key].n);
              // console.log(this.compilecustomsx.nr.Items[key].n == this.compileMaterial.customprop[ke].Items[ki].n);
              if (
                this.compilecustomsx.nr.ts[key].id ==
                this.compileMaterial.customprop[ke].ts[ki].id
              ) {
                if (
                  this.compilecustomsx.nr.ts[key].n !=
                  this.compileMaterial.customprop[ke].ts[ki].n
                ) {
                  this.compilecustomsx.chg.push({
                    id: this.compilecustomsx.nr.ts[key].id,
                    n: this.compilecustomsx.nr.ts[key].n
                  });
                }
              }
            }
          }
        }
      }
      if (
        this.compilecustomsx.nr.n != s ||
        this.compilecustomsx.delid.length != 0 ||
        this.compilecustomsx.addname.length != 0 ||
        this.compilecustomsx.chg.length != 0
      ) {
        this.$api.ERP.mat
          .requestmatchg_attr({
            id: Number(this.wuliaoid),
            attr_id: this.compilecustomsx.nr.id,
            attr_name: this.compilecustomsx.nr.n,
            del_dtl_items: this.compilecustomsx.delid,
            new_dtl_item_names: this.compilecustomsx.addname,
            chg_dtl_items: this.compilecustomsx.chg
          })
          .then(res => {
            console.log(res);
            if (res.code == 1) {
              this.refreshMaterialProperty();
              this.compiletrolprope = false;
              this.$message({
                showClose: true,
                message: "操作成功",
                type: "success"
              });
              this.comperty_isIndeterminate = false;
              this.comperty_checkAll = false;
              this.comperty_checkedCities = [];
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.compiletrolprope = false;
        this.$message({
          showClose: true,
          message: "操作成功",
          type: "success"
        });
      }
    },
    // 删除自定义属性
    delteperty() {
      this.$api.ERP.mat
        .requestmatrm_attr({
          id: Number(this.wuliaoid),
          attr_ids: this.comperty_checkedCities
        })
        .then(res => {
          console.log(res);
          if (res.code == 1) {
            this.refreshMaterialProperty();
            this.comperty_isIndeterminate = false;
            (this.comperty_checkAll = false),
              (this.comperty_checkedCities = []);
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
          }
        });
    },
    // 关闭编辑弹窗
    gaunbbjym() {
      this.redact = false;
      this.checkAll = false;
      this.checkedCities = [];
      this.isIndeterminate = false;
    },
    //获取焦点
    edit() {
      this.$nextTick(() => {
        //次要代码
        this.$refs.selectsse.focus();
        console.log(this.$refs.selectsse);
      });
    },
    // 滚动最大高度
    RollMaxHeight(i) {
      var s = i - 48 - 60 - 34 - 10;
      this.MaxHeight = s;
    },

    
    showOrHideDetailDialog(){
      this.dialogDelVisible = !this.dialogDelVisible
    },

    async deleteSureHandle(){
      const params = {ids: [this.wuliaoid]}
      try {
        const res = await this.$api.ERP.mat.requestmatdel(params)
        if (res.code == 1) {
          this.$message.success('操作成功')
          this.showOrHideDetailDialog()
          this.gaunbbjym()
          this.nr = ''
          eventVue.$emit('reloadTableData')
        }else if (res.code == 2) {
          this.dialogFible = true;
          this.srnr = "批量删除";
          res.data.ns = res.data.ns || []
          res.data.cs = (res.data.cs || []).map(item => item.r)
          this.cwsm.ns = res.data.ns || []
          this.cwsm.ns = [...res.data.ns, ...res.data.cs]
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('删除员工失败', error)
      }
    },
  
  },
  computed: {
    compileMate() {
      return JSON.parse(JSON.stringify(this.compileMaterial));
    },
    compileMatMatere() {
      return JSON.parse(JSON.stringify(this.compileMaterial.Materialunit));
    },
    addbjpupss() {
      return JSON.parse(JSON.stringify(this.addbjpopup));
    }
  },
  watch: {
    windowHeigh(val) {
      let that = this;
      this.RollMaxHeight(val);
      //   console.log("实时屏幕高度：",val, that.windowHeigh );
    },
    windowWidt(val) {
      let that = this;
      //   console.log("实时屏幕宽度：",val, that.windowWidt );
    },
    // 模糊查询
    nr: {
      deep: true,
      handler: function(after, before) {
        // console.log(after);
        if (this.timer) {
          clearTimeout(this.timer);
        }
        this.timer = setTimeout(() => {
          if (after == "") {
            this.sfshow = true;
          } else {
            this.searchesult = {
              yij: [],
              erj: [],
              wl: [],
              sl: ""
            };
            this.sfshow = false;
            this.$api.ERP.mcate
              .requestmcatesearch({ name: after })
              .then(res => {
                if (res.code == 1) {
                  for (const key in res.data) {
                    if (res.data[key].t == 1) {
                      this.searchesult.yij.push(res.data[key]);
                    } else if (res.data[key].t == 2) {
                      this.searchesult.erj.push(res.data[key]);
                    } else if (res.data[key].t == 3) {
                      this.searchesult.wl.push(res.data[key]);
                    }
                  }
                  this.tjflyj();
                  // console.log(res.data);
                  var s = res.data || [];
                  this.searchesult.sl = s.length;
                } else {
                  this.$message.warning(res.msg);
                }
              });
          }
        }, 500);
      }
    },
    //
    stairNames: {
      deep: true,
      handler: function(after, before) {
        console.log(after);
        this.gaibland = "全部";
        // if(after != ''){
        //     this.gaibland = after
        // }else{
        //     this.gaibland = '全部'
        // }
      }
    },
    secondNames: {
      deep: true,
      handler: function(after, before) {
        // console.log(after);
        if (after != "") {
          this.gaibland = after;
        } else {
          this.gaibland = this.$route.params.id;
        }
      }
    },
    materialNames: {
      deep: true,
      handler: function(after, before) {
        console.log(after);
        if (after != "") {
          this.gaibland = after;
        } else {
          this.gaibland = this.$route.params.id;
        }
      }
    },

    // 编辑 根据商品名称改变拼音 限制价格
    compileMate: {
      deep: true,
      handler: function(after, before) {
        // 根据商品名称改变拼音
        if (after.name != before.name) {
          this.$api.UtilAuth.util
            .requestutilpy({ str: after.name })
            .then(res => {
              this.compileMaterial.phoneticize = res.data || "";
            });
        }
        console.log(after.customprop);
      }
    },
    // 编辑 根据所选单位添加比例
    compileMatMatere: {
      deep: true,
      handler: function(after, before) {
        // console.log(after);

        var reg = /^[0-9]+(\.[0-9]{0,2})?$/;
        for (const key in this.compileMaterial.ListUnits) {
          for (const ke in after) {
            if (after[ke].id == this.compileMaterial.ListUnits[key].id) {
              this.compileMaterial.Materialunit[
                ke
              ].ratio = this.compileMaterial.ListUnits[key].us;
              // console.log(this.compileMaterial.ListUnits[key].ut);
              // console.log(this.compileMaterial.Materialunit[ke]);
              this.compileMaterial.Materialunit[
                ke
              ].ut = this.compileMaterial.ListUnits[key].ut;
            }
            if (after[ke].bp || "" == (before[ke] || {}).bp || "") {
              if (!reg.test(after[ke].bp)) {
                this.compileMaterial.Materialunit[ke].bp =
                  (before[ke] || {}).bp || "";
              }
            }
            if (after[ke].sp || "" == (before[ke] || {}).sp || "") {
              if (!reg.test(after[ke].sp)) {
                this.compileMaterial.Materialunit[ke].sp =
                  (before[ke] || {}).sp || "";
              }
            }
          }
        }
        // console.log(after[0]);
        // console.log(before[0]);
      }
    },
    // 编辑 根据所选单位添加比例 价格只允许输入数字
    addbjpupss: {
      deep: true,
      handler: function(after, before) {
        for (const key in this.compileMaterial.ListUnits) {
          if (after.unitid == this.compileMaterial.ListUnits[key].id) {
            this.addbjpopup.proportion = this.compileMaterial.ListUnits[key].us;
            this.addbjpopup.ut = this.compileMaterial.ListUnits[key].ut;
          }
        }
        // 只让输入数字  限制小数点后有两位就不能输入了
        if (after.purchase) {
          var reg = /^[0-9]+(\.[0-9]{0,2})?$/;
          if (!reg.test(after.purchase)) {
            this.addbjpopup.purchase = before.purchase;
          }
        }
        if (after.market) {
          var reg = /^[0-9]+(\.[0-9]{0,2})?$/;
          if (!reg.test(after.market)) {
            this.addbjpopup.market = before.market;
          }
        }
      }
    }
  }
};
</script>
<style >
.Singless {
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
  color: #08080a;
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
  padding: 0 6px;
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
<style >
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
  color: #8c8c8c;
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
  background-color: #d7e9ff;
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
.el-select__popper.el-popper[role="tooltip"][data-popper-placement^="bottom"]
  .el-popper__arrow::before {
  border: 1px solid #f5f5f5;
  background-color: #f5f5f5;
}
.el-select-dropdown__item.hover,
.el-select-dropdown__item:hover {
  background-color: #e5e5e5;
}
.el-select-dropdown__item.selected {
  color: #40404e;
}
.el-select-dropdown__item {
  color: #40404e;
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
  box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1);
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
  color: #30303e;
}

.Singless .el-dialog {
  background-color: #f9f9f9;
}
.Singless .el-input__inner {
  background-color: transparent;
  color: #40404e;
}

.Singless .el-dialog__title,
.Singless .el-dialog__headerbtn .el-dialog__close,
.Singless .el-form-item__label {
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
  width: 720px;
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
.Singless .dialogPrinter .el-button--mini,
.el-button--small {
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
  font-weight: 400;
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
  color: #409eff;
}
.Singless .dialogPrinter .Mater-unit .lans:hover {
  color: #66b1ff;
}
.Singless .dialogPrinter .Mater-unit .drag-list td:nth-of-type(1),
.Singless .dialogPrinter .Mater-unit .mmodity th:nth-of-type(1) {
  width: 70px;
}
.Singless .dialogPrinter .Mater-unit .drag-list td:nth-of-type(2),
.Singless .dialogPrinter .Mater-unit .mmodity th:nth-of-type(2) {
  width: 200px;
}
.Singless .dialogPrinter .Mater-unit .drag-list td:nth-of-type(3),
.Singless .dialogPrinter .Mater-unit .mmodity th:nth-of-type(3) {
  width: 100px;
}
.Singless .dialogPrinter .Mater-unit .drag-list td:nth-of-type(4),
.Singless .dialogPrinter .Mater-unit .mmodity th:nth-of-type(4) {
  width: 150px;
}
.Singless .dialogPrinter .Mater-unit .drag-list td:nth-of-type(5),
.Singless .dialogPrinter .Mater-unit .mmodity th:nth-of-type(5) {
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
.Singless .dialogPrinter .extend-unit .drag-list td:nth-of-type(1),
.Singless .dialogPrinter .extend-unit .mmodity th:nth-of-type(1) {
  width: 70px;
}
.Singless .dialogPrinter .extend-unit .drag-list td:nth-of-type(2),
.Singless .dialogPrinter .extend-unit .mmodity th:nth-of-type(2) {
  width: 200px;
}
.Singless .dialogPrinter .extend-unit .drag-list td:nth-of-type(3),
.Singless .dialogPrinter .extend-unit .mmodity th:nth-of-type(3) {
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
  /* border: 1px solid #ccc; */
  padding: 10px 0;
  margin-bottom: 10px;
}
.Singless .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(1),
.Singless .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(1) {
  width: 70px;
}
.Singless .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(2),
.Singless .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(2) {
  width: 170px;
}
.Singless .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(3),
.Singless .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(3) {
  width: 70px;
}
.Singless .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(4),
.Singless .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(4) {
  width: 140px;
}
.Singless .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(5),
.Singless .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(5) {
  width: 140px;
}
.Singless .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(6),
.Singless .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(6) {
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
</style>