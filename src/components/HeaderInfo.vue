<template>
  <div class="header-content">
    <div class="open-time">
      <span>开台时间：</span>
      <span>{{ openTime }}</span>
    </div>
    <div class="content-right">
      <div class="right-info">
        <div class="card-name-title" ref="cardNameTitle">
          <span :style="{ fontSize: titleFontSize }">{{ cardInfo.name }}</span>
          <span :style="{ fontSize: titleFontSize1 }">
            {{
              empInfoFilter($store.state.orderInfo.currentCardInfo.salesEmpId)
            }}
          </span>
        </div>
        <div class="card-name-seat" v-if="cardInfo.chgSeatInfo">
          <p :style="{ fontSize: seatFontSize }">{{ cardInfo.chgSeatInfo }}</p>
        </div>

      </div>
      <div class="right-time">
        <p>
          {{ authInfo.month }}-{{ authInfo.day }} {{ authInfo.hour }}:{{
            authInfo.minute
          }}
        </p>
        <p>
          {{ authTips }}:{{ authInfo.name }}
        </p>
      </div>
    </div>
  </div>
</template>
  
<script>
import common_book from "@/utils/common/book";
export default {
  name: 'HeaderInfo',
  data () {
    return {
      openTime: "",
      cardInfo: {},
      titleFontSize: '32px', // 初始字体大小
      titleFontSize1: '24px',
      seatFontSize: '18px',
      authInfo: {
        month: "00",
        day: "00",
        hour: "00",
        minute: "00",
        name: "",
      },
    }
  },
  methods: {
    adjustFontSize () {
      const windowWidth = window.innerWidth;
      const titleElement = this.$refs.cardNameTitle;
      const titleWidth = titleElement.clientWidth;
      if (windowWidth > 1300) {
        this.titleFontSize = titleWidth > 350 ? '26px' : '30px';
        this.titleFontSize1 = titleWidth > 350 ? '20px' : '24px';
        this.seatFontSize = titleWidth > 350 ? '14px' : '18px';

      } else {
        let s = parseInt(windowWidth / 60);
        let s1 = parseInt(windowWidth / 80);
        let f = parseInt(windowWidth / 90);
        this.titleFontSize = `${s}px`
        this.titleFontSize1 = `${s1}px`
        this.seatFontSize = `${f}px`

      }
    },
    getOpenTime () {
      let cardInfo = this.$store.state.orderInfo.currentCardInfo;
      if (cardInfo && cardInfo.openTime) {
        let h = parseInt(cardInfo.openTime.substring(8, 10)); // 时
        let s = parseInt(cardInfo.openTime.substring(10, 12)); // 分
        this.openTime = `${h}:${s}`
      }
    },
    empInfoFilter (empId) {
      empId = this.$route.path.startsWith("/payOrder") ? this.empId : empId;
      const empInfo = common_book.getOrderPersonInfo(empId) || { name: "散客" };
      const groupInfoName = common_book.getDepartmentName(empId) || "";
      return (this.cardInfo.name ? "/" : "") + (groupInfoName ? groupInfoName + "/" : "") + empInfo.name;
    },
    getAuthInfo () {
      const date = new Date();
      this.authInfo = {
        month: (date.getMonth() + 1).toString().padStart(2, 0),
        day: date.getDate().toString().padStart(2, 0),
        hour: date.getHours().toString().padStart(2, 0),
        minute: date.getMinutes().toString().padStart(2, 0),
        name: this.$store.state.userInfo.name,
      };
    },
  },
  mounted () {
    this.cardInfo = this.$store.state.orderInfo.currentCardInfo;
    this.getAuthInfo();
    this.getOpenTime();
    // this.adjustFontSize(); // 在组件加载后调整一次字体大小
    // window.addEventListener('resize', this.adjustFontSize); // 在窗口大小改变时再次调整字体大小
  },
  computed: {
    authTips() {
      return this.$route.path.startsWith("/orderMeal") ? "点单人" : "收银员";
    },
  },
  beforeDestroy () {
    // window.removeEventListener('resize', this.adjustFontSize); // 在组件销毁前移除事件监听器
  }

};
</script>
  
<style scoped lang="less">
.header-content {
  width: 100vw;
  height: 56px;
  background: #dce1ea;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 12px;
  box-sizing: border-box;

  .open-time {
    display: flex;
    align-items: center;

    span {
      font-size: 18px;
      font-family: PingFangSC, PingFang SC;
      font-weight: 400;
      color: #1a1a21;

      &:last-child {
        font-size: 24px;
        font-weight: 600;
      }
    }
  }

  .content-right {
    display: flex;
    align-items: center;

    .right-info {
      display: flex;
      flex-direction: column;
      align-items: center;

      .card-name-title {
        display: flex;
        align-items: center;
        color: #1a1a21;
        font-weight: 600;
        font-family: PingFangSC, PingFang SC;
      }

      .card-name-seat {
        font-family: PingFangSC, PingFang SC;
        font-weight: 600;
        color: #1a1a21;
      }
    }

    .right-time {
      display: flex;
      flex-direction: column;
      align-items: center;
      margin-left: 34px;
      font-size: 18px;
      font-family: PingFangSC, PingFang SC;
      font-weight: 400;
      color: #08080a;
    }
  }
}
</style>