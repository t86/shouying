<template>
  <div>
    <div class="contain" ref="containRef">
      <div class="contain-content">
        <ul>
          <li class="contain-content-item" v-for="(item, index) in cardList" :key="index">
            <div class="contain-content-item-left">{{ item.n }}</div>
            <ul class="contain-content-item-right" layout="row" layout-align="start center">
              <li :class="{ 'active': items.id === activeId, 'disabled': items.b == 2 }" v-for="(items, i) in item.ss"
                :key="i">
                <img :class="{ 'active': items.id === activeId }" :src="require('@/assets/card-imgs/zhuantaiduigou.png')"
                  alt />
                <div :class="['bgc' + items.bizStatus]" @click.stop="chooseCard(items)" layout="column"
                  layout-align="center start">
                  <div class="card-name">{{ items.n }}</div>
                </div>
              </li>
            </ul>
          </li>
        </ul>
      </div>
    </div>
    <!-- 箭头 -->
    <div class="arrow">
      <div class="bg" layout="row" layout-align="center center">
        <div class="bg-left" @click="scrollHandle('up')">
          <img :src="require('@/assets/order-img/arrow-Bottom.png')" alt />
        </div>
        <div class="bg-right" @click="scrollHandle('down')">
          <img :src="require('@/assets/order-img/arrow-Bottom.png')" alt />
        </div>
      </div>
    </div>

    <div class="card-info">
      当前选中卡台：{{ selectedInfo.n }}
    </div>
  </div>
</template>
 
<script>
import api_order from "@/api/order";
export default {
  data() {
    return {
      cardList: [],
      activeId: '',
      selectedInfo: {}
    };
  },
  methods: {
    init() {
      this.selectedInfo = {}
      this.activeId = ''
      this.$emit('chooseCardHandle', this.selectedInfo)
      this.getCardList();
    },

    async getCardList() {
      const params = {
        biz_day: this.dateVal //    string  营业日期,格式: yyyy-mm-dd
      };
      try {
        const res = await api_order.reqGetCanBJSeatList(params);
        if (res.code == 1) {
          const businessData = this.$store.state.cardPageInfo.resResultDataObj.businessData || []
          this.cardList = (res.data.regions || []).map(item => ({
            ...item,
            ss: (item.ss || []).map(items => ({
              ...items,
              bizStatus: (businessData.find(ite => ite.seatId == items.id) || {}).bizStatus || '1'
            })),
          }));
        }
      } catch (error) {
        console.log("卡台信息获取失败", error);
      }
    },

    chooseCard(cardInfo) {
      if (cardInfo.b == 2) return
      this.selectedInfo = cardInfo;
      this.activeId = cardInfo.id;
      this.$emit('chooseCardHandle', this.selectedInfo)
    },

    scrollHandle(direction) {
      let dom = this.$refs.containRef;
      const step = 200;
      const scrollTop =
        direction === "down" ? dom.scrollTop + step : dom.scrollTop - step;
      dom.scrollTo(0, scrollTop);
    },
  },
  props: {
    dateVal: {
      default: ""
    }
  }
};
</script>
<style lang="less" scoped>
@import '../../../../style/book/newCardBgc.less';
</style>

<style scoped lang='less'>
.contain {
  // color: rgba(255, 255, 255, .8);

  color: #08080A;
  width: 100%;
  height: calc(100vh - 200px);
  overflow-y: auto;
  scroll-behavior: smooth;
  overflow-x: hidden;
  word-break: break-all;

  .contain-content {
    padding-bottom: 10px;

    &-item {
      background: #2A3959;
      padding: 5px;
      position: relative;
      border-radius: 10px;
      transform: translate(10px, 10px);
      margin-bottom: 10px;
      min-height: 100px;

      &-left {
        position: absolute;
        height: calc(100% - 10px);
        padding: 20px 7px;
        // border: 5px solid #08080A;
        border-radius: 8px;
        text-align: center;
        box-sizing: border-box;
        background: #374368;
        writing-mode: vertical-lr;
        text-orientation: upright;
        letter-spacing: 4px;
      }

      &-right {
        width: calc(100% - 50px);
        min-height: 100px;
        flex-wrap: wrap;
        align-items: center;
        align-content: center;
        margin-left: 51px;

        >li {
          position: relative;
          cursor: pointer;
          border: 2px solid transparent;

          &.disabled {
            opacity: 0.3;
            cursor: no-drop;
          }

          &.active {
            border-color: #FDFF5F;
            border-radius: 10px;
          }

          >img {
            position: absolute;
            left: -2px;
            top: -2px;
            opacity: 0;

            &.active {
              opacity: 1;
            }
          }

          >div {
            padding: 0 10px;
            margin: 3px;
            word-break: break-word;
            width: 120px;
            height: 56px;
            border-radius: 8px;
            box-sizing: border-box;

            .card-name {
              font-size: 16px;
              line-height: 26px;
              word-break: keep-all;
              overflow: hidden;
              transform-origin: left center;
            }

            .card-amt {
              line-height: 16px;
              font-size: 12px;
            }
          }
        }
      }
    }
  }
}


// 箭头
.arrow {
  width: 120px;
  height: 60px;
  position: fixed;
  right: 10px;
  bottom: 0;
  z-index: 100;
  cursor: pointer;

  .bg {
    margin-top: 10px;

    .bg-left,
    .bg-right {
      width: 46px;
      height: 40px;
      background: #FFFFFF;
      // box-shadow: inset 0px 1px 1px 0px #2775BA;
      text-align: center;
      box-shadow: 0px 4px 4px 0px rgba(0, 0, 0, 0.1);
      border: 1px solid #989FAF;

      img {
        width: 20px;
        margin-top: 10px;
      }
    }

    .bg-left {
      border-radius: 8px 0px 0px 8px;
      border-right: none;

      img {
        transform: rotate(180deg);
      }
    }

    .bg-right {
      border-radius: 0 8px 8px 0;
    }
  }
}

.card-info {
  // color: rgba(255, 255, 255, .8);
  font-size: 24px;
  font-family: PingFangSC, PingFang SC;
  font-weight: 400;

  color: #08080A;
  padding: 20px 60px;
  text-align: right;
}
</style>