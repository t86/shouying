<template>
  <div class="step-two">
    <div class="top" layout="row" layout-align="space-between center">
      <div class="left">
        <span>{{phoneNum}}</span>
        <span>{{customName}}</span>
      </div>
      <div class="right" layout="row" layout-align="start center">
        <div class="card-name">{{$store.state.orderInfo.saveWineCardInfo.name}}</div>
        <div class="info">
          <span class="date">{{filterTime($store.state.orderInfo.saveWineCardInfo.openTime)}}</span>
          <span>订位人：{{getOrderPersonName($store.state.orderInfo.saveWineCardInfo.salesEmpId)}}</span>
        </div>
      </div>
    </div>

    <!-- 剩余取酒详情 -->
    <div class="get-list">
      <div class="left">
        <div class="title fs16 m-t-3 m-b-3">剩余取酒详情</div>
        <div class="table-content" layout="row" layout-align="space-between center">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">名称</div>
                <div class="th">规格</div>
                <div class="th">每瓶克数</div>
                <div class="th">存酒时间</div>
                <div class="th">过期时间</div>
                <div class="th">剩余可取数量</div>
              </div>
            </div>
            <div class="tbody" ref="firstTableRef">
              <div
                class="tr"
                layout="row"
                layout-align="space-between center"
                v-for="item in WineList"
                :key="item.id"
              >
                <div class="td">{{item.n}}</div>
                <div class="td">{{item.u}}</div>
                <div class="td">{{item.g || '-'}}</div>
                <div class="td">{{item.i}}</div>
                <div class="td">{{item.e}}</div>
                <div class="td" layout="row" layout-align="space-between center">
                  <div class="count">{{item.c}}</div>
                  <div class="get-icon" :class="{opacity: !item.canGet}" @click="addWineToShoppingCart(item)">取</div>
                </div>
              </div>
            </div>
          </div>

          <div class="arrow">
            <div class="bg" layout="row" layout-align="center center">
              <div class="bg-left" @click="scrollHandle('first','up')">
                <img :src="require('@/assets/order-img/arrowBottom.png')" alt />
              </div>
              <div class="bg-right" @click="scrollHandle('first','down')">
                <img :src="require('@/assets/order-img/arrowBottom.png')" alt />
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="right m-t-6">
        <div class="title fs16 m-t-3 m-b-3">取酒详情</div>
        <div class="table-content" layout="row" layout-align="space-between center">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">名称</div>
                <div class="th">规格</div>
                <div class="th">每瓶克数</div>
                <div class="th">数量</div>
                <div class="th">操作</div>
              </div>
            </div>
            <div class="tbody" ref="secondTableRef">
              <div
                class="tr"
                layout="row"
                layout-align="space-between center"
                v-for="item in shoppingCartWineList"
                :key="item.id"
              >
                <div class="td">{{item.n}}</div>
                <div class="td">{{item.u}}</div>
                <div class="td">{{item.g || '-'}}</div>
                <div class="td" layout="row" layout-align="start center">
                  <img :src="item.c > 1 ? require('@/assets/order-img/sub.png') : require('@/assets/order-img/sub-disabled.png')" @click="changeShoppingCartCount(item, Math.max((item.c * 1 - 1), 1))"
                  />
                  <input type="number" :min="1" v-model="item.c" @input="changeShoppingCartCount(item, Math.max(item.c, 1))" />
                  <img :src="item.c < item.maxCount ? require('@/assets/order-img/order_add.png') : require('@/assets/order-img/add-disabled.png')" @click="changeShoppingCartCount(item, (item.c * 1 + 1))" />
                </div>
                <div class="td" layout="row" layout-align="space-between center">
                  <img :src="require('@/assets/order-img/delete.png')" @click="changeShoppingCartCount(item, 0)"/>
                </div>
              </div>
            </div>
          </div>
          <div class="arrow">
            <div class="bg" layout="row" layout-align="center center">
              <div class="bg-left" @click="scrollHandle('second','up')">
                <img :src="require('@/assets/order-img/arrowBottom.png')" alt />
              </div>
              <div class="bg-right" @click="scrollHandle('second','down')">
                <img :src="require('@/assets/order-img/arrowBottom.png')" alt />
              </div>
            </div>
          </div>
        </div>
        
      </div> 

    </div>

    <!-- 底部按钮 -->
    <div class="form-btn" layout="row" layout-align="space-between center">
      <div class="left" layout="row" layout-align="end center">
        <!-- <el-button type="primary" @click="showChooseWineParamsOfAuthDrawer=true">授权存酒</el-button> -->
      </div>
      <div class="right" layout="row" layout-align="end center">
        <el-button type="info" @click="$emit('onCancelDrawer', true)">取消</el-button>
        <el-button type="info" @click="$emit('changeStatus', 1)">返回上一步</el-button>
        <el-button type="primary" @click="getWineHandle">确定取酒</el-button>
      </div>
    </div>
  </div>
