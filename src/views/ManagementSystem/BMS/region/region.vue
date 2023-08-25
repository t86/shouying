<template>
    <div class="region">
        <div class="region-controller">
            <icon-button @click.native="xingh" text="新增区域" img="添加.png" colors="#383943"></icon-button>
            <icon-button @click.native="compileprinter" text="编辑" img="编辑.png" colors="#383943"></icon-button>
            <icon-button @click.native="noneffective" text="置为无效" img="无效.png" colors="#383943"></icon-button>
            <icon-button @click.native="effective" text="置为有效" img="有效.png" colors="#383943"></icon-button>
            <icon-button @click.native="printerdel" text="批量删除" img="删除.png" colors="#6B2830"
                         bjcolors="#491E24"></icon-button>
        </div>
        <div class="zsykd" style="display: inline-block;">
            <table class="zhuixiaoi">
                <thead class="mmodity">
                <tr>
                    <th>
                        <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll" @change="handleCheckAllChange">
                            全选&ensp;
                        </el-checkbox>
                    </th>
                    <th>区域名称</th>
                    <th>卡台数量</th>
                    <th>创建时间</th>
                    <th>更新时间</th>
                    <th>状态</th>
                </tr>
                </thead>
                <tbody class="limiting" :style="{'border-bottom':tableData.length<1?'0px':'',
                'width':tableData.length>MaxNumber?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`}">
                <tr v-for="(item,i) in tableData" :key="item.id" class="drag-list"
                    draggable="true" @dragstart="dragstart(item)" @dragenter="dragenter(item)" @dragend="dragend(item)">
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
                    <img src="@/assets/img/wu.png" alt="">
                    <div class="hint">暂无数据</div>
                </td>
            </div>
        </div>


        <!-- 新增  编辑-->
        <div v-show="dialogFormVisible" class="dialogFormVisible">
            <el-dialog :title="title?'新增区域':'编辑区域'" @close="dialogFormVisible = false" :visible.sync="dialogFormVisible"
                       :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>区域名称：
                        </div>
                        <el-input v-model="regionName" placeholder="请输入区域名称" ref="selectsse" maxlength="10"
                                  show-word-limit class="controlling"/>
                    </div>
                </el-form>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFormVisible = false">取消</el-button>
                    <el-button v-show="title" type="primary" @click="construction">新建</el-button>
                    <el-button v-show="!title" type="primary" @click="saveprinter">确认</el-button>
                </span>
            </el-dialog>
        </div>
    </div>
</template>
<script>
import {mapState, mapMutations} from "vuex"
import IconButton from '@/components/IconButton.vue'//根据路径导入组件
export default {
  data(){
    return {
      List: [],//全部内容
      oldItem: '',//记录初始信息
      newItem: '',// 记录过程中信息

      tableData: [],//区域
      dialogFormVisible: false,//控制新建区域是否显示
      regionName: '',//区域名称
      quantity: [],// 判断哪个要亮

      title: true,//

      multipleSelection: [],// 选中的内容
      isIndeterminate: false,// 供应商选择一部分
      checkAll: false,//供应商全选
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
  computed: {},
  components: {
    IconButton
  },
  methods: {
    // 滚动最大高度
    RollMaxHeight(i){
      var s = i - 48 - 60 - 55 - 37
      this.MaxHeight = s
      this.MaxNumber = Math.floor(s / 37)
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
        console.log(oldIndex);
        console.log(newIndex);
        var down_up = 1;
        if (oldIndex > newIndex) {
          down_up = 2
        } else if (oldIndex < newIndex) {
          down_up = 1
        }
        this.$api.BMS.region.requestregionmove_dsp({
          id: this.oldItem.id,
          dest_id: this.newItem.id,
          down_up: down_up
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.$message({showClose: true, message: "更改位置成功", type: 'success', duration: 1000})
            let newList = [...this.tableData]; // 中间数组，用于交换两个节点
            //             // 删除老的节点
            newList.splice(oldIndex, 1);
            //             // 在列表目标位置增加新的节点
            newList.splice(newIndex, 0, this.oldItem);
            //             // 更新this.List，触发transition-group的动画效果
            this.tableData = [...newList];
          } else {
            this.$message.warning(res.msg)
          }
        })
      }
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
    // 获取区域信息内容 标记
    demand(){
      this.$api.BMS.region.requestregionlist().then(res => {
        console.log(res);
        if (res.code == 1) {
          this.tableData = res.data || []
          //显示标记
          this.quantity = []
          for (const key in res.data) {
            if (this.quantity.length == 0) {
              this.quantity = [res.data[key].d == 1]
            } else {
              this.quantity.push(res.data[key].d == 1)
            }
          }
        } else {
          this.$message.warning(res.msg)
        }
      })

    },
    // 点开创建name为空
    xingh(){
      this.dialogFormVisible = true
      this.regionName = ''
      this.title = true
    },
    // 创建区域
    construction(){
      if (this.regionName == '') {
        this.$message.warning('必选框不能为空')
      } else {
        this.$api.BMS.region.requestregionnew({
          name: this.regionName
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
            this.regionName = ''
            this.bempty()
          } else {
            this.$message.warning(res.msg)
          }
        })
      }
    },
    // 编辑内容
    compileprinter(){
      if (this.multipleSelection.length == 1) {
        this.$api.BMS.region.requestregionget({id: this.multipleSelection[0]}).then(res => {
          if (res.code == 1) {
            this.regionName = res.data.name
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
      this.$api.BMS.region.requestregionsave({
        id: this.multipleSelection[0],
        name: this.regionName
      }).then(res => {
        console.log(res);
        if (res.code == 1) {
          this.$message({
            showClose: true,
            message: "操作成功",
            type: 'success'
          })
          this.demand()
          this.regionName = ''
          this.dialogFormVisible = false
          this.bempty()
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 无效
    noneffective(){
      this.$api.BMS.region.requestregiondisable({ids: this.multipleSelection}).then(res => {
        console.log(res);
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
    },
    // 有效
    effective(){
      this.$api.BMS.region.requestregionenable({ids: this.multipleSelection}).then(res => {
        // console.log(res);
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
    },
    // 删除
    printerdel(){
      if (this.multipleSelection.length > 0) {
        this.$api.BMS.region.requestregiondel({ids: this.multipleSelection}).then(res => {
          console.log(res);
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
  }
}
</script>
<style>
    /* 靠右 */
    .region .el-dialog {
        margin: 0px 0px 0px auto !important;
        background-color: #1A1A20;
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
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;
    }

    .region .el-dialog {
        border-left: 1px solid #f9f9f9;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
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

    .region .el-input__suffix {
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
        width: 1600px;
        background-color: #202026;
        display: flex;
        align-items: center;
        border-top: 1px solid #2c2d36;
    }

    .region .dialogFormVisible .el-dialog {
        width: 500px !important;
    }

    .region .el-dialog .el-button--default {
        background-color: #ccc!important;
        border: 1px solid #ccc!important;
        color: #40404e!important;
    }

    .region .el-dialog {
        background-color: #f9f9f9;
    }

    .region .el-dialog__header, .region .el-dialog__footer {
        background-color: #1a1a21;
    }

    .region .el-dialog__title, .region .el-dialog__headerbtn .el-dialog__close, .region .el-form-item__label {
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
        background-color: rgba(0, 0, 0, 0);
    }

    /* 列表 */
    .zsykd {
        width: 100%;
        overflow-x: scroll !important;
    }

    .region .zhuixiaoi {
        width: 1600px;
        border-collapse: collapse;
        color: #40404e;
    }

    .region .zhuixiaoi .mmodity tr th {
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-size: 14px;
        font-weight: 400;
        padding-left: 20px;
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
        border-top: solid 1px #383943;
        display: block;
        display: flex;
    }

    .region .zhuixiaoi .mmodity {
        width: 100%;
        display: block;
    }

    .region .zhuixiaoi .mmodity tr {
        border-top: solid 1px #383943;
        background-color: #2d2e38;
        display: flex;
    }

    .region .zhuixiaoi .limiting {
        overflow-y: auto !important;
        max-height: 540px;
        border-bottom: solid 1px #383943;
        display: block;
    }

    .region .drag-list td:nth-of-type(1), .region .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .region .mmodity th:nth-of-type(2), .region .drag-list td:nth-of-type(2) {
        width: 240px;
    }

    .region .drag-list td:nth-of-type(3), .region .mmodity th:nth-of-type(3) {
        width: 140px;
    }

    .region .drag-list td:nth-of-type(4), .region .mmodity th:nth-of-type(4) {
        width: 140px;
    }

    .region .drag-list td:nth-of-type(5), .region .mmodity th:nth-of-type(5) {
        width: 140px;
    }

    .region .drag-list td:nth-of-type(6), .region .mmodity th:nth-of-type(6) {
        width: 60px;
    }

    .region .drag-list:nth-of-type(odd) {
        background-color: #1A1A20;
        color: #40404e;
    }

    .region .drag-list:nth-of-type(even) {
        background-color: #1F1F25;
        color: #40404e;
    }

    /* 全选颜色 */
    .region .zhuixiaoi .el-checkbox__label {
        color: #40404e;
    }

    .region .zhuixiaoi .mmodity .el-checkbox__label {
        font-size: 12px;
    }
</style>

