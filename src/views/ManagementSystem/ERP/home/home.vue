<template>
  <div class="home">
    <div v-if="storeList.length>0">
      <h3>！检测到以下物料库存为负，请尽快处理</h3>
      <div class="session">
        <div class="session-item" v-for="item in storeList" :key="item.id">
          <h4>{{item.n}}</h4>
          <div class="session-item-contain" layout="row" layout-align="space-between center">
            <div class="table-content">
              <div class="table">
                <div class="thead">
                  <div class="tr" layout="row" layout-align="space-between center">
                    <div class="th">序号</div>
                    <div class="th">收银商品名称</div>
                    <div class="th">对应物料名称</div>
                    <div class="th">物料一级分类</div>
                    <div class="th">物料二级分类</div>
                    <div class="th">物料分类</div>
                    <div class="th">当前库存</div>
                    <div class="th">卡住库存数</div>
                  </div>
                </div>
                <div class="tbody">
                  <div
                    class="tr"
                    v-for="(items,i) in item.ms"
                    :key="items.id"
                    layout="row"
                    layout-align="space-between center"
                  >
                    <div class="td">{{i+1}}</div>
                    <div class="td">{{items.sn}}</div>
                    <div class="td">{{items.mn}}</div>
                    <div class="td">{{items.on}}</div>
                    <div class="td">{{items.tn}}</div>
                    <div class="td">{{items.un}}</div>
                    <div class="td">{{items.c}}</div>
                    <div class="td">{{items.b}}</div>
                  </div>
                </div>
              </div>  
            </div>

            <h4 class="primary-link cursor" style="white-space: nowrap" @click="doSomeThingHandle(item)">立即处理 >></h4>
            
          </div>
        </div>
      </div>
    </div>
    <div v-if="prdList.length>0 && $store.state.client == 'erpAdmin'">
      <h3 class="m-t-10">！检测到以下售出的收银商品未配置对照关系，请尽快处理</h3>
      <div class="session">
        <div class="session-item">
          <div class="session-item-contain" layout="row" layout-align="space-between center">
            <div class="table-content">
              <div class="table">
                <div class="thead">
                  <div class="tr" layout="row" layout-align="space-between center">
                    <div class="th">序号</div>
                    <div class="th">收银商品名称</div>
                    <div class="th">一级分类</div>
                    <div class="th">二级分类</div>
                    <div class="th">操作</div>
                  </div>
                </div>
                <div class="tbody">
                  <div
                    class="tr"
                    v-for="(item,i) in prdList"
                    :key="item.id"
                    layout="row"
                    layout-align="space-between center"
                  >
                    <div class="td">{{i+1}}</div>
                    <div class="td">{{item.pn}}</div>
                    <div class="td">{{item.on}}</div>
                    <div class="td">{{item.tn}}</div>
                    <div class="td" layout="row" layout-align="start center">
                      <span @click="showOrHideDrawerHandle(item)">去绑定</span>
                      <span @click="notCompareHandle(item)">不用对照</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div v-if="($store.state.client == 'erpAdmin' && storeList.length==0 && prdList.length==0) || ($store.state.client == 'erp' && storeList.length==0)">
      <p>系统已自动完成处理，暂不需要手动调整。</p>
    </div>

    
    <drawerBindPrd
      :showDrawer="showDrawer"
      :currentItem="currentItem"
      @showOrHideDrawer="showOrHideDrawerHandle"
      @getBindList="getBindList"
    />

  </div>
</template>
 
<script>
import { sessionStorage, localStorage } from '@/utils/common/storage'
import drawerBindPrd from "../comparePrd/drawerBindPrd.vue";
export default {
  data() {
    return {
      showDrawer: false, // 是否显示绑定抽屉
      currentItem: {}, // 当前绑定的商品信息
      storeList: [],  // 仓库
      prdList: []  // 收银商品
    };
  },
  methods: {
    async getTableList(){
      try {
        const res = await this.$api.ERP.home.getTableList()
        if(res.code == 1){
          this.storeList = res.data.neg_stores || []
          this.prdList = res.data.not_bind_prds || []
        }else{
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取首页表格数据失败', error)
      }
    },

    doSomeThingHandle(itemObj) {
      if (sessionStorage.getItem("client") == "erp") {
        localStorage.setItem("navigation", "2,1,/ERP/changeOutLib,调拨出库");
      } else {
        localStorage.setItem("navigation", "4,1,/ERP/changeOutLib,调拨出库");
      }

      this.$parent &&
        this.$parent.$parent.initNavBarActive &&
        this.$parent.$parent.initNavBarActive('?itemObj=' + JSON.stringify(itemObj));
    },

    getBindList({ inventory, currentItem }) {
     this.compareSuccessHandle(currentItem.id, inventory[0].id)
    },

    
    // 不用对照
    async notCompareHandle(itemInfo) {
      const params = {
        ids: [itemInfo.id] //  []int64    待操作商品Id列表
      };
      if (params.ids.length <= 0)
        return this.$message.warning("请选择操作的商品");
      try {
        const res = await this.$api.ERP.comparePrd.reqCloseBindPrdList(params);
        if (res.code == 1) {
          this.getTableList();
          this.$message.success("操作成功");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("不用对照失败", error);
      }
    },

    // 完成对照
    async compareSuccessHandle(id, mid) {
      const params = {
        id: id * 1, // int64  待操作商品Id
        mid: mid * 1 // int64  绑定的物料Id
      };
      try {
        const res = await this.$api.ERP.comparePrd.reqBindPrdList(params);
        if (res.code == 1) {
          this.getTableList();
          this.$message.success("对照成功");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("完成对照失败", error);
      }
    },
    
    showOrHideDrawerHandle(item) {
      if (item && item.pn) {
        this.currentItem = { ...item };
      }
      this.showDrawer = !this.showDrawer;
    },
  },
  mounted () {
    this.getTableList()
  },
  components: {
    drawerBindPrd
  }
};
</script>

<style lang="less" scoped>
@import "../../../../style/erp/table.less";
@import "./home.less";
</style>