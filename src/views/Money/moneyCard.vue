<template>
  <div class="card-box">
    <div class="contain" ref="containRef">
      <div class="contain-content" ref="containContentRef">
        <div class="contain-top">
          <!-- tab -->
          <div class="tab" layout="row" layout-align="start center">
            <div
              class="tab-item"
              :class="{ active: item.id === tab.activeIndex }"
              v-for="(item, index) in tab.tabList"
              :key="index"
              @click="changeTab(index, item.id)"
            >
              <span>{{ item.name }}</span>
              <div
                class="anotherInfo"
                v-if="item.id === 999 && tab.showAnotherInfo"
              >
                <div
                  class="another-item"
                  :class="{ active: items.id === tab.anotherInfoActiveId }"
                  v-for="(items, i) in tab.anotherInfo"
                  :key="i"
                  @click.stop="changeTab('9999', items.id)"
                >
                  <span>{{ items.name }}</span>
                </div>
              </div>
            </div>
          </div>
          <!-- 搜索框 -->
          <div class="search" v-if="tab.tabList.length > 0">
            <input
              type="text"
              v-model="keyWord"
              @input="inputSearchHandle"
              ref="searchInputRef"
              placeholder="卡台名称/客人姓名/手机尾号后四位"
            />
          </div>
        </div>
        <!-- 卡台列表 -->
        <div class="content">
          <div
            v-if="card.cardList.length > 0"
            class="center-type"
            :style="'width:' + card.centerTypeWidth + 'px'"
            layout="row"
            layout-align="start center"
          >
            <div
              class="card-item"
              v-for="(item, index) in card.cardList"
              :key="index"
              :class="[
                'bgc' + Number(item.bizStatus),
                { notPay: item.bizStatus == 5 },
                { otherPay: item.bizStatus == 6 },
              ]"
              @click.stop="cardClickHandle(item, index)"
              @contextmenu.prevent.stop="rightClickHandle"
            >
              <p layout="row" layout-align="space-between center">
                <span class="area-name">{{ item.regionId | getAreaName }}</span>
                <span layout="row" layout-align="space-between center">
                  <span class="pay-tips" v-if="item.settle_mode == 2">后</span>
                  <span
                    class="up-max-time m-r-1 notify"
                    v-if="item.pay_notify == 1"
                    >超</span
                  >
                  <span>
                    <span v-if="item.mark" class="mark">{{ item.mark }}</span>
                    <span>{{
                      item.openTime
                        ? "(" + item.openTime + ")"
                        : "" | filterTime
                    }}</span>
                  </span>
                </span>
              </p>

              <h3 class="card-name" layout="row" layout-align="start center">
                <div
                  ref="cardRef"
                  style="white-space: nowrap; transform-origin: left center"
                  :style="{fontSize: fontSize(item, index) + 'px'}"
                >
                  {{ item.name }}
                </div>
              </h3>

              <!-- 点单金额 -->
              <p
                layout="row"
                v-if="
                  item.bizStatus != 1 &&
                  item.bizStatus != 2 &&
                  item.bizStatus != 8 &&
                  item.bizStatus != 4
                "
                layout-align="start center"
              >
                <span style="width: 68px">点：</span>
                <span
                  class="one-txt-cut"
                  style="display: inline-block; width: calc(100% - 34px)"
                  >¥{{ Number(item.orderAmt).toFixed(2) }}</span
                >
              </p>
              <p v-else style="height: 16px"></p>

              <!-- 已付 -->
              <p
                layout="row"
                v-if="
                  item.bizStatus != 1 &&
                  item.bizStatus != 2 &&
                  item.bizStatus != 8 &&
                  item.bizStatus != 4
                "
                layout-align="start center"
              >
                <span style="width: 68px">已付：</span>
                <span
                  class="one-txt-cut"
                  style="display: inline-block; width: calc(100% - 34px)"
                  >¥{{ Number(item.payedAmt).toFixed(2) }}</span
                >
              </p>
              <p v-else style="height: 16px"></p>

              <!-- 未付 -->
              <p
                layout="row"
                v-if="
                  item.bizStatus != 1 &&
                  item.bizStatus != 2 &&
                  item.bizStatus != 8 &&
                  item.bizStatus != 4
                "
                layout-align="start center"
              >
                <span style="width: 68px">未付：</span>
                <span
                  class="one-txt-cut"
                  style="display: inline-block; width: calc(100% - 34px)"
                  >¥{{
                    Number(item.orderAmt - item.payedAmt || 0).toFixed(2)
                  }}</span
                >
              </p>
              <p v-else style="height: 16px"></p>

              <p
                layout="row"
                layout-align="space-between center"
                style="margin-top: 4px"
              >
                <!-- tips -->
                <span layout="row" layout-align="start center">
                  <span
                    class="one-txt-cut"
                    v-if="item.bizStatus != 1 && item.bizStatus != 2"
                    style="display: inline-block; width: 100px"
                  >
                    {{ item.salesEmpId | getDepartmentName }}
                    {{ item.salesEmpId | getOrderPersonName }}
                  </span>
                  <span
                    class="card-tips"
                    :class="{ green: items !== '锁', yellow: items === '锁' }"
                    v-for="(items, i) in item.tipsArr"
                    :key="i"
                    >{{ items }}</span
                  >
                </span>
                <!-- 翻台数 -->
                <span>
                  <span v-if="item.turnoverCnt > 0"
                    >翻{{ item.turnoverCnt }}</span
                  >
                </span>
              </p>
              <!-- 选项操作箭头 -->
              <img
                v-if="item.showOption && item.isLeftArrow"
                :src="imgSrc.sanJiao"
                class="sanjiao left"
              />
              <img
                v-if="item.showOption && !item.isLeftArrow"
                :src="imgSrc.sanJiao"
                class="sanjiao right"
              />
              <!-- 卡台内部操作选项 -->
              <div
                class="card-options"
                v-if="item.showOption"
                :style="{
                  top: card.optionsPosition.top,
                  bottom: card.optionsPosition.bottom,
                  left: card.optionsPosition.left,
                  right: card.optionsPosition.right,
                  transform: card.optionsPosition.transform,
                }"
                ref="cardOptions"
              >
                <div class="options-item" @click.stop="reserveCard(item)">
                  <div class="options-item-contain">
                    <img :src="imgSrc.orderBack" alt />
                    <span>复台</span>
                  </div>
                </div>
                <div
                  class="options-item"
                  @click.stop="goPayOrderPageHandle(item)"
                >
                  <div class="options-item-contain">
                    <img
                      :src="
                        require('@/assets/card-imgs/cardOptions/chakankataixiangqing.png')
                      "
                      alt
                    />
                    <span>查看卡台记录</span>
                  </div>
                </div>
                <div class="close">
                  <i class="el-icon-close fs14"></i>
                  关闭
                </div>
              </div>
            </div>
          </div>
          <!-- 无数据 -->
          <div v-else class="no-data">
            <img :src="imgSrc.noCardInfo" alt />
            <p>暂无卡台数据</p>
          </div>
        </div>
        <!-- 卡台图例tab -->
        <div class="legend" layout="row" layout-align="space-between center">
          <!-- 卡台状态图例 -->
          <div
            class="legend-list"
            layout="row"
            layout-align="space-around center"
          >
            <!-- 过滤掉锁台 -->
            <div
              class="legend-list-item"
              v-for="(item, index) in legendList"
              :key="item.id"
            >
              <span
                class="btn"
                v-if="item.id != 20"
                :class="{ active: legendActive === item.id }"
              >
                <div
                  class="img-contain"
                  :class="[item.id == 20 ? '' : 'bgc' + (index + 2)]"
                >
                  <img :src="item.allRight" alt />
                </div>
              </span>
              <span
                class="btn"
                style="transform: translateY(26px)"
                v-else
                :class="{ active: legendActive === item.id }"
              >
                <div
                  class="img-contain"
                  :class="[item.id == 20 ? '' : 'bgc' + (index + 2)]"
                >
                  <span style="color: #fff; line-height: 20px">{{
                    cardStatusNoInfo[20] || 0
                  }}</span>
                </div>
              </span>
              <p v-if="item.id != 20">
                <span style="margin-right: 2px">{{ item.name }}</span
                ><span>{{
                  cardStatusNoInfo[item.id == 4 ? 10 : item.id] || 0
                }}</span>
              </p>
              <p v-else style="transform: translateY(-28px)">
                <span style="margin-right: 2px">{{ item.name }}</span>
              </p>
            </div>
            <div
              class="legend-list-item reload-btn"
              :class="{ pressdown: arrowStatus === 'reload' }"
              @mousedown="keyDownHandle('reload')"
              @touchstart="keyDownHandle('reload')"
              @mouseup="keyDownHandle"
            >
              <img :src="imgSrc.reload" alt />
              <p>刷新</p>
            </div>
            <!-- 会员系统 -->
            <div
              class="legend-list-item vip-item"
              @click.stop="legendOptionHandle('vip')"
            >
              <img :src="require('../../assets/money-img/vip-logo.png')" alt />
              <p>会员系统</p>
            </div>
            <!-- 商户号信息 -->
            <div
              class="legend-list-item merchant-item"
              @click.stop="showOrHideMerchantInfoDrawerHandle"
            >
              <!-- <img :src="require('../../assets/money-img/vip-logo.png')" alt /> -->
              <p class="fs16">{{ merchantAllAmt }}</p>
            </div>
          </div>
          <!-- 操作面板 -->
          <div
            class="dosomething"
            layout="row"
            layout-align="space-between center"
          >
            <div
              class="dosomething-item arrow-item"
              layout="row"
              layout-align="space-between center"
            >
              <div
                class="arrow arr-left"
                :class="{ pressdown: arrowStatus === 'down' }"
                @mousedown="keyDownHandle('down')"
                @touchstart="keyDownHandle('down')"
                @mouseup="keyDownHandle"
              >
                <img :src="imgSrc.arrowBottom" alt />
              </div>
              <div
                class="arrow arr-right"
                :class="{ pressdown: arrowStatus === 'up' }"
                @mousedown="keyDownHandle('up')"
                @touchstart="keyDownHandle('up')"
                @mouseup="keyDownHandle"
              >
                <img :src="imgSrc.arrowBottom" alt />
              </div>
            </div>

            <!-- 退款列表 -->
            <div
              class="dosomething-item back-list"
              @click.stop="legendOptionHandle('needBackOrder')"
            >
              <img :src="imgSrc.backList" alt />
              <p>异议单列表</p>
              <span
                class="count"
                v-if="
                  this.$store.state.cardPageInfo.resResultDataObj
                    .needBackOrderListCount &&
                  this.$store.state.cardPageInfo.resResultDataObj
                    .needBackOrderListCount.length > 0 &&
                  this.$store.state.cardPageInfo.resResultDataObj
                    .needBackOrderListCount[0]['cnt'] > 0
                "
                >{{
                  this.$store.state.cardPageInfo.resResultDataObj
                    .needBackOrderListCount[0]["cnt"]
                }}</span
              >
            </div>

            <!-- 更多功能 -->
            <div
              class="dosomething-item more-effect"
              @click.stop="legendOptionHandle('more')"
            >
              <img :src="imgSrc.more" alt />
              <p>更多功能</p>
              <div class="option more" v-if="legendOptions.showMoreFunc">
                <div class="option-item" @click="showOrHideStopClassDrawer()">
                  <img :src="require('@/assets/money-img/stopClass.png')" alt />
                  <span>班结表</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideDayReportHandle()"
                >
                  <img
                    :src="require('@/assets/money-img/day-report.png')"
                    alt
                  />
                  <span>售出日报表</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideYHCountDrawerHandle()"
                >
                  <img :src="require('@/assets/money-img/YH-count.png')" alt />
                  <span>查询优惠额度</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideOnlineTotalHandle()"
                >
                  <img
                    :src="require('@/assets/money-img/online-pay-total.png')"
                    alt
                  />
                  <span>线上支付汇总</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideOnlinePayDetailHandle()"
                >
                  <img
                    :src="require('@/assets/money-img/online-pay-detail.png')"
                    alt
                  />
                  <span>线上支付记录</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideKpiReportHandle()"
                >
                  <img
                    :src="require('@/assets/money-img/kpi-report.png')"
                    alt
                  />
                  <span>业绩日报表</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideTurnOverDrawerHandle()"
                >
                  <img :src="require('@/assets/card-imgs/turn-over.png')" alt />
                  <span>转台记录</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideOnlineBookingDrawer()"
                >
                  <img
                    :src="require('@/assets/money-img/online-booking-icon.png')"
                    alt
                  />
                  <span>线上预定记录</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideYHDetailDrawer()"
                >
                  <img
                    :src="require('@/assets/money-img/yh-detail-icon.png')"
                    alt
                  />
                  <span>优惠明细表</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideTYDetailDrawer()"
                >
                  <img
                    :src="require('@/assets/money-img/ty-detail-icon.png')"
                    alt
                  />
                  <span>鸡尾酒明细表</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideTYHZDrawer()"
                >
                  <img
                    :src="require('@/assets/money-img/ty-detail-icon.png')"
                    alt
                  />
                  <span>鸡尾酒汇总表</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideGZDetailDrawer()"
                >
                  <img
                    :src="require('@/assets/money-img/gz-detail-icon.png')"
                    alt
                  />
                  <span>挂账账户</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideTurnOverDetailHandle()"
                >
                  <img
                    :src="require('@/assets/money-img/turn-over-icon.png')"
                    alt
                  />
                  <span>翻台记录</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideOrderDetailDrawer()"
                >
                  <img
                    :src="require('@/assets/money-img/order-icon.png')"
                    alt
                  />
                  <span>点单记录</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideNotTYOrXFDrawer()"
                >
                  <img
                    :src="require('@/assets/money-img/order-icon.png')"
                    alt
                  />
                  <span style="width: 100px; line-height: 20px"
                    >非鸡尾酒类补交报表</span
                  >
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideUpdateEmpDrawer()"
                >
                  <img
                    :src="require('@/assets/money-img/update-book-icon.png')"
                    alt
                  />
                  <span>修改订位人记录</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideOutSomethingHandle(true)"
                >
                  <img :src="require('@/assets/money-img/guqing.png')" alt />
                  <span>估清商品</span>
                </div>
                <div class="option-item line" @click="showOrHideProfitHandle()">
                  <img :src="require('@/assets/money-img/profit.png')" alt />
                  <span>盘盈盘亏</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideMerchantDrawerHandle()"
                >
                  <img :src="require('@/assets/money-img/merchant.png')" alt />
                  <span>商户号管理</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideMinDetailDrawerHandle()"
                >
                  <img
                    :src="require('@/assets/money-img/ty-detail-icon.png')"
                    alt
                  />
                  <span>低消进度统计表</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideXCDetailDrawerHandle()"
                >
                  <img
                    :src="require('@/assets/money-img/yh-detail-icon.png')"
                    alt
                  />
                  <span>现抽明细表</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideXCAllInfoDrawerHandle()"
                >
                  <img
                    :src="require('@/assets/money-img/yh-detail-icon.png')"
                    alt
                  />
                  <span>现抽汇总表</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideQDAllInfoDrawerHandle()"
                >
                  <img
                    :src="require('@/assets/money-img/yh-detail-icon.png')"
                    alt
                  />
                  <span>非主营分类渠道</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideCatQDAllInfoDrawerHandle()"
                >
                  <img           
                    :src="require('@/assets/money-img/yh-detail-icon.png')"
                    alt />
                  <span>分类渠道汇总表</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideXSDetailDrawerHandle()"
                >
                  <img
                    :src="require('@/assets/money-img/yh-detail-icon.png')"
                    alt
                  />
                  <span>部门销售明细表</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideXSAllInfoDrawerHandle()"
                >
                  <img
                    :src="require('@/assets/money-img/yh-detail-icon.png')"
                    alt
                  />
                  <span>部门销售汇总表</span>
                </div>
                <div
                  class="option-item line"
                  @click="showOrHideSetCountDrawerHandle()"
                >
                  <img
                    :src="require('@/assets/money-img/yh-detail-icon.png')"
                    alt
                  />
                  <span>套餐统计表</span>
                </div>
                <div
                  class="option-item line"
                  @click.stop="endStoreHandle('stop')"
                >
                  <img :src="imgSrc.updatepwd" alt />
                  <span>结束营业日</span>
                </div>
                <div
                  class="option-item line"
                  @click.stop="endStoreHandle('stopAuto')"
                >
                  <img :src="imgSrc.loginOut" alt />
                  <span>自动结束营业日</span>
                </div>

              </div>

              <img
                class="sj"
                v-if="legendOptions.showMoreFunc"
                :src="imgSrc.sanJiao"
                alt
              />
            </div>

            <!-- 账号密码相关 -->
            <li
              class="dosomething-item mine"
              @click.stop="legendOptionHandle('pwd')"
            >
              <img
                :src="imgSrc.arrowTop"
                :class="{ rotate: legendOptions.showUpdatePwd }"
                alt
              />
              <p>{{ authName }}</p>
              <!-- 操作选项 -->
              <div class="option" v-if="legendOptions.showUpdatePwd">
                <div
                  class="option-item"
                  @click.stop="legendOptionHandle('updatePwd')"
                >
                  <img :src="imgSrc.updatepwd" alt />
                  <span>修改密码</span>
                </div>
                <div
                  class="option-item authPwd"
                  @click.stop="legendOptionHandle('authPwd')"
                >
                  <img :src="imgSrc.authPwd" alt />
                  <span>授权密码</span>
                </div>
                <div
                  class="option-item logout"
                  @click.stop="legendOptionHandle('logout')"
                >
                  <img :src="imgSrc.loginOut" alt />
                  <span>退出登录</span>
                </div>
                <img :src="imgSrc.sanJiao" alt />
              </div>
            </li>
          </div>
        </div>
      </div>
    </div>

    <!-- 结束营业日 -->
    <drawerStopStore
      ref="drawerStopStore"
      :showDrawer="endStore.showDrawer"
      :status="endStore.status"
      @showOrHideEndStoreDrawer="showOrHideEndStoreDrawer"
      @logoutHandle="legendOptionHandle"
    />
    <!-- 班结表 -->
    <drawerStopClass
      :showDrawer="stopClass.showDrawer"
      @showOrHideStopClassDrawer="showOrHideStopClassDrawer"
    />

    <!--异议单列表 -->
    <drawerNeedBackOrderList
      ref="drawerNeedBackOrderList"
      :showDrawer="legendOptions.showNeedBackOrderList"
      :status="endStore.status"
      @showOrHideDrawer="showOrHideNeedBackOrderListDrawer"
    />

    <!-- 修改密码 -->
    <updatePassword
      ref="updatePassword"
      :showDrawer="legendOptions.updatePwdModel"
      @submitHandle="submitUpdatePwdHandle"
      @cancelUpdatePwdHandle="cancelUpdatePwdHandle"
    />

    <!-- 授权密码 -->
    <updateAuthPassword
      ref="updateAuthPassword"
      :showDrawer="legendOptions.showAuthPwdModel"
      @submitHandle="submitUpdateAuthPwdHandle"
      @cancelUpdatePwdHandle="legendOptions.showAuthPwdModel = false"
    />

    <!-- 身份选择模态框 -->
    <div class="modal" v-if="modelVisible">
      <div class="modal-content">暂未开启营业日，请联系咨客人员！</div>
    </div>

    <!-- 估清 -->
    <div class="out-something" v-if="showOrHideOutSomething">
      <outSomething
        ref="outSomething"
        @showOrHideOutSomethingHandle="showOrHideOutSomethingHandle"
      />
    </div>

    <!-- 售出日报表 -->
    <div class="day-report" v-if="showOrHideDayReport">
      <dayReport
        ref="dayReport"
        @showOrHideDayReportHandle="showOrHideDayReportHandle"
      />
    </div>

    <!-- 盘盈盘亏 -->
    <drawerProfit
      ref="drawerProfit"
      :showDrawer="showOrHideProfit"
      @showOrHideProfitHandle="showOrHideProfitHandle"
    />

    <!-- 线上支付汇总 -->
    <drawerOnlinePayTotal
      ref="drawerOnlinePayTotal"
      :showDrawer="showOrHideOnlinePayTotal"
      @showOrHideOnlineTotalHandle="showOrHideOnlineTotalHandle"
    />

    <!-- 线上支付记录 -->
    <drawerOnlinePayDetail
      :showDrawer="showOrHideOnlinePayDetail"
      @showOrHideOnlinePayDetailHandle="showOrHideOnlinePayDetailHandle"
    />

    <!-- 业绩日报表 -->
    <drawerKpiReport
      :showDrawer="showOrHideKpiReport"
      @showOrHideKpiReportHandle="showOrHideKpiReportHandle"
    />

    <!-- 线上预定记录 -->
    <drawerOnlineBooking
      :showDrawer="showOrHideOnlineBooking"
      @showOrHideOnlineBookingDrawer="showOrHideOnlineBookingDrawer"
    />

    <!-- 优惠明细表 -->
    <drawerYHDetail
      :showDrawer="showOrHideYHDetail"
      @showOrHideYHDetailDrawer="showOrHideYHDetailDrawer"
    />

    <!-- 鸡尾酒明细表 -->
    <drawerTYDetail
      :showDrawer="showOrHideTYDetail"
      @showOrHideTYDetailDrawer="showOrHideTYDetailDrawer"
    />

    <!-- 鸡尾酒汇总表 -->
    <drawerTYHZ
      :showDrawer="showOrHideTYHZ"
      @showOrHideTYHZDrawer="showOrHideTYHZDrawer"
    />

    <!-- 挂账详情 -->
    <drawerGZDetail
      :showDrawer="showOrHideGZDetail"
      @showOrHideGZDetailDrawer="showOrHideGZDetailDrawer"
    />

    <!-- 翻台记录 -->
    <drawerTurnOverDetail
      :showDrawer="showOrHideTurnOverDetail"
      @showOrHideTurnOverDetailDrawer="showOrHideTurnOverDetailHandle"
    />

    <!-- 点单记录 -->
    <drawerOrderDetail
      :showDrawer="showOrHideOrderDetail"
      @showOrHideOrderDetailDrawer="showOrHideOrderDetailDrawer"
    />

    <!-- 非鸡尾酒类补交报表 -->
    <drawerNotTYOrXF
      :showDrawer="showOrHideNotTYOrXF"
      @showOrHideNotTYOrXFDrawer="showOrHideNotTYOrXFDrawer"
    />

    <!-- 修改订位人操作记录 -->
    <drawerUpdateBookEmp
      :showDrawer="showOrHideUpdateEmp"
      @showOrHideUpdateEmpDrawer="showOrHideUpdateEmpDrawer"
    />

    <!-- 转台记录 -->
    <drawerTurnOver
      :showDrawer="showTurnOverDrawer"
      @showOrHideDrawer="showOrHideTurnOverDrawerHandle"
    />

    <!-- 查询优惠额度 -->
    <drawerYHCount
      ref="drawerYHCount"
      :showDrawer="showYHCountDrawer"
      @showOrHideDrawer="showOrHideYHCountDrawerHandle"
    />

    <!-- 商户号管理 -->
    <drawerMerChant
      :showDrawer="showMerchantDrawer"
      @showOrHideDrawer="showOrHideMerchantDrawerHandle"
    />

    <!-- 商户号信息 -->
    <drawerMerChantInfo
      :showDrawer="showMerchantInfoDrawer"
      @showOrHideDrawer="showOrHideMerchantInfoDrawerHandle"
    />

    <!-- 低消进度统计表 -->
    <drawerMinDetail
      :showDrawer="showMinDetailDrawer"
      @showOrHideDrawer="showOrHideMinDetailDrawerHandle"
    />

    <!-- 现抽明细表 -->
    <drawerXCDetail
      :showDrawer="showXCDetailDrawer"
      @showOrHideDrawer="showOrHideXCDetailDrawerHandle"
    />

    <!-- 现抽汇总表 -->
    <drawerXCAllInfo
      :showDrawer="showXCAllInfoDrawer"
      @showOrHideDrawer="showOrHideXCAllInfoDrawerHandle"
    />

    <!-- 非主营分类渠道汇总表 -->
    <drawerQDAllInfo
      :showDrawer="showQDAllInfoDrawer"
      @showOrHideDrawer="showOrHideQDAllInfoDrawerHandle"
    />

    <!-- 分类渠道汇总表 -->
    <drawerCatQDAllInfo
      :showDrawer="showCatQDAllInfoDrawer"
      @showOrHideDrawer="showOrHideCatQDAllInfoDrawerHandle"
    />

    <!-- 部门销售汇总表 -->
    <drawerXSAllInfo
      :showDrawer="showXSAllInfoDrawer"
      @showOrHideDrawer="showOrHideXSAllInfoDrawerHandle"
    />

    <!-- 部门销售明细表 -->
    <drawerXSDetail
      :showDrawer="showDetailDrawer"
      @showOrHideDrawer="showOrHideXSDetailDrawerHandle"
    />

    <!-- 套餐统计表 -->
    <div class="day-report" v-if="showSetCountDrawer">
      <drawerSetCount
        @showOrHideSetCountDrawerHandle="showOrHideSetCountDrawerHandle"
      />
    </div>

    <!-- 部门销售汇总表 -->
    <drawerXSAllInfo
      :showDrawer="showXSAllInfoDrawer"
      @showOrHideDrawer="showOrHideXSAllInfoDrawerHandle"
    />
  </div>
