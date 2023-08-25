<template>
  <div style="display:inline-block;">
    <span class="date-picker-text" @click.stop="showPicker" :style="{'color': valueText=='请选择时间' ? 'rgba(255,255,255,.3)' : 'rgba(255,255,255,.8)'}">{{valueText}}</span>
    <div class="date-picker-bg" v-show="isShow" @click.stop="$emit('showOrHidePicker')"></div>
    <div class="date-picker" v-show="isShow" style="width: 300px;">
      <div class="picker-top">
        <span class="picker-arrow" @click.stop="preMonth">&lsaquo;</span>
        <span class="date-text">{{year.toString().padStart(2,0)}}-{{month.toString().padStart(2,0)}}</span>
        <span class="picker-arrow" @click.stop="nextMonth">&rsaquo;</span>
      </div>
      <div class="picker-content" layout="row" layout-align="space-between start">
        <div class="table">
          <div class="thead" layout="row" layout-align="space-between center">
            <div class="th" v-for="(item,idx) in weekList" :key="'week'+idx">{{item.name}}</div>
          </div>
          <div class="tbody">
            <div class="tr" layout="row" layout-align="space-between center" v-for="(week,index) in monthDayArr"
              :key="index">
              <div class="td" v-for="day in week" :key="day.date" :class="{'active': selectDate == day.dateNum, 'gray': currentSelectTabDate > day.dateNum || getEndDate() < day.dateNum}"
                @click.stop="onSelectDate(day)">
                {{day.name}}</div>
            </div>
          </div>
        </div>
        <ul class="hour-list">
          <li v-for="(item,index) in timeList" :key="index" @click.stop="onSelectHour(item.id)"
            :class="[selectHourId==item.id?'active':'']">{{item.name}}</li>
        </ul>
      </div>
      <div class="picker-footer">
        <span class="button close" @click.stop="$emit('showOrHidePicker')">取消</span>
        <span class="button ok" @click.stop="onSubmit">确认</span>
      </div>
    </div>
  </div>
