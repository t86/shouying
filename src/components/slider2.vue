<template>
  <div>
    <el-drawer
        title="选择和滑动"
        :visible.sync="visible"
        :before-close="handleCancel"
        append-to-body
        direction="rtl"
        size="80%"
    >
      <div class="content">

        <el-radio-group style="margin-top: 100px" v-model="selected" @change="onRadioChange">
          <el-radio-button v-for="item in options" :key="item" :label="item">
            {{ item }}
          </el-radio-button>
        </el-radio-group>
        <el-slider style="margin: 150px 30px" show-input v-model="sliderValue" :min="sliderMin" :max="sliderMax"></el-slider>
        <div
            class="form-btn"
            layout="row"
            layout-align="center center">
          <el-button type="info" @click.stop="handleCancel">取消</el-button>
          <el-button type="primary" @click.stop="handleConfirm">确定</el-button>
        </div>
      </div>
    </el-drawer>
  </div>
</template>

<script>

export default {
  data() {
    return {
      selected: null,
      sliderValue: 0,
      sliderMin: 0,
      sliderMax: 100
    };
  },
  methods: {
      resetDialog() {
        if (this.options.length > 0) {
          this.updateSelected();
          this.updateSliderRange();
        } else {
          this.selected = null;
          this.sliderValue = 0;
          this.sliderMin = 0;
          this.sliderMax = 100;
        }
      },
      updateSelected() {
        // 根据 current 值来找到对应的 option
        for (let i = 0; i < this.options.length; i++) {
          if (this.current <= this.options[i]) {
            this.selected = this.options[i];
            break;
          }
        }
      },
      updateSliderRange() {
        const index = this.options.indexOf(this.selected);
        this.sliderMin = index === 0 ? 0 : this.options[index - 1] + 1;
        this.sliderMax = this.selected;
        this.sliderValue = this.current >= this.sliderMin && this.current <= this.sliderMax ? this.current : this.sliderMax; // 确保滑块值在范围内
      },
      onRadioChange() {
        this.updateSliderRange();
      },
      handleCancel() {
        this.$emit('update:visible', false);
        this.$emit('cancel');
      },
      handleConfirm() {
        this.$emit('update:visible', false);
        this.$emit('confirm', this.sliderValue);
      }
  },
  props: {
    visible: {
      type: Boolean,
      required: true
    },
    options: {
      type: Array,
      required: true
    },
    current: {
      type: Number,
      required: true
    }
  },
  watch: {
    visible(newVal) {
      if (newVal) {
        this.resetDialog();
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../style/common/newElementDrawer.less";
@import "../style/common/elementDrawerHeaderAndSession.less";
@import "../style/common/newElementFormBtn.less";
</style>

<style lang="less" scoped>
</style>
