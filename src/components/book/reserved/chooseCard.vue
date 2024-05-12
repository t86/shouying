<template>
  <div>
    <el-drawer
      title="选择卡台"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="80%"
    >
      <div class="contain" ref="containRef">
        <div class="contain-content">
          <ul>
            <li class="contain-content-item" v-for="(item,index) in tabList" :key="index">
              <div class="contain-content-item-left">{{item.name}}</div>
              <ul class="contain-content-item-right" layout="row" layout-align="start center">
                <li
                  :class="{'active': items.selected, 'disabled': items.disabled}"
                  v-for="(items,i) in item.ss"
                  :key="i"
                >
                  <img :class="{'active': items.selected}" :src="require('@/assets/card-imgs/zhuantaiduigou.png')" alt />
                  <div
                    :class="['bgc' + items.bizStatus]"
                    @click.stop="chooseCard(items)"
                    layout="column"
                    layout-align="center start"
                  >
                    <div class="card-name">{{items.name}}</div>
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
            <img :src="require('@/assets/order-img/arrowBottom.png')" alt />
          </div>
          <div class="bg-right" @click="scrollHandle('down')">
            <img :src="require('@/assets/order-img/arrowBottom.png')" alt />
          </div>
        </div>
      </div>

      <div class="card-info" layout="row" layout-align="start center">
        当前选中卡台：<div style="margin-right: 10px;" v-for="item in selectedList"> {{ item.name}}</div>
      </div>
      <!-- 提交按钮 -->
      <div class="form-btn">
        <el-button type="info" @click="closeDrawerHandle">取消</el-button>
        <el-button type="primary" @click="onSubmit">确认</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      selectedList: [],
      show: this.showDrawer, // 是否显示drawer
    };
  },
  methods: {
    init() {
      this.selectedList = []
      this.tabList.forEach(it => {
        it.ss = []
        this.cardList.forEach(item => {
          item.disabled = !item.options.find(item => item.id == 1)
          if(it.id == item.regionId) {
            it.ss = [...it.ss, item]
          }
        })
      })
      this.selectedList = this.cardList.filter(item => item.selected)
    },
    onSubmit(){
      this.$emit('chooseCardHandle', this.selectedList)
      this.closeDrawerHandle()
    },
    chooseCard(cardInfo) {
      if(!cardInfo.options.find(item => item.id == 1)) {
        this.$message.error('该卡台不支持预留')
        return
      }
      cardInfo.selected = !cardInfo.selected
      this.selectedList = this.cardList.filter(item => item.selected)
    },

    scrollHandle(direction) {
      let dom = this.$refs.containRef;
      const step = 200;
      const scrollTop =
        direction === "down" ? dom.scrollTop + step : dom.scrollTop - step;
      dom.scrollTo(0, scrollTop);
    },
    closeDrawerHandle() {
      this.$emit("changeShowDrawer", false);
    },
  },
  props: {
    dateVal: {
      default: ""
    },
    cardList: {
      default: []
    },
    showDrawer: {
      default: false
    },
    tabList: {
      default: []
    },
  },
  watch: {
    showDrawer(newVal) {
      if(newVal) {
        this.init()
      }
      this.show = newVal;
    },
  }
};
</script>
<style lang="less" scoped>
@import '../../../style/book/cardBgc.less';
</style>

<style scoped lang='less'>
  .contain {
    color: rgba(255, 255, 255, .8);
    width: 100%;
    height: calc(100vh - 200px);
    overflow-y: auto;
    scroll-behavior: smooth;
    overflow-x: hidden;
    word-break: break-all;
    z-index: 2100;

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

            &.disabled{
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
        background: #0D172D;
        box-shadow: inset 0px 1px 1px 0px #2775BA;
        text-align: center;

        img {
          width: 20px;
          margin-top: 10px;
        }
      }

      .bg-left {
        border-radius: 30px 0px 0px 30px;

        img {
          transform: rotate(180deg);
        }
      }

      .bg-right {
        border-radius: 0 30px 30px 0;
      }
    }
  }

  .card-info {
    color: rgba(255, 255, 255, .8);
    padding: 20px 60px;
    text-align: left;
  }
  .form-btn {
      width: 100%;
      height: 54px;
      position: absolute;
      left: 0;
      bottom: 0;
      text-align: center;
      background: #161D33;

      button {
        margin-top: 12px;
      }
    }
</style>