</template>
<script>
  export default {
    name: "DateTimePicker",
    data: () => ({
      timeList: [],  // 时间段选项
      weekList: [
        { name: "日" },
        { name: "一" },
        { name: "二" },
        { name: "三" },
        { name: "四" },
        { name: "五" },
        { name: "六" }
      ],
      year: '',
      month: '',
      day: '',
      monthDayArr: [],  // 当前月份的天数列表
      selectDate: '',
      selectHourId: '',
      currentSelectTabDate: '', // 选择需要预定的营业日日期
      resultDateTime: ''
    }),
    methods: {
      // 获取未来上半天的时间
      getNextDayTopTimeOption(num = 24) {
        let H = 0
        let M = 0
        const resultOption = []
        for (let i = 0; i < num; i++) {
          resultOption.push({
            id: H.toString().padStart(2, 0) + M.toString().padStart(2, 0),
            name: H.toString().padStart(2, 0) + ':' + M.toString().padStart(2, 0)
          })
          M += 30
          if (M >= 60) {
            H++
            M = 0
          }
        }
        this.timeList = resultOption
      },

      // 获取未来下半天的时间
      getNextDayBottomTimeOption(num = 24) {
        let H = 12
        let M = 0
        const resultOption = []
        for (let i = 0; i < num; i++) {
          resultOption.push({
            id: H.toString().padStart(2, 0) + M.toString().padStart(2, 0),
            name: H.toString().padStart(2, 0) + ':' + M.toString().padStart(2, 0)
          })
          M += 30
          if (M >= 60) {
            H++
            M = 0
          }
        }
        this.timeList = resultOption
      },

      // 获取当天上半天时间
      getCurrentTopDayTimeOption(){
        const date = new Date()
        let H = date.getHours()
        let M = date.getMinutes()
        const resultOption = []
        for(let i = 0; i< 24; i++){
          H = M > 30 ? H + 1 : H
          M = M > 30 ? 0 : 30
          if(H < 12){
            resultOption.push({
              id: H.toString().padStart(2, 0) + M.toString().padStart(2, 0),
              name: H.toString().padStart(2, 0) + ':' + M.toString().padStart(2, 0)
            })
            M += 30
          }
        } 
        this.timeList = resultOption
      },

      // 获取当天下半天时间
      getCurrentDayTimeBottomOption() {
        const date = new Date()
        let H = date.getHours()
        let M = date.getMinutes()
        if(H < 12 || this.currentSelectTabDate > this.getCurrentDay()){
          H = 12
          M = 0
        }
        const resultOption = []
        M = M === 0 ? 0 : Math.max(M, 30)
        if (M > 30 && M <= 59) {
          H += 1
          M = 0
        }
        for (let i = 0; i < 24; i++) {
          if (M >= 60) {
            M = 0
            H += 1
          }
          if (H < 24) resultOption.push({
            id: H.toString().padStart(2, 0) + M.toString().padStart(2, 0),
            name: H.toString().padStart(2, 0) + ':' + M.toString().padStart(2, 0)
          })
          M += 30
        }
        this.timeList = resultOption
      },

      // 获取开启营业日tab下半天时间
      getOpenDayTimeBottomOption(){
        const date = new Date()
        let H = date.getHours()
        let M = date.getMinutes()
        H = M > 30 ? H + 1 : H
        M = M > 30 ? 0 : 30
        const resultOption = []
        for (let i = 0; i < 48; i++) {
          if (M >= 60) {
            M = 0
            H += 1
          }
          if (H < 24) resultOption.push({
            id: H.toString().padStart(2, 0) + M.toString().padStart(2, 0),
            name: H.toString().padStart(2, 0) + ':' + M.toString().padStart(2, 0)
          })
          M += 30
        }
        this.timeList = resultOption
      },

      nextMonth() {
        if (this.month == 12) {
          this.year = this.year + 1
          this.month = 1
        } else {
          this.month++
        }
        this.getMonthDay(this.year, this.month)
      },

      preMonth() {
        if (this.month == 1) {
          this.year = this.year - 1
          this.month = 12
        } else {
          this.month--
        }
        this.getMonthDay(this.year, this.month)
      },

      showPicker() {
        this.$emit("showOrHidePicker");
      },

      getMonthCount(year, month) {
        let allday = 0
        if (month != 2) {
          if (month == 4 || month == 6 || month == 9 || month == 11)//判断是否是相同天数的几个月，二月除外
            allday = 30;
          else
            allday = 31;
        } else {
          if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0))//判断是否是闰年，进行相应的改变
            allday = 29;
          else
            allday = 28;
        }
        return allday
      },

      getMonthDay(year, month) {
        const week = new Date(`${year}/${month}/01`).getDay();
        const allDay = this.getMonthCount(year, month)
        const dayArr = []
        for (var i = 0; i < week; i++) {//循环输出月初空余天数
          dayArr.push({
            name: '',
            date: i
          })
        }
        for (var j = 1; j <= allDay; j++) {
          dayArr.push({
            name: j,
            date: +new Date(year.toString() + '/' + month.toString() + '/' + j.toString()),
            dateNum: year.toString() + month.toString().padStart(2,0) + j.toString().padStart(2,0)
          })
        }
        let result = []
        let temp = []
        dayArr.forEach((el, index) => {
          if (index % 7 === 0) {
            result.push(JSON.parse(JSON.stringify(temp)))
            temp = [el]
          } else {
            temp.push(el)
          }
          if (index === (dayArr.length - 1)) {
            if (temp.length < 7) {
              const count = 7 - temp.length
              for (let i = 0; i < count; i++) {
                temp.push({ name: '', date: 100 - i })
              }
            }
            result.push(temp)
          }
        })
        this.monthDayArr = result
      },

      onSelectHour(id) {
        this.selectHourId = id
      },

      onSelectDate(dayInfo) {
        const date = dayInfo.date
        const dateNum = dayInfo.dateNum
        const now = +new Date(this.currentSelectTabDate.slice(0,4)+ '/' + this.currentSelectTabDate.slice(4,6)+'/'+this.currentSelectTabDate.slice(6, 8))
        const oneDay = (+new Date('2022/07/02') - (+new Date('2022/07/01')))

        const storeDay = this.$store.state.cardPageInfo.resResultDataObj.canDoList[this.dateTabActiveIndex].id
        const currentDay = this.getCurrentDay()
        if (now - date < oneDay && dateNum <= this.getEndDate()) {  // 当天或未来的日期
          if((storeDay < currentDay && this.isMorning) || (this.dateTabActiveIndex == 0 && storeDay == currentDay && this.isMorning)){ // 当天所处的营业日为上一个营业日（上午）
            this.getCurrentTopDayTimeOption()
          } else if (now - date >= 0) {  // 当天营业日（下午）
            this.getCurrentDayTimeBottomOption()
            const currentTime = new Date().getHours().toString().padStart(2, 0) + new Date().getMinutes().toString().padStart(2, 0)
            if (Number(currentTime) > Number(this.selectHourId)) this.selectHourId = ''
          } else { // 未来营业日
            this.getNextDayTopTimeOption()
          }
          this.selectDate = dateNum;
        }
      },

      onSubmit() {
        if (this.selectDate.length < 8) return this.$message.warning('请选择日期')
        if (this.selectHourId.length < 4) return this.$message.warning('请选择时间')
        this.resultDateTime = this.selectDate + this.selectHourId
        this.$emit('updateDatetime', this.resultDateTime)
      },

      getCurrentDay(){
        const Y = new Date().getFullYear().toString().padStart(2, 0)
        const M = (new Date().getMonth() + 1).toString().padStart(2, 0)
        const D = (new Date().getDate()).toString().padStart(2, 0)
        return `${Y}${M}${D}`
      },

      // 终止日期
      getEndDate(){
        const storeDay = this.$store.state.cardPageInfo.resResultDataObj.canDoList[this.dateTabActiveIndex].id
        const currentDay = this.getCurrentDay()

        const oneDay = (+new Date('2022/07/02') - (+new Date('2022/07/01')))
        const endDate = new Date(+new Date(this.currentSelectTabDate.slice(0, 4) + '/' + this.currentSelectTabDate.slice(4, 6) + '/' + this.currentSelectTabDate.slice(6, 8)) + oneDay)
        const endY = endDate.getFullYear()
        const endM = (endDate.getMonth() + 1).toString().padStart(2, 0)
        const endD = endDate.getDate().toString().padStart(2, 0)
        const nextDay = endY + endM + endD

        if (storeDay < currentDay){ 
          if (this.dateTabActiveIndex == 0) { // 营业日为今天之前的自然日
            return this.isMorning ? currentDay : nextDay
          } else if ((+new Date(currentDay.slice(0, 4) + '/' + currentDay.slice(4, 6) + '/' + currentDay.slice(6, 8))) - (+new Date(storeDay.slice(0, 4) + '/' + storeDay.slice(4, 6) + '/' + storeDay.slice(6, 8))) == oneDay) { // 当前时间与比选择的tab时间大一天
            return this.isMorning ? currentDay : storeDay
          }
          
          return storeDay
        }

        if(!this.$store.state.cardPageInfo.resResultDataObj.canDoList[1]) {
          return this.isMorning ? currentDay : nextDay
        }

        // if(this.dateTabActiveIndex == 0 && storeDay == currentDay && this.isMorning && storeDay >= this.$store.state.cardPageInfo.resResultDataObj.canDoList[1].id){
        //   // 营业日时间为中午十二点之前打开，第一个tab显示的为前一天的营业日
        //   return currentDay
        // }

        return nextDay
      },

      // 初始化数据
      initData(value) {
        const storeDay = this.$store.state.cardPageInfo.resResultDataObj.canDoList[this.dateTabActiveIndex].id
        const currentDay = this.getCurrentDay()
        this.year = value.length === 12 ? value.substr(0, 4) : storeDay > currentDay ? storeDay.substr(0, 4) : currentDay.substr(0, 4)
        this.month = value.length === 12 ? value.substr(4, 2) : storeDay > currentDay ? storeDay.substr(4, 2) : currentDay.substr(4, 2)
        this.day = value.length === 12 ? value.substr(6, 2) : new Date().getDate()
        this.selectHourId = value.length === 12 ? value.substr(8, 4) : ''
        // 首次选择时间
        if(!value){
          if(this.dateTabActiveIndex == 0) {  // 开启营业日时间
            this.selectDate = currentDay
            if (storeDay < currentDay) { // 开启营业日的自然日时间小于当天时间
              // if(storeDay > this.$store.state.cardPageInfo.resResultDataObj.canDoList[1].id){
                if(this.isMorning){
                  this.getCurrentTopDayTimeOption()
                } else {
                  this.getOpenDayTimeBottomOption()
                }
              // } else {
              //   // 开启营业日时间与当天营业日相同
              //   this.getCurrentTopDayTimeOption()
              // }
            } else if (storeDay == currentDay) { // 开启营业日的自然日时间与当天时间相同
              if(!this.$store.state.cardPageInfo.resResultDataObj.canDoList[1]){
                if(this.isMorning) {
                  this.getCurrentTopDayTimeOption()
                } else {
                  this.getOpenDayTimeBottomOption()
                }
              } else if (storeDay >= this.$store.state.cardPageInfo.resResultDataObj.canDoList[1].id){
                if(this.isMorning){
                  this.getCurrentTopDayTimeOption()
                } else {
                  this.getOpenDayTimeBottomOption()
                }
              } else {
                // 开启营业日时间与当天营业日相同
                this.getOpenDayTimeBottomOption()
              }
            }
          } else {
            // 非第一个(开启营业日)时间tab
            if ( storeDay < currentDay) { // 所选营业日时间小于当天自然日时间
              this.selectDate = currentDay
              if (this.isMorning){
                this.getCurrentTopDayTimeOption()
              } else {
                this.timeList = []
              }
            } else if (storeDay == currentDay) { // 所选营业日时间等于当天自然日时间
              this.selectDate = currentDay
              this.getCurrentDayTimeBottomOption()
            } else { // 所选营业日时间大于当天自然日时间
              this.selectDate = storeDay
              this.getNextDayBottomTimeOption()
            }
          }
          this.currentSelectTabDate = this.selectDate

        } else { // 编辑时间

          this.selectDate = this.year.toString().padStart(2,0) + this.month.toString().padStart(2,0) + this.day.toString().padStart(2,0)
          if (this.dateTabActiveIndex == 0) {  // 开启营业日时间
            if (storeDay < currentDay) { // 开启营业日的自然日时间小于当天时间
              if(storeDay > this.$store.state.cardPageInfo.resResultDataObj.canDoList[1].id){
                if(this.isMorning){
                  this.getCurrentTopDayTimeOption()
                } else {
                  this.getOpenDayTimeBottomOption()
                }
              } else {
                // 开启营业日时间与当天营业日相同
                this.getOpenDayTimeBottomOption()
              }
            } else if (storeDay == currentDay) { // 开启营业日的自然日时间与当天时间相同
              if(!this.$store.state.cardPageInfo.resResultDataObj.canDoList[1]){
                if(this.value.slice(-4) < 1200) {
                  this.getNextDayTopTimeOption()
                } else {
                  this.getCurrentDayTimeBottomOption()
                }
              } else if(storeDay > this.$store.state.cardPageInfo.resResultDataObj.canDoList[1].id){
                if(this.isMorning){
                  this.getCurrentTopDayTimeOption()
                } else {
                  this.selectDate > currentDay ? this.getNextDayTopTimeOption() : this.getOpenDayTimeBottomOption()
                }
              } else {
                // 开启营业日时间与当天营业日相同
                this.selectDate > storeDay ? this.getNextDayTopTimeOption() : this.getOpenDayTimeBottomOption()
              }
            }

          } else { // 非第一个(开启营业日)时间tab
            
            if ( storeDay < currentDay) { // 所选营业日时间小于当天自然日时间
              if (this.isMorning){
                this.getCurrentTopDayTimeOption()
              } else {
                this.timeList = []
              }
            } else if (storeDay == currentDay) { // 所选营业日时间等于当天自然日时间
              this.selectDate > currentDay ? this.getNextDayTopTimeOption() : this.getCurrentDayTimeBottomOption()
            } else { // 所选营业日时间大于当天自然日时间
              this.selectDate > storeDay ? this.getNextDayTopTimeOption() : this.getNextDayBottomTimeOption()
            }
          }
        }
        this.getMonthDay(this.year, this.month)
        
      }

    },
    mounted() {
      const { value } = this
      this.initData(value)
    },
    props: {
      value: {
        type: String,
        default: ''
      },
      isShow: {
        type: Boolean,
        default: false
      },
      dateTabActiveIndex:{  // 当前操作的时期tabIndex
        default: ''
      }
    },
    computed: {
      valueText() {
        const { value } = this
        if (value === '') return '请选择时间'
        if (value.length === 12) {
          const y = value.substr(0, 4)
          const m = value.substr(4, 2)
          const d = value.substr(6, 2)
          const h = value.substr(8, 2)
          const minute = value.substr(10, 2)
          return `${y}-${m}-${d} ${h}:${minute}`
        }
        return ''
      },
      // 是否为中午12点之前
      isMorning(){
        return new Date().getHours() < 12
      }
    },
    watch: {
      value(newVal) {
        this.initData(newVal)
      },
      isShow(newVal){
        this.initData(this.value)
      }
    }
  };
