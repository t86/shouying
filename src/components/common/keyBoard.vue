<template>
  <div class="keyboard">
    <div class="ul" :style="{width:width+'px'}">
      <div class="li" v-for="(item, index) in keyBoardData" :key="index" >
        <div v-if="!!landscape" layout="row" layout-align="center center">
          <div  class="item" :class="{'active': items.click}" v-for="items in item" :key="items.id" @click.stop="clickKeyBoardHandle(items)" :style="{
              width: itemWidth + 'px',
              height: itemHeight + 'px',
            }">
            <img v-if="items.icon" :src="items.icon" alt="">
            <span :style="{
              width: itemWidth + 'px',
              height: itemHeight + 'px',
            }"
            :class="{'hasIcon': items.icon}">{{items.name}}</span>
          </div>
          </div>
        <div v-else layout="row" layout-align="center center">
          <div  class="item" :class="{'active': items.click}" v-for="items in item" :key="items.id" @click.stop="clickKeyBoardHandle(items)" :style="{
            width: itemWidth + 'px',
            height: itemWidth + 'px',
          }">
            <img v-if="items.icon" :src="items.icon" alt="">
            <span :class="{'hasIcon': items.icon}">{{items.name}}</span>
          </div>
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
        if (this.landscape) {
          if(this.oneLine) {
            let trArr = []
            for (let i = 0; i < 12; i++) {
              if (i != 0 && i % 6 === 0) {
                keyBoardData.push(trArr)
                trArr = []
              }
              const item = {
                id: i === 11 ? i : i === 5 ? 10 : i < 5 ? i : i - 1,
                name: i === 11 ? '' : i === 5 ? '' : i < 5 ? i : i - 1,
                click: false
              }
              
              item.icon = i === 5 ? this.imgSrc.keyboardDel : i === 11 ? this.imgSrc.keyboardReset : ''
              trArr.push(item)
              if (i === 11) keyBoardData.push(trArr)
            }
          } else {
            let trArr = []
            for (let i = 0; i < 10; i++) {
              trArr.push({
                id: i,
                name: i,
                click: false
              })
            }
            trArr.push({
              id: 10,
              name: '清空',
              icon: this.imgSrc.keyboardReset
            })
            trArr.push({
              id: 11,
              name: '删除',
              icon: this.imgSrc.keyboardDel
            })
            keyBoardData.push(trArr)
          }
        } else {
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
      },
      oneLine: {
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