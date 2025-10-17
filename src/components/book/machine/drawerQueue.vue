<template>
  <div>
    <el-drawer
      title="排队详情"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="90%"
    >
    <el-tabs v-model="activeTab" @tab-click="handleClick" class="tab-list" >
      <el-tab-pane label="排队叫号" name="1" class="tab-pane">
        <div class="table">
          <div class="content">
            <div class="thead">
              <div class="tr">
                <div class="th w120" style="background-color: #182037;">类型</div>
                <div class="th w120">当前叫号</div>
                <div class="th w120">当前取号</div>
                <div class="th w120">等待桌数</div>
                <div class="th w120">等待叫号</div>
                <div class="th w200">操作</div>
              </div>
            </div>
            <div class="tbody" ref="scrollDom">
              <div
                  v-if="typeList.length==0"
                  style="text-align:center;transform:translateY(40px)"
              >暂无数据</div>
              <div v-else ref="scrollItem">
                <div class="coll" v-for="(item,i) in typeList" :key="i">
                  <div class="detail tr">
                    <div class="td w120" :style=" {backgroundColor : i % 2== 0 ? '#202c42' : '#293449'}">{{item.name}}</div>
                    <div class="td w120">{{item.curr_num}}</div>
                    <div class="td w120">{{item.num}}</div>
                    <div class="td w120">{{item.num_cnt}}</div>
                    <div class="td w120">{{item.wait}}</div>
                    <div class="td">
                      <div class="action">
<!--                        <el-button  key="1" type="primary" :disabled="!item.canCall" class="btn" size="medium" @click="call(item)">叫号</el-button>-->
                        <div class="btn"
                             :class="{ active: item.canCall }"
                             @click.stop="call(item)">
                          <span>叫号</span>
                        </div>

                        <div class="btn"
                             :class="{ active: item.canEnter }"
                             @click.stop="enter(item)">
                          <span>进店</span>
                        </div>


                        <div class="btn"
                             :class="{ active: item.canOverdue }"
                             @click.stop="overdue(item)">
                          <span>过号</span>
                        </div>

<!--                        <el-button key="2" type="primary" :disabled="!item.canEnter"  class="btn" size="medium" @click="enter(item)">进店</el-button>-->
<!--                        <el-button key="3" type="primary" :disabled="!item.canOverdue"  class="btn" size="medium" @click="overdue(item)">过号</el-button>-->
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </el-tab-pane>
      <el-tab-pane label="排队列表" name="2" class="tab-pane">
        <div class="header">
          <div class="queue-type-layout">
            <div class="label">排队类型：</div>
            <div class="btn" v-for="(item, index) in typeList" :key="index" @click="onTypeClick(item)" :class="{'btn-selected': item.id === checkType}">{{ item.name }}</div>

          </div>
          <div class="queue-status-layout">
            <div class="label">状态：</div>
            <div class="btn" v-for="(item, index) in statusList" :key="index" @click="onStatusClick(item)" :class="{'btn-selected': item.id === checkStatus}">{{ item.name }}</div>
          </div>
        </div>

        <div class="table">
          <div class="content">
            <div class="thead">
              <div class="tr">
                <div class="th w120" style="background-color: #182037;">排队号码</div>
                <div class="th w120">排队类型</div>
                <div class="th w120">客户姓名</div>
                <div class="th w120">前方桌数</div>
                <div class="th w120">状态</div>
                <div class="th w120">电话</div>
                <div class="th w200">等待时间</div>
                <div class="th w200">取号时间</div>
              </div>
            </div>
            <div class="tbody" ref="scrollDom">
              <div
                  v-if="queues.length===0"
                  style="text-align:center;transform:translateY(40px)"
              >暂无数据</div>
              <div v-else ref="scrollItem">
                <div class="coll" v-for="(item,i) in queues" :key="i" :style="{ display: item.show ? '' : 'none'}">
                  <div class="detail tr">
                    <div class="td w120" :style=" {backgroundColor : i % 2== 0 ? '#202c42' : '#293449'}">{{item.queue_no_name}}</div>
                    <div class="td w120">{{item.queue_name}}</div>
                    <div class="td w120">{{item.name}}</div>
                    <div class="td w120">{{item.desk_cnt}}</div>
                    <div class="td w120">{{item.status_name}}</div>
                    <div class="td w120">{{item.phone_num}}</div>
                    <div class="td w200">{{item.wait_time_t }}</div>
                    <div class="td w200">{{item.obtain_time_t}}</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </el-tab-pane>

    </el-tabs>

      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import {QUEUE_TASK} from "@/observer";