</template>

<script>
import api_money from "@/api/money";
import api_auth from "@/api/UtilAuth";
import { legendList } from "@/utils/config/card";

import drawerStopStore from "@/components/money/drawerStopStore";
import drawerNeedBackOrderList from "@/components/money/drawerNeedBackOrderList/drawerNeedBackOrderList.vue";

// 估清弹框
import outSomething from "../Order/orderMeal/orderMealList.vue";

// 班结表
import drawerStopClass from "@/components/money/drawerStopClass";

// 售出日报表
import dayReport from "@/components/money/dayReport.vue";

// 盘盈盘亏
import drawerProfit from "@/components/money/drawerProfit/drawerProfit.vue";

// 线上支付汇总
import drawerOnlinePayTotal from "../../components/money/drawerOnlineTotal.vue";

// 线上支付记录
import drawerOnlinePayDetail from "../../components/money/drawerOnlinePayDetail.vue";

// 业绩日报表
import drawerKpiReport from "../../components/money/drawerKpiReport.vue";

// 线上预定记录
import drawerOnlineBooking from "../../components/money/drawerOnlineBooking.vue";

// 优惠明细表
import drawerYHDetail from "../../components/money/drawerYHDetail.vue";

// 鸡尾酒明细表
import drawerTYDetail from "../../components/money/drawerTYDetail.vue";

