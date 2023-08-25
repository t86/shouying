<template>
  <div>
    <!-- 授权 -->
    <el-drawer
      title="授权"
      :visible.sync="show"
      append-to-body
      :before-close="onCancelDrawer"
      direction="rtl"
      size="1000px"
    >
      <div class="session p-5" layout="row" layout-align="start start">
        <div class="left">
          <div class="title">授权商品和数量</div>
          <div class="table-content">
            <div class="table">
              <div class="thead">
                <div class="tr" layout="row" layout-align="space-between center">
                  <div class="th">序号</div>
                  <div class="th">名称</div>
                  <div class="th">规格</div>
                  <div class="th">每瓶克数</div>
                  <div class="th">数量</div>
                </div>
              </div>
              <div class="tbody">
                <div
                  class="tr"
                  layout="row"
                  layout-align="space-between center"
                  v-for="(item, index) in tableData"
                  :key="item.id"
                >
                  <div class="td">{{index + 1}}</div>
                  <div class="td one-txt-cut">{{item.n}}</div>
                  <div class="td">{{item.u}}</div>
                  <div class="td">{{item.g || '-'}}</div>
                  <div class="td">{{item.c}}</div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="right">
          <div class="tab-content m-t-6">
            <div class="tab" layout="row" layout-align="center center">
              <div class="tab-item" :class="{active: tabIndex == 1}" @click="tabIndex = 1">刷卡</div>
              <div class="tab-item" :class="{active: tabIndex == 2}" @click="tabIndex = 2">账号密码</div>
            </div>
          </div>
          <div class="form-content">
            <div v-if="tabIndex == 1">
              <p style="text-align:center;font-size:24px;font-weight:400;margin-top:150px">请刷卡</p>
            </div>
            <div class="p-t-10" v-if="tabIndex == 2">
              <div class="coll m-t-6" layout="row" layout-align="center center">
                <div class="label m-r-2">账号</div>
                <div class="value">
                  <el-input v-model="userName" size="small" style="width: 200px"></el-input>
                </div>
              </div>
              <div class="coll m-t-6" layout="row" layout-align="center center">
                <div class="label m-r-2">密码</div>
                <div class="value">
                  <el-input v-model="passWord" size="small" style="width: 200px" show-password></el-input>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import md5 from "js-md5";
import swipingCard from "@/mixin/swipingCard";
export default {
  data() {
    return {
      tabIndex: 1,
      userName: '',
      passWord: ''
    };
  },
  methods: {
    onSubmit() {
      if(!this.userName) return this.$message.warning('请输入账号')
      if(!this.passWord) return this.$message.warning('请输入密码')
      this.$emit('emitHandle', {userName: this.userName, passWord: md5(this.passWord).toString().toUpperCase(), type: this.tabIndex == 1 ? 2 : 1})
    },

    // 刷卡授权
    swiperSubmit(cardNo, password, type = 2){
      this.$emit('emitHandle', {userName: cardNo, passWord: md5(password).toString().toUpperCase(), type})
    },

    onCancelDrawer() {
      this.show = false;
    }
  },
  mounted() {},
  props: {
    value: {
      default: false // 是否显示drawer
    },
    tableData: {
      default: () => []
    }
  },
  mixins: [swipingCard],
  computed: {
    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      }
    }
  },
  watch: {
    value(newVal){
      if(newVal) {
        this.tabIndex = 1
        this.userName = ''
        this.passWord = ''
        window.stopLoopReadCard()
        window.loopReadCard()
      } else {
        window.stopLoopReadCard()
      }
    },
    tabIndex(newVal) {
      if(newVal == 1) {
        window.stopLoopReadCard()
        window.loopReadCard()
      } else {
        window.stopLoopReadCard()
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../style/common/elementDrawerWine.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/common/elementFormBtnWine.less";
@import "../../../../style/wine/table.less";
</style>

<style lang="less" scoped>
.session {
  .left {
    width: 50%;
    border-right: 1px solid #eee;
    padding-right: 10px;
    box-sizing: border-box;
    .title {
      font-size: 18px;
      margin-bottom: 10px;
    }
    .table {
      .tbody {
        height: calc(100vh - 232px);
        overflow: auto;
      }
      .th,.td{
        &:nth-child(2){
          width: 70%;
        }
      }
    }
  }
  .right {
    width: 50%;
    .tab-content {
      .tab {
        width: 200px;
        margin: 0 auto;
        border-radius: 8px;
        border: 1px solid #eee;
        overflow: hidden;
        .tab-item {
          cursor: pointer;
          width: 100px;
          height: 40px;
          line-height: 40px;
          text-align: center;
          &.active {
            background-color: #409EFF;
            color: #fff;
          }
        }
      }
    }
  }
}
</style>