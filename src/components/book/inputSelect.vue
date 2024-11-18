<template>
  <!-- 基于element-ui2.x版本input写的input模糊查询组件 -->
  <div>
    <div ref="selectOption" style="position: relative;">
      <el-input v-model="selectInputVal" :type="inputType" ref="selectInput" :placeholder="placeholder" min="0" @input="inputHandle"></el-input>
      <ul class="options" ref="optionRef" v-if="optionsList.length > 0"
        :style="'width:' + selectOptionWidth + 'px;top:' + selectOptionTop + 'px'">
        <li v-for="(item, index) in optionsList" :key="item.id" :class="{'active': index == activeIndex}" @click="clickOption(item)">
          {{ item.name }}  {{ item.code }}
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
  export default {
    data() {
      return {
        selectInputVal: this.value,
        selectOptionWidth: 0,
        selectOptionTop: 0,
        activeIndex: 0
      };
    },
    methods: {
      inputFocusHandle() {
        if(this.autoFocus){
          this.$nextTick(() => {
            this.$refs.selectInput.focus()
          }, 1);
        }
      },
      getOptionsOffset() {
        this.selectOptionWidth = this.$refs.selectOption.children[0].offsetWidth;
        this.selectOptionTop = this.$refs.selectOption.children[0].offsetHeight;
      },
      inputHandle(value) {
        console.log("input handle ...")
        if(this.showKeyBoard) {
          setTimeout(()=> {
            this.keyboardShow()
          }, 100)
        }
        this.$emit("selectInputHandle", value);
      },
      clickOption(info) {
        this.$emit("selectOptionItem", info);
      },
      inputBlurHandle() {
        this.$emit("selectBlurHandle");
        if(this.showKeyBoard) {
          this.keyboardLeave();
        }
      },
      keyboardShow() {
        if (
          window.atool
          && window.atool.getTermType() == "android" &&
          ("showSoftInput" in window.atool)
        ) {
          atool.showSoftInput();
          atool.executeJs(`this.$refs.selectInput.focus()`)
        }
      },
      keyboardLeave() {
        setTimeout(() => {
          if (
            window.atool
            && window.atool.getTermType() == "android" &&
            ("hideSoftInput" in window.atool)
          ) {
            atool.executeJs(`this.$refs.selectInput.blur()`);
            atool.hideSoftInput();
            atool.restart();
          }
        }, 10)
      },
      keyHandle(e){
        if(this.optionsList.length > 0){
          if(e.keyCode == 38) {
            // up
            this.activeIndex = Math.max(0, this.activeIndex - 1)
            if(this.activeIndex >= 5) {
              this.$refs.optionRef.scrollTo(0, (this.activeIndex - 5) * 40)
            }
          } else if(e.keyCode == 40) {
            // down
            this.activeIndex = Math.min(this.optionsList.length - 1, this.activeIndex + 1)
            if(this.activeIndex > 5) {
              this.$refs.optionRef.scrollTo(0, (this.activeIndex - 5) * 40)
            }
          } else if (e.keyCode == 13) {
            const currentInfo = this.optionsList[this.activeIndex]
            this.clickOption(currentInfo)
          }
        }
      }
    },
    created() { },
    // updated() {
    //   this.inputFocusHandle()
    // },
    mounted() {
      this.getOptionsOffset();
      document.addEventListener("click", this.inputBlurHandle);
      document.onkeydown = this.keyHandle      
      this.inputFocusHandle()
    },
    props: {
      value: {
        default: "",
      },
      inputType: {
        default: "text",
      },
      placeholder: {
        type: String,
        default: "",
      },
      optionsList: {
        type: Array,
        default: () => [],
      },
      autoFocus: {
        type: Boolean,
        default: false,
      },
      showKeyBoard: {
        type: Boolean,
        default: false
      }
    },
    watch: {
      value(val) {
        this.selectInputVal = val;
      },
      optionsList: {
        handler(newVal){
          document.onkeydown = this.keyHandle
        },
        deep: true,
        immediate: true
      },
    },
    beforeDestroy() {
      document.removeEventListener("click", this.inputBlurHandle);
    },
  };
</script>

<style scoped>
  * {
    margin: 0;
    padding: 0;
    list-style: none;
  }

  ul.options {
    position: absolute;
    left: 0;
    border: 1px solid #dcdfe6;
    border-radius: 4px;
    z-index: 99999;
    background-color: #2A3959;
    box-sizing: border-box;
    max-height: 300px;
    overflow-y: auto;
  }

  li {
    cursor: pointer;
    /* border-bottom: 1px solid #dcdfe6; */
    user-select: none;
    padding: 0 10px;
    color: #fff;
  }
  li.active {
    background-color: rgba(90, 90, 90, 0.5);
  }

  li:hover {
    background-color: rgba(90, 90, 90, 0.5);
  }

  li:last-child {
    border-bottom: none;
  }
</style>