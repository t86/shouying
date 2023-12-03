<template>
  <!-- 基于element-ui2.x版本input写的input模糊查询组件 -->
  <div>
    <div ref="selectOption">
      <el-input v-model="selectInputVal" :type="inputType" ref="selectInput" :placeholder="placeholder" min="0"
        @input="inputHandle"></el-input>
      <ul class="options" ref="optionRef" :style="'width:' + selectOptionWidth + 'px;top:' + selectOptionTop + 'px'">
        <li v-for="(item, index) in optionsList" :key="item.id" :class="{ 'active': index == activeIndex }"
          @click="clickOption(item)">
          {{ item.name }} {{ item.code }}
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
      if (this.autoFocus) {
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
      this.$emit("selectInputHandle", value);
    },
    clickOption(info) {
      this.$emit("selectOptionItem", info);
    },
    inputBlurHandle() {
      this.$emit("selectBlurHandle");
    },
    keyHandle(e) {
      if (this.optionsList.length > 0) {
        if (e.keyCode == 38) {
          // up
          this.activeIndex = Math.max(0, this.activeIndex - 1)
          if (this.activeIndex >= 5) {
            this.$refs.optionRef.scrollTo(0, (this.activeIndex - 5) * 40)
          }
        } else if (e.keyCode == 40) {
          // down
          this.activeIndex = Math.min(this.optionsList.length - 1, this.activeIndex + 1)
          if (this.activeIndex > 5) {
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
  },
  watch: {
    value(val) {
      this.selectInputVal = val;
    },
    optionsList: {
      handler(newVal) {
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

<style scoped  lang="less">
* {
  margin: 0;
  padding: 0;
  list-style: none;
}

/deep/ .el-input {
  input {
    background: #FAFAFC;
    border-radius: 8px;
    border: 1px solid #C4CBD7;
    font-size: 20px;
    font-family: PingFangSC, PingFang SC;
    font-weight: 400;
    color: #08080A;

    &::placeholder {

      color: #7A7A7A;
    }

    &:focus {

      border: 2px solid #3373E8;
    }
  }
}

ul.options {
  position: absolute;
  left: 0;
  border: 1px solid #dcdfe6;
  border-radius: 4px;
  z-index: 99999;

  background: #FAFAFC;
  box-sizing: border-box;
  max-height: 300px;
  overflow-y: auto;

}

li {
  cursor: pointer;
  /* border-bottom: 1px solid #dcdfe6; */
  user-select: none;
  padding: 0 10px;

  color: #1A1A21;
}

li.active {

  background: rgba(16, 16, 32, 0.4);
}

li:hover {

  background: rgba(16, 16, 32, 0.4);
}

li:last-child {
  border-bottom: none;
}
</style>