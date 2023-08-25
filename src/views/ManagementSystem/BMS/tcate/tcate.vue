<template>
    <div class="tcate">
        <div class="tcate-controller">
            <icon-button @click.native="xingh" text="新增二级分类" img="添加.png" colors="#383943"></icon-button>
            <icon-button @click.native="compiletcate" text="编辑" img="编辑.png" colors="#383943"></icon-button>
            <icon-button @click.native="noneffective" text="置为无效" img="无效.png" colors="#383943"></icon-button>
            <icon-button @click.native="effective" text="置为有效" img="有效.png" colors="#383943"></icon-button>
            <icon-button @click.native="tcatedel" text="批量删除" img="删除.png" colors="#6B2830"
                         bjcolors="#491E24"></icon-button>
        </div>
        <div class="zsykd" style="display: inline-block;">
            <div style="width: 850px;border-top: 1px solid #383943;border-left: 1px solid #383943;">
                <el-table :data="tableData" style="min-width: 850px;" class="xiangfe"
                          @expand-change="handleExpandChange"
                          :row-key="getRowKeys"
                          :row-class-name="tableRowClassName"
                          :expand-row-keys="expands">
                    <el-table-column type="expand">
                        <template #default="">
                            <div class="substance">
                                <table class="zhuixiaoi">
                                    <thead>
                                    <tr>
                                        <th class="outline">
                                            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll"
                                                         @change="handleCheckAllChange">行号
                                            </el-checkbox>
                                        </th>
                                        <th>二级分类</th>
                                        <th>创建时间</th>
                                        <th>更新时间</th>
                                        <th>状态</th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                    <tr v-for="(item,i) in CardMachineCatalog" :key="i" class="drag-list"
                                        draggable="true"
                                        @dragstart="dragstart(item)" @dragenter="dragenter(item)"
                                        @dragend="dragend(item)">
                                        <td class="first">
                                            <el-checkbox-group v-model="checkedCities"
                                                               @change="handleCheckedCitiesChange">
                                                <el-checkbox :label="item.id">{{i+1}}</el-checkbox>
                                            </el-checkbox-group>
                                        </td>
                                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.n}}</td>
                                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.c}}</td>
                                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.u}}</td>
                                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.s}}</td>
                                    </tr>
                                    <tr class="drag-list" v-if="CardMachineCatalog.length<1">
                                        <td class="nodata">
                                            <img src="../../../../assets/img/wu.png" alt="">
                                            <div class="hint">暂无数据</div>
                                        </td>
                                    </tr>
                                    </tbody>
                                </table>
                            </div>
                        </template>
                    </el-table-column>
                    <el-table-column label="一级分类" prop="n" width="152"/>
                    <el-table-column label="分类状态" prop="cs" width="90"/>
                    <el-table-column label="首选出品库名称" prop="fmk" width="160"/>
                    <el-table-column label="首选出品库状态" prop="ms" width="130"/>
                    <el-table-column label="创建时间" prop="c" width="135"/>
                    <el-table-column label="更新时间" prop="u" width="135"/>
                </el-table>
            </div>
        </div>

        <!-- 新建编辑二级分类 -->
        <div class="dialogFormVisible" v-show="dialogFormVisible">
            <el-dialog :title="newcompile?'新建':'编辑'" :visible.sync="dialogFormVisible" :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>当前一级分类：
                        </div>
                        <div class="controlling">{{Area.Place}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>分类名称：
                        </div>
                        <el-input class="controlling" v-model="Area.Name" placeholder="请输入分类名称"/>
                    </div>
                </el-form>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFormVisible = false">取消</el-button>
                    <el-button v-show="newcompile" type="primary" @click="construction">新建</el-button>
                    <el-button v-show="!newcompile" type="primary" @click="savetcate">保存</el-button>
                </span>
            </el-dialog>
        </div>

        <!-- 置为无效错误 -->
        <div class="Seternewdefed" v-show="disable">
            <el-dialog title="置为无效错误" @close="disable = false" :visible.sync="disable" :close-on-click-modal="false">
                <div v-show="whetherbenull">
                    <div class="ewdefed">{{LnvalidGoodsList.msg}}</div>
                    <el-button type="primary" style="margin-bottom: 10px;" @click="constraint">置为无效</el-button>
                    <div style="display: inline-block;">
                        <table class="zhuixiaois">
                            <thead class="mmodity">
                            <tr>
                                <th style="border-left:1px solid #383943">
                                    <el-checkbox :indeterminate="disarminate" v-model="disacheckAll"
                                                 @change="disaCheckAllChange">行号
                                    </el-checkbox>
                                </th>
                                <th>套餐名称</th>
                                <th>套餐分类</th>
                                <th>被依赖商品名称</th>
                                <th>商品分类</th>
                            </tr>
                            </thead>
                            <tbody class="limiting">
                            <tr v-for="(item,i) in LnvalidGoodsList.data" :key="i" class="drag-list" draggable="true">
                                <td :style="{'border-left':'1px solid #383943'}">
                                    <el-checkbox-group v-model="disaCities" @change="disaCCheckedCitiesChange">
                                        <el-checkbox :label="item.sid">{{i+1}}</el-checkbox>
                                    </el-checkbox-group>
                                </td>
                                <td>{{item.sn}}</td>
                                <td>
                                    <div>{{item.so}} <i class="el-icon-arrow-right"></i> {{item.st}}</div>
                                </td>
                                <td>
                                    <div class="xian" v-for="(it,j) in item.dtls" :key="j">{{it.pn}}</div>
                                </td>
                                <td>
                                    <div class="xian" v-for="(it,j) in item.dtls" :key="j">{{it.po}} <i
                                            class="el-icon-arrow-right"></i> {{it.pt}}
                                    </div>
                                </td>
                            </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
                <div v-show="!whetherbenull">
                    <div class="ewdefed">相关依赖问题已经处理完成,点重试按钮,发起重试.</div>
                    <el-button type="primary" style="margin-bottom: 10px;" @click="noneffective">重试</el-button>
                </div>
                <span slot="footer" class="dialog-footer">
                  <el-button @click="disable = false">取消</el-button>
                </span>
            </el-dialog>
        </div>

        <!-- 置为有效错误 -->
        <div class="invaliddefed" v-show="invaliderror">
            <el-dialog title="置为有效错误" @close="invaliderror = false" :visible.sync="invaliderror"
                       :close-on-click-modal="false">
                <div class="ewdefed">{{resnr.msg}}</div>
                <div style="display: inline-block;">
                    <div v-show="resnr.code == 3" class="three">
                        <table class="zhuixiaois">
                            <thead class="mmodity">
                            <tr>
                                <th style="border-left:1px solid #383943">
                                    行号
                                </th>
                                <th>单品名称</th>
                                <th>单品分类</th>
                                <th>区域</th>
                                <th>出品库</th>
                                <th>问题</th>
                            </tr>
                            </thead>
                            <tbody class="limiting">
                            <tr v-for="(item,i) in resnr.data" :key="i" class="drag-list" draggable="true">
                                <td :style="{'border-left':'1px solid #383943'}">{{i+1}}</td>
                                <td>{{item.pn}}</td>
                                <td>{{item.pon}} <i class="el-icon-arrow-right"></i> {{item.ptn}}</td>
                                <td>{{item.rn}}</td>
                                <td>{{item.mn}}</td>
                                <td>
                                    <ellipsis-tooltip :text="item.c || '-----'"></ellipsis-tooltip>
                                </td>
                            </tr>
                            </tbody>
                        </table>
                    </div>
                    <div v-show="resnr.code == 4" class="four">
                        <table class="zhuixiaois">
                            <thead class="mmodity">
                            <tr>
                                <th style="border-left:1px solid #383943">
                                    行号
                                </th>
                                <th>套餐名称</th>
                                <th>套餐分类</th>
                                <th>被依赖单品名称</th>
                                <th>单品分类</th>
                            </tr>
                            </thead>
                            <tbody class="limiting">
                            <tr v-for="(item,i) in resnr.data" :key="i" class="drag-list" draggable="true">
                                <td :style="{'border-left':'1px solid #383943'}">{{i+1}}</td>
                                <td>{{item.sn}}</td>
                                <td>{{item.son}} <i class="el-icon-arrow-right"></i> {{item.stn}}</td>
                                <td>{{item.pn}}</td>
                                <td>{{item.pon}} <i class="el-icon-arrow-right"></i> {{item.ptn}}</td>
                            </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
                <span slot="footer" class="dialog-footer">
                  <el-button type="primary" @click="invaliderror = false">确定</el-button>
                </span>
            </el-dialog>
        </div>
    </div>
</template>
<script>
import EllipsisTooltip from '@/components/EllipsisTooltip.vue'//根据路径导入组件
import IconButton from '@/components/IconButton.vue'//根据路径导入组件
import {mapState, mapMutations} from "vuex"
export default {
  name: "tcate",
  data(){
    return {
      tableData: [],//一级目录
      CardMachineCatalog: [],//二级目录
      multipleSelection: [],// 选中的二级分类
      dialogFormVisible: false,//控制新建二级分类是否显示
      Area: {
        Place: "",
        Name: "",
      },//二级目录
      quantity: [],// 判断哪个要亮
      getRowKeys(row){
        return row.id
      },//根据id来判断选择
      expands: [],// 选中展开的一级分类
      isIndeterminate: false,//全选或者全不选
      checkAll: false,//全部选中触发
      checkedCities: [],//已选择内容
      oldItem: '',//记录初始信息
      newItem: '',// 记录过程中信息
      newcompile: false,//保存还是编辑


      disable: false,//显示强制无效
      LnvalidGoodsList: {},// 有效套餐使用到了置无效一级分类下的商品 显示列表

      disacheckAll: false,//全部选中触发
      disaCities: [],//已选择内容
      disarminate: false,//全选或者全不选
      whetherbenull: true,// 判断列表是否为空


      resnr: {},//错误内容
      invaliderror: false,//是否显示错误列表
      windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
      MaxHeight: 0,//滚动高度
      MaxNumber: 0//最大个数

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
    };
  },
  components: {
    EllipsisTooltip,
    IconButton,
  },
  methods: {
    ...mapMutations(["judgeauthorization"]),
    // 滚动最大高度
    RollMaxHeight(i){
      var s = i - 48 - 60 - 55 - 37
      this.MaxHeight = s
      this.MaxNumber = Math.floor(s / 37)
      console.log(this.MaxNumber);
      // console.log(i);
    },
    // 获取区域信息内容
    demand(){
      this.$api.BMS.tcate.requesttcateocate_list().then(res => {
        console.log(res);
        if (res.code == 1) {
          this.tableData = res.data || []
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 手风琴效果
    handleExpandChange(val, expandedRows) {
      console.log(val);
      if (this.expands[0] == val.id) {
        this.expands = []
        this.CardMachineCatalog = []
      } else {
        this.expands = [val.id]
        this.CardMachine(val.id)
        // this.expands.push(val.id)
        this.Area.Place = val.n
      }

    },
    // 显示标记 给二级分类赋值
    CardMachine(id){
      this.$api.BMS.tcate.requesttcatelist({id: id}).then(res => {
        console.log(res);
        this.CardMachineCatalog = res.data || [];
        this.quantity = []
        for (const key in res.data) {
          if (this.quantity.length == 0) {
            this.quantity = [res.data[key].d == 1]
          } else {
            this.quantity.push(res.data[key].d == 1)
          }
        }
        // console.log(this.quantity);

        this.checkedCities = []
        this.isIndeterminate = false
        this.checkAll = false
      })
    },
    // 打开新增卡台
    xingh(){
      if (this.expands.length == 1) {
        this.dialogFormVisible = true
        this.Area.Name = ""
        this.newcompile = true
      } else {
        this.$message({
          message: '请先打开一个一级分类',
          type: 'warning',
        })
      }
    },
    // 新增卡台
    construction(){
      if (this.Area.Name == '') {
        this.$message.warning('必选框不能为空')
      } else {
        this.$api.BMS.tcate.requesttcatenew({
          one_cate_id: this.expands[0],
          name: this.Area.Name,
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
            this.demand()
            this.CardMachine(this.expands[0])
            this.dialogFormVisible = false
            this.Area.Name = ""
          } else {
            this.$message({message: res.msg, type: 'warning',})
          }
        })

      }
    },
    // 获取编辑内容
    compiletcate(){
      if (this.expands.length == 1 && this.checkedCities.length == 1) {
        this.$api.BMS.tcate.requesttcateget({id: this.checkedCities[0]}).then(res => {
          this.Area.Name = res.data.name
        })
        this.dialogFormVisible = true
        this.newcompile = false
      } else {
        this.$message({
          message: '请选择一个进行编辑',
          type: 'warning',
        })
      }
    },
    // 保存编辑内容
    savetcate(){
      this.$api.BMS.tcate.requesttcatesave({
        id: this.checkedCities[0],
        name: this.Area.Name
      }).then(res => {
        // console.log(res);
        if (res.code == 1) {
          this.$message({
            showClose: true,
            message: "保存成功",
            type: 'success'
          })
          this.demand()
          this.Area.Name = ""
          this.CardMachine(this.expands[0])
          this.dialogFormVisible = false
        } else {
          this.$message({message: res.msg, type: 'warning',})
        }
      })
    },
    // 无效
    noneffective(){
      if (this.checkedCities.length > 0) {
        this.$api.BMS.tcate.requesttcatedisable({
          ids: this.checkedCities
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.demand()
            this.CardMachine(this.expands[0])

            this.checkedCities = []
            this.isIndeterminate = false
            this.checkAll = false
            this.disable = false
            this.$message({
              showClose: true,
              message: "更改状态成功",
              type: 'success'
            })
          } else if (res.code == 2) {
            this.LnvalidGoodsList = {
              data: res.data,
              msg: res.msg
            }
            this.disable = true
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
    // 控制全选或者全不选
    disaCheckAllChange(val) {
      console.log(val);
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
    // 有效
    effective(){
      if (this.checkedCities.length > 0) {
        this.$api.BMS.tcate.requesttcateenable({
          ids: this.checkedCities,
          is_force: 2
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.demand()
            this.CardMachine(this.expands[0])
            this.$message({
              showClose: true,
              message: "更改状态成功",
              type: 'success'
            })
          } else if (res.code == 3 || res.code == 4) {
            this.resnr = res
            this.invaliderror = true
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

    // 删除
    tcatedel(){
      if (this.checkedCities.length > 0) {
        this.$api.BMS.tcate.requesttcatedel({ids: this.checkedCities}).then(res => {
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "删除成功",
              type: 'success'
            })
            this.demand()
            this.CardMachine(this.expands[0])
          } else {
            this.$message({message: res.msg, type: 'warning',})
          }
        })
      } else {
        this.$message({
          message: '请选择一个在进行删除',
          type: 'warning',
        })
      }

    },
    // 控制全选或者全不选
    handleCheckAllChange(val) {
      if (val) {
        this.checkedCities = []
        for (const key in this.CardMachineCatalog) {
          this.checkedCities.push(this.CardMachineCatalog[key].id)
        }
      } else {
        this.checkedCities = []
      }
      this.isIndeterminate = false;
    },
    // 控制单个选中
    handleCheckedCitiesChange(value) {
      let checkedCount = value.length;
      this.checkAll = checkedCount === this.CardMachineCatalog.length;
      this.isIndeterminate = checkedCount > 0 && checkedCount < this.CardMachineCatalog.length;
    },
    // 记录初始信息
    dragstart(item) {
      this.oldItem = item;
      //   console.log(item);
    },
    // 记录过程中信息
    dragenter(item) {
      // console.log(item);
      this.newItem = item;
    },
    // 做最终操作
    dragend(item) {
      if (this.oldItem != this.newItem) {
        let oldIndex = this.CardMachineCatalog.indexOf(this.oldItem);
        let newIndex = this.CardMachineCatalog.indexOf(this.newItem);
        var down_up = 1;
        if (oldIndex > newIndex) {
          down_up = 2
        } else if (oldIndex < newIndex) {
          down_up = 1
        }
        console.log(oldIndex);
        console.log(newIndex);
        this.$api.BMS.tcate.requesttcatemove_dsp({
          id: this.oldItem.id,
          dest_id: this.newItem.id,
          down_up: down_up
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            let newList = [...this.CardMachineCatalog]; // 中间数组，用于交换两个节点
            // 删除老的节点
            newList.splice(oldIndex, 1);
            // 在列表目标位置增加新的节点
            newList.splice(newIndex, 0, this.oldItem);
            // 更新this.List，触发transition-group的动画效果
            this.CardMachineCatalog = [...newList];
            // }
            // this.CardMachine(this.expands[0])
            this.$message({showClose: true, message: "更改位置成功", type: 'success', duration: 1000})
          } else {
            this.$message.warning(res.msg);
          }

        })

      }
    },
    // 选中改颜色 斑马线
    tableRowClassName({row, rowIndex}){
      // console.log(row);
      if (row.cs == '无效') {
        return 'wuxiao';
      }
      return '';
    },
  },
  computed: {
    setmea(){
      return JSON.parse(JSON.stringify(this.LnvalidGoodsList))
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
    .tcate .el-dialog {
        margin: 0px 0px 0px auto !important;
        background-color: #f9f9f9;
        height: 100%;
        position: relative;
    }

    .tcate .el-dialog__footer {
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }

    .tcate .el-dialog__body {
        padding: 0px 0px 30px 20px;
        overflow-y: scroll !important;
        /* width: 100%; */
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;
    }

    .tcate .el-dialog {
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .tcate {
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding: 20px 30px;
    }

    /* 区域无效改变颜色 */
    .tcate .wuxiao > td > div {
        color: #595959 !important;
    }

    .tcate .wuxiao:hover > td > div {
        color: #595959 !important;
    }

    /* 必填 */
    .tcate .mandatory {
        color: #D9D9D9;
        width: 140px;
        text-align: right;
        /* padding-top: 10px; */
    }

    .tcate .controlling {
        width: 230px !important;
        line-height: 40px;
        color: #D9D9D9;
    }

    .tcate .controlleingsg {
        width: 300px !important;
        line-height: 40px;
        color: #D9D9D9;
        display: flex;
    }

    .tcate .controlleingsg input {
        width: 98px !important;
    }

    .tcate .controlleingsg .ateast {
        margin: 0 10px;
    }

    .tcate .reqfieldsd {
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
    .tcate .drag-list .nodata {
        border-left: solid 1px #383943;
        border-bottom: solid 1px #383943;
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
    }

    .tcate .drag-list .nodata img {
        width: 60px;
        height: 60px;
    }

    .tcate .drag-list .nodata .hint {
        font-size: 13px !important;
    }

    .el-table__empty-text {
        background-color: #1A1A20;
        border-right: solid 1px #383943;
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
        color: #d9d9d96b;
    }

    /* 鼠标进入不改变颜色 */
    .tcate .el-table__body tr:nth-of-type(odd):hover > td {
        background-color: #1A1A20;
        color: #D9D9D9;
    }

    .tcate .el-table__body tr:nth-of-type(even):hover > td {
        background-color: #202026;
        color: #D9D9D9;
    }

    .tcate table tr:nth-of-type(odd):hover > td {
        background-color: #1A1A20;
        color: #D9D9D9;
    }

    .tcate table tr:nth-of-type(even):hover > td {
        background-color: #202026;
        color: #D9D9D9;
    }

    /* 改限制字体数量的颜色背景 */
    .tcate .el-input .el-input__count .el-input__count-inner {
        background: none;
        color: #D9D9D9;
    }

    .tcate .el-input__suffix {
        background-color: #1A1A20;
        color: #D9D9D9;
        right: -45px;
        top: 8px;
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 没一级分类的时候 */
    .tcate .between {
        display: flex;
        flex-direction: column;
        align-items: center;
        margin-top: 170px;
        padding-right: 400px;
    }

    .tcate .between img {
        width: 100px;
        height: 100px;
    }

    .tcate .between .period {
        margin-top: 30px;
        color: #a3a3a3;
        font-size: 18px;
    }

    .tcate .el-table {
        overflow: inherit;
    }

    .zsykd {
        width: 100%;
        overflow-x: scroll !important;
    }

    .tcate .el-table__body-wrapper {
        max-height: 500px;
        overflow: auto;
        width: calc(100% + 6px) !important;
    }

    /* .tcate {
        width: calc(100% - 100px);
        height: calc(100% - 60px);
        padding: 20px 40px;
        margin: 10px 10px;
        background-color:#1A1A20 ;
        border-radius: 10px;
    } */
    .tcate .tcate-headline {
        font-size: 30px;
        font-weight: bold;
        color: #D9D9D9;
    }

    .tcate .tcate-controller {
        /*margin-top: 30px;*/
        height: 54px;
        width: 850px;
        background-color: #202026;
        display: flex;
        align-items: center;
        border-top: 1px solid #2c2d36;
    }

    .tcate .layouts {
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* .tcate .checked{
        border-left: 2px solid #16D52B;
    }
    .tcate .didNotChange{
        border-left: 2px solid #383943;
    } */
    .tcate .explain {
        color: #ce4153;
        margin-left: 10px;
        margin-bottom: 10px;
    }

    /* 改限制字体数量的颜色背景 */
    .tcate .el-input .el-input__count .el-input__count-inner {
        background: none;
        color: #D9D9D9;
    }

    .tcate .compatibility {
        display: flex;
        align-items: center;
        margin-bottom: 10px;
    }

    .tcate .compatibility1 {
        display: flex;
        align-items: center;
        margin-bottom: 15px;
    }

    .tcate .compatibility1 .el-input__inner {
        width: 90px;
    }

    .tcate .required {
        width: 60px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .tcate .el-dialog .el-button--default {
        background-color: #ccc;
        border: 1px solid #ccc;
        color: #404041;
    }

    .tcate .el-dialog {
        background-color: #f9f9f9;
    }

    .tcate .el-input__inner {
        background-color: transparent;
        color: #D9D9D9;
    }

    .tcate .el-dialog__header, .tcate .el-dialog__footer {
        background-color: #1a1a21;
    }

    .tcate .el-dialog__title, .tcate .el-dialog__headerbtn .el-dialog__close, .tcate .el-form-item__label {
        color: #1a1a21;
    }

    .tcate .el-form-item {
        display: flex;
        margin: 0;
    }

    .tcate .el-table th.el-table__cell.is-leaf {
        background-color: #2A2B34;
        color: #D9D9D9;
        border-bottom: 1px solid #383943;
        border-right: 1px solid #383943;
        height: 40px;
    }

    .el-table .el-table__cell {
        text-align: center;
        padding: 0;
    }

    .tcate .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    .tcate .tcate .el-dialog {
        width: 30vw;
    }

    .tcate .has-gutter {
        border: 1px solid #383943;
    }

    .tcate .el-table__body:nth-of-type(odd) {
        background-color: #f9f9f9;
        color: #40404e;
    }

    .tcate .el-table__body:nth-of-type(even) {
        background-color: #f5f5f5;
        color: #40404e;
    }

    .tcate .el-table__empty-block {
        background-color: #e5e5e5 !important;
    }

    .tcate .el-table__empty-text {
        color: #D9D9D9;
    }

    .tcate .el-table__body tr.current-row > td {
        background-color: #3C3D46 !important;
    }

    .tcate .el-table__body .success-row {
        background-color: #3C3D46 !important;
    }

    .tcate .el-table__body td.el-table__cell {
        /* height: 40px; */
        /* line-height: 40px; */
        border-bottom: 1px solid #383943;
        border-right: 1px solid #383943;
    }

    .tcate .el-table--border, .tcate .el-table--group {
        border-top: 1px solid #383943;
        border-left: 1px solid #383943;
    }

    .tcate .el-table--border::after,
    .tcate .el-table--group::after,
    .tcate .el-table::before {
        background-color: #383943;
    }

    .tcate .el-table td.el-table__cell div {
        color: #D9D9D9;
    }

    .tcate .el-table__cell.el-table__expanded-cell {
        padding: 10px 40px 10px 40px;
        background-color: rgba(0, 0, 0, 0);
    }

    .tcate .el-table__cell.el-table__expanded-cell:hover {
        background-color: rgba(0, 0, 0, 0);
    }

    .tcate .xiangfe thead tr th, .tcate .xiangfe tbody tr td {
        height: 40px;
        font-size: 14px;
    }

    .tcate .substance {
        width: 100%;
        /* overflow: hidden; */
        /* position: relative; */
        /* height: 60px; */
        /* padding-left: 50px; */
    }

    .tcate .el-table tr:nth-of-type(odd) {
        background-color: #f9f9f9;
        color: #40404e;
    }

    .tcate .el-table tr:nth-of-type(even) {
        background-color: #f5f5f5;
        color: #40404e;
    }

    /*  */
    .tcate .dialogFormVisible .el-dialog {
        width: 450px !important;
    }

    /* 显示今天更改状态了没有 */
    .tcate .outline {
        position: relative;
    }
</style>
<style>
    /* 强制 */
    .tcate .check {
        color: rgb(255, 0, 0);
        margin-bottom: 10px;
        font-size: 14px;
    }

    .tcate .listpage {
        border-collapse: collapse;
        border: solid 1px #383943;
        color: #D9D9D9;
        width: 100%;
        /* max-height: 430px !important; */
        /* overflow: auto !important; */
        display: inline-block;
    }

    .tcate .listpage, .tcate .listpage thead, .tcate .listpage tr {
        width: 100%;
        display: inline-block;
    }

    .tcate .listpage thead tr th:nth-of-type(1) {
        width: 120px;
        position: relative;
    }

    .tcate .listpage thead tr th:nth-of-type(2) {
        width: 280px;
    }

    .tcate .listpage tbody tr td:nth-of-type(1) {
        width: 120px;
    }

    .tcate .listpage tbody tr td:nth-of-type(2) {
        width: 280px;
    }

    .tcate .listpage thead tr th, .tcate .listpage tbody tr td {
        /* width: 50%; */
        height: 40px;
        line-height: 40px;
        text-align: center;
        border: solid 1px #383943;
    }

    .tcate .disable .el-dialog {
        width: 30vw !important;
        min-width: 490px !important;
        max-width: 530px !important;
    }
</style>
<style>
    /* 移动标签 */
    .tcate .zhuixiaoi {
        width: 100%;
        display: inline-block;
        border-collapse: collapse;
        color: #D9D9D9;
    }

    .tcate .zhuixiaoi .List-move {
        transition: transform 0.2s;
    }

    .tcate .zhuixiaoi thead, .tcate .zhuixiaoi thead tr，.tcate .zhuixiaoi tbody tr {
        width: 100% !important;

    }

    .tcate .zhuixiaoi tbody {
        display: inline-block;
        width: 100% !important;
    }

    .tcate .zhuixiaoi thead {
        /* width: 100% !important; */
        display: inline-block;
    }

    .tcate .zhuixiaoi .drag-list {
        margin: 0 auto;
        /* width: 100% !important; */
        /* height: 40px; */
        line-height: 40px;
        text-align: center;
        /* border: solid 1px #383943; */
    }

    .tcate .zhuixiaoi thead th {
        height: 40px;
        line-height: 40px;
        text-align: center;
        border-right: solid 1px #383943;
        border-top: solid 1px #383943;
        border-bottom: solid 1px #383943;
        font-size: 14px;
        font-weight: 400;
    }

    .tcate .zhuixiaoi thead th:nth-of-type(1) {
        border-left: solid 1px #383943;
    }

    .tcate .zhuixiaoi tbody td {
        height: 40px;
        line-height: 40px;
        text-align: center;
        border-right: solid 1px #383943;
        /* border-top: solid 1px #383943; */
        border-bottom: solid 1px #383943;
        font-size: 14px;
        font-weight: 400;
    }

    .tcate .zhuixiaoi tbody td:nth-of-type(1) {
        border-left: solid 1px #383943;
    }

    .tcate .zhuixiaoi thead tr th {
        background-color: #2A2B34;
    }

    .tcate .zhuixiaoi tr {
        display: flex;
    }

    .tcate .zhuixiaoi .drag-list:nth-of-type(odd) td {
        background-color: #1A1A20;
    }

    .tcate .zhuixiaoi .drag-list:nth-of-type(even) td {
        background-color: #202026;
    }

    .tcate .zhuixiaoi .drag-list:hover td {
        background-color: #3C3D46;
    }

    .tcate .zhuixiaoi .drag-list td:nth-of-type(1), .tcate .zhuixiaoi thead th:nth-of-type(1) {
        width: 80px;
    }

    .tcate .zhuixiaoi .drag-list td:nth-of-type(2), .tcate .zhuixiaoi thead th:nth-of-type(2) {
        /* display: inline-block;
        width: calc(100% - 430px) !important; */
        width: 276px;
        /* width: 30%; */
    }

    .tcate .zhuixiaoi .drag-list td:nth-of-type(3), .tcate .zhuixiaoi thead th:nth-of-type(3) {
        width: 160px;
    }

    .tcate .zhuixiaoi .drag-list td:nth-of-type(4), .tcate .zhuixiaoi thead th:nth-of-type(4) {
        width: 160px;
    }

    .tcate .zhuixiaoi .drag-list td:nth-of-type(5), .tcate .zhuixiaoi thead th:nth-of-type(5) {
        width: 80px;
    }

    .tcate .zhuixiaoi .el-checkbox__label {
        color: #40404e;
        font-size: 12px;
    }

    .tcate .zhuixiaoi .mmodity .el-checkbox__label {
        font-size: 12px;
    }
</style>
<style>
    /* 列表 */
    .tcate .zhuixiaois {
        /* width:1400px; */
        border-collapse: collapse;
        color: #D9D9D9;
    }

    .tcate .zhuixiaois .mmodity tr th {
        height: 36px;
        line-height: 36px;
        text-align: center;
        border-right: solid 1px #383943;
        border-top: solid 1px #383943;
        border-bottom: solid 1px #383943;
        background-color: #2d2e38;
        font-size: 14px;
        font-weight: 400;
    }

    .tcate .zhuixiaois .mmodity tr th:nth-of-type(1) {
        border-left: solid 1px #383943;
    }

    .tcate .zhuixiaois .limiting .drag-list td {
        /* height: 40px; */
        line-height: 36px;
        text-align: center;
        border-right: solid 1px #383943;
        border-bottom: solid 1px #383943;
        /* border-top: solid 1px #383943; */
        font-size: 14px;
        font-weight: 400;
    }

    .tcate .zhuixiaois .limiting .drag-list td:nth-of-type(1) {
        border-left: solid 1px #383943;
    }

    .tcate .zhuixiaois .limiting .drag-list {
        display: block;
        display: flex;
    }

    .tcate .zhuixiaois .mmodity {
        width: 100%;
        display: block;
    }

    .tcate .zhuixiaois .mmodity tr {
        display: flex;
    }

    .tcate .zhuixiaois .limiting {
        overflow-y: auto !important;
        max-height: 520px !important;
        border-bottom: solid 1px #383943;
        display: block;
    }

    .tcate .zhuixiaois .drag-list td:nth-of-type(1), .tcate .zhuixiaois thead th:nth-of-type(1) {
        width: 80px;
    }

    .tcate .zhuixiaois .drag-list td:nth-of-type(2), .tcate .zhuixiaois thead th:nth-of-type(2) {
        width: 200px
    }

    .tcate .zhuixiaois .drag-list td:nth-of-type(3), .tcate .zhuixiaois thead th:nth-of-type(3) {
        width: 140px;
    }

    .tcate .zhuixiaois .drag-list td:nth-of-type(4), .tcate .zhuixiaois thead th:nth-of-type(4) {
        width: 160px;
    }

    .tcate .zhuixiaois .drag-list td:nth-of-type(5), .tcate .zhuixiaois thead th:nth-of-type(5) {
        width: 100px;
    }

    .tcate .zhuixiaois .drag-list td:nth-of-type(6), .tcate .zhuixiaois thead th:nth-of-type(6) {
        width: 140px;
    }

    .tcate .zhuixiaois .drag-list td:nth-of-type(7), .tcate .zhuixiaois thead th:nth-of-type(7) {
        width: 105px;
    }

    .tcate .zhuixiaois .drag-list td:nth-of-type(8), .tcate .zhuixiaois thead th:nth-of-type(8) {
        width: 140px;
    }

    .tcate .zhuixiaois .drag-list td:nth-of-type(9), .tcate .zhuixiaois thead th:nth-of-type(9) {
        width: 140px;
    }

    .tcate .zhuixiaois .drag-list td:nth-of-type(10), .tcate .zhuixiaois thead th:nth-of-type(10) {
        width: 140px;
    }

    .tcate .zhuixiaois .drag-list td:nth-of-type(11), .tcate .zhuixiaois thead th:nth-of-type(11) {
        width: 70px;
    }

    /* 套餐单品问题区域 */
    .tcate .Seternewdefed .el-dialog {
        width: 930px !important;
    }

    .tcate .Seternewdefed .ewdefed {
        color: #D9D9D9;
        font-size: 20px;
        margin: 20px 0 10px 00px;
        line-height: 30px;
    }

    .tcate .Seternewdefed .zhuixiaois {
        min-width: 602px !important;
        display: inline-block;
    }

    .tcate .Seternewdefed .divbigesd {
        display: flex;
        flex-direction: column;
    }

    .tcate .Seternewdefed .divbigesd .data {
        height: 30px;
        line-height: 30px;
    }

    .tcate .Seternewdefed .divbigesd .xian {
        height: 1px;
        background-color: #383943;
    }

    .tcate .Seternewdefed .zhuixiaois .drag-list td {
        line-height: 30px;
        display: flex;
        flex-direction: column;
        justify-content: center;
    }

    .tcate .Seternewdefed .zhuixiaois .drag-list td .xian {
        border-top: solid 1px #383943;
    }

    .tcate .Seternewdefed .zhuixiaois .drag-list td .xian:nth-of-type(1) {
        border-top: solid 0px #383943;
    }

    .tcate .Seternewdefed .zhuixiaois .drag-list td:nth-of-type(1), .tcate .Seternewdefed .zhuixiaois .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .tcate .Seternewdefed .zhuixiaois .drag-list td:nth-of-type(2), .tcate .Seternewdefed .zhuixiaois .mmodity th:nth-of-type(2) {
        width: 200px;
    }

    .tcate .Seternewdefed .zhuixiaois .drag-list td:nth-of-type(3), .tcate .Seternewdefed .zhuixiaois .mmodity th:nth-of-type(3) {
        width: 200px;
    }

    .tcate .Seternewdefed .zhuixiaois .drag-list td:nth-of-type(4), .tcate .Seternewdefed .zhuixiaois .mmodity th:nth-of-type(4) {
        width: 200px;
    }

    .tcate .Seternewdefed .zhuixiaois .drag-list td:nth-of-type(5), .tcate .Seternewdefed .zhuixiaois .mmodity th:nth-of-type(5) {
        width: 200px;
    }

    /* 无效错误 */
    .tcate .invaliddefed .el-dialog {
        width: 1130px !important;
    }

    .tcate .invaliddefed .ewdefed {
        color: #D9D9D9;
        font-size: 20px;
        margin: 20px 0 10px 00px;
        line-height: 30px;
    }

    .tcate .invaliddefed .zhuixiaois {
        min-width: 602px !important;
        display: inline-block;
    }

    .tcate .invaliddefed .divbigesd {
        display: flex;
        flex-direction: column;
    }

    .tcate .invaliddefed .divbigesd .data {
        height: 30px;
        line-height: 30px;
    }

    .tcate .invaliddefed .divbigesd .xian {
        height: 1px;
        background-color: #383943;
    }

    /* 错误2 */
    .tcate .invaliddefed .two .zhuixiaois .drag-list td:nth-of-type(1), .tcate .invaliddefed .two .zhuixiaois .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .tcate .invaliddefed .two .zhuixiaois .drag-list td:nth-of-type(2), .tcate .invaliddefed .two .zhuixiaois .mmodity th:nth-of-type(2) {
        width: 300px;
    }

    .tcate .invaliddefed .two .zhuixiaois .drag-list td:nth-of-type(3), .tcate .invaliddefed .two .zhuixiaois .mmodity th:nth-of-type(3) {
        width: 300px;
    }

    .tcate .invaliddefed .two .zhuixiaois .drag-list td:nth-of-type(4), .tcate .invaliddefed .two .zhuixiaois .mmodity th:nth-of-type(4) {
        width: 300px;
    }

    /* 错误3 */
    .tcate .invaliddefed .three .zhuixiaois .drag-list td:nth-of-type(1), .tcate .invaliddefed .three .zhuixiaois .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .tcate .invaliddefed .three .zhuixiaois .drag-list td:nth-of-type(2), .tcate .invaliddefed .three .zhuixiaois .mmodity th:nth-of-type(2) {
        width: 200px;
    }

    .tcate .invaliddefed .three .zhuixiaois .drag-list td:nth-of-type(3), .tcate .invaliddefed .three .zhuixiaois .mmodity th:nth-of-type(3) {
        width: 200px;
    }

    .tcate .invaliddefed .three .zhuixiaois .drag-list td:nth-of-type(4), .tcate .invaliddefed .three .zhuixiaois .mmodity th:nth-of-type(4) {
        width: 200px;
    }

    .tcate .invaliddefed .three .zhuixiaois .drag-list td:nth-of-type(5), .tcate .invaliddefed .three .zhuixiaois .mmodity th:nth-of-type(5) {
        width: 200px;
    }

    .tcate .invaliddefed .three .zhuixiaois .drag-list td:nth-of-type(6), .tcate .invaliddefed .three .zhuixiaois .mmodity th:nth-of-type(6) {
        width: 200px;
    }

    /* 错误4 */
    .tcate .invaliddefed .four .zhuixiaois .drag-list td:nth-of-type(1), .tcate .invaliddefed .four .zhuixiaois .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .tcate .invaliddefed .four .zhuixiaois .drag-list td:nth-of-type(2), .tcate .invaliddefed .four .zhuixiaois .mmodity th:nth-of-type(2) {
        width: 250px;
    }

    .tcate .invaliddefed .four .zhuixiaois .drag-list td:nth-of-type(3), .tcate .invaliddefed .four .zhuixiaois .mmodity th:nth-of-type(3) {
        width: 250px;
    }

    .tcate .invaliddefed .four .zhuixiaois .drag-list td:nth-of-type(4), .tcate .invaliddefed .four .zhuixiaois .mmodity th:nth-of-type(4) {
        width: 250px;
    }

    .tcate .invaliddefed .four .zhuixiaois .drag-list td:nth-of-type(5), .tcate .invaliddefed .four .zhuixiaois .mmodity th:nth-of-type(5) {
        width: 250px;
    }
</style>