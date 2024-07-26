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
                    <div class="td w120">
                      <div class="action">
                        <el-button type="primary" class="btn" size="mini" @click="call">叫号</el-button>
                        <el-button type="primary" class="btn" size="mini" @click="enter">进店</el-button>
                        <el-button type="primary" class="btn" size="mini" @click="overdue">过号</el-button>
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

export default {
  data () {
    return {
      timer: null,
      show: false,
      numberType: 1,
      loadTime: '',
      tableData: [],
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
      callback: null
    };
  },
  async mounted() {
    console.log('mountedmountedmountedmountedmountedmountedmounted')
    this.callback =  () => {

    }
    this.$observer.subscribe(QUEUE_TASK, this.callback);
  },
  beforeDestroy() {
    console.log('beforeDestroybeforeDestroybeforeDestroy')
    if (this.timer) {
      clearInterval(this.timer);
    }
    this.$observer.unsubscribe(QUEUE_TASK, this.callback);
  },
  methods: {
    async call(){
      this.showConfirmHandle(
          "叫号",
          "是否确认叫号",
          async () => {
            console.log('------call 叫号')
          }
      );
    },
    async enter(){
      this.showConfirmHandle(
          "进店",
          "是否确认客人已进店",
          async () => {
            console.log('------call 进店')
          }
      );
    },
    async overdue(){
      this.showConfirmHandle(
          "过号",
          "是否设置为过号?操作后不可撤销",
          async () => {
            console.log('------call 过号')
          }
      );
    },

    closeDrawerHandle () {
      this.$emit("showOrHideDrawer", false);
    },

    onCancelDrawer () {
      this.closeDrawerHandle();
      if (this.timer) {
        clearInterval(this.timer);
      }
    },

    async updateQueueWait() {
      this.timer = setInterval(async () => { // 使用箭头函数，确保this指向正确
        try {
          console.log('updateQueueWait....')
          this.queues.forEach(a => a.wait_time_t = this.formatTimeDifference(a.obtain_time))
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
      console.log('item', item)
      this.typeList.forEach((i) => {
        i.checked = false;
      });
      item.checked = true;
      this.checkType = item.id
      this.typeList = [...this.typeList];
    },
    onStatusClick (item) {
      this.statusList.forEach((i) => {
        i.checked = false;
      });
      item.checked = true;
      this.checkStatus = item.id
      this.statusList = [...this.statusList];
    },
    formatTimeDifference(timestamp) {
      // 将时间字符串解析为Date对象
      const year = parseInt(timestamp.substring(0, 4), 10);
      const month = parseInt(timestamp.substring(4, 6), 10) - 1; // 月份从0开始
      const day = parseInt(timestamp.substring(6, 8), 10);
      const hour = parseInt(timestamp.substring(8, 10), 10);
      const minute = parseInt(timestamp.substring(10, 12), 10);
      const second = parseInt(timestamp.substring(12, 14), 10);

      const targetDate = new Date(year, month, day, hour, minute, second);
      const now = new Date();

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
    getTableData(){
      let config = this.$store.state.cardPageInfo.resResultDataObj.queueConfig // 46 配置
      let types = this.$store.state.cardPageInfo.resResultDataObj.queueType //47 排队类型
      let queues = this.$store.state.cardPageInfo.resResultDataObj.queueRecord //48 排队记录
      let currents = this.$store.state.cardPageInfo.resResultDataObj.queueCurNumber //49 当前取号

      console.log('------------config', config)
      console.log('------------types', types)
      console.log('------------queues', queues)
      console.log('------------scurrents', currents)


      if (config && config.length > 0) {
        this.numberType = config[0].number_type
      }

      /*
      type:
           id : el[0], // 主键
          status : el[1], // 状态 1 有效 3 删除
          name: el[2], //  类型名称
          num_prefix: el[3], //  类型编码
          min_cnt: el[4], //  起始人数
          max_cnt : el[5], //  截止人数
          min_csm_amt: el[6], // 抵消金额(单位元)
      queue:
          phone_num: el[1], // 客人手机号
          name: el[2], // 客人姓名
          queue_type_id: el[3], // 排队类型id
          queue_no: el[4], // 排队号
          status: el[5], // 状态1 排队中 2 已过号 5 已叫号 3 已取消
          obtain_time: el[6], // 取号时间 取号时间(格式:yyyymmddhh24miss)
          update_time: el[7], // 更新时间(格式:yyyymmddhh24miss) 对应 到店时间 取消时间 过号时间 叫号时间
          {
            "wkday_id": "242061247418275",
            "phone_num": "17721067513",
            "name": "trump",
            "queue_type_id": "23",
            "queue_no": "ZZ1",
            "status": "1",
            "obtain_time": "20240725233927",
            "update_time": "20240725233927",
            "queue_name": "包厢",
            "desk_cnt": 10,
            "status_name": "排队中",
            "obtain_time_t": "2024-01-01 12:00:00",
            "wait_time_t": "12分钟"
        }
      current:
          queue_type_id: el[1], //  排队类型id
          last_gen_num: el[2], //  当前取到几号了
          curr_no: el[3], //  当前轮到哪个号了=0代表没有了
          curr_no_status: el[4], //  当前叫号状态 1 排队中(可以叫号,过号,入场), 2,5 已过号,已入场(只能叫号)
          wait_cnt: el[5], //  等待桌数
          wait_no: el[6], //  等待叫号
       */


      // 计算排队叫号
      for(let _type of types) {
        let idx = currents.findIndex(current => current.queue_type_id === _type.id)
        if (idx >= 0) {
          let finder = currents[idx]

          let cur_num
          let last_gen_num
          if(this.numberType * 1 === 1) {
            // cur_num = _type.num_prefix + finder.curr_no
            cur_num = finder.curr_no
            last_gen_num = finder.last_gen_num
          } else if (this.numberType * 1 === 2) {
            cur_num = finder.curr_no.padStart(2, 0)
            last_gen_num = finder.last_gen_num.padStart(2, 0)
          } else if (this.numberType * 1 === 3) {
            cur_num = finder.curr_no.padStart(3, 0)
            last_gen_num = finder.last_gen_num.padStart(3, 0)
          }

          _type.curr_num = _type.num_prefix  + cur_num
          _type.num = _type.num_prefix + last_gen_num
          _type.num_cnt = finder.wait_cnt
          _type.wait =  finder.wait_no
        } else {
          _type.curr_num = '-'
          _type.num = '-'
          _type.num_cnt = '-'
          _type.wait =  '-'
        }
      }
      //计算队列
      /* name:"trump"
      // obtain_time:"20240725134736"
      // phone_num:"17721067513"
      // queue_no:"1"
      // queue_type_id:"24"
      // status:"1"
      // update_time:"20240725134736" */

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
            queue.status_name = '已叫号'
          } else if (queue.status * 1 === 3) {
            queue.status_name = '已取消'
          }

          queue.obtain_time_t = this.formatTimestamp(queue.obtain_time)
          queue.wait_time_t = this.formatTimeDifference(queue.obtain_time)
        }
      }

      this.typeList = types
      this.queues = queues

      console.log('======this.typeList', this.typeList)

      this.callback =  () => {
        // this.tableData = [...this.$store.state.cardPageInfo.resResultDataObj.queueRecord]


        // if (this.checkType > 0) {
        //
        // }
        // if(this.checkStatus > 0) {
        //
        // }
      }
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
        this.getTableData();
        this.updateQueueWait();
      }
    },
    checkType(newVal) {
      console.log('checkType changed', newVal)
      this.queues.map(queue => {
        if(queue.queue_type_id === newVal) {
          queue.show = true
        } else {
          queue.show = false
        }
      })
      this.queues = [...this.queues]
      console.log('after queue:', this.queues)
    },
    checkStatus(newVal) {
      console.log('checkStatus changed', newVal)
      this.queues.map(queue => {
        if(queue.status === newVal) {
          queue.show = true
        } else {
          queue.show = false
        }
      })
      this.queues = [...this.queues]
      console.log('after queue:', this.queues)
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
/deep/.select-com {
  font-size: 14px;
}

/deep/.options li {
  font-size: 14px;
}
</style>

<style>
.el-cascader__dropdown {
  background-color: #202c4a;
  color: rgba(255, 255, 255, 0.8);
}

.el-cascader-node {
  color: rgba(255, 255, 255, 0.8);
  font-size: 14px;
}

.el-cascader-node:not(.is-disabled):focus,
.el-cascader-node:not(.is-disabled):hover {
  background-color: rgba(90, 90, 90, 0.5);
}

.el-cascader-panel {
  border: none;
}
</style>