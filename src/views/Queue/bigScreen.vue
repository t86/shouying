<template>
    <div class="container">
        <div class="header">
            <div class="title">上海Amanda阿曼达酒吧</div>
            <div class="date">2024-07-13 星期六 22:00</div>
            <!-- 全屏按钮 全屏时隐藏-->
            <div class="btn" @click="toggleFullScreen">全屏</div>
        </div>
        <div class="table">
            <div class="thead">
            <div class="tr" layout="row" layout-align="start center">
              <div class="th">类型</div>
              <div class="th">当前叫号</div>
              <div class="th">当前取号</div>
              <div class="th">等待桌数</div>
            </div>
          </div>
          <div class="tbody">
            <div
              class="tr"
              layout="row"
              layout-align="start center"
              v-for="(item, index) in tableData"
              :key="index"
            >
              <div class="td">{{item.n}}</div>
              <div class="td">{{item.c}}</div>
              <div class="td">{{item.c}}</div>
              <div class="td">{{item.c}}</div>
            </div>
            <p v-if="tableData.length == 0" class="m-t-10 fs14" style="text-align:center">暂无数据</p>
          </div>
        </div>
    </div>
</template>

<script>
export default {
    data() {
        return {
            isFullScreen: false,
            tableData: []
        }
    },
    mounted() {
        // this.fullScreen()
    },
    methods: {
        toggleFullScreen() {
            if (this.isFullScreen) {
                this.exitFullScreen()
            } else {
                this.fullScreen()
            }
        },
        fullScreen() {
            let element = document.documentElement
            if (element.requestFullscreen) {
                element.requestFullscreen()
            } else if (element.mozRequestFullScreen) {
                element.mozRequestFullScreen()
            } else if (element.webkitRequestFullscreen) {
                element.webkitRequestFullscreen()
            } else if (element.msRequestFullscreen) {
                element.msRequestFullscreen()
            }
            this.isFullScreen = true
        },
        exitFullScreen() {
            if (document.exitFullscreen) {
                document.exitFullscreen()
            } else if (document.mozCancelFullScreen) {
                document.mozCancelFullScreen()
            } else if (document.webkitExitFullscreen) {
                document.webkitExitFullscreen()
            }
            this.isFullScreen = false
        }
    }
}
</script>

<style scoped lang="less">
  @font-face {
    font-family: 'MyCustomFont';
    src: url('https://ncrm-prd.oss-cn-shanghai.aliyuncs.com/prd_pic/douyuFont-2.otf') format('opentype');
    font-weight: normal;
    font-style: normal;
  }

  body {
    box-sizing: border-box;
  }
  .container {
    font-family: 'MyCustomFont', sans-serif;
    background-size: cover;
    background-position: center center;
    background-repeat: no-repeat;
    background-image: url('../../assets/img/bigscreen.png');
    padding: 16px;
    .header {
        display: flex;
        width: 100%;
        justify-content: center;
        align-items: center;
        .title {
            font-weight: normal;
            font-size: 48px;
            color: #FFFFFF;
            line-height: 54px;
        }
        .date {
            font-family: 'PingFang-SC', sans-serif;
            font-weight: 400;
            font-size: 30px;
            color: rgba(255,255,255,0.8);
            line-height: 30px;
        }
    }
    .table{
        border-radius: 10px;
        height: calc(100vh - 90px);
        overflow-y: auto;
        .tr{
          padding: 0 20px;
          box-sizing: border-box;
          height: 36px;
          line-height: 36px;
          font-size: 14px;
        }
        .thead{
          font-family: 'PingFang-SC', sans-serif;
          position: sticky;
          top: 0;
          // background: linear-gradient(180deg, #182037 0%, #11182D 100%);
          color: rgba(255, 255, 255, .5);
        }
        .tbody{
          color: rgba(255, 255, 255, .8);
        }
        .th,td {
            display: flex;
            justify-content: center;
            align-items: center;
        }

        .th:nth-child(1), .td:nth-child(1){
          width: 25%;
        }
        .th:nth-child(2), .td:nth-child(2){
          width: 25%;
        }
        .th:nth-child(3), .td:nth-child(3){
          width: 25%;
        }
        .th:nth-child(4), .td:nth-child(4){
          width: 25%;
        }
    }
  }
</style>