</script>
<style lang="less" scoped>
  .date-picker-bg {
    position: fixed;
    left: 0;
    top: 0;
    width: 100%;
    height: 100%;
    z-index: 9;
  }

  .date-picker-text {
    display: block;
    height: 100%;
    height: 38px;
    border: 1px solid rgba(255, 255, 255, .15);
    background: rgba(0, 0, 0, 0.2);
    border-radius: 10px;
    color: rgba(255, 255, 255, .8);
    padding: 0 15px;
    cursor: pointer;
  }

  .date-picker {
    background-color: #2A3959;
    position: fixed;
    display: block;
    padding: 4px;
    z-index: 10;
    border: solid 1px rgba(255, 255, 255, .15);
    border-radius: 2px;
    color: rgba(255, 255, 255, .8);

    .picker-top {
      display: flex;
      flex-direction: row;
      align-items: center;
      height: 30px;
      line-height: 30px;

      .picker-arrow {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 30px;
        height: 30px;
        cursor: pointer;

        .iconfont {
          color: #8a8a8a;
        }

        .iconfont:active,
        .iconfont:hover {
          color: #388dea;
        }
      }

      .date-text {
        flex: 1;
        font-weight: 600;
        display: inline-block;
        text-align: center;
        font-size: 16px;
      }
    }

    .picker-content {
      height: 210px;

      .table {
        width: calc(100% - 100px);

        div {
          line-height: 30px;
        }

        .th,
        .td {
          width: 15%;
          text-align: center;

          &.active {
            background: #388dea;
          }

          &.gray {
            color: rgba(255, 255, 255, .25);
          }

          &.deepGray {
            color: #aaa;
          }
        }
      }

      .hour-list {
        width: 80px;
        display: inline-block;
        list-style: none;
        padding: 0;
        margin: 0;
        height: 100%;
        overflow-x: hidden;
        font-size: 12px;
        overflow-y: auto;

        li {
          width: 60%;
          padding: 0;
          margin: 0 auto;
          display: flex;
          align-items: center;
          justify-content: center;
          height: 30px;
          cursor: pointer;
        }

        li.active {
          background: #388dea;
        }
      }
    }

    .picker-footer {
      padding: 6px 0;
      display: block;
      line-height: 30px;
      text-align: right;
      white-space: nowrap;
      text-align: center;

      .button {
        display: inline-block;
        border-radius: 6px;
        color: #fff;
        font-size: 12px;
        height: 20px;
        line-height: 20px;
        padding: 4px 10px;
        margin: 0 10px;

        &.close {
          background: #374368;
        }

        &.ok {
          background: #4B89FF;
        }
      }
    }
  }
</style>