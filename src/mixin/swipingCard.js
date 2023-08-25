import api_auth from '@/api/UtilAuth'
import eventVue from '@/utils/eventVue';

export default {
  methods: {
    init() {
      // 二维码扫描完成后回调
      window.qr_scan_callback = this.qr_scan_callback
      // 读取卡号
      window.card_scan_done_callback = this.card_scan_done_callback
      // 循环读卡pc
      window.loopReadCard = this.loopReadCard
      // 停止循环读卡
      window.stopLoopReadCard = this.stopLoopReadCard
    },

    // 循环读卡(pc)
    loopReadCard() {
      if(!this.isPcTerminal) return
      this.stopLoopReadCard()
      loopTimer = setInterval(() => {
        console.log('读卡中...')
        this.card_scan_done_callback()
      }, 1500);
    },

    // 停止循环读卡
    stopLoopReadCard() {
      if(window.loopTimer) clearInterval(window.loopTimer)
      window.loopTimer = null
    },

    // 开启二维码扫描
    start_qr_code_scan() {
      try {
        atool.startQrCodeScan()
        this.$message.success('开始扫码二维码')
      } catch (error) {
        console.log('开启二维码扫描失败：', error)
        this.$message.warning('开启二维码扫描失败：' + error)
      }
    },

    // 二维码扫描完成后回调
    qr_scan_callback() {
      let qrCodeText = ''
      try {
        qrCodeText = atool.getQrCode();
        this.$message.success('qrCode:' + qrCodeText)
      } catch (error) {
        console.log('qrCode信息获取失败：', error)
        this.$message.warning('qrCode信息获取失败：' + error)
      }
    },

    // 是否支持nfc
    has_nfc() {
      let hasNfc = false
      try {
        hasNfc = atool.hasNFC() == 1
        this.$message.success('是否支持nfc:' + hasNfc)
      } catch (error) {
        console.log('是否支持nfc失败：', error)
        this.$message.warning('是否支持nfc失败：' + error)
      }

      return hasNfc
    },

    // 读取卡号
    card_scan_done_callback() {
      let cardNo = ''
      try {
        cardNo = atool.getCardNo();
        // console.log('当前读取的卡号为', cardNo)
        if (!cardNo) {
          return
        } else {
          this.stopLoopReadCard()
        }

        this.getCardPassword(cardNo)
      } catch (error) {
        this.stopLoopReadCard()
        console.log('cardNo信息获取失败：', error)
        this.$message.warning('当前设备不支持读卡刷卡，请用使用账号密码操作')
      }
    },

    // 通过云端接口查询卡密码
    async getCardPassword(cardNo) {
      const params = {
        card_no: cardNo.toString(), // string   卡号
      }
      try {
        const res = await api_auth.auth.reqGetCardPassword(params)
        if (res.code == 1) {
          this.get_card_data(cardNo, res.data.p)
        } else {
          window.loopReadCard()
          this.$message.warning(res.msg)
        }
      } catch (error) {
        window.loopReadCard()
        console.log('通过卡号查询卡密码失败', error)
      }
    },

    // 通过查询返回的卡密码,读取卡数据验证身份
    get_card_data(cardNo = '', password = '') {
      let cardInfoText = ''
      try {
        cardInfoText = atool.getCardData(password);  // 参数为密码
        if (cardInfoText.length == 0) return this.$message.warning('卡验证失败,请确认卡未离开读卡位置或是有效卡')
        // console.log('读取到卡数据:' + cardInfoText)
        const routeName = this.$route.name
        this.getRouteName(routeName, cardNo, cardInfoText)
      } catch (error) {
        console.log('获取卡片身份信息失败：', error)
        this.$message.warning('获取卡身份信息失败：' + error)
      }
    },

    // 获取到机器码
    get_machine_code() {
      let machineCode = ''
      try {
        machineCode = atool.getMachineCode();
        this.$message.success('获取到机器码数据为:' + machineCode)
      } catch (error) {
        console.log('获取到机器码失败', error)
        this.$message.warning('获取到机器码失败：' + error)
      }
      return machineCode
    },

    // 获取终端类型
    get_term_type() {
      let termType = ''
      try {
        termType = atool.getTermType();
        // this.$message.success('获取终端类型为:' + termType)
      } catch (error) {
        console.log('获取终端类型失败', error)
        // this.$message.warning('获取终端类型失败' + error)
      }
      return termType
    },

    // 是否为pc端
    isPcTerminal(){
      return this.get_term_type() == 'pc'
    },

    // 退出程序
    exit() {
      atool.exit();
    },


    getRouteName(routeName, cardNo, password) {
      switch (routeName) {
        case 'Thelogin':
          this.submit(cardNo, password, 2)
          break;
        case 'orderCard':
          eventVue.$emit('saveWineToShoppingCartHandle', {
            cardNo,
            password
          })
          break;
        case 'myOrder':
          eventVue.$emit('empMyOrderHandle', {
            cardNo,
            password
          })
          break;
        case 'shoppingCart':
          eventVue.$emit('empShoppingCartHandle', {
            cardNo,
            password
          })
          break;
        case 'payOrder':
          // 付款抹零授权
          eventVue.$emit('moneyPayOrderHandle', {
            cardNo,
            password
          })
          // 批量优惠、批量优惠2授权
          eventVue.$emit('empMyOrderHandle', {
            cardNo,
            password
          })
          break;
        case 'moneyCard':
          // 查看优惠额度
          eventVue.$emit('YHCount', {
            cardNo,
            password
          })
          break;
        case 'orderMealList':
          if (this.$store.state.userInfo.authStatus == 4) {
            eventVue.$emit('payYH2OrderHandle', {
              cardNo,
              password
            })
          } else {
            this.$message.warning('刷卡无效，请在登录或授权时进行刷卡！')
          }
          break;

        // 存酒仓库
        case 'saveNeedToLib': // 存酒待入库
        case 'getNeedToLib': // 取酒待入库
        case 'toStore': // 待充公
          this.swiperSubmit(cardNo, password, 2)
          break;
          
        default:
          this.$message.warning('刷卡无效，请在登录或授权时进行刷卡！')
          break
      }
    }
  },

  created() {
    this.init()
  }
}