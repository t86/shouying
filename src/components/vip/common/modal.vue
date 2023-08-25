<template>
  <div class="modal-com" v-if="show">
    <div class="modal-box">
      <img class="icon" :src="iconSrc" alt />
      <p class="context">{{modalText}}</p>
      <div class="bottom" layout="row" layout-align="center center">
        <button class="btn normal info" @click="$emit('showOrHideModal')">{{btnText[0]}}</button>
        <button v-if="btnText.length==3" class="btn normal primary" @click="$emit('centerBtnClick')">{{btnText[1]}}</button>
        <button class="btn normal primary" @click="$emit('submitBtnClick')">{{btnText[2] || btnText[1]}}</button>
      </div>
    </div>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      show: false,
      imgIcon: {
        successIcon: require("@/assets/vip-imgs/success.png"),
        warningIcon: require("@/assets/vip-imgs/warning.png")
      }
    };
  },
  methods: {
  },
  created() {},
  mounted() {},
  props: {
    showModal: {
      default: false
    },
    iconText: {
      default: "success"
    },
    modalText: {
      default: ""
    },
    btnText: {
      default: ['关闭', '确定']
    }
  },
  computed: {
    iconSrc() {
      return this.iconText == "success"
        ? this.imgIcon.successIcon
        : this.imgIcon.warningIcon;
    },

  },
  watch: {
    showModal: {
      handler(newVal) {
        this.show = newVal;
      },
      immediate: true
    }
  }
};
</script>

<style lang="less" scoped>
@import "../../../style/vip/vipBtn.less";
</style>
<style scoped lang="less">
.modal-com {
  width: 100vw;
  height: 100vh;
  position: fixed;
  left: 0;
  top: 0;
  background-color: rgba(0, 0, 0, 0.3);
  .modal-box {
    position: absolute;
    left: 50%;
    top: 50%;
    transform: translate(-50%, -50%);
    width: 480px;
    height: 284px;
    background: #bec5d5;
    box-shadow: 0px 12px 20px 0px rgba(0, 0, 0, 0.1);
    border-radius: 12px;
    display: grid;
    grid-template-rows: 1.8fr 1fr 80px;
    text-align: center;
    img.icon {
      display: block;
      margin: 50px auto 0;
      width: 50px;
    }
    p.context {
      font-size: 18px;
    }
    .bottom {
      background: #b3bbcd;
      border-radius: 0px 0px 8px 8px;
      .btn {
        margin: 0 10px;
      }
    }
  }
}
</style>