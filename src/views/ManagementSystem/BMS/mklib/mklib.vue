<template>
  <div class="mklib">
    <div class="zsykd" style="display: inline-block;">
      <table class="zhuixiaoi" style="min-width: 1191px;">
        <div class="mklib-controller">
          <icon-button @click.native="productionlibrary" text="新增出品库" img="btn_add.png" colors="#f5f5f5"></icon-button>
          <icon-button @click.native="compileprinter" text="编辑" img="btn_edit.png" colors="#f5f5f5"></icon-button>
          <icon-button @click.native="noneffective" text="置为无效" img="btn_in_vain.png" colors="#f5f5f5"></icon-button>
          <icon-button @click.native="effective" text="置为有效" img="btn_effective.png" colors="#f5f5f5"></icon-button>
          <icon-button
            @click.native="printerdel"
            text="批量删除"
            img="btn_delete.png"
            colors="#6B2830"
            bjcolors="#491E24"
          ></icon-button>
        </div>
        <thead class="mmodity">
          <tr>
            <th>
              <el-checkbox
                :indeterminate="isIndeterminate"
                v-model="checkAll"
                @change="handleCheckAllChange"
              >全选&ensp;</el-checkbox>
            </th>
            <th>出品库名称</th>
            <th>存货仓库名称</th>
            <th>出品打印机名称</th>
            <th>出品打印次数</th>
            <th>传菜打印名称</th>
            <th>传菜打印次数</th>
            <th>创建时间</th>
            <th>更新时间</th>
            <th>状态</th>
          </tr>
        </thead>
        <tbody
          class="limiting"
          :style="{'border-bottom':Product.length<1?'0px':'',
                'width':Product.length>MaxNumber?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`}"
        >
          <tr
            v-for="(item,i) in Product"
            :key="item.id"
            class="drag-list"
            :class="multipleSelection.includes(item.id)? 'drag-list-check':''"
          >
            <td :style="{'color':item.s=='无效'?'#595959':''}">
              <el-checkbox-group v-model="multipleSelection" @change="handleCheckedCitiesChange">
                <el-checkbox :label="item.id">{{i+1}}&emsp;&ensp;</el-checkbox>
              </el-checkbox-group>
            </td>
            <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.n}}</td>
            <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.sn}}</td>
            <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.pn}}</td>
            <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.pc}}</td>
            <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.cn}}</td>
            <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.cc || '-'}}</td>
            <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.c}}</td>
            <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.u}}</td>
            <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.s}}</td>
          </tr>
        </tbody>
      </table>
      <div class="drag-list" v-if="Product.length<1">
        <td class="nodata" :style="{'height':`${MaxHeight}px !important`}">
          <img src="@/assets/img/wu.png" alt />
          <div class="hint">暂无数据</div>
        </td>
      </div>
    </div>

    <!-- 新建出品库 -->
    <div class="dialogPrinter" v-show="dialogPrinter">
      <el-dialog
        :title="compileprinterss?'新建出品库':'编辑出品库'"
        :visible.sync="dialogPrinter"
        @close="ManufactureDeselect"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>出品库名称：
              </div>
              <el-input
                v-model="mklib.name"
                ref="selectsse"
                placeholder="请输入出品库名称"
                class="controlling"
                :class="form_rule_msg_name?'error':''"
                @blur="validator('name')"
              />
              <div class="cwts">{{form_rule_msg_name}}</div>
            </div>
          </div>
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>存货仓库名称：
              </div>
              <el-select v-model="mklib.stores" placeholder="请选择存货仓库" class="controlling">
                <el-option v-for="(each,i) in stores" :key="i" :label="each.n" :value="each.id +''"></el-option>
                <!-- <el-option label="--新增打印机--" value="新增1"></el-option> -->
              </el-select>
            </div>
            <!-- <div class="layouts">用于打印出品单</div>                 -->
          </div>
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>出品打印机名称：
              </div>
              <el-select v-model="mklib.printername" placeholder="请选择打印机" class="controlling">
                <el-option
                  v-for="(each,i) in printernr"
                  :key="i"
                  :label="each.n"
                  :value="each.id +''"
                ></el-option>
                <el-option label="--新增打印机--" value="新增1"></el-option>
              </el-select>
            </div>
            <div class="layouts">用于打印出品单</div>
          </div>
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>出品打印份数：
              </div>
              <el-form-item class="controlling">
                <el-input-number v-model="mklib.ProducePrintCopies" :disabled="disableds[0]" />
              </el-form-item>
            </div>
            <div class="layouts">如没有选择选择打印机则不能改份数，打印份数要在[1,3]范围内</div>
          </div>
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>单品是否分页打印：
              </div>
              <el-form-item>
                <el-radio v-model="mklib.WhetherPagingPrint" label="2">否</el-radio>
                <el-radio v-model="mklib.WhetherPagingPrint" label="1">是</el-radio>
              </el-form-item>
              <span class="preview" @click="PagingPreview = true">查看预览</span>
            </div>
          </div>
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>传菜打印机名称：
              </div>
              <el-select
                clearable 
                v-model="mklib.PantryHelperPrinter"
                placeholder="请选择打印机"
                class="controlling"
              >
                <el-option
                  v-for="(each,i) in printernr"
                  :key="i"
                  :label="each.n"
                  :value="each.id +''"
                ></el-option>
                <el-option label="--新增打印机--" value="新增2"></el-option>
              </el-select>
            </div>
            <div class="layouts">用于打印传菜单，方便传菜人员核单</div>
          </div>
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>传菜打印份数：
              </div>
              <el-form-item class="controlling">
                <el-input-number v-model="mklib.PantryHelperCopies" :disabled="disableds[1]" />
              </el-form-item>
            </div>
            <div class="layouts">如没有选择选择打印机则不能改份数，打印份数要在[1,3]范围内</div>
          </div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="ManufactureDeselect">取消</el-button>
          <el-button v-show="compileprinterss" type="primary" @click="EstablishMake">确认</el-button>
          <el-button v-show="!compileprinterss" type="primary" @click="saveprinter">保存</el-button>
        </span>
      </el-dialog>
    </div>
    <!-- 新建打印机 -->
    <div v-show="dialogFormVisible" class="dialogFormVisible">
      <el-dialog
        title="新建打印机"
        :visible.sync="dialogFormVisible"
        @close="PrinterCancel"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div class="compatibility">
            <div class="mandatory">
              <span class="reqfieldsd">*</span>打印机名称：
            </div>
            <el-input
              v-model="printer.printername"
              ref="selectsse"
              placeholder="请输入打印机名称"
              class="controlling"
            />
          </div>
          <div class="compatibility">
            <div class="mandatory">
              <span class="reqfieldsd">*</span>IP地址：
            </div>
            <el-input v-model="printer.printerIP" placeholder="请输入打印机ID地址" class="controlling" />
          </div>
        </el-form>
        <div class="layouts">IP地址格式为：a.b.c.d;其中a,b,c,d均为0-254的数字</div>
        <span slot="footer" class="dialog-footer">
          <el-button @click="PrinterCancel">取消</el-button>
          <el-button type="primary" @click="construction">确认</el-button>
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

    <!-- 分页预览 -->
    <div class="Pagingss" v-show="PagingPreview">
      <el-dialog title="预览" :visible.sync="PagingPreview" :close-on-click-modal="false">
        <div class="Pagingll">
          <div class="NoPaging">
            <div class="headline">不分页打印</div>
            <div class="content">
              <div class="appearancefee">
                <div class="bold p-b-2 fs18">[卡座区] K001</div>
                <div layout="row" layout-align="space-between center">
                  <span>人数：10</span>
                  <span>服务员：000000 系统管理员</span>
                </div>
              </div>
              <div class="cuisine" layout="row" layout-align="space-between center">
                <div>雪花啤酒</div>
                <div style="width:150px;text-align:right">¥10.00</div>
                <div class="bold fs20">1</div>
              </div>
              <div class="cuisine" layout="row" layout-align="space-between center">
                <div>青岛啤酒</div>
                <div style="width:150px;text-align:right">¥10.00</div>
                <div class="bold fs20">1</div>
              </div>
              <div class="totalmoney">
                <div>
                  <div>总金额：¥20.00元</div>
                  <div>总数：2（2道）</div>
                </div>
                <div class="m-b-1">下单时间：2023-02-06 21:50:20</div>
                <div class="m-b-1">打印时间：2023-02-06 21:50:20</div>
                <div>[大厅出品库]</div>
              </div>
            </div>
          </div>
          <div class="NoPaging">
            <div class="headline">分页打印</div>
            <div class="content">
              <div class="appearancefee">
                <div class="bold p-b-2 fs18">[卡座区] K001</div>
                <div layout="row" layout-align="space-between center">
                  <span>人数：10</span>
                  <span>服务员：000000 系统管理员</span>
                </div>
              </div>
              <div class="cuisine" layout="row" layout-align="space-between center">
                <div>雪花啤酒</div>
                <div style="width:150px;text-align:right">¥10.00</div>
                <div class="bold fs20">1</div>
              </div>
              <div class="totalmoney">
                <div>
                  <div>总金额：¥10.00元</div>
                  <div>总数：1（1道）</div>
                </div>
                <div class="m-b-1">下单时间：2023-02-06 21:50:20</div>
                <div class="m-b-1">打印时间：2023-02-06 21:50:20</div>
                <div>[大厅出品库]</div>
              </div>
            </div>
            <div class="content">
              <div class="appearancefee">
                <div class="bold p-b-2 fs18">[卡座区] K001</div>
                <div layout="row" layout-align="space-between center">
                  <span>人数：10</span>
                  <span>服务员：000000 系统管理员</span>
                </div>
              </div>
              <div class="cuisine" layout="row" layout-align="space-between center">
                <div>青岛啤酒</div>
                <div style="width:150px;text-align:right">¥10.00</div>
                <div class="bold fs20">1</div>
              </div>
              <div class="totalmoney">
                <div>
                  <div>总金额：¥10.00元</div>
                  <div>总数：1（1道）</div>
                </div>
                <div class="m-b-1">下单时间：2023-02-06 21:50:20</div>
                <div class="m-b-1">打印时间：2023-02-06 21:50:20</div>
                <div>[大厅出品库]</div>
              </div>
            </div>
          </div>
        </div>
        <span slot="footer" class="dialog-footer">
          <el-button @click="PagingPreview = false">关闭</el-button>
        </span>
      </el-dialog>
    </div>
  </div>
</template>
<script>
import IconButton from "@/components/IconButton.vue"; //根据路径导入组件
import EllipsisTooltip from "@/components/EllipsisTooltip.vue"; //根据路径导入组件
import CharactersButton from "@/components/CharactersButton.vue"; //根据路径导入组件
export default {
  data() {
    return {
      Product: [], //出品库目录
      dialogPrinter: false, //控制新增出品库是否显示
      dialogFormVisible: false, //控制新建打印机是否显示
      printernr: [], //打印机内容
      stores: [], //存货仓库内容

      multipleSelection: [], // 选中的内容
      isIndeterminate: false, // 供应商选择一部分
      checkAll: false, //供应商全选

      mklib: {
        name: "", //出品库名称
        stores: "", //存货仓库
        printername: "", //列表打印机ID
        ProducePrintCopies: "1", // 出品打印份数
        WhetherPagingPrint: "2", //是否分页打印
        PantryHelperPrinter: "", //传菜打印机ID
        PantryHelperCopies: "1" //传菜打印份数
      }, //出品库
      printer: {
        printername: "", //打印机名称
        printerIP: "", //打印机IP
        printerID: "" //打印机ID
      }, //打印机
      compileprinterss: false, //控制是编辑还是新建
      PagingPreview: false, //分页预览
      estimateoneortwo: 0, //判断第几个选的新建打印机
      disableds: [true, true], //判断哪个能选份数哪个不能选
      quantity: [], // 判断哪个要亮
      windowWidt: document.documentElement.clientWidth, //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight, //实时屏幕高度
      MaxHeight: 0, //滚动高度
      MaxNumber: 0, //最大个数

      dialogFible: false, //控制错误2是否显示
      srnr: "", //文案
      cwsm: {
        ns: [], //不可操作列表
        cs: [] //可一键操作列表
      }, //错误2说明
      kzsfjy: false, //控制同步按钮是否禁用

      form_rules: ["name"],
      form_rule_msg_name: ""
    };
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
  components: {
    EllipsisTooltip,
    IconButton,
    CharactersButton
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
  methods: {
    // form表单检测
    validator(val) {
      switch (val) {
        case "name":
          if (this.mklib.name == "") {
            this.form_rule_msg_name = "请输入出品库名称";
          } else if (this.$overall.character(this.mklib.name) > 20) {
            this.form_rule_msg_name = "输入文字长度超过10";
          } else {
            this.form_rule_msg_name = "";
          }
          break;
      }
    },
    // 滚动最大高度
    RollMaxHeight(i) {
      var s = i - 48 - 60 - 55 - 37;
      this.MaxHeight = s;
      this.MaxNumber = Math.floor(s / 37);
      console.log(this.MaxNumber);
      // console.log(i);
    },
    //获取焦点
    edit() {
      this.$nextTick(() => {
        //次要代码
        this.$refs.selectsse.focus();
        console.log(this.$refs);
      });
    },
    // 为空
    ktsewf() {
      this.multipleSelection = [];
      this.isIndeterminate = false;
      this.checkAll = false;
    },
    // 获取打印机出品库内容 标记
    demand() {
      this.$api.BMS.mklib.requestmkliblist().then(res => {
        console.log(res);
        if (res.code == 1) {
          this.Product = res.data || [];
          this.$api.BMS.mklib.requestmklibget({ id: 0 }).then(rese => {
            console.log(rese);
            if ((rese.code = 1)) {
              console.log(rese.data);
              this.printernr = rese.data.prts || [];
              this.stores = rese.data.stores || [];
            }
          });
        } else {
          this.$message.warning(res.msg);
        }
      });
    },
    // 选择全选或取消
    handleCheckAllChange(val) {
      if (val) {
        this.multipleSelection = [];
        for (const key in this.Product) {
          this.multipleSelection.push(this.Product[key].id);
        }
      } else {
        this.multipleSelection = [];
      }
      this.isIndeterminate = false;
    },
    // 控制单个选中
    handleCheckedCitiesChange(value) {
      let checkedCount = value.length;
      this.checkAll = checkedCount === this.Product.length;
      this.isIndeterminate =
        checkedCount > 0 && checkedCount < this.Product.length;
    },
    // 创建打印机
    construction() {
      if (this.printer.printername == "" || this.printer.printerIP == "") {
        this.$message.warning("必选框不能为空");
      } else {
        this.$api.BMS.mklib
          .requestmklibnew_printer({
            name: this.printer.printername,
            ip_addr: this.printer.printerIP,
            type_id: 1 // 1 普通打印机
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
              console.log(this.estimateoneortwo);
              if (this.estimateoneortwo == 1) {
                this.mklib.printername = res.data + "" || "";
              }
              if (this.estimateoneortwo == 2) {
                this.mklib.PantryHelperPrinter = res.data + "" || "";
              }
              this.dialogFormVisible = false;
              this.estimateoneortwo = 0;
            } else {
              this.$message.warning(res.msg);
            }
          });
      }
    },
    // 打开新增出品库
    productionlibrary() {
      this.form_rule_msg_name = "";
      this.dialogPrinter = true;
      this.producezero();
      this.edit();
      this.compileprinterss = true;
      this.$api.BMS.mklib.requestmklibget({ id: 0 }).then(rese => {
        console.log(rese);
        if ((rese.code = 1)) {
          console.log(rese.data);
          this.printernr = [];
          this.stores = [];
          if (rese.data.prts != null) {
            for (const key in rese.data.prts) {
              if (rese.data.prts[key].s == 1) {
                this.printernr.push(rese.data.prts[key]);
              }
            }
          }
          if (rese.data.stores != null) {
            for (const key in rese.data.stores) {
              if (rese.data.stores[key].s == 1) {
                this.stores.push(rese.data.stores[key]);
              }
            }
          }
        } else {
          this.$message.warning(res.msg);
        }
      });
    },
    // 创建出品库
    EstablishMake() {
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_name) return;
      if (this.mklib.name == "" || this.mklib.printername == "") {
        this.$message.warning("必选框不能为空");
      } else {
        console.log(this.mklib);

        this.$api.BMS.mklib
          .requestmklibnew({
            name: this.mklib.name,
            cp_prt_id: parseInt(this.mklib.printername),
            cp_prt_cnt: parseInt(this.mklib.ProducePrintCopies),
            cp_prt_split: parseInt(this.mklib.WhetherPagingPrint),
            cc_prt_id: parseInt(this.mklib.PantryHelperPrinter) || "",
            cc_prt_cnt: parseInt(this.mklib.PantryHelperPrinter) ? parseInt(this.mklib.PantryHelperCopies) : 0,
            store_id: parseInt(this.mklib.stores)
          })
          .then(res => {
            console.log(res);
            if (res.code == 1 || res.code == 6) {
              if (res.msg === '') {
                this.$message({
                  showClose: true,
                  message: "操作成功",
                  type: "success"
                });
              } else {
                this.$message({
                  showClose: true,
                  message: res.msg,
                  type: "warning"
                });
              }
              this.demand();
              this.dialogPrinter = false;
              this.producezero();
              this.ktsewf();
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
        this.$api.BMS.mklib
          .requestmklibget({ id: this.multipleSelection[0] })
          .then(res => {
            console.log(res);
            if (res.code == 1) {
              this.mklib.name = res.data.mklib.name;
              this.mklib.printername = res.data.mklib.cp_prt_id + "";
              this.mklib.ProducePrintCopies = res.data.mklib.cp_prt_cnt;
              this.mklib.WhetherPagingPrint = res.data.mklib.cp_prt_split.toString();
              this.mklib.PantryHelperPrinter =
                res.data.mklib.cc_prt_id == 0
                  ? ""
                  : res.data.mklib.cc_prt_id + "";
              (this.mklib.PantryHelperCopies = res.data.mklib.cc_prt_cnt),
                (this.mklib.stores = res.data.mklib.store_id + "");
              // console.log(res);
              this.dialogPrinter = true;
              this.compileprinterss = false;

              this.printernr = [];
              this.stores = [];
              for (const key of this.Product) {
                if (this.multipleSelection[0] == key.id) {
                  console.log(key);
                  if (key.s == "无效") {
                    this.printernr = res.data.prts || [];
                    this.stores = res.data.stores || [];
                  } else {
                    if (res.data.prts != null) {
                      for (const key in res.data.prts) {
                        if (res.data.prts[key].s == 1) {
                          this.printernr.push(res.data.prts[key]);
                        }
                      }
                    }
                    if (res.data.stores != null) {
                      for (const key in res.data.stores) {
                        if (res.data.stores[key].s == 1) {
                          this.stores.push(res.data.stores[key]);
                        }
                      }
                    }
                  }
                }
              }
            } else {
              this.$message({
                message: res.msg,
                type: "warning"
              });
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
      this.$api.BMS.mklib
        .requestmklibsave({
          id: this.multipleSelection[0],
          name: this.mklib.name,
          cp_prt_id: parseInt(this.mklib.printername),
          cp_prt_cnt: parseInt(this.mklib.ProducePrintCopies),
          cp_prt_split: parseInt(this.mklib.WhetherPagingPrint),
          cc_prt_id: parseInt(this.mklib.PantryHelperPrinter),
          cc_prt_cnt: parseInt(this.mklib.PantryHelperPrinter) ? parseInt(this.mklib.PantryHelperCopies) : 0,
          store_id: parseInt(this.mklib.stores)
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
            this.dialogPrinter = false;
            this.producezero();
            this.ktsewf();
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
      this.$api.BMS.mklib
        .requestMklibOb({
          op_status: Number(s),
          type_ids: tid,
          ids: id
        })
        .then(res => {
          if (res.code == 1) {
            for (const key in this.cwsm.cs) {
              this.cwsm.cs[key].jg = "成功";
            }
            // this.refresh(this.$route.params.id);
            this.chdefrs();
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
    // 无效
    noneffective() {
      this.$api.BMS.mklib
        .requestmklibdisable({ ids: this.multipleSelection })
        .then(res => {
          // console.log(res);
          if (res.code == 1) {
            this.demand();
            this.ktsewf();
            this.dialogFible = false;
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
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
      this.$api.BMS.mklib
        .requestmklibenable({ ids: this.multipleSelection })
        .then(res => {
          // console.log(res);
          if (res.code == 1) {
            this.demand();
            this.ktsewf();
            this.dialogFible = false;
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
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
      // console.log(this.multipleSelection)
      if (this.multipleSelection.length > 0) {
        this.$api.BMS.mklib
          .requestmklibdel({ ids: this.multipleSelection })
          .then(res => {
            // console.log(res);
            if (res.code == 1) {
              this.demand();
              this.ktsewf();
              this.dialogFible = false;
              this.$message({
                showClose: true,
                message: "操作成功",
                type: "success"
              });
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
          message: "请先选择出品库",
          type: "warning"
        });
      }
    },
    // 新增打印机取消新增
    PrinterCancel() {
      this.dialogFormVisible = false;
      if (this.estimateoneortwo == 1) {
        this.mklib.printername = "";
      } else if (this.estimateoneortwo == 2) {
        this.mklib.PantryHelperPrinter = "";
      }
    },
    // 新增出品库取消新增  内容全部归零
    ManufactureDeselect() {
      this.dialogPrinter = false;
      this.producezero();
    },
    // 出品库归零
    producezero() {
      this.mklib.name = "";
      this.mklib.printername = "";
      this.mklib.ProducePrintCopies = "1";
      this.mklib.WhetherPagingPrint = "2";
      this.mklib.PantryHelperPrinter = "";
      this.mklib.PantryHelperCopies = "1";
      this.mklib.stores = "";
    }
  },
  computed: {
    Produary() {
      return JSON.parse(JSON.stringify(this.mklib));
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
    // 监听是否选中了新增打印机
    Produary: {
      deep: true,
      handler: function(after, before) {
        // 判断选中了没打印机  没有选中则不能改变份数
        // console.log(after.ProducePrintCopies);
        // console.log(after.PantryHelperCopies);
        if (after.ProducePrintCopies > "3") {
          this.mklib.ProducePrintCopies = "3";
          this.$message.warning("打印份数不在[1,3]范围内");
        } else if (after.ProducePrintCopies < "1") {
          this.mklib.ProducePrintCopies = "1";
          this.$message.warning("打印份数不在[1,3]范围内");
        }
        if (after.PantryHelperCopies > "3") {
          this.mklib.PantryHelperCopies = "3";
          this.$message.warning("打印份数不在[1,3]范围内");
        } else if (after.PantryHelperCopies < "1") {
          this.mklib.PantryHelperCopies = "1";
          // this.$message.warning("打印份数不在[1,3]范围内");
        }
        if (after.printername != "") {
          this.disableds[0] = false;
          // if(before.ProducePrintCopies != "0"){
          //     this.mklib.ProducePrintCopies = after.ProducePrintCopies
          // }
        } else {
          this.disableds[0] = true;
        }
        if (after.PantryHelperPrinter != "") {
          this.disableds[1] = false;
          // if(before.PantryHelperCopies != "0"){
          //     this.mklib.PantryHelperCopies = after.PantryHelperCopies
          // }
        } else {
          this.disableds[1] = true;
        }
        if (after.printername == "新增1") {
          this.dialogFormVisible = true;
          this.estimateoneortwo = 1;
          this.printer.printername = "";
          this.printer.printerIP = "";
        }
        console.log(after.PantryHelperPrinter);
        if (after.PantryHelperPrinter == "新增2") {
          console.log("-------");
          this.dialogFormVisible = true;
          this.estimateoneortwo = 2;
          this.printer.printername = "";
          this.printer.printerIP = "";
        }
      }
    }
  }
};
</script>
<style>
/* 靠右 */
.mklib .el-dialog {
  margin: 0px 0px 0px auto !important;
  background-color: #f9f9f9;
  height: 100%;
  position: relative;
}

.mklib .el-dialog__footer {
  position: absolute;
  width: 100%;
  bottom: 0;
  right: 0;
  display: flex;
  justify-content: center;
}

.mklib .el-dialog__body {
  padding: 0px 0px 30px 20px;
  overflow-y: scroll !important;
  /* width: 100%; */
  width: calc(100% - 40px);
  height: calc(100% - 160px);
  max-height: calc(100% - 160px);
  margin: 0;
}

.mklib .el-dialog {
  box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1);
}

.mklib {
  width: calc(100% - 40px);
  height: calc(100% - 40px);
  padding: 20px 30px;
}

/* 必填 */
.mklib .mandatory {
  color: #40404e;
  width: 200px;
  text-align: right;
}

.mklib .controlling {
  color: #40404e;
  width: 230px !important;
}

.mklib .reqfieldsd {
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
.mklib .tiaodd {
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

.mklib .nodata {
  width: 100% !important;
  height: 250px !important;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: 0;
}

.mklib .nodata img {
  width: 60px;
  height: 60px;
}

.mklib .nodata .hint {
  line-height: 36px;
  font-size: 13px !important;
}

/* 改变多选框背景颜色和上下间距 */
.mklib .el-checkbox-group {
  display: flex;
  align-items: flex-end;
  justify-content: left;
}

.mklib .el-checkbox__input {
  background-color: rgba(0, 0, 0, 0);
}

/* 全选颜色 */
.mklib .zhuixiaoi .el-checkbox__label {
  color: #40404e;
}

.mklib .zhuixiaoi .mmodity .el-checkbox__label {
  font-size: 12px;
}

.mklib-headline {
  font-size: 30px;
  font-weight: bold;
  color: #40404e;
}

.mklib-controller {
  /*margin-top: 30px;*/
  height: 54px;
  /*width: 1600px;*/
  background-color: #eee;
  display: flex;
  align-items: center;
}

.mklib .dialogFormVisible .layouts {
  font-size: 12px;
  margin-left: 83px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.mklib .layouts {
  margin-left: 200px;
  font-size: 12px;
  /* margin-bottom: 5px; */
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.mklib .preview {
  color: #409eff;
  font-size: 14px;
  margin-left: 65px;
  cursor: pointer;
}

.mklib .Pagingll {
  /* color: #40404e; */
  color: #000;
  display: flex;
  justify-content: space-evenly;
}

.mklib .NoPaging {
  font-size: 14px;
  margin: 10px;
}

.mklib .headline {
  color: #40404e;
  text-align: center;
  margin-bottom: 10px;
}

.mklib .content {
  width: 350px;
  border: 1px solid #40404e;
  padding: 10px 8px;
  margin-bottom: 20px;
  background-color: #fff;
}

.mklib .appearancefee {
  padding-bottom: 7px;
  border-bottom: 1px dashed #000;
  color: #000;
}

.mklib .bold{
  font-weight: 600;
}

.mklib .cuisine {
  padding: 7px;
  border-bottom: 1px dashed #000;
  color: #000;
}

.mklib .cuisine div:nth-of-type(1) {
  font-size: 17px;
  padding: 5px 0;
}

.mklib .totalmoney div:nth-of-type(1) {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin: 4px 0 6px;
  color: #000;
}

.mklib .Pagingss .el-dialog {
  margin-top: 6vh;
  margin-bottom: 0;
  width: 50vw !important;
  min-width: 800px !important;
  max-width: 800px !important;
}

.mklib .Pagingss .el-dialog__body {
  padding: 10px 20px;
}

.mklib .Pagingss .el-dialog__footer {
  padding-bottom: 10px;
}

.mklib .Pagingss .el-dialog__header {
  padding-top: 10px;
}

.mklib .dialogPrinter .el-dialog {
  width: 720px;
}

.mklib .dialogFormVisible .el-dialog {
  width: 50vw !important;
  min-width: 420px !important;
  max-width: 440px !important;
}

.mklib .compatibil {
  margin-bottom: 20px;
}

.mklib .compatibility {
  display: flex;
  align-items: center;
  margin-bottom: 10px;
}

.mklib .required {
  width: 60px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.mklib .el-dialog .el-button--default {
  background-color: #ccc;
  border: 1px solid #ccc;
  color: #40404e;
}

.mklib .el-input__inner {
  background-color: rgba(0, 0, 0, 0);
  color: #40404e;
}

.mklib .el-dialog__header,
.mklib .el-dialog__footer {
  background-color: #22232b;
}

.mklib .el-dialog__title,
.mklib .el-dialog__headerbtn .el-dialog__close,
.mklib .el-form-item__label {
  color: #1a1a21;
}

.mklib .el-form-item {
  display: flex;
  margin: 0;
}

.mklib .dialogPrinter .el-form-item__content {
  display: flex;
  margin: 0;
}

.mklib table thead tr th,
.mklib table tbody tr td {
  height: 40px;
  font-size: 14px;
}

.mklib .el-checkbox__input {
  background-color: rgba(0, 0, 0, 0);
}

.mklib .printer .el-dialog {
  width: 30vw;
}

.mklib .has-gutter {
  border: 1px solid #f5f5f5;
}

.mklib .el-input-number__decrease,
.mklib .el-input-number__increase {
  background-color: rgba(0, 0, 0, 0);
}

.mklib .el-radio__label {
  color: #40404e;
}

.mklib .el-input__inner {
  background-color: transparent !important;
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

/* 列表 */
.zsykd {
  width: 100%;
  overflow-x: scroll !important;
}

.mklib .zhuixiaoi {
  width: 800px;
  border-collapse: collapse;
  color: #40404e;
}

.mklib .zhuixiaoi .mmodity tr th {
  height: 36px;
  line-height: 36px;
  text-align: left;
  font-size: 14px;
  font-weight: 600;
  color: #40404e;
  padding-left: 20px;
}

.mklib .zhuixiaoi .mmodity tr th .el-checkbox__label {
  font-size: 14px;
  font-weight: 600;
  color: #40404e;
}

.mklib .zhuixiaoi .limiting .drag-list td {
  height: 36px;
  line-height: 36px;
  text-align: left;
  font-size: 14px;
  font-weight: 400;
  padding-left: 20px;
}

.mklib .zhuixiaoi .limiting .drag-list {
  display: block;
  display: flex;
}

.mklib .zhuixiaoi .mmodity {
  width: 100%;
  display: block;
}

.mklib .zhuixiaoi .mmodity tr {
  background-color: #f5f5f5;
  display: flex;
}

.mklib .zhuixiaoi .limiting {
  overflow-y: auto !important;
  max-height: 540px;
  border-bottom: solid 1px #f5f5f5;
  display: block;
}

.mklib .drag-list td:nth-of-type(1),
.mklib .mmodity th:nth-of-type(1) {
  width: 70px;
}

.mklib .mmodity th:nth-of-type(2),
.mklib .drag-list td:nth-of-type(2) {
  width: 180px;
}

.mklib .drag-list td:nth-of-type(3),
.mklib .mmodity th:nth-of-type(3) {
  width: 140px;
}

.mklib .drag-list td:nth-of-type(4),
.mklib .mmodity th:nth-of-type(4) {
  width: 140px;
}

.mklib .drag-list td:nth-of-type(5),
.mklib .mmodity th:nth-of-type(5) {
  width: 120px;
}

.mklib .drag-list td:nth-of-type(6),
.mklib .mmodity th:nth-of-type(6) {
  width: 140px;
}

.mklib .drag-list td:nth-of-type(7),
.mklib .mmodity th:nth-of-type(7) {
  width: 120px;
}

.mklib .drag-list td:nth-of-type(8),
.mklib .mmodity th:nth-of-type(8) {
  width: 160px;
}

.mklib .drag-list td:nth-of-type(9),
.mklib .mmodity th:nth-of-type(9) {
  width: 160px;
}

.mklib .drag-list td:nth-of-type(10),
.mklib .mmodity th:nth-of-type(10) {
  width: 60px;
}

.mklib .drag-list:nth-of-type(odd) {
  background-color: #f9f9f9;
  color: #40404e;
}

.mklib .drag-list:nth-of-type(even) {
  background-color: #f5f5f5;
  color: #40404e;
}

.drag-list-check {
  /* background: rgba(39, 52, 82, .5) !important; */
}

.cwts {
  color: #ce4253;
  line-height: 34px;
  padding-left: 10px;
}

/* 错误2 */
.mklib .diagrgeesfelogFor .el-dialog {
  width: 720px;
  box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1);
}

.mklib .diagrgeesfelogFor .wwent {
  color: #ce4153;
  font-size: 14px;
  margin: 20px 0px 20px 20px;
  display: flex;
  align-items: center;
}

.mklib .diagrgeesfelogFor .wentlb {
  margin-left: 20px;
  width: 640px;
}

.mklib .diagrgeesfelogFor .zhuixiaoi {
  width: 100%;
}

.mklib .diagrgeesfelogFor .zhuixiaoi .limiting {
  max-height: 280px !important;
  overflow-y: auto !important;
}

.mklib .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(1),
.mklib .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(1) {
  width: 50px;
}

.mklib .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(2),
.mklib .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(2) {
  width: 320px;
}

.mklib .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(3),
.mklib .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(3) {
  width: 200px;
}

.mklib .diagrgeesfelogFor .danykz .mmodity th:nth-of-type(2),
.mklib .diagrgeesfelogFor .danykz .drag-list td:nth-of-type(2) {
  width: 520px;
}

/* 无效颜色 */
.mklib .diagrgeesfelogFor .el-button--primary.is-disabled,
.mklib .diagrgeesfelogFor .el-button--primary.is-disabled:hover {
  background-color: #1f2846;
  color: #4e505a;
  border-color: #1f2846;
}
</style>

