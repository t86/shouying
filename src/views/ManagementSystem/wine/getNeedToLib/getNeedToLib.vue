<template>
  <!-- 取酒待入库 -->
  <div class="get-lib">
    <div class="top">
      <el-input
        v-model="keyword"
        style="width:300px"
        class="m-r-2"
        size="small"
        placeholder="输入客人手姓名/手机号/商品/卡台/订位人"
      ></el-input>
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button size="small" @click="resetHandle">重置</el-button>
    </div>
    <div class="btn-area m-t-4">
      <el-button type="primary" size="small" @click="showDialogHandle">确认出库</el-button>
      <el-button type="danger" size="small" @click="fromLibBackHandle">驳回</el-button>
    </div>

    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="start center">
            <div class="th">
              <el-checkbox
                :indeterminate="isIndeterminate"
                v-model="checkAll"
                @change="changeCheckboxHandle('all')"
              >全选</el-checkbox>
            </div>
            <div class="th">超级码</div>
            <div class="th">客人姓名</div>
            <div class="th">联系方式</div>
            <div class="th">卡台</div>
            <div class="th">订台人</div>
            <div class="th">服务员</div>
            <div class="th">取酒时间</div>
            <div class="th">操作</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" :class="{'selected': item.checked}" v-for="(item, index) in tableData" :key="item.id">
            <div class="coll" layout="row" layout-align="space-between center">
              <div class="td" layout="row" layout-align="start center">
                <el-checkbox
                  v-model="item.checked"
                  @change="changeCheckboxHandle('item')"
                >{{index + 1}}</el-checkbox>
                <i
                  class="m-l-2"
                  style="border:1px solid #ccc;cursor:pointer"
                  @click="item.show = !item.show"
                  :class="[item.show ? 'el-icon-minus' : 'el-icon-plus']"
                ></i>
              </div>
              <div class="td" :class="{'is-black': item.us == '是'}">{{item.us}}</div>
              <div class="td" :class="{'is-black': item.b == 1}">{{item.c}}</div>
              <div class="td" :class="{'is-black': item.b == 1}">{{item.p}}</div>
              <div class="td">{{item.s}}</div>
              <div class="td">{{item.e}}</div>
              <div class="td">{{item.w}}</div>
              <div class="td">{{item.t}}</div>
              <div class="td">
                <span @click="showEditDrawerHandle(item)">编辑</span>
              </div>
            </div>
            <div class="detail-list" v-if="item.show">
              <div class="tr-thead" layout="row" layout-align="space-between center">
                <div class="tr-th">酒水名称</div>
                <div class="tr-th">规格</div>
                <div class="tr-th">每瓶克数</div>
                <div class="tr-th">数量</div>
                <div class="tr-th">存酒卡台</div>
                <div class="tr-th">存酒订位人</div>
                <div class="tr-th">过期时间</div>
                <div class="tr-th">授权人</div>
                <div class="th">备注</div>
                <div class="tr-th">库存id</div>
              </div>
              <div class="tr-tbody">
                <div
                  class="tr-tr"
                  layout="row"
                  layout-align="space-between center"
                  v-for="(items, index) in (item.ss || [])"
                  :key="index"
                >
                  <div class="tr-td" :class="{'is-black': item.b == 1}">{{items.n}}</div>
                  <div class="tr-td">{{items.u}}</div>
                  <div class="tr-td">{{items.g || '-'}}</div>
                  <div class="tr-td">{{items.c}}</div>
                  <div class="tr-td">{{items.ss}}</div>
                  <div class="tr-td">{{items.s}}</div>
                  <div class="tr-td">{{items.e}}</div>
                  <div class="tr-td">{{items.a}}</div>
                  <div class="tr-td" style="color: red;">{{items.w}}</div>
                  <div class="tr-td">{{items.i}}</div>
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

    <!-- 编辑取酒单 -->
    <drawerEditGetInfo v-model="showEditDrawer" :currentWineInfo="currentSaveInfo" :needWaiterAuth="needWaiterAuth" @getTableData="getTableData" />

    <el-dialog
      title="提示"
      :visible.sync="dialogVisible"
      width="30%">
      <p class="p-t-6">确认出库吗？</p>
      <span slot="footer" class="dialog-footer">
        <el-button @click="dialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="fromLibSureHandle">确 定</el-button>
      </span>
    </el-dialog>
  </div>