// 鸡尾酒汇总表
import drawerTYHZ from "../../components/money/drawerTYHZ.vue";

// 挂账详情
import drawerGZDetail from "../../components/money/drawerGZDetail/index.vue";

// 翻台记录
import drawerTurnOverDetail from "../../components/money/drawerTurnOver.vue";

// 点单记录
import drawerOrderDetail from "../../components/money/drawerOrder.vue";

// 非特饮消费类补交报表
import drawerNotTYOrXF from "../../components/money/drawerNotTYOrXF.vue";

// 修改订位人操作记录
import drawerUpdateBookEmp from "../../components/money/drawerUpdateBookEmp.vue";

// 修改密码
import updatePassword from "@/components/common/updatePassword.vue";

// 修改授权码
import updateAuthPassword from "@/components/common/updateAuthPassword.vue";

// 转台记录
import drawerTurnOver from "@/components/book/machine/drawerTurnOver.vue";

// 查询优惠额度
import drawerYHCount from "../../components/money/drawerYHCount/index.vue";

// 商户号管理
import drawerMerChant from "../../components/money/drawerMerchant.vue";

// 商户号信息
import drawerMerChantInfo from "../../components/money/drawerMerChantInfo.vue";

// 低消进度统计表
import drawerMinDetail from "../../components/money/drawerMinDetail.vue";

