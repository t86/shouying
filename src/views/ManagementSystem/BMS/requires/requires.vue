<template>
    <div class="requires">
        <div class="searchselect">
            <el-input v-model="nr" prefix-icon="el-icon-search" class="classifysearch" placeholder="搜索" clearable
                      @clear="dainj"/>
            <div class="collapse" v-show="sfshow" :style="{'max-height':`${MaxHeight}px`, 'padding-left': '10px'}">
                <el-collapse v-model="stairNames" @change="stairhandleChange" accordion>
                    <el-collapse-item name="全部">
                        <router-link to="/BMS/requires/requireType"
                                     slot="title" class="routerlinkyus collapse-title">
                            <img class="icons" src="@/assets/img/文件夹.png" alt="">
                            <ellipsis-tooltip text="全部"></ellipsis-tooltip>
                        </router-link>
                        <!--要求类型列表 stair -->
                        <div v-for="(stair,i) in classify" :style="{'background-color':gaibland==stair.id?'#d7e9ff':''}"
                             style="width: calc(100% - 35px);padding-left: 35px;border-radius:6px"
                             :key="i" class="collapse-title" @click="secondhandleChange(stair)">
                            <img class="icons" src="@/assets/img/文件夹.png" alt="">
                            <router-link :to="`/BMS/requires/require/${stair.id}`" class="routerlinkyus" style="width: calc(100% - 18px);">
                                <ellipsis-tooltip :text="stair.n || '-----'"></ellipsis-tooltip>
                            </router-link>
                        </div>
                    </el-collapse-item>
                </el-collapse>
            </div>
            <div class="eresult" v-show="!sfshow">
                <div class="lbao" v-show="searchesult.sl > 0">
                    <div class="liebia" v-show="searchesult.yij.length > 0">要求类型列表：</div>
                    <div class="yansnafe" v-show="searchesult.yij.length > 0">
                        <div class="lbnrs" v-for="(stair,i) in searchesult.yij" :key="i" @click="xuanzyij(stair.id+'')">
                            <img class="icons" src="@/assets/img/文件夹.png" alt="">
                            <ellipsis-tooltip :text="stair.n || '-----'"></ellipsis-tooltip>
                        </div>
                    </div>
                    <div class="liebia" v-show="searchesult.erj.length > 0">要求明细列表：</div>
                    <div class="yansnafe" v-show="searchesult.erj.length > 0">
                        <div class="lbnrs" v-for="(stair,i) in searchesult.erj" :key="i"
                             @click="xuanzerj(stair.id, stair.rt)">
                            <img class="icons" src="@/assets/img/文件夹.png" alt="">
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
        <div style="width: calc(100% - 200px);">
            <router-view/>
        </div>
    </div>
</template>
<script>
import IconButton from '@/components/IconButton.vue'//根据路径导入组件
import EllipsisTooltip from '@/components/EllipsisTooltip.vue'//根据路径导入组件
export default {
  data() {
    return {
      nr: '',// 搜索内容
      stairNames: '全部',// 全部
      secondNames: '',// 要求类型id
      classify: [],//要求类型/要求明细数据

      gaibland: '全部',//选中哪一个状态

      searchesult: {
        yij: [],
        erj: [],
        sl: ''
      },//模糊查询结果
      sfshow: true,//是否查询

      windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
      MaxHeight: 0,//滚动高度


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

  },
  components: {
    EllipsisTooltip,
    IconButton
  },

  methods: {
    // 请求数据
    demand(){
      this.$api.BMS.require.requestRqmTree().then(res => {
        if (res.code == 1) {
          // console.log(res.data);
          this.classify = res.data || [];
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 请求要求类型数据
    stairhandleChange(val) {
      this.secondNames = "全部";
    },
    // 请求要求明细数据 获取要求类型id
    secondhandleChange(item){
      this.secondNames = item.id;
    },

    // 给要求明细添加要求类型id
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
      this.$router.push(`/BMS/requires/require/${id}`)

    },
    // 查询选择 二级
    xuanzerj(id, rt){
      this.$router.push(`/BMS/requires/require/${rt}?searchId=${id}`)
    },

    dainj(){
      console.log(1234);
    },

    // 滚动最大高度
    RollMaxHeight(i){
      var s = i - 48 - 60 - 34 - 10
      this.MaxHeight = s
    }

  },
  computed: {},
  watch: {
    $route(newVal){
      this.gaibland = newVal.params.id
      this.nr = ''
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
              sl: ''
            }
            this.sfshow = false
            this.$api.BMS.require.requestRqmSearch({name: after}).then(res => {
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
    secondNames: {
      deep: true,
      handler: function (after, before) {
        // console.log(after);
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
    .requires {
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
    .requires .eresult {

        /* padding-right: 6px; */
        max-height: 700px;
        overflow-x: scroll;
        overflow: overlay;
    }

    .requires .eresult .lbao {
        margin-top: 20px;
    }

    .requires .eresult .lbao .liebia {
        height: 40px;
        line-height: 40px;
        font-size: 12px;
        color: #8C8C8C;
        padding-left: 10px;
    }

    .requires .eresult .lbao .yansnafe {
        margin: 0 10px;
        border-radius: 6px;
    }

    .requires .eresult .lbao .lbnrs {
        height: 40px;
        width: 100%;
        display: flex;
        align-items: center;
        cursor: pointer;
    }

    .requires .eresult .lbao .lbnrs img {
        margin-left: 14px;
        width: 14px;
        height: 14px;
    }

    .requires .eresult .lbao .lbnrs div {
        margin-left: 4px;
        color: #40404e;
        font-size: 14px;
    }

    .requires .searchselect .eresult .meiy {
        display: flex;
        flex-direction: column;
        align-items: center;
        padding-top: 128px;
    }

    .requires .searchselect .eresult .meiy img {
        width: 60px;
        height: 60px;
    }

    .requires .searchselect .eresult .meiy div {
        margin-top: 20px;
        font-size: 14px;
        color: #40404e;
    }
</style>
<style>
    /* 表格无数据时展示 */
    .requires .drag-list .nodata {
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
    }

    .requires .drag-list .nodata img {
        width: 60px;
        height: 60px;
    }

    .requires .drag-list .nodata .hint {
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
        color: #40404E
    }

    .el-select-dropdown {
        border: 1px solid #f5f5f5;
    }

    /* 靠右 */
    .requires .el-dialog {
        margin: 0px 0px 0px auto !important;
        height: 100%;
        position: relative;
    }

    .requires .el-dialog__body {
        padding: 0px 0px 30px 20px;
        overflow-y: scroll !important;
        width: 100%;
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;

    }

    .requires .el-dialog {
        border-left: 1px solid #f9f9f9;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .requires .el-dialog__footer {
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }
</style>