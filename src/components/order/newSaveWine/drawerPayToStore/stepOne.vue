<template>
  <div class="step-one">
    <div class="m-b-6">
      <div class="coll" layout="row" layout-align="center center">
        <div class="label">充公日期</div>
        <div class="value">
          <el-date-picker v-model="dateVal" style="width:268px;height:36px" type="date" format="yyyy-MM-dd"
            value-format="yyyy-MM-dd" placeholder="选择日期">
          </el-date-picker>
        </div>
      </div>
      <div class="coll" layout="row" layout-align="center center">
        <div class="label">订位人</div>
        <div class="value">
          <inputSelect style="width:268px;" :value="empName" placeholder="请输入姓名或工号" :optionsList="empOption"
            @selectInputHandle="inputSealName" @selectOptionItem="changeSealName" @selectBlurHandle="selectBlurHandle">
          </inputSelect>
        </div>
      </div>
    </div>
    <keyBoard @changeNum="changeNumHandle" />
  </div>
</template>
 
<script>
import api_vip from "@/api/vip";
import inputSelect from "@/components/book/newInputSelect";
import keyBoard from "@/components/common/newKeyBoard.vue";
export default {
  data() {
    return {
      dateVal: '',
      empName: '',
      empId: '',
      empOption: []
    };
  },
  methods: {
    changeNumHandle(value) {
      let count = this.empName
      switch (value) {
        case 10: // 清空
          count = "";
          break;
        case 12: // 回退(
          if (isNaN(count * 1)) {
            count = "";
          } else {
            count =
              count.toString().slice(0, count.toString().length - 1) *
              1;
          }
          break;
        default:
          count = count.toString() + value * 1;
          break;
      }
      this.inputSealName(count)
      this.emitStepOneInfoHandle()
    },
    emitStepOneInfoHandle() {
      this.$emit("updateStepInfo", {
        empName: this.empName,
        empId: this.empId,
        dateVal: this.dateVal
      });
    },
    /*
     *订位人
     */
    // 获取模糊查询订位人的相关信息
    inputSealName(query) {
      this.empName = query;
      const sealInfoArr = this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo || [];
      const results = query
        ? sealInfoArr.filter(
          el =>
            el.code.toString().includes(query) ||
            el.name.toString().includes(query) ||
            el.namePy.toString().includes(query.toLowerCase())
        )
        : sealInfoArr;
      this.empOption = results;
    },
    // 选择订位人的信息
    changeSealName(info) {
      this.empName = info.name;
      this.empId = info.id
      this.empOption = [];
      this.emitStepOneInfoHandle()
    },
    selectBlurHandle() {
      this.empOption = [];
    },
  },
  props: {
    stepOneInfo: {
      default: () => ({})
    }
  },
  components: {
    inputSelect,
    keyBoard
  },
  watch: {
    stepOneInfo: {
      handler(newVal) {
        this.dateVal = newVal.dateVal
        this.empId = newVal.empId
        this.empName = newVal.empName
      },
      deep: true,
      immediate: true
    },
  }
};
</script>
<style lang="less" scoped>
@import "../../../../style/saveWine/newTable.less";
</style>
<style scoped lang="less">
.step-one {
  padding: 20px;

  .coll {
    height: 50px;
    transform: translateX(-6px);

    .label {
      font-size: 20px;
      font-family: PingFangSC, PingFang SC;
      font-weight: 400;
      color: #08080A;
      width: 80px;
      text-align: right;
    }

    .value {
      margin-left: 6px;
      position: relative;
      flex-wrap: nowrap;
      flex-shrink: 0;
      width: 320px;
    }
  }

}


/deep/.select-com,
/deep/.options li {
  font-size: 14px;
  height: 36px;
  line-height: 36px;
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
</style>
<style>
.el-icon-date:before {
  color: rgba(50, 185, 255, 1);
  transform: translateY(-2px);
}

.el-picker-panel {
  background-color: #5d6e99 !important;
}
</style>