<template>
  <div>
    <el-drawer
      title="异议单列表"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="80%"
    >
      <!-- tab -->
      <ul class="tab" layout="row" layout-align="start center">
        <li :class="{'active': activeId == 0}" @click="changeOrderList(0)">待退款</li>
        <li :class="{'active': activeId == 1}" @click="changeOrderList(1)">退款中</li>
        <li :class="{'active': activeId == 2}" @click="changeOrderList(2)">已退款</li>
        <li :class="{'active': activeId == 3}" @click="changeOrderList(3)">已失败</li>
      </ul>
      <!-- 订单表格 -->
      <div class="order-table">
        <div class="content" :class="{'short': activeId==2}">
          <div class="thead">
            <div class="tr">
              <div class="th">序号</div>
              <div class="th">单号</div>
              <div class="th">卡台名称</div>
              <div class="th">订位人</div>
              <div class="th">客人</div>
              <div class="th">客人手机号</div>
              <div class="th">支付方式</div>
              <div class="th">支付金额</div>
              <div class="th">时间</div>
              <div class="th">业务类型</div>
              <div class="th">业务详情</div>
              <div class="th">备注</div>
              <div
                class="th"
                :class="{'fixed': activeId<2}"
                v-if="activeId!=1 && activeId!= 2"
              >{{activeId==3 ? '失败原因':'操作'}}</div>
            </div>
          </div>
          <div class="tbody" ref="scrollDom">
            <div
              v-if="tableData.length==0"
              style="text-align:center;transform:translateY(40px)"
            >暂无数据</div>
            <div v-else ref="scrollItem">
              <div class="coll" v-for="(item,i) in tableData" :key="i">
                <div class="detail tr">
                  <div class="td">{{i+1}}</div>
                  <div class="td">{{item.id}}</div>
                  <div class="td">{{item.cardInfo ? item.cardInfo.name : ''}}</div>
                  <div class="td">{{item.personInfo ? item.personInfo.name : '自助'}}</div>
                  <div class="td">{{item.cn}}</div>
                  <div class="td">{{item.cp}}</div>
                  <div class="td">{{item.payInfo ? item.payInfo.name : ''}}</div>
                  <div class="td">{{item.ra}}</div>
                  <div class="td">{{item.c}}</div>
                  <div class="td">{{item.tn}}</div>
                  <div class="td">{{item.bi}}</div>
                  <div class="td">{{item.pr}}</div>
                  <div class="td" :class="{'fixed': activeId<1}" v-if="activeId!=1 && activeId!= 2">
                    <span v-if="activeId==3">{{item.rs}}</span>
                    <div
                      v-else
                      class="btn"
                      :class="{'gray': item.disabled}"
                      @click="toBackHandle(item)"
                    >{{activeId==0?'发起退款':'重试退款'}}</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="red-color fs18" style="margin:10px 20px">注意：退款操作后，请至少等待10秒后点击刷新按钮查看退款详情，具体时间取决于微信的退款处理时间</div>

      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button type="primary" @click="getBackOrderList(true)">刷新</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_money from "@/api/money";

import common_book from "@/utils/common/book";
import common_money from "@/utils/common/money";

const keyList = ["to_dos", "doings", "dones", "fails"];
export default {
  data() {
    return {
      timer: null,
      show: false,
      activeId: 0, // 0:待退款  1：退款中  2：已退款  3：已失败
      tableData: [],
      pageDataList: [] // 页面总数据
    };
  },
  methods: {
    // 获取退款订单列表
    async getBackOrderList(showTips) {
      try {
        const res = await api_money.reqGetBackOrderList();
        if (res.code === 1) {
          for (let key in res.data) {
            res.data[key] = res.data[key] || [];
            res.data[key].forEach(el => {
              el.cardInfo = common_book.getCardInfo(el.s);
              el.personInfo =
                el.se == 0 ? "" : common_book.getOrderPersonInfo(el.se);
              el.payInfo = common_money.getPayInfo(el.pc);
            });
          }

          this.pageDataList = { ...res.data };

          this.tableData = [...this.pageDataList[keyList[this.activeId]]];
          if (showTips) this.$message.success("刷新成功");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("退款订单列表获取失败", error);
      }
    },

    changeOrderList(activeId) {
      this.activeId = activeId;
      this.tableData = [...this.pageDataList[keyList[this.activeId]]];
    },

    toBackHandle(orderInfo) {
      if (orderInfo.disabled)
        return this.$message.warning("退款处理中，请稍后...");
      this.showConfirmHandle(
        this.activeId == 0 ? "发起退款" : "重试退款",
        "是否确认发起退款？",
        async () => {
          orderInfo.disabled = true;
          this.$forceUpdate();
          try {
            const res =
              this.activeId == 0
                ? await api_money.reqBackOrder({
                    id: orderInfo.id * 1 // int64   异议单Id
                  })
                : await api_money.reqTryBackSecond({
                    id: orderInfo.id * 1 //  int64   异议单Id
                  });
            res.code == 1
              ? this.$message.success("操作成功")
              : this.$message.warning(res.msg);
          } catch (error) {
            console.log("再次发起退款失败", error);
          }
        }
      );
    },

    // 操作确认框
    showConfirmHandle(title = "", content = "", callback) {
      this.$confirm(content, title, {
        distinguishCancelAndClose: true,
        confirmButtonText: "确定",
        cancelButtonText: "取消"
      })
        .then(() => {
          callback && callback();
        })
        .catch(e => "");
    },

    closeDrawerHandle() {
      this.$emit("showOrHideDrawer", false);
    },

    onCancelDrawer() {
      this.closeDrawerHandle();
    }
  },
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    }
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.getBackOrderList();
        if(this.timer) clearInterval(this.timer)
        this.timer = setInterval(() => {
          this.getBackOrderList()
        }, 3000);
      } else {
        clearInterval(this.timer)
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/common/elementFormBtn.less";
@import "../../../style/common/scrollBar.less";
@import "../../../style/money/drawerNeedBackOrderList.less";
</style>