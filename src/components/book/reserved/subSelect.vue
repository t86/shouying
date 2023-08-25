<template>
  <!-- 基于原生标签写的select单项下拉框选择组件 -->
  <div>
    <div class="select-bg" v-if="showOption" @click.stop="showOrHideOption"></div>
    <div ref="selectOption">
      <div class="select-com" :class="{'placeholder-color': !selectVal, 'select-active': showOption}"
        v-text="selectVal ? selectVal : placeholder" @click.stop="showOrHideOption"></div>
      <ul class="options" v-if="showOption"
        :style="'width:' + selectOptionWidth + 'px;bottom:' + selectOptionTop + 'px'">
        <li v-for="(item, index) in optionsList" :key="item.id" @click="clickOption(item, index)">
          <span>{{ item.name }} {{ item.code }}</span>
          <ul class="sub" v-if="item.showSubList" :style="`top:calc(50% + ${optionScrollTop}px)`">
            <li v-for="(items, ind) in item.cardList" :key="ind" @click.stop="clickOption(items, index, true)">{{items.name}}</li>
          </ul>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
  const selectFirstOptInfo = {}
  const selectSecondOptInfo = {}
  export default {
    data() {
      return {
        selectVal: this.value,
        selectOptionWidth: 0,
        selectOptionTop: 0,
        optionsList: [],
        optionScrollTop: 0,
        showOption: false
      };
    },
    methods: {
      getOptionsOffset() {
        this.selectOptionWidth = this.$refs.selectOption.children[0].offsetWidth;
        this.selectOptionTop = this.$refs.selectOption.children[0].offsetHeight;
      },
      showOrHideOption() {
        this.showOption = !this.showOption
        // this.$emit('getOption')
        if (this.showOption) {
          clearTimeout(this.setTimer)
          this.setTimer = setTimeout(() => {
            document.querySelector('.options').removeEventListener('scroll', this.scrollHandle)
            document.querySelector('.options').addEventListener('scroll', this.scrollHandle)
          }, 100)

        }
      },

      scrollHandle(e) {
        this.optionScrollTop = e.target.scrollTop
      },

      clickOption(info, index, isSub = false) {  // isSub:是否为二级选型(选择卡台)
        if (!isSub) { // 选择区域
          this.optionsList.forEach((el, i) => {
            if (index === i) {
              this.optionsList[index]['showSubList'] = true
              selectFirstOptInfo.orgionId = el.id
              selectFirstOptInfo.orgionName = el.name
              selectSecondOptInfo.seatId = ''
              selectSecondOptInfo.seatName = ''
            }
            else el['showSubList'] = false
          })
        } else {
          selectSecondOptInfo.seatId = info.seatId
          selectSecondOptInfo.seatName = info.name
          this.showOrHideOption()
        }

        this.$emit("selectSubOptionItem", { ...selectFirstOptInfo, ...selectSecondOptInfo })
      },
      inputBlurHandle() {
        // this.$emit("selectBlurHandle")
      },
      getOption() {
        const resultData = JSON.parse(JSON.stringify(this.$store.state.cardPageInfo.tabList))
        const cardList = JSON.parse(JSON.stringify(this.$store.state.cardPageInfo.cardList))
        resultData.forEach(el => {
          el.cardList = [{ name: '全部', id: 0 }, ...cardList.filter(ele => ele.regionId === el.id)]
          el.showSubList = false
        })
        this.optionsList = resultData
      }
    },
    created() { },
    mounted() {
      this.getOptionsOffset();
      this.getOption();
      document.addEventListener("click", this.inputBlurHandle);
    },
    props: {
      value: {
        default: "",
      },
      placeholder: {
        type: String,
        default: "",
      }
    },
    watch: {
      value(val) {
        this.selectVal = val;
      },
    },
    beforeDestroy() {
      clearTimeout(this.setTimer)
      document.removeEventListener("click", this.inputBlurHandle);
    },
  };
</script>

<style scoped lang="less">
  * {
    margin: 0;
    padding: 0;
    list-style: none;
  }

  .select-com {
    border: 1px solid #ccc;
    background: rgba(0, 0, 0, 0.2);
    border-radius: 10px;
    color: #fff;
    padding: 0 15px;
    cursor: pointer;
  }

  .select-active {
    height: 100%;
    border: 1px solid #32B9FF;
  }

  .placeholder-color {
    color: #bbb;
  }

  .select-bg {
    position: fixed;
    width: 100vw;
    height: 100vh;
    z-index: 9;
    left: 0;
    top: 0;
  }

  ul.options {
    position: absolute;
    left: 0;
    border: 1px solid #dcdfe6;
    border-radius: 4px;
    z-index: 99999;
    background-color: #08080a;
    box-sizing: border-box;
    max-height: 300px;
    overflow-y: auto;
    transform: translate(0, 0);

    >li {
      cursor: pointer;
      /* border-bottom: 1px solid #dcdfe6; */
      user-select: none;
      padding: 0 10px;
      color: #fff;

      ul.sub {
        position: fixed;
        right: 0;
        top: 50%;
        transform: translateY(-50%);
        width: 50%;
        max-height: 100%;
        border: 1px solid #ccc;
        overflow-y: auto;
        background-color: #08080a;

        >li {
          padding-left: 10px;
        }
      }
    }

    li:hover {
      background-color: rgba(90, 90, 90, 0.5);
    }

    li:last-child {
      border-bottom: none;
    }
  }
</style>