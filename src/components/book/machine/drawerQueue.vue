<template>
  <div>
    <el-drawer
      title="排队详情"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="90%"
    >
<!--      item.curr_num = item.num_prefix + current.curr_num-->
<!--      item.num = item.num_prefix + current.num-->
<!--      item.num_cnt = item.num_cnt-->
<!--      item.wait =  ''-->
    <!-- 添加tab 排队叫号 排队列表 -->
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
                        <el-button type="primary" class="btn" size="mini">叫号</el-button>
                        <el-button type="primary" class="btn" size="mini">进店</el-button>
                        <el-button type="primary" class="btn" size="mini">过号</el-button>
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
        <div class="content">
           <div class="header">
              <div class="queue-type-layout">
                <div class="label">排队类型：</div>
                <div class="btn" v-for="(item, index) in typeList" :key="index" @click="onTypeClick(item)" :class="[ index == checkType && 'btn-selected']">{{ item.name }}</div>

              </div>
              <div class="queue-status-layout">
                <div class="label">状态：</div>
                <div class="btn" v-for="(item, index) in statusList" :key="index" @click="onStatusClick(item)" :class="[ index == checkStatus && 'btn-selected']">{{ item.name }}</div>
              </div>
           </div>

          <div class="thead">
            <div class="tr">
              <th class="th w80">排队号码</th>
              <th class="th w90">排队类型</th>
              <th class="th w120">客人姓名</th>
              <th class="th w120">前方桌数</th>
              <th class="th w120">状态</th>
              <th class="th w90">电话</th>
              <th class="th w120">等待时间</th>
              <th class="th w120">取号时间</th>
            </div>
          </div>
          <div class="tbody" ref="scrollDom">
            <div
              v-if="tableData.length==0"
              style="text-align:center;transform:translateY(40px)"
            >暂无数据</div>
            <div v-else ref="scrollItem">
              <div class="coll" v-for="(item,i) in tableData" :key="i">
                <div class="detail tr">
                  <div class="td w80">{{i+1}}</div>
                  <div class="td w90">{{item.b}}</div>
                  <div class="td w120">{{item.n}}</div>
                  <div class="td w120">{{item.p}}</div>
                  <div class="td w120">{{item.d}}</div>
                  <div class="td w90">{{item.e}}</div>
                  <div class="td w120">{{item.r}}</div>
                  <div class="td w120">{{item.sn}}</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </el-tab-pane>

    </el-tabs>
      <!-- 订单表格
      预留时间、预留客人姓名、客人电话、订位人部门、订位人、区域、台号、卡台标记、状态（开台、预留、拉台）、状态变更时间、备注
          records    []*ResGetBookListItem //Records 记录列表
            --------------------------------
            引用 ResGetBookListItem 格式:
              b          string     //BookTime 预留时间
              n          string     //CustomerName 客户姓名
              p          string     //CustomerPhone 客户手机
              d          string     //SalesDeptName 订位部门
              e          string     //SalesEmpName 订位人姓名
              r          string     //RegionName 区域名称
              sn         string     //SeatName 卡台名称
              m          string     //Mark 标签
              s          string     //Status 状态
              c          string     //StatusChgTime 状态变更时间
              rm         string     //Remark 备注
        普通失败, 返回编码<>1, 数据为空
     -->
      

      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_book from "@/api/Book";
import { QUEUE_TASK } from "@/observer";

export default {
  data () {
    return {
      show: false,
      loadTime: '',
      tableData: [],
      activeTab: '1', // 排队叫号 1 排队列表 2
      typeList: [], // 排队类型
      currents: [],
      checkType: 0, // 选中的排队类型
      statusList: [
        {
          name: '排队中',
          id: 1
        },
        {
          name: '已过号',
          id: 2
        },
        {
          name: '已取消',
          id: 3
        },
        {
          name: '已进店',
          id: 5
        },
      ], // 状态
      checkStatus: 0, // 选中的状态
      callback: null
    };
  },
  mounted() {
    this.callback =  () => {

    }
    this.$observer.subscribe(QUEUE_TASK, this.callback);
  },
  beforeDestroy() {
    this.$observer.unsubscribe(QUEUE_TASK, this.callback);
  },
  methods: {
    getReloadTime () {
      const date = new Date();
      const Y = date.getFullYear();
      const M = (date.getMonth() + 1).toString().padStart(2, 0);
      const D = date.getDate().toString().padStart(2, 0);
      const hour = date.getHours().toString().padStart(2, 0);
      const minute = date.getMinutes().toString().padStart(2, 0);
      const second = date.getSeconds().toString().padStart(2, 0);
      this.loadTime = `${Y}-${M}-${D} ${hour}:${minute}:${second}`
    },


    closeDrawerHandle () {
      this.$emit("showOrHideDrawer", false);
    },

    onCancelDrawer () {
      this.closeDrawerHandle();
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
      this.typeList = [...this.typeList];
    },
    onStatusClick (item) {
      this.statusList.forEach((i) => {
        i.checked = false;
      });
      item.checked = true;
      this.statusList = [...this.statusList];
    },
    getTableData(){
      // curr_cust_name:"trump"
      // curr_cust_phone:"17721067513"
      // curr_num:"1"
      // num:"1"
      // num_cnt:"1"
      // queue_type_id:"21"

      let types = this.$store.state.cardPageInfo.resResultDataObj.queueType
      let currents = this.$store.state.cardPageInfo.resResultDataObj.queueCurNumber

      // checked:true
      // id:"21"
      // max_cnt:"999"
      // min_cnt:"10"
      // min_csm_amt:"1001"
      // name:"小桌"
      // num_prefix:"A"
      // status:"1"

      console.log('currents', currents)
      for(let _type of types) {
        let idx = currents.findIndex(current => current.queue_type_id === _type.id)
        if (idx >= 0) {
          let finder = currents[idx]
          _type.curr_num = _type.num_prefix + finder.curr_num
          _type.num = _type.num_prefix + finder.num
          _type.num_cnt = finder.num_cnt
          _type.wait =  ''
        } else {
          _type.curr_num = '-'
          _type.num = '-'
          _type.num_cnt = '-'
          _type.wait =  '-'
        }
      }
      this.typeList = types

      console.log('this.typeList', this.typeList)

      this.callback =  () => {
        this.tableData = [...this.$store.state.cardPageInfo.resResultDataObj.queueRecord]
        if (this.checkType > 0) {

        }
        if(this.checkStatus > 0) {

        }
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
      }
    }
  }
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