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
    <el-dialog
        title="选择和滑动"
        :visible.sync="visible"
        append-to-body
        width="40%"
    >
      <div class="content" style="margin-top: 20px;">
<!--        <el-radio-group  v-model="selected" @change="onRadioChange" style="margin-left: auto">-->
<!--          <el-radio-button v-for="item in options" :key="item" :label="item">-->
<!--            {{ item }}-->
<!--          </el-radio-button>-->
<!--        </el-radio-group>-->

        <div class="number-container">
          <div
              v-for="(item, index) in options"
              :key="index"
              :class="['number-box', { selected: selected === item }]"
              @click="toggleSelection(index)"
          >
            {{ item }}
          </div>
        </div>

      </div>
      <div style="display: flex; padding: 30px 0">
        <el-slider class="slider-content" v-model="sliderValue" :min="sliderMin" :max="sliderMax"></el-slider>
        <div class="slider-container">
<!--          <div class="placeholder">-</div>-->
          <img class="placeholder" :src="require('@/assets/img/minus.png')" @click="sliderValue = Math.max(1, sliderValue-1)"/>
          <div class="value-box">{{ sliderValue }}</div>
          <img class="placeholder" :src="require('@/assets/img/plus.png')" @click="sliderValue++"/>
        </div>
      </div>


      <span class="footer">
          <el-button class="btn-cancel" @click.stop="handleCancel">取消</el-button>
          <el-button class="btn-confirm" @click.stop="handleConfirm">确定</el-button>
    </span>
<!--    </el-drawer>-->
    </el-dialog>
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
    toggleSelection(index) {
      if (this.selected === this.options[index]) {
        this.selected = null;
      } else {
        this.selected = this.options[index];
        this.updateSliderRange()
      }
    },
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


<style lang="less" scoped>
.footer{
  background: rgba(236, 239, 244, 1);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 6px 0;

  .btn-cancel{
    border: none;
    font-size: 20px;
    font-family: PingFangSC, PingFang SC;
    font-weight: 600;
    color: #FFFFFF;
    width: 112px;
    height: 52px;
    background: #374368;
    box-shadow: inset 0px 1px 1px 0px rgba(255, 255, 255, 0.2);
    border-radius: 8px;
  }
  .btn-confirm {
    border: none;
    font-size: 20px;
    font-family: PingFangSC, PingFang SC;
    font-weight: 600;
    color: #FFFFFF;
    width: 112px;
    height: 52px;
    background: #3373E8;
    border-radius: 8px;
  }
}
.number-container {
  display: flex;
  justify-content: space-between;
  flex-wrap: nowrap;
  margin: 10px 20px;
}

.number-box {
  padding: 10px;
  //background-color: #f0f0f0;
  border-radius: 4px;
  border: 1px solid rgba(196, 203, 215, 1);
  cursor: pointer;
  margin: 0 5px;
  width: 40px;
  text-align: center;
  font-weight: 600;
}

.number-box.selected {
  background-color: #007bff;
  color: #fff;
}


.slider-container {
  display: flex;
  align-items: center;
  margin-right: 20px;
}
.slider-content{
  width: 80%;
  margin: 5px 15px;
}
.placeholder {
  width: 45px;
  height: 45px;
  //background-color: #ccc;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  /* margin: 0 10px; */
  cursor: pointer;
}

.value-box {
  padding: 10px;
  //background-color: #f0f0f0;
  border-radius: 4px;
  border: 1px solid rgba(196, 203, 215, 1);
  cursor: pointer;
  margin: 0 5px;
  width: 40px;
  text-align: center;
  font-weight: 600;
  background-color: #007bff;
  color: #fff;
}


/deep/ .el-dialog__header {
  padding: 20px 20px 10px;
  background: #C4CBD7;
  text-align: left;
}

/deep/ .el-dialog__title {
  font-size: 18px;
  font-family: PingFangSC, PingFang SC;
  font-weight: 600;
  color: #1A1A21;
}
/deep/ .el-dialog__headerbtn {
  font-size: x-large;
  position: absolute;
  top: 20px;
  right: 20px;
  padding: 0;
  background: 0 0;
  border: none;
  outline: 0;
  cursor: pointer;
}

/deep/ .el-dialog__body {
  padding: 0;
  color: #606266;
  font-size: 20px;
  background-color: #FFF !important;
  word-break: break-all;
}
</style>
