<template>
    <div class="pgrp">
        <div class="pgrp-controller">
            <icon-button @click.native="xingh" text="新增商品组" img="btn_add.png" colors="#383943"></icon-button>
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
                        <th>商品组名称</th>
                        <th>二级分类数量</th>
                        <th>商品数量</th>
                        <th>创建时间</th>
                        <th>更新时间</th>
                        <th>状态</th>
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
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.cc || '---'}}</td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.pc || '---'}}</td>
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
            <div style="display: inline-block;position: absolute;top: 0;left: 0;z-index: 100">
                <table class="zhuixiaoi zhuixiaoi_l" style="width: auto">
                    <thead class="mmodity">
                    <tr>
                        <th>
                            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll"
                                         @change="handleCheckAllChange">
                                全选&ensp;
                            </el-checkbox>
                        </th>
                        <th>商品组名称</th>
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
        <!-- :title="title?'新增区域':'编辑区域' -->
        <div v-show="dialogFormVisible" class="dialogFormVisible">
            <el-dialog :title="title?'新增商品组':'编辑商品组'" @close="dialogFormVisible = false"
                       :visible.sync="dialogFormVisible" :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>商品组名称：
                        </div>
                        <el-input v-model="pgrp.Name" placeholder="请输入商品组名称" ref="selectsse" class="controlling"
                                  :class="form_rule_msg_name?'error':''" @blur="validator('name')"/>
                        <div class="cwts">{{form_rule_msg_name}}</div>
                    </div>
                    <div class="dotwire"></div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span><span class="magnify">包含</span>二级分类：
                        </div>
                        <!-- <div class="controlling">
                            <el-tree
                              node-key="id"
                              :data="Commodimessage"
                              show-checkbox
                              :props="defaultProps"
                              @check="handleBucketClick"
                              >
                            </el-tree>
                        </div>     -->
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>
                        </div>
                        <div class="controlling">
                            <el-tree
                                    ref="defaultnode"
                                    node-key="id"
                                    :data="Commodimessage"
                                    show-checkbox
                                    :props="defaultProps"
                                    @check="handleBucketClick"
                                    :default-checked-keys="Selecteefault"
                            >
                            </el-tree>
                        </div>
                    </div>
                    <div class="dotwire"></div>
                    <div class="compatibilityswe">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span><span class="magnify">包含</span>特定商品：
                        </div>
                        <div class="reqfieldsd">
                            说明：选择除去上面所选二级分类下的商品外，该商品组还包含的商品
                        </div>
                    </div>
                </el-form>
                <div style="margin-left: 30px;">
                    <el-button type="primary" @click="OpenAddgoods">新增商品</el-button>
                    <el-button type="primary" @click="deletebatchessp">批量删除</el-button>
                </div>
                <div style="margin-top: 20px;">
                    <table class="zhuixiaoi">
                        <thead class="mmodity">
                        <tr>
                            <th>
                                <el-checkbox :indeterminate="spterminate" v-model="spckAll" @change="spCheckAllChange">
                                    全选&ensp;
                                </el-checkbox>
                            </th>
                            <th>单品</th>
                            <th>分类</th>
                            <th>单价</th>
                        </tr>
                        </thead>
                        <tbody class="limiting" :style="{'width':'100%'}">
                        <tr v-for="(item,i) in bhcommodity" :key="item.id" class="drag-list"
                            :class="sppleSelection.includes(item.id)? 'drag-list-check':''">
                            <td :style="{'color':item.s=='无效'?'#595959':''}">
                                <el-checkbox-group v-model="sppleSelection" @change="sheckedCitiesChange">
                                    <el-checkbox :label="item.id">{{i+1}}&emsp;&ensp;</el-checkbox>
                                </el-checkbox-group>
                            </td>
                            <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.n}}</td>
                            <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.on}} <i
                                    class="el-icon-arrow-right"></i> {{item.tn}}
                            </td>
                            <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.price || '---'}}</td>
                        </tr>
                        <tr class="drag-list" v-if="bhcommodity.length<1">
                            <td class="nodata">
                                <img src="@/assets/img/wu.png" alt="">
                                <div class="hint">暂无数据</div>
                            </td>
                        </tr>
                        </tbody>
                    </table>
                </div>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFormVisible = false">取消</el-button>
                    <el-button v-show="title" type="primary" @click="construction">新建</el-button>
                    <el-button v-show="!title" type="primary" @click="saveprinter">保存</el-button>
                    <!-- <el-button  type="primary" @click="construction">新建</el-button> -->
                </span>
            </el-dialog>
        </div>
        <!-- 新增商品 -->
        <div v-show="OpenAddgood" class="OpenAddgood">
            <el-dialog title="新增商品" @close="OpenAddgood = false" :visible.sync="OpenAddgood"
                       :close-on-click-modal="false">
                <div class="in_sum-rkrq">
                    <div class="rkrq">
                        <span>商品分类：</span>
                        <el-cascader
                                clearable
                                :options="dcommoditytems"
                                :props="optionProp"
                                v-model="commoditycode"
                                popper-class='liebdwd'
                                ref="cascaderRef">
                        </el-cascader>
                    </div>
                    <div class="rkrq">
                        <el-input v-model="searchcriteria.name" placeholder="请输入商品名称 模糊查询"></el-input>
                    </div>
                    <div class="rkrq">
                        <el-button type="primary" @click="Searchfogoods">查询</el-button>
                    </div>
                </div>
                <div style="display: inline-block;width: 602px; ">
                    <table class="zhuixiaoi">
                        <thead class="mmodity">
                        <tr>
                            <th>行号</th>
                            <th>名称</th>
                            <th>分类</th>
                            <th>单价</th>
                        </tr>
                        </thead>
                        <tbody class="limiting infinite-list" v-infinite-scroll="load"
                               :infinite-scroll-disabled="disabled">
                        <tr v-for="(item,i) in Commodityontent" :key="i" class="drag-list " draggable="true"
                            :class="checkedCitispes.includes(item.id)? 'drag-list-check':''">
                            <td :style="{'color':item.s=='2'?'#595959':''}">
                                <el-checkbox-group v-model="checkedCitispes" :disabled="item.control">
                                    <el-checkbox :label="item.id">{{i+1}}</el-checkbox>
                                </el-checkbox-group>
                            </td>
                            <td :style="{'color':item.s=='2'?'#595959':''}">{{item.n}}</td>
                            <td :style="{'color':item.s=='2'?'#595959':''}">{{item.on}} <i
                                    class="el-icon-arrow-right"></i> {{item.tn}}
                            </td>
                            <td :style="{'color':item.s=='2'?'#595959':''}">{{item.price}}</td>
                        </tr>
                        <tr class="drag-list" v-if="Commodityontent.length<1">
                            <td class="nodata">
                                <img v-show="controlpicture ==1" src="../../../../assets/img/wu.png" alt="">
                                <img v-show="controlpicture ==2" src="../../../../assets/img/empty_search.png" alt="">
                                <img v-show="controlpicture ==3" src="../../../../assets/img/state_loading.png" alt="">
                                <div v-show="controlpicture ==1" class="hint">暂无数据</div>
                                <div v-show="controlpicture ==2" class="hint">空-请检索</div>
                                <div v-show="controlpicture ==3" class="hint">加载中...</div>
                            </td>
                        </tr>
                        <tr v-if="loading" class="drag-listfsfew">
                            <td>加载中...</td>
                        </tr>
                        <tr v-if="noMore" class="drag-listfsfew">
                            <td>没有更多了</td>
                        </tr>
                        </tbody>
                    </table>
                </div>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="OpenAddgood = false">取消</el-button>
                    <el-button type="primary" @click="addsp">添加</el-button>
                </span>
            </el-dialog>
        </div>

      <!-- 批量删除 -->
      <div v-show="dialogFible" class="diagrgeesfelogFor">
        <el-dialog
          :title="srnr"
          :visible.sync="dialogFible"
          @close="dialogFible = false"
          :close-on-click-modal="false"
        >
          <div class="wwent" v-show="cwsm.cs.length>0">
            <span>以下对象存在依赖，需同步设置为{{srnr | pand}}</span>
            <characters-button
              @click.native="synchronizon"
              :disaed="kzsfjy"
              colors="#f5f5f5"
              :wz="`同步${srnr}`"
            ></characters-button>
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
import EllipsisTooltip from "@/components/EllipsisTooltip.vue"; //根据路径导入组件
export default {
  data(){
    return {
      tableData: [],//商品组
      dialogFormVisible: false,//控制新建商品组是否显示

      multipleSelection: [],// 选中的商品组
      isIndeterminate: false,// 商品组选择一部分
      checkAll: false,//商品组全选

      pgrp: {
        Name: '',//商品组名称
        id: ''
      },
      xzclassify: [],//选中的二级分类
      bhcommodity: [],//商品组包含商品


      Commodimessage: [],//选择二级列表全部内容
      defaultProps: {
        children: 'ts',
        label: 'n'
      },
      Selecteefault: [],// 默认选中节点

      title: true,// 新建还是编辑

      sppleSelection: [],// 选中的商品组
      spterminate: false,// 商品组选择一部分
      spckAll: false,//商品组全选


      OpenAddgood: false, //打开新增商品
      searchcriteria: {
        name: '',
        page_num: 1,//第几页
        page_size: 10,//每页多少行
        init: 1,//初始化
        one_cate_id: 0,//一级分类
        two_cate_id: 0,//二级分类
      },//搜索条件

      dcommoditytems: [],//商品分类信息
      optionProp: {
        value: 'id',
        label: 'n',
        children: 'ss',
        checkStrictly: true,
        expandTrigger: 'hover'
      },//规则
      commoditycode: [],//选中的分类
      Commodityontent: [],//商品内容

      checkedCitispes: [],//选中的商品
      Toadditem: [],// 待添加项

      disabled: false,//控制是否到全部禁用
      loading: true,//控制加载中
      noMore: false,//控制没有更多数据
      hefirstime: true,//是否是第一次进入

      controlpicture: '2',
      windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
      MaxHeight: 0,//滚动高度
      MaxNumber: 0,//最大个数

      form_rules: ["name"],
      form_rule_msg_name: "",

      flag: false,


      dialogFible: false,  // 批量删除冲突
      srnr: "", //文案
      cwsm: {
        ns: [], //不可操作列表
        cs: [] //可一键操作列表
      }, //错误2说明
      kzsfjy: false, //控制同步按钮是否禁用
    }
  },
  components: {
    IconButton,
    EllipsisTooltip
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
    // form表单检测
    validator(val){
      switch (val) {
        case "name":
          if (this.pgrp.Name == '') {
            this.form_rule_msg_name = '请输入商品组名称'
          } else if (this.$overall.character(this.pgrp.Name) > 20) {
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
    // 获取商品组信息内容
    demand(){
      this.$api.BMS.pgrp.requestpgrplist().then(res => {
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
    // 读取商品组信息
    Readhegoods(){
      this.$api.BMS.pgrp.requestpgrpget({id: 0}).then(res => {
        console.log(res.data.cates);
        var s = res.data.cates
        for (var i = 0; i < s.length; i++) {
          if (s[i].ts == null) {
            s.splice(i, 1)
            i -= 1
          }
        }
        this.Commodimessage = [{
          n: '以下全部',
          ts: s,
        }]
        this.$nextTick(() => {  //次要代码
          this.$refs.defaultnode.setCheckedKeys(this.Selecteefault);
        })
        // console.log(this.Commodimessage);
      })
    },
    // 点开创建name为空
    xingh(){
      this.form_rule_msg_name = ''
      this.dialogFormVisible = true
      this.pgrp.Name = ''
      this.title = true
      this.xzclassify = []
      this.Selecteefault = []
      this.bhcommodity = []
      this.edit()
      this.Readhegoods()
    },
    // 选中的二级分类
    handleBucketClick(nodeObj, SelectedObj){
      console.log(SelectedObj.checkedKeys)   // 这是选中的节点的key数组
      this.xzclassify = []
      for (const iterator of SelectedObj.checkedKeys) {
        if (iterator != undefined) {
          this.xzclassify.push(iterator)
        }
      }
    },
    // 打开添加商品
    OpenAddgoods(){

      this.controlpicture = '2'
      this.commoditycode = []
      this.checkedCitispes = []
      this.Toadditem = []
      this.hefirstime = true
      this.searchcriteria = {
        name: '',
        page_num: 1,//第几页
        page_size: 10,//每页多少行
        init: 1,//初始化
        one_cate_id: 0,//一级分类
        two_cate_id: 0,//二级分类
      }
      this.$api.BMS.pgrp.requestpgrpprd_items({
        name: this.searchcriteria.name,
        page_num: this.searchcriteria.page_num,
        page_size: this.searchcriteria.page_size,
        init: this.searchcriteria.init,
        one_cate_id: this.searchcriteria.one_cate_id,
        two_cate_id: this.searchcriteria.two_cate_id,
      }).then(res => {
        console.log(res);
        if (res.code == 1) {
          this.dcommoditytems = res.data.cates || []
          this.Commodityontent = []
          this.OpenAddgood = true
          this.loading = false
          this.noMore = false
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 选择全选或取消
    spCheckAllChange(val) {
      if (val) {
        this.sppleSelection = []
        for (const key in this.bhcommodity) {
          this.sppleSelection.push(this.bhcommodity[key].id)
        }
      } else {
        this.sppleSelection = []
      }
      this.spterminate = false;
    },
    // 控制单个选中
    sheckedCitiesChange(value) {
      let checkedCount = value.length;
      this.checkAll = checkedCount === this.bhcommodity.length;
      this.spterminate = checkedCount > 0 && checkedCount < this.bhcommodity.length;
    },
    // 搜索商品
    Searchfogoods(){
      this.controlpicture = '3'
      this.Commodityontent = []
      setTimeout(() => {
        this.searchcriteria.page_num = 1
        this.searchcriteria.init = 2
        this.$api.BMS.pgrp.requestpgrpprd_items({
          name: this.searchcriteria.name,
          page_num: this.searchcriteria.page_num,
          page_size: this.searchcriteria.page_size,
          init: this.searchcriteria.init,
          one_cate_id: this.searchcriteria.one_cate_id,
          two_cate_id: this.searchcriteria.two_cate_id,
        }).then(res => {
          console.log(res);
          this.disabled = false
          if (res.data.prds == null) {
            this.controlpicture = '1'
          }
          for (const ky in res.data.prds || []) {
            for (const key in this.bhcommodity) {
              if (res.data.prds[ky].id == this.bhcommodity[key].id) {
                res.data.prds[ky].control = true
              }
            }
          }

          this.Commodityontent = res.data.prds || []
          this.loading = true
          this.noMore = false
          if (res.data.cates == null) {
            this.loading = false
          } else if (res.data.cates.loading < 9) {
            this.noMore = true
          }
        })
      }, 1000)

    },
    // 无限加载
    load(){
      if (this.hefirstime) {
        this.hefirstime = false
      } else {
        this.loading = true
        setTimeout(() => {
          this.searchcriteria.page_num += 1
          this.$api.BMS.pgrp.requestpgrpprd_items({
            name: this.searchcriteria.name,
            page_num: this.searchcriteria.page_num,
            page_size: this.searchcriteria.page_size,
            init: this.searchcriteria.init,
            one_cate_id: this.searchcriteria.one_cate_id,
            two_cate_id: this.searchcriteria.two_cate_id,
          }).then(res => {
            console.log(res.data.prds);
            if (res.data.prds == null) {
              this.loading = false
              this.noMore = true
              this.disabled = true
            } else if (res.data.prds.length > 0) {
              for (const ky in res.data.prds || []) {
                for (const key in this.bhcommodity) {
                  if (res.data.prds[ky].id == this.bhcommodity[key].id) {
                    res.data.prds[ky].control = true
                  }
                }
              }
              for (const iterator of res.data.prds) {
                this.Commodityontent.push(iterator)
              }
            }
          })
        }, 2000)

      }
      console.log(1231);
    },
    // 新增商品
    addsp(){
      for (const iterator of this.Toadditem) {
        this.bhcommodity.push(iterator)
      }
      this.OpenAddgood = false
    },
    // 商品组批量删除商品
    deletebatchessp(){
      console.log(123);
      for (const iterator of this.sppleSelection) {
        for (const key in this.bhcommodity) {
          if (this.bhcommodity[key].id == iterator) {
            this.bhcommodity.splice(key, 1);
            continue;
          }
        }
      }
      this.spterminate = false
      this.spckAll = false
      this.sppleSelection = []
    },
    // 创建商品组
    construction(){
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_name) return;
      var s = []
      for (const iterator of this.bhcommodity) {
        s.push(iterator.id)
      }
      this.$api.BMS.pgrp.requestpgrpnew({
        name: this.pgrp.Name,
        prd_ids: s,
        cate_ids: this.xzclassify,
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
          this.pgrp.Name = ''
          this.bempty()
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 获取编辑内容
    compileprinter(){
      if (this.multipleSelection.length == 1) {
        this.form_rule_msg_name = ''
        this.$api.BMS.pgrp.requestpgrpget({id: this.multipleSelection[0]}).then(res => {
          console.log(res)
          if (res.code == 1) {
            // 给分类赋值
            var s = res.data.cates
            for (var i = 0; i < s.length; i++) {
              if (s[i].ts == null) {
                s.splice(i, 1)
                i -= 1
              }
            }
            this.Commodimessage = [{
              n: '以下全部',
              ts: s,
            }]
            console.log(s);
            var w = []
            for (const iterator of s) {
              for (const itetor of iterator.ts) {
                if (itetor.s == 1) {
                  w.push(itetor.id)
                }
              }
            }
            console.log(w);
            this.pgrp.Name = res.data.name
            this.pgrp.id = res.data.id
            this.bhcommodity = res.data.prds || []
            this.xzclassify = w
            this.Selecteefault = w

            this.$nextTick(() => {  //次要代码
              this.$refs.defaultnode.setCheckedKeys(this.Selecteefault);
            })
            this.dialogFormVisible = true
            this.title = false
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
      var s = []
      for (const iterator of this.bhcommodity) {
        s.push(iterator.id)
      }
      this.$api.BMS.pgrp.requestpgrpsave({
        id: this.pgrp.id,
        name: this.pgrp.Name,
        prd_ids: s,
        cate_ids: this.xzclassify,
      }).then(res => {
        console.log(res);
        if (res.code == 1) {
          this.$message({
            showClose: true,
            message: "操作成功",
            type: 'success'
          })
          this.demand()
          this.pgrp.Name = ''
          this.dialogFormVisible = false
          this.bempty()
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 删除
    printerdel(){
      if (this.multipleSelection.length > 0) {
        this.$api.BMS.pgrp.requestpgrpdel({ids: this.multipleSelection}).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.demand()
            this.$message({
              showClose: true,
              message: "操作成功",
              type: 'success'
            })
            this.bempty()
          } else if(res.code == 2) {
            console.log(res.code)
            this.dialogFible = true;
              this.kzsfjy = false;
              this.srnr = "批量删除";
              this.cwsm.ns = res.data.ns || [];
              for (const key in res.data.cs) {
                res.data.cs[key].jg = "---";
              }
              this.cwsm.cs = res.data.cs || [];
          } else {
            this.$message.warning(res.msg)
          }
        })
      } else {
        this.$message({
          message: '请先选择商品组',
          type: 'warning',
        })
      }
    },

    // 同步
    synchronizon() {
      this.kzsfjy = true;
      var tid = [];
      var id = [];
      for (const iterator of this.cwsm.cs) {
        tid.push(iterator.tid);
        id.push(iterator.id);
      }
      this.$api.BMS.mklib
        .requestpgrpdelOb({
          op_status: 3,
          type_ids: tid,
          ids: id
        })
        .then(res => {
          if (res.code == 1) {
            for (const key in this.cwsm.cs) {
              this.cwsm.cs[key].jg = "成功";
            }
            this.printerdel();
            this.dialogFible = false;
          } else if (res.code == 2) {
            for (const key in this.cwsm.cs) {
              for (const keys in res.data) {
                if (this.cwsm.cs[key].id == res.data[keys].id) {
                  this.cwsm.cs[key].jg = "失败";
                }
              }
            }
            for (const key in this.cwsm.cs) {
              if (this.cwsm.cs[key].jg == "---") {
                this.cwsm.cs[key].jg = "成功";
              }
            }
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    // 为空
    bempty(){
      this.multipleSelection = []
      this.isIndeterminate = false
      this.checkAll = false
    }
  }
  ,
  watch: {
    windowHeigh(val)
    {
      let that = this;
      this.RollMaxHeight(val)
      //   console.log("实时屏幕高度：",val, that.windowHeigh );
    }
    ,
    windowWidt(val)
    {
      let that = this;
      //   console.log("实时屏幕宽度：",val, that.windowWidt );
    }
    ,
    // 选中一个分类后关闭
    commoditycode: {
      deep: true,
      handler: function (after, before) {
        // this.erp_prds.erp_cate_code = after[after.length-1]
        // console.log(after);
        // this.prderp_prds()
        // this.checkedCitispes = []
        console.log(after);
        if (after.length == 1) {
          this.searchcriteria.one_cate_id = after[0]
          this.searchcriteria.two_cate_id = 0

        } else if (after.length == 2) {
          this.searchcriteria.one_cate_id = after[0]
          this.searchcriteria.two_cate_id = after[1]
        } else if (after.length == 0) {
          this.searchcriteria.one_cate_id = 0
          this.searchcriteria.two_cate_id = 0
        }
        // this.Searchfogoods()
        if (this.$refs.cascaderRef) {
          this.$refs.cascaderRef.dropDownVisible = false
        }
      }
    }
    ,
    // 选中的商品
    checkedCitispes: {
      deep: true,
      handler: function (after, before) {
        if (after.length > before.length) {
          for (const iterator of this.Commodityontent) {
            if (iterator.id == after[after.length - 1]) {
              this.Toadditem.push(iterator)
            }
          }
        } else if (after.length < before.length) {
          var w = before
          for (const iterator of after) {
            for (const key in w) {
              if (w[key] == iterator) {
                w.splice(key, 1);
                continue;
              }
            }
          }
          console.log(w);
          for (const key in this.Toadditem) {
            if (this.Toadditem[key].id == w[0]) {
              this.Toadditem.splice(key, 1);
            }
          }
        }
      }
    }
  }
}
</script>
<style>
    /* 靠右 */
    .pgrp .el-dialog {
        margin: 0px 0px 0px auto !important;
        background-color: #f9f9f9;
        height: 100%;
        position: relative;
    }

    .pgrp .el-dialog__footer {
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }

    .pgrp .el-dialog__body {
        padding: 0px 0px 30px 20px;
        overflow-y: scroll !important;
        /* width: 100%; */
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;
    }

    .pgrp .el-dialog {
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .pgrp {
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding: 20px 30px;
    }

    /* 级联选择器 */
    .liebdwd .el-radio__inner {
        top: -18px;
        left: -19px;
        border-radius: 0;
        border: 0;
        width: 170px;
        height: 34px;
        background-color: transparent;
        cursor: pointer;
        box-sizing: border-box;
        position: absolute;
    }

    .liebdwd .el-radio__input.is-checked .el-radio__inner {
        background: transparent;
    }

    /* ERP商品 */
    .in_sum-rkrq {
        color: #40404e;
        padding: 20px 0;
        display: flex;

    }

    .pgrp .in_sum-rkrq .rkrq {
        margin-right: 15px;
        /* width: 280px; */
        display: flex;
        align-items: center;
    }

    .pgrp .in_sum-rkrq .el-cascader__dropdown {
        background-color: #383943;
    }

    .pgrp .in_sum-rkrq .rkrq > span {
        width: 70px;
        display: inline-block;
    }

    .pgrp .in_sum-rkrq .rkrq .el-select {
        width: 230px;
    }

    .pgrp .in_sum-rkrq .rkrq .el-input {
        width: 220px;
    }

    .pgrp .in_sum-rkrq .rkrq:nth-of-type(3) {
        width: 240px;
    }

    /* 级联选择器 */
    .el-cascader__dropdown {
        border: 1px solid #f5f5f5;
    }

    .el-cascader-menu__wrap {
        background-color: #f5f5f5;
    }

    .el-cascader-node:not(.is-disabled):hover {
        color: #40404e
    }

    .el-cascader-node.in-active-path, .el-cascader-node.is-active, .el-cascader-node.is-selectable.in-checked-path {
        color: #409EFF !important;
        background-color: #e5e5e5;
    }

    .el-radio__inner::after {
        background-color: #e5e5e5;
    }

    .el-cascader-node__label {
        color: #40404e
    }

    .el-cascader-menu {
        border-right: solid 1px transparent;
    }

    /* 必填 */
    .pgrp .mandatory {
        color: #40404e;
        width: 140px;
        text-align: right;
    }

    .pgrp .controlling {
        color: #40404e;
        width: 230px !important;
    }

    .pgrp .reqfieldsd {
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
    .pgrp .tiaodd {
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

    .pgrp .nodata {
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        padding: 0;
    }

    .pgrp .nodata img {
        width: 60px;
        height: 60px;
    }

    .pgrp .nodata .hint {
        line-height: 36px;
        font-size: 13px !important;
    }

    .pgrp .compatibility {
        display: flex;
        align-items: center;
        margin-bottom: 10px;
    }

    .compatibilityswe {
        display: flex;
        align-items: flex-end;
        margin-bottom: 10px;
    }

    .pgrp-headline {
        font-size: 30px;
        font-weight: bold;
        color: #40404e;
    }

    .pgrp-controller {
        /*margin-top: 30px;*/
        height: 54px;
        /*width: 1600px;*/
        background-color: #eee;
        display: flex;
        align-items: center;
    }

    .pgrp .el-dialog .el-button--default {
        background-color: #ccc;
        border: 1px solid #ccc;
        color: #40404e;
    }

    .pgrp .el-dialog {
        background-color: #f9f9f9;
    }

    .pgrp .el-dialog__header, .pgrp .el-dialog__footer {
        background-color: #eee;
    }

    .pgrp .el-dialog__title, .pgrp .el-dialog__headerbtn .el-dialog__close, .pgrp .el-form-item__label {
        color: #1a1a21;
    }

    .pgrp .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    .pgrp .el-dialog {
        width: 30vw;
    }

    /* 新增商品组 */
    .pgrp .dialogFormVisible .el-dialog {
        width: 650px !important;
    }

    .pgrp .dialogFormVisible .zhuixiaoi .limiting {
        max-height: 250px !important;
    }

    /* 点线 */
    .pgrp .dialogFormVisible .dotwire {
        width: 100%;
        border-top: 1px dotted #383943;
        margin-bottom: 10px;
    }

    /* 放大字 */
    .pgrp .dialogFormVisible .magnify {
        font-size: 22px;
    }

    /* 树状结构 */
    .pgrp .dialogFormVisible .el-tree-node__content:hover, .el-tree-node__content, .el-tree-node:focus > .el-tree-node__content {
        background-color: transparent;
    }

    .pgrp .dialogFormVisible .el-tree {
        background-color: transparent;
        color: #40404e;
    }

    .pgrp .dialogFormVisible .el-checkbox__inner::after {
        border-color: #fff;
    }

    .pgrp .dialogFormVisible .zhuixiaoi {
        width: 600px;
        border-collapse: collapse;
        color: #40404e;
    }

    /* 表格无数据时展示 */
    .pgrp .dialogFormVisible .drag-list .nodata {
        height: 150px !important;
    }

    .pgrp .dialogFormVisible .drag-list td:nth-of-type(1), .pgrp .dialogFormVisible .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .pgrp .dialogFormVisible .mmodity th:nth-of-type(2), .pgrp .dialogFormVisible .drag-list td:nth-of-type(2) {
        width: 240px;
    }

    .pgrp .dialogFormVisible .drag-list td:nth-of-type(3), .pgrp .dialogFormVisible .mmodity th:nth-of-type(3) {
        width: 140px;
    }

    .pgrp .dialogFormVisible .drag-list td:nth-of-type(4), .pgrp .dialogFormVisible .mmodity th:nth-of-type(4) {
        width: 140px;
    }

    /* 新增商品 */
    .pgrp .OpenAddgood .el-dialog {
        width: 660px !important;
    }

    .pgrp .OpenAddgood .zhuixiaoi {
        /* width: 100%; */
        width: 600px;
        /* width: calc(100% + 6px) !important; */
    }

    .pgrp .OpenAddgood .zhuixiaoi .limiting {
        max-height: 350px !important;
        /* display: flex;
        flex-direction: column; */
        /* max-width: 100%; */
        /* width: calc(100% + 6px) !important; */
    }

    .pgrp .OpenAddgood .drag-list {
        width: 100%;
    }

    .pgrp .OpenAddgood .drag-list td:nth-of-type(1), .pgrp .OpenAddgood .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .pgrp .OpenAddgood .mmodity th:nth-of-type(2), .pgrp .OpenAddgood .drag-list td:nth-of-type(2) {
        width: 240px;
    }

    .pgrp .OpenAddgood .drag-list td:nth-of-type(3), .pgrp .OpenAddgood .mmodity th:nth-of-type(3) {
        width: 140px;
    }

    .pgrp .OpenAddgood .drag-list td:nth-of-type(4), .pgrp .OpenAddgood .mmodity th:nth-of-type(4) {
        width: 140px;
    }

    .pgrp .OpenAddgood .drag-listfsfew {
        box-sizing: border-box;
        width: 100%;
        display: block;
    }

    .pgrp .OpenAddgood .drag-listfsfew td {
        width: 100%;
        height: 40px;
        line-height: 40px;
        text-align: center;
        font-size: 14px;
        font-weight: 400;
        display: block;
    }

    /* 改变多选框背景颜色和上下间距 */
    .pgrp .el-checkbox-group {
        display: flex;
        align-items: flex-end;
        justify-content: left;
    }

    .pgrp .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    /* 列表 */
    .zsykd {
        width: 100%;
        overflow-x: scroll !important;
    }

    .pgrp .zhuixiaoi {
        width: 1600px;
        border-collapse: collapse;
        color: #40404e;
    }

    .pgrp .zhuixiaoi .mmodity tr th {
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-size: 14px;
        font-weight: 600;
        padding-left: 20px;
        color: #40404e;
    }

    .pgrp .zhuixiaoi .mmodity tr th .el-checkbox__label {
        font-size: 14px;
        font-weight: 600;
        color: #40404e;
    }

    .pgrp .zhuixiaoi .limiting .drag-list td {
        height: 36px;
        line-height: 36px;
        text-align: left;
        /*border-right: solid 1px #383943;*/
        /*border-top: solid 1px #383943;*/
        font-size: 14px;
        font-weight: 400;
        padding-left: 20px;
    }

    .pgrp .zhuixiaoi .limiting .drag-list {
        display: block;
        display: flex;
    }

    .pgrp .zhuixiaoi .mmodity {
        width: 100%;
        display: block;
    }

    .pgrp .zhuixiaoi .mmodity tr {
        background-color: #f5f5f5;
        display: flex;
    }

    .pgrp .zhuixiaoi .limiting {
        overflow-y: auto !important;
        max-height: 540px;
        display: block;
    }

    .pgrp .drag-list td:nth-of-type(1), .pgrp .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .pgrp .mmodity th:nth-of-type(2), .pgrp .drag-list td:nth-of-type(2) {
        width: 240px;
    }

    .pgrp .drag-list td:nth-of-type(3), .pgrp .mmodity th:nth-of-type(3) {
        width: 140px;
    }

    .pgrp .drag-list td:nth-of-type(4), .pgrp .mmodity th:nth-of-type(4) {
        width: 140px;
    }

    .pgrp .drag-list td:nth-of-type(5), .pgrp .mmodity th:nth-of-type(5) {
        width: 140px;
    }

    .pgrp .drag-list td:nth-of-type(6), .pgrp .mmodity th:nth-of-type(6) {
        width: 140px;
    }

    .pgrp .drag-list td:nth-of-type(7), .pgrp .mmodity th:nth-of-type(7) {
        width: 60px;
    }

    .pgrp .drag-list:nth-of-type(odd) {
        background-color: #f9f9f9;
        color: #40404e;
    }

    .pgrp .drag-list:nth-of-type(even) {
        background-color: #f5f5f5;
        color: #40404e;
    }

    /* 全选颜色 */
    .pgrp .zhuixiaoi .el-checkbox__label {
        color: #40404e;
    }

    .pgrp .zhuixiaoi .mmodity .el-checkbox__label {
        font-size: 12px;
    }

    .drag-list-check {
        /* background: rgba(39, 52, 82, .5) !important; */
    }


    .pgrp .diagrgeesfelogFor .el-dialog {
      width: 720px;
      box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1);
    }

    .pgrp .diagrgeesfelogFor .wwent {
      color: #ce4153;
      font-size: 14px;
      margin: 20px 0px 20px 20px;
      display: flex;
      align-items: center;
    }

    .pgrp .diagrgeesfelogFor .wentlb {
      margin-left: 20px;
      width: 640px;
    }

    .pgrp .diagrgeesfelogFor .zhuixiaoi {
      width: 100%;
    }

    .pgrp .diagrgeesfelogFor .zhuixiaoi .limiting {
      max-height: 280px !important;
      overflow-y: auto !important;
    }

    .pgrp .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(1),
    .pgrp .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(1) {
      width: 50px;
    }

    .pgrp .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(2),
    .pgrp .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(2) {
      width: 320px;
    }

    .pgrp .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(3),
    .pgrp .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(3) {
      width: 200px;
    }

    .pgrp .diagrgeesfelogFor .danykz .mmodity th:nth-of-type(2),
    .pgrp .diagrgeesfelogFor .danykz .drag-list td:nth-of-type(2) {
      width: 520px;
    }

    /* 无效颜色 */
    .pgrp .diagrgeesfelogFor .el-button--primary.is-disabled,
    .pgrp .diagrgeesfelogFor .el-button--primary.is-disabled:hover {
      background-color: #1f2846;
      color: #4e505a;
      border-color: #1f2846;
    }


</style>