import {cardPageMixins} from "@/mixin/cardPage";
import api from "@/api";
import api_money from "@/api/money";

export default {
  data () {
    return {
      timer: null,
      show: false,
      numberType: 1,
      loadTime: '',
      activeTab: '1', // 排队叫号 1 排队列表 2
      typeList: [], // 排队类型
      currents: [],
      checkType: -1, // 选中的排队类型
      queues: [],
      statusList: [
        {
          name: '排队中',
          id: "1"
        },
        {
          name: '已过号',
          id: "2"
        },
        {
          name: '已取消',
          id: "3"
        },
        {
          name: '已进店',
          id: "5"
        },
      ], // 状态
      checkStatus: -1, // 选中的状态
      callback: null,
      // 音频播放相关
      audioBaseUrl: 'http://nls.server.com/server/wavs/',
      currentAudio: null, // 当前播放的音频实例
      audioQueue: [], // 待播放的音频队列
      isPlaying: false, // 是否正在播放
      queueConfig: null // 排队配置
    };
  },
  async mounted() {
    // console.log('mountedmountedmountedmountedmountedmountedmounted')
    // this.callback =  () => {
    // }
    // this.$observer.subscribe(QUEUE_TASK, this.callback);
  },
  beforeDestroy() {
    // 停止音频播放
    this.stopAudio();
    
    if (this.timer) {
      clearInterval(this.timer);
    }
    if (this.callback) {
      this.$observer.unsubscribe(QUEUE_TASK, this.callback);
    }
  },
  methods: {
    // 停止音频播放
    stopAudio() {
      if (this.currentAudio) {
        this.currentAudio.pause();
        this.currentAudio.currentTime = 0;
        this.currentAudio = null;
      }
      this.audioQueue = [];
      this.isPlaying = false;
    },

    // 根据号码生成音频文件列表 (例如: A12 -> ['A', '1', '2'])
    generateAudioFiles(queueNo) {
      const files = [];
      const queueNoStr = String(queueNo).toUpperCase();
      
      for (let i = 0; i < queueNoStr.length; i++) {
        const char = queueNoStr[i];
        files.push(`${this.audioBaseUrl}${char}.WAV`);
      }
      
      return files;
    },

    // 播放下一个音频
    playNextAudio() {
      if (this.audioQueue.length === 0) {
        this.isPlaying = false;
        this.currentAudio = null;
        return;
      }

      const audioUrl = this.audioQueue.shift();
      this.currentAudio = new Audio(audioUrl);
      
      this.currentAudio.addEventListener('ended', () => {
        this.playNextAudio();
      });

      this.currentAudio.addEventListener('error', (e) => {
        console.error('音频播放失败:', audioUrl, e);
        // 继续播放下一个
        this.playNextAudio();
      });

      this.currentAudio.play().catch(err => {
        console.error('播放音频时出错:', err);
        // 继续播放下一个
        this.playNextAudio();
      });
    },

    // 播放音频序列
    playAudioSequence(queueNo) {
      // 检查配置
      if (!this.queueConfig) {
        console.log('排队配置不存在，跳过音频播放');
        return;
      }

      // 检查语音播报开关
      if (this.queueConfig.sound_on * 1 !== 1) {
        console.log('语音播报已关闭');
        return;
      }

      // 停止当前正在播放的音频
      this.stopAudio();

      // 获取播放次数
      const repeatCount = this.queueConfig.sound_cnt * 1 || 1;
      
      // 生成单次播放的音频文件列表
      const singlePlayList = [
        `${this.audioBaseUrl}PREFIX.WAV`,
        ...this.generateAudioFiles(queueNo),
        `${this.audioBaseUrl}SUFFIX.WAV`
      ];

      // 根据播放次数重复
      this.audioQueue = [];
      for (let i = 0; i < repeatCount; i++) {
        this.audioQueue.push(...singlePlayList);
      }

      console.log('开始播放音频队列:', this.audioQueue);
      
      this.isPlaying = true;
      this.playNextAudio();
    },

    async call(item){
      console.log(item)
      let queue_no
      if (item.current_status * 1 === 1){
        queue_no = item.curr_num_id * 1
      } else if (item.current_status * 1 === 2 || item.current_status * 1 === 5){
        queue_no = item.wait_no * 1
      } else if (item.current_status * 1 === 0){
        queue_no = item.wait_no * 1
      }
      this.showConfirmHandle(
          "叫号",
          "是否确认叫号",
          async () => {
            try {
              let params = {
                queue_type_id:  item.id * 1,    //QueueTypeId 排队类型Id
                queue_no: queue_no     //QueueNo 排队号
              }
              const res =  await api_money.reqQueueCall(params)
              if (res.code === 1) {
                this.$message.success("叫号成功");
                // 播放叫号音频
                this.playAudioSequence(item.curr_num);
              } else {
                this.$message.warning(res.msg);
              }
            } catch (error) {
              console.log("叫号失败", error);
            }
          }
      );
    },
    async enter(item){
      console.log(item)
      let queue_no
      if (item.current_status * 1 === 1){
        queue_no = item.curr_num_id * 1
      } else {
        return
      }
      this.showConfirmHandle(
          "进店",
          "是否确认客人已进店",
          async () => {
            try {
              let params = {
                queue_type_id:  item.id  * 1,    //QueueTypeId 排队类型Id
                queue_no: queue_no     //QueueNo 排队号
              }
              const res =  await api_money.reqQueueEnter(params)
              if (res.code === 1) {
                this.$message.success("进店成功");
                // 停止音频播放
                this.stopAudio();
              } else {
                this.$message.warning(res.msg);
              }
            } catch (error) {
              console.log("进店失败", error);
            }
          }
      );
    },
    async overdue(item){
      console.log(item)
      let queue_no
      if (item.current_status * 1 === 1){
        queue_no = item.curr_num_id * 1
      } else {
        return
      }
      this.showConfirmHandle(
          "过号",
          "是否设置为过号?操作后不可撤销",
          async () => {
            try {
              let params = {
                queue_type_id:  item.id * 1,    //QueueTypeId 排队类型Id
                queue_no: queue_no,      //QueueNo 排队号
              }
              const res =  await api_money.reqQueueOverdue(params)
              if (res.code === 1) {
                this.$message.success("设置过号成功");
                // 停止音频播放
                this.stopAudio();
              } else {
                this.$message.warning(res.msg);
              }
            } catch (error) {
              console.log("设置过号失败", error);
            }
          }
      );
    },

    closeDrawerHandle () {
      this.$emit("showOrHideDrawer", false);
      // 停止音频播放
      this.stopAudio();
    },

    onCancelDrawer () {
      this.closeDrawerHandle();
      if (this.timer) {
        clearInterval(this.timer);
      }
      this.$observer.unsubscribe(QUEUE_TASK, this.callback);
    },

    async updateQueueWait() {
      this.timer = setInterval(async () => { // 使用箭头函数，确保this指向正确
        try {
          console.log('updateQueueWait....')
          this.queues.forEach(a => {
            let now = new Date()
            if(a.status * 1 !== 1) {
              let timestamp = a.update_time
              const year = parseInt(timestamp.substring(0, 4), 10);
              const month = parseInt(timestamp.substring(4, 6), 10) - 1; // 月份从0开始
              const day = parseInt(timestamp.substring(6, 8), 10);
              const hour = parseInt(timestamp.substring(8, 10), 10);
              const minute = parseInt(timestamp.substring(10, 12), 10);
              const second = parseInt(timestamp.substring(12, 14), 10);
              now = new Date(year, month, day, hour, minute, second);
            }
            a.wait_time_t = this.formatTimeDifference(a.obtain_time, now)
          })
          this.queues = [...this.queues]
        } catch (e) {
          if (this.timer) {
            clearInterval(this.timer);
          }
          this.timer = null;
        }
      }, 1000*60)
    },

    handleClick(tab, event) {
      console.log(tab, event);
      this.activeTab = tab.name;
    },
    onTypeClick(item) {
      if (this.checkType === item.id) {
        this.checkType = -1
      } else {
        this.checkType = item.id;
      }
    },
    onStatusClick (item) {
      console.log('onStatusClick', item);
      if (this.checkStatus === item.id) {
        this.checkStatus = -1
      } else {
        this.checkStatus = item.id;
      }
    },
    formatTimeDifference(timestamp, now= new Date()) {
      // 将时间字符串解析为Date对象
      const year = parseInt(timestamp.substring(0, 4), 10);
      const month = parseInt(timestamp.substring(4, 6), 10) - 1; // 月份从0开始
      const day = parseInt(timestamp.substring(6, 8), 10);
      const hour = parseInt(timestamp.substring(8, 10), 10);
      const minute = parseInt(timestamp.substring(10, 12), 10);
      const second = parseInt(timestamp.substring(12, 14), 10);

      const targetDate = new Date(year, month, day, hour, minute, second);
      // const now = new Date();

      // 计算时间差值（以毫秒为单位）
      const diffMilliseconds = Math.abs(now - targetDate);

      // 将毫秒转换为分钟和小时
      const diffMinutes = Math.floor(diffMilliseconds / 1000 / 60);
      const diffHours = Math.floor(diffMinutes / 60);
      const remainingMinutes = diffMinutes % 60;

      // 构造返回的字符串
      let result = '';
      if (diffHours > 0) {
        result += `${diffHours}小时`;
      }
      if (remainingMinutes > 0) {
        result += `${remainingMinutes}分钟`;
      }

      return result || '0分钟';
    },
    formatTimestamp(timestamp) {
      const year = timestamp.substring(0, 4);
      const month = timestamp.substring(4, 6);
      const day = timestamp.substring(6, 8);
      const hour = timestamp.substring(8, 10);
      const minute = timestamp.substring(10, 12);
      const second = timestamp.substring(12, 14);
      return `${year}-${month}-${day} ${hour}:${minute}:${second}`;
    },
    countElementsBeforeQueueNo(queue, targetQueueNo) {
      const targetElement = queue.find(element => element.queue_no === targetQueueNo);
      if (!targetElement) {
        return 0;
      }
      const targetObtainTime = targetElement.obtain_time;
      const count = queue.filter(element =>
          element.status === "1" &&
          element.obtain_time < targetObtainTime
      ).length;

      return count;
    },
    getData(){
      let config = this.$store.state.cardPageInfo.resResultDataObj.queueConfig || [] // 46 配置
      let types = this.$store.state.cardPageInfo.resResultDataObj.queueType || [] //47 排队类型
      let queues = this.$store.state.cardPageInfo.resResultDataObj.queueRecord || [] //48 排队记录
      let currents = this.$store.state.cardPageInfo.resResultDataObj.queueCurNumber || []//49 当前取号

      console.log('------------config', config)
      console.log('------------types', types)
      console.log('------------queues', queues)
      console.log('------------scurrents', currents)


      if (config && config.length > 0) {
        this.numberType = config[0].number_type
        // 保存排队配置用于音频播放
        this.queueConfig = config[0]
      }

      // 计算排队叫号
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

          if(_type.current_status*1 === 1){
            _type.canCall = true
          } else{
            if (_type.wait_no * 1 > 0) {
              _type.canCall = true
            } else {
              _type.canCall = false
            }
          }
          if(_type.current_status*1 === 1){
            _type.canEnter = true
          } else {
            _type.canEnter = false
          }
          if(_type.current_status*1 === 1){
            _type.canOverdue = true
          } else {
            _type.canOverdue = false
          }
        } else {
          _type.curr_num = '-'
          _type.curr_num_id = -1
          _type.num = '-'
          _type.num_cnt = '-'
          _type.wait =  '-'
          _type.wait_no  = -1
          _type.current_status = -1
          _type.canCall = false
          _type.canEnter = false
          _type.canOverdue = false
        }
      }
      //计算队列
      for(let queue of queues) {
        let idx = types.findIndex(t => t.id === queue.queue_type_id)
        if (idx >= 0) {
          let finder = types[idx]
          console.log('finder: ', finder)
          let queue_number
          if(this.numberType * 1 === 1) {
            queue_number = queue.queue_no
          } else if(this.numberType * 1 === 2) {
            queue_number = queue.queue_no.padStart(2, 0)
          } else if(this.numberType * 1 === 3) {
            queue_number = queue.queue_no.padStart(3, 0)
          }
          queue.queue_no_name = finder.num_prefix + queue_number
          queue.queue_name = finder.name
          queue.desk_cnt = this.countElementsBeforeQueueNo(queues, queue.queue_no)
          queue.show = true


          if (queue.status * 1 === 1) {
            queue.status_name = '排队中'
          } else if (queue.status * 1 === 2) {
            queue.status_name = '已过号'
          } else if (queue.status * 1 === 5) {
            queue.status_name = '已进店'
          } else if (queue.status * 1 === 3) {
            queue.status_name = '已取消'
          }

          queue.obtain_time_t = this.formatTimestamp(queue.obtain_time)

          let now = new Date()
          if(queue.status * 1 !== 1) {
            let timestamp = queue.update_time
            const year = parseInt(timestamp.substring(0, 4), 10);
            const month = parseInt(timestamp.substring(4, 6), 10) - 1; // 月份从0开始
            const day = parseInt(timestamp.substring(6, 8), 10);
            const hour = parseInt(timestamp.substring(8, 10), 10);
            const minute = parseInt(timestamp.substring(10, 12), 10);
            const second = parseInt(timestamp.substring(12, 14), 10);
            now = new Date(year, month, day, hour, minute, second);
          }

          queue.wait_time_t = this.formatTimeDifference(queue.obtain_time, now)
        }
      }

      this.typeList = types
      this.queues = queues
      console.log('======this.typeList', this.typeList)
    },
    filterQueue(queueType, queryStatus){
      console.log('queueType, queryStatus', queueType, queryStatus)
      if(queueType > 0 && queryStatus > 0) {
        this.queues.map(queue => {
          queue.show = (queue.status === queryStatus && queue.queue_type_id === queueType);
        })
      } else if (queueType > 0) {
        this.queues.map(queue => {
          queue.show = (queue.queue_type_id === queueType);
        })
      } else if (queryStatus > 0) {
        this.queues.map(queue => {
          queue.show = (queue.status === queryStatus);
        })
      } else {
        this.queues.map(queue => {
          queue.show = true
        })
      }
      console.log('queues now', this.queues)
      this.queues = [...this.queues]
    }

  },
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    }
  },
  components: {
  },
  watch: {
    showDrawer (newVal) {
      this.show = newVal;
      if (newVal) {
        this.callback =  () => {
          this.getData();
        }
        this.$observer.subscribe(QUEUE_TASK, this.callback);
        this.getData();
        this.updateQueueWait();
      }
    },
    checkType(newVal) {
      this.filterQueue(newVal, this.checkStatus)
    },
    checkStatus(newVal) {
      this.filterQueue(this.checkType, newVal)
    }
  },
  mixins: [cardPageMixins],
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
//@import "../../../style/common/elementFormBtn.less";
@import "../../../style/common/scrollBar.less";
@import "../../../style/book/machine/drawerQueue.less";
</style>

<style scoped lang="less">
</style>