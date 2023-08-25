<template>
  <!-- 取酒 -->
  <div class="cus-get-lib">
    <div class="top">
      <el-input
        v-model="keyword"
        style="width:260px"
        class="m-r-2"
        size="small"
        placeholder="输入订位人/商品/卡台/存酒流水号"
      ></el-input>
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button size="small" @click="resetHandle">重置</el-button>
    </div>
    <div class="btn-area m-t-4" layout="row" layout-align="start center">
      <el-button type="primary" size="small" @click="addGaveWineShoppingHandle">加入待取酒列表</el-button>
      <div class="shopping-cart">
        <el-button type="primary" size="small" @click="showNeedGetWineShoppingCartHandle">待取酒列表</el-button>
        <div v-if="shoppingCartList.length > 0" class="count">{{shoppingCartList.length}}</div>
      </div>
    </div>

    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="start center">
            <div class="th">序号</div>
            <div class="th">卡台</div>
            <div class="th">订位人</div>
            <div class="th">服务员</div>
            <div class="th">存酒时间</div>
            <div class="th">入库时间</div>
            <div class="th">入库操作人</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" v-for="(item, index) in tableData" :key="item.id">
            <div class="coll" layout="row" layout-align="space-between center">
              <div class="td" layout="row" layout-align="start center">
                <span>{{index + 1}}</span>
                <i
                  class="m-l-2"
                  style="border:1px solid #ccc;cursor:pointer"
                  @click="item.show = !item.show"
                  :class="[item.show ? 'el-icon-minus' : 'el-icon-plus']"
                ></i>
              </div>
              <div class="td">{{item.s}}</div>
              <div class="td">{{item.e}}</div>
              <div class="td">{{item.w}}</div>
              <div class="td">{{item.t}}</div>
              <div class="td">{{item.it}}</div>
              <div class="td">{{item.we}}</div>
            </div>
            <div class="detail-list" v-if="item.show">
              <div class="tr-thead" layout="row" layout-align="space-between center">
                <div class="tr-th" layout="row" layout-align="start center">
                  <div style="width:50px;text-align:left">
                    <el-checkbox
                      :indeterminate="item.isIndeterminate"
                      :disabled="item.disabled"
                      v-model="item.checkAll"
                      @change="changeCheckboxHandle('all', item)"
                    >全选</el-checkbox>
                  </div>
                </div>
                <div class="tr-th">酒水名称</div>
                <div class="tr-th">规格</div>
                <div class="tr-th">每瓶克数</div>
                <div class="tr-th">数量</div>
                <div class="tr-th">过期时间</div>
                <div class="tr-th">授权人</div>
                <div class="tr-th">备注姓名</div>
                <div class="tr-th">备注手机号</div>
                <div class="tr-th">存酒流水号</div>
              </div>
              <div class="tr-tbody">
                <div
                  class="tr-tr"
                  layout="row"
                  layout-align="space-between center"
                  v-for="(items, i) in (item.ss || [])"
                  :key="i"
                >
                  <div class="tr-td" layout="row" layout-align="start center">
                    <div style="width:50px;text-align:left">
                      <el-checkbox
                        v-model="items.checked"
                        :disabled="items.disabled"
                        @change="changeCheckboxHandle('item', item)"
                      >{{i + 1}}</el-checkbox>
                    </div>
                  </div>
                  <div class="tr-td">{{items.n}}</div>
                  <div class="tr-td">{{items.u}}</div>
                  <div class="tr-td">{{items.g || '-'}}</div>
                  <div class="tr-td">{{items.c}}</div>
                  <div class="tr-td">{{items.e}}</div>
                  <div class="tr-td">{{items.a}}</div>
                  <div class="tr-td">{{items.rn}}</div>
                  <div class="tr-td">{{items.rp}}</div>
                  <div class="tr-td" style="user-select: text;">{{items.id}}</div>
                </div>
              </div>
            </div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img src="@/assets/img/wu.png" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>

  <!-- 待取酒列表 -->
  <drawerGetLibShoppingCart v-model="showShoppingCartDrawer" :shoppingCartList="shoppingCartList" @shoppingCartComChangeShoppingCartListHandle="shoppingCartComChangeShoppingCartListHandle" @getTableData="getTableData"/>
  </div>
</template>
 
