<template>
    <div class="container">
        <div class="header">
            <div class="title">{{ orgName }}</div>
            <div class="date">{{ formattedDate }}</div>
        </div>
        <div class="table">
            <div class="thead">
            <div class="tr">
              <div class="th">类型</div>
              <div class="th">当前叫号</div>
              <div class="th">当前取号</div>
              <div class="th">等待叫号</div>
              <div class="th">等待桌数</div>
            </div>
          </div>
          <div class="tbody">
            <div
              class="tr"
              v-for="(item, index) in typeList"
              :key="index"
            >
              <div class="td">{{item.name}}</div>
              <div class="td">{{item.curr_num}}</div>
              <div class="td">{{item.num}}</div>
              <div class="td">{{item.wait}}</div>
              <div class="td">{{item.num_cnt}}</div>
            </div>
            <p v-if="typeList.length === 0" class="m-t-10 nodata" style="text-align:center">暂无数据</p>
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
            formattedDate: '',
            orgName: '',
            typeList: [], // 排队类型
            currents: [],
            queues: [],
        }
    },

    async mounted() {
      // 清除 body 和 html 的默认边距
      document.body.style.margin = '0';
      document.body.style.padding = '0';
      document.documentElement.style.margin = '0';
      document.documentElement.style.padding = '0';
      document.body.style.overflow = 'hidden';
      
      setTimeout(() => {
        document.onkeydown = this.keydownHandle;
      }, 200);
      await this.getData()
      this.callback = () => {
        this.getData()
      }
      this.$observer.subscribe(QUEUE_TASK, this.callback);
      setInterval(this.updateTime, 5000);
      this.orgName = this.$store.state.cardPageInfo.resResultDataObj.storeStatusInfo.org_name
    },
    beforeDestroy() {
      // 恢复 body 和 html 的原始样式
      document.body.style.margin = '';
      document.body.style.padding = '';
      document.documentElement.style.margin = '';
      document.documentElement.style.padding = '';
      document.body.style.overflow = '';
      
      this.$observer.unsubscribe(QUEUE_TASK, this.callback);
    },
    methods: {
      keydownHandle(e){
        // console.log(e.keyCode)
        if (e.keyCode === 13){
          this.toggleFullScreen()
        }
      },
      async getData(){
        let config = this.$store.state.cardPageInfo.resResultDataObj.queueConfig || [] // 46 配置
        let types = this.$store.state.cardPageInfo.resResultDataObj.queueType || [] //47 排队类型
        let currents = this.$store.state.cardPageInfo.resResultDataObj.queueCurNumber || []//49 当前取号

        console.log('------------config', config)
        console.log('------------types', types)
        console.log('------------scurrents', currents)

        if (config && config.length > 0) {
          this.numberType = config[0].number_type
        }
        for(let _type of types) {
          let idx = currents.findIndex(current => current.queue_type_id === _type.id)
          if (idx >= 0) {
            let finder = currents[idx]

            let cur_num
            let wait_num
            let last_gen_num


            if(this.numberType * 1 === 1) {
              // cur_num = _type.num_prefix + finder.curr_no
              cur_num = finder.curr_no
              wait_num = finder.wait_no
              last_gen_num = finder.last_gen_num
            } else if (this.numberType * 1 === 2) {
              cur_num = finder.curr_no.padStart(2, 0)
              last_gen_num = finder.last_gen_num.padStart(2, 0)
              wait_num = finder.wait_no.padStart(2, 0)
            } else if (this.numberType * 1 === 3) {
              cur_num = finder.curr_no.padStart(3, 0)
              last_gen_num = finder.last_gen_num.padStart(3, 0)
              wait_num = finder.wait_no.padStart(3, 0)
            }

            if(finder.curr_no * 1 === 0) {
              _type.curr_num = '-'
            } else {
              _type.curr_num = _type.num_prefix  + cur_num
            }
            if(finder.wait_no * 1 === 0) {
              _type.wait = '-'
            } else {
              _type.wait =  _type.num_prefix + wait_num
            }

            _type.curr_num_id = finder.curr_no
            _type.num = _type.num_prefix + last_gen_num
            _type.num_cnt = finder.wait_cnt

            _type.wait_no = finder.wait_no
            _type.current_status = finder.curr_no_status
          } else {
            _type.curr_num = '-'
            _type.curr_num_id = -1
            _type.num = '-'
            _type.num_cnt = '-'
            _type.wait =  '-'
            _type.wait_no  = -1
            _type.current_status = -1
          }
        }
        this.typeList = types
      },
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
    background-image: url('../../assets/img/bigscreen.webp');
    padding: 0 !important;
    margin: 0 !important;
    height: 100vh !important;
    width: 100vw !important;
    min-height: 100vh !important;
    min-width: 100vw !important;
    position: fixed !important;
    top: 0 !important;
    left: 0 !important;
    right: 0 !important;
    bottom: 0 !important;
    display: flex !important;
    flex-direction: column !important;
    align-items: center !important;
    justify-content: flex-start !important;
    overflow: hidden !important;
    .header {
        display: flex;
        width: 92%;
        max-width: 1400px;
        justify-content: center;
        align-items: center;
        position: relative;
        padding: 30px 0 20px 0;
        margin: 0 auto;
        .title {
            font-weight: normal;
            font-size: 48px;
            color: #FFFFFF;
            line-height: 54px;
        }
        .date {
            position: absolute;
            right: 0;
            top: 30px;
            font-family: 'PingFang-SC', sans-serif;
            font-weight: 400;
            font-size: 30px;
            color: rgba(255,255,255,0.8);
            line-height: 30px;
        }
    }
    .table{
        border-radius: 10px;
        width: 92%;
        max-width: 1400px;
        flex: 1;
        overflow-y: auto;
        box-sizing: border-box;
        display: flex !important;
        flex-direction: column !important;
        padding: 30px 0;
        margin: 0 auto;

        .thead{
          display: flex !important;
          flex-direction: column !important;
          font-family: 'PingFang-SC', sans-serif;
          color: rgba(255, 255, 255, .5);
          width: 100%;
          
          .tr {
            display: flex !important;
            width: 100% !important;
          }
          
          .th {
            flex: 1 !important;
            text-align: center !important;
            vertical-align: middle !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            font-weight: 500;
            font-size: 36px;
            color: rgba(255,255,255,0.8);
            line-height: 36px;
            padding: 20px 10px;
          }
        }

      .tbody{
          display: flex !important;
          flex-direction: column !important;
          font-family: 'PingFang-SC', sans-serif;
          color: rgba(255, 255, 255, .8);
          width: 100%;
          
          .tr {
            display: flex !important;
            width: 100% !important;
          }
          
          .nodata {
            font-weight: 500;
            font-size: 40px;
            color: rgba(255,255,255,0.8);
            line-height: 40px;
          }
          
          .td {
            flex: 1 !important;
            text-align: center !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            font-weight: 500;
            font-size: 36px;
            color: rgba(255,255,255,0.8);
            line-height: 60px;
            padding: 15px 10px;
          }
        }



    }
  }
</style>