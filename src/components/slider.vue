<template>
  <el-dialog :visible.sync="visible" title="选择和滑动" width="40%">
      <el-radio-group v-model="selected" @change="onRadioChange">
        <el-radio-button v-for="item in options" :key="item" :label="item">
          {{ item }}
        </el-radio-button>
      </el-radio-group>

      <el-slider show-input v-model="sliderValue" :min="sliderMin" :max="sliderMax"></el-slider>

      <div slot="footer" class="dialog-footer">
        <el-button @click="handleCancel">取消</el-button>
        <el-button type="primary" @click="handleConfirm">确定</el-button>
      </div>

  </el-dialog>
</template>

<script>
export default {
  name: 'MyDialog',
  props: {
    visible: {
      type: Boolean,
      required: true
    },
    options: {
      type: Array,
      required: true
    }
  },
  data() {
    return {
      selected: null,
      sliderValue: 0,
      sliderMin: 0,
      sliderMax: 100
    };
  },
  watch: {
    visible(newVal) {
      if (newVal) {
        this.resetDialog();
      }
    }
  },
  methods: {
    resetDialog() {
      if (this.options.length > 0) {
        this.selected = this.options[0];
        this.sliderMin = 0;
        this.sliderMax = this.options[0];
        this.sliderValue = this.sliderMin; // 重置滑块值到新范围的最小值
      } else {
        this.selected = null;
        this.sliderValue = 0;
        this.sliderMin = 0;
        this.sliderMax = 100;
      }
    },
    onRadioChange() {
      const index = this.options.indexOf(this.selected);
      this.sliderMin = index === 0 ? 0 : this.options[index - 1] + 1;
      this.sliderMax = this.selected;
      this.sliderValue = this.sliderMin; // 重置滑块值到新范围的最小值
    },
    handleCancel() {
      this.$emit('update:visible', false);
      this.$emit('cancel');
    },
    handleConfirm() {
      this.$emit('update:visible', false);
      this.$emit('confirm', this.sliderValue);
    }
  }
};
</script>

<style scoped>
.dialog-footer {
  text-align: right;
}
</style>

<style>
/*.el-dialog__body {*/
/*  background-color: #aaa;*/
/*}*/
</style>