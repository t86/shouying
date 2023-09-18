<template>
  <div>
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      append-to-body
      direction="rtl"
      size="50%"
    >
      <!-- 定制数量 -->
      <div class="require-count" v-if="showSelectedCount">
        <span>选择次数：</span>
        <img :src="selectedCount==1?imgSrc.subDisabled:imgSrc.sub" @click="changeCount('sub')" />
        <input type="number" min="1" v-model="selectedCount" @input="changeCount('input')" />
        <img
          :src="selectedCount>=maxCount?imgSrc.addDisabled:imgSrc.add"
          @click="changeCount('add')"
        />
      </div>
      <!-- 定制要求 -->
      <div class="m-b-10">
        <div class="require" v-for="(item,index) in requireList" :key="index">
          <div class="require-title">{{item.name}}</div>
          <div class="require-content" layout="row" layout-align="start center" flex-wrap="wrap">
            <div
              class="require-item"
              :class="{'active': item1.checked}"
              v-for="(item1,index1) in item.requireList"
              :key="index1"
              @click="changeRequire(item, item1)"
            >{{item1.name}}</div>
          </div>
        </div>
        <div class="textarea p-t-1" v-if="isNotAndroid">
          <div style="color:rgba(255,255,255,0.8);margin: 3px 0 6px 0px">其他要求</div>
          <textarea v-model="textareaText" placeholder="请输入自定义要求" maxlength="30"></textarea>
          <div class="tips">{{textareaText.length}} / 30</div>
        </div>
        <div class="white m-t-6 fs16" style="text-align:center" v-if="!showSelectedCount&&requireList.length == 0 && !isNotAndroid ">
          当前商品暂无可配置要求项
        </div>
      </div>
      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button v-if="(!(!showSelectedCount&&requireList.length == 0)) || isNotAndroid" type="primary" @click="onSubmit">确认</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import add from "@/assets/order-img/order_add.png";
import sub from "@/assets/order-img/sub.png";
import addDisabled from "@/assets/order-img/add-disabled.png";
import subDisabled from "@/assets/order-img/sub-disabled.png";

export default {
  data() {
    return {
      title: "加定制",
      show: false,
      textareaText: "",
      requireList: [],
      selectedCount: 1, // 可选单品的选中次数

      imgSrc: {
        add,
        sub,
        addDisabled,
        subDisabled
      }
    };
  },
  methods: {
    closeDrawerHandle() {
      this.$emit("showOrHideDrawer");
    },

    onCancelDrawer() {
      this.closeDrawerHandle();
    },

    changeRequire(item, item1) {
      if (item.mode_type == 1) {
        // 单选
        item.requireList.forEach(el => {
          if (el.id == item1.id) {
            item1.checked = !item1.checked;
          } else {
            el.checked = false;
          }
        });
      } else {
        // 多选
        item1.checked = !item1.checked;
      }
      this.$forceUpdate();
    },

    // 更改定制数量
    changeCount(type) {
      switch (type) {
        case "add":
          this.selectedCount = Math.min(this.selectedCount + 1, this.maxCount);
          break;
        case "sub":
          this.selectedCount = Math.max(this.selectedCount - 1, 1);
          break;
        case "input":
          this.selectedCount = Math.min(this.selectedCount, this.maxCount);
          this.selectedCount = Math.max(this.maxCount, 1);
          this.$forceUpdate();
          break;
      }
      this.$emit("updateRequireCount", this.selectedCount);
    },

    onSubmit() {
      if(!this.showSelectedCount && this.requireList.length == 0) return
      const resultRequireArr = this.requireList
        .map(item =>
          item.requireList
            .filter(items => items.checked)
            .map(items => items.name)
        )
        .flat();
      if (this.textareaText.length > 0)
        resultRequireArr.push(this.textareaText);

      this.$emit("updateRequireInfoArr", resultRequireArr);
      this.notCloseDrawer ? "" : this.closeDrawerHandle();
    }
  },
  mounted() {},
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    },
    productInfo: {
      default: () => ({})
    },
    requestInfoArr: {
      default: () => []
    },
    notCloseDrawer: {
      default: false // 点击提交后是否关闭drawer
    },
    maxCount: {
      default: 1
    },
    showSelectedCount:{
      default: false
    }
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.selectedCount = 1;
        this.$emit("updateRequireCount", this.selectedCount);
        // 加定制
        this.requireList = this.productInfo.requireInfo.map(item => ({
          ...item,
          requireList: item.requireList.map(items => ({
            ...items,
            checked: false
          }))
        }));

        this.textareaText = "";
        this.title = "加定制";

        if (this.requestInfoArr.length > 0) {
          // 修改定制
          let tempRequireInfoArr = []; // 用来判断是否有自定义要求
          this.requireList.forEach((el, index) => {
            el.requireList.forEach(ele => {
              ele.checked = this.requestInfoArr.indexOf(ele.name) > -1;
              if (ele.checked) tempRequireInfoArr.push(true);
            });
          });

          this.textareaText =
            tempRequireInfoArr.length === this.requestInfoArr.length
              ? ""
              : this.requestInfoArr[this.requestInfoArr.length - 1];
          this.title = "修改定制";
        }

        this.$forceUpdate();
      }
    }
  },
  computed: {
    isNotAndroid(){
      let termType = ''
      try {
        termType = atool.getTermType();
      } catch (error) {
        console.log('获取终端类型失败', error)
      }
      return termType != 'android'
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementFormBtn.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/common/scrollBar.less";
</style>

<style scoped lang="less">
// 定制数量
.require-count {
  padding: 30px 30px 10px;
  color: rgba(255, 255, 255, 0.8);
  img {
    vertical-align: middle;
    width: 26px;
    cursor: pointer;
  }

  input {
    color: rgba(255, 255, 255, 0.8);
    vertical-align: middle;
    width: 56px;
    height: 28px;
    padding: 0 10px;
    text-align: center;
    box-sizing: border-box;
    background: rgba(255, 255, 255, 0.08);
    border-radius: 24px;
    border: 1px solid rgba(255, 255, 255, 0.3);
  }
}
// 定制要求
.require {
  user-select: none;
  padding: 10px 30px;
  color: rgba(255, 255, 255, 0.8);
  &-title {
    font-size: 16px;
  }
  &-content {
    font-size: 15px;
    .require-item {
      margin: 10px 10px 0 0;
      padding: 4px 14px;
      border-radius: 30px;
      border: 1px solid rgba(255, 255, 255, 0.2);
      cursor: pointer;
      &.active {
        color: #5c9fff;
        background: #24406E;
        border-radius: 30px;
        border-color: transparent;
      }
    }
  }
}

.textarea {
  width: 90%;
  margin: 0 auto;
  color: rgba(255, 255, 255, 0.8);
  position: relative;
  textarea {
    width: 100%;
    height: 72px;
    resize: none;
    padding: 6px 10px;
    font-size: 14px;
    box-sizing: border-box;
    outline: none;
    &:focus{
      border-color: #5c9fff;
    }
  }
  .tips {
    font-size: 14px;
    position: absolute;
    right: 8px;
    bottom: 8px;
  }
}
</style>