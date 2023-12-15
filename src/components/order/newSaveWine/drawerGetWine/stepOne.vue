<template>
  <div class="step-one">
    <div class="custom-info">
      <div class="label">
        <span class="red">*</span>
        <span>客人信息</span>
      </div>
      <div class="value" layout="row" layout-align="center center">
        <div class="info-detail m-t-3" :layout="isRect ? 'row' : 'column'"
          :layout-align="isRect ? 'center start' : 'center center'">
          <div class="tab-info">
            <div class="tab" layout="row" layout-align="start center">
              <div class="tab-item m-r-3" :class="{ active: tabIndex == 2 }" @click="tabIndex = 2; focus = 0">手机号</div>
              <div class="tab-item m-r-3" :class="{ active: tabIndex == 1 }" @click="tabIndex = 1; focus = 0">服务码</div>

              <div class="tab-item" :class="{ active: tabIndex == 3 }" @click="tabIndex = 3; focus = 0">超级授权码</div>
            </div>
            <div class="tab-content m-t-6">
              <div v-if="tabIndex == 1" class="m-b-6">
                <div class="coll" layout="row" layout-align="start center">
                  <div class="label">服务码</div>
                  <div class="value">
                    <input v-model="authValidateVal" :class="{ focus: focus == 1 }" @click.stop="focus = 1"
                      @input="emitStepOneInfoHandle" placeholder="请输入服务码" />
                  </div>
                </div>
              </div>
              <div v-if="tabIndex == 2" class="m-b-6">
                <div class="coll" layout="row" layout-align="start center">
                  <div class="label">手机号</div>
                  <div class="value">
                    <input-select
                     :class="{ focus: focus == 2 }"
                      style="width:300px;"
                      :value="phoneNum"
                      placeholder="请输入手机号"
                      :optionsList="phoneList"
                      @selectInputHandle="inputPhone"
                      @selectOptionItem="changePhone"
                      @selectBlurHandle="selectBlurHandle"
                    ></input-select>
                  </div>
                </div>
                <div class="label color-red fs20 m-t-2">输入手机号后4位模糊查询</div>
              </div>
              <div v-if="tabIndex == 3" class="m-b-6">
                <div class="coll" layout="row" layout-align="start center">
                  <div class="label">手机号</div>
                  <div class="value">
                    <input-select
                     :class="{ focus: focus == 2 }"
                      style="width:300px;"
                      :value="phoneNum"
                      placeholder="请输入手机号"
                      :optionsList="phoneList"
                      @selectInputHandle="inputPhone"
                      @selectOptionItem="changePhone"
                      @selectBlurHandle="selectBlurHandle"
                    ></input-select>
                  </div>
                </div>
                <div class="coll" layout="row" layout-align="start center">
                  <div class="label">授权码</div>
                  <div class="value">
                    <input v-model="superValidate" :class="{ focus: focus == 4 }" @click.stop="focus = 4"
                      @input="emitStepOneInfoHandle" placeholder="请输入超级授权码" />
                  </div>
                </div>
              </div>
            </div>
          </div>

          <keyBoard @changeNum="changeNumHandle" />
        </div>
      </div>
    </div>
  </div>
</template>
 
