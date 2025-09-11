<template>
  <div class="vip-keyboard">
    <div class="ul" :style="{width:width+'px'}">
      <div class="li" v-for="(item, index) in keyBoardData" :key="index" >
        <div layout="row" layout-align="center center">
          <div  class="item" :class="{'active': items.click, 'has-icon': items.icon}" v-for="items in item" :key="items.id" @click.stop="clickKeyBoardHandle(items)" :style="{
              width: getItemWidth(items, index) + 'px',
              height: itemHeight + 'px',
            }">
            <img v-if="items.icon" :src="items.icon" alt="">
            <span :style="{
              width: getItemWidth(items, index) + 'px',
              height: itemHeight + 'px',
            }"
            :class="{'hasIcon': items.icon}">{{items.name}}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import keyboardReset from '@/assets/order-img/keyboard-reset.png'
  import keyboardDel from '@/assets/order-img/keyboard-del.png'
  
  export default {
    name: 'VipKeyBoard',
    data() {
      return {
        keyBoardData: [],
        imgSrc: {
          keyboardReset,
          keyboardDel
        }
      }
    },
    methods: {
      getKeyBoardData() {
        const keyBoardData = []
        
        if (this.landscape) {
          // 横屏模式：保持原来的6x2布局
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
          // 竖屏模式：6+4布局
          // 第一行：1 2 3 4 5 6
          // 第二行：7 8 9 0 清空 删除
          const firstRow = []
          const secondRow = []
          
          // 第一行：1-6
          for (let i = 1; i <= 6; i++) {
            firstRow.push({
              id: i,
              name: i,
              click: false
            })
          }
          
          // 第二行：7 8 9 0 清空 删除
          for (let i = 7; i <= 9; i++) {
            secondRow.push({
              id: i,
              name: i,
              click: false
            })
          }
          secondRow.push({
            id: 0,
            name: 0,
            click: false
          })
          secondRow.push({
            id: 10,
            name: '清空',
            icon: this.imgSrc.keyboardReset,
            click: false
          })
          secondRow.push({
            id: 11,
            name: '删除',
            icon: this.imgSrc.keyboardDel,
            click: false
          })
          
          keyBoardData.push(firstRow)
          keyBoardData.push(secondRow)
        }
        
        return keyBoardData
      },
      
      // 计算每个按键的宽度
      getItemWidth(item, rowIndex) {
        if (this.landscape) {
          return this.itemWidth
        } else {
          // 竖屏模式下，第二行的按钮宽度需要特殊处理
          if (rowIndex === 1 && (item.id === 10 || item.id === 11)) {
            // 功能键稍微宽一点
            return this.itemWidth + 10
          }
          return this.itemWidth
        }
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
      itemWidth: {
        default: 88  // 每个item的宽度
      },
      itemHeight: {
        default: 44  // 每个item的高度 - 符合响应式设计规则
      },
      width:{
        default: 600  // 整个键盘的宽度
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
  .vip-keyboard {
    .ul {
      margin: 0 auto;
      border: 1px solid #4a90e2;
      border-radius: 8px; // 符合响应式设计规则
      background: linear-gradient(145deg, #1a202c 0%, #2d3748 100%);
      box-shadow: 0 4px 20px rgba(74, 144, 226, 0.15), 
                  0 2px 8px rgba(0, 0, 0, 0.2);
      overflow: hidden;

      .li {
        margin-bottom: 6px; // 增加行间距

        &:last-child {
          margin-bottom: 0;
        }
        
        border-bottom: 1px solid rgba(74, 144, 226, 0.2);

        &:nth-last-child(1) {
          border: none;
        }

        .item {
          color: #e2e8f0;
          text-align: center;
          cursor: pointer;
          border-right: 1px solid rgba(74, 144, 226, 0.2);
          display: flex;
          flex-direction: column;
          justify-content: center;
          align-items: center;
          margin-right: 6px; // 按键间距
          border-radius: 6px; // 符合响应式设计规则
          background: linear-gradient(145deg, #2d3748 0%, #1a202c 100%);
          border: 1px solid rgba(74, 144, 226, 0.3);
          transition: all 0.2s ease;
          
          &:last-child {
            margin-right: 0;
          }

          &:hover {
            background: linear-gradient(145deg, #3d4758 0%, #2a303c 100%);
            border-color: #4a90e2;
            box-shadow: 0 2px 8px rgba(74, 144, 226, 0.25);
            transform: translateY(-1px);
          }

          &.active {
            background: linear-gradient(145deg, #4a90e2 0%, #357abd 100%);
            color: #ffffff;
            border-color: #4a90e2;
            box-shadow: 0 4px 12px rgba(74, 144, 226, 0.4), 
                        inset 0 1px 3px rgba(255, 255, 255, 0.2);
            transform: translateY(1px);
          }

          // 功能键特殊样式
          &.has-icon {
            background: linear-gradient(145deg, #667eea 0%, #764ba2 100%);
            border: 1px solid #667eea;
            color: #ffffff;
            
            &:hover {
              background: linear-gradient(145deg, #7c8ffc 0%, #8a63b4 100%);
              box-shadow: 0 3px 12px rgba(102, 126, 234, 0.4);
              transform: translateY(-1px);
            }
            
            &:active, &.active {
              background: linear-gradient(145deg, #5a6bd8 0%, #6a4d90 100%);
              box-shadow: 0 2px 8px rgba(102, 126, 234, 0.6), 
                          inset 0 1px 3px rgba(255, 255, 255, 0.2);
              transform: translateY(1px);
            }
          }

          img {
            overflow: hidden;
            margin-bottom: 4px;
          }

          span {
            display: block;
            font-size: 16px; // 符合响应式设计规则
            font-family: PingFangSC-Semibold, PingFang SC, -apple-system, BlinkMacSystemFont, sans-serif;
            font-weight: 600;
            color: #e2e8f0;
            user-select: none;
            text-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);

            &.hasIcon {
              font-size: 12px; // 符合响应式设计规则
              line-height: 12px;
              letter-spacing: 0.5px;
              font-weight: 500;
            }
          }
        }
      }
    }
  }

  // 竖屏适配
  @media (orientation: portrait) {
    .vip-keyboard {
      .ul {
        width: 95% !important;
        box-shadow: 0 2px 16px rgba(74, 144, 226, 0.12), 
                    0 1px 6px rgba(0, 0, 0, 0.15);
        
        .li .item {
          span {
            font-size: 14px !important; // 竖屏时适中的字体大小
            
            &.hasIcon {
              font-size: 11px !important;
              letter-spacing: 0.3px;
            }
          }
        }
      }
    }
  }

  // 小屏幕适配
  @media (max-width: 900px) {
    .vip-keyboard {
      .ul {
        width: 95% !important;
        
        .li .item {
          border-radius: 4px; // 小屏幕时减小圆角
          
          &:hover {
            transform: translateY(-0.5px); // 减小悬浮效果
          }
        }
      }
    }
  }
</style>
