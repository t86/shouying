import eventVue from '@/utils/eventVue';

// 卡台相关数据 及 websocket数据

import api_card from '@/api/Book'
import api_auth from "@/api/UtilAuth";
import base from '@/api/base'
import { resResultDataArr } from '@/utils/config/card'
import { transformCardDataHandle } from '@/utils/transformCardData'

let resResultDataObj = {}  // 元数据（后台接口返回处理后的初始化数据）
export const cardInfoMixins = {
  methods: {
    // 请求全量基础数据  loadCard:是否重新更新卡台数据
    async getAllData(loadCard = false) {
      // const loading = (this.$route.name === 'cardMachine' || this.$route.name === 'orderCard' || this.$route.name === 'moneyCard') ? this.$loading({
      //   lock: true,
      //   text: 'Loading',
      //   spinner: 'el-icon-loading',
      //   background: 'rgba(0, 0, 0, 0.7)'
      // }) : ''
      try {
        const res = await api_card.reqGetAllData()
        // console.log(res.data);
        if (res.code === 1) {
          resResultDataArr.forEach((el, index) => {
            resResultDataObj[el] = el != 'businessData' ? transformCardDataHandle(res.data[index], index).filter(item => item.status == 1) : transformCardDataHandle(res.data[index], index).filter(item => item.bizStatus != 22 && item.bizStatus != 33)
          })

          console.log('resResultDataObj:', resResultDataObj);

          this.$store.commit('updateResResultDataObj', resResultDataObj)
          this.$store.commit('updateStoreStatusId', resResultDataObj['storeStatusInfo'][0]['wkday_id'])

          if (loadCard) {
            if (this.$route.name === 'cardMachine' || this.$route.name === 'orderCard' || this.$route.name === 'moneyCard') {

              // 加载卡台相关数据
              const getTabShowCount = this.$children[0].getTabShowCount
              const getAllData = this.$children[0].getAllData

              if (getTabShowCount && getAllData) getTabShowCount(getAllData);

              this.$children[0].showOrHideModelVisible && this.$children[0].showOrHideModelVisible();

            } else { // 更新本地store和sessionStorage中存储的卡台信息
              this.updateTabListData(resResultDataObj['areaInfo'])
              this.updateCardListData(resResultDataObj['cardInfo'], resResultDataObj['businessData'])
              if (resResultDataObj['storeStatusInfo'][0]['wkday_id'] == 0) {
                this.$message.warning('营业日已关闭，即将返回登录页面');
                setTimeout(this.logoutHandle, 1000);
              }
            }
          }

        }
      } catch (error) {
        console.log('全量数据请求失败', error);
      }
      // loading && loading.close();
    },

    // 获取websocket断开期间的增量数据
    async getUpdateData() {
      const params = {  // '20220902171731'//
        last_sync_time: this.websocketTimeMessageTime, // string     //LastSyncTime 上次完成同步时间,建议往回走个30秒, 格式 yyyymmddhh24miss
      }
      try {
        const res = await api_card.reqGetUpdateData(params)
        // console.log('增量数据:', res)  // TODO:

        // 更新接收到消息的时间
        this.websocketTimeStart = +new Date()

        const data = res.data || []

        res.code === 1 ? this.updateCardList(data) : this.$message.warning(res.msg)

      } catch (error) {
        console.log('获取websocket断开期间的增量数据失败', error);
      }
    },

    // 初始化websocket数据
    initWebsocket() {
      typeof (WebSocket) === "undefined" ? this.$message.warning("您的浏览器不支持socket") : this.connectWebsocket()
    },

    connectWebsocket() {
      // 实例化socket
      this.socket = new WebSocket(base.cardWebsocketPath + '/sync')
      // 监听socket连接
      this.socket.onopen = this.openHandle
      // 监听socket错误信息
      this.socket.onerror = this.errorHandle
      // 监听socket消息
      this.socket.onmessage = this.messageHandle
    },

    openHandle(e) {
      const token = this.$localStorage.getItem('tk') || ''
      this.socket.send(JSON.stringify(token))

      // 监听处理websocket是否断开连接
      this.websocketHasConnect()

    },

    errorHandle(e) {
      console.log('websocket error：', e);
      clearTimeout(this.errorTimer)
      this.errorTimer = setTimeout(() => {
        this.$message.warning('websocket连接失败，5s后将重新连接！')
        console.log('%c websocket连接失败，5s后将重新连接！', 'color:blue;font-size:14px');
        this.connectWebsocket()
        // 是否接收到系统返回的时间？接收到了获取增量数据，否则重新拉取全量数据
        this.websocketTimeMessageTime ? this.getUpdateData() : this.getAllData(true)
      }, 5000)
    },

    closeHandle(e) {
      if (this.socket) {
        this.socket.close()
        this.$store.commit('updateResResultDataObj', resResultDataObj)
        this.socket.onclose = event => console.log('websocket已关闭')
      }
    },

    messageHandle(e) {
      const { p: code, t: time, d: data } = JSON.parse(e.data)
      // console.log('websocket message:', { code, time, data })  // TODO:

      // 更新接收到消息的时间
      this.websocketTimeStart = +new Date()
      // 接收到websocket推送消息的时间
      this.websocketTimeMessageTime = time

      // code: 1:数据更新  2：无更新，保持连接不断  3：错误信息
      code === 1 ? this.updateCardList(data) : (code === 3 ? this.$message.warning(typeof data === 'string' ? data : 'websocket返回数据出错') : '')
    },

    // 监听处理websocket是否断开
    websocketHasConnect() {
      // 首次加载时间
      this.websocketTimeStart = +new Date()
      const distanceTime = +new Date('2022/09/02 11:01:05') - +new Date('2022/09/02 11:00:00')

      const hasConnectedHandle = time => {
        this.isConnectedTimer = setTimeout(() => {
          // this.getUpdateData()
          // console.log('是否断开', (+new Date() - this.websocketTimeStart) > distanceTime);
          if ((+new Date() - this.websocketTimeStart) > distanceTime) {
            // 已断开连接
            this.$message.warning('检测到websocket已断开，即将重新连接！')
            console.log('%c检测到websocket已断开，即将重新连接！', 'color:blue;font-size:14px');
            this.connectWebsocket()
            // 是否接收到系统返回的时间？接收到了获取增量数据，否则重新拉取全量数据
            this.websocketTimeMessageTime ? this.getUpdateData() : this.getAllData(true)
          } else {
            hasConnectedHandle(60000)
          }
        }, time);
      }


      clearTimeout(this.isConnectedTimer)
      // 首次间隔65s
      // 其后间隔60m，与后端保持一致（心跳检测）
      hasConnectedHandle(65000)
    },

    // websocket数据更新
    updateCardList(dataObj = {}) {
      for (let key in dataObj) {
        // 开启营业日的时候，业务数据为空，需要重新赋值业务数据
        if (key == 14 && resResultDataObj[resResultDataArr[key]].length == 0) {
          this.getAllData(true)
        } else if (key == 18) {
          // 判断营业日id状态是否发生变化，变化的话重新获取业务数据
          this.$store.commit('updateStoreStatusId', dataObj[key][0][0])
          this.getAllData(true)
        } else if (key == 22) { // 收银系统卡台页面小红点数量发生变化
          this.$store.commit('updateMoneyCardNeedBackOrderCount', dataObj[key][0][0])
        } else if (key == 1 || key == 23 || key == 28 || key == 31 || key == 32 || key == 33 || key == 34 || key == 36 || key == 37 || key == 38) {
          // 页面需要从新获取最新全量数据
          this.getAllData(true)
        } else if (key == 29 && this.$route.name == 'cardMachine') {
          this.getAllData(true)  // 调整置顶
        } else {
          dataObj[key] = transformCardDataHandle(dataObj[key], key)
          dataObj[key].forEach(el => {
            // console.log(`websocket改变详情:`, el);  // TODO:
            // 查找当前改变的数据下标索引值
            const index = resResultDataObj[resResultDataArr[key]].findIndex(ele => {
              if (Number(key) <= 8) {  // 数据id字段名称为id
                return ele.id === el.id
              } else if (Number(key) <= 10) {  // 数据id字段为prdId
                return ele.prdId === el.prdId
              } else if (Number(key) <= 12) {  // 数据id字段为stationId
                return ele.stationId === el.stationId
              } else if (Number(key) === 13) {  // 数据字段为station_id
                return ele.station_id === el.station_id
              } else if (Number(key) === 14) {  // 数据id字段为seatId
                return ele.seatId === el.seatId
              } else if (Number(key) === 15) {  // 数据id字段为station_id
                return ele.station_id === el.station_id
              } else if (Number(key) === 16) {  // 数据id字段为region_id
                return ele.region_id === el.region_id
              } else if (Number(key) === 17) {  // 数据id字段为id
                return ele.id === el.id
              } else if (Number(key) < 21) {  // 数据id字段为id
                return ele.id === el.id
              } else if (Number(key) === 21) {  // 数据id字段为rqm_type_id
                return ele.rqm_type_id === el.rqm_type_id
              } else if (Number(key) === 24) {  //  咨客可操作日期列表
                return ele.id === el.id
              } else if (Number(key) === 25) {  //  未来(当日以后的)预留业务数据
                return ele.seat_id === el.seat_id && ele.book_day_value === el.book_day_value
              } else if (Number(key) === 26) {   // 线上卡台标记
                return ele.seat_id === el.seat_id
              } else if (Number(key) === 39) {   // 卡台状态数量统计
                return ele.id === el.id
              } 
            })
            if (index < 0 && key == 8) {
              // 新增估清商品
              resResultDataObj[resResultDataArr[key]][resResultDataObj[resResultDataArr[key]].length] = el
            }
            if (index < 0 && key == 39) {
              // 新增卡台状态数量统计
              return this.getAllData(true)
            }
            if (index < 0 && Number(key) == 25) {
              // 新增未来日期的预留
              resResultDataObj[resResultDataArr[key]][resResultDataObj[resResultDataArr[key]].length] = el
            } else if (Number(key) == 35) {
              resResultDataObj[resResultDataArr[key]][0] = el
            } else {
              resResultDataObj[resResultDataArr[key]][index] = el
            }
            

            // 刷新收银系统订单数据
            if(this.$route.name == 'payOrder' && key * 1 == 14 && this.$store.state.orderInfo.currentCardInfo && dataObj[key].some(item => item.seatId == this.$store.state.orderInfo.currentCardInfo.seatId)){
              eventVue.$emit('reloadPayOrderList')
            }

          })
        }
      }

      this.$store.commit('updateResResultDataObj', resResultDataObj)
      if (this.$route.name == 'cardMachine' || this.$route.name == 'orderCard' || this.$route.name == 'moneyCard') {
        this.$children[0] && this.$children[0].getTabList && this.$children[0].getTabList(resResultDataObj['areaInfo'])
        this.$children[0] && this.$children[0].getCardList && this.$children[0].getCardList(resResultDataObj['cardInfo'], resResultDataObj['businessData'])
      } else { // 更新本地store和sessionStorage中存储的卡台信息
        this.updateTabListData(resResultDataObj['areaInfo'])
        this.updateCardListData(resResultDataObj['cardInfo'], resResultDataObj['businessData'])
      }

    },


    // 更新修改后的tab数据
    updateTabListData(arr = []) {
      arr = arr.sort((a, b) => Number(a.dsp) - Number(b.dsp))
      let tabList = arr.filter(el => el.status === '1')  // status:  1:有效 2:无效
      this.$store.commit('updateTabList', tabList)
    },


    // 更新修改后的card数据
    updateCardListData(cardInfo = [], businessData = []) {// cardInfo:卡台数据  businessData:业务数据 
      cardInfo = cardInfo.sort((a, b) => a.name.localeCompare(b.name))
      const cardList = []
      cardInfo.forEach((item, index) => {
        if (item.status === '1') {
          // 查找对应的业务数据
          const data = businessData.find(el => el.seatId === item.id) || []
          if (data.bizStatus != '22' && data.bizStatus != '33') {
            cardList.push({
              // 卡台数据
              ...item,
              // 业务数据
              ...data,
              // 赠送金额
              zengSongAmt: (Number(data.yhAmt) + Number(data.yh2Amt)).toFixed(2),
              // 当前卡台所处状态的小卡片 
              // tipsArr: this.getTips(data.bizStatus, data.openType),
              // 抵消进度
              diXiaoJindu: Number(data.assignMinCsmAmt) > 0 && data.openType == 1 ? (((Number(data.orderAmt) / Number(data.assignMinCsmAmt)).toFixed(0)) > 1 ? '100%' : (((Number(data.orderAmt) / Number(data.assignMinCsmAmt)) * 100).toFixed(0)) + '%') : '',
              // 点击卡台出现的可操作选项
              // options: this.getCardOptions(data.bizStatus),
              // 是否显示卡台的操作按钮选项
              // showOption: this.card.cardList[index] && this.card.cardList[index].showOption
              // showOption: cardListInfoArr[index] && cardListInfoArr[index].showOption,
              // isLeftArrow: false // 操作选项列表是否显示在左边
            })
          }

        }
      })

      this.$store.commit('updateCardList', cardList)
    },

    // 退出登录
    async logoutHandle() {
      try {
        const res = await api_auth.auth.requestauthlogout();
        if (res.code === 1) {
          this.$store.commit("updateResResultDataObj", "");
          this.$store.commit("updateUserInfo", "");
          this.$router.replace({
            name: "Thelogin",
            replace: true,
            query: {
              client: this.$store.state.client
            }
          });
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("logout失败", error);
      }
    },

    initAllData() {
      clearTimeout(this.timeOutTimer)
      this.timeOutTimer = setTimeout(() => {
        const token = this.$localStorage.getItem('tk') || ''
        if (token) {
          this.getAllData(true)
          this.initWebsocket()
        } else {
          this.initAllData()
        }
      }, 100);
    }
  },
  mounted() {
    this.initAllData()
    window.addEventListener("beforeunload", e => this.closeHandle(e));
  },
  beforeDestroy() {
    clearTimeout(this.timeOutTimer)
    clearTimeout(this.errorTimer)
    clearTimeout(this.isConnectedTimer)
  }
}