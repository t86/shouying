<template>
  <div class="keyboard">
    <ul>
      <li v-for="item in keyBoardData" :key="item.id" layout="row" layout-align="center center">
        <div class="item" :class="{'active': items.click}" v-for="items in item" :key="items.id" @click.stop="clickKeyBoardHandle(items)">
          <img v-if="items.icon" :src="items.icon" alt="">
          <span :class="{'hasIcon': items.icon}">{{items.name}}</span>
        </div>
      </li>
    </ul>
  </div>
</template>

<script>
  import keyboardReset from '@/assets/order-img/keyboard-reset.png'
  import keyboardDel from '@/assets/order-img/keyboard-del.png'
  import keyboardChoose from '@/assets/order-img/keyboard-choose.png'
  export default {
    data() {
      return {
        keyBoardData: [],
        imgSrc: {
          keyboardReset,
          keyboardDel,
          keyboardChoose
        }
      }
    },
    methods: {
      getKeyBoardData() {
        const keyBoardData = []
        let trArr = []
        for (let i = 0; i < 12; i++) {
          if (i != 0 && i % 3 === 0) {
            keyBoardData.push(trArr)
            trArr = []
          }
          const item = {
            id: i === 10 ? 0 : i + 1,
            name: i >= 9 ? (i === 9 ? this.needPoint ? '.' : '清空' : (i === 10 ? 0 : '回退')) : (i + 1),
            click: false
          }
          item.icon = i === 9 ? (this.needPoint ? '' : this.imgSrc.keyboardReset) : (i === 11 ? this.imgSrc.keyboardDel : '')
          trArr.push(item)
          if (i === 11) keyBoardData.push(trArr)

        }
        return keyBoardData
      },
      clickKeyBoardHandle(keyboardInfo) {
        keyboardInfo.click = true
        this.$emit('changeNum', keyboardInfo.id)
        clearTimeout(this.timer)
        this.timer = setTimeout(() => {
          keyboardInfo.click = false
        }, 150);
      }
    },
    created() {

    },
    mounted() {
      this.keyBoardData = this.getKeyBoardData()
    },
    props: {
      needPoint:{
        default: false  // 是否显示小数点
      }
    },
    components: {

    },
    filters: {

    },
    beforeDestroy() {

      clearTimeout(this.timer)
    }
  }

</script>

<style scoped lang="less">
  .keyboard {

  ul {
    width: 300px;
    height: 252px;
    margin: 0 auto;
    border: 1px solid rgba(255,255,255,0.15);;
    border-radius: 10px;
    border: 1px solid rgba(255,255,255,0.15);
    background: rgba(0,0,0,0.2);
    overflow: hidden;

    li {
      border-bottom: 1px solid rgba(255, 255, 255, 0.15);

      &:nth-last-child(1) {
        border: none;
      }

      .item {
        color: #fff;
        width: 100px;
        height: 62px;
        text-align: center;
        cursor: pointer;
        border-right: 1px solid rgba(255,255,255,0.15);
        box-sizing: border-box;

        &:nth-last-child(1) {
          border-color: transparent;
        }

        &.active {
          background: #002760;
          box-shadow: inset 0px 0px 12px 1px #32B9FF;
        }

        img {
          margin-top: 8px;
          overflow: hidden;
        }

        span {
          display: block;
          font-size: 30px;
          line-height: 62px;
          font-family: PingFangSC-Semibold, PingFang SC;
          font-weight: 600;
          color: #FFFFFF;
          user-select: none;

          &.hasIcon {
            font-size: 14px;
            line-height: 14px;
            letter-spacing: 2px;
          }
        }
      }
    }
  }
}
</style>