// 现抽明细表
import drawerXCDetail from "../../components/money/drawerXCDetail.vue";

// 现抽汇总表
import drawerXCAllInfo from "../../components/money/drawerXCAllInfo.vue";

// 非主营分类渠道汇总表
import drawerQDAllInfo from "../../components/money/drawerQDAllInfo.vue";

// 分类渠道汇总表
import drawerCatQDAllInfo from "../../components/money/drawerCatQDAllInfo.vue";

// 部门销售汇总表
import drawerXSAllInfo from "../../components/money/drawerXSAllInfo.vue";

// 套餐统计表
import drawerSetCount from "../../components/money/drawerSetCount.vue";


// 部门销售明细表
import drawerXSDetail from "../../components/money/drawerXSDetail.vue";

import { cardPageMixins } from "@/mixin/cardPage";
import authStatus from "@/mixin/authStatus";
import eventVue from "@/utils/eventVue";
import arrowBottom from "@/assets/card-imgs/arrow-bottom.png";
import more from "@/assets/card-imgs/more.png";
import reload from "@/assets/card-imgs/reload.png";
import arrowTop from "@/assets/card-imgs/arrow-top.png";
import checkout from "@/assets/card-imgs/checkout.png";
import loginOut from "@/assets/card-imgs/loginout.png";
import updatepwd from "@/assets/card-imgs/updatepwd.png";
import authPwd from "@/assets/card-imgs/authPwd.png";
import noCardInfo from "@/assets/card-imgs/no-card.png";
import sanJiao from "@/assets/card-imgs/cardOptions/sanjiao.png";
import orderBack from "@/assets/money-img/order-back.png";
import backList from "@/assets/money-img/back-list.png";
const TabWidth = 100; // tab固定宽度
const cardWidth = 168; // 卡台信息固定宽度
const cardOptionHos = 164; // 卡台选项横向偏移量
let resResultDataObj = {}; // 元数据（后台接口返回处理后的初始化数据）
let cardListInfoArr = []; // 卡台总数据
let hasShowOptions = false; // 是否有显示的options操作选项
let hasNotify = false; // 是否已执行通知卡台背景闪烁函数

