<template>
  <div class="keyboard">
    <div class="ul" :style="{width:width+'px'}">
      <div class="li" v-for="item in keyBoardData" :key="item.id" layout="row" layout-align="center center">
      <div v-if="!!landscape" class="item" :class="{'active': items.click}" v-for="items in item" :key="items.id" @click.stop="clickKeyBoardHandle(items)" :style="{
          width: itemWidth + 'px',
          height: itemHeight + 'px',
        }">
        <img v-if="items.icon" :src="items.icon" alt="">
        <span :class="{'hasIcon': items.icon}">{{items.name}}</span>
      </div>
      <div v-else class="item" :class="{'active': items.click}" v-for="items in item" :key="items.id" @click.stop="clickKeyBoardHandle(items)" :style="{
          width: itemWidth + 'px',
          height: itemWidth + 'px',
        }">
          <img v-if="items.icon" :src="items.icon" alt="">
          <span :class="{'hasIcon': items.icon}">{{items.name}}</span>
        </div>
      </div>
    </div>
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
      },
      itemWidth: {
        default: '88'  // 每个item的宽度
      },
      itemHeight: {
        default: '88'  // 每个item的宽度
      },
      width:{
        default: 270  // 整个键盘的宽度
      },
      landscape: {
        default: false
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
  @import '../../style/common/keyboard.less';
</style>