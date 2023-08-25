<template>
  <div>
    <!-- 选择卡台 -->
    <el-drawer
      title="选择卡台"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      append-to-body
      direction="rtl"
      size="90%"
    >
      <div class="session p-5 choose-seat">
        <div class="seat-list">
          <div class="region" v-for="item in regionList" :key="item.id">
            <div class="region-name m-t-2 m-b-2">{{item.n}}</div>
            <div class="seats" layout="row" layout-align="start start">
              <div @click.stop="chooseSeatHandle(items)" class="seat-item" :class="{'active': items.id == currentSeatInfo.id}" v-for="items in item.seatList" :key="items.id">
                <div class="seat-item-content" :class="{'opacity': items.q != 1}" layout="row" layout-align="center center" >
                  <img v-if="items.id == currentSeatInfo.id" :src="require('@/assets/card-imgs/zhuantaiduigou.png')" alt />
                  <div>{{items.s}}</div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="user-info m-t-3 p-r-6" layout="row" layout-align="end center">
          <span class="m-r-6">当前选中卡台：{{currentSeatInfo.s || '-'}}</span>
          <span>订位人：{{currentSeatInfo.e || '-'}}</span>
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
import api_wine from '@/api/wine'
export default {
  data() {
    return {
      currentSeatInfo: {},
      regionList: []
    };
  },
  methods: {
    async getSeatInfo(){
      try {
        const res = await api_wine.reqGetCustomCenterSeatList()
        if(res.code == 1) {
          res.data.regions = res.data.regions || []
          res.data.seats = res.data.seats || []
          res.data.regions.forEach(el => {
            el.seatList = res.data.seats.filter(item => item.r == el.id)
          })
          this.regionList = res.data.regions.filter(item => item.seatList.length > 0)
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('卡台列表信息获取失败', error)
      }
    },

    chooseSeatHandle(seatInfo = {}){
      if(seatInfo.id && seatInfo.q == 1) {
        this.currentSeatInfo = {...seatInfo}
      } 
    },

    onSubmit (){
      if(!this.currentSeatInfo.id) return this.$message.warning('请选择卡台')
      this.$emit('submitHandle', this.currentSeatInfo)
    },
    onCancelDrawer(){
      this.show = false
    },

  },
  mounted() {},
  props: {
    value: {
      default: false // 是否显示drawer
    },
    status: {
      default: 1
    }
  },
  computed: {
    show: {
      get(){
        return this.value
      },

      set(val) {
        this.$emit('input', val)
      }
    }
  },
  watch: {
    value: {
      handler(newVal) {
        if(newVal) {
          this.currentSeatInfo = {}
         this.getSeatInfo() 
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import '../../../../style/common/elementDrawerWine.less';
@import '../../../../style/common/elementDrawerHeaderAndSession.less';
@import '../../../../style/common/elementFormBtnWine.less';
</style>

<style lang="less" scoped>
.choose-seat {
  .seat-list {
    height: calc(100vh - 180px);
    overflow: auto;
    .region{
      .region-name {
        font-weight: 600;
      }
      .seats {
        flex-wrap: wrap;
        .seat-item {
          margin: 6px;
          position: relative;
          user-select: none;
          width: 100px;
          height: 56px;
          padding: 3px;
          border-radius: 8px;
          box-sizing: border-box;
          border: 2px solid transparent;
          &.active {
            border: 2px solid yellow;
          }
          .seat-item-content {
            width: 100%;
            height: 100%;
            border-radius: 6px;
            background-color: #C7C7C7;
            border: solid 1px #888;
            color: #08080A;
            box-sizing: border-box;
            cursor: pointer;
            &.opacity {
              opacity: 0.5;
              cursor: no-drop;
            }
            img{
              position: absolute;
              left: -2px;
              top: -2px;
            }
          }
        }
      }
    }
  }
}
</style>