<script>
import api_wine from "@/api/wine";
import drawerGetLibShoppingCart from './drawerGetLibShoppingCart.vue'
export default {
  data() {
    return {
      needWaiterAuth: true,  // 是否需要服务员授权 1 需要 2 不需要
      keyword: "",
      checkAll: false,
      tableData: [],

      shoppingCartList: [],  // 待取酒列表

      showShoppingCartDrawer: false
    };
  },
  methods: {
    async getTableData(resetShoppingCart = false) {
      const params = {
        key: this.keyword || "" //  string   搜索关键字
      };

      try {
        const res = await api_wine.reqGetCustomCenterGetWineList(params);
        if (res.code == 1) {
          res.data.records = res.data.records || [];
          res.data.records.forEach(el => {
            el.ss = (el.ss || []).map(item => ({
              ...item,
              checked: false,
              disabled: false
            }));
            el.show = true;
            el.checkAll = false;
            el.disabled = false;
            el.isIndeterminate = false
          });
          this.tableData = res.data.records;
          if(resetShoppingCart) this.shoppingCartList = []
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("待入库存酒数据获取失败", error);
      }
    },

    // 加入待取酒列表
    addGaveWineShoppingHandle() {
      let shoppingCartList = []
      this.tableData.forEach(el => {
        el.ss.forEach(ele => {
          if(ele.checked) {
            ele.disabled = true
            shoppingCartList = [...shoppingCartList, ele]
          }
        })
        el.disabled = el.checkAll
      })

      this.shoppingCartList = [...shoppingCartList]
      this.$message.success('加入成功')
    },

    // 待取酒列表
    showNeedGetWineShoppingCartHandle() {
      this.showShoppingCartDrawer = true
    },

    // 购物车改变待出库列表数据
    shoppingCartComChangeShoppingCartListHandle(shoppingCartList){
      this.tableData.forEach(el => {
        el.ss.forEach(ele => {
          const find = shoppingCartList.find(item => item.id == ele.id)
          ele.disabled = !!find
          ele.checked = !!find
        })
        el.disabled = el.ss.every(item => item.disabled)
        el.checkAll = el.ss.every(item => item.checked)
        el.isIndeterminate = !el.checkAll && el.ss.some(item => item.checked)
      })
      this.shoppingCartList = [...shoppingCartList]
    },

    changeCheckboxHandle(type, itemInfo) {
      switch (type) {
        case "all":
          itemInfo.ss.forEach(el => {
            el.checked = el.disabled ? el.checked : itemInfo.checkAll;
          });
          break;
        case "item":
          itemInfo.checkAll = itemInfo.ss.every(item => item.checked);
          break;
      }
      itemInfo.isIndeterminate = !itemInfo.checkAll && itemInfo.ss.some(item => item.checked);
    },

    resetHandle() {
      this.keyword = "";
      this.getTableData();
    },
  },
  created() {
    this.getTableData();
  },
  components: {
    drawerGetLibShoppingCart
  },
  computed: {
    isIndeterminate() {
      return !this.checkAll && this.tableData.some(item => item.checked);
    }
  }
};
</script>

<style lang="less" scoped>
@import "../../../../style/wine/table.less";
</style>
<style scoped lang="less">
.cus-get-lib {
  padding: 20px;
  .btn-area {
    .shopping-cart {
      position: relative;
      margin: 0 16px;
      .count {
        width: 26px;
        height: 26px;
        position: absolute;
        right: -10px;
        top: -10px;
        background-color: #ff9900;
        border-radius: 50%;
        text-align: center;
        line-height: 26px;
        font-size: 13px;
        color: #fff;
      }
    }
  }
  .table-content {
    .table {
      .thead .th {
        font-size: 15px;
      }
      .tbody {
        height: calc(100vh - 260px);
        overflow: auto;
        .tr {
          background-color: #ddd!important;
          margin-top: 2px;
          .td {
            background-color: #ddd!important;
          }
          &:hover{
            .td {
              background-color: #ddd!important;

            }
          }
        }
        .coll {
          height: 40px;
          font-size: 15px;
          .td {
            font-weight: 600;
            /deep/.el-checkbox__label{
              font-weight: 600;
            }
            &:nth-last-child(1) {
              span {
                color: #2170ff;
                cursor: pointer;
              }
            }
          }
        }
        .detail-list {
          font-size: 13px;
          .tr-thead {
            height: 30px;
            width: 100%;
            background-color: #eee;
            .tr-th {
              width: 50%;
              color: #6A6A74;
              font-weight: 600;
              &:nth-child(1){
                padding-left: 20px;
                /deep/.el-checkbox__label {
                  font-weight: 600;
                }
              }
            }
          }
          .tr-tbody {
            // max-height: 200px;
            // overflow: auto;
            .tr-tr{
              min-height: 30px;
              &:hover{
                background-color: #d7e9ff!important;
              }
              &:nth-child(2n){
                background-color: #eee;
              }
              &:nth-child(2n + 1){
                background-color: #f9f9f9;
              }
              .tr-td {
                width: 50%;
                &:nth-child(1){
                  padding-left: 20px;
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