// 键盘码 keycode
let downKeyCode = [0, 0];
const ctrlAndShiftCode = [17, 16];
export default {
  data() {
    return {
      loadIndex: 0,
      // modelVisible: true, // 是否显示未开启营业日模态框
      socket: null,
      showFullPageTable: false, // 是否显示全屏表格（转台等操作）
      showOrHideOutSomething: false, // 是否显示估清商品模态框
      showOrHideDayReport: false, // 是否显示日报表模态框
      showOrHideProfit: false, // 是否显示盘盈盘亏抽屉
      showOrHideOnlinePayTotal: false, // 线上支付汇总
      showOrHideOnlinePayDetail: false, // 线上支付记录
      showOrHideKpiReport: false, // 业绩日报表
      showOrHideOnlineBooking: false, // 线上预定记录
      showOrHideYHDetail: false, // 优惠明细表
      showOrHideTYDetail: false, // 鸡尾酒明细表
      showOrHideTYHZ: false, // 鸡尾酒汇总表
      showOrHideGZDetail: false, // 挂账详情
      showOrHideTurnOverDetail: false, // 翻台记录
      showOrHideOrderDetail: false, // 点单记录
      showOrHideNotTYOrXF: false, // 非鸡尾酒类补交报表
      showOrHideUpdateEmp: false, // 修改订位人操作记录
      showTurnOverDrawer: false, // 转台记录
      showYHCountDrawer: false, // 查询优惠额度
      showMerchantDrawer: false, // 商户号管理
      showMerchantInfoDrawer: false, // 商户号信息
      showMinDetailDrawer: false, // 低消进度统计表
      showXCDetailDrawer: false, // 现抽明细表
      showXCAllInfoDrawer: false, // 现抽汇总表
      showQDAllInfoDrawer: false, // 非主营分类渠道汇总表
      showCatQDAllInfoDrawer: false, // 分类渠道汇总表
      showDetailDrawer: false, // 部门销售明细表
      showSetCountDrawer: false, // 套餐统计表
      showXSAllInfoDrawer: false, // 部门销售汇总表
      keyWord: "",
      tab: {
        tabListOrigin: [], // 原始数据（只经过排序处理的数据）
        tabList: [],
        activeIndex: 0,
        tabMaxCount: 0,
        anotherInfo: [],
        showAnotherInfo: false,
        anotherInfoActiveId: 0,
      },
      card: {
        centerTypeWidth: 0, // 版心宽度
        cardList: [],
        cardListInfoArr: [],
        optionsPosition: {
          top: "50%",
          bottom: "",
          transform: "translate(0,-50%)",
          left: cardOptionHos + "px",
          right: "",
        },
      },
      imgSrc: {
        reload,
        arrowBottom,
        more,
        arrowTop,
        checkout,
        loginOut,
        updatepwd,
        authPwd,
        noCardInfo,
        sanJiao,
        orderBack,
        backList,
      },
      legendList: legendList.filter((item) => item.id !== 2),
      legendActive: 0,
      authName: "", // 员工姓名
      arrowStatus: "", // 鼠标按下按钮状态
      // 图例操作选项

      legendOptions: {
        showUpdatePwd: false, // 是否显示更改密码或退出
        showMoreFunc: false, // 是否显示更多功能
        updatePwdModel: false, // 是否显示更改密码模态框
        showAuthPwdModel: false, // 是否显示授权密码模态框
        showNeedBackOrderList: false, // 是否显示待退款列表
      },
      cardStatusNoInfo: {}, // 图例抵达卡台数量

      endStore: {
        showDrawer: false,
        status: "", // 1：手动结束  2：自动结束
      },

      // 班结表
      stopClass: {
        showDrawer: false,
      },
    };
  },
  methods: {
    // 获取tab展示的数量
    getTabShowCount(callback) {
      const windowWidth = document.body.clientWidth;
      this.tab.tabMaxCount = Math.floor((windowWidth * 0.68) / TabWidth);
      this.card.centerTypeWidth =
        Math.floor(windowWidth / cardWidth) * cardWidth;
      callback && callback();
    },
    // 搜索卡台(关键字搜索)
    inputSearchHandle() {
      this.legendActive = 0;
      this.tab.anotherInfoActiveId = 0;
      this.tab.activeIndex = 0;
      this.card.cardList = this.filterCardList("keyword");
    },

    // 获取tab数据
    getTabList(arr = []) {
      arr = arr.sort((a, b) => Number(a.dsp) - Number(b.dsp));
      let tabList = arr.filter((el) => el.status === "1"); // status:  1:有效 2:无效
      tabList = tabList.filter(
        (e) => this.filterCardList("regionId", e.id).length > 0
      );

      this.tab.tabListOrigin = JSON.parse(JSON.stringify(tabList));
      this.$store.commit("updateTabList", this.tab.tabListOrigin);
      if (tabList.length > 0) {
        tabList.unshift({
          id: 0,
          name: "全部",
        });
      }
      if (tabList.length > this.tab.tabMaxCount) {
        this.tab.anotherInfo = tabList.splice(this.tab.tabMaxCount - 1);
        tabList.push({
          id: 999,
          name: "其它",
        });
      }
      this.tab.tabList = tabList;
    },

    // 获取全量数据
    getCardList(cardInfo = [], businessData = [], resort) {
      // // 获取设备可操作区域或卡台
      const currentMachineId = this.$localStorage.getItem("machineId");
      const currentAreaAndCardList = (
        this.$store.state.cardPageInfo.resResultDataObj["machineArea"] || []
      ).filter(
        (item) => item.license_id == currentMachineId && item.status == 1
      );
      const isNoLimit = currentAreaAndCardList.filter(
        (item) => item.type_id == 3
      );
      if (isNoLimit.length <= 0) {
        // 有限制
        const areaList = currentAreaAndCardList.filter(
          (item) => item.type_id == 1
        );
        const cardListNew = currentAreaAndCardList.filter(
          (item) => item.type_id == 2
        );
        // 当前配置的区域id
        let areaIdList = areaList.map((item) => item.region_o_seat_id);

        // 通过cardList反推出对应的区域，并添加到区域id中
        const allCardInfo =
          [...this.$store.state.cardPageInfo.resResultDataObj.cardInfo] || [];

        // 最终经过筛选过后的区域列表，对应元数据的areaInfo
        let resultAreaList = [];
        // 最终经过筛选过后的卡台列表，对应元数据的cardInfo
        let resultCardList = [];

        areaIdList.forEach((el) => {
          // 存储配置区域的区域下所有卡台
          const currentAreaCardList = allCardInfo.filter(
            (item) => item.regionId == el
          );
          resultCardList = [...resultCardList, ...currentAreaCardList];
        });

        cardListNew.forEach((el) => {
          const find = allCardInfo.find(
            (item) => item.id == el.region_o_seat_id
          );
          if (find) {
            resultCardList.push(find);
            if (!areaIdList.find((item) => item == find.regionId)) {
              areaIdList.push(find.regionId);
            }
          }
        });
        cardInfo = resultCardList;
      }
      // cardInfo:卡台数据  businessData:业务数据
      cardInfo = cardInfo.sort((a, b) => a.dsp - b.dsp);
      console.log("%c 卡台数据断点", "color:blue;font-size:14px");
      console.log("cardInfo", cardInfo.length);
      console.log("businessData", businessData.length);
      let comingCount = 0;
      let pushComingCount = 0;
      const cardList = [];
      cardInfo.forEach((item, index) => {
        if (item.status == "1") {
          comingCount++;
          // 查找对应的业务数据
          const data = businessData.find((el) => el.seatId == item.id) || {};
          if (data.bizStatus != "22" && data.bizStatus != "33") {
            pushComingCount++;
            cardList.push({
              // 卡台数据
              ...item,
              // 业务数据
              ...data,
              // 卡台名称放大倍数
              cardNameScale: this.getScaleCardName(item.name),
              // 赠送金额
              zengSongAmt: (Number(data.yhAmt) + Number(data.yh2Amt)).toFixed(
                2
              ),
              // 当前卡台所处状态的小卡片
              tipsArr: this.getTips(data.bizStatus),
              // 低消进度
              diXiaoJindu:
                Number(data.assignMinCsmAmt) > 0
                  ? (
                      Number(data.orderAmt) / Number(data.assignMinCsmAmt)
                    ).toFixed(0) > 1
                    ? "100%"
                    : (
                        (Number(data.orderAmt) / Number(data.assignMinCsmAmt)) *
                        100
                      ).toFixed(0) + "%"
                  : "",
            });
          }
        }
      });

      // 设置图例中显示的抵达数量
      this.setLegendCount(this.tab.activeIndex);

      console.log("cardList", cardList.length);

      cardListInfoArr = JSON.parse(JSON.stringify(cardList));

      this.$store.commit("updateCardList", cardList);

      const resultCardList = this.filterCardList(
        "regionId",
        this.tab.activeIndex
      );

      // if(resultCardList.length < cardList.length) {
      //   console.log('%c 卡台数据断点重新开始', 'color:red;font-size:14px');
      //   setTimeout(() => {
      //     this.loadIndex += 1
      //     this.$parent.getAllData(true, this.loadIndex % 5 == 0)
      //   }, 100);
      //   return
      // }

      if (!this.keyWord) {
        this.card.cardList = resultCardList;
      } else {
        if(resort) {
          this.card.cardList = resultCardList;
        } else {
          this.card.cardList = this.card.cardList.map(item => resultCardList.find(i => i.id == item.i))
        }
      }

      // console.log(
      //   "comingCount",
      //   comingCount,
      //   "pushComingCount",
      //   pushComingCount
      // );
      // console.log(
      //   "cardList",
      //   this.card.cardList.map((items) => items.name)
      // );

      hasNotify ? "" : this.cardNotifyHandle(); // 卡台闪烁提醒检测

      this.$forceUpdate();
    },

    // 筛选卡台数据
    filterCardList(key, id) {
      const arr = this.$store.state.cardPageInfo.resResultDataObj["areaInfo"]
      let a = {}
      arr.forEach(item => {
        a[item.id] = item.dsp
      })
      cardListInfoArr.forEach(item => {
        item.rdsp = a[item.regionId]
      })

      // 点击全部卡台按钮
      const notPayCardList = cardListInfoArr
        .filter((item) => item.bizStatus == 5)
        .sort((a, b) => a.rdsp -b.rdsp || a.dsp - b.dsp);
      const PayOtherCardList = cardListInfoArr
        .filter((item) => item.bizStatus == 6)
        .sort((a, b) => a.rdsp -b.rdsp || a.dsp - b.dsp);
      const PayedCardList = cardListInfoArr
        .filter((item) => item.bizStatus == 7)
        .sort((a, b) => a.rdsp -b.rdsp || a.dsp - b.dsp);
      const openCardList = cardListInfoArr
        .filter((item) => item.bizStatus == 4)
        .sort((a, b) => a.rdsp -b.rdsp || a.dsp - b.dsp);
      const reservedCardList = cardListInfoArr.filter(
        (item) => item.bizStatus == 8
      ).sort((a, b) => a.rdsp -b.rdsp || a.dsp - b.dsp);
      // 空台
      const notOpenCardList = [
        ...cardListInfoArr.filter(
          (item) => item.bizStatus == 1 && item.turnoverCnt > 0
        ).sort((a, b) => a.rdsp -b.rdsp || a.dsp - b.dsp),
        ...cardListInfoArr.filter(
          (item) => item.bizStatus == 1 && item.turnoverCnt == 0
        ).sort((a, b) => a.rdsp -b.rdsp || a.dsp - b.dsp),
      ];
      // 锁台
      const clockCardList = [
        ...cardListInfoArr.filter(
          (item) => item.bizStatus == 2 && item.turnoverCnt > 0
        ).sort((a, b) => a.rdsp -b.rdsp || a.dsp - b.dsp),
        ...cardListInfoArr.filter(
          (item) => item.bizStatus == 2 && item.turnoverCnt == 0
        ).sort((a, b) => a.rdsp -b.rdsp || a.dsp - b.dsp),
      ];

      const resultCardList = [
        ...notPayCardList,
        ...PayOtherCardList,
        ...PayedCardList,
        ...openCardList,
        ...reservedCardList,
        ...notOpenCardList,
        ...clockCardList,
      ];

      // console.log('notPayCardList', notPayCardList);
      // console.log('PayOtherCardList', PayOtherCardList);
      // console.log('PayedCardList', PayedCardList);
      // console.log('openCardList', openCardList);
      // console.log('reservedCardList', reservedCardList);
      // console.log('notOpenCardList', notOpenCardList);
      // console.log('clockCardList', clockCardList);
      console.log(
        "length",
        notPayCardList.length +
          PayOtherCardList.length +
          PayedCardList.length +
          openCardList.length +
          reservedCardList.length +
          notOpenCardList.length +
          clockCardList.length
      );

      if (key === "regionId" && id === 0) {
        return resultCardList;
      }

      if (key === "keyword") {
        return resultCardList.filter(
          (item) =>
            item.customerName
              .toLocaleUpperCase()
              .includes(this.keyWord.toLocaleUpperCase()) ||
            item.customerPhone.slice(-4).includes(this.keyWord) ||
            item.customer_name_py
              .toLocaleUpperCase()
              .includes(this.keyWord.toLocaleUpperCase()) ||
            item.name
              .toLocaleUpperCase()
              .includes(this.keyWord.toLocaleUpperCase())
        );
      }
      return resultCardList.filter((item) => item[key] == id);
    },

    // 点击卡台
    cardClickHandle(info, index) {
      if (
        info.bizStatus == 4 ||
        info.bizStatus == 5 ||
        info.bizStatus == 6 ||
        info.bizStatus == 7
      ) {
        this.goPayOrderPageHandle(info);
      } else if (info.bizStatus == 1 && info.turnoverCnt > 0) {
        this.showOrHideOptionHandle(index, true);
      } else {
        this.windowScrollHideOptionsHandle();
      }
    },

    // 进入订单页面
    goPayOrderPageHandle(info) {
      this.$store.commit("updateOrderInfo", {
        key: "currentCardInfo",
        value: info,
      });
      this.$router.push({ name: "payOrder" });
    },

    showOrHideEndStoreDrawer(status) {
      // status: 1:手动结束  2：自动结束
      this.endStore.showDrawer = !this.endStore.showDrawer;
      if (status) this.endStore.status = status;
    },

    // 显示或隐藏班结表
    showOrHideStopClassDrawer() {
      this.stopClass.showDrawer = !this.stopClass.showDrawer;
    },

    showOrHideNeedBackOrderListDrawer() {
      this.legendOptionHandle("needBackOrder");
    },

    // 显示或隐藏转台记录
    showOrHideTurnOverDrawerHandle() {
      this.showTurnOverDrawer = !this.showTurnOverDrawer;
    },

    // 显示或隐藏优惠额度
    showOrHideYHCountDrawerHandle() {
      this.showYHCountDrawer = !this.showYHCountDrawer;
    },

    // 显示或隐藏商户号管理
    showOrHideMerchantDrawerHandle() {
      this.showMerchantDrawer = !this.showMerchantDrawer;
    },

    // 显示或隐藏商户号信息
    showOrHideMerchantInfoDrawerHandle() {
      this.showMerchantInfoDrawer = !this.showMerchantInfoDrawer;
    },

    // 显示或隐藏低消进度统计表
    showOrHideMinDetailDrawerHandle() {
      this.showMinDetailDrawer = !this.showMinDetailDrawer;
    },

    // 显示或隐藏现抽明细表
    showOrHideXCDetailDrawerHandle() {
      this.showXCDetailDrawer = !this.showXCDetailDrawer;
    },

    // 显示或隐藏现抽成汇总表
    showOrHideXCAllInfoDrawerHandle() {
      this.showXCAllInfoDrawer = !this.showXCAllInfoDrawer;
    },

    // 显示或隐藏非主营分类渠道汇总表
    showOrHideQDAllInfoDrawerHandle() {
      this.showQDAllInfoDrawer = !this.showQDAllInfoDrawer;
    },

    // 分类渠道汇总表
    showOrHideCatQDAllInfoDrawerHandle() {
      this.showCatQDAllInfoDrawer = !this.showCatQDAllInfoDrawer;
    },

    // 显示或隐藏部门销售汇总表
    showOrHideXSAllInfoDrawerHandle() {
      this.showXSAllInfoDrawer = !this.showXSAllInfoDrawer;
    },

    // 显示或隐藏部门销售明细表
    showOrHideXSDetailDrawerHandle() {
      this.showDetailDrawer = !this.showDetailDrawer;
    },

    // 显示或隐藏套餐统计表
    showOrHideSetCountDrawerHandle() {
      this.showSetCountDrawer = !this.showSetCountDrawer;
    },

    // 更多功能
    endStoreHandle(type) {
      switch (type) {
        case "stop":
          this.showOrHideEndStoreDrawer(1);
          break;
        case "stopAuto":
          this.showOrHideEndStoreDrawer(2);
          break;
        default:
          console.log("default");
          break;
      }
    },

    // 估清商品
    showOrHideOutSomethingHandle(value) {
      this.showOrHideOutSomething = !this.showOrHideOutSomething;
    },

    // 日表表
    showOrHideDayReportHandle() {
      this.showOrHideDayReport = !this.showOrHideDayReport;
    },

    // 盘盈盘亏
    showOrHideProfitHandle() {
      this.showOrHideProfit = !this.showOrHideProfit;
    },

    // 线上支付汇总
    showOrHideOnlineTotalHandle() {
      this.showOrHideOnlinePayTotal = !this.showOrHideOnlinePayTotal;
    },

    // 线上支付记录
    showOrHideOnlinePayDetailHandle() {
      this.showOrHideOnlinePayDetail = !this.showOrHideOnlinePayDetail;
    },

    // 业绩日报表
    showOrHideKpiReportHandle() {
      this.showOrHideKpiReport = !this.showOrHideKpiReport;
    },

    // 线上预定记录
    showOrHideOnlineBookingDrawer() {
      this.showOrHideOnlineBooking = !this.showOrHideOnlineBooking;
    },

    // 优惠明细表
    showOrHideYHDetailDrawer() {
      this.showOrHideYHDetail = !this.showOrHideYHDetail;
    },

    // 鸡尾酒明细表
    showOrHideTYDetailDrawer() {
      this.showOrHideTYDetail = !this.showOrHideTYDetail;
    },

    // 鸡尾酒汇总表
    showOrHideTYHZDrawer() {
      this.showOrHideTYHZ = !this.showOrHideTYHZ;
    },

    // 挂账详情
    showOrHideGZDetailDrawer() {
      this.showOrHideGZDetail = !this.showOrHideGZDetail;
    },

    // 翻台记录
    showOrHideTurnOverDetailHandle() {
      this.showOrHideTurnOverDetail = !this.showOrHideTurnOverDetail;
    },

    // 点单记录
    showOrHideOrderDetailDrawer() {
      this.showOrHideOrderDetail = !this.showOrHideOrderDetail;
    },

    // 非鸡尾酒类补交报表
    showOrHideNotTYOrXFDrawer() {
      this.showOrHideNotTYOrXF = !this.showOrHideNotTYOrXF;
    },

    // 修改订位人操作记录
    showOrHideUpdateEmpDrawer() {
      this.showOrHideUpdateEmp = !this.showOrHideUpdateEmp;
    },

    // 操作图例legend中的option
    async legendOptionHandle(type) {
      switch (type) {
        case "vip": // 点击去VIP系统
          this.$router.push({ name: "vipManager" });
          break;
        case "pwd": // 点击修改密码系列
          this.legendOptions.showUpdatePwd = !this.legendOptions.showUpdatePwd;
          this.legendOptions.showMoreFunc = false;
          break;
        case "logout": // 登出
          this.showConfirmHandle("退出登录", "是否退出登录？", async () => {
            try {
              const res = await api_auth.auth.requestauthlogout();
              if (res.code === 1) {
                // this.$store.commit("updateResResultDataObj", "");
                this.$store.commit("updateUserInfo", "");
                this.$router.replace({
                  name: "Thelogin",
                  replace: true,
                  query: {
                    client: "money",
                  },
                });
                this.$message.success("退出成功！");
              } else {
                this.$message.warning(res.msg);
              }
            } catch (error) {
              console.log("logout失败", error);
            }
          });
          break;
        case "logoutNotConfirm":
          try {
            const res = await api_auth.auth.requestauthlogout();
            if (res.code === 1) {
              // this.$store.commit("updateResResultDataObj", "");
              this.$store.commit("updateUserInfo", "");
              this.$router.replace({
                name: "Thelogin",
                replace: true,
                query: {
                  client: "money",
                },
              });
            } else {
              this.$message.warning(res.msg);
            }
          } catch (error) {
            console.log("logout失败", error);
          }
          break;
        case "updatePwd":
          this.legendOptions.updatePwdModel = true;
          break;
        case "authPwd":
          this.legendOptions.showAuthPwdModel = true;
          break;
        case "more": // 更多功能
          this.legendOptions.showMoreFunc = !this.legendOptions.showMoreFunc;
          this.legendOptions.showUpdatePwd = false;
          break;
        case "needBackOrder": // 待退款列表
          this.legendOptions.showNeedBackOrderList =
            !this.legendOptions.showNeedBackOrderList;
          break;
        default:
          this.legendOptions.showUpdatePwd = false;
          this.legendOptions.showMoreFunc = false;
          break;
      }
    },

    // 请求全量基础数据(首次页面加载在父组件中调用(返回到此页面数据由mounted加载))
    async getAllData(resort = true) {
      this.getAuthStatus();
      // const loading = this.$loading({
      //   lock: true,
      //   text: "Loading",
      //   spinner: "el-icon-loading",
      //   background: "rgba(0, 0, 0, 0.7)"
      // });
      try {
        resResultDataObj = this.$store.state.cardPageInfo.resResultDataObj;
        if (
          !resResultDataObj &&
          (!resResultDataObj["areaInfo"] ||
            !resResultDataObj["cardInfo"] ||
            !resResultDataObj["businessData"])
        )
          return;

        // console.log("inMoney", resResultDataObj);
        await this.getCardList(
          resResultDataObj["cardInfo"],
          resResultDataObj["businessData"],
          resort
        );
        await this.getTabList(JSON.parse(JSON.stringify(resResultDataObj["areaInfo"])));
        // 获取卡台数据
      } catch (error) {
        console.log("全量数据请求失败", error);
      }
      // loading.close();
    },

    //卡台闪烁提醒
    cardNotifyHandle() {
      hasNotify = true;
      let index = 1;
      const time = 1000;
      changeColor();

      function changeColor() {
        const dom = document.querySelectorAll(".notify");
        dom.forEach((el) => {
          index % 2 == 0
            ? el.classList.remove("notify-opacity0")
            : el.classList.add("notify-opacity0");
        });
        index++;
        setTimeout(() => {
          changeColor();
        }, time);
      }
    },

    // 点击卡台出现或隐藏options选项
    showOrHideOptionHandle(index, isClickCard = false) {
      this.card.cardList.forEach((el, i) => {
        el.showOption = index === i ? !el.showOption : false;
      });
      if (this.legendOptions.showUpdatePwd)
        this.legendOptions.showUpdatePwd = false;
      hasShowOptions = false;

      // 初始化position位置
      this.card.optionsPosition = {
        top: "50%",
        bottom: "",
        transform: "translate(0,-50%)",
        left: cardOptionHos + "px",
        right: "",
      };

      if (isClickCard) {
        // 点击卡台
        hasShowOptions = true;
        this.$nextTick(() => {
          this.getOptionsPosition(index);
        });
      }
      this.$forceUpdate();
    },

    // 获取卡台操作选项的位置(上移/下移/居左/居右)
    getOptionsPosition(index) {
      this.$nextTick(() => {
        const cardDom = this.$refs.cardOptions;
        if (cardDom.length === 0) return false;
        // console.log(cardDom[0]);

        // 设置最小上下偏移量
        const minDistant = 17;

        // 计算一行显示几列卡台
        const oneLineCount = Math.floor(this.card.centerTypeWidth / cardWidth);

        // dom元素高度
        const domHeight = cardDom[0].getBoundingClientRect().height;
        // 距离浏览器可视区域顶部的距离
        const domTop = cardDom[0].getBoundingClientRect().top;
        // 距离浏览器可视区域底部的距离
        const domBottom = cardDom[0].getBoundingClientRect().bottom;
        // dom元素距离底部最大距离
        const domMaxBottomDistant =
          window.innerHeight ||
          document.documentElement.clientHeight ||
          document.body.clientHeight;

        if (domTop < 0) {
          const beyondDis = Math.abs(domTop);
          const translateY = Math.max(minDistant, domHeight / 2 - beyondDis);
          this.card.optionsPosition.transform = `translate(0,${
            -1 * translateY
          }px)`;
        } else if (domBottom > domMaxBottomDistant) {
          const beyondDis = Math.abs(domMaxBottomDistant - domBottom);
          const translateY =
            Math.min(domHeight - minDistant, domHeight / 2 + beyondDis) + 60;
          // console.log('bottom:', `translate(0,${-1 * translateY}px)`);
          this.card.optionsPosition.transform = `translate(0,${
            -1 * translateY
          }px)`;
        }

        // 判断左右显示
        if ((index + 1) % oneLineCount === 0) {
          // 每行最后一个卡台
          this.card.optionsPosition.left = "";
          this.card.optionsPosition.right = cardOptionHos + "px";
          this.card.cardList[index].isLeftArrow = true;
        }
        this.$forceUpdate();
      });
    },

    // 复台
    reserveCard(info) {
      this.showConfirmHandle("复台", "确定要进行复台操作吗？", async () => {
        try {
          const res = await api_money.reqReserveCardStatus({
            seat_id: info.seatId * 1, // int64   卡台Id
          });
          if (res.code === 1) {
            this.$message.success("复台成功");
            info.showOption = false;
            this.$forceUpdate();
          } else {
            this.$message.warning(res.msg);
          }
        } catch (error) {
          console.log("复台失败", error);
        }
      });
    },

    // 页面滚动隐藏目前页面中显示的卡台操作选项
    windowScrollHideOptionsHandle() {
      if (hasShowOptions) {
        this.card.cardList.forEach((el) => {
          el.showOption = false;
        });
        hasShowOptions = false;
        this.$forceUpdate();
      }
    },

    // 点击页面
    documentClickHandle() {
      this.showOrHideOptionHandle();
      this.legendOptions.showUpdatePwd = false;
      this.legendOptions.showMoreFunc = false;
    },

    keyHandle(e) {
      // alt 或 windows键(防止利用alt切屏)
      if (e.keyCode == 18 || e.keyCode == 91) return e.preventDefault();
      switch (e.type) {
        case "keydown":
          if (downKeyCode.findIndex((item) => item == 0) < 0) return;

          if (ctrlAndShiftCode.includes(e.keyCode)) {
            downKeyCode[0] = e.keyCode;
          } else if (downKeyCode[0] == 0 && downKeyCode[1] == 0) {
            downKeyCode[1] = e.keyCode;
          } else if (downKeyCode[0] == e.keyCode && downKeyCode[1] == 0) {
            // 重复按同一个件
          } else if (downKeyCode[0] != 0 && downKeyCode[1] == 0) {
            downKeyCode[1] = e.keyCode;
          }

          this.$nextTick(() => {
            if (downKeyCode[0] == 17 && downKeyCode[1] == 70) {
              e.preventDefault();
              // console.log('ctrl + f')  // 焦点定位在搜索框中
              this.$refs.searchInputRef && this.$refs.searchInputRef.focus();
            } else if (downKeyCode[0] == 0 && downKeyCode[1] == 37) {
              // console.log('left')  // 区域左选(左箭头)
              e.preventDefault();
              let index = [
                ...this.tab.tabList,
                ...this.tab.anotherInfo,
              ].findIndex((item) => item.id == this.tab.activeIndex);
              index = Math.max(0, index - 1);

              this.tab.anotherInfoActiveId = this.tab.activeIndex = [
                ...this.tab.tabList,
                ...this.tab.anotherInfo,
              ][index].id;
              // 查找对应卡台数据
              const fnParamsIndex =
                this.tab.tabList.findIndex(
                  (item) => item.id == this.tab.activeIndex
                ) > -1
                  ? index
                  : this.tab.tabList[this.tab.tabList.length - 1].id;
              this.changeTab(fnParamsIndex, this.tab.activeIndex);

              // 控制是否显示其它隐藏的区域
              if (
                index >= this.tab.tabList.length - 1 &&
                this.tab.anotherInfo.length > 0
              ) {
                this.tab.showAnotherInfo = true;
              } else {
                this.tab.showAnotherInfo = false;
              }
            } else if (downKeyCode[0] == 0 && downKeyCode[1] == 39) {
              // console.log('right')  // 区域右选（右箭头）
              e.preventDefault();
              let index = [
                ...this.tab.tabList,
                ...this.tab.anotherInfo,
              ].findIndex((item) => item.id == this.tab.activeIndex);
              index = Math.min(
                this.tab.tabList.length + this.tab.anotherInfo.length - 1,
                index + 1
              );

              this.tab.anotherInfoActiveId = this.tab.activeIndex = [
                ...this.tab.tabList,
                ...this.tab.anotherInfo,
              ][index].id;
              // 查找对应卡台数据
              const fnParamsIndex =
                this.tab.tabList.findIndex(
                  (item) => item.id == this.tab.activeIndex
                ) > -1
                  ? index
                  : this.tab.tabList[this.tab.tabList.length - 1].id;
              this.changeTab(fnParamsIndex, this.tab.activeIndex);

              // 控制是否显示其它隐藏的区域
              if (
                index >= this.tab.tabList.length - 1 &&
                this.tab.anotherInfo.length > 0
              ) {
                this.tab.showAnotherInfo = true;
              } else {
                this.tab.showAnotherInfo = false;
              }
            } else if (downKeyCode[0] == 0 && downKeyCode[1] == 13) {
              // enter回车
              if (this.endStore.showDrawer) {
                // 结束营业日
                this.$refs.drawerStopStore.onSubmit();
              } else if (this.legendOptions.showNeedBackOrderList) {
                // 异议订单
                this.$refs.drawerNeedBackOrderList.getBackOrderList(true);
              } else if (this.legendOptions.updatePwdModel) {
                // 修改密码
                this.$refs.updatePassword.onSubmit();
              } else if (this.legendOptions.showAuthPwdModel) {
                // 授权密码
                this.$refs.updateAuthPassword.onSubmit();
              } else if (this.showOrHideOutSomething) {
                // 估清
                const com = this.$refs.outSomething.$children.find(
                  (item) => item.$el.className == "product-list-GQ"
                );
                if (com.drawer.showDrawer) {
                  com &&
                    com.$refs.mealDrawer &&
                    com.$refs.mealDrawer.$refs.singleProductRef &&
                    com.$refs.mealDrawer.$refs.singleProductRef.onSubmit();
                } else {
                  com && com.$emit("showOrHideOutSomethingHandle");
                }
              } else if (this.showOrHideDayReport) {
                // 售出日报表
                this.$refs.dayReport.$emit("showOrHideDayReportHandle");
              } else if (this.showOrHideProfit) {
                // 盘盈盘亏
                const com = this.$refs.drawerProfit;
                if (com.showOrHideAddProfitPrdDrawer) {
                  // 添加盘盈盘亏
                  com.$refs.drawerAddProfitPrd.onSubmit();
                }
              } else if (this.showOrHideOnlinePayTotal) {
                // 线上支付汇总
                this.$refs.drawerOnlinePayTotal.printAllData();
              } else if (this.showYHCountDrawer) {
                // 查询优惠额度
                if (this.$refs.drawerYHCount.status == 1)
                  this.$refs.drawerYHCount.onSubmit();
              }
            } else if (downKeyCode[0] == 0 && downKeyCode[1] == 27) {
              // esc
              if (this.showOrHideOutSomething) {
                // 估清
                const com = this.$refs.outSomething.$children.find(
                  (item) => item.$el.className == "product-list-GQ"
                );
                com && com.$emit("showOrHideOutSomethingHandle");
              } else if (this.showOrHideDayReport) {
                // 售出日报表
                this.$refs.dayReport.$emit("showOrHideDayReportHandle");
              }
            }
          });

          // console.log('down:', downKeyCode)
          break;

        case "keyup":
          const index = downKeyCode.findIndex((item) => item == e.keyCode);

          if (index > -1) downKeyCode[index] = 0;

          if (ctrlAndShiftCode.includes(e.keyCode)) downKeyCode = [0, 0];
          // console.log('up:', downKeyCode)
          break;
      }
    },

    rightClickHandle() {
      return false;
    },

    // 设置图例中的抵达数量
    setLegendCount(regionId = 0) {
      setTimeout(() => {
        let result = {};

        // 获取设备可操作区域或卡台
        const currentMachineId = this.$localStorage.getItem("machineId");
        const currentAreaAndCardList = (
          resResultDataObj["machineArea"] || []
        ).filter(
          (item) => item.license_id == currentMachineId && item.status == 1
        );
        const isNoLimit = currentAreaAndCardList.filter(
          (item) => item.type_id == 3
        );
        if (isNoLimit.length > 0) {
          // 没有对设备进行卡台或区域限制
          if (regionId == 0) {
            // 选择的'全部'
            (
              this.$store.state.cardPageInfo.resResultDataObj.cardStatusNo || []
            ).forEach((el) => {
              if (result[el.id] != undefined) {
                result[el.id] = result[el.id] * 1 + el.cnt * 1;
              } else {
                result[el.id] = el.cnt * 1;
              }
            });
          } else {
            (this.$store.state.cardPageInfo.resResultDataObj.cardStatusNo || [])
              .filter((item) => item.region_id == regionId)
              .forEach((el) => {
                if (result[el.id] != undefined) {
                  result[el.id] = result[el.id] * 1 + el.cnt * 1;
                } else {
                  result[el.id] = el.cnt * 1;
                }
              });
          }
        } else {
          // 对设备进行了卡台区域配置
          if (regionId == 0) {
            // 选择的'全部'
            this.tab.tabListOrigin.forEach((el) => {
              if (el.isAllCard) {
                // 区域下所有卡台
                const currentAreaData = (
                  this.$store.state.cardPageInfo.resResultDataObj
                    .cardStatusNo || []
                ).filter((item) => item.region_id == el.id);
                // 当前区域下所有卡台都展示
                currentAreaData.forEach((el) => {
                  if (result[el.id] != undefined) {
                    result[el.id] = result[el.id] * 1 + el.cnt * 1;
                  } else {
                    result[el.id] = el.cnt * 1;
                  }
                });
              } else {
                // 区域下部分卡台
                const cardStatusNo =
                  this.$store.state.cardPageInfo.resResultDataObj
                    .cardStatusNo || [];
                // 累计卡台数
                const allOpenInfo = cardStatusNo.filter(
                  (item) => item.id == 30
                );
                // 累计抵达数
                const allArriveInfo = cardStatusNo.filter(
                  (item) => item.id == 31
                );
                this.card.cardList
                  .filter((item) => item.regionId == el.id)
                  .forEach((el) => {
                    if (el.bizStatus != 4 && el.bizStatus != 20) {
                      // 除了开台数和抵达数以外的状态
                      result[el.bizStatus] =
                        (result[el.bizStatus] || 0) * 1 + 1;
                    }
                    // 开台数、抵达数
                    const currentSeatOpenInfo = allOpenInfo.find(
                      (items) => items.region_id == el.id
                    ) || { cnt: 0 };
                    const currentSeatArriveInfo = allArriveInfo.find(
                      (items) => items.region_id == el.id
                    ) || { cnt: 0 };
                    result["10"] =
                      (result["10"] || 0) * 1 + currentSeatOpenInfo.cnt * 1; // 开台数
                    result["20"] =
                      (result["20"] || 0) * 1 + currentSeatArriveInfo.cnt * 1; // 抵达数
                  });
              }
            });
          } else {
            const currentAreaInfo =
              this.tab.tabList.find(
                (item) => item.id == this.tab.activeIndex
              ) || {};
            if (currentAreaInfo.isAllCard) {
              const currentAreaData = (
                this.$store.state.cardPageInfo.resResultDataObj.cardStatusNo ||
                []
              ).filter((item) => item.region_id == regionId);
              // 当前区域下所有卡台都展示
              currentAreaData.forEach((el) => {
                if (result[el.id] != undefined) {
                  result[el.id] = result[el.id] * 1 + el.cnt * 1;
                } else {
                  result[el.id] = el.cnt * 1;
                }
              });
            } else {
              // 展示的是当前区域下部分卡台的信息，需要重新计算卡台的数量

              const cardStatusNo =
                this.$store.state.cardPageInfo.resResultDataObj.cardStatusNo ||
                [];
              // 累计卡台数
              const allOpenInfo = cardStatusNo.filter((item) => item.id == 30);
              // 累计抵达数
              const allArriveInfo = cardStatusNo.filter(
                (item) => item.id == 31
              );
              this.card.cardList.forEach((el) => {
                if (el.bizStatus != 4 && el.bizStatus != 20) {
                  // 除了开台数和抵达数以外的状态
                  result[el.bizStatus] = (result[el.bizStatus] || 0) * 1 + 1;
                }
                // 开台数、抵达数
                const currentSeatOpenInfo = allOpenInfo.find(
                  (items) => items.region_id == el.id
                ) || { cnt: 0 };
                const currentSeatArriveInfo = allArriveInfo.find(
                  (items) => items.region_id == el.id
                ) || { cnt: 0 };
                result["10"] =
                  (result["10"] || 0) * 1 + currentSeatOpenInfo.cnt * 1; // 开台数
                result["20"] =
                  (result["20"] || 0) * 1 + currentSeatArriveInfo.cnt * 1; // 抵达数
              });
            }
          }
        }
        // 合并点单和半结
        result['5'] = result['6'] || 0 + result['5'] || 0;
        // console.log(result);
        this.cardStatusNoInfo = result;
      }, 200);
    },
  },

  mounted() {
    // 监听是否有其他人更改订单相关数据
    eventVue.$on("reloadMoneyCard", this.getAllData);

    setTimeout(() => {
      window.addEventListener("click", (e) => this.legendOptionHandle());
      this.$refs.containRef.addEventListener(
        "scroll",
        this.windowScrollHideOptionsHandle
      );
      window.addEventListener("resize", this.windowResizeHandle);
      document.addEventListener("click", this.documentClickHandle);

      window.onkeydown = this.keyHandle;
      window.onkeyup = this.keyHandle;

      this.$refs.searchInputRef && this.$refs.searchInputRef.focus();
    }, 1000);
  },

  computed: {
    merchantAllAmt() {
      const { merchantInfo } = this.$store.state.cardPageInfo.resResultDataObj;
      const resultAmt =
        merchantInfo.length == 0 ? 0 : ((merchantInfo[0].amt || 0) * 1) / 10000;
      return this.$overall.toFixed(resultAmt, 1);
    },
  },

  components: {
    drawerStopStore,
    drawerNeedBackOrderList,
    outSomething,
    drawerStopClass,
    dayReport,
    drawerProfit,
    drawerOnlinePayTotal,
    drawerOnlinePayDetail,
    drawerKpiReport,
    drawerOnlineBooking,
    drawerYHDetail,
    drawerTYDetail,
    drawerTYHZ,
    drawerGZDetail,
    drawerTurnOverDetail,
    drawerOrderDetail,
    drawerNotTYOrXF,
    drawerUpdateBookEmp,
    updatePassword,
    updateAuthPassword,
    drawerTurnOver,
    drawerYHCount,
    drawerMerChant,
    drawerMerChantInfo,
    drawerMinDetail,
    drawerXCDetail,
    drawerXCAllInfo,
    drawerQDAllInfo,
    drawerCatQDAllInfo,
    drawerXSDetail,
    drawerXSAllInfo,
    drawerSetCount,
  },

  watch: {
    "tab.activeIndex": {
      handler(newVal, oldVal) {
        let regionId = "";
        if (newVal == 999) {
          // 选的的是'其他'按钮
          regionId = oldVal;
        } else {
          regionId = newVal;
        }

        this.setLegendCount(regionId);
      },
      immediate: true,
    },
  },

  beforeDestroy() {
    window.removeEventListener("resize", this.windowResizeHandle);
    this.$refs.containRef.removeEventListener(
      "scroll",
      this.windowScrollHideOptionsHandle
    );
    window.removeEventListener("click", (e) => this.legendOptionHandle());
    document.body.removeEventListener("click", this.documentClickHandle);

    window.onkeydown = null;
    window.onkeyup = null;
    downKeyCode = [0, 0];
  },

  filters: {
    // 根据区域id获取区域名称
    getAreaName: (areaId) => {
      const result = resResultDataObj.areaInfo.find((el) => el.id === areaId);
      return (result && result.name) || "";
    },
    // 根据部门id获取员工姓名
    getOrderPersonName: (orderPersonId) =>
      (resResultDataObj.orderPersonInfo.find((el) => el.id === orderPersonId) &&
        resResultDataObj.orderPersonInfo.find((el) => el.id === orderPersonId)
          .name) ||
      "散客",
    // 根据定位人（员工）id获取部门名称
    getDepartmentName: (orderPersonId) => {
      const sealPersonInfo = resResultDataObj.orderPersonInfo.find(
        (el) => el.id === orderPersonId
      );
      if (sealPersonInfo) {
        // 非散客（有定位人）
        const result = resResultDataObj.departmentInfo.find(
          (el) => el.id === sealPersonInfo.deptId
        );
        return (result && result.name) || "";
      } else {
        // 散客
        return "";
      }
    },
  },

  mixins: [cardPageMixins, authStatus],
};
</script>

<style scoped lang="less">
@import "../../style/common/scrollBar.less";
@import "../../style/money/moneyCard.less";
@import "../../style/book/cardBgc.less";
</style>

<style lang="less">
@import "../../style/common/elementConfirm.less";
</style>

<style lang="less" scoped>
// 卡台背景闪烁颜色
.notify-opacity0 {
  opacity: 0;
}
</style>

<style>
.v-modal {
  z-index: 1 !important;
}
</style>
