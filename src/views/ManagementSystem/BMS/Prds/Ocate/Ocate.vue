<template>
    <div class="Ocate">
        <div class="Ocate-controller">
            <icon-button @click.native="VolumeProduction" text="新增一级分类" img="添加.png" colors="#f5f5f5"></icon-button>
            <icon-button @click.native="Ocatecompile" text="编辑" img="编辑.png" colors="#f5f5f5"></icon-button>
            <icon-button @click.native="noneffective" text="置为无效" img="无效.png" colors="#f5f5f5"></icon-button>
            <icon-button @click.native="effective" text="置为有效" img="有效.png" colors="#f5f5f5"></icon-button>
            <icon-button @click.native="DelPayOcate" text="批量删除" img="删除.png" colors="#6B2830"></icon-button>
            <characters-button @click.native="$message.info('上下拖动分类可调整顺序')" colors="#383943" wz='调整顺序'></characters-button>
        </div>
        <!-- 一级分类 -->
        <div class="one-category">
            <div class="zsykd first-cate" >
                <table class="zhuixiaoi">
                    <thead class="mmodity">
                    <tr>
                        <th>
                            <el-checkbox 
                            :indeterminate="isIndeterminate" 
                            v-model="checkAll" 
                            @change="handleCheckAllChange"
                            >行号</el-checkbox>
                        </th>
                        <th style="padding-left:0">一级分类名称</th>
                        <th style="padding-left:0">首选出品库</th>
                        <th style="padding-left:0;width:200px">微信小程序是否可见</th>
                        <th style="padding-left:0">创建时间</th>
                        <th style="padding-left:0;width:140px">更新时间</th>
                        <th style="padding-left:0">状态</th>
                    </tr>
                    </thead>
                    <tbody class="limiting" ref="systemForm" @scroll="sysHandleScroll()" @mouseover="changeFlag(false)"
                           :style="{'border-bottom':List.length<1?'0px':'',
                'width':List.length>MaxNumber?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`}">
                    <tr v-for="(item, i) in List" :key="i" class="drag-list" draggable="true"
                        @dragstart="dragstart(item)" @dragenter="dragenter(item)" @dragend="dragend(item)"
                        :class="checkedCities.includes(item.id)? 'drag-list-check':''" title="拖动可调整顺序">
                        <td style="width:90px" :style="{'color':item.s=='无效'?'#595959':''}">
                            <el-checkbox-group v-model="checkedCities" @change="handleCheckedCitiesChange">
                                <el-checkbox :label="item.id">{{i+1}}</el-checkbox>
                            </el-checkbox-group>
                        </td>
                        <td style="padding-left:0;user-select: text" :style="{'color':item.s=='无效'?'#595959':''}">{{item.n}}</td>
                        <td style="padding-left:0" :style="{'color':item.s=='无效'?'#595959':''}">{{item.fmk}}</td>
                        <td style="padding-left:0;width:200px" :style="{'color':item.s=='无效'?'#595959':''}">{{item.sm}}</td>
                        <td style="padding-left:0" :style="{'color':item.s=='无效'?'#595959':''}">{{item.c}}</td>
                        <td style="padding-left:0;width:140px" :style="{'color':item.s=='无效'?'#595959':''}">{{item.u}}</td>
                        <td style="padding-left:0" :style="{'color':item.s=='无效'?'#595959':''}">{{item.s}}</td>
                    </tr>
                    </tbody>
                </table>
                <div class="drag-list" v-if="List.length<1">
                    <td class="nodata" :style="{'height':`${MaxHeight}px !important`}">
                        <img src="@/assets/img/wu.png" alt="">
                        <div class="hint">暂无数据</div>
                    </td>
                </div>
            </div>
        </div>

        <!-- 商品 -->
        <div class="product-list m-t-6">
          <h3 class="m-b-3">商品列表</h3>
          <div class="zsykd prd-list" >
              <table class="zhuixiaoi">
                  <thead class="mmodity">
                  <tr style="padding-left:10px">
                      <th style="padding-left:0;width:60px">序号</th>
                      <th style="padding-left:0;width:180px">商品名称</th>
                      <th style="padding-left:0;width:80px">商品单价</th>
                      <th style="display:none;padding-left:0;width:80px">商品会员价</th>
                      <th style="padding-left:0;width:80px">商品类型</th>
                      <th style="padding-left:0;width:80px">业务类型</th>
                      <th style="padding-left:0;width:120px">拼音</th>
                      <th style="padding-left:0;width:120px">英文名</th>
                      <th style="padding-left:0;width:80px">状态</th>
                      <th style="padding-left:0;width:160px">创建时间</th>
                      <th style="padding-left:0;width:160px">更新时间</th>
                      <th style="padding-left:0;width:180px">erp商品名称</th>
                      <th style="padding-left:0;width:120px">一级分类名称</th>
                      <th style="padding-left:0;width:120px">二级分类名称</th>
                  </tr>
                  </thead>
                  <tbody class="limiting" :style="{'border-bottom':prdInfo.prdList.length<1?'0px':''}">
                  <tr style="padding-left:10px" v-for="(item, i) in prdInfo.prdList" :key="i" class="drag-list" >
                      <td style="padding-left:0;width:60px" :style="{'color':item.s=='无效'?'#595959':''}">{{i+1}}
                      </td>
                      <td style="padding-left:0;width:180px" :style="{'color':item.s=='无效'?'#595959':''}">{{item.n}}</td>
                      <td style="padding-left:0;width:80px" :style="{'color':item.s=='无效'?'#595959':''}">{{item.p}}</td>
                      <td style="display:none;padding-left:0;width:80px" :style="{'color':item.s=='无效'?'#595959':''}">{{item.mp}}</td>
                      <td style="padding-left:0;width:80px" :style="{'color':item.s=='无效'?'#595959':''}">{{item.pt}}</td>
                      <td style="padding-left:0;width:80px" :style="{'color':item.s=='无效'?'#595959':''}">{{item.bt}}</td>
                      <td style="padding-left:0;width:120px;word-break:break-all" :style="{'color':item.s=='无效'?'#595959':''}">{{item.np}}</td>
                      <td style="padding-left:0;width:120px;word-break:break-all" :style="{'color':item.s=='无效'?'#595959':''}">{{item.ne}}</td>
                      <td style="padding-left:0;width:80px" :style="{'color':item.s=='无效'?'#595959':''}">{{item.s}}</td>
                      <td style="padding-left:0;width:160px" :style="{'color':item.s=='无效'?'#595959':''}">{{item.c}}</td>
                      <td style="padding-left:0;width:160px" :style="{'color':item.s=='无效'?'#595959':''}">{{item.u}}</td>
                      <td style="padding-left:0;width:180px" :style="{'color':item.s=='无效'?'#595959':''}">{{item.en}}</td>
                      <td style="padding-left:0;width:120px" :style="{'color':item.s=='无效'?'#595959':''}">{{item.on}}</td>
                      <td style="padding-left:0;width:120px" :style="{'color':item.s=='无效'?'#595959':''}">{{item.tn}}</td>
                  </tr>
                  </tbody>
              </table>
              <div class="drag-list" v-if="prdInfo.prdList.length<1">
                  <td class="nodata">
                      <img src="@/assets/img/wu.png" alt="">
                      <div class="hint">暂无数据</div>
                  </td>
              </div>
          </div>
          <div class="fr m-t-4">
            <el-pagination
            background
            layout="prev, pager, next"
            @current-change="changePageHandle"
            :page-size="prdInfo.pageSize"
            :total="prdInfo.allSize">
          </el-pagination>
          </div>
            
        </div>
        

        <!-- 新建一级分类 -->
        <div class="Paging" v-show="QuantityProduction">
            <el-dialog title="新建一级分类" :visible.sync="QuantityProduction" :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="compatibil">
                        <div class="compatibility wenzcq">
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>分类名称：
                            </div>
                            <el-input v-model="Ocate.name" placeholder="请填分类名称" ref="selectsse"
                                      show-word-limit class="controlling"
                                      :class="form_rule_msg_name?'error':''" @blur="validator('name')"/>
                            <div class="cwts">{{form_rule_msg_name}}</div>
                        </div>
                    </div>
                    <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>首选出品库：
                            </div>
                            <el-select v-model="Ocate.Productlibrary" placeholder="请选择出品库" class="controlling">
                                <el-option v-for="(each,i) in mklibs" :key="i" :label="each.n"
                                           :value="each.id"></el-option>
                                <!-- <el-option label="--新增出品库--" value="新增1"></el-option> -->
                            </el-select>
                        </div>
                    </div>
                     <div class="compatibil">
                        <div class="compatibility wenzcq">
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>微信小程序可见：
                            </div>
                            <el-radio v-model="isShowRadio" label="1">可见</el-radio>
                            <el-radio v-model="isShowRadio" label="2">不可见</el-radio>
                        </div>
                    </div>
                </el-form>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="QuantityProduction = false">取消</el-button>
                    <el-button type="primary" @click="construction">新建</el-button>
                </span>
            </el-dialog>
        </div>
        <!-- 编辑一级分类 -->
        <div class="Paging" v-show="QuantityProductions">
            <el-dialog title="编辑一级分类" :visible.sync="QuantityProductions" :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="compatibil">
                        <div class="compatibility wenzcq">
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>分类名称：
                            </div>
                            <el-input v-model="Ocate.name" placeholder="请填分类名称" ref="selectsse"
                                      show-word-limit class="controlling"
                                      :class="form_rule_msg_name?'error':''" @blur="validator('name')"/>
                            <div class="cwts">{{form_rule_msg_name}}</div>
                        </div>
                    </div>
                    <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>首选出品库：
                            </div>
                            <el-select v-model="Ocate.Productlibrary" placeholder="请选择出品库" class="controlling">
                                <el-option v-for="(each,i) in mklibs" :key="i" :label="each.n"
                                           :value="each.id"></el-option>
                                <!-- <el-option label="--新增出品库--" value="新增1"></el-option> -->
                            </el-select>
                        </div>
                    </div>
                     <div class="compatibil">
                        <div class="compatibility wenzcq">
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>微信小程序可见：
                            </div>
                            <el-radio v-model="isShowRadio" label="1">可见</el-radio>
                            <el-radio v-model="isShowRadio" label="2">不可见</el-radio>
                        </div>
                    </div>
                </el-form>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="QuantityProductions = false">取消</el-button>
                    <el-button type="primary" @click="saveprinter">保存</el-button>
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
import EllipsisTooltip from '@/components/EllipsisTooltip.vue'//根据路径导入组件
import IconButton from '@/components/IconButton.vue'//根据路径导入组件
import CharactersButton from '@/components/CharactersButton.vue'//根据路径导入组件
import {mapMutations, mapState} from "vuex"
import eventVue from '@/utils/eventVue';

export default {
  data() {
    return {
      List: [],//全部内容
      oldItem: '',//记录初始信息
      newItem: '',// 记录过程中信息
      checkAll: false,//全部选中触发
      checkedCities: [],//已选择内容
      isIndeterminate: false,//全选或者全不选
      QuantityProduction: false,//控制新增的打开关闭
      QuantityProductions: false,//控制编辑的打开关闭
      Ocate: {
        name: '',//名字
        // type:'1',//类型
        Productlibrary: '',//出品库
        // divideinto:false,//分成结账
        Product: true,//控制出品库展示是否
      },//一级分类
      isShowRadio: "1", // 微信小程序是否可点
      mklibs: [],// 出品库

      LnvalidGoodsList: {},// 有效套餐使用到了置无效一级分类下的商品 显示列表

      disacheckAll: false,//全部选中触发
      disaCities: [],//已选择内容
      disarminate: false,//全选或者全不选
      whetherbenull: true,// 判断列表是否为空

      resnr: {},//错误内容
      windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
      MaxHeight: 0,//滚动高度
      MaxNumber: 0,//最大个数

      dialogFible: false,//控制错误2是否显示
      srnr: '',//文案
      cwsm: {
        ns: [],//不可操作列表
        cs: [],//可一键操作列表
      },//错误2说明
      kzsfjy: false,//控制同步按钮是否禁用

      form_rules: ["name"],
      form_rule_msg_name: "",

      flag: false,


      // 商品列表
      prdInfo: {
        prdList: [],
        page: 1,
        pageSize: 20,
        allSize: 0
      }
    }
  },
  components: {
    EllipsisTooltip,
    IconButton,
    CharactersButton,
  },
  mounted(){
    this.demand();
    this.getPrdList();
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
  methods: {
    ...mapMutations(["OcateValuation"]),
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
          if (this.Ocate.name == '') {
            this.form_rule_msg_name = '请输入分类名称'
          } else if (this.$overall.character(this.Ocate.name) > 10) {
            this.form_rule_msg_name = '输入文字长度超过5'
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
    // 请求数据
    demand(){
      this.$api.BMS.ocate.requestocatelist().then(res => {
        console.log(res.data);
        if (res.code == 1) {
          this.List = res.data || []
          this.checkAll = false
          this.checkedCities = []
          this.isIndeterminate = false
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 记录初始信息
    dragstart(item) {
      this.oldItem = item;
    },
    // 记录过程中信息
    dragenter(item) {
      this.newItem = item;
    },
    // 做最终操作
    dragend(item) {
      if (this.oldItem != this.newItem) {
        let oldIndex = this.List.indexOf(this.oldItem);
        let newIndex = this.List.indexOf(this.newItem);
        var down_up = 1;
        if (oldIndex > newIndex) {
          down_up = 2
        } else if (oldIndex < newIndex) {
          down_up = 1
        }
        this.$api.BMS.ocate.requestocatemove_dsp({
          id: this.oldItem.id,
          dest_id: this.newItem.id,
          down_up: down_up
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.$message({showClose: true, message: "更改位置成功", type: 'success', duration: 1000})
            let newList = [...this.List]; // 中间数组，用于交换两个节点
            // 删除老的节点
            newList.splice(oldIndex, 1);
            // 在列表目标位置增加新的节点
            newList.splice(newIndex, 0, this.oldItem);
            // 更新this.List，触发transition-group的动画效果
            this.List = [...newList];
              eventVue.$emit('reloadCategoryList')
          } else {
            this.$message.warning(res.msg)
          }
        })
      }
    },
    // 控制全选或者全不选
    handleCheckAllChange(val) {
      if (val) {
        this.checkedCities = []
        for (const key in this.List) {
          this.checkedCities.push(this.List[key].id)
        }
      } else {
        this.checkedCities = []
      }
      this.isIndeterminate = false;
    },
    // 控制单个选中
    handleCheckedCitiesChange(value) {
      let checkedCount = value.length;
      this.checkAll = checkedCount === this.List.length;
      this.isIndeterminate = checkedCount > 0 && checkedCount < this.List.length;
    },
    // 控制新建一级分类显示是否 加载出品库
    VolumeProduction(){
      this.form_rule_msg_name = "";
      this.QuantityProduction = true
      console.log(this.mklibs);

      this.$api.BMS.ocate.requestocateget({id: 0}).then(res => {
        console.log(res);
        this.mklibs = res.data.mklibs || []

        this.Ocate.name = ''
        this.Ocate.Productlibrary = ''
      })
    },
    // 新建一级分类
    construction(){
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_name) return;
      this.$api.BMS.ocate.requestocatenew({
        name: this.Ocate.name,
        // prd_type:parseInt(this.Ocate.type),
        first_mklib_id: this.Ocate.Productlibrary,
        // is_fc:parseInt(this.Ocate.divideinto?1:2),
        show_in_mp: this.isShowRadio * 1 //  int    小程序可见,1 可见, 2 不可见
      }).then(res => {
        if (res.code == 1 || res.code == 6) {
          if(res.msg === '') {
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
          this.QuantityProduction = false
          this.demand()
          this.$root.$emit('next') //调用父路由中刷新菜单
          
          eventVue.$emit('reloadCategoryList')
          this.isShowRadio = '1'
          this.Ocate = {
            name: '',//名字
            // type:'1',//类型
            Productlibrary: '',//出品库
            // divideinto:false,//分成结账
            // Product:true,//控制出品库展示是否
          }//一级分类
        } else if (res.code == -20001) {
          this.$message.warning('套餐分类不支持指定分成结账方式')
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 打开编辑一级分类
    Ocatecompile(){
      this.form_rule_msg_name = "";
      if (this.checkedCities.length == 1) {
        this.$api.BMS.ocate.requestocateget({id: this.checkedCities[0]}).then(res => {
          this.mklibs = res.data.mklibs || []
          this.Ocate.name = res.data.prd_one_cate.name
          this.Ocate.Productlibrary = res.data.prd_one_cate.first_mklib_id
          this.QuantityProductions = true
          this.isShowRadio = res.data.prd_one_cate.show_in_mp + ''
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
      this.$api.BMS.ocate.requestocatesave({
        id: this.checkedCities[0],
        name: this.Ocate.name,
        first_mklib_id: this.Ocate.Productlibrary,
        show_in_mp: this.isShowRadio * 1 //  int    小程序可见,1 可见, 2 不可见
        // is_fc:parseInt(this.Ocate.divideinto?1:2),
      }).then(res => {
        if (res.code == 1) {
          this.$message({
            showClose: true,
            message: "保存成功",
            type: 'success'
          })
          this.demand()
          this.$root.$emit('next') //调用父路由中刷新菜单
          eventVue.$emit('reloadCategoryList')
          this.isShowRadio = '1'
          this.Ocate = {
            name: '',//名字
            Productlibrary: '',//出品库
          }//一级分类
          this.QuantityProductions = false
        } else {
          this.$message({message: res.msg, type: 'warning',})
        }
      })
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
      this.$api.BMS.ocate.requestocateob({
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
      if (this.checkedCities.length > 0) {
        this.$api.BMS.ocate.requestocatedisable({
          ids: this.checkedCities
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            if (res.code == 1) {
              this.demand()
              this.checkedCities = []
              this.isIndeterminate = false
              this.checkAll = false
              this.dialogFible = false
              this.$message({
                showClose: true,
                message: "更改状态成功",
                type: 'success'
              })
              eventVue.$emit('reloadCategoryList')
            } else {
              this.$message({message: res.msg, type: 'warning',})
            }
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
        this.$message({
          message: '请选择一个进行更改状态',
          type: 'warning',
        })
      }
    },
    // 控制全选或者全不选
    disaCheckAllChange(val) {
      if (val) {
        this.disaCities = []
        for (const key in this.LnvalidGoodsList.data) {
          this.disaCities.push(this.LnvalidGoodsList.data[key].sid)
        }
      } else {
        this.disaCities = []
      }
      console.log(this.disaCities);
      this.disarminate = false;
    },
    // 控制单个选中
    disaCCheckedCitiesChange(value) {
      console.log(value);
      let checkedCount = value.length;
      this.disacheckAll = checkedCount === this.LnvalidGoodsList.data.length;
      this.disarminate = checkedCount > 0 && checkedCount < this.LnvalidGoodsList.data.length;
    },
    // 套餐置为无效
    constraint(){
      this.$api.BMS.Prd.requestprddisable({
        ids: this.disaCities
      }).then(res => {
        console.log(res);
        if (res.code == 1) {
          var arr = []
          for (const key in this.disaCities) {
            for (const ite of this.LnvalidGoodsList.data) {
              if (this.disaCities[key] == ite.sid) {
                arr.push(key)
              }
            }
          }
          var max;
          for (var i = 0; i < arr.length; i++) {
            for (var j = i; j < arr.length; j++) {
              if (arr[i] < arr[j]) {
                max = arr[j];
                arr[j] = arr[i];
                arr[i] = max;
              }
            }
          }
          for (const key of arr) {
            this.LnvalidGoodsList.data.splice(key, 1)
          }
          this.disaCities = []
          this.disacheckAll = false
          this.disarminate = false
          this.$message({
            showClose: true,
            message: "操作成功",
            type: 'success'
          })
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 有效
    effective(){
      if (this.checkedCities.length > 0) {
        this.$api.BMS.ocate.requestocateenable({
          ids: this.checkedCities,
        }).then(res => {
          if (res.code == 1) {
            this.demand()
            this.checkedCities = []
            this.isIndeterminate = false
            this.checkAll = false
            this.dialogFible = false
            this.$message({
              showClose: true,
              message: "更改状态成功",
              type: 'success'
            })
            eventVue.$emit('reloadCategoryList')
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
        this.$message({
          message: '请选择一个进行更改状态',
          type: 'warning',
        })
      }
    },
    // 删除一级分类
    DelPayOcate(){
      this.$api.BMS.ocate.requestocatedel({ids: this.checkedCities}).then(res => {
        console.log(res);

        if (res.code == 1) {
          this.demand()
          this.isIndeterminate = false
          this.dialogFible = false

          this.$message({
            showClose: true,
            message: "删除成功",
            type: 'success'
          })
          eventVue.$emit('reloadCategoryList')
        } else if (res.code == 2) {
          this.dialogFible = true
          this.kzsfjy = false
          this.srnr = '批量删除'
          this.cwsm.ns = res.data.ns || []
          for (const key in res.data.cs) {
            res.data.cs[key].jg = '---'
          }
          this.cwsm.cs = res.data.cs || []
        } else if (res.code == 500) {
          this.$message.warning('服务器异常，请稍后在试')
        } else {
          this.$message.warning(res.msg)
        }
      })
    },


    /*
        商品列表
    */ 
   async getPrdList(){
    const params = {
      page_num: this.prdInfo.page * 1, //   int  指定第几页
      page_size: this.prdInfo.pageSize, //  int  每页行数
    }

    try {
      const res = await this.$api.BMS.ocate.reqGetPrdList(params);
      console.log(res)
      if(res.code == 1){
        this.prdInfo.prdList = res.data.records || [];
        this.prdInfo.page = res.data.page_num || 1;
        this.prdInfo.allSize = res.data.row_cnt;
      } else {
        this.$message.warning(res.msg);
      }
    } catch (error) {
      console.log('获取商品列表失败', error)
    }
   },

    changePageHandle(page){
      this.prdInfo.page = page;
      this.getPrdList();
    }

  },
  computed: {
    setmea(){
      return JSON.parse(JSON.stringify(this.LnvalidGoodsList))
    },

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
    setmea: {
      deep: true,
      handler: function (after, before) {
        if (after.data.length < 1) {
          this.whetherbenull = false
        } else {
          this.whetherbenull = true
        }
      }
    },
  }

}
</script>
<style>
    /* 靠右 */
    .Ocate .el-dialog {
        margin: 0px 0px 0px auto !important;
        background-color: #f9f9f9;
        height: 100%;
        position: relative;
    }

    .Ocate .el-dialog__footer {
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }

    .Ocate .el-dialog__body {
        padding: 0px 0px 30px 20px;
        overflow-y: scroll !important;
        /* width: 100%; */
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;
    }

    .Ocate .el-dialog {
        border-left: 1px solid #f9f9f9;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .Ocate {
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding: 20px 30px;
    }

    /* 必填 */
    .Ocate .mandatory {
        color: #40404E;
        width: 140px;
        text-align: right;
    }

    .Ocate .controlling {
        color: #40404E;
        width: 230px !important;
    }

    .Ocate .reqfieldsd {
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
    .Ocate .tiaodd {
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

    .Ocate .nodata {
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        padding: 0;
    }

    .Ocate .nodata img {
        width: 60px;
        height: 60px;
    }

    .Ocate .nodata .hint {
        line-height: 36px;
        font-size: 13px !important;
    }

    /* 改变多选框背景颜色和上下间距 */
    .Ocate .el-checkbox-group {
        display: flex;
        align-items: flex-end;
        justify-content: left;
    }

    .Ocate .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    /* 全选颜色 */
    .Ocate .zhuixiaoi .el-checkbox__label {
        color: #40404E;
    }

    .Ocate .zhuixiaoi .mmodity .el-checkbox__label {
        font-size: 12px;
    }

    /* 改变多选框背景颜色和上下间距 */
    .Ocate .el-checkbox-group {
        display: flex;
        align-items: flex-end;
        justify-content: left;
    }

    .Ocate .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }


    .Ocate .zhuixiaoi {
        width: 1600px;
        overflow: scroll !important;
        border-collapse: collapse;
        color: #1A1A21;
    }

    .Ocate .zhuixiaoi .mmodity{
      position: sticky;
      top: 0;
      background-color: #f5f5f5;
      z-index: 10;
    }

    .Ocate .zhuixiaoi .mmodity tr th {
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-size: 14px;
        font-weight: 400;
        padding-left: 20px;
        font-weight: 600;
        color: #1A1A21;
    }

    .Ocate .zhuixiaoi .mmodity tr th:nth-of-type(1) {
        /*border-left: solid 1px #f5f5f5;*/
    }

    .Ocate .zhuixiaoi .limiting .drag-list td {
        min-height: 36px;
        padding: 4px 0;
        box-sizing: border-box;
        /* line-height: 36px; */
        text-align: left;
        font-size: 14px;
        font-weight: 400;
        padding-left: 20px;
    }

    .Ocate .zhuixiaoi .limiting .drag-list td:nth-of-type(1) {
        /*border-left: solid 1px #f5f5f5;*/
    }

    .Ocate .zhuixiaoi .limiting .drag-list {
        display: block;
        display: flex;
    }

    .Ocate .zhuixiaoi .mmodity {
        width: 100%;
        display: block;
    }

    .Ocate .zhuixiaoi .mmodity tr {
        background-color: #f5f5f5;
        display: flex;
    }

    .Ocate .zhuixiaoi .drag-list td:nth-of-type(1), .Ocate .zhuixiaoi .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .Ocate .zhuixiaoi .mmodity th:nth-of-type(2), .Ocate .zhuixiaoi .drag-list td:nth-of-type(2) {
        width: 240px;
    }

    .Ocate .zhuixiaoi .drag-list td:nth-of-type(3), .Ocate .zhuixiaoi .mmodity th:nth-of-type(3) {
        width: 140px;
    }

    .Ocate .zhuixiaoi .drag-list td:nth-of-type(4), .Ocate .zhuixiaoi .mmodity th:nth-of-type(4) {
        width: 140px;
    }

    .Ocate .zhuixiaoi .drag-list td:nth-of-type(5), .Ocate .zhuixiaoi .mmodity th:nth-of-type(5) {
        width: 140px;
    }

    .Ocate .zhuixiaoi .drag-list td:nth-of-type(6), .Ocate .zhuixiaoi .mmodity th:nth-of-type(6) {
        width: 60px;
    }

    .Ocate .zhuixiaoi .drag-list:nth-of-type(odd) {
        background-color: #f9f9f9;
        color: #40404E;
    }

    .Ocate .zhuixiaoi .drag-list:nth-of-type(even) {
        background-color: #f5f5f5;
        color: #40404E;
    }

    /* 全选颜色 */
    .Ocate .zhuixiaoi .el-checkbox__label {
        color: #40404E;
    }

    .Ocate .zhuixiaoi .mmodity .el-checkbox__label {
        font-size: 14px;
        font-weight: 600;
        color: #1a1a21;
    }

    .Ocate .listpage {
        border-collapse: collapse;
        border: solid 1px #f5f5f5;
        color: #40404E;
        width: 100%;
        max-height: 430px !important;
        overflow: auto !important;
        display: inline-block;
    }

    .Ocate .listpage, .Ocate .listpage thead, .Ocate .listpage tr {
        width: 100%;
        display: inline-block;
    }

    .Ocate .listpage thead tr th:nth-of-type(1) {
        width: 120px;
    }

    .Ocate .listpage thead tr th:nth-of-type(2) {
        width: 280px;
    }

    .Ocate .listpage tbody tr td:nth-of-type(1) {
        width: 120px;
    }

    .Ocate .listpage tbody tr td:nth-of-type(2) {
        width: 280px;
    }

    .Ocate .listpage thead tr th, .Ocate .listpage tbody tr td {
        /* width: 50%; */
        height: 40px;
        line-height: 40px;
        font-size: 14px;
        text-align: center;
        border: solid 1px #f5f5f5;

    }

    .Ocate-headline {
        font-size: 30px;
        font-weight: bold;
        color: #40404E;
    }

    .check {
        color: #ce4153;
        margin-bottom: 10px;
        font-size: 15px;
    }

    .Pagingll {
        display: flex;
        justify-content: center;
        height: 50vh;
        overflow: auto;
        min-height: 410px !important;
    }

    .Ocate-controller {
        /*margin-top: 30px;*/
        height: 54px;
        /* width: 1600px; */
        background-color: #EEE;
        display: flex;
        align-items: center;
    }

    .Ocate table thead tr th, .Ocate table tbody tr td {
        font-size: 14px;
    }

    /* 更改按钮字体大小 */
    .Ocate .el-button {
        font-size: 14px;
    }

    /* 改限制字体数量的颜色背景 */
    .Ocate .el-input .el-input__count .el-input__count-inner {
        background: none;
        color: #40404E;
    }

    .Ocate .List-move {
        transition: transform 0.2s;
    }

    /* 分页预览 */
    .Ocate .preview {
        color: rgb(19, 169, 233);
        font-size: 14px;
        margin-left: 70px;
    }

    .Ocate .Pagingss .el-dialog {
        margin-top: 6vh;
        margin-bottom: 0;
        width: 60vw !important;
        min-width: 840px !important;
        max-width: 900px !important;
    }

    .Ocate .Pagingss .el-dialog__body {
        padding: 10px 20px;
    }

    .Ocate .Pagingss .el-dialog__footer {
        padding-bottom: 10px;
    }

    .Ocate .Pagingss .el-dialog__header {
        padding-top: 10px;
    }

    .Ocate .Pagingll {
        color: rgb(226, 226, 226);
        display: flex;
        justify-content: space-evenly;
    }

    .Ocate .NoPaging {
        /* font-size: 1px; */
        margin: 10px;
    }

    .Ocate .headline {
        text-align: center;
        margin-bottom: 10px;
    }

    .Ocate .content {
        width: 350px;
        border: 1px solid rgb(226, 226, 226);
        padding: 10px 8px;
        margin-bottom: 20px;
    }

    .Ocate .appearancefee {
        padding-bottom: 7px;
        border-bottom: 1px dashed rgb(226, 226, 226);
    }

    .Ocate .appearancefee div:nth-of-type(2) {
        font-size: 22px;
        padding: 5px 0;
        font-weight: 900;
    }

    .Ocate .cuisine {
        padding: 7px;
        border-bottom: 1px dashed rgb(226, 226, 226);
    }

    .Ocate .cuisine div:nth-of-type(1) {
        font-size: 20px;
        padding: 5px 0;
        font-weight: 600;
    }

    .Ocate .totalmoney div:nth-of-type(1) {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin: 7px 0;
    }

    /* 控制弹窗的最大最小值 */
    .Ocate .dialogPrinter .el-dialog {
        width: 50vw !important;
        min-width: 470px !important;
        max-width: 580px !important;
    }

    .Ocate .dialogFormVisible .el-dialog {
        width: 50vw !important;
        min-width: 420px !important;
        max-width: 580px !important;
    }

    .Ocate .Paging .el-dialog {
        width: 33vw !important;
        min-width: 540px !important;
        max-width: 600px !important;
    }

    .Ocate .Paging .el-form-item__content {
        width: 100%;
    }

    .Ocate .disable .el-dialog {
        width: 30vw !important;
        min-width: 490px !important;
        max-width: 530px !important;
    }

    /*  */
    .Ocate .required {
        width: 60px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .Ocate .compatibility {
        display: flex;
        align-items: center;
        margin-bottom: 5px;
    }

    .Ocate .compatibil {
        margin-bottom: 10px;
    }

    .Ocate .layouts {
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .Ocate .el-dialog .el-button--default {
        background-color: #ccc;
        border: 1px solid #ccc;
        color: #40404e;
    }

    .Ocate .el-dialog {
        background-color: #f9f9f9 !important;
    }

    .Ocate .el-input__inner {
        background-color: transparent;
        color: #40404E;
    }

    .Ocate .el-dialog__header, .el-dialog__footer {
        background-color: #22232B;
    }

    .Ocate .el-dialog__title, .Ocate .el-dialog__headerbtn .el-dialog__close, .Ocate .el-form-item__label {
        color: #1a1a21;
    }

    .Ocate .el-form-item {
        display: flex;
        margin: 0;
    }

    .Ocate .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    .Ocate .el-dialog {
        width: 30vw;
    }

    .Ocate .has-gutter {
        border: 1px solid #f5f5f5;
    }

    .Ocate .el-input-number__decrease, .Ocate .el-input-number__increase {
        background-color: rgba(0, 0, 0, 0);
    }

    .Ocate .el-radio__label {
        color: #40404E;
    }
</style>
<style>

    /* 下拉框 */
    .el-select-dropdown__wrap {
        background-color: #f5f5f5;
    }

    .el-select-dropdown__empty {
        background-color: #f5f5f5;
        color: #40404E;
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
        color: #40404E;
    }

    .el-select-dropdown__item {
        color: #40404E
    }

    .el-select-dropdown {
        border: 1px solid #f5f5f5;
    }

    /* 改限制字体数量的颜色背景 */
    .Ocate .wenzcq .el-input .el-input__count .el-input__count-inner {
        background: none;
        color: #40404E;
    }

    /* 文字位置 */
    .Ocate .wenzcq .el-input__suffix {
        background-color: #1A1A20;
        color: #40404E;
        right: -45px;
        top: 8px;
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }
</style>
<style>
    /* 列表 */
    .Ocate .zhuixiaois {
        /* width:1400px; */
        border-collapse: collapse;
        color: #40404E;
    }

    .Ocate .zhuixiaois .mmodity tr th {
        height: 40px;
        line-height: 40px;
        text-align: center;
        border-right: solid 1px #f5f5f5;
        border-top: solid 1px #f5f5f5;
        border-bottom: solid 1px #f5f5f5;
        background-color: #2d2e38;
        font-size: 14px;
        font-weight: 400;
    }

    .Ocate .zhuixiaois .mmodity tr th:nth-of-type(1) {
        border-left: solid 1px #f5f5f5;
    }

    .Ocate .zhuixiaois .limiting .drag-list td {
        /* height: 40px; */
        line-height: 40px;
        text-align: center;
        border-right: solid 1px #f5f5f5;
        border-bottom: solid 1px #f5f5f5;
        /* border-top: solid 1px #f5f5f5; */
        font-size: 14px;
        font-weight: 400;
    }

    .Ocate .zhuixiaois .limiting .drag-list td:nth-of-type(1) {
        border-left: solid 1px #f5f5f5;
    }

    .Ocate .zhuixiaois .limiting .drag-list {
        display: block;
        display: flex;
    }

    .Ocate .zhuixiaois .mmodity {
        width: 100%;
        display: block;
    }

    .Ocate .zhuixiaois .mmodity tr {
        display: flex;
    }

    .Ocate .zhuixiaois .limiting {
        overflow-y: auto !important;
        max-height: 520px !important;
        border-bottom: solid 1px #f5f5f5;
        display: block;
    }

    /* 套餐单品问题区域 */
    .Ocate .Seternewdefed .el-dialog {
        width: 930px !important;
    }

    .Ocate .Seternewdefed .ewdefed {
        color: #40404E;
        font-size: 20px;
        margin: 20px 0 10px 00px;
        line-height: 30px;
    }

    .Ocate .Seternewdefed .zhuixiaois {
        min-width: 602px !important;
        display: inline-block;
    }

    .Ocate .Seternewdefed .divbigesd {
        display: flex;
        flex-direction: column;
    }

    .Ocate .Seternewdefed .divbigesd .data {
        height: 30px;
        line-height: 30px;
    }

    .Ocate .Seternewdefed .divbigesd .xian {
        height: 1px;
        background-color: #f5f5f5;
    }

    .Ocate .Seternewdefed .zhuixiaois .drag-list td {
        line-height: 30px;
        display: flex;
        flex-direction: column;
        justify-content: center;
    }

    .Ocate .Seternewdefed .zhuixiaois .drag-list td .xian {
        border-top: solid 1px #f5f5f5;
    }

    .Ocate .Seternewdefed .zhuixiaois .drag-list td .xian:nth-of-type(1) {
        border-top: solid 0px #f5f5f5;
    }

    .Ocate .Seternewdefed .zhuixiaois .drag-list td:nth-of-type(1), .Ocate .Seternewdefed .zhuixiaois .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .Ocate .Seternewdefed .zhuixiaois .drag-list td:nth-of-type(2), .Ocate .Seternewdefed .zhuixiaois .mmodity th:nth-of-type(2) {
        width: 200px;
    }

    .Ocate .Seternewdefed .zhuixiaois .drag-list td:nth-of-type(3), .Ocate .Seternewdefed .zhuixiaois .mmodity th:nth-of-type(3) {
        width: 200px;
    }

    .Ocate .Seternewdefed .zhuixiaois .drag-list td:nth-of-type(4), .Ocate .Seternewdefed .zhuixiaois .mmodity th:nth-of-type(4) {
        width: 200px;
    }

    .Ocate .Seternewdefed .zhuixiaois .drag-list td:nth-of-type(5), .Ocate .Seternewdefed .zhuixiaois .mmodity th:nth-of-type(5) {
        width: 200px;
    }

    /* 无效错误 */
    .Ocate .invaliddefed .el-dialog {
        width: 1130px !important;
    }

    .Ocate .invaliddefed .ewdefed {
        color: #40404E;
        font-size: 20px;
        margin: 20px 0 10px 00px;
        line-height: 30px;
    }

    .Ocate .invaliddefed .zhuixiaois {
        min-width: 602px !important;
        display: inline-block;
    }

    .Ocate .invaliddefed .divbigesd {
        display: flex;
        flex-direction: column;
    }

    .Ocate .invaliddefed .divbigesd .data {
        height: 30px;
        line-height: 30px;
    }

    .Ocate .invaliddefed .divbigesd .xian {
        height: 1px;
        background-color: #f5f5f5;
    }

    /* 错误3 */
    .Ocate .invaliddefed .three .zhuixiaois .drag-list td:nth-of-type(1), .Ocate .invaliddefed .three .zhuixiaois .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .Ocate .invaliddefed .three .zhuixiaois .drag-list td:nth-of-type(2), .Ocate .invaliddefed .three .zhuixiaois .mmodity th:nth-of-type(2) {
        width: 200px;
    }

    .Ocate .invaliddefed .three .zhuixiaois .drag-list td:nth-of-type(3), .Ocate .invaliddefed .three .zhuixiaois .mmodity th:nth-of-type(3) {
        width: 200px;
    }

    .Ocate .invaliddefed .three .zhuixiaois .drag-list td:nth-of-type(4), .Ocate .invaliddefed .three .zhuixiaois .mmodity th:nth-of-type(4) {
        width: 200px;
    }

    .Ocate .invaliddefed .three .zhuixiaois .drag-list td:nth-of-type(5), .Ocate .invaliddefed .three .zhuixiaois .mmodity th:nth-of-type(5) {
        width: 200px;
    }

    .Ocate .invaliddefed .three .zhuixiaois .drag-list td:nth-of-type(6), .Ocate .invaliddefed .three .zhuixiaois .mmodity th:nth-of-type(6) {
        width: 200px;
    }

    /* 错误4 */
    .Ocate .invaliddefed .four .zhuixiaois .drag-list td:nth-of-type(1), .Ocate .invaliddefed .four .zhuixiaois .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .Ocate .invaliddefed .four .zhuixiaois .drag-list td:nth-of-type(2), .Ocate .invaliddefed .four .zhuixiaois .mmodity th:nth-of-type(2) {
        width: 250px;
    }

    .Ocate .invaliddefed .four .zhuixiaois .drag-list td:nth-of-type(3), .Ocate .invaliddefed .four .zhuixiaois .mmodity th:nth-of-type(3) {
        width: 250px;
    }

    .Ocate .invaliddefed .four .zhuixiaois .drag-list td:nth-of-type(4), .Ocate .invaliddefed .four .zhuixiaois .mmodity th:nth-of-type(4) {
        width: 250px;
    }

    .Ocate .invaliddefed .four .zhuixiaois .drag-list td:nth-of-type(5), .Ocate .invaliddefed .four .zhuixiaois .mmodity th:nth-of-type(5) {
        width: 250px;
    }

    /* 错误2 */
    .Ocate .diagrgeesfelogFor .el-dialog {
        width: 720px;
        border-left: 1px solid #f5f5f5;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.5)
    }

    .Ocate .diagrgeesfelogFor .wwent {
        color: #ce4153;
        font-size: 14px;
        margin: 20px 0px 20px 20px;
        display: flex;
        align-items: center;
    }

    .Ocate .diagrgeesfelogFor .wentlb {
        margin-left: 20px;
        width: 640px;
    }

    .Ocate .diagrgeesfelogFor .zhuixiaoi {
        width: 100%;
    }

    .Ocate .diagrgeesfelogFor .zhuixiaoi .limiting {
        max-height: 280px !important;
        overflow-y: auto !important;
    }

    .Ocate .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(1), .Ocate .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(1) {
        width: 50px;
    }

    .Ocate .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(2), .Ocate .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(2) {
        width: 320px;
    }

    .Ocate .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(3), .Ocate .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(3) {
        width: 200px;
    }

    .Ocate .diagrgeesfelogFor .danykz .mmodity th:nth-of-type(2), .Ocate .diagrgeesfelogFor .danykz .drag-list td:nth-of-type(2) {
        width: 520px;
    }

    /* 无效颜色 */
    .Ocate .diagrgeesfelogFor .el-button--primary.is-disabled, .Ocate .diagrgeesfelogFor .el-button--primary.is-disabled:hover {
        background-color: #1F2846;
        color: #4e505a;
        border-color: #1F2846;
    }

    .drag-list-check {
        /* background: rgba(39, 52, 82, .5) !important; */
    }
</style>

<style scoped lang="less">

    /* 列表 */
    .zsykd {
        width: 100%;
        position: relative;
        &.first-cate{
          height: calc(30vh - 140px);
          min-height: 100px;
        }
        &.prd-list{
          height: calc(70vh - 160px);
          min-width: 100px;
        }
    }
</style>

