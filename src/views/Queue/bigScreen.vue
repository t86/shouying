<template>
    <div class="container">
        <div class="header">
            <div class="title">上海Amanda阿曼达酒吧</div>
            <div class="date">{{ formattedDate }}</div>
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
              <div class="td">{{item.queue_type_id}}</div>
              <div class="td">{{item.curr_num > 0 || ''}}</div>
              <div class="td">{{item.num}}</div>
              <div class="td">{{item.num_cnt}}</div>
            </div>
            <p v-if="tableData.length == 0" class="m-t-10 nodata" style="text-align:center">暂无数据</p>
          </div>
        </div>
    </div>
</template>

<script>
import { QUEUE_TASK } from "@/observer";
export default {
    data() {
        return {
            isFullScreen: false,
            tableData: [],
            formattedDate: ''
        }
    },

    mounted() {
      console.log(
        '排队数据',
          this.$store.state.cardPageInfo.resResultDataObj.queueConfig, 
          this.$store.state.cardPageInfo.resResultDataObj.queueType,
          this.$store.state.cardPageInfo.resResultDataObj.queueRecord,
          this.$store.state.cardPageInfo.resResultDataObj.queueCurNumber);

      this.callback = () => {
        this.tableData = [...this.$store.state.cardPageInfo.resResultDataObj.queueCurNumber]
        console.log(
          this.$store.state.cardPageInfo.resResultDataObj.queueConfig, 
          this.$store.state.cardPageInfo.resResultDataObj.queueType,
          this.$store.state.cardPageInfo.resResultDataObj.queueRecord,
          this.$store.state.cardPageInfo.resResultDataObj.queueCurNumber
          );
      }
      this.$observer.subscribe(QUEUE_TASK, this.callback);
      setInterval(this.updateTime, 1000);
    },
    beforeDestroy() {
      this.$observer.unsubscribe(QUEUE_TASK, this.callback);
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
        },
        formatDate(date) {
          const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
          const year = date.getFullYear();
          const month = String(date.getMonth() + 1).padStart(2, '0');
          const day = String(date.getDate()).padStart(2, '0');
          const hours = String(date.getHours()).padStart(2, '0');
          const minutes = String(date.getMinutes()).padStart(2, '0');
          const weekday = weekdays[date.getDay()];

          return `${year}-${month}-${day} ${weekday} ${hours}:${minutes}`;
        },
        updateTime() {
          const now = new Date();
          this.formattedDate = this.formatDate(now);
          console.log(this.formattedDate);
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
    box-sizing: border-box;
    font-family: 'MyCustomFont', sans-serif;
    background-size: cover;
    background-position: center center;
    background-repeat: no-repeat;
    background-image: url('../../assets/img/bigscreen.png');
    padding: 16px;
    height: 100vh;
    width: 100vw;
    .header {
        display: flex;
        width: 100%;
        justify-content: center;
        align-items: center;
        position: relative;
        .title {
            font-weight: normal;
            font-size: 48px;
            color: #FFFFFF;
            line-height: 54px;
        }
        .date {
            position: absolute;
            right: 0;
            top: 0px;
            font-family: 'PingFang-SC', sans-serif;
            font-weight: 400;
            font-size: 30px;
            color: rgba(255,255,255,0.8);
            line-height: 30px;
        }
    }
    .table{
        border-radius: 10px;
        height: 100%;
        padding-top: 180px;
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
          .th {
            font-weight: 500;
            font-size: 40px;
            color: rgba(255,255,255,0.8);
            line-height: 40px;
          }
          
        }
        .tbody{
          color: rgba(255, 255, 255, .8);
          .nodata {
            font-weight: 500;
            font-size: 40px;
            color: rgba(255,255,255,0.8);
            line-height: 40px;
          }
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