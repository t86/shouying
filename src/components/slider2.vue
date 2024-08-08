<template>
  <div>
<!--    <el-drawer-->
<!--        title="选择和滑动"-->
<!--        :visible.sync="visible"-->
<!--        :before-close="handleCancel"-->
<!--        append-to-body-->
<!--        direction="rtl"-->
<!--        size="50%"-->
<!--    >-->
      <div class="content" style="margin-top: 20px; display: flex">
        <el-radio-group  v-model="selected" @change="onRadioChange">
          <el-radio-button v-for="item in options" :key="item" :label="item">
            {{ item }}
          </el-radio-button>
        </el-radio-group>
        <div style="margin-left: 5px">
          <el-button type="info" @click.stop="handleCancel">取消</el-button>
          <el-button type="primary" @click.stop="handleConfirm">确定</el-button>
        </div>
      </div>
    <el-slider style="margin-left: 20px; margin-right: 20px" show-input v-model="sliderValue" :min="sliderMin" :max="sliderMax"></el-slider>
<!--    </el-drawer>-->
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
          this.sliderMax = 30;
        }
      },
      // updateSelected() {
      //   // 根据 current 值来找到对应的 option
      //   for (let i = 0; i < this.options.length; i++) {
      //     if (this.current <= this.options[i]) {
      //
      //       this.selected = this.options[i-1];
      //       break;
      //     }
      //   }
      // },
      updateSelected() {
        // 根据 current 值来找到对应的 option
        let selectedOption = this.options[0]; // 默认选择第一个选项
        for (let i = 0; i < this.options.length - 1; i++) {
          if (this.current >= this.options[i] && this.current < this.options[i + 1]) {
            selectedOption = this.options[i];
            break;
          } else if (this.current >= this.options[this.options.length - 1]) {
            selectedOption = this.options[this.options.length - 1];
          }
        }
        this.selected = selectedOption;
        console.log('Updated selected:', this.selected);
      },
      // updateSliderRange() {
      //   const index = this.options.indexOf(this.selected);
      //   this.sliderMin = index === 0 ? 0 : this.options[index - 1] + 1;
      //   this.sliderMax = this.selected;
      //   this.sliderValue = this.current >= this.sliderMin && this.current <= this.sliderMax ? this.current : this.sliderMax; // 确保滑块值在范围内
      // },
      updateSliderRange() {
        const index = this.options.indexOf(this.selected);
        this.sliderMin = this.selected;
        // this.sliderMax = index === this.options.length - 1 ? this.selected : this.options[index + 1];
        this.sliderMax = index === this.options.length - 1 ? 999 : this.options[index + 1];
        this.sliderValue = this.current >= this.sliderMin && this.current <= this.sliderMax ? this.current : this.sliderMin; // 确保滑块值在范围内
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
  mounted() {
    console.log('mount-------------------')
    console.log(this.current)
    this.resetDialog();
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
      console.log('show-------------------')
      if (newVal) {
        this.resetDialog();
      }
    }
  }
};
</script>

<style scoped lang="less">
//@import "../style/common/newElementDrawer.less";
//@import "../style/common/elementDrawerHeaderAndSession.less";
//@import "../style/common/newElementFormBtn.less";
</style>

<style lang="less" scoped>
///deep/ label {
//  width: 80px !important;
//  color: rgba(255, 255, 255, 0.8);
//}
///deep/ .el-radio-button__inner, .el-radio-group {
//  line-height: 1;
//  vertical-align: middle;
//  display: block;
//  //line-height: 1;
//  //vertical-align: middle;
//  //display: flex;
//  //justify-content: center;
//}
///deep/ .el-radio-button__inner {
//  margin-top: 10px;
//  white-space: nowrap;
//  background: #FFF;
//  border: 1px solid #DCDFE6;
//  font-weight: 500;
//  border-left: 0;
//  color: #606266;
//  -webkit-appearance: none;
//  text-align: center;
//  box-sizing: border-box;
//  outline: 0;
//  margin: 0;
//  position: relative;
//  cursor: pointer;
//  transition: all .3s cubic-bezier(.645,.045,.355,1);
//  padding: 12px 20px;
//  font-size: 20px;
//  border-radius: 0;
//}
//
///deep/ .el-input--small {
//  font-size: 20px;
//  top: 5px;
//}
//
///deep/ .el-input-number__decrease {
//  width: 40px;
//  height: 38px;
//  font-size: 30px;
//  font-weight: bold;
//  left: -20px;
//  border-radius: 4px 0 0 4px;
//  border-right: 1px solid #DCDFE6;
//}
//
///deep/ .el-input-number__increase {
//  width: 30px;
//  height: 38px;
//  font-size: 30px;
//  font-weight: bold;
//  right: -20px;
//  border-radius: 0 4px 4px 0;
//  border-left: 1px solid #DCDFE6;
//}
///deep/ .el-input__inner {
//  color: rgba(255, 255, 255, 0.8);
//  background: #409EFF;
//  border-radius: 10px;
//  border: 1px solid rgba(255, 255, 255, 0.15);
//  resize: none;
//  /* margin-top: 5px; */
//  //height: 40px;
//}
</style>
