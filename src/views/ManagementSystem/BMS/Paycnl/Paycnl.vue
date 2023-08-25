<template>
    <div class="channel">
      <p class="m-t-3 m-b-3 fs14" style="color:#ec808d">提示：请勾选门店使用的支付渠道，去掉勾选则无法使用该渠道结账；“自适应”代表自适应门店业务</p>
        <div class="zsykd" style="display: inline-block;">
            <table class="zhuixiaoi">
                <thead class="mmodity">
                <tr>
                    <th>序号</th>
                    <th>支付渠道</th>
                    <th>启用</th>
                </tr>
                </thead>
                <tbody class="limiting" :style="{'border-bottom':List.length<1?'0px':'',
                'width':List.length>MaxNumber?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`}">
                <tr v-for="(item,i) in List" :key="item.id" class="drag-list">
                    <td>
                      {{i+1}}
                    </td>
                    <td>{{item.n || '---'}}</td>
                    <td>
                      <el-checkbox v-if="item.id < 100 || item.id == 500" v-model="item.checked" @change="changeSelectHandle(item)"></el-checkbox>
                      <span v-else>自适应</span>
                    </td>
                </tr>
                <div class="drag-list" v-if="List.length<1">
                    <td class="nodata" :style="{'height':`${MaxHeight}px !important`}">
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
export default {
  data() {
    return {
      List: [],//全部内容
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
  methods: {
    // 滚动最大高度
    RollMaxHeight(i){
      var s = i - 48 - 60 - 60
      this.MaxHeight = s
      this.MaxNumber = Math.floor(s / 37)
    },
    // 请求数据
    demand(){
      this.$api.BMS.paycnl.requestpaycnllist().then(res => {
        if (res.code == 1) {
          const isAllNotChoose = (res.data || []).filter(item => item.id < 100 || item.id == 500).some(item => item.iu == 1)
          const result = (res.data || []).map(item => ({
            ...item,
            checked: isAllNotChoose ? item.iu == 1 : true
          }))
          this.List = [...result.filter(item => item.id < 100), ...result.filter(item => item.id == 500), ...result.filter(item => item.id > 100 && item.id != 500)]
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    async changeSelectHandle(itemInfo){
      const api = itemInfo.checked ? 'reqSelectItem' : 'reqNotSelectItem'
      const params = {
        id: itemInfo.id * 1 //  int64  支付渠道Id
      }

      try {
        const res = await this.$api.BMS.paycnl[api](params)
        if(res.code == 1) {
          this.$message.success('操作成功')
        }
      } catch (error) {
        console.log('操作支付渠道失败', error)
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
  }
}
</script>
<style>
    .channel {
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding: 20px 30px;
    }

    .channel-headline {
        font-size: 30px;
        font-weight: bold;
        color: #40404e;
    }

    .channel .channel-controller {
        /*margin-top: 30px;*/
        margin-bottom: 30px;
    }

    /* 表格无数据时展示 */
    .channel .tiaodd {
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

    .channel .nodata {
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        padding: 0;
    }

    .channel .nodata img {
        width: 60px;
        height: 60px;
    }

    .channel .nodata .hint {
        line-height: 36px;
        font-size: 13px !important;
    }

    /* 列表 */
    .zsykd {
        width: 100%;
        overflow-x: scroll !important;
    }

    .channel .zhuixiaoi {
        width: 100%;
        border-collapse: collapse;
        color: #40404e;
    }

    .channel .zhuixiaoi .mmodity tr th {
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-size: 14px;
        font-weight: 600;
        color: #40404e;
        padding-left: 20px;
    }

    .channel .zhuixiaoi .limiting .drag-list td {
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-size: 14px;
        font-weight: 400;
        padding-left: 20px;
    }

    .channel .zhuixiaoi .limiting .drag-list {
        display: block;
        display: flex;
    }

    .channel .zhuixiaoi .mmodity {
        width: 100%;
        display: block;
    }

    .channel .zhuixiaoi .mmodity tr {
        display: flex;
        background-color: #f5f5f5;
    }

    .channel .zhuixiaoi .limiting {
        overflow-y: auto !important;
        max-height: 540px;
        display: block;
    }

    .channel .Pagingss .zhuixiaoi .limiting {
        overflow-y: auto !important;
        max-height: 540px;
        border-bottom: solid 1px #383943;
        display: block;
    }

    .channel .Pagingss .check {
        color: #40404e;
        margin-bottom: 20px;
        padding-top: 30px;
        font-size: 16px;
    }

    .channel .drag-list td:nth-of-type(1), .channel .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .channel .mmodity th:nth-of-type(2), .channel .drag-list td:nth-of-type(2) {
        width: 330px;
    }

    .channel .drag-list:nth-of-type(odd) {
        background-color: #f9f9f9;
        color: #40404e;
    }

    .channel .drag-list:nth-of-type(even) {
        background-color: #f5f5f5;
        color: #40404e;
    }




</style>
