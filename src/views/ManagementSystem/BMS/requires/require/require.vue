<template>
    <div class="require">
        <div class="zsykd" style="display: inline-block;">
            <table class="zhuixiaoi">
                <thead class="mmodity">
                <tr>
                    <th>序号</th>
                    <th>明细名称</th>
                </tr>
                </thead>
                <tbody class="limiting" :style="{'border-bottom':tableData.length<1?'0px':'',
                'width':tableData.length>MaxNumber?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`}">
                <tr v-for="(item,i) in tableData" :key="item.id" class="drag-list" :class="{'active': searchId == item.id}">
                    <td :style="{'color':item.s=='无效'?'#595959':''}">{{i+1}}</td>
                    <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.n}}</td>
                </tr>
                <div class="drag-list" v-if="tableData.length<1">
                    <td class="nodata">
                        <img src="@/assets/img/wu.png" alt="">
                        <div class="hint">暂无数据</div>
                    </td>
                </div>
                </tbody>
            </table>
        </div>

    </div>
</template>
<script>
import {mapState, mapMutations} from "vuex"
import IconButton from '@/components/IconButton.vue'//根据路径导入组件
import EllipsisTooltip from '@/components/EllipsisTooltip.vue'//根据路径导入组件
import CharactersButton from '@/components/CharactersButton.vue'//根据路径导入组件
export default {
  data(){
    return {
      tableData: [],//区域
      title: true,//

      windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
      MaxHeight: 0,//滚动高度
      MaxNumber: 0,//最大个数

      searchId: 0, // 查询详情的id
    }
  },
  mounted(){
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
    EllipsisTooltip,
    IconButton,
    CharactersButton
  },
  methods: {
    // 滚动最大高度
    RollMaxHeight(i){
      var s = i - 48 - 60 - 55 - 37
      this.MaxHeight = s
      this.MaxNumber = Math.floor(s / 37)
      console.log(this.MaxNumber);
    },
    // 获取区域信息内容 标记
    demand(id){
      this.$api.BMS.require.requestRqmlist({id: Number(id)}).then(res => {
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
  },
  watch: {
    windowHeigh(val) {
      this.RollMaxHeight(val)
    },
    // 监听路由变化
    '$route': {
      handler () {
        this.demand(+this.$route.params.id)
        this.searchId = this.$route.query.searchId || 0
      },
      deep: true,
      immediate: true
    },
  }
}
</script>
<style>

    .require {
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding: 20px 30px;
    }

    /* 表格无数据时展示 */
    .require .tiaodd {
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

    .require .nodata {
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        padding: 0;
    }

    .require .nodata img {
        width: 60px;
        height: 60px;
    }

    .require .nodata .hint {
        line-height: 36px;
        font-size: 13px !important;
    }

    /* 列表 */
    .zsykd {
        width: 100%;
        overflow-x: scroll !important;
    }

    .require .zhuixiaoi {
        width: 1400px;
        border-collapse: collapse;
        color: #40404e;
    }

    .require .zhuixiaoi .mmodity tr th {
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-size: 14px;
        font-weight: 600;
        padding-left: 20px;
        color: #40404e;
    }

    .require .zhuixiaoi .limiting .drag-list td {
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-size: 14px;
        font-weight: 400;
        padding-left: 20px;
    }

    .require .zhuixiaoi .limiting .drag-list {
        display: block;
        display: flex;
    }

    .require .zhuixiaoi .mmodity {
        width: 100%;
        display: block;
    }

    .require .zhuixiaoi .mmodity tr {
        display: flex;
    }
    tr.drag-list.active{
      background-color: #d7e9ff!important;
    }
    .require .zhuixiaoi .limiting {
        overflow-y: auto !important;
        max-height: 540px;
        display: block;
    }

    .require .drag-list td:nth-of-type(1), .require .mmodity th:nth-of-type(1) {
        width: 100px;
    }

    .require .mmodity th:nth-of-type(2), .require .drag-list td:nth-of-type(2) {
        width: 400px;
    }

    .require .mmodity th:nth-of-type(2), .require .drag-list td:nth-of-type(2) {
        width: 400px;
    }

    .require .drag-list:nth-of-type(odd) {
        background-color: #f9f9f9;
        color: #40404e;
    }

    .require .drag-list:nth-of-type(even) {
        background-color: #f5f5f5;
        color: #40404e;
    }
</style>