</template>
 
<script>
import api_saveWine from "@/api/saveWine";
export default {
  data() {
    return {
      customName: '',
      WineList: [],  // 当前流水可取酒水
      shoppingCartWineList: [],  // 存酒购物车酒水
    };
  },
  methods: {
    init(){
      this.shoppingCartWineList = []
      this.getOrderCanGetWine()
    },

    
    scrollHandle(type, direction) {
      let dom = this.$refs[type + "TableRef"];
      const step = 200;
      const scrollTop =
        direction === "down" ? dom.scrollTop + step : dom.scrollTop - step;
      dom.scrollTo(0, scrollTop);
    },

    // 获取订单流水可存酒水
    async getOrderCanGetWine() {
      const params = {
        phone_num: this.phoneNum.toString(),  // string   客户手机号,用以返还客户姓名
        key: ''  //   string     过滤关键字
      }

      try {
        const res = await api_saveWine.reqGetCanGetFromLib(params)
        if(res.code == 1) {
          this.customName = res.data.cust_name || ''
          this.WineList = (res.data.records || []).map(item => ({
            ...item,
            canGet: true
          }))
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取可取酒水列表失败', error)
      }
    },

    // 选择流水中酒水信息
    addWineToShoppingCart(itemInfo){
      if(!itemInfo.canGet) return this.$message.warning('当前酒水可取数量已达到最大值')
      const hasItem = this.shoppingCartWineList.find(item => item.id == itemInfo.id)
      if(hasItem) {
        this.shoppingCartWineList = this.shoppingCartWineList.map(item => ({
          ...item,
          c: item.id == itemInfo.id ? itemInfo.c : item.c
        }))
      } else {
        this.shoppingCartWineList = [...this.shoppingCartWineList, {...itemInfo, maxCount: itemInfo.c}]
      }
      this.WineList = this.WineList.map(item => ({
        ...item,
        canGet: item.id == itemInfo.id ? false : item.canGet
      }))
    },

    // 修改购物车数量/删除
    changeShoppingCartCount(itemInfo, count) {
      if(itemInfo.maxCount <= count) {
        itemInfo.c = itemInfo.maxCount
      } else if (count <= 0) {
        // 删除
        const index = this.shoppingCartWineList.findIndex(item => item.id == itemInfo.id)
        if(index > -1) {
          this.shoppingCartWineList.splice(index, 1)
        }
        itemInfo.c = count
      } else {
        itemInfo.c = count
      }

      this.WineList = this.WineList.map(item => ({
        ...item,
        canGet: item.id == itemInfo.id ? itemInfo.c < item.c : item.canGet
      }))
    },

    async getWineHandle(){
      const params = {
        seat_id: this.$store.state.orderInfo.saveWineCardInfo.id * 1, // int64    卡台Id
        invt_ids: this.shoppingCartWineList.map(item => item.id * 1), //   []int64   存酒库存Id列表
        prd_cnts:this.shoppingCartWineList.map(item => item.c * 1),  //  []int  对应存酒库存Id的取酒商品数量
        phone_num_auth_code: this.tabIndex == 3 ? this.superValidate : this.phoneValidateStr, // string  认证手机授权码
        phone_num: this.phoneNum   //  string  取酒客户手机号
      }
      try {
        const res = await api_saveWine.reqGetWineToNextLib(params)
        if(res.code == 1) {
          this.$message.success('取酒成功')
          this.$emit('onCancelDrawer', true)
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('新增取酒订单失败', error)
      }
    },

    getOrderPersonName(orderPersonId){
      return (this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo.find(el => el.id === orderPersonId) &&
        this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo.find(el => el.id === orderPersonId)
          .name) ||
      "散客"
    },
    filterTime(timeNumber) {
      if (!timeNumber) return "";
      const month = timeNumber.slice(4, 6);
      const day = timeNumber.slice(6, 8)
      const hour = timeNumber.slice(8, 10);
      const minute = timeNumber.slice(10, 12);
      return `${month}/${day} ${hour}:${minute}`;
    }
  },
  props: {
    tabIndex: {
      default: 1
    },
    stepTwoInfo: {},
    phoneNum: '',
    superValidate: '',
    phoneValidateStr: ''
  }
};
</script>
<style lang="less" scoped>
@import "../../../../style/saveWine/table.less";
@import "../../../../style/common/elementFormBtn.less";
</style>
<style scoped lang="less">
.step-two {
  color: rgba(255, 255, 255, 0.8);
  font-size: 14px;

  // 头部
  .top {
    background-color: #11182d;
    padding: 0 20px 20px;
    .left {
      font-size: 24px;
      color: #fff;
    }
    .right {
      .card-name {
        color: #fff;
        font-size: 24px;
        padding-right: 20px;
        position: relative;
        &:after {
          content: "";
          position: absolute;
          right: 0;
          top: 0;
          width: 1px;
          height: 100%;
          background: rgba(255, 255, 255, 0);
          // background: linear-gradient(
          //   180deg,
          //   rgba(255, 255, 255, 0) 0%,
          //   #ffffff 53%,
          //   rgba(255, 255, 255, 0) 100%
          // );
          opacity: 0.5;
        }
      }

      .info {
        padding-left: 20px;
        span {
          font-size: 14px;
          color: #aed8ff;

          &.date {
            margin-right: 20px;
          }
        }
      }
    }
  }

  // 列表
  .get-list {
    padding: 0 20px;
    height: calc(100vh - 178px);
    // 左侧
    .left {
      overflow: auto;
      box-sizing: border-box;
      // border-right: 1px solid rgba(255, 255, 255, 0.2);
      .table {
        width: calc(100% - 100px);
        .tbody {
          height: calc(50vh - 200px);
          overflow: auto;
          scroll-behavior: smooth;
          .get-icon {
            width: 36px;
            height: 28px;
            line-height: 28px;
            text-align: center;
            font-size: 18px;
            color: #fff;
            background: #4b89ff;
            border-radius: 6px;
            cursor: pointer;
            &.opacity {
              opacity: 0.2;
            }
          }
        }
      }
    }
    // 右侧
    .right {
      overflow: auto;
      box-sizing: border-box;
      .table {
        width: calc(100% - 100px);
        .tbody {
          height: calc(50vh - 200px);
          overflow: auto;
          scroll-behavior: smooth;
        }
        .th,.td {
            width: 20%;
            &:nth-child(4) {
              width: 30%;
              img {
                width: 20px;
                cursor: pointer;
              }
              input {
                width: 50px;
                height: 26px;
                border-radius: 13px;
                margin: 0 6px;
                font-size: 14px;
                text-align: center;
                box-sizing: border-box;
              }
            }
            &:nth-child(5) {
              img {
                width: 20px;
                cursor: pointer;
              }
            }
          }
      }
    }

    //  箭头
    .arrow {
      width: 120px;
      height: 60px;
      position: fixed;
      right: 0;
      cursor: pointer;

      .bg {
        margin-top: 10px;

        .bg-left,
        .bg-right {
          width: 46px;
          height: 40px;
          background: #0D172D;
          box-shadow: inset 0px 1px 1px 0px #2775BA;
          text-align: center;

          img {
            width: 20px;
            margin-top: 10px;
          }
        }

        .bg-left {
          border-radius: 30px 0px 0px 30px;

          img {
            transform: rotate(180deg);
          }
        }

        .bg-right {
          border-radius: 0 30px 30px 0;
        }
      }
    }
  }

  .form-btn {
    width: 100%;
    box-sizing: border-box;
    padding: 0 20px;
    .left {
      height: 100%;
      width: 50%;
      padding-right: 10px;
      box-sizing: border-box;
      // border-right: 1px solid rgba(255, 255, 255, 0.2);
    }
    .right {
      width: 50%;
      box-sizing: border-box;
    }
  }
}
</style>