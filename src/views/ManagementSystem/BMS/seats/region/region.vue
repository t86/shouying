<template>
  <div class="region">
    <div class="region-controller">
      <icon-button @click.native="xingh" text="新增区域" img="添加.png" colors="#383943"></icon-button>
      <icon-button @click.native="compileprinter" text="编辑" img="编辑.png" colors="#383943"></icon-button>
      <icon-button @click.native="noneffective" text="置为无效" img="无效.png" colors="#383943"></icon-button>
      <icon-button @click.native="effective" text="置为有效" img="有效.png" colors="#383943"></icon-button>
      <icon-button
        @click.native="printerdel"
        text="批量删除"
        img="删除.png"
        colors="#6B2830"
        bjcolors="#491E24"
      ></icon-button>
      <characters-button @click.native="$message.info('上下拖动区域可调整顺序')" colors="#383943" wz='调整顺序'></characters-button>
    </div>
    <div style="position: relative">
      <div class="zsykd" style="display: inline-block;">
        <table class="zhuixiaoi">
          <thead class="mmodity">
            <tr>
              <th>
                <el-checkbox
                  :indeterminate="isIndeterminate"
                  v-model="checkAll"
                  @change="handleCheckAllChange"
                >全选&ensp;</el-checkbox>
              </th>
              <th>区域名称</th>
              <th>卡台数量</th>
              <th>创建时间</th>
              <th>更新时间</th>
              <th>状态</th>
            </tr>
          </thead>
          <tbody
            class="limiting"
            ref="systemForm"
            @scroll="sysHandleScroll()"
            @mouseover="changeFlag(false)"
            :style="{'border-bottom':tableData.length<1?'0px':'',
                'width':tableData.length>MaxNumber?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`}"
          >
            <tr
              v-for="(item,i) in tableData"
              :key="item.id"
              class="drag-list"
              draggable="true"
              @dragstart="dragstart(item)"
              @dragenter="dragenter(item)"
              @dragend="dragend(item)"
              :class="multipleSelection.includes(item.id)? 'drag-list-check':''"
              title="拖动可调整顺序"
            >
              <td :style="{'color':item.s=='无效'?'#595959':''}">
                <el-checkbox-group v-model="multipleSelection" @change="handleCheckedCitiesChange">
                  <el-checkbox :label="item.id">{{i+1}}&emsp;&ensp;</el-checkbox>
                </el-checkbox-group>
              </td>
              <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.n}}</td>
              <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.sc || '---'}}</td>
              <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.c || '---'}}</td>
              <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.u}}</td>
              <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.s}}</td>
            </tr>
          </tbody>
        </table>
        <div class="drag-list" v-if="tableData.length<1">
          <td class="nodata">
            <img src="@/assets/img/wu.png" alt />
            <div class="hint">暂无数据</div>
          </td>
        </div>
      </div>
      <div style="display: inline-block;position: absolute;top: 0;left: 0;z-index: 100;">
        <table class="zhuixiaoi zhuixiaoi_l" style="width: auto;">
          <thead class="mmodity">
            <tr>
              <th>
                <el-checkbox
                  :indeterminate="isIndeterminate"
                  v-model="checkAll"
                  @change="handleCheckAllChange"
                >全选&ensp;</el-checkbox>
              </th>
              <th>区域名称</th>
            </tr>
          </thead>
          <tbody
            class="limiting"
            ref="externalForm"
            @scroll="exterHandleScroll()"
            @mouseover="changeFlag(true)"
            :style="{'border-bottom':tableData.length<1?'0px':'',
                'width':tableData.length>MaxNumber?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`}"
          >
            <tr
              v-for="(item,i) in tableData"
              :key="item.id"
              class="drag-list"
              draggable="true"
              @dragstart="dragstart(item)"
              @dragenter="dragenter(item)"
              @dragend="dragend(item)"
              :class="multipleSelection.includes(item.id)? 'drag-list-check':''"
              title="拖动可调整顺序"
            >
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
      <el-dialog
        :title="title?'新增区域':'编辑区域'"
        @close="dialogFormVisible = false"
        :visible.sync="dialogFormVisible"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div class="compatibility">
            <div class="mandatory">
              <span class="reqfieldsd">*</span>区域名称：
            </div>
            <el-input
              v-model="regionName"
              placeholder="请输入区域名称"
              ref="selectsse"
              show-word-limit
              class="controlling"
              :class="form_rule_msg_name?'error':''"
              @blur="validator('name')"
            />
            <div class="cwts">{{form_rule_msg_name}}</div>
          </div>
          <div v-if="!title" class="compatibility">
            <div class="mandatory">
              <span class="reqfieldsd"></span>必点商品：
            </div>
            <div v-if="formPrdInfo.n" layout="row" layout-align="start center">
              <div
                style="padding:5px;border-radius:2px"
                layout="row"
                layout-align="start center"
                class="m-r-1"
              >
                <span style="color:#40404e">{{formPrdInfo.n}}</span>
                <i class="el-icon-error cursor" @click="formPrdInfo={}"></i>
              </div>
            </div>
            <el-button type="primary" @click="bindingPrdHandle" v-if="formPrdInfo.n">修改商品</el-button>
            <el-button type="primary" @click="bindingPrdHandle" v-else>添加商品</el-button>
          </div>
          <p v-if="!title" style="margin-left:60px;color:#f56c6c">启用必点商品后，该区域的卡台需要点单该商品后才可下单</p>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="dialogFormVisible = false">取消</el-button>
          <el-button v-show="title" type="primary" @click="construction">新建</el-button>
          <el-button v-show="!title" type="primary" @click="saveprinter">确认</el-button>
        </span>
      </el-dialog>
    </div>

    <!-- 添加或修改商品 -->
    <div class="user-defined" v-show="choosePrdDrawer.showDrawer">
      <el-dialog
        :title="formPrdInfo.name ? '修改商品':'添加商品'"
        @close="choosePrdDrawer.showDrawer = false"
        :visible.sync="choosePrdDrawer.showDrawer"
        :close-on-click-modal="false"
      >
        <div class="in_sum-rkrq m-t-2 m-b-2" layout="row" layout-align="space-around center">
          <div class="rkrq">
            <span>商品分类：</span>
            <el-cascader
              clearable
              :options="choosePrdDrawer.cateOptions"
              v-model="choosePrdDrawer.cateVal"
            ></el-cascader>
          </div>
          <div class="rkrq">
            <el-input v-model="choosePrdDrawer.keyword" placeholder="请输入商品名称"></el-input>
          </div>
          <div class="rkrq">
            <el-button type="primary" @click="getPrdCategoryAndPrdList(1)">查询</el-button>
            <el-button type="info" @click="resetSelectHandle">重置</el-button>
          </div>
        </div>
        <div>
          <table class="zhuixiaoi">
            <thead class="mmodity">
              <tr>
                <th>序号</th>
                <th>单品名称</th>
                <th>分类</th>
                <th>单价</th>
                <th>商品类型</th>
                <th>营业类型</th>
                <th>状态</th>
              </tr>
            </thead>
            <tbody class="limiting tbody" @scroll="tbodyScrollHandle">
              <div class="tbody-contain">
                <tr
                  v-for="(item,i) in choosePrdDrawer.tableData"
                  :key="i"
                  class="drag-list"
                  draggable="true"
                >
                  <td :style="{'color':item.s=='无效'?'#595959':''}">
                    <el-checkbox-group v-model="item.checked">
                      <el-checkbox
                        :label="item.id"
                        @change="changeCheckBoxHandle(item)"
                      >{{i+1}}&emsp;&ensp;</el-checkbox>
                    </el-checkbox-group>
                    <!-- <el-radio v-model="checkedCitispes" :label="item.c">{{i+1}}&emsp;&ensp;</el-radio> -->
                  </td>
                  <td>{{item.n}}</td>
                  <td>{{item.on}} > {{item.tn}}</td>
                  <td>{{item.p}}</td>
                  <td>{{item.pt}}</td>
                  <td>{{item.bt}}</td>
                  <td>{{item.s == 1 ? '有效':'无效'}}</td>
                </tr>
                <tr
                  v-if="choosePrdDrawer.tableData.length>0"
                  layout="row"
                  layout-align="center center"
                >
                  <td style="line-height:50px;white-space:nowrap">{{choosePrdDrawer.loadingText}}</td>
                </tr>
                <tr v-else class="drag-list" layout="row" layout-align="center center">
                  <td class="nodata">
                    <img src="../../../../../assets/img/空-请检索.png" alt />
                    <div>暂无数据</div>
                  </td>
                </tr>
              </div>
            </tbody>
          </table>
        </div>

        <span slot="footer" class="dialog-footer">
          <el-button @click="choosePrdDrawer.showDrawer = false">取消</el-button>
          <el-button type="primary" @click="submitChoosePrdHandle">绑定</el-button>
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
      >
        <div class="wwent" v-show="cwsm.cs.length>0">
          <span>以下对象存在依赖，需同步设置为{{srnr | pand}}</span>
          <characters-button
            @click.native="synchronizon"
            :disaed="kzsfjy"
            colors="#383943"
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
import IconButton from "@/components/IconButton.vue"; //根据路径导入组件
import EllipsisTooltip from "@/components/EllipsisTooltip.vue"; //根据路径导入组件
import CharactersButton from "@/components/CharactersButton.vue"; //根据路径导入组件
import eventVue from '@/utils/eventVue';
export default {
  data() {
    return {
      List: [], //全部内容
      oldItem: "", //记录初始信息
      newItem: "", // 记录过程中信息

      tableData: [], //区域
      dialogFormVisible: false, //控制新建区域是否显示
      regionName: "", //区域名称
      quantity: [], // 判断哪个要亮

      title: true, //

      multipleSelection: [], // 选中的内容
      isIndeterminate: false, // 供应商选择一部分
      checkAll: false, //供应商全选

      dialogFible: false, //控制错误2是否显示
      srnr: "", //文案
      cwsm: {
        ns: [], //不可操作列表
        cs: [] //可一键操作列表
      }, //错误2说明
      kzsfjy: false, //控制同步按钮是否禁用

      windowWidt: document.documentElement.clientWidth, //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight, //实时屏幕高度
      MaxHeight: 0, //滚动高度
      MaxNumber: 0, //最大个数

      form_rules: ["name"],
      form_rule_msg_name: "",

      formPrdInfo: {}, // 必点商品
      choosePrdDrawer: {
        showDrawer: false,
        cateOptions: [],
        cateVal: [0, 0],
        keyword: "",
        pageSize: 50,
        page: 1,
        tableData: [],
        loadingText: "加载中..."
      },

      flag: false
    };
  },
  mounted() {
    this.demand();
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
    IconButton,
    CharactersButton
  },
  filters: {
    pand: function(v) {
      if (v == "置为无效") {
        return "无效";
      } else if (v == "置为有效") {
        return "有效";
      } else if (v == "批量删除") {
        return "删除";
      }
    }
  },
  methods: {
    //滚动条监听
    changeFlag(flag) {
      this.flag = flag;
    },
    // 左右滚动条滚动同步
    sysHandleScroll() {
      if (!this.flag) {
        this.$refs.externalForm.scrollTop = this.$refs.systemForm.scrollTop;
      }
    },
    exterHandleScroll() {
      if (this.flag) {
        this.$refs.systemForm.scrollTop = this.$refs.externalForm.scrollTop;
      }
    },
    // form表单检测
    validator(val) {
      switch (val) {
        case "name":
          if (this.regionName == "") {
            this.form_rule_msg_name = "请输入区域名称";
          } else if (this.$overall.character(this.regionName) > 4) {
            this.form_rule_msg_name = "输入文字长度超过2";
          } else {
            this.form_rule_msg_name = "";
          }
          break;
      }
    },
    // 滚动最大高度
    RollMaxHeight(i) {
      var s = i - 48 - 60 - 55 - 50;
      this.MaxHeight = s;
      this.MaxNumber = Math.floor(s / 37);
      console.log(this.MaxNumber);
      // console.log(i);
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
        let oldIndex = this.tableData.indexOf(this.oldItem);
        let newIndex = this.tableData.indexOf(this.newItem);
        var down_up = 1;
        if (oldIndex > newIndex) {
          down_up = 2;
        } else if (oldIndex < newIndex) {
          down_up = 1;
        }
        this.$api.BMS.region
          .requestregionmove_dsp({
            id: this.oldItem.id,
            dest_id: this.newItem.id,
            down_up: down_up
          })
          .then(res => {
            console.log(res);
            if (res.code == 1) {
              this.$message({
                showClose: true,
                message: "更改位置成功",
                type: "success",
                duration: 1000
              });
              let newList = [...this.tableData]; // 中间数组，用于交换两个节点
              //             // 删除老的节点
              newList.splice(oldIndex, 1);
              //             // 在列表目标位置增加新的节点
              newList.splice(newIndex, 0, this.oldItem);
              //             // 更新this.List，触发transition-group的动画效果
              this.tableData = [...newList];
              eventVue.$emit('reloadReginList')
            } else {
              this.$message.warning(res.msg);
            }
          });
      }
    },
    //获取焦点
    edit() {
      this.$nextTick(() => {
        //次要代码
        this.$refs.selectsse.focus();
        console.log(this.$refs);
      });
    },
    // 选择全选或取消
    handleCheckAllChange(val) {
      if (val) {
        this.multipleSelection = [];
        for (const key in this.tableData) {
          this.multipleSelection.push(this.tableData[key].id);
        }
      } else {
        this.multipleSelection = [];
      }
      this.isIndeterminate = false;
    },
    // 控制单个选中
    handleCheckedCitiesChange(value) {
      let checkedCount = value.length;
      this.checkAll = checkedCount === this.tableData.length;
      this.isIndeterminate =
        checkedCount > 0 && checkedCount < this.tableData.length;
    },
    // 获取区域信息内容 标记
    demand() {
      this.$api.BMS.region.requestregionlist().then(res => {
        console.log(res);
        if (res.code == 1) {
          this.tableData = res.data || [];
          //显示标记
          this.quantity = [];
          for (const key in res.data) {
            if (this.quantity.length == 0) {
              this.quantity = [res.data[key].d == 1];
            } else {
              this.quantity.push(res.data[key].d == 1);
            }
          }
        } else {
          this.$message.warning(res.msg);
        }
      });
    },
    // 点开创建name为空
    xingh() {
      this.form_rule_msg_name = "";
      this.dialogFormVisible = true;
      this.regionName = "";
      this.title = true;
    },
    // 创建区域
    construction() {
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_name) return;
      if (this.regionName == "") {
        this.$message.warning("必选框不能为空");
      } else {
        this.$api.BMS.region
          .requestregionnew({
            name: this.regionName
          })
          .then(res => {
            if (res.code == 1) {
              this.$message({
                showClose: true,
                message: "新增成功",
                type: "success"
              });
              this.demand();
              this.dialogFormVisible = false;
              this.regionName = "";
              this.bempty();
              eventVue.$emit('reloadReginList')
            } else {
              this.$message.warning(res.msg);
            }
          });
      }
    },
    // 编辑内容
    compileprinter() {
      this.form_rule_msg_name = "";
      if (this.multipleSelection.length == 1) {
        this.$api.BMS.region
          .requestregionget({ id: this.multipleSelection[0] })
          .then(res => {
            console.log(res);
            if (res.code == 1) {
              this.regionName = res.data.name;
              this.dialogFormVisible = true;
              this.title = false;
              this.formPrdInfo.n = res.data.must_order_prd_name;
              this.formPrdInfo.id = res.data.must_order_prd_id;
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message({
          message: "请选择一个进行编辑",
          type: "warning"
        });
      }
    },
    // 保存编辑内容
    saveprinter() {
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_name) return;
      this.$api.BMS.region
        .requestregionsave({
          id: this.multipleSelection[0],
          name: this.regionName,
          must_order_prd_id: this.formPrdInfo.id ? this.formPrdInfo.id * 1 : 0
        })
        .then(res => {
          console.log(res);
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
            this.demand();
            this.regionName = "";
            this.dialogFormVisible = false;
            this.bempty();
            eventVue.$emit('reloadReginList')
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    // 重试
    chdefrs() {
      if (this.srnr == "置为无效") {
        this.noneffective();
      } else if (this.srnr == "置为有效") {
        this.effective();
      } else if (this.srnr == "批量删除") {
        this.printerdel();
      }
    },
    // 同步
    synchronizon() {
      this.kzsfjy = true;
      var s = "";
      if (this.srnr == "置为无效") {
        s = 2;
      } else if (this.srnr == "置为有效") {
        s = 1;
      } else if (this.srnr == "批量删除") {
        s = 3;
      }
      var tid = [];
      var id = [];
      for (const iterator of this.cwsm.cs) {
        tid.push(iterator.tid);
        id.push(iterator.id);
      }
      this.$api.BMS.region
        .requestRegionOb({
          op_status: Number(s),
          type_ids: tid,
          ids: id
        })
        .then(res => {
          if (res.code == 1) {
            for (const key in this.cwsm.cs) {
              this.cwsm.cs[key].jg = "成功";
            }
            this.chdefrs();
            this.dialogFible = false
            this.demand();
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
    // 无效
    noneffective() {
      this.$api.BMS.region
        .requestregiondisable({ ids: this.multipleSelection })
        .then(res => {
          console.log(res);
          if (res.code == 1) {
            this.demand();
            this.dialogFible = false;
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
            this.bempty();
            eventVue.$emit('reloadReginList')
          } else if (res.code == 2) {
            this.dialogFible = true;
            this.kzsfjy = false;
            this.srnr = "置为无效";
            this.cwsm.ns = res.data.ns || [];
            for (const key in res.data.cs) {
              res.data.cs[key].jg = "---";
            }
            this.cwsm.cs = res.data.cs || [];
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    // 有效
    effective() {
      this.$api.BMS.region
        .requestregionenable({ ids: this.multipleSelection })
        .then(res => {
          // console.log(res);
          if (res.code == 1) {
            this.demand();
            this.dialogFible = false;
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
            this.bempty();
            eventVue.$emit('reloadReginList')
          } else if (res.code == 2) {
            this.dialogFible = true;
            this.kzsfjy = false;
            this.srnr = "置为有效";
            this.cwsm.ns = res.data.ns || [];
            for (const key in res.data.cs) {
              res.data.cs[key].jg = "---";
            }
            this.cwsm.cs = res.data.cs || [];
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    // 删除
    printerdel() {
      if (this.multipleSelection.length > 0) {
        this.$api.BMS.region
          .requestregiondel({ ids: this.multipleSelection })
          .then(res => {
            if (res.code == 1) {
              this.demand();
              this.dialogFible = false;
              this.$message({
                showClose: true,
                message: "操作成功",
                type: "success"
              });
              this.bempty();
              eventVue.$emit('reloadReginList')
            } else if (res.code == 2) {
              this.dialogFible = true;
              this.kzsfjy = false;
              this.srnr = "批量删除";
              this.cwsm.ns = res.data.ns || [];
              for (const key in res.data.cs) {
                res.data.cs[key].jg = "---";
              }
              this.cwsm.cs = res.data.cs || [];
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message({
          message: "请先选择区域",
          type: "warning"
        });
      }
    },
    // 为空
    bempty() {
      this.multipleSelection = [];
      this.isIndeterminate = false;
      this.checkAll = false;
    },

    // 添加商品
    bindingPrdHandle() {
      this.choosePrdDrawer.showDrawer = true;
      this.getPrdCategoryAndPrdList(1);
    },

    // 获取商品分类和商品列表
    async getPrdCategoryAndPrdList(isInit = 0) {
      const params = {
        name: this.choosePrdDrawer.keyword.toString(), //      string  关键字
        page_num: this.choosePrdDrawer.page * 1, //  int   页码
        page_size: this.choosePrdDrawer.pageSize, //  int    每页显示数量
        is_init: isInit * 1, //    int     是否初始化 1:初始化
        one_cate_id: this.choosePrdDrawer.cateVal[0], // int64   一级分类
        two_cate_id: this.choosePrdDrawer.cateVal[1] // int64   二级分类
      };

      try {
        const res = await this.$api.BMS.region.reqGetPrdCateAndPrdList(params);
        if (res.code == 1) {
          if (isInit == 1) {
            const cateOptions = res.data.cates || [];
            cateOptions.forEach(el => {
              el.value = el.id;
              el.label = el.n;
              if (el.ss) {
                el.ss.forEach(ele => {
                  ele.value = ele.id;
                  ele.label = ele.n;
                });
                el.children = el.ss;
              }
            });

            this.choosePrdDrawer.cateOptions = cateOptions;
          }
          const tableData = res.data.items || [];

          this.choosePrdDrawer.loadingText =
            tableData.length == this.choosePrdDrawer.pageSize
              ? "加载中..."
              : "没有更多数据了";

          this.choosePrdDrawer.tableData =
            isInit == 1
              ? tableData.map(item => ({
                  ...item,
                  checked: item.id == this.formPrdInfo.id
                }))
              : [
                  ...this.choosePrdDrawer.tableData,
                  ...tableData.map(item => ({
                    ...item,
                    checked: item.id == this.formPrdInfo.id
                  }))
                ];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取相关数据失败", error);
      }
    },

    // 重置筛选商品条件
    resetSelectHandle() {
      this.choosePrdDrawer.cateVal = [0, 0];
      this.choosePrdDrawer.keyword = "";
      this.getPrdCategoryAndPrdList(1);
    },

    changeCheckBoxHandle(itemInfo) {
      this.choosePrdDrawer.tableData.forEach(el => {
        if (el.id != itemInfo.id) {
          el.checked = false;
        }
      });
    },

    // 提交选择好的商品
    submitChoosePrdHandle() {
      const selectedPrdInfo = this.choosePrdDrawer.tableData.find(
        item => item.checked
      );
      if (selectedPrdInfo) {
        this.formPrdInfo = selectedPrdInfo;
        this.choosePrdDrawer.showDrawer = false;
      } else {
        this.$message.warning("请选择需要添加的商品");
      }
    },

    // tobody滚动监听
    tbodyScrollHandle(e) {
      const dom = document.querySelector(".tbody");
      const domHeight = dom.getBoundingClientRect().height;
      const scrollTop = dom.scrollTop;
      const containHeight = document
        .querySelector(".tbody-contain")
        .getBoundingClientRect().height;
      if (containHeight - domHeight - scrollTop <= 10) {
        // 到底部了
        this.choosePrdDrawer.page += 1;
        this.getPrdCategoryAndPrdList();
      }
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
    }
  }
};
</script>
<style>
/* 靠右 */
.region .el-dialog {
  margin: 0px 0px 0px auto !important;
  background-color: #f9f9f9;
  height: 100%;
  position: relative;
}

.region .el-dialog__footer {
  position: absolute;
  width: 100%;
  bottom: 0;
  right: 0;
  display: flex;
  justify-content: center;
}

.region .el-dialog__body {
  padding: 0px 0px 30px 20px;
  overflow-y: scroll !important;
  /* width: 100%; */
  width: calc(100% - 20px);
  height: calc(100% - 160px);
  max-height: calc(100% - 160px);
  margin: 0;
}

.region .el-dialog {
  box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1);
}

.region {
  width: calc(100% - 40px);
  height: calc(100% - 40px);
  padding: 20px 30px;
}

/* 必填 */
.region .mandatory {
  color: #40404e;
  width: 140px;
  text-align: right;
}

.region .controlling {
  color: #40404e;
  width: 230px !important;
}

.region .reqfieldsd {
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
.region .tiaodd {
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

.region .nodata {
  width: 100% !important;
  height: 250px !important;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: 0;
}

.region .nodata img {
  width: 60px;
  height: 60px;
}

.region .nodata .hint {
  line-height: 36px;
  font-size: 13px !important;
}

/* 改限制字体数量的颜色背景 */
.region .el-input .el-input__count .el-input__count-inner {
  background: none;
  color: #40404e;
}

.region .compatibility {
  display: flex;
  align-items: center;
  margin-bottom: 10px;
}

.region-headline {
  font-size: 30px;
  font-weight: bold;
  color: #40404e;
}

.region-controller {
  /*margin-top: 30px;*/
  height: 54px;
  width: 100%;
  background-color: #eee;
  display: flex;
  align-items: center;
}

.region .dialogFormVisible .el-dialog {
  width: 550px !important;
}

/* 必填 */
.seats .region .mandatory {
  padding-top: 0;
}

.region .el-dialog .el-button--default {
  background-color: #ccc !important;
  border: 1px solid #ccc !important;
  color: #40404e !important;
}

.region .el-dialog {
  background-color: #1a1a20;
}

.region .el-dialog__header,
.region .el-dialog__footer {
  background-color: #1a1a21;
}

.region .el-dialog__title,
.region .el-dialog__headerbtn .el-dialog__close,
.region .el-form-item__label {
  color: #1a1a21;
}

.region .el-checkbox__input {
  background-color: transparent;
}

.region .el-dialog {
  width: 30vw;
}

/* 改变多选框背景颜色和上下间距 */
.region .el-checkbox-group {
  display: flex;
  align-items: flex-end;
  justify-content: center;
}

.region .el-checkbox__input {
  background-color: transparent;
}

/* 列表 */
.zsykd {
  width: 100%;
  overflow-x: scroll !important;
}

.region .zhuixiaoi {
  width: 1400px;
  border-collapse: collapse;
  color: #40404e;
}

.region .zhuixiaoi .mmodity tr th {
  height: 36px;
  line-height: 36px;
  text-align: left;
  font-size: 14px;
  font-weight: 600;
  padding-left: 20px;
  color: #1a1a21;
}

.region .zhuixiaoi .mmodity tr th .el-checkbox__label {
  font-weight: 600;
  font-size: 14px;
  color: #1a1a21;
}

.region .zhuixiaoi .limiting .drag-list td {
  height: 36px;
  line-height: 36px;
  text-align: left;
  font-size: 14px;
  font-weight: 400;
  padding-left: 20px;
}

.region .zhuixiaoi .limiting .drag-list {
  display: block;
  display: flex;
}

.region .zhuixiaoi .mmodity {
  width: 100%;
  display: block;
}

.region .zhuixiaoi .mmodity tr {
  background-color: #f5f5f5;
  display: flex;
}

.region .zhuixiaoi .limiting {
  overflow-y: auto !important;
  max-height: 540px;
  display: block;
}

.region .drag-list td:nth-of-type(1),
.region .mmodity th:nth-of-type(1) {
  width: 70px;
}

.region .mmodity th:nth-of-type(2),
.region .drag-list td:nth-of-type(2) {
  width: 240px;
}

.region .drag-list td:nth-of-type(3),
.region .mmodity th:nth-of-type(3) {
  width: 140px;
}

.region .drag-list td:nth-of-type(4),
.region .mmodity th:nth-of-type(4) {
  width: 140px;
}

.region .drag-list td:nth-of-type(5),
.region .mmodity th:nth-of-type(5) {
  width: 140px;
}

.region .drag-list td:nth-of-type(6),
.region .mmodity th:nth-of-type(6) {
  width: 60px;
}

.region .drag-list:nth-of-type(odd) {
  background-color: #f9f9f9;
  color: #40404e;
}

.region .drag-list:nth-of-type(even) {
  background-color: #f5f5f5;
  color: #40404e;
}

/* 全选颜色 */
.region .zhuixiaoi .el-checkbox__label {
  color: #40404e;
}

.region .zhuixiaoi .mmodity .el-checkbox__label {
  font-size: 12px;
}

/* 错误2 */
.region .diagrgeesfelogFor .el-dialog {
  width: 720px;
  box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1);
}

.region .diagrgeesfelogFor .wwent {
  color: #ce4153;
  font-size: 14px;
  margin: 20px 0px 20px 20px;
  display: flex;
  align-items: center;
}

.region .diagrgeesfelogFor .wentlb {
  margin-left: 20px;
  width: 640px;
}

.region .diagrgeesfelogFor .zhuixiaoi {
  width: 100%;
}

.region .diagrgeesfelogFor .zhuixiaoi .limiting {
  max-height: 280px !important;
  overflow-y: auto !important;
}

.region .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(1),
.region .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(1) {
  width: 50px;
}

.region .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(2),
.region .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(2) {
  width: 320px;
}

.region .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(3),
.region .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(3) {
  width: 200px;
}

.region .diagrgeesfelogFor .danykz .mmodity th:nth-of-type(2),
.region .diagrgeesfelogFor .danykz .drag-list td:nth-of-type(2) {
  width: 520px;
}

/* 无效颜色 */
.region .diagrgeesfelogFor .el-button--primary.is-disabled,
.region .diagrgeesfelogFor .el-button--primary.is-disabled:hover {
  background-color: #1f2846;
  color: #4e505a;
  border-color: #1f2846;
}
</style>

<style>
/* 选择必点商品 */
.region .user-defined .el-dialog {
  width: 850px !important;
}

.region .user-defined .explain {
  margin-top: 20px;
  color: #ce4153;
  font-size: 12px;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.region .user-defined .el-form {
  padding-top: 20px !important;
}

.region .user-defined .attribute {
  width: 350px;
  display: flex;
  flex-direction: column;
}

.region .user-defined .el-input {
  width: 230px;
}

.region .user-defined .el-form-item__content {
  display: flex;
  margin-bottom: 10px;
}

.region .user-defined .compatibil .compatibility {
  align-items: flex-start;
}

.region .user-defined .compatibil .compatibility .el-button {
  width: 40px;
  height: 40px;
  margin-left: 10px;
}

.region .user-defined .zhuixiaoi {
  min-width: 802px !important;
  width: 802px;
  overflow: hidden;
  display: inline-block;
}

.region .user-defined .drag-list td:nth-of-type(1),
.region .user-defined .mmodity th:nth-of-type(1) {
  width: 70px;
}

.region .user-defined .drag-list td:nth-of-type(2),
.region .user-defined .mmodity th:nth-of-type(2) {
  width: 240px;
}

.region .user-defined .drag-list td:nth-of-type(3),
.region .user-defined .mmodity th:nth-of-type(3) {
  width: 300px;
}

.region .user-defined .drag-list td:nth-of-type(4),
.region .user-defined .mmodity th:nth-of-type(4) {
  width: 70px;
}

.region .user-defined .tbody {
  height: calc(100vh - 260px) !important;
  max-height: calc(100vh - 260px) !important;
  overflow-y: auto;
}

.region .user-defined tr {
  width: 750px;
}
.region .user-defined tr th:nth-child(1),
.region .user-defined tr td:nth-child(1) {
  width: 80px !important;
}
.region .user-defined tr th:nth-child(2),
.region .user-defined tr td:nth-child(2) {
  width: 150px !important;
}
.region .user-defined tr th:nth-child(3),
.region .user-defined tr td:nth-child(3) {
  width: 250px !important;
}
.region .user-defined tr th:nth-child(4),
.region .user-defined tr td:nth-child(4) {
  width: 80px !important;
}
.region .user-defined tr th:nth-child(5),
.region .user-defined tr td:nth-child(5) {
  width: 80px !important;
}
.region .user-defined tr th:nth-child(6),
.region .user-defined tr td:nth-child(6) {
  width: 100px !important;
}
.region .user-defined tr th:nth-child(7),
.region .user-defined tr td:nth-child(7) {
  width: 80px !important;
}
</style>

