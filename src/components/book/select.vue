<template>
  <!-- 基于原生标签写的select单项下拉框选择组件 -->
  <div>
    <div ref="selectOption" style="height:100%;position:relative;">
      <div class="select-com" :class="{'placeholder-color': !selectVal, 'select-active': optionsListArr.length>0}" v-text="selectVal ? selectVal : placeholder"
        @click.stop="clickSelect"></div>
      <ul class="options" v-if="optionsListArr.length"
        :style="'width:' + selectOptionWidth + 'px;top:' + selectOptionTop + 'px'">
        <li v-for="item in optionsListArr" :key="item.id" @click="clickOption(item)">
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
        optionsListArr: [], // options
        selectVal: this.value,
        selectOptionWidth: 0,
        selectOptionTop: 0,
      };
    },
    methods: {
      getOptionsOffset() {
        this.selectOptionWidth = this.$refs.selectOption.children[0].offsetWidth;
        this.selectOptionTop = this.$refs.selectOption.children[0].offsetHeight;
      },
      clickSelect() {
        if(this.optionsList.length > 0) return this.inputBlurHandle()
        this.$emit('getOption')
      },
      clickOption(info) {
        this.$emit("selectOptionItem", info)
      },
      inputBlurHandle() {
        this.$emit("selectBlurHandle")
      },
    },
    created() { },
    mounted() {
      this.getOptionsOffset();
      document.addEventListener("click", this.inputBlurHandle);
    },
    props: {
      value: {
        default: "",
      },
      placeholder: {
        type: String,
        default: "",
      },
      optionsList: {
        type: Array,
        default: () => [],
      },
    },
    watch: {
      value(val) {
        this.selectVal = val;
      },
      optionsList(newVal){
        this.optionsListArr = JSON.parse(JSON.stringify(newVal))
      }
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

  .select-com {
    height: 100%;
    min-height: 28px;
    border: 1px solid rgba(255, 255, 255, 0.15);
    background: rgba(0, 0, 0, 0.2);
    border-radius: 8px;
    color: rgba(255, 255, 255, 0.8);
    padding: 0 10px;
    cursor: pointer;
  }

  .select-active {
    height: 100%;
    border: 1px solid #32B9FF;
  }

  .placeholder-color {
    color: rgba(255, 255, 255, 0.3);
  }

  ul.options {
    position: absolute;
    left: 0;
    border: 1px solid rgba(255, 255, 255, 0.15);
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

  li:hover {
    background-color: rgba(90, 90, 90, 0.5);
  }

  li:last-child {
    border-bottom: none;
  }
</style>