</template>
 
<script>
import { keyHandle } from "../../../../mixin/keyhandle";
import api_wine from "@/api/wine";
import drawerEditGetInfo from './drawerEditGetInfo.vue'
export default {
  data() {
    return {
      ids: [], // 选中的id列表
      needWaiterAuth: true,  // 是否需要服务员授权 1 需要 2 不需要
      keyword: "",
      checkAll: false,
      tableData: [],
      showEditDrawer: false,
      currentSaveInfo: {},
      dialogVisible: false
    };
  },
  methods: {
    async getTableData() {
      const params = {
        key: this.keyword || "" //  string     //Key 搜索关键字
      };

      try {
        const res = await api_wine.reqGetGetFromLib(params);
        if (res.code == 1) {
          res.data.records = res.data.records || [];
          res.data.records.forEach(el => {
            el.ss = el.ss || [];
            el.show = true
            el.checked = false;
          });
          this.needWaiterAuth = res.data.need_waiter_auth == 1  // 是否需要服务员授权 1 需要 2 不需要
          this.checkAll = false;
          this.tableData = res.data.records;
          this.ids = []
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("待入库存酒数据获取失败", error);
      }
    },
    
    showDialogHandle(){
      if(this.ids.length == 0) return this.$message.warning('请选择需要确认的数据')
      this.dialogVisible = true
    },

    // 确认出库
    async fromLibSureHandle() {
      const params = {
        ids: this.ids // []int64   取酒待出库订单列表
      };
      if (params.ids.length == 0)
        return this.$message.warning("请选择需要确认的数据");
      try {
        const res = await api_wine.reqSureFromGetInLib(params);
        if (res.code == 1) {
          this.$message.success("出库成功");
          this.dialogVisible = false
          this.getTableData();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("确认入库操作失败", error);
      }
    },

    // 驳回
    async fromLibBackHandle() {
      const params = {
        bef_out_ids: this.ids // []int64      //BefOutIds 取酒待出库订单Id列表
      };
      if (params.bef_out_ids.length == 0)
        return this.$message.warning("请选择需要驳回的数据");
      try {
        const res = await api_wine.reqBackFromGetInLib(params);
        if (res.code == 1) {
          this.$message.success("驳回成功");
          this.getTableData();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("驳回操作失败", error);
      }
    },

    changeCheckboxHandle(type) {
      switch (type) {
        case "all":
          this.tableData.forEach(el => {
            el.checked = this.checkAll;
          });
          break;
        case "item":
          this.checkAll = this.tableData.every(item => item.checked);
          break;
      }
      this.ids = this.tableData
        .filter(item => item.checked)
        .map(item => item.o);
    },

    resetHandle() {
      this.keyword = "";
      this.getTableData();
    },

    showEditDrawerHandle(itemInfo){
      this.currentSaveInfo = {...itemInfo}
      this.showEditDrawer = true
    }
  },
  created() {
    this.getTableData();
  },
  components: {
    drawerEditGetInfo
  },
  computed: {
    isIndeterminate() {
      return !this.checkAll && this.tableData.some(item => item.checked);
    }
  },
  mixins: [keyHandle]
};
</script>

<style lang="less" scoped>
@import "../../../../style/wine/table.less";
</style>
<style scoped lang="less">
.get-lib {
  padding: 20px;
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
            margin: 10px 10px;
          }
          &:hover{
            .td {
              background-color: #ddd!important;

            }
          }
          .is-black {
            color: red;
          }
        }
        .coll {
          padding: 15px auto;
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
              .is-black {
                color: red;
              }
            }
          }
        }
      }
    }
  }
}
</style>