<script>
import keyBoard from "@/components/common/newKeyBoard.vue";
import api_saveWine from "@/api/saveWine";
import inputSelect from "@/components/book/inputSelect";
export default {
  data() {
    return {
      isRect: true,  // 是否为横屏
      focus: 1,

      tabIndex: 1,
      authValidateVal: "", // 服务码
      superValidate: '',  // 超级授权码
      phoneNum: "", // 手机号
      validateVal: "", // 验证码
      phoneList: [], // 手机号列表, p          string     //PhoneNum 手机号， n          string     //Name 客户姓名
    };
  },
  methods: {
    async inputPhone(query){
      this.focus = 2;
      this.phoneNum = query;
      this.emitStepOneInfoHandle()
      // 判断query是4位长度的数字
      if(/^[0-9]{4}$/.test(query)) {
        try {
          const res = await api_saveWine.reqGetWineCustByPhone4({
            p: query
          })
          if(res.code == 1 && res.data.records) {
            console.log(res.data.records)
            this.phoneList = res.data.records.map(item => {
              return {
                code: item.p,
                name: item.n
              }
            })
          } else {
            this.$message.warning('手机号查询无结果')
          }
        }catch(e) {
          this.$message.warning('模糊查询失败')
        }
      }
      
    },
    changePhone(info){
      this.phoneList = []
      this.phoneNum = info.code
      this.emitStepOneInfoHandle()
    },
    selectBlurHandle(){
      this.phoneList = []
      this.focus = 2;
    },
    interValHandle() {
      const storageSecondCount = this.$sessionStorage.getItem("secondGetWineCount");  // 获取发送短信时的时间戳
      const now = +new Date()
      const oneMinute = +new Date('2023/05/25 12:01:00') - +new Date('2023/05/25 12:00:00')
      if (now - storageSecondCount < oneMinute) {
        // 倒计时为结束接着倒计时
        this.count = ((oneMinute - (now - storageSecondCount)) / (oneMinute / 60)).toFixed(0) * 1;
        this.loopSecond();
      } else {
        this.count = 60;
      }
    },

    blueHandle() {
      this.focus = 0;
    },

    changeNumHandle(value) {
      if (!this.focus) return;
      let count = "";
      if (this.focus == 1) count = "authValidateVal";
      else if (this.focus == 2) count = "phoneNum";
      else if (this.focus == 3) count = "validateVal";
      else if (this.focus == 4) count = "superValidate";
      switch (value) {
        case 10: // 清空
          this[count] = "";
          break;
        case 12: // 回退(
          this[count] =
            this[count].toString().slice(0, this[count].toString().length - 1) *
            1;
          break;
        default:
          this[count] = this[count].toString() + value * 1;
          break;
      }
      if(this.focus == 2) {
        this.inputPhone(this.phoneNum);
      }
      this.emitStepOneInfoHandle()
    },
    // 检测是否为横屏
    getRectVal() {
      const width = screen.availWidth
      const height = screen.availHeight
      this.isRect = width >= height
    },

    emitStepOneInfoHandle() {
      this.$emit("updateStepInfo", {
        ...JSON.parse(JSON.stringify(this.stepOneInfo)),
        tabIndex: this.tabIndex,
        authValidateVal: this.authValidateVal || '', // 服务码
        superValidate: this.superValidate || '', // 超级授权码
        phoneNum: this.phoneNum || '', // 手机号
        validateVal: this.validateVal || '', // 验证码
      });
    }
  },
  props: {
    stepOneInfo: {
      default: () => ({ orderList: [] })
    }
  },
  components: {
    keyBoard,
    inputSelect,
  },

  watch: {
    stepOneInfo: {
      handler(newVal) {
        this.getRectVal()
        this.tabIndex = newVal.tabIndex;
        this.validateVal = newVal.validateVal;
        this.phoneNum = newVal.phoneNum;
        this.authValidateVal = newVal.authValidateVal;
        this.superValidate = newVal.superValidate;
      },
      deep: true,
      immediate: true
    },
    tabIndex() {
      this.emitStepOneInfoHandle()
    }
  }
};
</script>
<style lang="less" scoped>
@import "../../../../style/saveWine/newTable.less";
</style>
<style scoped lang="less">
.step-one {
  padding: 20px;
  font-size: 24px;
  font-family: PingFangSC, PingFang SC;
  font-weight: 400;
  color: #1A1A21;

  .red {
    color: #ff2f64;
  }

  .table {
    .tbody {
      max-height: 20vh;
      overflow: auto;
    }
  }

  /deep/.el-input__inner {
    color: black; /* 文本颜色 */
    background-color: white; /* 背景颜色 */
    font-size: 20px;
  }

  .custom-info {
    >.value {
      height: calc(100vh - 200px);

      .info-detail {
        .tab-info {
          width: 500px;

          .tab {
            .tab-item {
              line-height: 44px;
              text-align: center;
              cursor: pointer;

              width: 120px;
              height: 44px;
              border-radius: 8px;
              border: 1px solid #40404E;
              font-size: 20px;
              font-family: PingFangSC, PingFang SC;
              font-weight: 400;
              color: #08080A;

              &.active {
                font-weight: 500;
                border: none;
                color: #FFFFFF;
                background: #3373E8;
                box-shadow: inset 0px 1px 1px 0px rgba(255, 255, 255, 0.5);
              }
            }
          }

          .tab-content {
            .coll {
              height: 50px;

              .label {
                width: 80px;
                font-size: 20px;
                font-family: PingFangSC, PingFang SC;
                font-weight: 400;
                color: #08080A;
              }

              .value {
                position: relative;
                flex-wrap: nowrap;
                flex-shrink: 0;
                width: 320px;
                margin-left: 10px;

                input {

                  width: 266px;
                  height: 44px;
                  background: #FAFAFC;
                  border-radius: 8px;
                  border: 1px solid #C4CBD7;
                  padding: 0 10px;
                  box-sizing: border-box;
                  margin-right: 10px;
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

                .focus {
                  order: 2px solid #3373E8;
                }
              }
            }
          }
        }
      }
    }
  }
}
</style>