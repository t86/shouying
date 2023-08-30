<template>
  <div class="simple-key-board" :style="{'width' : size == 'big' ? '430px' : '240px'}">
    <div class="ul item" layout="row" layout-align="start center">
      <div
        class="li"
        v-for="(item, i) in list"
        :key="i"
        layout="row"
        layout-align="center center"
        @click="clickItemHandle(item,i)"
        :style="{'width': size == 'big' ? '72px' : '40px'}"
      >
        <span :class="{'active': activeIndex == i}" v-html="item.name"></span>
      </div>
      <div class="li" layout="column" layout-align="center center" :style="{'width': size == 'big' ? '72px' : '40px'}"  @click="subValHandle">
        <img :src="require('@/assets/order-img/keyboard-del.png')" alt />
        <span class="back">回退</span>
      </div>
    </div>
    <div v-if="currentItem.length>0" class="ul item-info" layout="row" layout-align="start center">
      <div class="li" v-for="item in currentItem" :key="item" @click="$emit('addInputHandle', item)" :style="{'width': size == 'big' ? '72px' : '40px'}">{{item}}</div>
    </div>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      activeIndex: -1,
      currentItem: [],
      list: [
        {
          id: 0,
          name: "ABC<br/>DEF",
          children: ["A", "B", "C", "D", "E", "F"]
        },
        {
          id: 1,
          name: "GHI<br/>JKL",
          children: ["G", "H", "I", "J", "K", "L"]
        },
        {
          id: 2,
          name: "MNO<br/>PQR",
          children: ["M", "N", "O", "P", "Q", "R"]
        },
        {
          id: 3,
          name: "STU<br/>VWX",
          children: ["S", "T", "U", "V", "W", "X"]
        },
        {
          id: 4,
          name: "YZ",
          children: ["Y", "Z"]
        }
      ]
    };
  },
  methods: {
    clickItemHandle(itemInfo, index) {
      if(this.activeIndex == index) {
        this.currentItem = []
        this.activeIndex = -1
        return
      }
      this.activeIndex = index;
      this.currentItem = itemInfo.children;
    },
    subValHandle(){
      this.currentItem = []
      this.activeIndex = -1
      this.$emit('subInputHandle')
    }
  },
  created() {},
  mounted() {},
  props: {
    size: {
      default: 'big'
    }
  },
  components: {},
  filters: {}
};
</script>

<style scoped lang="less">
.simple-key-board {
  position: relative;
  width: 430px;
  .ul {
    border-radius: 8px;
    width: 100%;
    max-width: 430px;
    background: rgba(25, 34, 54, 0.7);
    //     background: linear-gradient(
    //   180deg,
    //   rgba(25, 34, 54, 0.7) 0%,
    //   rgba(15, 21, 38, 0.7) 100%
    // );
    border: 1px solid rgba(255, 255, 255, 0.14);
    .li {
      width: 72px;
      height: 44px;
      padding: 4px 0;
      box-sizing: border-box;
      text-align: center;
      cursor: pointer;
      border-right: 1px solid rgba(255, 255, 255, 0.15);
      img {
        width: 20px;
      }

      &:nth-last-child(1) {
        border: none;
      }

      span {
        font-size: 16px;
        &.active {
          color: #6a9eff;
        }
        &.back {
          font-size: 12px;
          margin-top: 2px;
        }
      }
    }
  }

  .ul.item-info {
    position: absolute;
    right: -2px;
    top: 50px;
    width: auto;
    .li {
      line-height: 38px;
    }
  }
}
</style>